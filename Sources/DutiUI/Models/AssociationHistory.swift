import Foundation

/// 关联变化历史记录
struct AssociationHistory: Codable, Identifiable {
    let id: UUID
    let associationID: UUID
    let fileExtension: String
    let expectedApplicationName: String
    let expectedBundleIdentifier: String
    let detectedApplicationName: String?
    let detectedBundleIdentifier: String?
    let result: RestoreResult
    let errorMessage: String?
    let duration: TimeInterval?
    let createdAt: Date

    init(
        id: UUID = UUID(),
        associationID: UUID,
        fileExtension: String,
        expectedApplicationName: String,
        expectedBundleIdentifier: String,
        detectedApplicationName: String? = nil,
        detectedBundleIdentifier: String? = nil,
        result: RestoreResult,
        errorMessage: String? = nil,
        duration: TimeInterval? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.associationID = associationID
        self.fileExtension = fileExtension
        self.expectedApplicationName = expectedApplicationName
        self.expectedBundleIdentifier = expectedBundleIdentifier
        self.detectedApplicationName = detectedApplicationName
        self.detectedBundleIdentifier = detectedBundleIdentifier
        self.result = result
        self.errorMessage = errorMessage
        self.duration = duration
        self.createdAt = createdAt
    }
}
