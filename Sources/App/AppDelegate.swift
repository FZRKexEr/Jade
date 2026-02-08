import SwiftUI

/// 应用委托 - 处理应用生命周期事件
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 应用启动完成
        print("中国象棋应用已启动")

        // 设置默认偏好
        setupDefaultPreferences()
    }

    func applicationWillTerminate(_ notification: Notification) {
        // 应用即将退出
        print("中国象棋应用即将退出")

        // 清理资源
        cleanupResources()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // 处理 Dock 点击重新打开
        if !flag {
            // 如果没有可见窗口，创建新窗口
        }
        return true
    }

    // MARK: - 私有方法

    private func setupDefaultPreferences() {
        let defaults: [String: Any] = [
            "board.showCoordinates": true,
            "board.showLastMove": true,
            "board.showValidMoves": true,
            "board.scale": 1.0,
            "board.style": "wood",
            "sound.enabled": true,
            "sound.volume": 0.7,
            "engine.path": "",
            "engine.hashSize": 256,
            "engine.threads": 4
        ]

        UserDefaults.standard.register(defaults: defaults)
    }

    private func cleanupResources() {
        // 断开引擎连接
        // 保存当前游戏状态
        // 清理临时文件
    }
}
