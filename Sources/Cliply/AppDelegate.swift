import AppKit

/// Owns the app-wide services and runs as a menu-bar accessory (no Dock icon).
///
/// We manage the status item manually (instead of SwiftUI's `MenuBarExtra`)
/// because `MenuBarExtra(.window)` caches its content and does not reliably
/// refresh when the history changes. Both the status-item click and the global
/// hotkey open the same panel, which does refresh correctly.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var monitor: ClipboardMonitor?
    private var hotkey: HotkeyService?
    private var panel: PopupPanelController?
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let monitor = ClipboardMonitor(store: .shared)
        monitor.start()
        self.monitor = monitor

        let panel = PopupPanelController(store: .shared)
        self.panel = panel

        let hotkey = HotkeyService()
        hotkey.onTrigger = { [weak panel] in panel?.toggle() }
        hotkey.register()
        self.hotkey = hotkey

        setUpStatusItem()
    }

    private func setUpStatusItem() {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = NSImage(
            systemSymbolName: "doc.on.clipboard",
            accessibilityDescription: "Cliply"
        )
        statusItem.button?.target = self
        statusItem.button?.action = #selector(statusItemClicked)
        self.statusItem = statusItem
    }

    @objc private func statusItemClicked() {
        panel?.toggle(relativeTo: statusItem?.button)
    }
}
