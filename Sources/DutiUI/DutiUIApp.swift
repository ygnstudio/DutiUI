import SwiftUI
import AppKit
import UserNotifications
import OSLog

let logger = Logger(subsystem: "com.ygnstudio.DutiUI", category: "app")

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        logger.info("DutiUI launched — setting activation policy")

        // 隐藏 Dock 图标（用代码而非 Info.plist LSUIElement）
        NSApp.setActivationPolicy(.accessory)

        // 通知权限
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }

        // 延迟确保 MenuBarExtra 已初始化，然后自动打开主窗口
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Auto-open main window for debugging
            if let window = NSApp.windows.first(where: { $0.title == "DutiUI" }) {
                window.makeKeyAndOrderFront(nil)
            }
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

@main
struct DutiUIApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
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
            Image(nsImage: menuBarIcon)
        }

        Window("DutiUI", id: "main") {
            MainWindow()
                .environmentObject(appState)
                .frame(minWidth: 680, minHeight: 460)
                .onAppear {
                    logger.info("MainWindow appeared")
                }
        }
        .windowResizability(.contentMinSize)
        .defaultSize(width: 780, height: 540)

        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }

    private var menuBarIcon: NSImage {
        if appState.protectionService.isRunning && !appState.protectionService.isPaused {
            return MenuBarIcon.shieldChecked()
        }
        return MenuBarIcon.shield()
    }

    private func openMainWindow() {
        openWindow(id: "main")
        NSApp.activate(ignoringOtherApps: true)
    }
}
