import SwiftUI

struct EditAssociationView: View {
    let extensionInfo: ExtensionInfo
    let onSave: (AppInfo, Bool) -> Void
    let onCancel: () -> Void

    @EnvironmentObject var appState: AppState

    @StateObject private var selectedApp = OptionalStateValue<AppInfo>()
    @StateObject private var isLocked = StateValue(false)
    @StateObject private var uti = StateValue("")
    @StateObject private var isLoading = StateValue(true)
    @StateObject private var currentDefaultApp = OptionalStateValue<AppInfo>()

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 标题
            VStack(alignment: .leading, spacing: 4) {
                Text(extensionInfo.localizedDisplayName)
                    .font(.title3)
                    .fontWeight(.semibold)
                Text(".\(extensionInfo.ext)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)
            }

            Divider()

            // 当前默认应用
            if let current = currentDefaultApp.value {
                VStack(alignment: .leading, spacing: 6) {
                    Text(Locale.current.isChinese ? "当前默认应用" : "Current Default App")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack(spacing: 8) {
                        if let icon = current.icon {
                            Image(nsImage: icon)
                                .resizable()
                                .frame(width: 24, height: 24)
                        }
                        Text(current.name)
                            .font(.headline)
                    }
                }
            }

            // 选择新默认应用
            VStack(alignment: .leading, spacing: 8) {
                Text(Locale.current.isChinese ? "选择新的默认应用" : "Select New Default App")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                ApplicationPicker(uti: uti.value, selectedApp: $selectedApp.value)
            }

            // 锁定开关
            if selectedApp.value != nil {
                Toggle(isOn: $isLocked.value) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Locale.current.isChinese ? "锁定此关联" : "Lock This Association")
                            .font(.body)
                        Text(Locale.current.isChinese
                            ? "当关联被其他应用修改时，自动恢复"
                            : "Automatically restore when changed by other apps"
                        )
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
                .toggleStyle(.switch)
            }

            Spacer()

            // 按钮
            HStack {
                Spacer()
                Button(Locale.current.isChinese ? "取消" : "Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.escape)

                Button(Locale.current.isChinese ? "保存" : "Save") {
                    if let app = selectedApp.value {
                        onSave(app, isLocked.value)
                    }
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
                .disabled(selectedApp.value == nil)
            }
        }
        .padding(24)
        .frame(width: 480, height: 440)
        .task {
            await loadData()
        }
    }

    private func loadData() async {
        isLoading.value = true
        defer { isLoading.value = false }

        // 解析 UTI
        if let resolved = appState.associationService.resolveUTI(for: extensionInfo.ext) {
            uti.value = resolved
        } else if let preferred = extensionInfo.preferredUTI {
            uti.value = preferred
        }

        // 获取当前默认应用
        if !uti.value.isEmpty {
            currentDefaultApp.value = appState.associationService.getDefaultApplication(forUTI: uti.value)
            // 默认选中当前应用
            if selectedApp.value == nil {
                selectedApp.value = currentDefaultApp.value
            }
        }
    }
}
