import SwiftUI

@main
struct CliplyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @StateObject private var store = ClipboardStore()
    @State private var monitor: ClipboardMonitor?

    var body: some Scene {
        MenuBarExtra("Cliply", systemImage: "doc.on.clipboard") {
            VStack(alignment: .leading) {
                Text("Cliply")
                    .font(.headline)
                Text("\(store.items.count) items")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .onAppear(perform: startMonitorIfNeeded)
        }
        .menuBarExtraStyle(.window)
    }

    private func startMonitorIfNeeded() {
        guard monitor == nil else { return }
        let monitor = ClipboardMonitor(store: store)
        monitor.start()
        self.monitor = monitor
    }
}
