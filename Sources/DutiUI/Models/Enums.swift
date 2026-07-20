import Foundation

/// 关联保护状态
enum AssociationStatus: String, Codable, CaseIterable {
    /// 正常：已锁定且当前默认应用与目标一致
    case normal
    /// 未保护：未开启锁定
    case unlocked
    /// 已变化：检测到默认应用被修改，等待恢复
    case changed
    /// 恢复失败：尝试恢复但失败
    case restoreFailed
    /// 目标应用不存在
    case targetApplicationMissing

    var displayName: String {
        switch self {
        case .normal:
            return Locale.current.isChinese ? "正常" : "Normal"
        case .unlocked:
            return Locale.current.isChinese ? "未保护" : "Unprotected"
        case .changed:
            return Locale.current.isChinese ? "已变化" : "Changed"
        case .restoreFailed:
            return Locale.current.isChinese ? "恢复失败" : "Restore Failed"
        case .targetApplicationMissing:
            return Locale.current.isChinese ? "目标应用不存在" : "App Missing"
        }
    }
}

/// 恢复结果
enum RestoreResult: String, Codable {
    /// 已恢复
    case restored
    /// 恢复失败
    case failed
    /// 跳过（目标应用缺失等）
    case skipped

    var displayName: String {
        switch self {
        case .restored:
            return Locale.current.isChinese ? "已恢复" : "Restored"
        case .failed:
            return Locale.current.isChinese ? "恢复失败" : "Failed"
        case .skipped:
            return Locale.current.isChinese ? "已跳过" : "Skipped"
        }
    }
}

extension Locale {
    var isChinese: Bool {
        Locale.preferredLanguages.first?.hasPrefix("zh") == true
    }
}
