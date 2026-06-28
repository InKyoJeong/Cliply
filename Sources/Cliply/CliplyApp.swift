import SwiftUI

@main
struct CliplyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // The UI is driven by a manually managed status item and a floating
        // panel (see AppDelegate). This empty Settings scene just satisfies the
        // App protocol's requirement for at least one scene.
        Settings {
            EmptyView()
        }
    }
}
