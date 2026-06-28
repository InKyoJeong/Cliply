import Foundation

/// Lightweight subsequence fuzzy matching with a relevance score.
///
/// A query matches a candidate when its characters appear in order (not
/// necessarily contiguously). Contiguous runs, word-boundary hits and
/// prefix matches score higher.
enum FuzzySearch {
    /// Returns a match score, or `nil` when the query does not match.
    /// Higher is better.
    static func score(query: String, in candidate: String) -> Int? {
        let query = query.lowercased()
        guard !query.isEmpty else { return 0 }
        let text = Array(candidate.lowercased())
        let pattern = Array(query)

        var score = 0
        var ti = 0
        var pi = 0
        var previousMatchIndex: Int? = nil

        while ti < text.count && pi < pattern.count {
            if text[ti] == pattern[pi] {
                score += 1
                if let prev = previousMatchIndex, prev == ti - 1 {
                    score += 5 // contiguous run bonus
                }
                if ti == 0 || text[ti - 1] == " " || text[ti - 1] == "/" || text[ti - 1] == "_" {
                    score += 3 // word-boundary bonus
                }
                previousMatchIndex = ti
                pi += 1
            }
            ti += 1
        }

        guard pi == pattern.count else { return nil }
        if candidate.lowercased().hasPrefix(query) { score += 10 }
        return score
    }

    /// Filters and ranks history items against a query.
    /// An empty query returns the items unchanged (pinned-first ordering is
    /// handled by the caller).
    static func rank(_ items: [ClipItem], query: String) -> [ClipItem] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return items }

        return items
            .compactMap { item -> (ClipItem, Int)? in
                let haystack = item.textValue ?? item.title
                guard let s = score(query: trimmed, in: haystack) else { return nil }
                return (item, s)
            }
            .sorted { $0.1 > $1.1 }
            .map(\.0)
    }
}
