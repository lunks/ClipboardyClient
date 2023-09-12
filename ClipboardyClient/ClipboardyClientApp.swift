import SwiftUI

@main
struct ClipboardyClientApp: App {
    private var webSocketManager = WebSocketManager()
    private var menuBarManager: MenuBarManager!

    init() {
        menuBarManager = MenuBarManager(webSocketManager: webSocketManager)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
