#!/bin/bash
#
# generate-icons.sh - 生成应用图标
#
# 从源图像生成所有需要的图标尺寸
#

set -e

SOURCE_ICON="${1:-Assets/Icons/icon_source.png}"
OUTPUT_DIR="${2:-Resources/Assets.xcassets/AppIcon.appiconset}"

if [[ ! -f "$SOURCE_ICON" ]]; then
    echo "错误: 源图标不存在: $SOURCE_ICON"
    echo ""
    echo "用法: $0 [源图标路径] [输出目录]"
    echo ""
    echo "请提供一个 1024x1024 的 PNG 图像作为源图标。"
    exit 1
fi

# 创建输出目录
mkdir -p "$OUTPUT_DIR"

# 定义图标尺寸
# 格式: "文件名 尺寸"
ICONS=(
    "icon_16x16.png 16"
    "icon_16x16@2x.png 32"
    "icon_32x32.png 32"
    "icon_32x32@2x.png 64"
    "icon_128x128.png 128"
    "icon_128x128@2x.png 256"
    "icon_256x256.png 256"
    "icon_256x256@2x.png 512"
    "icon_512x512.png 512"
    "icon_512x512@2x.png 1024"
)

echo "========================================="
echo "生成应用图标"
echo "========================================="
echo "源图标: $SOURCE_ICON"
echo "输出目录: $OUTPUT_DIR"
echo ""

# 检查 sips 或 ImageMagick
if command -v sips &> /dev/null; then
    USE_SIPS=true
    echo "使用 sips 处理图像"
elif command -v convert &> /dev/null; then
    USE_SIPS=false
    echo "使用 ImageMagick 处理图像"
else
    echo "错误: 需要 sips (macOS) 或 ImageMagick 来处理图像"
    exit 1
fi

echo ""

# 生成图标
for icon_info in "${ICONS[@]}"; do
    filename=$(echo "$icon_info" | cut -d' ' -f1)
    size=$(echo "$icon_info" | cut -d' ' -f2)

    output_file="$OUTPUT_DIR/$filename"

    echo "生成 $filename (${size}x${size})..."

    if [[ "$USE_SIPS" == true ]]; then
        sips -z "$size" "$size" "$SOURCE_ICON" --out "$output_file" > /dev/null 2>&1
    else
        convert "$SOURCE_ICON" -resize "${size}x${size}" "$output_file"
    fi
done

echo ""
echo "========================================="
echo "图标生成完成!"
echo "========================================="
echo "输出目录: $OUTPUT_DIR"
echo ""
echo "生成的文件:"
ls -lh "$OUTPUT_DIR"
echo ""

# 验证图标数量
ICON_COUNT=$(ls "$OUTPUT_DIR"/*.png 2> /dev/null | wc -l)
if [[ "$ICON_COUNT" -eq 10 ]]; then
    echo "✓ 所有 10 个图标已生成"
else
    echo "警告: 预期生成 10 个图标，实际生成 $ICON_COUNT 个"
fi
