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

            // 当前目标应用
            VStack(alignment: .leading, spacing: 6) {
                Text(Locale.current.isChinese ? "目标默认应用" : "Target Default App")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                HStack(spacing: 8) {
                    Image(systemName: "app.fill")
                    Text(association.targetApplicationName)
                        .font(.headline)
                }
            }

            // 选择新应用
            VStack(alignment: .leading, spacing: 8) {
                Text(Locale.current.isChinese ? "选择新的默认应用" : "Select New Default App")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                ApplicationPicker(uti: association.uti, selectedApp: $selectedApp.value)
            }

            // 锁定开关
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(Locale.current.isChinese ? "锁定状态" : "Lock Status")
                        .font(.subheadline)
                    Text(association.isLocked
                        ? (Locale.current.isChinese ? "已锁定" : "Locked")
                        : (Locale.current.isChinese ? "未锁定" : "Unlocked")
                    )
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(association.isLocked ? Color.green.opacity(0.15) : Color.secondary.opacity(0.15))
                    .cornerRadius(4)
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

                if let app = selectedApp.value {
                    Button(Locale.current.isChinese ? "保存" : "Save") {
                        Task {
                            await appState.setDefaultApp(for: association, to: app)
                            dismiss()
                        }
                    }
                    .keyboardShortcut(.return)
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(24)
        .frame(width: 480, height: 440)
    }
}
