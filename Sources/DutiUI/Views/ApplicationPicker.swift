import SwiftUI

struct ApplicationPicker: View {
    let uti: String
    @Binding var selectedApp: AppInfo?
    @EnvironmentObject var appState: AppState

    @StateObject private var availableApps = StateValue<[AppInfo]>([])
    @StateObject private var isLoading = StateValue(true)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isLoading.value {
                HStack {
                    ProgressView()
                        .controlSize(.small)
                    Text(Locale.current.isChinese ? "正在加载应用列表…" : "Loading applications…")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else if availableApps.value.isEmpty {
                Text(Locale.current.isChinese
                    ? "未找到可以打开此文件类型的应用"
                    : "No applications found for this file type"
                )
                .font(.caption)
                .foregroundColor(.secondary)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(availableApps.value) { app in
                            Button {
                                selectedApp = app
                            } label: {
                                HStack(spacing: 10) {
                                    if let icon = app.icon {
                                        Image(nsImage: icon)
                                            .resizable()
                                            .frame(width: 28, height: 28)
                                    } else {
                                        Image(systemName: "app.fill")
                                            .resizable()
                                            .frame(width: 28, height: 28)
                                            .foregroundColor(.secondary)
                                    }

                                    Text(app.name)
                                        .font(.body)
                                        .foregroundColor(.primary)

                                    Spacer()

                                    // 选中标记
                                    if selectedApp?.bundleIdentifier == app.bundleIdentifier {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.accentColor)
                                            .font(.system(size: 18))
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .background(
                                selectedApp?.bundleIdentifier == app.bundleIdentifier
                                    ? Color.accentColor.opacity(0.12)
                                    : Color.clear
                            )
                            .cornerRadius(6)

                            if app.bundleIdentifier != availableApps.value.last?.bundleIdentifier {
                                Divider()
                                    .padding(.leading, 48)
                            }
                        }
                    }
                    .padding(4)
                }
                .frame(minHeight: 120)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )
            }

            // 手动选择应用
            Button {
                selectFromFinder()
            } label: {
                Label(
                    Locale.current.isChinese ? "从 Applications 中选择…" : "Choose from Applications…",
                    systemImage: "folder"
                )
                .font(.caption)
            }
        }
        .task {
            await loadAvailableApps()
        }
    }

    private func loadAvailableApps() async {
        isLoading.value = true
        defer { isLoading.value = false }

        let apps = appState.associationService.getAvailableApplications(forUTI: uti)
        availableApps.value = apps.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        // 如果还没有选中项，且 binding 中有值，标记为选中
        // （首次加载时 selectedApp 已经在 EditAssociationView 中预设好了）
    }

    private func selectFromFinder() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.prompt = Locale.current.isChinese ? "选择" : "Select"

        if panel.runModal() == .OK, let url = panel.url {
            let bundle = Bundle(url: url)
            let name = url.deletingPathExtension().lastPathComponent
            let bundleID = bundle?.bundleIdentifier ?? ""
            let icon = NSWorkspace.shared.icon(forFile: url.path)

            let app = AppInfo(
                name: name,
                bundleIdentifier: bundleID,
                path: url.path,
                icon: icon
            )
            selectedApp = app
        }
    }
}
