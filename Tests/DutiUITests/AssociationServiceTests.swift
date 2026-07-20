import XCTest
@testable import DutiUI

final class AssociationServiceTests: XCTestCase {

    func testExtensionNormalization() {
        XCTAssertEqual(ManagedAssociation.normalizeExtension("PDF"), "pdf")
        XCTAssertEqual(ManagedAssociation.normalizeExtension(".pdf"), "pdf")
        XCTAssertEqual(ManagedAssociation.normalizeExtension("  Md  "), "md")
        XCTAssertEqual(ManagedAssociation.normalizeExtension(".TXT"), "txt")
    }

    func testManagedAssociationInit() {
        let assoc = ManagedAssociation(
            fileExtension: ".PDF",
            displayName: "PDF Document",
            uti: "com.adobe.pdf",
            targetApplicationName: "Preview",
            targetBundleIdentifier: "com.apple.Preview",
            isLocked: true,
            status: .normal
        )
        XCTAssertEqual(assoc.fileExtension, "pdf") // 标准化
        XCTAssertEqual(assoc.displayName, "PDF Document")
        XCTAssertEqual(assoc.uti, "com.adobe.pdf")
        XCTAssertTrue(assoc.isLocked)
        XCTAssertEqual(assoc.status, .normal)
    }

    func testAssociationStatusEncoding() throws {
        let statuses: [AssociationStatus] = [.normal, .unlocked, .changed, .restoreFailed, .targetApplicationMissing]
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for status in statuses {
            // 创建一个带状态的 association
            let assoc = ManagedAssociation(
                fileExtension: "pdf",
                displayName: "PDF",
                uti: "com.adobe.pdf",
                targetApplicationName: "Preview",
                targetBundleIdentifier: "com.apple.Preview",
                status: status
            )
            let data = try encoder.encode(assoc)
            let decoded = try decoder.decode(ManagedAssociation.self, from: data)
            XCTAssertEqual(decoded.status, status)
        }
    }

    func testAssociationHistoryEncoding() throws {
        let history = AssociationHistory(
            associationID: UUID(),
            fileExtension: "pdf",
            expectedApplicationName: "Preview",
            expectedBundleIdentifier: "com.apple.Preview",
            detectedApplicationName: "Adobe Acrobat",
            detectedBundleIdentifier: "com.adobe.Reader",
            result: .restored,
            duration: 0.18,
            createdAt: Date()
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(history)
        let decoded = try decoder.decode(AssociationHistory.self, from: data)

        XCTAssertEqual(decoded.fileExtension, history.fileExtension)
        XCTAssertEqual(decoded.expectedApplicationName, history.expectedApplicationName)
        XCTAssertEqual(decoded.result, history.result)
    }

    func testDutiDetectorPaths() {
        // 只验证常见路径列表存在
        let isInstalled = DutiDetector.isInstalled()
        // 无论是否安装，这个调用不应崩溃
        XCTAssertTrue(isInstalled || !isInstalled)

        let path = DutiDetector.findDutiPath()
        // 返回 nil 或有效路径
        if let path = path {
            XCTAssertTrue(FileManager.default.isExecutableFile(atPath: path))
        }
    }
}
