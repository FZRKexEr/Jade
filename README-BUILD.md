# ChineseChess 构建和发布指南

本指南说明如何构建、签名、公证和发布 ChineseChess macOS 应用。

## 目录

- [快速开始](#快速开始)
- [环境要求](#环境要求)
- [项目结构](#项目结构)
- [构建流程](#构建流程)
- [代码签名](#代码签名)
- [公证](#公证)
- [发布](#发布)
- [CI/CD](#cicd)
- [故障排除](#故障排除)

## 快速开始

### 开发构建（无签名）

```bash
# 克隆仓库
git clone https://github.com/yourorg/chinesechess.git
cd chinesechess

# 构建
./Scripts/build-and-sign.sh

# 运行
open build/Export/ChineseChess.app
```

### 分发构建（带签名和公证）

```bash
# 设置环境变量
export CODE_SIGN_IDENTITY="Developer ID Application: Your Name"
export DEVELOPMENT_TEAM="YOUR_TEAM_ID"
export APPLE_ID="your@email.com"
export APPLE_TEAM_ID="YOUR_TEAM_ID"
export APPLE_APP_SPECIFIC_PASSWORD="your-app-specific-password"

# 构建
./Scripts/build-and-sign.sh

# 公证
./Scripts/notarize.sh \
  --app-path build/Export/ChineseChess.app \
  --team-id "$APPLE_TEAM_ID" \
  --apple-id "$APPLE_ID" \
  --password "$APPLE_APP_SPECIFIC_PASSWORD"

# 创建 DMG
./Scripts/create-dmg.sh \
  --app-path build/Export/ChineseChess.app \
  --output-path build/ChineseChess-1.0.0.dmg \
  --version "1.0.0"
```

## 环境要求

### 必需

- macOS 14.0 或更高版本
- Xcode 15.0 或更高版本
- Swift 5.9 或更高版本
- 至少 10 GB 可用磁盘空间

### 可选（用于分发）

- Apple Developer Program 会员资格
- 有效的 Developer ID 证书
- Apple ID 和应用程序专用密码

## 项目结构

```
ChineseChess/
├── ChineseChess.xcodeproj/      # Xcode 项目
├── Sources/                      # 源代码
│   ├── App/                      # 应用入口
│   ├── ChineseChess/             # 主程序
│   ├── Configuration/            # 配置模块
│   ├── Domain/                   # 领域模型
│   ├── Engine/                   # 引擎模块
│   ├── Game/                     # 游戏逻辑
│   ├── Infrastructure/           # 基础设施
│   ├── Presentation/             # 表示层
│   └── Tests/                    # 测试
├── Resources/                    # 资源文件
│   ├── Assets.xcassets/          # 图标和颜色
│   └── Help/                     # 帮助文档
├── Config/                       # 配置文件
│   ├── Info.plist                # 应用信息
│   └── ChineseChess.entitlements  # 权限配置
├── Scripts/                      # 构建脚本
│   ├── build-and-sign.sh         # 构建和签名
│   ├── create-dmg.sh             # 创建 DMG
│   ├── notarize.sh               # 公证
│   ├── install.sh                # 安装
│   └── generate-icons.sh         # 生成图标
├── BuildConfig/                  # 构建设置
│   ├── Debug.xcconfig            # Debug 配置
│   ├── Release.xcconfig          # Release 配置
│   ├── Archive.xcconfig          # Archive 配置
│   ├── CodeSigning.md            # 代码签名指南
│   ├── Entitlements.md           # 权限配置指南
│   └── QuickStart.md             # 快速开始
├── .github/
│   └── workflows/                # GitHub Actions
│       ├── build.yml             # 构建工作流
│       ├── test.yml              # 测试工作流
│       ├── release.yml           # 发布工作流
│       └── distribute.yml        # 分发工作流
└── Package.swift                 # Swift Package Manager
```

## 构建流程

### 1. 开发构建

用于日常开发和测试：

```bash
# 构建 Debug 版本
xcodebuild -project ChineseChess.xcodeproj \
           -scheme ChineseChess \
           -configuration Debug \
           -destination 'platform=macOS' \
           build
```

### 2. 发布构建

用于分发：

```bash
# 构建 Release 版本
xcodebuild -project ChineseChess.xcodeproj \
           -scheme ChineseChess \
           -configuration Release \
           -destination 'platform=macOS' \
           build
```

### 3. 归档构建

用于 App Store 或完整分发：

```bash
# 创建归档
xcodebuild -project ChineseChess.xcodeproj \
           -scheme ChineseChess \
           -configuration Release \
           -archivePath build/ChineseChess.xcarchive \
           archive

# 导出
xcodebuild -exportArchive \
           -archivePath build/ChineseChess.xcarchive \
           -exportPath build/Export \
           -exportOptionsPlist ExportOptions.plist
```

## 代码签名

### 开发签名

使用自动签名（推荐用于开发）：

```bash
codesign --force --deep --sign "-" build/Debug/ChineseChess.app
```

### 分发签名

使用 Developer ID 证书：

```bash
codesign --force --deep --sign "Developer ID Application: Your Name" \
         --options runtime \
         --entitlements Config/ChineseChess.entitlements \
         build/Export/ChineseChess.app
```

### 验证签名

```bash
# 检查签名
codesign -dv --verbose=4 build/Export/ChineseChess.app

# 验证签名有效性
codesign --verify --verbose=4 build/Export/ChineseChess.app

# 检查 hardened runtime
spctl -a -t exec -vv build/Export/ChineseChess.app
```

## 公证

### 前提条件

- Apple Developer ID
- 应用专用密码

### 公证步骤

```bash
# 1. 创建 zip
ditto -c -k --keepParent build/Export/ChineseChess.app ChineseChess.zip

# 2. 提交公证
xcrun notarytool submit ChineseChess.zip \
  --apple-id "your@email.com" \
  --team-id "TEAM_ID" \
  --password "app-specific-password" \
  --wait

# 3. 装订票据
xcrun stapler staple build/Export/ChineseChess.app

# 4. 验证
spctl -a -t exec -vv build/Export/ChineseChess.app
```

### 使用脚本

```bash
./Scripts/notarize.sh \
  --app-path build/Export/ChineseChess.app \
  --team-id "TEAM_ID" \
  --apple-id "your@email.com"
```

## 发布

### 创建 DMG

```bash
./Scripts/create-dmg.sh \
  --app-path build/Export/ChineseChess.app \
  --output-path build/ChineseChess-1.0.0.dmg \
  --version "1.0.0"
```

### 创建 GitHub Release

```bash
# 创建 tag
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0

# GitHub CLI 创建 release (需要安装 gh)
gh release create v1.0.0 \
  --title "ChineseChess 1.0.0" \
  --notes-file RELEASE_NOTES.md \
  build/ChineseChess-1.0.0.dmg
```

## CI/CD

### GitHub Actions

项目包含以下工作流：

- **build.yml**: Push 时自动构建
- **test.yml**: 运行单元测试和 UI 测试
- **release.yml**: 创建 tag 时自动发布
- **distribute.yml**: 手动触发分发

### 配置 Secrets

在 GitHub 仓库设置中配置以下 Secrets：

- `BUILD_CERTIFICATE_BASE64`
- `P12_PASSWORD`
- `KEYCHAIN_PASSWORD`
- `DEVELOPMENT_TEAM`
- `CODE_SIGN_IDENTITY`
- `APPLE_ID`
- `APPLE_TEAM_ID`
- `APPLE_APP_SPECIFIC_PASSWORD`

## 故障排除

### 常见问题

#### 签名失败

```bash
# 检查证书
security find-identity -v -p codesigning

# 重置钥匙串
security delete-keychain build.keychain 2>/dev/null || true

# 重新导入证书
security import certificate.p12 -k build.keychain -P "$PASSWORD" -T /usr/bin/codesign
```

#### 公证失败

```bash
# 检查 hardened runtime
codesign -dvv --entitlements - ChineseChess.app

# 重新签名并启用 hardened runtime
codesign --force --deep --sign "Developer ID Application" \
         --options runtime \
         --entitlements ChineseChess.entitlements \
         ChineseChess.app
```

#### DMG 创建失败

```bash
# 手动创建 DMG
hdiutil create -srcfolder ChineseChess.app -volname "ChineseChess" \
               -fs HFS+ -format UDZO \
               ChineseChess.dmg
```

### 获取帮助

- 查看 `BuildConfig/` 目录中的详细文档
- 查看 GitHub Issues
- 联系开发团队

## 参考文档

- [Apple Code Signing Guide](https://developer.apple.com/library/archive/documentation/Security/Conceptual/CodeSigningGuide/)
- [Hardened Runtime](https://developer.apple.com/documentation/security/hardened_runtime)
- [Notarizing macOS Software](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
- [App Sandbox](https://developer.apple.com/documentation/security/app_sandbox)
