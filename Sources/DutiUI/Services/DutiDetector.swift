import Foundation

/// 检测系统中 duti 的安装状态和路径
enum DutiDetector {
    /// 常见的 duti 安装路径
    private static let commonPaths = [
        "/opt/homebrew/bin/duti",
        "/usr/local/bin/duti",
        "/opt/local/bin/duti",
        "/usr/bin/duti"
    ]

    /// 检测 duti 是否安装
    static func isInstalled() -> Bool {
        findDutiPath() != nil
    }

    /// 查找 duti 可执行文件的路径
    /// 返回 nil 表示未找到
    static func findDutiPath() -> String? {
        // 先检查常见路径
        for path in commonPaths {
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }

        // 尝试通过 which 查找
        if let path = try? CommandRunner.run(
            executablePath: "/usr/bin/env",
            arguments: ["which", "duti"],
            timeout: 3
        ) {
            let trimmed = path.standardOutput.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty, FileManager.default.isExecutableFile(atPath: trimmed) {
                return trimmed
            }
        }

        return nil
    }

    /// 获取安装指导信息
    static func installGuide() -> String {
        "brew install duti"
    }
}
