import SwiftUI

@main
struct CliplyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("Cliply", systemImage: "doc.on.clipboard") {
            PopupView(store: appDelegate.store)
        }
        .menuBarExtraStyle(.window)
    }
}
