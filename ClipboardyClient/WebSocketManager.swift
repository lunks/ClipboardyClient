import Foundation
import Starscream
import AppKit
import Network

class WebSocketManager {
    var socket: WebSocket!
    var reconnectTimer: Timer?
    var isConnected = false
    var monitor: NWPathMonitor!
    var currentEndpoint: String
    var lastServerID: String?
    var lastChangeCount: Int = NSPasteboard.general.changeCount
    
    private let endpointKey = "WebSocketEndpoint"
    private let lastServerIDKey = "LastServerID"
    
    init() {
        let defaultEndpoint = "ws://ubuntu.local:3000"
        self.currentEndpoint = UserDefaults.standard.string(forKey: endpointKey) ?? defaultEndpoint
        
        var request = URLRequest(url: URL(string: self.currentEndpoint)!)
        request.timeoutInterval = 5
        socket = WebSocket(request: request)
        socket.delegate = self
        
        lastServerID = UserDefaults.standard.string(forKey: lastServerIDKey)
        
        monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            if path.status == .satisfied {
                self.startReconnectTimer()
            } else {
                self.reconnectTimer?.invalidate()
            }
        }

        observeClipboardChanges()
        socket.connect()
    }
    
    func reconnectIfNeeded() {
        if isConnected == false && monitor.currentPath.status == .satisfied {
            print("Reconnecting WebSocket...")
            socket.connect()
        }
    }
    
    func observeClipboardChanges() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if self.lastChangeCount != NSPasteboard.general.changeCount {
                self.lastChangeCount = NSPasteboard.general.changeCount
                self.clipboardChanged()
            }
        }
    }
    
    func clipboardChanged() {
        let pasteboard = NSPasteboard.general
        if let text = pasteboard.string(forType: .string) {
            let message = ["type": "newTextItem", "text": text]
            if let jsonData = try? JSONSerialization.data(withJSONObject: message, options: []) {
                socket.write(data: jsonData)
            }
        }
    }
    
    func updateClipboard(text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    func updateClipboard(imageURL: String) {
        guard let url = URL(string: imageURL) else { return }
        DispatchQueue.global().async {
            if let data = try? Data(contentsOf: url), let image = NSImage(data: data) {
                DispatchQueue.main.async {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.writeObjects([image])
                }
            }
        }
    }
    
    func updateEndpoint(_ newEndpoint: String) {
        UserDefaults.standard.setValue(newEndpoint, forKey: endpointKey)
        socket.disconnect()
        var request = URLRequest(url: URL(string: newEndpoint)!)
        request.timeoutInterval = 5
        socket = WebSocket(request: request)
        socket.delegate = self
        socket.connect()
    }
    deinit {
        reconnectTimer?.invalidate()
    }
    func startReconnectTimer() {
        reconnectTimer?.invalidate()  // Invalidate any existing timer
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.reconnectIfNeeded()
        }
    }
    
}

extension WebSocketManager: WebSocketDelegate {
    func didReceive(event: WebSocketEvent, client: WebSocketClient) {
        switch event {
        case .connected(let headers):
            isConnected = true
            print("WebSocket connected with headers: \(headers)")
            if let lastServerID = self.lastServerID {
                let message = ["type": "retrieve", "id": Int(lastServerID)!] as [String : Any]
                if let jsonData = try? JSONSerialization.data(withJSONObject: message, options: []) {
                    socket.write(data: jsonData)
                }
            }
            reconnectTimer?.invalidate()  // Stop the timer when connected

        case .disconnected(let reason, let code):
            print("WebSocket disconnected due to \(reason) with code \(code)")
            isConnected = false
            startReconnectTimer()
            reconnectIfNeeded()
        case .text(let text):
            if let jsonData = text.data(using: .utf8),
               let clipboardData = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
               let type = clipboardData["type"] as? String, type == "newTextItem",
               let clipboardText = clipboardData["text"] as? String,
               let serverID = clipboardData["id"] as? Int {
                self.updateClipboard(text: clipboardText)
                self.lastServerID = "\(serverID)"
                UserDefaults.standard.setValue(self.lastServerID, forKey: self.lastServerIDKey)
            }
        default:
            break
        }
    }
}
