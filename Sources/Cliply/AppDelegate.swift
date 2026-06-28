import AppKit

/// Owns the app-wide services and runs as a menu-bar accessory (no Dock icon).
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let store = ClipboardStore()

    private var monitor: ClipboardMonitor?
    private var hotkey: HotkeyService?
    private var panel: PopupPanelController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let monitor = ClipboardMonitor(store: store)
        monitor.start()
        self.monitor = monitor

        let panel = PopupPanelController(store: store)
        self.panel = panel

        let hotkey = HotkeyService()
        hotkey.onTrigger = { [weak panel] in panel?.toggle() }
        hotkey.register()
        self.hotkey = hotkey
    }
}
