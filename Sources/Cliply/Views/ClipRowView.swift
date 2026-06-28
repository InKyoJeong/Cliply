import SwiftUI

/// A single row in the history popup.
struct ClipRowView: View {
    let item: ClipItem
    let isSelected: Bool

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
            Text(item.title)
                .lineLimit(1)
                .foregroundStyle(isSelected ? Color.white : .primary)
        } else {
            Text(item.title)
                .lineLimit(1)
                .foregroundStyle(isSelected ? Color.white : .primary)
        }
    }
}
