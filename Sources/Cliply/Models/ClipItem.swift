import Foundation

/// A single entry in the clipboard history.
struct ClipItem: Identifiable, Codable, Equatable {
    let id: UUID
    var createdAt: Date
    var lastUsedAt: Date
    var useCount: Int

    var kind: ClipKind
    /// Stable hash of the normalized content, used for de-duplication.
    var contentHash: String

    var sourceAppBundleID: String?
    var sourceAppName: String?

    /// Short, human-readable summary shown in the list (first line / file name / hex).
    var title: String
    /// Plain-text payload for text / url / color kinds.
    var textValue: String?
    /// Inline image bytes for the image kind (PNG/TIFF). Kept small via the size cap.
    var imageData: Data?

    var byteSize: Int
    var isPinned: Bool

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        kind: ClipKind,
        contentHash: String,
        title: String,
        textValue: String? = nil,
        imageData: Data? = nil,
        byteSize: Int,
        sourceAppBundleID: String? = nil,
        sourceAppName: String? = nil,
        isPinned: Bool = false
    ) {
        self.id = id
        self.createdAt = createdAt
        self.lastUsedAt = createdAt
        self.useCount = 1
        self.kind = kind
        self.contentHash = contentHash
        self.title = title
        self.textValue = textValue
        self.imageData = imageData
        self.byteSize = byteSize
        self.sourceAppBundleID = sourceAppBundleID
        self.sourceAppName = sourceAppName
        self.isPinned = isPinned
    }
}
