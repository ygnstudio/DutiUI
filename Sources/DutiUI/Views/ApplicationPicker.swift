import SwiftUI

struct ApplicationPicker: View {
    let uti: String
    @Binding var selectedApp: AppInfo?
    @EnvironmentObject var appState: AppState

    @StateObject private var availableApps = StateValue<[AppInfo]>([])
    @StateObject private var isLoading = StateValue(true)
    @StateObject private var showCustomPicker = StateValue(false)

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
                List(availableApps.value, id: \.bundleIdentifier, selection: $selectedApp) { app in
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
                    }
                    .padding(.vertical, 2)
                }
                .listStyle(.plain)
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
