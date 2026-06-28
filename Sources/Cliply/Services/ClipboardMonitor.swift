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
    private var activity: NSObjectProtocol?

    var pollingInterval: TimeInterval = 0.5

    init(store: ClipboardStore) {
        self.store = store
        self.lastChangeCount = pasteboard.changeCount
    }

    func start() {
        stop()

        // As a background-only (accessory) app we would otherwise be subject to
        // App Nap, which can suspend the polling timer and miss copies. Keep the
        // process active so the timer fires reliably.
        activity = ProcessInfo.processInfo.beginActivity(
            options: .userInitiatedAllowingIdleSystemSleep,
            reason: "Clipboard monitoring"
        )

        let timer = Timer.scheduledTimer(withTimeInterval: pollingInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.poll() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        if let activity {
            ProcessInfo.processInfo.endActivity(activity)
            self.activity = nil
        }
    }

    /// Forces an immediate clipboard check — used right before showing the
    /// popup so a clip copied a moment ago appears without waiting for the next
    /// poll tick.
    func checkNow() {
        poll()
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
