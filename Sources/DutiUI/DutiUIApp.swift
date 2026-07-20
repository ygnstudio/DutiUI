import SwiftUI
import AppKit
import UserNotifications

@main
struct DutiUIApp: App {
    @StateObject private var appState = AppState()
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        // 菜单栏图标
        MenuBarExtra {
            Button {
                openMainWindow()
            } label: {
                Label(
                    Locale.current.isChinese ? "打开 DutiUI" : "Open DutiUI",
                    systemImage: "rectangle.inset.filled"
                )
            }
            .keyboardShortcut("o")

            Divider()

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Label(
                    Locale.current.isChinese ? "退出 DutiUI" : "Quit DutiUI",
                    systemImage: "power"
                )
            }
            .keyboardShortcut("q")
        } label: {
            Image(systemName: appState.protectionService.isRunning
                  && !appState.protectionService.isPaused
                  ? "shield.checkered"
                  : "shield.slash")
        }

        // 主窗口
        Window("DutiUI", id: "main") {
            MainWindow()
                .environmentObject(appState)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 780, height: 520)

        // 设置窗口
        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }

    init() {
        // 隐藏 Dock 图标（LSUIElement = true）
        NSApp.setActivationPolicy(.accessory)

        // 请求通知权限
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func openMainWindow() {
        openWindow(id: "main")
        // 将应用置于前台
        NSApp.activate(ignoringOtherApps: true)
    }
}
