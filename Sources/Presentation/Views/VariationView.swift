import SwiftUI

/// 变着评注标签页
struct VariationTab: View {
    @State private var variations: [Variation] = []
    @State private var selectedVariation: Variation?
    @State private var comments: String = ""

    struct Variation: Identifiable {
        let id = UUID()
        let moveNumber: Int
        let notation: String
        let evaluation: String
        let depth: Int
    }

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("变着评注")
                    .font(.headline)
                Spacer()

                Menu("添加变着") {
                    Button("从当前局面") { }
                    Button("从选中的着法") { }
                }
                .menuStyle(.borderlessButton)
                .controlSize(.small)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.quaternary.opacity(0.5))

            if variations.isEmpty {
                // 空状态
                VStack(spacing: 12) {
                    Image(systemName: "arrow.branch")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary)

                    Text("暂无变着")
                        .font(.headline)

                    Text("在分析时发现的变着将显示在这里\n您可以添加评注保存研究心得")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(24)
            } else {
                // 变着列表
                List(selection: $selectedVariation) {
                    ForEach(variations) { variation in
                        VariationRow(variation: variation)
                            .tag(variation)
                    }
                }
                .listStyle(.plain)

                // 评注编辑区
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "text.quote")
                            .foregroundColor(.secondary)
                        Text("评注")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()

                        Button("清除") {
                            comments = ""
                        }
                        .font(.caption)
                        .disabled(comments.isEmpty)
                    }

                    TextEditor(text: $comments)
                        .font(.body)
                        .frame(height: 80)
                }
                .padding(12)
                .background(.quaternary.opacity(0.2))
            }
        }
    }
}

/// 变着行
struct VariationRow: View {
    let variation: VariationTab.Variation

    var body: some View {
        HStack(spacing: 8) {
            // 步数
            Text("\(variation.moveNumber).")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .trailing)

            // 着法
            Text(variation.notation)
                .font(.system(.body, design: .monospaced))

            Spacer()

            // 评估
            Text(variation.evaluation)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(evaluationColor(variation.evaluation))

            // 深度
            Text("d\(variation.depth)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private func evaluationColor(_ eval: String) -> Color {
        // 解析评估值
        if eval.hasPrefix("+") {
            return .green
        } else if eval.hasPrefix("-") {
            return .red
        }
        return .primary
    }
}

// MARK: - 预览

#Preview {
    VariationTab()
        .frame(height: 500)
}
