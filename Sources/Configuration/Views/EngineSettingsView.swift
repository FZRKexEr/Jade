import SwiftUI

// MARK: - Engine Settings View

/// 引擎设置视图
public struct EngineSettingsView: View {

    @Binding var configuration: AppConfiguration
    let onEngineSelected: (UUID) -> Void

    @State private var selectedEngineId: UUID?
    @State private var showingAddEngineSheet = false
    @State private var showingDeleteAlert = false
    @State private var engineToDelete: EngineConfiguration?
    @State private var showAlert = false
    @State private var alertMessage = ""

    private var selectedEngine: EngineConfiguration? {
        configuration.engineConfigurations.first { $0.id == selectedEngineId }
    }

    public var body: some View {
        VStack(spacing: 0) {
            // 引擎列表
            HStack(spacing: 0) {
                // 引擎列表
                engineList
                    .frame(width: 250)

                Divider()

                // 引擎详情
                if let engine = selectedEngine {
                    engineDetailView(engine: engine)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    emptySelectionView
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .sheet(isPresented: $showingAddEngineSheet) {
            AddEngineView { newEngine in
                addEngine(newEngine)
                showingAddEngineSheet = false
            }
        }
        .alert("提示", isPresented: $showAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .alert("删除引擎", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                if let engine = engineToDelete {
                    deleteEngine(engine)
                }
            }
        } message: {
            Text("确定要删除引擎 \"\(engineToDelete?.name ?? "")\" 吗？此操作不可撤销。")
        }
        .onAppear {
            // 选择默认引擎
            if selectedEngineId == nil {
                selectedEngineId = configuration.defaultEngineConfiguration?.id
                    ?? configuration.engineConfigurations.first?.id
            }
        }
    }

    // MARK: - Subviews

    private var engineList: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("引擎列表")
                    .font(.headline)
                Spacer()
                Button(action: { showingAddEngineSheet = true }) {
                    Image(systemName: "plus")
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            .padding()

            Divider()

            // 引擎列表
            List(selection: $selectedEngineId) {
                ForEach(configuration.engineConfigurations) { engine in
                    EngineRowView(
                        engine: engine,
                        isDefault: engine.isDefault,
                        isEnabled: engine.isEnabled
                    )
                    .tag(engine.id)
                    .contextMenu {
                        Button("设为默认") {
                            setDefaultEngine(engine)
                        }
                        .disabled(engine.isDefault)

                        Button(engine.isEnabled ? "禁用" : "启用") {
                            toggleEngineEnabled(engine)
                        }

                        Divider()

                        Button("删除", role: .destructive) {
                            engineToDelete = engine
                            showingDeleteAlert = true
                        }
                    }
                }
            }
            .listStyle(.plain)
        }
    }

    private func engineDetailView(engine: EngineConfiguration) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 引擎名称和状态
                HStack {
                    Text(engine.name)
                        .font(.title)
                        .fontWeight(.bold)

                    Spacer()

                    StatusBadge(isEnabled: engine.isEnabled, isDefault: engine.isDefault)
                }

                Divider()

                // 基本信息
                InfoSection(title: "基本信息") {
                    InfoRow(label: "ID", value: engine.id.uuidString.prefix(8) + "...")
                    InfoRow(label: "路径", value: engine.executablePath)
                    InfoRow(label: "工作目录", value: engine.workingDirectory ?? "默认")
                }

                // 参数设置
                InfoSection(title: "启动参数") {
                    if engine.arguments.isEmpty {
                        Text("无额外参数")
                            .foregroundColor(.secondary)
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(engine.arguments, id: \.self) { arg in
                                Text(arg)
                                    .font(.system(.body, design: .monospaced))
                                    .padding(4)
                                    .background(Color.secondary.opacity(0.1))
                                    .cornerRadius(4)
                            }
                        }
                    }
                }

                // 默认选项
                InfoSection(title: "默认选项") {
                    if engine.defaultOptions.isEmpty {
                        Text("无默认选项")
                            .foregroundColor(.secondary)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(engine.defaultOptions.keys.sorted()), id: \.self) { key in
                                HStack {
                                    Text(key)
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text(engine.defaultOptions[key] ?? "")
                                        .foregroundColor(.secondary)
                                        .font(.system(.body, design: .monospaced))
                                }
                                .padding(.vertical, 4)
                                Divider()
                            }
                        }
                    }
                }

                // 支持的变体
                InfoSection(title: "支持的棋类") {
                    FlowLayout(spacing: 8) {
                        ForEach(engine.supportedVariants, id: \.self) { variant in
                            Badge(text: variantDisplayName(variant))
                        }
                    }
                }
            }
            .padding()
        }
    }

    private var emptySelectionView: some View {
        VStack(spacing: 20) {
            Image(systemName: "cpu")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("选择或添加引擎")
                .font(.title2)
                .foregroundColor(.secondary)

            Text("在左侧列表中选择一个引擎查看详情，或点击 + 添加新引擎")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("添加引擎") {
                showingAddEngineSheet = true
            }
            .buttonStyle(BorderedProminentButtonStyle())
            .padding(.top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helper Views

    private func InfoSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)

            content()
                .padding()
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(8)
        }
    }

    private func InfoRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .fontWeight(.medium)
                .frame(width: 80, alignment: .leading)

            Text(value)
                .foregroundColor(.secondary)
                .lineLimit(2)

            Spacer()
        }
    }

    private func StatusBadge(isEnabled: Bool, isDefault: Bool) -> some View {
        HStack(spacing: 8) {
            if isDefault {
                Badge(text: "默认", color: .blue)
            }
            Badge(
                text: isEnabled ? "启用" : "禁用",
                color: isEnabled ? .green : .red
            )
        }
    }

    private func Badge(text: String, color: Color = .blue) -> some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundColor(color)
            .background(color.opacity(0.15))
            .cornerRadius(4)
    }

    // MARK: - Actions

    private func addEngine(_ engine: EngineConfiguration) {
        configurationManager.setEngineConfiguration(engine)
        selectedEngineId = engine.id
        onEngineSelected(engine.id)
    }

    private func deleteEngine(_ engine: EngineConfiguration) {
        configurationManager.removeEngineConfiguration(id: engine.id)
        if selectedEngineId == engine.id {
            selectedEngineId = configuration.engineConfigurations.first?.id
        }
    }

    private func setDefaultEngine(_ engine: EngineConfiguration) {
        var updatedEngine = engine
        updatedEngine.isDefault = true
        configurationManager.setEngineConfiguration(updatedEngine)
    }

    private func toggleEngineEnabled(_ engine: EngineConfiguration) {
        var updatedEngine = engine
        updatedEngine.isEnabled.toggle()
        configurationManager.setEngineConfiguration(updatedEngine)
    }

    private func variantDisplayName(_ variant: String) -> String {
        switch variant {
        case "xiangqi":
            return "中国象棋"
        case "chess":
            return "国际象棋"
        case "shogi":
            return "将棋"
        default:
            return variant
        }
    }
}

// MARK: - Engine Row View

struct EngineRowView: View {
    let engine: EngineConfiguration
    let isDefault: Bool
    let isEnabled: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(engine.name)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)

                Text(engine.executablePath)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            HStack(spacing: 4) {
                if isDefault {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                }

                Circle()
                    .fill(isEnabled ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 4)
        .opacity(isEnabled ? 1.0 : 0.6)
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}
