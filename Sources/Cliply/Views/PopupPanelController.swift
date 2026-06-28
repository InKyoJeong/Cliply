import AppKit
import SwiftUI

/// A floating panel that hosts the history popup, shown via the global hotkey.
@MainActor
final class PopupPanelController {
    private let panel: FloatingPanel
    private let store: ClipboardStore

    /// Called just before the panel becomes visible (e.g. to force an immediate
    /// clipboard check so the latest clip is present).
    var onWillShow: (() -> Void)?

    init(store: ClipboardStore) {
        self.store = store
        panel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 420),
            // No .nonactivatingPanel: the panel must become the key window so
            // the search field receives keystrokes.
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.isReleasedWhenClosed = false
        panel.isMovableByWindowBackground = true
        // Auto-hide when the app is deactivated (user clicks another app). This
        // is the robust way to get "click outside closes" without the focus
        // races that custom resign-key handling caused.
        panel.hidesOnDeactivate = true
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true
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

        // Rebuild the content fresh on every open so the search field, selection
        // and list always reflect the current history (no stale state).
        panel.contentView = NoInsetHostingView(rootView: PopupView(store: store))

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

/// Hosting view that doesn't reserve safe-area space for the (hidden) title bar,
/// so the content fills all the way to the top edge.
final class NoInsetHostingView<Content: View>: NSHostingView<Content> {
    override var safeAreaInsets: NSEdgeInsets {
        NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
}
