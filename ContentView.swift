//
//  ContentView.swift
//  Dark Light Joint
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers
import ApplicationServices
import CoreGraphics

struct ContentView: View {
    @State private var hasPermission = false
    @State private var permissionChecked = false
    @State private var leftImage: NSImage?
    @State private var rightImage: NSImage?
    @State private var mergedImage: NSImage?
    @State private var width: CGFloat = 360
    @State private var ratio: CGFloat = 16/9
    @State private var showSaveAlert = false
    @State private var alertMessage = ""
    @State private var isCapturing = false

    var height: CGFloat {
        let calculatedHeight = width / ratio
        return min(calculatedHeight, 350)
    }

    var body: some View {
        if !permissionChecked {
            ProgressView("检查权限...")
                .onAppear { checkPermission() }
        } else if !hasPermission {
            VStack(spacing: 20) {
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.orange)
                Text("需要屏幕录制权限")
                    .font(.system(size: 20, weight: .bold))
                Text("请点击下方按钮授权")
                    .foregroundColor(.secondary)
                Button(action: requestPermission) {
                    Text("授权")
                        .frame(width: 120)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .frame(width: 400, height: 300)
        } else {
            mainContentView
        }
    }

    var mainContentView: some View {
        HStack(spacing: 20) {
            ImageBox(
                image: $leftImage,
                placeholder: "📷",
                action: { captureImage(position: .left) },
                isCapturing: $isCapturing,
                width: width,
                ratio: $ratio,
                onDelete: {
                    leftImage = nil
                    mergedImage = nil
                }
            )

            Text("+")
                .font(.system(size: 40))
                .foregroundColor(.secondary)

            ImageBox(
                image: $rightImage,
                placeholder: "📷",
                action: { captureImage(position: .right) },
                isCapturing: $isCapturing,
                width: width,
                ratio: $ratio,
                onDelete: {
                    rightImage = nil
                    mergedImage = nil
                }
            )

            Text("=")
                .font(.system(size: 40))
                .foregroundColor(.secondary)

            ZStack(alignment: .topTrailing) {
                GeometryReader { geometry in
                    if let merged = mergedImage {
                        Image(nsImage: merged)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: width, height: height)
                            .onTapGesture { saveImage() }
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: width, height: height)
                            .overlay(Text("预览").foregroundColor(.secondary))
                    }
                }
                .frame(width: width, height: height)

                if mergedImage != nil {
                    Button(action: saveImage) {
                        Image(systemName: "arrow.down.doc.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.plain)
                    .padding(8)
                }
            }
        }
        .padding(20)
        .frame(width: 1280, height: 400)
        .disabled(isCapturing)
        .alert("提示", isPresented: $showSaveAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }

    func checkPermission() {
        let permitted = CGPreflightScreenCaptureAccess()
        permissionChecked = true
        hasPermission = permitted
    }

    func requestPermission() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }

    enum CapturePosition { case left, right }

    func getWindow() -> NSWindow? { NSApp.windows.first }

    func captureImage(position: CapturePosition) {
        if !CGPreflightScreenCaptureAccess() {
            hasPermission = false
            return
        }

        guard let window = getWindow() else { return }

        isCapturing = true
        window.orderOut(nil)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
            task.arguments = ["-i", "-c"]

            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = pipe

            do {
                try task.run()

                DispatchQueue.global(qos: .userInitiated).async {
                    task.waitUntilExit()
                    Thread.sleep(forTimeInterval: 0.3)

                    DispatchQueue.main.async {
                        if let clipboardImage = NSPasteboard.general.data(forType: .tiff),
                           let image = NSImage(data: clipboardImage) {

                            let imageSize = image.size
                            let imageRatio = imageSize.width / imageSize.height

                            if position == .left {
                                leftImage = image
                                if rightImage == nil { ratio = imageRatio }
                                if rightImage != nil { mergeImages() }
                            } else {
                                rightImage = image
                                if leftImage == nil { ratio = imageRatio }
                                if leftImage != nil { mergeImages() }
                            }

                            window.orderFront(nil)
                            window.makeKeyAndOrderFront(nil)
                            isCapturing = false

                        } else {
                            DispatchQueue.main.async {
                                alertMessage = "未能获取截图，请重试"
                                showSaveAlert = true
                                window.orderFront(nil)
                                window.makeKeyAndOrderFront(nil)
                                isCapturing = false
                            }
                        }
                    }
                }

            } catch {
                DispatchQueue.main.async {
                    alertMessage = "截图失败: \(error.localizedDescription)"
                    showSaveAlert = true
                    window.orderFront(nil)
                    window.makeKeyAndOrderFront(nil)
                    isCapturing = false
                }
            }
        }
    }

