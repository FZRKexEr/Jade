#!/bin/bash
#
# notarize.sh - 应用公证脚本
#
# 用法:
#   ./notarize.sh --app-path /path/to/ChineseChess.app --team-id TEAM_ID --apple-id apple@id.com
#

set -e

# 配置
APP_PATH=""
TEAM_ID=""
APPLE_ID=""
APP_SPECIFIC_PASSWORD=""
BUNDLE_ID="com.chinesechess.app"
NOTARIZE_ZIP=""

# 解析命令行参数
while [[ $# -gt 0 ]]; do
  case $1 in
    --app-path)
      APP_PATH="$2"
      shift 2
      ;;
    --team-id)
      TEAM_ID="$2"
      shift 2
      ;;
    --apple-id)
      APPLE_ID="$2"
      shift 2
      ;;
    --password)
      APP_SPECIFIC_PASSWORD="$2"
      shift 2
      ;;
    --bundle-id)
      BUNDLE_ID="$2"
      shift 2
      ;;
    --help)
      echo "用法: $0 [选项]"
      echo ""
      echo "选项:"
      echo "  --app-path PATH          应用程序路径 (必需)"
      echo "  --team-id ID             Apple 团队 ID (必需)"
      echo "  --apple-id ID            Apple ID 邮箱 (必需)"
      echo "  --password PASSWORD      应用专用密码 (可选, 会提示输入)"
      echo "  --bundle-id ID           Bundle ID (默认: com.chinesechess.app)"
      echo "  --help                   显示此帮助信息"
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

if [[ -z "$TEAM_ID" ]]; then
  echo "错误: 缺少 --team-id 参数"
  exit 1
fi

if [[ -z "$APPLE_ID" ]]; then
  echo "错误: 缺少 --apple-id 参数"
  exit 1
fi

# 检查应用是否存在
if [[ ! -d "$APP_PATH" ]]; then
  echo "错误: 应用程序不存在: $APP_PATH"
  exit 1
fi

# 获取应用信息
APP_BUNDLE_ID=$(defaults read "$APP_PATH/Contents/Info.plist" CFBundleIdentifier 2>/dev/null || echo "$BUNDLE_ID")
APP_VERSION=$(defaults read "$APP_PATH/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "unknown")

echo "========================================="
echo "应用公证"
echo "========================================="
echo "应用: $APP_PATH"
echo "Bundle ID: $APP_BUNDLE_ID"
echo "版本: $APP_VERSION"
echo "团队 ID: $TEAM_ID"
echo "Apple ID: $APPLE_ID"
echo ""

# 提示输入密码（如果没有提供）
if [[ -z "$APP_SPECIFIC_PASSWORD" ]]; then
  echo "请输入应用专用密码:"
  read -s APP_SPECIFIC_PASSWORD
  echo ""
fi

# 创建临时目录
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# 创建 zip 文件用于公证
echo "步骤 1/4: 创建 zip 文件..."
NOTARIZE_ZIP="$TEMP_DIR/$APP_BUNDLE_ID.zip"
ditto -c -k --keepParent "$APP_PATH" "$NOTARIZE_ZIP"

echo "  Zip 文件: $NOTARIZE_ZIP"
echo "  大小: $(du -h "$NOTARIZE_ZIP" | cut -f1)"

# 提交公证
echo ""
echo "步骤 2/4: 提交公证..."
NOTARY_OUTPUT=$(xcrun notarytool submit "$NOTARIZE_ZIP" \
  --apple-id "$APPLE_ID" \
  --team-id "$TEAM_ID" \
  --password "$APP_SPECIFIC_PASSWORD" \
  --wait 2>&1)

# 获取提交 ID
SUBMISSION_ID=$(echo "$NOTARY_OUTPUT" | grep "id:" | awk '{print $2}' | head -1)

echo "$NOTARY_OUTPUT"

# 检查公证状态
if echo "$NOTARY_OUTPUT" | grep -q "status: Accepted"; then
  echo ""
  echo "✓ 公证成功!"
elif echo "$NOTARY_OUTPUT" | grep -q "status: Invalid"; then
  echo ""
  echo "✗ 公证失败"
  echo ""
  echo "错误日志:"
  xcrun notarytool log "$SUBMISSION_ID" \
    --apple-id "$APPLE_ID" \
    --team-id "$TEAM_ID" \
    --password "$APP_SPECIFIC_PASSWORD"
  exit 1
else
  echo ""
  echo "警告: 无法确定公证状态"
fi

# 装订票据
echo ""
echo "步骤 3/4: 装订公证票据..."
xcrun stapler staple "$APP_PATH"
echo "✓ 票据装订完成"

# 验证公证
echo ""
echo "步骤 4/4: 验证公证..."
echo ""
echo "代码签名验证:"
codesign -dv --verbose=4 "$APP_PATH" 2>&1 | grep -E "(Signature|Authority|TeamIdentifier)" || true

echo ""
echo "公证验证:"
spctl -a -t exec -vv "$APP_PATH" 2>&1 || true

echo ""
echo "========================================="
echo "公证完成!"
echo "========================================="
echo "应用: $APP_PATH"
echo "版本: $APP_VERSION"
echo ""
echo "应用现在可以分发给其他用户了。"
echo ""
