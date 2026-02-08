# ChineseChess v1.0.0 发布说明

**发布日期**: 2024年

## 概述

ChineseChess v1.0.0 是首个正式版本，为中国象棋爱好者提供了一个功能完整、界面精美的 macOS 应用。

## 主要特性

### 核心功能
- 完整的中国象棋规则实现
- 人机对弈（支持 UCI 引擎）
- 人人对弈模式
- 悔棋和重做功能
- 提示功能

### 界面特色
- 精美设计的棋盘界面
- 点击和拖拽两种走子方式
- 三种棋盘样式：传统、现代、木纹
- 深色/浅色主题支持
- 棋盘翻转功能
- 可移动位置提示
- 最后一步高亮显示

### 引擎支持
- UCI 协议引擎支持
- 内置 Pikafish 引擎自动下载和配置
- 支持 Fairy-Stockfish 等多引擎
- 引擎选项配置（Hash、Threads、Skill Level 等）
- 分析模式支持

### 棋谱管理
- PGN 格式导入导出
- 自定义格式保存
- 复制/粘贴棋谱
- 复制/粘贴局面（FEN 格式）
- 棋谱元数据编辑
- 最近文件列表

## 系统要求

- macOS 14.0 或更高版本
- Apple Silicon 或 Intel Mac
- 约 200 MB 可用磁盘空间

## 安装方法

1. 下载 `ChineseChess-1.0.0.dmg`
2. 双击挂载 DMG
3. 将 `ChineseChess.app` 拖到 `Applications` 文件夹
4. 从 Launchpad 或 Applications 启动应用

## 首次运行

由于应用经过代码签名但未经过 Apple 公证，首次运行时可能会看到安全警告。

**解决方法**:
1. 打开 `系统偏好设置` > `安全性与隐私`
2. 点击 `仍要打开`
3. 或者按住 Control 键点击应用，选择 `打开`

## 卸载方法

1. 将 `ChineseChess.app` 从 `Applications` 文件夹拖到废纸篓
2. 删除配置文件（可选）:
   ```
   ~/Library/Preferences/com.chinesechess.app.plist
   ~/Library/Application Support/ChineseChess/
   ```

## 已知问题

- 某些复杂的引擎配置可能需要手动编辑配置文件
- 部分 PGN 格式的变着记录可能无法正确解析

## 反馈与支持

- GitHub Issues: https://github.com/yourorg/chinesechess/issues
- 电子邮件: support@chinesechess.app

## 更新日志

详细更新日志请查看 [CHANGELOG.md](CHANGELOG.md)

## 许可证

本项目采用 MIT 许可证。详见 [LICENSE](LICENSE) 文件。

---

**感谢使用 ChineseChess!**
