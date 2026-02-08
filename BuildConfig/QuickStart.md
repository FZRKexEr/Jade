# Quick Start - 构建和发布指南

快速开始指南，帮助您快速构建和发布 ChineseChess 应用。

## 环境要求

- macOS 14.0+
- Xcode 15.0+
- Swift 5.9+
- Apple Developer Account（用于分发）

## 快速构建（开发）

### 1. 克隆仓库

```bash
git clone https://github.com/yourorg/chinesechess.git
cd chinesechess
```

### 2. 快速构建（无签名）

```bash
./Scripts/build-and-sign.sh
```

这将在 `build/Export/ChineseChess.app` 创建未签名的应用。

### 3. 运行应用

```bash
open build/Export/ChineseChess.app
```

**注意**: 未签名的应用只能在开发者机器上运行。

## 签名构建（测试分发）

### 1. 配置开发者证书

在 Xcode 中:
1. 打开 `ChineseChess.xcodeproj`
2. 选择项目 -> Targets -> ChineseChess
3. 在 Signing & Capabilities 中选择你的团队

### 2. 使用开发者证书构建

```bash
export CODE_SIGN_IDENTITY="Apple Development: your@email.com"
export DEVELOPMENT_TEAM="YOUR_TEAM_ID"

./Scripts/build-and-sign.sh
```

## 正式分发构建

### 1. 准备证书

需要以下证书:
- **Developer ID Application**: 用于 DMG 分发

在 [Apple Developer Portal](https://developer.apple.com/account/) 创建并下载证书。

### 2. 配置环境变量

```bash
export CODE_SIGN_IDENTITY="Developer ID Application: Your Name"
export DEVELOPMENT_TEAM="YOUR_TEAM_ID"
export APPLE_ID="your@email.com"
export APPLE_TEAM_ID="YOUR_TEAM_ID"
export APPLE_APP_SPECIFIC_PASSWORD="xxxx-xxxx-xxxx-xxxx"
```

### 3. 完整构建流程

```bash
# 构建并签名
./Scripts/build-and-sign.sh

# 公证 (可选，但推荐)
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

## CI/CD 构建

### GitHub Actions

项目已配置 GitHub Actions 工作流:

1. **Push 到 main 分支**: 自动构建和测试
2. **创建 Release**: 自动构建、签名、公证并发布

查看 `.github/workflows/` 目录了解详情。

### 配置 Secrets

在 GitHub 仓库设置中添加以下 Secrets:

- `BUILD_CERTIFICATE_BASE64`: Base64 编码的 .p12 证书
- `P12_PASSWORD`: 证书密码
- `KEYCHAIN_PASSWORD`: 临时钥匙串密码
- `DEVELOPMENT_TEAM`: 开发团队 ID
- `CODE_SIGN_IDENTITY`: 签名身份
- `APPLE_ID`: Apple ID
- `APPLE_TEAM_ID`: Apple 团队 ID
- `APPLE_APP_SPECIFIC_PASSWORD`: 应用专用密码

## 故障排除

### 构建失败

```bash
# 清理构建缓存
rm -rf build/
rm -rf .build/
rm -rf ~/Library/Developer/Xcode/DerivedData/ChineseChess-*/

# 重新构建
./Scripts/build-and-sign.sh
```

### 签名错误

```bash
# 检查证书
security find-identity -v -p codesigning

# 重置签名
xattr -cr build/Export/ChineseChess.app
codesign --force --deep --sign "Developer ID Application: Your Name" build/Export/ChineseChess.app
```

### 公证失败

```bash
# 查看详细错误
xcrun notarytool log <submission-id> \
  --apple-id "your@email.com" \
  --team-id "TEAM_ID" \
  --password "password"
```

## 更多信息

- [代码签名配置指南](CodeSigning.md)
- [Apple Code Signing Guide](https://developer.apple.com/library/archive/documentation/Security/Conceptual/CodeSigningGuide/)
- [Notarizing macOS Software](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
