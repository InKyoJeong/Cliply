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
        panel.onWillShow = { [weak monitor] in monitor?.checkNow() }
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
        statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        self.statusItem = statusItem
    }

    @objc private func statusItemClicked() {
        // Right-click (or control-click) opens the menu; left-click opens the popup.
        let event = NSApp.currentEvent
        let isRightClick = event?.type == .rightMouseUp
            || event?.modifierFlags.contains(.control) == true
        if isRightClick {
            showMenu()
        } else {
            panel?.toggle(relativeTo: statusItem?.button)
        }
    }

    private func showMenu() {
        let menu = NSMenu()

        let open = NSMenuItem(title: "Open Cliply", action: #selector(openPopup), keyEquivalent: "")
        open.target = self
        menu.addItem(open)

        menu.addItem(.separator())

        let clear = NSMenuItem(title: "Clear History", action: #selector(clearHistory), keyEquivalent: "")
        clear.target = self
        menu.addItem(clear)

        menu.addItem(.separator())

        let about = NSMenuItem(title: "About Cliply", action: #selector(showAbout), keyEquivalent: "")
        about.target = self
        menu.addItem(about)

        let quit = NSMenuItem(title: "Quit Cliply", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        // Attaching the menu and clicking pops it up, then we detach so the next
        // left-click still opens the popup instead of the menu.
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }

    @objc private func openPopup() {
        panel?.toggle(relativeTo: statusItem?.button)
    }

    @objc private func clearHistory() {
        ClipboardStore.shared.clear()
    }

    @objc private func showAbout() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(nil)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
