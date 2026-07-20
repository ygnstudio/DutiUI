import Foundation

/// 检测系统中 duti 和 Homebrew 的安装状态
enum DutiDetector {
    /// 常见的 duti 安装路径
    private static let commonDutiPaths = [
        "/opt/homebrew/bin/duti",
        "/usr/local/bin/duti",
        "/opt/local/bin/duti",
    ]

    /// 常见的 Homebrew (brew) 安装路径
    private static let commonBrewPaths = [
        "/opt/homebrew/bin/brew",
        "/usr/local/bin/brew",
    ]

    // MARK: - duti Detection

    /// 检测 duti 是否安装
    static func isDutiInstalled() -> Bool {
        findDutiPath() != nil
    }

    /// 查找 duti 可执行文件的路径，返回 nil 表示未找到
    static func findDutiPath() -> String? {
        for path in commonDutiPaths {
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }
        // 尝试通过 which 查找
        if let result = try? CommandRunner.run(
            executablePath: "/usr/bin/env",
            arguments: ["which", "duti"],
            timeout: 3
        ) {
            let trimmed = result.standardOutput.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty, FileManager.default.isExecutableFile(atPath: trimmed) {
                return trimmed
            }
        }
        return nil
    }

    // MARK: - Homebrew Detection

    /// 检测 Homebrew 是否安装
    static func isHomebrewInstalled() -> Bool {
        findBrewPath() != nil
    }

    /// 查找 brew 可执行文件的路径，返回 nil 表示未找到
    static func findBrewPath() -> String? {
        for path in commonBrewPaths {
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }
        // 尝试通过 which 查找
        if let result = try? CommandRunner.run(
            executablePath: "/usr/bin/env",
            arguments: ["which", "brew"],
            timeout: 3
        ) {
            let trimmed = result.standardOutput.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty, FileManager.default.isExecutableFile(atPath: trimmed) {
                return trimmed
            }
        }
        return nil
    }

    // MARK: - Legacy Compatibility

    static func installGuide() -> String { "brew install duti" }
}
