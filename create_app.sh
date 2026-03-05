#!/bin/bash
# 创建 .app 应用程序包（保留权限版本）

set -e

PROJECT_DIR="$HOME/m/dark-light-joint"
BUILD_DIR="$PROJECT_DIR/build"
APP_NAME="DarkLightJoint"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
BUNDLE_ID="com.darklight.joint"

echo "📦 创建/更新 .app 应用..."

cd "$PROJECT_DIR"

# 创建目录结构（首次运行时）
if [ ! -d "$APP_BUNDLE" ]; then
    echo "📁 首次创建应用..."
    mkdir -p "$CONTENTS/MacOS"
    mkdir -p "$CONTENTS/Resources"
fi

# 每次都更新 Info.plist（确保配置最新）
echo "📝 更新 Info.plist..."
cat > "$CONTENTS/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>DarkLightJoint</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleName</key>
    <string>DarkLightJoint</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSScreenCaptureDescription</key>
    <string>需要屏幕录制权限来截取屏幕内容。</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
</dict>
</plist>
EOF

# 复制可执行文件
if [ ! -f "$BUILD_DIR/$APP_NAME" ]; then
    echo "❌ 可执行文件不存在，先运行 build.sh"
    exit 1
fi

cp "$BUILD_DIR/$APP_NAME" "$CONTENTS/MacOS/"

# 复制图标文件
if [ -f "$PROJECT_DIR/AppIcon.icns" ]; then
    echo "🎨 添加应用图标..."
    cp "$PROJECT_DIR/AppIcon.icns" "$CONTENTS/Resources/"
fi

# 添加代码签名
echo "🔐 添加代码签名..."
codesign --force --deep --sign - "$APP_BUNDLE" 2>/dev/null || true

echo ""
echo "✅ 应用准备完成！"
echo ""
echo "📂 位置: $APP_BUNDLE"
echo ""
echo "📊 大小:"
du -sh "$APP_BUNDLE"
echo ""
echo "💡 权限设置提示："
echo ""
echo "   【首次使用】"
echo "   1. 运行应用"
echo "   2. 系统会弹出权限请求"
echo "   3. 点击「打开系统设置」"
echo "   4. 在「屏幕录制」中勾选 DarkLightJoint"
echo "   5. 重启应用"
echo ""
echo "   【永久解决权限问题】"
echo "   将应用拖到「应用程序」文件夹："
echo "   cp -R \"$APP_BUNDLE\" /Applications/"
echo ""
echo "🚀 运行:"
echo "   open \"$APP_BUNDLE\""
