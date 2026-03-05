//
//  DarkLightJointApp.swift
//  Dark Light Joint
//
//  截图拼接工具 - macOS 原生应用
//

import SwiftUI

@main
struct DarkLightJointApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}
