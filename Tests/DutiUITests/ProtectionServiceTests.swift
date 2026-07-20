import XCTest
@testable import DutiUI

final class ProtectionServiceTests: XCTestCase {

    @MainActor
    func testProtectionServiceInitialState() {
        let service = ProtectionService.shared
        XCTAssertFalse(service.isRunning)
        XCTAssertFalse(service.isPaused)
    }

    @MainActor
    func testStartAndStop() {
        let service = ProtectionService.shared
        service.start()
        XCTAssertTrue(service.isRunning)
        XCTAssertFalse(service.isPaused)

        service.stop()
        XCTAssertFalse(service.isRunning)
    }

    @MainActor
    func testPauseAndResume() {
        let service = ProtectionService.shared
        service.start()
        XCTAssertTrue(service.isRunning)

        service.pause()
        XCTAssertTrue(service.isPaused)

        service.resume()
        XCTAssertFalse(service.isPaused)
        XCTAssertTrue(service.isRunning)

        service.stop()
    }

    @MainActor
    func testCantPauseWhenStopped() {
        let service = ProtectionService.shared
        service.stop()
        service.pause()
        // pause 应该不生效
        XCTAssertFalse(service.isPaused)
    }

    @MainActor
    func testCantResumeWhenNotPaused() {
        let service = ProtectionService.shared
        service.stop()
        service.resume()
        // resume 应该不生效
        XCTAssertFalse(service.isRunning)
    }
}
