import AppKit

/// Watches the general pasteboard for changes and forwards new clips to the store.
///
/// macOS does not push clipboard-change notifications, so we poll `changeCount`
/// on a timer and only read the pasteboard when it actually changed.
@MainActor
final class ClipboardMonitor {
    private let pasteboard = NSPasteboard.general
    private let store: ClipboardStore
    private var lastChangeCount: Int
    private var timer: Timer?

    var pollingInterval: TimeInterval = 0.5

    init(store: ClipboardStore) {
        self.store = store
        self.lastChangeCount = pasteboard.changeCount
    }

    func start() {
        stop()
        let timer = Timer.scheduledTimer(withTimeInterval: pollingInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.poll() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func poll() {
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount

        guard PrivacyFilter.shouldStore(pasteboard) else { return }
        guard let item = ClipboardReader.read(from: pasteboard) else { return }
        guard item.byteSize <= PrivacyFilter.maxItemBytes else { return }
        store.add(item)
    }
}
