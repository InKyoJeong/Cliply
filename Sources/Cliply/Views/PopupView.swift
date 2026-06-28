import SwiftUI

/// The history popup: a search field plus a keyboard-navigable result list.
struct PopupView: View {
    let store: ClipboardStore

    @State private var query = ""
    @State private var selection = 0
    @State private var window: NSWindow?
    @FocusState private var searchFocused: Bool

    private var results: [ClipItem] {
        if query.trimmingCharacters(in: .whitespaces).isEmpty {
            return store.items.filter(\.isPinned) + store.items.filter { !$0.isPinned }
        }
        return FuzzySearch.rank(store.items, query: query)
    }

    var body: some View {
        VStack(spacing: 0) {
            searchField
            Divider()
            resultsList
            Divider()
            hintBar
        }
        .frame(width: 360, height: 420)
        .ignoresSafeArea(.all)
        .background(WindowAccessor { window = $0 })
        .onKeyPress(.downArrow) { move(1); return .handled }
        .onKeyPress(.upArrow) { move(-1); return .handled }
        .onKeyPress(.return) { activateSelection(); return .handled }
        .onKeyPress(.escape) { close(); return .handled }
        .onChange(of: query) { selection = 0 }
        .onAppear { searchFocused = true }
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField("Search clipboard…", text: $query)
                .textFieldStyle(.plain)
                .focused($searchFocused)
        }
        .padding(10)
    }

    private var resultsList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 2) {
                    if results.isEmpty {
                        Text(query.isEmpty ? "No clipboard history yet" : "No results")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                    }
                    ForEach(Array(results.enumerated()), id: \.element.id) { index, item in
                        ClipRowView(item: item, isSelected: index == selection)
                            .id(index)
                            .onTapGesture { selection = index; activateSelection() }
                    }
                }
                .padding(6)
            }
            .onChange(of: selection) { proxy.scrollTo(selection, anchor: .center) }
        }
    }

    private var hintBar: some View {
        HStack(spacing: 12) {
            Label("Navigate", systemImage: "arrow.up.arrow.down")
            Label("Paste", systemImage: "return")
            Label("Close", systemImage: "escape")
            Spacer()
            Text("\(results.count)")
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }

    // MARK: - Actions

    private func move(_ delta: Int) {
        guard !results.isEmpty else { return }
        selection = min(max(selection + delta, 0), results.count - 1)
    }

    private func activateSelection() {
        guard results.indices.contains(selection) else { return }
        ClipboardWriter.write(results[selection])
        close()
    }

    private func close() {
        window?.close()
        query = ""
        selection = 0
    }
}

/// Grabs the hosting `NSWindow` so the popup can close itself.
private struct WindowAccessor: NSViewRepresentable {
    let onResolve: (NSWindow?) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { onResolve(view.window) }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
