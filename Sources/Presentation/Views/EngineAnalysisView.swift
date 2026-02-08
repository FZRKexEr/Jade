import SwiftUI

/// 引擎分析标签页
struct EngineAnalysisTab: View {
    @Bindable var engineViewModel: EngineViewModel

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("引擎分析")
                    .font(.headline)
                Spacer()

                // 分析开关
                Toggle("", isOn: $engineViewModel.analysisMode)
                    .toggleStyle(.switch)
                    .controlSize(.small)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.quaternary.opacity(0.5))

            if engineViewModel.engineState == .ready || engineViewModel.engineState == .searching {
                // 引擎信息显示
                EngineStatsView(engineViewModel: engineViewModel)
                    .padding(12)

                Divider()

                // 主变例显示
                VariationListView(engineViewModel: engineViewModel)

                Spacer()

                // 控制按钮
                AnalysisControlsView(engineViewModel: engineViewModel)
                    .padding(12)
                    .background(.quaternary.opacity(0.3))
            } else {
                // 引擎未连接提示
                VStack(spacing: 16) {
                    Image(systemName: "cpu")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text("引擎未连接")
                        .font(.headline)

                    Text("请先在左侧边栏连接引擎，或点击按钮连接")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Button("连接引擎") {
                        engineViewModel.connectEngine(name: "Pikafish")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(24)
            }
        }
    }
}

/// 引擎统计信息视图
struct EngineStatsView: View {
    @Bindable var engineViewModel: EngineViewModel

    var body: some View {
        VStack(spacing: 12) {
            // 第一行：深度、评分、NPS
            HStack(spacing: 16) {
                StatItem(
                    label: "深度",
                    value: "\(engineViewModel.currentDepth)",
                    icon: "arrow.down.forward"
                )

                StatItem(
                    label: "评分",
                    value: formatScore(engineViewModel.currentScore),
                    valueColor: scoreColor(engineViewModel.currentScore),
                    icon: "chart.line.uptrend.xyaxis"
                )

                StatItem(
                    label: "NPS",
                    value: formatNPS(engineViewModel.currentNPS),
                    icon: "speedometer"
                )
            }

            // 第二行：哈希表使用
            if engineViewModel.hashFull > 0 {
                HStack {
                    Text("哈希表")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    ProgressView(value: Double(engineViewModel.hashFull) / 1000.0)
                        .progressViewStyle(.linear)
                        .frame(width: 100)

                    Text("\(engineViewModel.hashFull / 10)%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 40, alignment: .trailing)
                }
            }
        }
        .padding(12)
        .background(.quaternary.opacity(0.2))
        .cornerRadius(8)
    }

    private func formatScore(_ score: Int) -> String {
        if score > 9000 {
            return "+M\(10000 - score)"
        } else if score < -9000 {
            return "-M\(10000 + score)"
        } else {
            let sign = score >= 0 ? "+" : ""
            return "\(sign)\(Double(score) / 100.0, specifier: "%.1f")"
        }
    }

    private func scoreColor(_ score: Int) -> Color {
        if score > 100 {
            return .green
        } else if score < -100 {
            return .red
        } else {
            return .primary
        }
    }

    private func formatNPS(_ nps: Int) -> String {
        if nps >= 1_000_000 {
            return String(format: "%.1fM", Double(nps) / 1_000_000)
        } else if nps >= 1_000 {
            return String(format: "%.1fK", Double(nps) / 1_000)
        } else {
            return "\(nps)"
        }
    }
}

/// 统计项视图
struct StatItem: View {
    let label: String
    let value: String
    var valueColor: Color = .primary
    let icon: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(valueColor)
                    .fontWeight(.semibold)
            }
        }
    }
}

/// 主变例列表视图
struct VariationListView: View {
    @Bindable var engineViewModel: EngineViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 表头
            HStack {
                Text("主变例 (PV)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(.quaternary.opacity(0.3))

            // 变例内容
            ScrollView {
                if engineViewModel.principalVariation.isEmpty {
                    Text("暂无分析数据")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 60)
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(engineViewModel.principalVariation.enumerated()), id: \.offset) { index, move in
                            Text("\(index + 1). \(move)")
                                .font(.system(.body, design: .monospaced))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 2)
                        }
                    }
                }
            }
            .frame(maxHeight: 150)
        }
    }
}

/// 分析控制按钮
struct AnalysisControlsView: View {
    @Bindable var engineViewModel: EngineViewModel

    var body: some View {
        HStack(spacing: 16) {
            // 多PV选择
            HStack(spacing: 4) {
                Text("多PV:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Picker("", selection: $engineViewModel.multiPV) {
                    ForEach(1...5, id: \.self) { count in
                        Text("\(count)").tag(count)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 100)
            }

            Spacer()

            // 分析开关
            Toggle(isOn: $engineViewModel.analysisMode) {
                HStack(spacing: 4) {
                    Image(systemName: "brain")
                    Text("分析模式")
                }
            }
            .toggleStyle(.switch)
            .controlSize(.small)
        }
    }
}

// MARK: - 预览

#Preview {
    EngineAnalysisTab(engineViewModel: EngineViewModel())
        .frame(height: 500)
}
