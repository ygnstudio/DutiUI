import SwiftUI

struct AddAssociationSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @StateObject private var searchText = StateValue("")
    @StateObject private var searchResults = StateValue<[ExtensionInfo]>([])
    @StateObject private var selectedExtension = OptionalStateValue<ExtensionInfo>()
    @StateObject private var showEditView = StateValue(false)
    @StateObject private var customExtension = StateValue("")
    @StateObject private var showCustomError = StateValue(false)
    @StateObject private var customErrorMessage = StateValue("")

    var body: some View {
        Group {
            if let ext = selectedExtension.value, showEditView.value {
                EditAssociationView(
                    extensionInfo: ext,
                    onSave: { app, isLocked in
                        handleSave(ext: ext, app: app, isLocked: isLocked)
                    },
                    onCancel: {
                        showEditView.value = false
                    }
                )
            } else {
                searchView
            }
        }
        .frame(minWidth: 480, minHeight: 400)
    }

    // MARK: - Search View

    private var searchView: some View {
        VStack(spacing: 0) {
            // 搜索栏
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField(
                    Locale.current.isChinese ? "搜索扩展名或文件类型" : "Search extensions or file types",
                    text: $searchText.value
                )
                .textFieldStyle(.plain)
                .onChange(of: searchText.value) { _, newValue in
                    searchResults.value = appState.extensionCatalog.search(newValue)
                }

                if !searchText.value.isEmpty {
                    Button {
                        searchText.value = ""
                        searchResults.value = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            .background(Color(nsColor: .textBackgroundColor))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
            )
            .padding(16)

            // 搜索结果
            if searchText.value.isEmpty {
                // 初始状态：显示常用分类
                categoryBrowseView
            } else if searchResults.value.isEmpty {
                // 无结果：支持自定义扩展名
                noResultsView
            } else {
                resultsListView
            }
        }
    }

    // MARK: - Category Browse

    private var categoryBrowseView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(Locale.current.isChinese ? "常用文件类型" : "Common File Types")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                let categories = ["document", "image", "video", "audio", "archive", "development"]
                ForEach(categories, id: \.self) { category in
                    let items = appState.extensionCatalog.search(category)
                    if !items.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(items.first!.localizedCategory)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(items.prefix(12)) { item in
                                        extensionChip(item)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
            }
            .padding(.vertical)
        }
    }

    private func extensionChip(_ item: ExtensionInfo) -> some View {
        Button {
            selectedExtension.value = item
            showEditView.value = true
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(".\(item.ext)")
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.medium)
                Text(item.localizedDisplayName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Results List

    private var resultsListView: some View {
        List(searchResults.value) { item in
            Button {
                selectedExtension.value = item
                showEditView.value = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: fileTypeIcon(for: item.category))
                        .frame(width: 28, height: 28)
                        .foregroundColor(.accentColor)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.localizedDisplayName)
                            .font(.body)
                        Text(".\(item.ext)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
        }
        .listStyle(.plain)
    }

    // MARK: - No Results

    private var noResultsView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "questionmark.folder")
                .font(.system(size: 36))
                .foregroundColor(.secondary)

            Text(Locale.current.isChinese
                ? "未找到匹配的文件类型"
                : "No matching file types found"
            )
            .font(.body)
            .foregroundColor(.secondary)

            // 自定义扩展名
            VStack(spacing: 8) {
                Text(Locale.current.isChinese ? "自定义扩展名" : "Custom Extension")
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack {
                    TextField(
                        Locale.current.isChinese ? "输入扩展名（如：md）" : "Enter extension (e.g. md)",
                        text: $customExtension.value
                    )
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 160)
                    .onChange(of: customExtension.value) { _, newValue in
                        // 自动标准化
                        let cleaned = ManagedAssociation.normalizeExtension(newValue)
                        if cleaned != newValue {
                            customExtension.value = cleaned
                        }
                    }

                    Button(Locale.current.isChinese ? "添加自定义" : "Add Custom") {
                        addCustomExtension()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(customExtension.value.isEmpty)
                }
            }

            if showCustomError.value {
                Text(customErrorMessage.value)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
            }

            Spacer()
        }
    }

    // MARK: - Actions

    private func addCustomExtension() {
        let normalized = ManagedAssociation.normalizeExtension(customExtension.value)
        guard !normalized.isEmpty else { return }

        // 尝试解析 UTI
        guard let resolvedUTI = appState.associationService.resolveUTI(for: normalized) else {
            showCustomError.value = true
            customErrorMessage.value = Locale.current.isChinese
                ? "无法识别 \".\(normalized)\" 对应的文件类型。\n\n请确认此扩展名已被系统中的某个应用注册。"
                : "Cannot recognize the file type for \".\(normalized)\".\n\nPlease make sure this extension is registered by an application on your system."
            return
        }

        // 创建临时 ExtensionInfo（使用 auto-generated memberwise init）
        let displayNameDict = [
            "zh-Hans": ".\(normalized) 文件",
            "en": ".\(normalized) File"
        ]
        let extInfo = ExtensionInfo(
            ext: normalized,
            displayName: displayNameDict,
            category: "custom",
            preferredUTI: resolvedUTI
        )

        selectedExtension.value = extInfo
        showEditView.value = true
    }

    private func handleSave(ext: ExtensionInfo, app: AppInfo, isLocked: Bool) {
        // 解析 UTI
        guard let resolvedUTI = appState.associationService.resolveUTI(for: ext.ext)
                ?? ext.preferredUTI
        else {
            appState.showErrorMessage(
                Locale.current.isChinese
                    ? "无法解析 .\(ext.ext) 的文件类型"
                    : "Cannot resolve file type for .\(ext.ext)"
            )
            return
        }

        // 如果开启了锁定，先写入默认应用
        if isLocked {
            Task {
                do {
                    try await appState.associationService.setDefaultApplication(
                        bundleIdentifier: app.bundleIdentifier,
                        forUTI: resolvedUTI
                    )
                } catch {
                    appState.showErrorMessage(
                        Locale.current.isChinese
                            ? "写入默认应用失败"
                            : "Failed to set default application"
                    )
                    return
                }

                appState.addAssociation(
                    fileExtension: ext.ext,
                    displayName: ext.localizedDisplayName,
                    uti: resolvedUTI,
                    targetApp: app,
                    isLocked: true
                )
                dismiss()
            }
        } else {
            appState.addAssociation(
                fileExtension: ext.ext,
                displayName: ext.localizedDisplayName,
                uti: resolvedUTI,
                targetApp: app,
                isLocked: false
            )
            dismiss()
        }
    }

    // MARK: - Helpers

    private func fileTypeIcon(for category: String) -> String {
        switch category {
        case "document": return "doc.text"
        case "image": return "photo"
        case "video": return "film"
        case "audio": return "music.note"
        case "archive": return "archivebox"
        case "development": return "chevron.left.forwardslash.chevron.right"
        default: return "doc"
        }
    }
}
