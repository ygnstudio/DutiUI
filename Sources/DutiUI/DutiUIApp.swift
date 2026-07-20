import SwiftUI
import AppKit
import UserNotifications

/// 自定义 AppDelegate 处理激活策略等
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 隐藏 Dock 图标（LSUIElement = true）
        NSApp.setActivationPolicy(.accessory)

        // 请求通知权限
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
}

@main
struct DutiUIApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
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

    private func openMainWindow() {
        openWindow(id: "main")
        NSApp.activate(ignoringOtherApps: true)
    }
}
