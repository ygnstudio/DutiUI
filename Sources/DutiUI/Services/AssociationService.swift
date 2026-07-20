import Foundation
import UniformTypeIdentifiers
import AppKit

/// 应用信息（用于显示，不暴露 Bundle ID 给 UI）
struct AppInfo: Identifiable, Hashable {
    var id: String { bundleIdentifier }
    let name: String
    let bundleIdentifier: String
    let path: String?
    let icon: NSImage?

    init(name: String, bundleIdentifier: String, path: String? = nil, icon: NSImage? = nil) {
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.path = path
        self.icon = icon
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(bundleIdentifier)
    }

    static func == (lhs: AppInfo, rhs: AppInfo) -> Bool {
        lhs.bundleIdentifier == rhs.bundleIdentifier
    }
}

/// 默认应用关联服务
/// 负责 UTI 解析、查询默认应用、设置默认应用
@MainActor
final class AssociationService: Sendable {
    static let shared = AssociationService()

    private var dutiPath: String?

    private init() {
        refreshDutiPath()
    }

    // MARK: - Duti Path

    func refreshDutiPath() {
        dutiPath = DutiDetector.findDutiPath()
    }

    var isDutiAvailable: Bool {
        dutiPath != nil
    }

    var currentDutiPath: String? {
        dutiPath
    }

    // MARK: - UTI Resolution

    /// 扩展名 → UTI
    func resolveUTI(for fileExtension: String) -> String? {
        let normalized = ManagedAssociation.normalizeExtension(fileExtension)
        // 先尝试 UTType
        if let type = UTType(filenameExtension: normalized) {
            return type.identifier
        }
        // 回退：通过 duti 查询
        return resolveUTIViaDuti(extension: normalized)
    }

    /// 通过 duti 解析 UTI（回退方案）
    private func resolveUTIViaDuti(extension ext: String) -> String? {
        guard let path = dutiPath else { return nil }
        do {
            let result = try CommandRunner.run(
                executablePath: path,
                arguments: ["-x", ext],
                timeout: 5
            )
            return result.standardOutput.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return nil
        }
    }

    // MARK: - Query Default App

    /// 查询某个 UTI 的当前默认应用
    func getDefaultApplication(forUTI uti: String) -> AppInfo? {
        // 使用 Launch Services 公开 API
        guard let handler = LSCopyDefaultRoleHandlerForContentType(
            uti as CFString,
            LSRolesMask.all
        )?.takeRetainedValue() as String? else {
            return nil
        }
        return appInfo(forBundleIdentifier: handler)
    }

    /// 查询某个扩展名的当前默认应用
    func getDefaultApplication(forExtension ext: String) -> AppInfo? {
        guard let uti = resolveUTI(for: ext) else { return nil }
        return getDefaultApplication(forUTI: uti)
    }

    // MARK: - Available Apps

    /// 获取能够打开某个 UTI 的所有应用
    func getAvailableApplications(forUTI uti: String) -> [AppInfo] {
        guard let handlers = LSCopyAllRoleHandlersForContentType(
            uti as CFString,
            LSRolesMask.all
        )?.takeRetainedValue() as? [String] else {
            return []
        }
        return handlers.compactMap { appInfo(forBundleIdentifier: $0) }
    }

    // MARK: - Set Default App

    /// 设置某个 UTI 的默认应用
    /// 使用 duti 命令写入，写入后验证
    func setDefaultApplication(bundleIdentifier: String, forUTI uti: String) async throws {
        guard let path = dutiPath else {
            throw AssociationServiceError.dutiNotInstalled
        }

        // 执行 duti 写入
        let result = try await CommandRunner.runAsync(
            executablePath: path,
            arguments: ["-s", bundleIdentifier, uti, "all"],
            timeout: 10
        )

        guard result.isSuccess else {
            throw AssociationServiceError.writeFailed(
                reason: result.standardError.isEmpty ? "Unknown error" : result.standardError
            )
        }

        // 写入后验证
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 秒等待系统生效

        if !verifyDefaultApplication(forUTI: uti, bundleIdentifier: bundleIdentifier) {
            throw AssociationServiceError.verificationFailed
        }
    }

    /// 验证 UTI 的默认应用是否为预期值
    func verifyDefaultApplication(forUTI uti: String, bundleIdentifier: String) -> Bool {
        guard let current = getDefaultApplication(forUTI: uti) else { return false }
        return current.bundleIdentifier == bundleIdentifier
    }

    // MARK: - Helpers

    /// 根据 Bundle Identifier 获取应用信息
    private func appInfo(forBundleIdentifier bundleID: String) -> AppInfo? {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            // 应用可能已卸载，但 Launch Services 仍有记录
            return AppInfo(
                name: bundleNameFromIdentifier(bundleID),
                bundleIdentifier: bundleID,
                path: nil,
                icon: nil
            )
        }

        let name = url.deletingPathExtension().lastPathComponent
        let path = url.path
        let icon = NSWorkspace.shared.icon(forFile: path)

        return AppInfo(
            name: name,
            bundleIdentifier: bundleID,
            path: path,
            icon: icon
        )
    }

    /// 从 Bundle Identifier 推测应用名称（回退方案）
    private func bundleNameFromIdentifier(_ identifier: String) -> String {
        // 取最后一段并美化
        let components = identifier.split(separator: ".")
        guard let last = components.last else { return identifier }
        let name = String(last)
        // 常见映射
        let knownNames: [String: String] = [
            "Preview": "预览",
            "Safari": "Safari",
            "Mail": "邮件",
            "Notes": "备忘录",
            "TextEdit": "文本编辑",
            "Finder": "访达",
            "QuickTime Player": "QuickTime Player",
            "Music": "音乐",
            "Photos": "照片",
        ]
        return knownNames[name] ?? name
    }
}

// MARK: - Errors

enum AssociationServiceError: LocalizedError {
    case dutiNotInstalled
    case writeFailed(reason: String)
    case verificationFailed
    case cannotResolveUTI(String)

    var errorDescription: String? {
        switch self {
        case .dutiNotInstalled:
            return "duti is not installed"
        case .writeFailed(let reason):
            return "Failed to set default application: \(reason)"
        case .verificationFailed:
            return "Verification failed after writing"
        case .cannotResolveUTI(let ext):
            return "Cannot resolve UTI for extension: \(ext)"
        }
    }
}
