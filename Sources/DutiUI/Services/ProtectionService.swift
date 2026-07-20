import Foundation
import UserNotifications

/// 自动保护服务
/// 定时检查已锁定的项目，发现变化后自动恢复
@MainActor
final class ProtectionService: ObservableObject {
    static let shared = ProtectionService()

    // MARK: - Published State

    @Published var isRunning = false
    @Published var isPaused = false

    // MARK: - Settings (backed by UserDefaults)

    private let defaults = UserDefaults.standard

    var checkInterval: Double {
        get {
            let value = defaults.double(forKey: "checkInterval")
            return value > 0 ? value : 10
        }
        set { defaults.set(newValue, forKey: "checkInterval") }
    }

    var showNotifications: Bool {
        get {
            if defaults.object(forKey: "showNotifications") == nil { return true }
            return defaults.bool(forKey: "showNotifications")
        }
        set { defaults.set(newValue, forKey: "showNotifications") }
    }

    var autoStartProtection: Bool {
        get {
            if defaults.object(forKey: "autoStartProtection") == nil { return true }
            return defaults.bool(forKey: "autoStartProtection")
        }
        set { defaults.set(newValue, forKey: "autoStartProtection") }
    }

    // MARK: - Private

    private var timer: Timer?
    private let persistence = PersistenceController.shared
    private let associationService = AssociationService.shared

    private init() {}

    // MARK: - Lifecycle

    func start() {
        guard !isRunning else { return }
        isRunning = true
        isPaused = false
        scheduleTimer()
    }

    func stop() {
        isRunning = false
        isPaused = false
        timer?.invalidate()
        timer = nil
    }

    func pause() {
        guard isRunning, !isPaused else { return }
        isPaused = true
        timer?.invalidate()
        timer = nil
    }

    func resume() {
        guard isRunning, isPaused else { return }
        isPaused = false
        scheduleTimer()
    }

    // MARK: - Timer

    private func scheduleTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(
            withTimeInterval: checkInterval,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.performCheck()
            }
        }
    }

    /// 更新检查间隔（从设置中读取新值后调用）
    func updateInterval() {
        guard isRunning, !isPaused else { return }
        scheduleTimer()
    }

    // MARK: - Check Logic

    private func performCheck() async {
        let associations = persistence.loadAssociations()
        let lockedItems = associations.filter { $0.isLocked }

        for var item in lockedItems {
            // 检查目标应用是否存在
            if item.targetApplicationPath != nil {
                let pathExists = FileManager.default.fileExists(atPath: item.targetApplicationPath!)
                if !pathExists {
                    // 目标应用不存在
                    item.status = .targetApplicationMissing
                    item.updatedAt = Date()
                    persistence.saveAssociations(
                        associations.map { $0.id == item.id ? item : $0 }
                    )
                    continue
                }
            }

            // 查询当前默认应用
            guard let currentApp = associationService.getDefaultApplication(forUTI: item.uti) else {
                continue
            }

            // 更新检查时间
            item.lastCheckedAt = Date()

            // 对比
            if currentApp.bundleIdentifier == item.targetBundleIdentifier {
                // 一致：恢复正常状态
                if item.status != .normal {
                    item.status = .normal
                    item.updatedAt = Date()
                }
            } else {
                // 不一致：尝试恢复
                item.status = .changed
                let startTime = Date()

                do {
                    try await associationService.setDefaultApplication(
                        bundleIdentifier: item.targetBundleIdentifier,
                        forUTI: item.uti
                    )
                    let duration = Date().timeIntervalSince(startTime)

                    item.status = .normal
                    item.lastRestoredAt = Date()
                    item.updatedAt = Date()

                    // 写入历史记录
                    let history = AssociationHistory(
                        associationID: item.id,
                        fileExtension: item.fileExtension,
                        expectedApplicationName: item.targetApplicationName,
                        expectedBundleIdentifier: item.targetBundleIdentifier,
                        detectedApplicationName: currentApp.name,
                        detectedBundleIdentifier: currentApp.bundleIdentifier,
                        result: .restored,
                        duration: duration,
                        createdAt: Date()
                    )
                    persistence.appendHistory(history)

                    // 发送通知
                    sendRestoreSuccessNotification(ext: item.fileExtension, appName: item.targetApplicationName)

                } catch {
                    let duration = Date().timeIntervalSince(startTime)
                    item.status = .restoreFailed
                    item.updatedAt = Date()

                    let history = AssociationHistory(
                        associationID: item.id,
                        fileExtension: item.fileExtension,
                        expectedApplicationName: item.targetApplicationName,
                        expectedBundleIdentifier: item.targetBundleIdentifier,
                        detectedApplicationName: currentApp.name,
                        detectedBundleIdentifier: currentApp.bundleIdentifier,
                        result: .failed,
                        errorMessage: error.localizedDescription,
                        duration: duration,
                        createdAt: Date()
                    )
                    persistence.appendHistory(history)

                    sendRestoreFailedNotification(ext: item.fileExtension, appName: item.targetApplicationName)
                }
            }

            // 保存更新后的关联状态
            persistence.saveAssociations(
                associations.map { $0.id == item.id ? item : $0 }
            )
        }
    }

    // MARK: - Notifications

    private func sendRestoreSuccessNotification(ext: String, appName: String) {
        guard showNotifications else { return }
        let isChinese = Locale.current.isChinese

        let content = UNMutableNotificationContent()
        content.title = isChinese
            ? "已恢复 .\(ext) 的默认应用"
            : "Restored Default App for .\(ext)"
        content.body = isChinese
            ? "默认应用已恢复为\"\(appName)\"。"
            : "Default app restored to \"\(appName)\"."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    private func sendRestoreFailedNotification(ext: String, appName: String) {
        guard showNotifications else { return }
        let isChinese = Locale.current.isChinese

        let content = UNMutableNotificationContent()
        content.title = isChinese
            ? "无法恢复 .\(ext) 的默认应用"
            : "Failed to Restore Default App for .\(ext)"
        content.body = isChinese
            ? "目标应用\"\(appName)\"可能已被删除。"
            : "Target app \"\(appName)\" may have been deleted."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
