import SwiftUI

@main
struct CliplyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("Cliply", systemImage: "doc.on.clipboard") {
            Text("Cliply")
                .font(.headline)
                .padding()
        }
        .menuBarExtraStyle(.window)
    }
}
