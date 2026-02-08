#!/bin/bash
#
# install.sh - ChineseChess 安装脚本
#
# 用于从 DMG 安装应用
#

set -e

APP_NAME="ChineseChess"
APP_BUNDLE="ChineseChess.app"
INSTALL_DIR="/Applications"
SOURCE_DMG=""

echo "========================================="
echo "ChineseChess 安装程序"
echo "========================================="
echo ""

# 检查参数
if [[ $# -eq 0 ]]; then
    # 查找当前目录的 DMG
    DMG_FILES=(*.dmg)
    if [[ -f "${DMG_FILES[0]}" ]]; then
        SOURCE_DMG="${DMG_FILES[0]}"
        echo "找到 DMG: $SOURCE_DMG"
    else
        echo "用法: $0 <path/to/ChineseChess-x.x.x.dmg>"
        echo ""
        echo "或者将 DMG 文件放在当前目录"
        exit 1
    fi
else
    SOURCE_DMG="$1"
fi

# 验证 DMG 存在
if [[ ! -f "$SOURCE_DMG" ]]; then
    echo "错误: 找不到 DMG 文件: $SOURCE_DMG"
    exit 1
fi

echo "DMG 文件: $SOURCE_DMG"
echo "安装目录: $INSTALL_DIR"
echo ""

# 检查是否已安装
if [[ -d "$INSTALL_DIR/$APP_BUNDLE" ]]; then
    echo "⚠️ 应用已存在: $INSTALL_DIR/$APP_BUNDLE"
    read -p "是否覆盖安装? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "安装已取消"
        exit 0
    fi
    echo "删除旧版本..."
    rm -rf "$INSTALL_DIR/$APP_BUNDLE"
fi

# 挂载 DMG
echo "挂载 DMG..."
MOUNT_OUTPUT=$(hdiutil attach "$SOURCE_DMG" -nobrowse -noverify -noautoopen 2>&1)
MOUNT_POINT=$(echo "$MOUNT_OUTPUT" | grep -o '/Volumes/.*$' | head -1)

if [[ -z "$MOUNT_POINT" ]]; then
    echo "错误: 无法挂载 DMG"
    echo "$MOUNT_OUTPUT"
    exit 1
fi

echo "挂载点: $MOUNT_POINT"

# 复制应用
echo "复制应用到 $INSTALL_DIR..."
if [[ -d "$MOUNT_POINT/$APP_BUNDLE" ]]; then
    cp -R "$MOUNT_POINT/$APP_BUNDLE" "$INSTALL_DIR/"
else
    echo "错误: DMG 中找不到 $APP_BUNDLE"
    hdiutil detach "$MOUNT_POINT" -quiet
    exit 1
fi

# 卸载 DMG
echo "卸载 DMG..."
hdiutil detach "$MOUNT_POINT" -quiet

# 验证安装
echo ""
echo "验证安装..."
if [[ -d "$INSTALL_DIR/$APP_BUNDLE" ]]; then
    INSTALLED_VERSION=$(defaults read "$INSTALL_DIR/$APP_BUNDLE/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "未知")
    echo "✓ 安装成功!"
    echo ""
    echo "应用: $INSTALL_DIR/$APP_BUNDLE"
    echo "版本: $INSTALLED_VERSION"
    echo ""
    echo "启动应用:"
    echo "  open '$INSTALL_DIR/$APP_BUNDLE'"
    echo ""
else
    echo "✗ 安装失败"
    exit 1
fi

# 检查首次运行注意事项
echo ""
echo "========================================="
echo "重要提示"
echo "========================================="
echo ""
echo "如果首次运行时出现安全警告:"
echo ""
echo "1. 前往 系统偏好设置 > 安全性与隐私"
echo "2. 点击 '仍要打开'"
echo ""
echo "或者按住 Control 键点击应用，选择 '打开'"
echo ""
echo "========================================="
