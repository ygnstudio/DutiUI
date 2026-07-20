import Foundation

/// 内置扩展名目录
/// 负责加载 builtin_extensions.json 并提供搜索功能
@MainActor
final class ExtensionCatalog: Sendable {
    static let shared = ExtensionCatalog()

    private var extensions: [ExtensionInfo] = []

    private init() {
        loadBuiltinExtensions()
    }

    // MARK: - Loading

    private func loadBuiltinExtensions() {
        guard let url = Bundle.module.url(
            forResource: "builtin_extensions",
            withExtension: "json"
        ) else {
            print("[ExtensionCatalog] Failed to locate builtin_extensions.json in bundle")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            extensions = try decoder.decode([ExtensionInfo].self, from: data)
        } catch {
            print("[ExtensionCatalog] Failed to load extensions: \(error)")
        }
    }

    // MARK: - Search

    /// 搜索扩展名
    /// - Parameter query: 用户输入（支持扩展名、中文名、英文名、分类名）
    /// - Returns: 匹配的 ExtensionInfo 列表
    func search(_ query: String) -> [ExtensionInfo] {
        let normalizedQuery = query.lowercased().trimmingCharacters(in: .whitespaces)
        guard !normalizedQuery.isEmpty else {
            return extensions.sorted { $0.ext < $1.ext }
        }

        // 去掉开头可能存在的点号
        let cleanQuery = normalizedQuery.replacingOccurrences(of: ".", with: "")

        return extensions.filter { info in
            // 扩展名匹配
            if info.ext.lowercased().contains(cleanQuery) {
                return true
            }
            // 中文名匹配
            if let zh = info.displayName["zh-Hans"], zh.lowercased().contains(cleanQuery) {
                return true
            }
            // 英文名匹配
            if let en = info.displayName["en"], en.lowercased().contains(cleanQuery) {
                return true
            }
            // 分类匹配
            if info.localizedCategory.lowercased().contains(cleanQuery) {
                return true
            }
            // 分类英文名匹配
            if info.category.lowercased().contains(cleanQuery) {
                return true
            }
            return false
        }.sorted { $0.ext < $1.ext }
    }

    /// 精确查找某个扩展名
    func find(extension ext: String) -> ExtensionInfo? {
        let normalized = ManagedAssociation.normalizeExtension(ext)
        return extensions.first { $0.ext == normalized }
    }

    /// 获取所有扩展名
    func allExtensions() -> [ExtensionInfo] {
        extensions
    }

    /// 重新加载（开发调试用）
    func reload() {
        loadBuiltinExtensions()
    }
}
