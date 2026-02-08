#!/bin/bash
#
# create-dmg.sh - 创建中国象棋 macOS 应用的 DMG 安装包
#
# 用法:
#   ./create-dmg.sh --app-path /path/to/ChineseChess.app --output-path /path/to/output.dmg --version 1.0.0
#

set -e

# 默认配置
APP_PATH=""
OUTPUT_PATH=""
VERSION="1.0.0"
APP_NAME="ChineseChess"
VOLUME_NAME="ChineseChess ${VERSION}"
BACKGROUND_IMAGE=""

# 解析命令行参数
while [[ $# -gt 0 ]]; do
  case $1 in
    --app-path)
      APP_PATH="$2"
      shift 2
      ;;
    --output-path)
      OUTPUT_PATH="$2"
      shift 2
      ;;
    --version)
      VERSION="$2"
      shift 2
      ;;
    --background)
      BACKGROUND_IMAGE="$2"
      shift 2
      ;;
    --help)
      echo "用法: $0 [选项]"
      echo ""
      echo "选项:"
      echo "  --app-path PATH      应用程序路径 (必需)"
      echo "  --output-path PATH   输出 DMG 路径 (必需)"
      echo "  --version VERSION    版本号 (默认: 1.0.0)"
      echo "  --background PATH    背景图片路径 (可选)"
      echo "  --help               显示此帮助信息"
      exit 0
      ;;
    *)
      echo "未知选项: $1"
      echo "使用 --help 查看帮助"
      exit 1
      ;;
  esac
done

# 验证必需参数
if [[ -z "$APP_PATH" ]]; then
  echo "错误: 缺少 --app-path 参数"
  exit 1
fi

if [[ -z "$OUTPUT_PATH" ]]; then
  echo "错误: 缺少 --output-path 参数"
  exit 1
fi

# 检查应用程序是否存在
if [[ ! -d "$APP_PATH" ]]; then
  echo "错误: 应用程序不存在: $APP_PATH"
  exit 1
fi

echo "========================================="
echo "创建 DMG 安装包"
echo "========================================="
echo "应用程序: $APP_PATH"
echo "输出路径: $OUTPUT_PATH"
echo "版本号: $VERSION"
echo ""

# 创建工作目录
WORK_DIR=$(mktemp -d)
MOUNT_DIR="$WORK_DIR/mount"
DMG_TEMP="$WORK_DIR/temp.dmg"

echo "步骤 1/7: 创建工作目录..."
mkdir -p "$MOUNT_DIR"

# 计算 DMG 大小
APP_SIZE=$(du -sm "$APP_PATH" | cut -f1)
# 增加额外空间用于窗口样式和链接
DMG_SIZE=$((APP_SIZE + 50))

echo "步骤 2/7: 创建临时 DMG (大小: ${DMG_SIZE}MB)..."
hdiutil create \
  -srcfolder "$APP_PATH" \
  -volname "$VOLUME_NAME" \
  -fs HFS+ \
  -format UDRW \
  -size "${DMG_SIZE}m" \
  "$DMG_TEMP"

echo "步骤 3/7: 挂载 DMG..."
hdiutil attach "$DMG_TEMP" -nobrowse -noverify -noautoopen -mountpoint "$MOUNT_DIR"

# 创建 Applications 链接
echo "步骤 4/7: 配置 DMG 布局..."
ln -s /Applications "$MOUNT_DIR/Applications"

# 设置 DMG 窗口样式
if [[ -f "$BACKGROUND_IMAGE" ]]; then
  echo "  使用自定义背景图片..."
  mkdir -p "$MOUNT_DIR/.background"
  cp "$BACKGROUND_IMAGE" "$MOUNT_DIR/.background/background.png"

  osascript <<EOF
  tell application "Finder"
    tell disk "$VOLUME_NAME"
      open
      set current view of container window to icon view
      set toolbar visible of container window to false
      set statusbar visible of container window to false
      set the bounds of container window to {100, 100, 600, 500}
      set viewOptions to icon view options of container window
      set arrangement of viewOptions to not arranged
      set icon size of viewOptions to 128
      set background picture of viewOptions to POSIX file "$MOUNT_DIR/.background/background.png"
      set position of item "ChineseChess.app" of container window to {150, 200}
      set position of item "Applications" of container window to {400, 200}
      close
      open
      update without registering applications
      delay 2
    end tell
  end tell
EOF
else
  echo "  使用默认布局..."
  osascript <<EOF
  tell application "Finder"
    tell disk "$VOLUME_NAME"
      open
      set current view of container window to icon view
      set toolbar visible of container window to false
      set statusbar visible of container window to false
      set the bounds of container window to {100, 100, 600, 500}
      set viewOptions to icon view options of container window
      set arrangement of viewOptions to not arranged
      set icon size of viewOptions to 128
      set position of item "ChineseChess.app" of container window to {150, 200}
      set position of item "Applications" of container window to {400, 200}
      close
      open
      update without registering applications
      delay 2
    end tell
  end tell
EOF
fi

echo "步骤 5/7: 卸载 DMG..."
hdiutil detach "$MOUNT_DIR" -force -quiet

echo "步骤 6/7: 压缩 DMG..."
# 压缩为只读格式
hdiutil convert "$DMG_TEMP" -format UDZO -imagekey zlib-level=9 -o "$OUTPUT_PATH"

echo "步骤 7/7: 计算校验和..."
DMG_CHECKSUM=$(shasum -a 256 "$OUTPUT_PATH" | awk '{ print $1 }')
echo "SHA256: $DMG_CHECKSUM"

# 清理
rm -rf "$WORK_DIR"

echo ""
echo "========================================="
echo "DMG 创建成功!"
echo "========================================="
echo "文件: $OUTPUT_PATH"
echo "大小: $(du -h "$OUTPUT_PATH" | cut -f1)"
echo "SHA256: $DMG_CHECKSUM"
echo ""
