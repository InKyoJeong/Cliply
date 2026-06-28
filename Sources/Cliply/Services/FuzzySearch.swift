import Foundation

/// Case-insensitive substring search with relevance scoring.
///
/// A query matches a candidate only when it appears as a contiguous substring.
/// Matches at the start of the text or at a word boundary rank higher, and
/// earlier matches rank above later ones.
enum FuzzySearch {
    /// Returns a match score, or `nil` when the candidate does not contain the
    /// query. Higher is better.
    static func score(query: String, in candidate: String) -> Int? {
        let query = query.lowercased()
        guard !query.isEmpty else { return 0 }
        let text = candidate.lowercased()
        guard let range = text.range(of: query) else { return nil }

        var score = 1000
        let start = text.distance(from: text.startIndex, to: range.lowerBound)
        score -= min(start, 100) // earlier match ranks higher

        if range.lowerBound == text.startIndex {
            score += 100 // prefix match
        } else {
            let before = text[text.index(before: range.lowerBound)]
            if before == " " || before == "/" || before == "_" || before == "\n" || before == "-" {
                score += 50 // word-boundary match
            }
        }
        return score
    }

    /// Filters and ranks history items against a query.
    /// An empty query returns the items unchanged (pinned-first ordering is
    /// handled by the caller).
    static func rank(_ items: [ClipItem], query: String) -> [ClipItem] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return items }

        return items
            .enumerated()
            .compactMap { index, item -> (ClipItem, Int, Int)? in
                let haystack = item.textValue ?? item.title
                guard let s = score(query: trimmed, in: haystack) else { return nil }
                return (item, s, index)
            }
            // Higher score first; ties broken by recency (original order).
            .sorted { $0.1 != $1.1 ? $0.1 > $1.1 : $0.2 < $1.2 }
            .map(\.0)
    }
}
