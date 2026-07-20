import XCTest
@testable import DutiUI

final class ExtensionCatalogTests: XCTestCase {
    var catalog: ExtensionCatalog!

    override func setUp() async throws {
        catalog = ExtensionCatalog.shared
    }

    func testSearchByExtension() {
        let results = catalog.search("md")
        XCTAssertTrue(results.contains(where: { $0.ext == "md" }))
    }

    func testSearchByChineseName() {
        let results = catalog.search("Markdown")
        XCTAssertTrue(results.contains(where: { $0.ext == "md" }))
    }

    func testSearchByCategory() {
        let results = catalog.search("图片")
        XCTAssertTrue(results.contains(where: { $0.ext == "jpg" }))
        XCTAssertTrue(results.contains(where: { $0.ext == "png" }))
    }

    func testSearchCaseInsensitive() {
        let lower = catalog.search("pdf")
        let upper = catalog.search("PDF")
        XCTAssertEqual(lower.count, upper.count)
    }

    func testSearchIgnoresLeadingDot() {
        let withDot = catalog.search(".pdf")
        let withoutDot = catalog.search("pdf")
        XCTAssertEqual(withDot.count, withoutDot.count)
    }

    func testFindExactExtension() {
        let info = catalog.find(extension: "md")
        XCTAssertNotNil(info)
        XCTAssertEqual(info?.ext, "md")
    }

    func testFindNonexistentExtension() {
        let info = catalog.find(extension: "xyz123")
        XCTAssertNil(info)
    }

    func testEmptySearchReturnsAll() {
        let results = catalog.search("")
        XCTAssertFalse(results.isEmpty)
        XCTAssertTrue(results.count > 10)
    }

    func testExtensionNormalization() {
        XCTAssertEqual(ManagedAssociation.normalizeExtension("PDF"), "pdf")
        XCTAssertEqual(ManagedAssociation.normalizeExtension(".pdf"), "pdf")
        XCTAssertEqual(ManagedAssociation.normalizeExtension(".PDF"), "pdf")
        XCTAssertEqual(ManagedAssociation.normalizeExtension("  md  "), "md")
    }
}