    func mergeImages() {
        guard let left = leftImage, let right = rightImage else { return }

        let targetWidth = min(left.size.width, right.size.width)
        let targetHeight = min(left.size.height, right.size.height)
        let targetSize = NSSize(width: targetWidth, height: targetHeight)

        let leftResized = resizeImage(left, to: targetSize)
        let rightResized = resizeImage(right, to: targetSize)

        let merged = createDiagonalMerge(leftResized, rightResized, size: targetSize)

        mergedImage = merged
        ratio = targetWidth / targetHeight
    }

    func resizeImage(_ image: NSImage, to size: NSSize) -> NSImage {
        let resized = NSImage(size: size)
        resized.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: size), from: NSRect(origin: .zero, size: image.size), operation: .copy, fraction: 1.0)
        resized.unlockFocus()
        return resized
    }

    func createDiagonalMerge(_ left: NSImage, _ right: NSImage, size: NSSize) -> NSImage {
        let merged = NSImage(size: size)
        merged.lockFocus()

        NSGraphicsContext.saveGraphicsState()
        let leftPath = NSBezierPath()
        leftPath.move(to: NSPoint(x: 0, y: 0))
        leftPath.line(to: NSPoint(x: 0, y: size.height))
        leftPath.line(to: NSPoint(x: size.width, y: 0))
        leftPath.close()
        leftPath.addClip()

        left.draw(in: NSRect(origin: .zero, size: size), from: NSRect(origin: .zero, size: left.size), operation: .copy, fraction: 1.0)
        NSGraphicsContext.restoreGraphicsState()

        NSGraphicsContext.saveGraphicsState()
        let rightPath = NSBezierPath()
        rightPath.move(to: NSPoint(x: size.width, y: 0))
        rightPath.line(to: NSPoint(x: size.width, y: size.height))
        rightPath.line(to: NSPoint(x: 0, y: size.height))
        rightPath.close()
        rightPath.addClip()

        right.draw(in: NSRect(origin: .zero, size: size), from: NSRect(origin: .zero, size: right.size), operation: .copy, fraction: 1.0)
        NSGraphicsContext.restoreGraphicsState()

        merged.unlockFocus()
        return merged
    }

    func saveImage() {
        guard let merged = mergedImage else { return }

        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.png]
        savePanel.nameFieldStringValue = "merge_\(Int(Date().timeIntervalSince1970)).png"
        savePanel.canCreateDirectories = true
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                if let tiffData = merged.tiffRepresentation,
                   let bitmap = NSBitmapImageRep(data: tiffData),
                   let pngData = bitmap.representation(using: .png, properties: [:]) {
                    do {
                        try pngData.write(to: url)
                        alertMessage = "图片已保存"
                    } catch {
                        alertMessage = "保存失败: \(error.localizedDescription)"
                    }
                    showSaveAlert = true
                }
            }
        }
    }
}

// 图片框组件
struct ImageBox: View {
    @Binding var image: NSImage?
    let placeholder: String
    let action: () -> Void
    @Binding var isCapturing: Bool
    let width: CGFloat
    @Binding var ratio: CGFloat
    let onDelete: () -> Void

    var height: CGFloat {
        width / ratio
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: action) {
                ZStack {
                    if let img = image {
                        Image(nsImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: width, height: height)
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.1))
                            .frame(width: width, height: height)
                            .overlay(
                                VStack(spacing: 8) {
                                    Text(placeholder)
                                        .font(.system(size: 40))
                                    if isCapturing {
                                        Text("截图中...")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            )
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(isCapturing)

            // 删除按钮（右上角，红色）
            if image != nil {
                Button(action: onDelete) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .frame(width: 18, height: 18)
                        .background(Circle().fill(Color.red))
                }
                .buttonStyle(.plain)
                .padding(8)
            }
        }
        .frame(width: width, height: height)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
        )
    }
}

extension UTType {
    static var png: UTType {
        UTType(filenameExtension: "png") ?? UTType.data
    }
}
