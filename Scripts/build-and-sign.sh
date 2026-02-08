#!/bin/bash
#
# build-and-sign.sh - 本地构建和签名脚本 (使用 Swift Package Manager)
#
# 用于本地开发时构建、签名和创建 DMG
#

set -e

# 配置
APP_NAME="ChineseChess"
BUNDLE_ID="com.chinesechess.app"
VERSION=$(cat VERSION 2>/dev/null || echo "1.0.0")
BUILD_DIR="build"
APP_PATH="$BUILD_DIR/$APP_NAME.app"
DMG_PATH="$BUILD_DIR/$APP_NAME-$VERSION.dmg"

# 代码签名配置（本地开发时使用 - 表示不签名或使用开发者证书）
CODE_SIGN_IDENTITY=${CODE_SIGN_IDENTITY:--}

# Swift Package Manager 生成的 .app 路径
SPM_BUILD_PATH=".build/release/$APP_NAME.app"
SPM_DEBUG_BUILD_PATH=".build/debug/$APP_NAME.app"

echo "========================================="
echo "ChineseChess 构建脚本 (SPM)"
echo "========================================="
echo "版本: $VERSION"
echo "应用名称: $APP_NAME"
echo "Bundle ID: $BUNDLE_ID"
echo "代码签名: $CODE_SIGN_IDENTITY"
echo ""

# 清理旧构建
echo "步骤 1/5: 清理旧构建..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
# 清理 SPM 缓存
swift package clean

# 解析依赖
echo "步骤 2/5: 解析 Swift 包依赖..."
swift package resolve

# 构建应用
echo "步骤 3/5: 构建应用..."
# 使用 SPM 构建 Release 版本
swift build -c release

# 检查构建输出
if [ -d "$SPM_BUILD_PATH" ]; then
    echo "找到 SPM 构建的 .app 包: $SPM_BUILD_PATH"
    cp -R "$SPM_BUILD_PATH" "$APP_PATH"
elif [ -d "$SPM_DEBUG_BUILD_PATH" ]; then
    echo "找到 SPM 构建的 debug .app 包: $SPM_DEBUG_BUILD_PATH"
    cp -R "$SPM_DEBUG_BUILD_PATH" "$APP_PATH"
else
    # 对于 executableTarget，SPM 可能只生成二进制文件
    SPM_BINARY=".build/release/$APP_NAME"
    if [ -f "$SPM_BINARY" ]; then
        echo "找到 SPM 构建的二进制文件: $SPM_BINARY"
        echo "创建 .app 包..."
        # 创建基本的 .app 包结构
        mkdir -p "$APP_PATH/Contents/MacOS"
        mkdir -p "$APP_PATH/Contents/Resources"
        cp "$SPM_BINARY" "$APP_PATH/Contents/MacOS/"

        # 创建 Info.plist
        cat > "$APP_PATH/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

        # 复制资源文件
        if [ -d "Resources" ]; then
            cp -R Resources/* "$APP_PATH/Contents/Resources/" 2>/dev/null || true
        fi
    else
        echo "错误: 找不到构建输出"
        exit 1
    fi
fi

# 代码签名
echo "步骤 4/5: 代码签名..."
if [[ "$CODE_SIGN_IDENTITY" != "-" ]]; then
    echo "使用证书签名: $CODE_SIGN_IDENTITY"
    codesign --force --sign "$CODE_SIGN_IDENTITY" --entitlements Config/ChineseChess.entitlements "$APP_PATH"
    codesign -dv --verbose=4 "$APP_PATH"
else
    echo "使用临时签名..."
    codesign --force --sign - --entitlements Config/ChineseChess.entitlements "$APP_PATH" 2>/dev/null || true
fi

# 创建 DMG
echo "步骤 5/5: 创建 DMG 安装包..."
./Scripts/create-dmg.sh \
    --app-path "$APP_PATH" \
    --output-path "$DMG_PATH" \
    --version "$VERSION"

# 显示结果
echo ""
echo "========================================="
echo "构建完成!"
echo "========================================="
echo "应用路径: $APP_PATH"
echo "DMG 路径: $DMG_PATH"
if [ -f "$DMG_PATH" ]; then
    echo "文件大小: $(du -h "$DMG_PATH" | cut -f1)"
    echo "SHA256: $(shasum -a 256 "$DMG_PATH" | awk '{ print $1 }')"
fi
echo ""
echo "签名状态:"
codesign -vv "$APP_PATH" 2>&1 | head -3 || echo "  未签名"
