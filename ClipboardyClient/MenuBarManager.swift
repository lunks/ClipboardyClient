import SwiftUI
import AppKit

class MenuBarManager: ObservableObject {
    var statusBarItem: NSStatusItem!
    var webSocketManager: WebSocketManager!
    
    init(webSocketManager: WebSocketManager) {
        self.webSocketManager = webSocketManager
        DispatchQueue.main.async {
            self.statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
            if let button = self.statusBarItem.button {
                //button.image = NSImage(named: NSImage.Name("your_icon_name"))  // Replace with your icon
                button.action = #selector(self.showMenu)
                button.target = self
            }
            
            let menu = NSMenu()
            let changeServerItem = NSMenuItem(title: "Set Server Endpoint", action: #selector(self.setServerEndpoint), keyEquivalent: "s")
            changeServerItem.target = self
            let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
            
            menu.addItem(changeServerItem)
            menu.addItem(quitItem)
            
            self.statusBarItem.menu = menu
        }
        
    }
    
    @objc func showMenu() {
        statusBarItem.menu?.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
    }
    
    @objc func setServerEndpoint() {
        let alert = NSAlert()
        alert.messageText = "Set Server Endpoint"
        alert.informativeText = "Please enter the server endpoint:"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        let inputField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        inputField.stringValue = webSocketManager.currentEndpoint
        alert.accessoryView = inputField
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            webSocketManager.updateEndpoint(inputField.stringValue)
        }
    }
}
