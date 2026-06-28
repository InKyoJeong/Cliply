import AppKit

/// Writes a stored clip back to the general pasteboard so it can be pasted.
enum ClipboardWriter {
    static func write(_ item: ClipItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        switch item.kind {
        case .image:
            if let data = item.imageData {
                pasteboard.setData(data, forType: .png)
            }
        case .file:
            // Restore the actual file references (plus the path as text fallback).
            if let text = item.textValue {
                let urls = text.split(separator: "\n").map { URL(fileURLWithPath: String($0)) as NSURL }
                if !urls.isEmpty {
                    pasteboard.writeObjects(urls)
                }
                pasteboard.setString(text, forType: .string)
            }
        default:
            if let text = item.textValue {
                pasteboard.setString(text, forType: .string)
            }
        }
    }
}
