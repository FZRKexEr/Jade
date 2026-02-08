# 代码签名配置指南

本文档说明如何配置 ChineseChess 应用的代码签名。

## 开发签名 (本地开发)

对于本地开发，可以不进行代码签名，或者使用免费的开发者证书。

### 使用未签名模式

```bash
# 构建时不签名
./Scripts/build-and-sign.sh
```

注意：未签名的应用只能在开发者机器上运行，不能分发给其他用户。

### 使用个人开发者证书

1. 在 Xcode 中登录 Apple ID
2. 创建个人证书
3. 设置环境变量：

```bash
export CODE_SIGN_IDENTITY="Apple Development: your@email.com"
export DEVELOPMENT_TEAM="YOUR_TEAM_ID"

./Scripts/build-and-sign.sh
```

## 分发签名 (App Store / DMG 分发)

要分发给其他用户，需要使用 Apple Developer Program 的证书。

### 所需证书类型

1. **Developer ID Application**: 用于 DMG 分发（推荐）
2. **Mac App Distribution**: 用于 Mac App Store
3. **Mac Installer Distribution**: 用于 Mac App Store 安装包

### 创建 Developer ID 证书

1. 访问 [Apple Developer Portal](https://developer.apple.com/account/)
2. 进入 Certificates, Identifiers & Profiles
3. 点击 "+" 创建新证书
4. 选择 "Developer ID Application"
5. 上传 Certificate Signing Request (CSR)
6. 下载并安装证书

### 配置 CI/CD 签名

对于 GitHub Actions，需要在仓库 Secrets 中设置：

1. **BUILD_CERTIFICATE_BASE64**: Base64 编码的 .p12 证书文件
2. **P12_PASSWORD**: .p12 文件的密码
3. **KEYCHAIN_PASSWORD**: 临时钥匙串密码（任意值）
4. **DEVELOPMENT_TEAM**: 开发团队 ID
5. **CODE_SIGN_IDENTITY**: 签名身份 (如 "Developer ID Application: Your Name")

#### 准备 Base64 证书

```bash
# 导出证书为 .p12
# 在 Keychain Access 中右键证书 -> 导出

# 转换为 Base64
base64 -i certificate.p12 -o certificate.base64

# 复制到 GitHub Secrets
cat certificate.base64 | pbcopy
```

### 本地使用 Developer ID 签名

```bash
# 设置环境变量
export CODE_SIGN_IDENTITY="Developer ID Application: Your Name"
export DEVELOPMENT_TEAM="YOUR_TEAM_ID"
export DEVELOPER_ID_APPLICATION="Developer ID Application: Your Name (TEAM_ID)"

# 构建并签名
./Scripts/build-and-sign.sh

# 验证签名
codesign -dv --verbose=4 build/Export/ChineseChess.app

# 验证公证 (如果已公证)
spctl -a -t exec -vv build/Export/ChineseChess.app
```

## 公证 (Notarization)

macOS 10.15+ 要求所有分发的应用必须经过 Apple 公证。

### 使用命令行公证

```bash
# 创建 zip 进行公证
zip -r ChineseChess.zip build/Export/ChineseChess.app

# 提交公证
xcrun notarytool submit ChineseChess.zip \
  --apple-id "your@email.com" \
  --team-id "TEAM_ID" \
  --password "app-specific-password" \
  --wait

# 装订票据
xcrun stapler staple build/Export/ChineseChess.app

# 验证
spctl -a -t exec -vv build/Export/ChineseChess.app
```

### 在 CI/CD 中配置公证

在 GitHub Secrets 中设置：
- **APPLE_ID**: Apple ID 邮箱
- **APPLE_TEAM_ID**: 团队 ID
- **APPLE_APP_SPECIFIC_PASSWORD**: 应用专用密码

## 故障排除

### 签名验证失败

```bash
# 检查签名
codesign -dv --verbose=4 ChineseChess.app

# 检查证书有效性
security find-identity -v -p codesigning

# 重置签名
xattr -cr ChineseChess.app
codesign --force --deep --sign "Developer ID Application: Your Name" ChineseChess.app
```

### 公证失败

```bash
# 查看公证日志
xcrun notarytool log <submission-id> \
  --apple-id "your@email.com" \
  --team-id "TEAM_ID" \
  --password "password"

# 检查 hardened runtime
spctl -vv --assess --type exec ChineseChess.app
```

### 缺少 entitlements

确保 `ChineseChess.entitlements` 包含所有需要的权限：
- `com.apple.security.cs.allow-jit`: 允许 JIT 编译
- `com.apple.security.files.user-selected.read-write`: 文件访问
- `com.apple.security.network.client`: 网络客户端

## 相关文档

- [Apple Code Signing Guide](https://developer.apple.com/library/archive/documentation/Security/Conceptual/CodeSigningGuide/)
- [Notarizing macOS Software](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
- [Hardened Runtime](https://developer.apple.com/documentation/security/hardened_runtime)
