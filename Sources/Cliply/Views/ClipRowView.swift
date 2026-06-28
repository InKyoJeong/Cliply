import SwiftUI

/// A single row in the history popup.
struct ClipRowView: View {
    let item: ClipItem
    let isSelected: Bool
    var query: String = ""

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f
    }()

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: item.kind.systemImage)
                .frame(width: 18)
                .foregroundStyle(isSelected ? Color.white : .secondary)

            preview

            Spacer(minLength: 8)

            if item.isPinned {
                Image(systemName: "pin.fill")
                    .font(.caption2)
                    .foregroundStyle(isSelected ? Color.white : .secondary)
            }

            Text(Self.relativeFormatter.localizedString(for: item.lastUsedAt, relativeTo: Date()))
                .font(.caption2)
                .foregroundStyle(isSelected ? Color.white.opacity(0.8) : .secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(isSelected ? Color.accentColor : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var preview: some View {
        if let data = item.imageData, let image = NSImage(data: data) {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 28, height: 28)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            Text(displayText).lineLimit(1)
        } else {
            Text(displayText).lineLimit(1)
        }
    }

    /// When searching, show a snippet centered on the match with the matched
    /// text highlighted — so it's clear why the item matched (the term may be
    /// buried deep in a long, multi-line clip). Otherwise show the title.
    private var displayText: AttributedString {
        let q = query.trimmingCharacters(in: .whitespaces)
        let source = item.textValue ?? item.title

        guard !q.isEmpty,
              let match = source.range(of: q, options: .caseInsensitive) else {
            var attr = AttributedString(item.title)
            attr.foregroundColor = isSelected ? .white : .primary
            return attr
        }

        let leading = 12
        let startOffset = source.distance(from: source.startIndex, to: match.lowerBound)
        let snippetStart = source.index(source.startIndex, offsetBy: max(0, startOffset - leading))
        var snippet = String(source[snippetStart...])
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
        if startOffset - leading > 0 { snippet = "…" + snippet }
        snippet = String(snippet.prefix(100))

        var attr = AttributedString(snippet)
        attr.foregroundColor = isSelected ? .white : .primary
        if let r = attr.range(of: q, options: .caseInsensitive) {
            attr[r].inlinePresentationIntent = .stronglyEmphasized
            attr[r].foregroundColor = isSelected ? .white : .accentColor
        }
        return attr
    }
}
