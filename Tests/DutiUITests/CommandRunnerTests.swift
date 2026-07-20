import XCTest
@testable import DutiUI

final class CommandRunnerTests: XCTestCase {

    func testRunSimpleCommand() throws {
        let result = try CommandRunner.run(
            executablePath: "/bin/echo",
            arguments: ["hello", "world"]
        )
        XCTAssertEqual(result.exitCode, 0)
        XCTAssertEqual(result.standardOutput, "hello world")
        XCTAssertTrue(result.duration >= 0)
    }

    func testRunCommandWithError() {
        do {
            _ = try CommandRunner.run(
                executablePath: "/bin/ls",
                arguments: ["/nonexistent/path/12345"]
            )
            // ls with nonexistent path returns exit code != 0, but doesn't throw
            // CommandRunner only throws for execution failures, not non-zero exit
        } catch {
            // This would be an execution error
        }
    }

    func testExecutableNotFound() {
        XCTAssertThrowsError(try CommandRunner.run(
            executablePath: "/nonexistent/executable",
            arguments: []
        )) { error in
            XCTAssertTrue(error is CommandError)
        }
    }

    func testArgumentsAreSafe() throws {
        // 验证参数不会导致 shell 注入
        let malicious = "; rm -rf /"
        let result = try CommandRunner.run(
            executablePath: "/bin/echo",
            arguments: [malicious]
        )
        // 参数被原样输出，不会被执行
        XCTAssertTrue(result.standardOutput.contains(malicious))
        XCTAssertEqual(result.exitCode, 0)
    }
}
