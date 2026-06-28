import Foundation

/// The kind of content a clip holds. Determines how it is rendered and reused.
enum ClipKind: String, Codable, CaseIterable {
    case text
    case richText
    case image
    case file
    case url
    case color

    var systemImage: String {
        switch self {
        case .text: return "text.alignleft"
        case .richText: return "doc.richtext"
        case .image: return "photo"
        case .file: return "doc"
        case .url: return "link"
        case .color: return "paintpalette"
        }
    }
}
