import XCTest
@testable import DutiUI

final class PersistenceControllerTests: XCTestCase {
    var persistence: PersistenceController!

    override func setUp() async throws {
        persistence = PersistenceController.shared
        persistence.clearAll()
    }

    override func tearDown() async throws {
        persistence.clearAll()
    }

    func testSaveAndLoadAssociations() {
        let assoc = ManagedAssociation(
            fileExtension: "pdf",
            displayName: "PDF Document",
            uti: "com.adobe.pdf",
            targetApplicationName: "Preview",
            targetBundleIdentifier: "com.apple.Preview",
            isLocked: true,
            status: .normal
        )

        persistence.saveAssociations([assoc])
        let loaded = persistence.loadAssociations()

        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.fileExtension, "pdf")
        XCTAssertEqual(loaded.first?.targetApplicationName, "Preview")
        XCTAssertTrue(loaded.first?.isLocked ?? false)
    }

    func testSaveMultipleAssociations() {
        let assocs = [
            ManagedAssociation(
                fileExtension: "pdf",
                displayName: "PDF",
                uti: "com.adobe.pdf",
                targetApplicationName: "Preview",
                targetBundleIdentifier: "com.apple.Preview"
            ),
            ManagedAssociation(
                fileExtension: "md",
                displayName: "Markdown",
                uti: "net.daringfireball.markdown",
                targetApplicationName: "Obsidian",
                targetBundleIdentifier: "md.obsidian"
            ),
            ManagedAssociation(
                fileExtension: "txt",
                displayName: "Text",
                uti: "public.plain-text",
                targetApplicationName: "TextEdit",
                targetBundleIdentifier: "com.apple.TextEdit"
            )
        ]

        persistence.saveAssociations(assocs)
        let loaded = persistence.loadAssociations()

        XCTAssertEqual(loaded.count, 3)
    }

    func testSaveAndLoadHistory() {
        let history = AssociationHistory(
            associationID: UUID(),
            fileExtension: "pdf",
            expectedApplicationName: "Preview",
            expectedBundleIdentifier: "com.apple.Preview",
            detectedApplicationName: "Adobe",
            detectedBundleIdentifier: "com.adobe.Reader",
            result: .restored,
            duration: 0.18
        )

        persistence.appendHistory(history)
        let loaded = persistence.loadHistory()

        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.fileExtension, "pdf")
        XCTAssertEqual(loaded.first?.result, .restored)
    }

    func testHistoryMaxRecords() {
        // 创建 510 条记录
        for i in 0..<510 {
            let history = AssociationHistory(
                associationID: UUID(),
                fileExtension: "pdf",
                expectedApplicationName: "App",
                expectedBundleIdentifier: "com.example",
                result: .restored,
                createdAt: Date().addingTimeInterval(Double(i))
            )
            persistence.appendHistory(history)
        }

        let loaded = persistence.loadHistory()
        // 应该只保留 500 条
        XCTAssertEqual(loaded.count, 500)
    }

    func testEmptyState() {
        // 清空后应该返回空数组
        persistence.clearAll()
        XCTAssertTrue(persistence.loadAssociations().isEmpty)
        XCTAssertTrue(persistence.loadHistory().isEmpty)
    }
}
