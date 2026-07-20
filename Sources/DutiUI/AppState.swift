import Foundation
import AppKit
import SwiftUI

/// 全局应用状态
/// 使用 ObservableObject + @Published 实现响应式绑定
@MainActor
final class AppState: ObservableObject {
    // MARK: - Services

    let persistence = PersistenceController.shared
    let associationService = AssociationService.shared
    let protectionService = ProtectionService.shared
    let extensionCatalog = ExtensionCatalog.shared

    // MARK: - Data

    @Published var associations: [ManagedAssociation] = []
    @Published var history: [AssociationHistory] = []

    // MARK: - UI State

    @Published var isMainWindowOpen = false
    @Published var showAddSheet = false
    @Published var showHistory = false
    @Published var showSettings = false
    @Published var selectedAssociation: ManagedAssociation?
    @Published var editingAssociation: ManagedAssociation?
    @Published var dutiInstalled = false
    @Published var homebrewInstalled = false

    // MARK: - Error State

    @Published var errorMessage: String?
    @Published var showError = false

    // MARK: - Init

    init() {
        refreshDutiStatus()
        loadData()
    }

    // MARK: - Data Loading

    func loadData() {
        associations = persistence.loadAssociations()
        history = persistence.loadHistory()
    }

    func refreshDutiStatus() {
        dutiInstalled = DutiDetector.isDutiInstalled()
        homebrewInstalled = DutiDetector.isHomebrewInstalled()
        associationService.refreshDutiPath()
    }

    // MARK: - Association Management

    /// 添加新的管理项
    func addAssociation(
        fileExtension: String,
        displayName: String,
        uti: String,
        targetApp: AppInfo,
        isLocked: Bool
    ) {
        let normalized = ManagedAssociation.normalizeExtension(fileExtension)

        // 检查是否已存在
        guard !associations.contains(where: { $0.fileExtension == normalized }) else {
            showErrorMessage(
                Locale.current.isChinese
                    ? "已存在 .\(normalized) 的管理项"
                    : "A managed item for .\(normalized) already exists"
            )
            return
        }

        let association = ManagedAssociation(
            fileExtension: normalized,
            displayName: displayName,
            uti: uti,
            targetApplicationName: targetApp.name,
            targetBundleIdentifier: targetApp.bundleIdentifier,
            targetApplicationPath: targetApp.path,
            isLocked: isLocked,
            status: isLocked ? .normal : .unlocked
        )

        associations.append(association)
        save()
    }

    /// 更新管理项
    func updateAssociation(_ association: ManagedAssociation) {
        guard let index = associations.firstIndex(where: { $0.id == association.id }) else { return }
        var updated = association
        updated.updatedAt = Date()
        associations[index] = updated
        save()
    }

    /// 删除管理项（不修改系统默认应用）
    func deleteAssociation(_ association: ManagedAssociation) {
        associations.removeAll { $0.id == association.id }
        save()
    }

    /// 切换锁定状态
    func toggleLock(for association: ManagedAssociation) {
        guard let index = associations.firstIndex(where: { $0.id == association.id }) else { return }
        var updated = associations[index]
        updated.isLocked.toggle()
        updated.status = updated.isLocked ? .normal : .unlocked
        updated.updatedAt = Date()

        if updated.isLocked {
            // 锁定开启时，刷新最后恢复时间
            updated.lastCheckedAt = Date()
        }

        associations[index] = updated
        save()
    }

    /// 为一个关联设置新的默认应用并写入系统
    func setDefaultApp(for association: ManagedAssociation, to app: AppInfo) async {
        guard let index = associations.firstIndex(where: { $0.id == association.id }) else { return }

        do {
            try await associationService.setDefaultApplication(
                bundleIdentifier: app.bundleIdentifier,
                forUTI: association.uti
            )

            var updated = associations[index]
            updated.targetApplicationName = app.name
            updated.targetBundleIdentifier = app.bundleIdentifier
            updated.targetApplicationPath = app.path
            updated.updatedAt = Date()

            if updated.isLocked {
                updated.status = .normal
            }

            associations[index] = updated
            save()

        } catch {
            showErrorMessage(
                Locale.current.isChinese
                    ? "无法修改 .\(association.fileExtension) 的默认应用"
                    : "Failed to change default app for .\(association.fileExtension)"
            )
        }
    }

    // MARK: - Save

    func save() {
        persistence.saveAssociations(associations)
    }

    // MARK: - Error

    func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }

    func dismissError() {
        errorMessage = nil
        showError = false
    }
}
