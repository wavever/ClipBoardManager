import SwiftUI

struct ExportPanelView: View {
    let allItems: [ClipboardItem]
    let onClose: () -> Void

    @State private var filter = ExportFilter()
    @State private var isExporting = false

    private var matched: [ClipboardItem] { filter.apply(to: allItems) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.horizontal, 22)
                .padding(.top, 18)
                .padding(.bottom, 14)

            ScrollView {
                VStack(spacing: 14) {
                    typesCard
                    rangeCard
                    favoriteCard
                    optionsCard
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 18)
            }

            Divider().opacity(0.4)

            footer
                .padding(.horizontal, 22)
                .padding(.vertical, 14)
        }
        .frame(width: 520, height: 600)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [.accentColor, .accentColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 38, height: 38)
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("导出为 JSON")
                    .font(.system(size: 17, weight: .bold))
                Text("按筛选条件导出剪贴板历史")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(.secondary.opacity(0.15)))
            }
            .buttonStyle(.plain)
            .help("关闭")
            .keyboardShortcut(.escape, modifiers: [])
        }
    }

    private var typesCard: some View {
        ExportCard(title: "类型", subtitle: "勾选要导出的内容类型") {
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                spacing: 8
            ) {
                ForEach(ClipboardItemType.allCases, id: \.self) { type in
                    typeChip(type)
                }
            }
        }
    }

    private func typeChip(_ type: ClipboardItemType) -> some View {
        let isOn = filter.types.contains(type)
        return Button {
            if isOn {
                filter.types.remove(type)
            } else {
                filter.types.insert(type)
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 12))
                    .foregroundStyle(isOn ? Color.accentColor : Color.secondary)
                Image(systemName: type.icon)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Text(type.displayName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.primary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(isOn ? Color.accentColor.opacity(0.12) : Color.secondary.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .strokeBorder(
                        isOn ? Color.accentColor.opacity(0.4) : Color.secondary.opacity(0.2),
                        lineWidth: 0.5
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var rangeCard: some View {
        ExportCard(title: "时间范围", subtitle: nil) {
            VStack(alignment: .leading, spacing: 10) {
                Picker("", selection: $filter.dateRange) {
                    ForEach(ExportFilter.DateRange.allCases) { range in
                        Text(range.displayName).tag(range)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)

                if filter.dateRange == .custom {
                    HStack(spacing: 10) {
                        DatePicker("从", selection: $filter.customStart, displayedComponents: [.date])
                        DatePicker("到", selection: $filter.customEnd, displayedComponents: [.date])
                    }
                    .font(.system(size: 12))
                }
            }
        }
    }

    private var favoriteCard: some View {
        ExportCard(title: "收藏与置顶", subtitle: nil) {
            Picker("", selection: $filter.favoriteScope) {
                ForEach(ExportFilter.FavoriteScope.allCases) { scope in
                    Text(scope.displayName).tag(scope)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
        }
    }

    private var optionsCard: some View {
        ExportCard(title: "其他选项", subtitle: nil) {
            Toggle(isOn: $filter.includeImageData) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("包含图片数据（base64）")
                        .font(.system(size: 13, weight: .medium))
                    Text("文件体积会显著增大；不勾选时仅记录元信息")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            .toggleStyle(.switch)
        }
    }

    private var footer: some View {
        HStack(spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Text("将导出 \(matched.count) / \(allItems.count) 条")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("取消", action: onClose)
                .keyboardShortcut(.cancelAction)

            Button {
                exportNow()
            } label: {
                HStack(spacing: 6) {
                    if isExporting {
                        ProgressView().controlSize(.small)
                    }
                    Text("导出 JSON")
                }
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
            .disabled(matched.isEmpty || isExporting)
        }
    }

    private func exportNow() {
        isExporting = true
        ExportService.shared.exportToJSON(items: allItems, filter: filter) { result in
            DispatchQueue.main.async {
                isExporting = false
                switch result {
                case .none:
                    break
                case .success(let url):
                    ToastCenter.shared.show(
                        "已导出 \(matched.count) 条到 \(url.lastPathComponent)",
                        systemImage: "checkmark.circle.fill",
                        tint: .green
                    )
                    onClose()
                case .failure(let error):
                    ToastCenter.shared.show(
                        "导出失败：\(error.localizedDescription)",
                        systemImage: "exclamationmark.triangle.fill",
                        tint: .red
                    )
                }
            }
        }
    }
}

private struct ExportCard<Content: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.secondary.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(.separator.opacity(0.4), lineWidth: 0.5)
        )
    }
}
