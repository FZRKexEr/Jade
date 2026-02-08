# 权限和 Entitlements 配置

本文档说明 ChineseChess 应用所需的权限和 entitlements 配置。

## 当前 Entitlements 配置

位于 `Config/ChineseChess.entitlements`:

### 执行权限

```xml
<key>com.apple.security.cs.allow-jit</key>
<true/>
```

允许 JIT 编译，用于某些引擎计算。

### 文件访问权限

```xml
<key>com.apple.security.files.user-selected.read-write</key>
<true/>
```

允许用户选择的文件读写（打开/保存对话框）。

```xml
<key>com.apple.security.files.downloads.read-write</key>
<true/>
```

允许访问 Downloads 文件夹。

```xml
<key>com.apple.security.files.bookmarks.app-scope</key>
<true/>
<key>com.apple.security.files.bookmarks.document-scope</key>
<true/>
```

允许使用安全 scope bookmarks 持久化文件访问权限。

### 网络权限

```xml
<key>com.apple.security.network.client</key>
<true/>
```

允许出站网络连接（用于下载引擎、检查更新等）。

### 临时例外

```xml
<key>com.apple.security.temporary-exception.files.home-relative-path.read-write</key>
<array>
    <string>/Library/Caches/com.chinesechess.app/</string>
</array>
```

允许访问应用特定的缓存目录。

## 不需要的权限

以下权限当前**未启用**，因为应用不需要：

- `com.apple.security.device.audio-input`: 麦克风
- `com.apple.security.device.camera`: 摄像头
- `com.apple.security.device.bluetooth`: 蓝牙
- `com.apple.security.automation.apple-events`: Apple Events 自动化
- `com.apple.security.network.server`: 入站网络连接
- `com.apple.security.print`: 打印

## 自定义 entitlements

如果需要添加额外的 entitlements：

1. 编辑 `Config/ChineseChess.entitlements`
2. 参考 [Apple Entitlements 文档](https://developer.apple.com/documentation/bundleresources/entitlements)
3. 重新构建应用

## 验证 entitlements

```bash
# 查看应用的 entitlements
codesign -d --entitlements - build/Export/ChineseChess.app

# 查看详细的签名信息
codesign -dv --verbose=4 build/Export/ChineseChess.app
```

## 沙盒问题排查

如果应用遇到沙盒限制：

1. 检查 Console.app 的日志
2. 查看 `/var/log/system.log`
3. 使用 `syspolicyd` 日志诊断
4. 临时禁用 SIP 进行测试（仅开发机器）
