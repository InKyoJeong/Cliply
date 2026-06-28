import AppKit
import SwiftUI

/// A floating panel that hosts the history popup, shown via the global hotkey.
@MainActor
final class PopupPanelController {
    private let panel: FloatingPanel

    /// Called just before the panel becomes visible (e.g. to force an immediate
    /// clipboard check so the latest clip is present).
    var onWillShow: (() -> Void)?

    init(store: ClipboardStore) {
        panel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 420),
            styleMask: [.titled, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.isReleasedWhenClosed = false
        panel.isMovableByWindowBackground = true
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        panel.contentView = NSHostingView(rootView: PopupView(store: store))

        // Dismiss when the user clicks outside / switches apps, like a menu.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(panelDidResignKey),
            name: NSWindow.didResignKeyNotification,
            object: panel
        )
    }

    @objc private func panelDidResignKey() {
        panel.orderOut(nil)
    }

    /// Toggles the panel. When `anchor` is given (the status-item button), the
    /// panel appears just below it; otherwise it is centered near the cursor.
    func toggle(relativeTo anchor: NSStatusBarButton? = nil) {
        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            show(relativeTo: anchor)
        }
    }

    private func show(relativeTo anchor: NSStatusBarButton?) {
        onWillShow?()
        if let anchor, let anchorWindow = anchor.window {
            position(below: anchor, in: anchorWindow)
        } else {
            positionNearCursor()
        }
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }

    private func position(below anchor: NSStatusBarButton, in anchorWindow: NSWindow) {
        let frameInScreen = anchorWindow.convertToScreen(anchor.convert(anchor.bounds, to: nil))
        let size = panel.frame.size
        var origin = NSPoint(
            x: frameInScreen.midX - size.width / 2,
            y: frameInScreen.minY - size.height - 4
        )
        if let visible = anchor.window?.screen?.visibleFrame ?? NSScreen.main?.visibleFrame {
            origin.x = min(max(origin.x, visible.minX + 8), visible.maxX - size.width - 8)
        }
        panel.setFrameOrigin(origin)
    }

    private func positionNearCursor() {
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(NSEvent.mouseLocation) })
            ?? NSScreen.main else { return }
        let size = panel.frame.size
        let cursor = NSEvent.mouseLocation
        let visible = screen.visibleFrame
        var origin = NSPoint(x: cursor.x - size.width / 2, y: cursor.y - size.height)
        origin.x = min(max(origin.x, visible.minX + 8), visible.maxX - size.width - 8)
        origin.y = min(max(origin.y, visible.minY + 8), visible.maxY - size.height - 8)
        panel.setFrameOrigin(origin)
    }
}

/// An `NSPanel` that can become key so the search field receives keystrokes.
final class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}
