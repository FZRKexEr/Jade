# 中国象棋 (Chinese Chess)

[![macOS](https://img.shields.io/badge/macOS-14+-blue)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange)](https://swift.org/)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

一款精美的 macOS 中国象棋 GUI 应用程序，支持 UCI 引擎协议，提供人机对弈、棋谱管理等功能。

<!-- TODO: Screenshot - 主界面截图 -->
*主界面截图（待添加）*

## 功能特性

- **精美界面**: 使用 SwiftUI 构建的现代化 macOS 界面，支持深色/浅色模式
- **人机对弈**: 集成 UCI 象棋引擎（如 Pikafish、Fairy-Stockfish）
- **引擎分析**: 实时显示引擎思考线和评分
- **棋谱管理**: 支持 PGN 格式的导入、导出和保存
- **走子方式**: 支持点击和拖拽两种走子方式
- **历史记录**: 完整的悔棋、重做功能
- **提示功能**: 向引擎请求当前最佳着法
- **时间控制**: 支持自定义对局时间限制
- **键盘快捷键**: 丰富的快捷键支持，提高操作效率

## 系统要求

- **操作系统**: macOS 14.0 (Sonoma) 或更高版本
- **处理器**: Apple Silicon 或 Intel 芯片
- **内存**: 最低 4GB 推荐 8GB+
- **磁盘空间**: 200MB（不包含引擎）

## 快速开始

### 安装

1. 下载最新的 DMG 安装包从 [Releases](../../releases) 页面
2. 打开 DMG 文件，将应用拖到 Applications 文件夹
3. 首次启动时，在系统偏好设置 > 安全性与隐私中允许应用运行

<!-- TODO: Screenshot - 安装步骤截图 -->
*安装步骤截图（待添加）*

### 第一盘棋

1. 启动应用，选择 **文件 > 新局** 或按 `Cmd+N`
2. 点击 **引擎 > 连接引擎** 连接到 Pikafish
3. 选择对弈模式（人机对战或人人对战）
4. 点击棋盘上的棋子进行走子

<!-- TODO: Screenshot - 对弈界面截图 -->
*对弈界面截图（待添加）*

## 技术栈

- **语言**: Swift 5.9+
- **UI 框架**: SwiftUI + AppKit
- **最低系统**: macOS 14.0
- **架构**: MVVM

## 项目结构

```
Jade/
├── Sources/
│   ├── App/                    # 应用入口
│   ├── Models/                 # 数据模型
│   ├── Views/                  # SwiftUI 视图
│   ├── ViewModels/             # 视图模型
│   ├── Services/               # 服务层
│   ├── Engine/                 # UCI 引擎接口
│   └── Utils/                  # 工具类
├── Resources/                  # 资源文件
├── Tests/                      # 测试代码
└── docs/                       # 文档
```

## 文档

- [安装指南](docs/Installation.md) - 详细的安装和配置说明
- [快速开始](docs/QuickStart.md) - 新手入门教程
- [用户手册](docs/UserGuide.md) - 完整的功能说明
- [引擎配置](docs/EngineGuide.md) - UCI 引擎配置指南
- [常见问题](docs/FAQ.md) - 常见问题解答
- [快捷键](docs/Shortcuts.md) - 键盘快捷键参考

## 更新日志

参见 [CHANGELOG.md](CHANGELOG.md) 了解各版本的更新内容。

## 贡献

欢迎提交 Issue 和 Pull Request！请参阅 [CONTRIBUTING.md](CONTRIBUTING.md) 了解如何参与项目。

## 开源协议

本项目采用 [MIT 协议](LICENSE) 开源。

## 致谢

- [Pikafish](https://github.com/official-pikafish/Pikafish) - 强大的开源中国象棋引擎
- [Fairy-Stockfish](https://github.com/fairy-stockfish/Fairy-Stockfish) - 支持多种象棋变体的引擎

---

**注意**: 本项目是一个 macOS 原生应用，目前不支持 Windows 或 Linux 平台。
