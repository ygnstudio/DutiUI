import Foundation

/// JSON 文件持久化管理
/// 数据存储在 ~/Library/Application Support/DutiUI/
@MainActor
final class PersistenceController: Sendable {
    static let shared = PersistenceController()

    private let fileManager = FileManager.default
    private let maxHistoryRecords = 500

    private var dataDirectory: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("DutiUI", isDirectory: true)
    }

    private var associationsFile: URL {
        dataDirectory.appendingPathComponent("associations.json")
    }

    private var historyFile: URL {
        dataDirectory.appendingPathComponent("history.json")
    }

    private init() {
        ensureDirectory()
    }

    // MARK: - Directory Setup

    private func ensureDirectory() {
        guard !fileManager.fileExists(atPath: dataDirectory.path) else { return }
        try? fileManager.createDirectory(at: dataDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Associations

    func loadAssociations() -> [ManagedAssociation] {
        guard fileManager.fileExists(atPath: associationsFile.path),
              let data = try? Data(contentsOf: associationsFile) else {
            return []
        }
        let decoder = JSONDecoder()
        return (try? decoder.decode([ManagedAssociation].self, from: data)) ?? []
    }

    func saveAssociations(_ associations: [ManagedAssociation]) {
        ensureDirectory()
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        guard let data = try? encoder.encode(associations) else { return }
        try? data.write(to: associationsFile, options: .atomic)
    }

    // MARK: - History

    func loadHistory() -> [AssociationHistory] {
        guard fileManager.fileExists(atPath: historyFile.path),
              let data = try? Data(contentsOf: historyFile) else {
            return []
        }
        let decoder = JSONDecoder()
        return (try? decoder.decode([AssociationHistory].self, from: data)) ?? []
    }

    func saveHistory(_ history: [AssociationHistory]) {
        ensureDirectory()
        // 保留不超过上限
        let trimmed = history.suffix(maxHistoryRecords)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        guard let data = try? encoder.encode(Array(trimmed)) else { return }
        try? data.write(to: historyFile, options: .atomic)
    }

    /// 添加一条历史记录
    func appendHistory(_ record: AssociationHistory) {
        var history = loadHistory()
        history.append(record)
        saveHistory(history)
    }

    /// 清空所有数据（测试用）
    func clearAll() {
        try? fileManager.removeItem(at: associationsFile)
        try? fileManager.removeItem(at: historyFile)
    }
}
