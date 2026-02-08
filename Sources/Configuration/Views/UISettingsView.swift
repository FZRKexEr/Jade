import SwiftUI

// MARK: - UI Settings View

/// 界面设置视图
public struct UISettingsView: View {

    @Binding var configuration: UIConfiguration

    public var body: some View {
        Form {
            // 主题设置
            Section("主题") {
                Picker("外观", selection: $configuration.theme) {
                    ForEach(ThemeConfiguration.allCases, id: \.self) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())

                Picker("强调色", selection: $configuration.accentColor) {
                    ForEach(AccentColor.allCases, id: \.self) { color in
                        HStack {
                            Circle()
                                .fill(color.swiftUIColor)
                                .frame(width: 12, height: 12)
                            Text(color.displayName)
                        }
                        .tag(color)
                    }
                }
            }

            // 棋盘主题
            Section("棋盘") {
                Picker("棋盘样式", selection: $configuration.boardTheme) {
                    ForEach(BoardTheme.allCases, id: \.self) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }

                Picker("棋子样式", selection: $configuration.pieceTheme) {
                    ForEach(PieceTheme.allCases, id: \.self) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
            }

            // 布局设置
            Section("布局") {
                Picker("棋盘大小", selection: $configuration.layoutConfiguration.boardSize) {
                    ForEach(BoardSize.allCases, id: \.self) { size in
                        Text(size.displayName).tag(size)
                    }
                }

                Toggle("显示坐标", isOn: $configuration.layoutConfiguration.showCoordinates)
                Toggle("显示走棋历史", isOn: $configuration.layoutConfiguration.showMoveHistory)
                Toggle("显示吃子", isOn: $configuration.layoutConfiguration.showCapturedPieces)
                Toggle("紧凑模式", isOn: $configuration.layoutConfiguration.compactMode)
            }

            // 动画设置
            Section("动画") {
                Toggle("启用动画", isOn: $configuration.animationConfiguration.enableAnimations)

                if configuration.animationConfiguration.enableAnimations {
                    Picker("动画速度", selection: $configuration.animationConfiguration.animationSpeed) {
                        ForEach(AnimationSpeed.allCases, id: \.self) { speed in
                            Text(speed.displayName).tag(speed)
                        }
                    }
                }

                Toggle("启用音效", isOn: $configuration.animationConfiguration.enableSound)

                if configuration.animationConfiguration.enableSound {
                    HStack {
                        Text("音量")
                        Slider(
                            value: $configuration.animationConfiguration.soundVolume,
                            in: 0...1
                        )
                        Text("\(Int(configuration.animationConfiguration.soundVolume * 100))%")
                            .monospacedDigit()
                            .frame(width: 40)
                    }
                }
            }
        }
        .formStyle(.grouped)
    }
}
