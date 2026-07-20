import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @EnvironmentObject var appState: AppState

    // 设置项（使用 @AppStorage 自动持久化，在 SwiftUI View 中可用）
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("checkInterval") private var checkInterval: Double = 10
    @AppStorage("showNotifications") private var showNotifications = true

    @StateObject private var loginItemError = OptionalStateValue<String>()

    var body: some View {
        Form {
            // 常规设置
            Section {
                // 登录时启动
                Toggle(isOn: $launchAtLogin) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Locale.current.isChinese ? "登录时启动" : "Launch at Login")
                        Text(Locale.current.isChinese
                            ? "登录后自动在后台启动 DutiUI"
                            : "Automatically start DutiUI in the background after login"
                        )
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
                .onChange(of: launchAtLogin) { _, newValue in
                    setLoginItem(enabled: newValue)
                }

                if let error = loginItemError.value {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }

                // 显示通知
                Toggle(isOn: $showNotifications) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Locale.current.isChinese ? "显示恢复通知" : "Show Restore Notifications")
                        Text(Locale.current.isChinese
                            ? "当默认应用被自动恢复时发送通知"
                            : "Send a notification when default apps are auto-restored"
                        )
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }

                // 检查间隔
                Picker(
                    Locale.current.isChinese ? "检查间隔" : "Check Interval",
                    selection: $checkInterval
                ) {
                    Text(Locale.current.isChinese ? "5 秒" : "5 seconds").tag(5.0)
                    Text(Locale.current.isChinese ? "10 秒" : "10 seconds").tag(10.0)
                    Text(Locale.current.isChinese ? "30 秒" : "30 seconds").tag(30.0)
                    Text(Locale.current.isChinese ? "60 秒" : "60 seconds").tag(60.0)
                }
                .onChange(of: checkInterval) { _, _ in
                    appState.protectionService.updateInterval()
                }
            } header: {
                Text(Locale.current.isChinese ? "常规" : "General")
            }

            // 关于
            Section {
                HStack {
                    Text("DutiUI")
                        .fontWeight(.medium)
                    Spacer()
                    Text("v1.0")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text(Locale.current.isChinese ? "duti 状态" : "duti Status")
                    Spacer()
                    if appState.dutiInstalled {
                        HStack(spacing: 4) {
                            Circle().fill(Color.green).frame(width: 6, height: 6)
                            Text(Locale.current.isChinese ? "已安装" : "Installed")
                                .foregroundColor(.secondary)
                        }
                    } else {
                        HStack(spacing: 4) {
                            Circle().fill(Color.red).frame(width: 6, height: 6)
                            Text(Locale.current.isChinese ? "未安装" : "Not Installed")
                                .foregroundColor(.secondary)
                        }
                    }
                }

                if let path = appState.associationService.currentDutiPath {
                    HStack {
                        Text(Locale.current.isChinese ? "duti 路径" : "duti Path")
                        Spacer()
                        Text(path)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
            } header: {
                Text(Locale.current.isChinese ? "关于" : "About")
            }
        }
        .formStyle(.grouped)
        .frame(width: 460, height: 320)
        .task {
            // 同步初始状态
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }

    // MARK: - Login Item

    private func setLoginItem(enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            loginItemError.value = nil
        } catch {
            loginItemError.value = error.localizedDescription
            // 回滚 UI
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}
