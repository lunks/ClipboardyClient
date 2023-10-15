// ClipboardyClientApp.swift
import SwiftUI

@main
struct ClipboardyClientApp: App {
    @Environment(\.openWindow) private var openWindow
    
    @StateObject private var webSocketManager = WebSocketManager()
    
    var body: some Scene {
        MenuBarExtra {
            Text("ClipboardyClient")
                .font(.headline)
            Text((webSocketManager.isConnected ? "Connected" : "Disconnected"))
                .font(.subheadline)
            
            Divider()
            
            Button() {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            } label: {
                HStack {
                    Image(systemName: "gearshape")
                    Text("Preferences...")
                }
            }.keyboardShortcut(",")
            
            Divider()
            
            Button("Quit") { NSApp.terminate(nil) }
        } label: {
            Image(systemName: "clipboard.fill")
        }
        Settings {
            SettingsView(webSocketManager: webSocketManager)
        }
    }
}

extension NSApplication {
    
    static func show(ignoringOtherApps: Bool = true) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: ignoringOtherApps)
    }
    
    static func hide() {
        NSApp.hide(self)
        NSApp.setActivationPolicy(.accessory)
    }
}
