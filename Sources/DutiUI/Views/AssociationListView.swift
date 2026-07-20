import SwiftUI

struct AssociationListView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if appState.associations.isEmpty {
                EmptyStateView()
            } else {
                VStack(spacing: 0) {
                    // 表头
                    headerRow
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(nsColor: .controlBackgroundColor))

                    Divider()

                    // 列表
                    List {
                        ForEach(appState.associations) { association in
                            AssociationRowView(association: association)
                                .contextMenu {
                                    Button {
                                        appState.toggleLock(for: association)
                                    } label: {
                                        Label(
                                            association.isLocked
                                                ? (Locale.current.isChinese ? "关闭锁定" : "Unlock")
                                                : (Locale.current.isChinese ? "开启锁定" : "Lock"),
                                            systemImage: association.isLocked ? "lock.open" : "lock"
                                        )
                                    }

                                    Divider()

                                    Button(role: .destructive) {
                                        appState.deleteAssociation(association)
                                    } label: {
                                        Label(
                                            Locale.current.isChinese ? "删除" : "Delete",
                                            systemImage: "trash"
                                        )
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                }
            }
        }
        .sheet(isPresented: $appState.showAddSheet) {
            AddAssociationSheet()
                .environmentObject(appState)
        }
        .sheet(item: $appState.selectedAssociation) { association in
            EditExistingAssociationView(association: association)
                .environmentObject(appState)
        }
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(spacing: 16) {
            Text(Locale.current.isChinese ? "文件类型" : "File Type")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)

            Text(Locale.current.isChinese ? "默认应用" : "Default App")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .frame(width: 160, alignment: .leading)

            Text(Locale.current.isChinese ? "锁定" : "Lock")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .frame(width: 50, alignment: .leading)

            Text(Locale.current.isChinese ? "状态" : "Status")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)

            Spacer()
        }
    }
}

// MARK: - Edit Existing Association

struct EditExistingAssociationView: View {
    let association: ManagedAssociation
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @StateObject private var selectedApp = OptionalStateValue<AppInfo>()

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 标题
            VStack(alignment: .leading, spacing: 4) {
                Text(".\(association.fileExtension)")
                    .font(.title3)
                    .fontWeight(.semibold)
                Text(association.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            // 选择新应用
            VStack(alignment: .leading, spacing: 8) {
                Text(Locale.current.isChinese ? "选择新的默认应用" : "Select New Default App")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                ApplicationPicker(uti: association.uti, selectedApp: $selectedApp.value)
            }

            // 当前默认应用信息
            if let app = selectedApp.value {
                HStack(spacing: 6) {
                    Text(Locale.current.isChinese ? "将设为默认：" : "Will set as default:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(app.name)
                        .font(.caption)
                        .fontWeight(.medium)
                    if app.bundleIdentifier == association.targetBundleIdentifier {
                        Text(Locale.current.isChinese ? "(当前)" : "(current)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // 按钮
            HStack {
                Spacer()
                Button(Locale.current.isChinese ? "取消" : "Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)

                Button(Locale.current.isChinese ? "保存" : "Save") {
                    if let app = selectedApp.value {
                        Task {
                            await appState.setDefaultApp(for: association, to: app)
                            dismiss()
                        }
                    }
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
                .disabled(selectedApp.value == nil)
            }
        }
        .padding(24)
        .frame(width: 480, height: 440)
        .onAppear {
            // 预选当前目标应用
            if selectedApp.value == nil {
                let icon: NSImage? = {
                    if let path = association.targetApplicationPath {
                        return NSWorkspace.shared.icon(forFile: path)
                    }
                    return nil
                }()
                selectedApp.value = AppInfo(
                    name: association.targetApplicationName,
                    bundleIdentifier: association.targetBundleIdentifier,
                    path: association.targetApplicationPath,
                    icon: icon
                )
            }
        }
    }
}
