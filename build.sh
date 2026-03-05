#!/bin/bash
# 快速构建 Swift 应用

set -e

PROJECT_DIR="$HOME/m/dark-light-joint"
BUILD_DIR="$PROJECT_DIR/build"
APP_NAME="DarkLightJoint"

echo "🔨 构建 $APP_NAME..."

cd "$PROJECT_DIR"

# 创建构建目录
mkdir -p "$BUILD_DIR"

# 编译 Swift 文件
echo "📝 编译..."
swiftc -o "$BUILD_DIR/$APP_NAME" \
    -target x86_64-apple-macosx13.0 \
    -target arm64-apple-macosx13.0 \
    -O \
    DarkLightJointApp.swift \
    ContentView.swift \
    -framework SwiftUI \
    -framework AppKit \
    -framework UniformTypeIdentifiers

echo "✅ 构建成功！"
echo ""
echo "📂 可执行文件: $BUILD_DIR/$APP_NAME"
echo ""
echo "🚀 运行应用:"
echo "   $BUILD_DIR/$APP_NAME"
