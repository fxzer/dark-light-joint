#!/bin/bash
# 将应用安装到 /Applications/ 文件夹

set -e

PROJECT_DIR="$HOME/m/dark-light-joint"
BUILD_DIR="$PROJECT_DIR/build"
APP_NAME="DarkLightJoint"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
APP_DEST="/Applications/$APP_NAME.app"

echo "📦 安装 DarkLightJoint 到应用程序文件夹..."

# 检查应用是否存在
if [ ! -d "$APP_BUNDLE" ]; then
    echo "❌ 应用不存在，请先运行: ./create_app.sh"
    exit 1
fi

# 删除旧版本（如果存在）
if [ -d "$APP_DEST" ]; then
    echo "🗑️  删除旧版本..."
    rm -rf "$APP_DEST"
fi

# 复制应用
echo "📋 复制应用..."
cp -R "$APP_BUNDLE" "$APP_DEST"

echo ""
echo "✅ 安装完成！"
echo ""
echo "📂 应用位置: $APP_DEST"
echo ""
echo "💡 现在可以从启动台或 Spotlight 搜索「DarkLightJoint」启动应用"
echo ""
echo "🚀 立即运行?"
echo "   open \"$APP_DEST\""
