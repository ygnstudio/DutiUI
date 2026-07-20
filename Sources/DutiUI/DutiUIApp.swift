import SwiftUI
import AppKit
import UserNotifications
import OSLog

let logger = Logger(subsystem: "com.ygnstudio.DutiUI", category: "app")

/// 自定义 AppDelegate 处理通知权限等
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        logger.info("DutiUI launched")

        // 安全请求通知权限（在非 bundle 环境下可能失败）
        if Bundle.main.bundleURL.pathExtension == "app" {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
                logger.info("Notifications: granted=\(granted), error=\(String(describing: error))")
            }
        } else {
            logger.warning("Skipping notification auth: not running from .app bundle")
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        logger.info("DutiUI terminating")
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
            // 使用 Text + Image 组合确保始终可见
            HStack(spacing: 2) {
                Image(systemName: menuBarIconName)
                    .font(.system(size: 14))
            }
        }

        // 主窗口
        Window("DutiUI", id: "main") {
            MainWindow()
                .environmentObject(appState)
                .frame(minWidth: 680, minHeight: 460)
        }
        .windowResizability(.contentMinSize)
        .defaultSize(width: 780, height: 540)

        // 设置窗口
        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }

    private var menuBarIconName: String {
        if appState.protectionService.isRunning && !appState.protectionService.isPaused {
            return "shield.checkered"
        }
        return "shield.slash"
    }

    private func openMainWindow() {
        openWindow(id: "main")
        NSApp.activate(ignoringOtherApps: true)
    }
}
