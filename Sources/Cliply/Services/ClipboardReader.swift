import AppKit
import CryptoKit

/// Reads the current contents of an `NSPasteboard` into a `ClipItem`,
/// picking the most meaningful representation available.
enum ClipboardReader {
    static func read(from pasteboard: NSPasteboard) -> ClipItem? {
        let app = NSWorkspace.shared.frontmostApplication
        let bundleID = app?.bundleIdentifier
        let appName = app?.localizedName

        // Priority: files > image > text (url/color/plain).
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self]) as? [URL],
           urls.contains(where: { $0.isFileURL }) {
            let paths = urls.filter(\.isFileURL).map(\.path)
            let joined = paths.joined(separator: "\n")
            return ClipItem(
                kind: .file,
                contentHash: hash(joined),
                title: paths.count == 1 ? (paths.first.map { ($0 as NSString).lastPathComponent } ?? joined) : "\(paths.count) files",
                textValue: joined,
                byteSize: joined.utf8.count,
                sourceAppBundleID: bundleID,
                sourceAppName: appName
            )
        }

        if let image = NSImage(pasteboard: pasteboard),
           let tiff = image.tiffRepresentation,
           let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:]) {
            return ClipItem(
                kind: .image,
                contentHash: hash(png),
                title: "Image \(Int(image.size.width))×\(Int(image.size.height))",
                imageData: png,
                byteSize: png.count,
                sourceAppBundleID: bundleID,
                sourceAppName: appName
            )
        }

        if let string = pasteboard.string(forType: .string) {
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            let kind = classify(trimmed)
            let hasRichText = pasteboard.data(forType: .rtf) != nil
            return ClipItem(
                kind: hasRichText ? .richText : kind,
                contentHash: hash(string),
                title: summary(of: string),
                textValue: string,
                byteSize: string.utf8.count,
                sourceAppBundleID: bundleID,
                sourceAppName: appName
            )
        }

        return nil
    }

    // MARK: - Helpers

    private static func classify(_ text: String) -> ClipKind {
        if text.range(of: #"^https?://"#, options: .regularExpression) != nil {
            return .url
        }
        if text.range(of: #"^#?[0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?$"#, options: .regularExpression) != nil {
            return .color
        }
        return .text
    }

    private static func summary(of text: String) -> String {
        let firstLine = text
            .split(whereSeparator: \.isNewline)
            .first
            .map(String.init)?
            .trimmingCharacters(in: .whitespaces) ?? text
        return String(firstLine.prefix(200))
    }

    private static func hash(_ string: String) -> String {
        hash(Data(string.utf8))
    }

    private static func hash(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}
