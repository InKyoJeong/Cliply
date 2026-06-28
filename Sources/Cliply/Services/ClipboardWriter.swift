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
        default:
            if let text = item.textValue {
                pasteboard.setString(text, forType: .string)
            }
        }
    }
}
