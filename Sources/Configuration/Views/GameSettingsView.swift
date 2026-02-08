import SwiftUI

// MARK: - Game Settings View

/// 游戏设置视图
public struct GameSettingsView: View {

    @Binding var configuration: GameConfiguration

    public var body: some View {
        Form {
            // 默认时间控制
            Section("时间控制") {
                Picker("默认时间", selection: $configuration.defaultTimeControl) {
                    ForEach(allTimeControls, id: \.self) { timeControl in
                        Text(timeControl.displayName).tag(timeControl)
                    }
                }

                // 自定义时间显示
                if case .custom(let minutes, let increment) = configuration.defaultTimeControl {
                    HStack {
                        Text("时间: \(minutes) 分钟")
                        if increment > 0 {
                            Text("+")
                            Text("每步 \(increment) 秒")
                        }
                    }
                    .foregroundColor(.secondary)
                }
            }

            // 游戏模式
            Section("默认游戏模式") {
                Picker("模式", selection: $configuration.defaultGameMode) {
                    ForEach(GameMode.allCases, id: \.self) { mode in
                        HStack {
                            Image(systemName: mode.icon)
                            Text(mode.displayName)
                        }
                        .tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                // 人机对战设置
                if configuration.defaultGameMode == .humanVsEngine {
                    VStack(alignment: .leading, spacing: 12) {
                        Picker("电脑执棋", selection: $configuration.enginePlayerSide) {
                            ForEach(PlayerSide.allCases, id: \.self) { side in
                                Text(side.displayName).tag(side)
                            }
                        }

                        Picker("电脑强度", selection: $configuration.engineSkillLevel) {
                            ForEach(SkillLevel.allCases, id: \.self) { level in
                                Text(level.displayName).tag(level)
                            }
                        }
                    }
                    .padding(.top, 8)
                }
            }

            // 游戏选项
            Section("游戏选项") {
                Toggle("显示提示", isOn: $configuration.enableHints)
                    .help("显示可能的走法提示")

                Toggle("走棋确认", isOn: $configuration.enableMoveConfirmation)
                    .help("需要确认每次走棋")

                Toggle("允许预走", isOn: $configuration.enablePremove)
                    .help("在对手走棋前预先选择走法")

                Toggle("显示合法走法", isOn: $configuration.showLegalMoves)
                    .help("高亮显示所有合法走法")

                Toggle("显示上一步", isOn: $configuration.showLastMove)
                    .help("高亮显示上一步走法")

                Toggle("显示坐标", isOn: $configuration.showCoordinates)
                    .help("在棋盘边缘显示坐标")

                Toggle("自动翻转棋盘", isOn: $configuration.autoFlipBoard)
                    .help("始终从当前行棋方视角显示棋盘")
            }

            // 音效设置
            Section("音效") {
                Toggle("启用音效", isOn: $configuration.soundEffects.enabled)

                if configuration.soundEffects.enabled {
                    VStack(alignment: .leading, spacing: 8) {
                        VolumeSlider(
                            label: "走棋音量",
                            value: $configuration.soundEffects.moveSoundVolume
                        )
                        VolumeSlider(
                            label: "吃子音量",
                            value: $configuration.soundEffects.captureSoundVolume
                        )
                        VolumeSlider(
                            label: "将军音量",
                            value: $configuration.soundEffects.checkSoundVolume
                        )
                        VolumeSlider(
                            label: "游戏结束音量",
                            value: $configuration.soundEffects.gameEndSoundVolume
                        )
                    }
                    .padding(.leading, 16)
                }
            }

            // 记谱设置
            Section("记谱") {
                Picker("记谱风格", selection: $configuration.notation.notationStyle) {
                    ForEach(NotationStyle.allCases, id: \.self) { style in
                        Text(style.displayName).tag(style)
                    }
                }

                Toggle("显示棋子名称", isOn: $configuration.notation.showPieceName)
                Toggle("使用中文数字", isOn: $configuration.notation.useChineseNumbers)
                Toggle("显示坐标", isOn: $configuration.notation.showCoordinates)
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Helper Properties

    private var allTimeControls: [TimeControl] {
        [
            .bullet,
            .blitz,
            .rapid,
            .classical,
            .unlimited,
            .custom(minutes: 15, increment: 10)
        ]
    }
}

// MARK: - Volume Slider

struct VolumeSlider: View {
    let label: String
    @Binding var value: Double

    var body: some View {
        HStack {
            Text(label)
                .frame(width: 80, alignment: .leading)

            Slider(value: $value, in: 0...1)

            Text("\(Int(value * 100))%")
                .monospacedDigit()
                .frame(width: 40)
        }
    }
}
