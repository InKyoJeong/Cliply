import Foundation
import Observation

/// In-memory history with JSON persistence to Application Support.
/// De-duplicates by content hash and enforces a maximum item count.
@MainActor
@Observable
final class ClipboardStore {
    private(set) var items: [ClipItem] = []

    var maxHistoryCount: Int = 1000

    private let fileURL: URL

    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? Self.defaultFileURL()
        load()
    }

    /// Adds a captured clip. If an identical clip already exists it is promoted
    /// to the top instead of creating a duplicate.
    func add(_ item: ClipItem) {
        if let index = items.firstIndex(where: { $0.contentHash == item.contentHash }) {
            var existing = items.remove(at: index)
            existing.lastUsedAt = Date()
            existing.useCount += 1
            items.insert(existing, at: 0)
        } else {
            items.insert(item, at: 0)
        }
        trim()
        save()
    }

    func remove(_ item: ClipItem) {
        items.removeAll { $0.id == item.id }
        save()
    }

    func clear() {
        items.removeAll()
        save()
    }

    func togglePin(_ item: ClipItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].isPinned.toggle()
        save()
    }

    // MARK: - Maintenance

    private func trim() {
        guard maxHistoryCount > 0 else { return }
        let unpinned = items.filter { !$0.isPinned }
        guard unpinned.count > maxHistoryCount else { return }
        let overflow = unpinned
            .sorted { $0.lastUsedAt < $1.lastUsedAt }
            .prefix(unpinned.count - maxHistoryCount)
        let dropIDs = Set(overflow.map(\.id))
        items.removeAll { dropIDs.contains($0.id) }
    }

    // MARK: - Persistence

    private static func defaultFileURL() -> URL {
        let base = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Cliply", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base.appendingPathComponent("history.json")
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        if let decoded = try? JSONDecoder().decode([ClipItem].self, from: data) {
            items = decoded
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
