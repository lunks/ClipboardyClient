import Foundation
import Starscream
import AppKit
import Network
import SwiftUI

class WebSocketManager: ObservableObject {
    var reconnectTimer: Timer?
    private let socketQueue = DispatchQueue(label: "contact.pedro.cliboardy.SocketQueue")

    @Published var isConnected = false {
        didSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    lazy var socket: WebSocket = {
        return createWebSocket()
    }()

    lazy var monitor: NWPathMonitor = {
        return createNetworkMonitor()
    }()
    var currentEndpoint: String
    var lastServerID: String?
    var lastChangeCount: Int = NSPasteboard.general.changeCount
    let lastServerIDKey = "LastServerID"
    
    init() {
        self.currentEndpoint = Config.shared.endpoint
        lastServerID = UserDefaults.standard.string(forKey: lastServerIDKey)
        self.observeClipboardChanges()
        self.socket.delegate = self
        self.connectWebSocket()
        self.startReconnectTimer()
        
    }
    
    func createWebSocket() -> WebSocket {
        var request = URLRequest(url: URL(string: currentEndpoint)!)
        request.timeoutInterval = 5
        let ws = WebSocket(request: request)
        return ws
    }

    func createNetworkMonitor() -> NWPathMonitor {
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            if path.status == .satisfied {
                print("Network is available")
                self?.reconnectIfNeeded()
            } else {
                print("No network")
            }
        }
        let queue = DispatchQueue(label: "NetworkMonitorQueue")
        monitor.start(queue: queue)
        return monitor
    }

    func reconnectIfNeeded() {
        print("reconnectIfNeeded")
        print(isConnected, monitor.currentPath.status)
        if isConnected == false && monitor.currentPath.status == .satisfied {
            connectWebSocket()
            print("reconnectTriggered")
        }
    }

    func connectWebSocket() {
        socketQueue.async {
            self.socket.disconnect()
            self.socket = self.createWebSocket()
            self.socket.delegate = self
            self.socket.connect()
        }
    }
    
    func startReconnectTimer() {
        print("startReconnectTimer")
        DispatchQueue.main.async {
            self.reconnectTimer?.invalidate()
            self.reconnectTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
                self.reconnectIfNeeded()
            }
        }
    }
    
    func observeClipboardChanges() {
        DispatchQueue.main.async {
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                if self.lastChangeCount != NSPasteboard.general.changeCount {
                    self.lastChangeCount = NSPasteboard.general.changeCount
                    self.clipboardChanged()
                }
            }
        }
    }
    
    func clipboardChanged() {
        let pasteboard = NSPasteboard.general
        if let text = pasteboard.string(forType: .string) {
            let message = ["type": "newTextItem", "text": text]
            if let jsonData = try? JSONSerialization.data(withJSONObject: message, options: []) {
                if isConnected {
                    socket.write(data: jsonData)
                }
            }
        }
    }
    
    func updateClipboard(text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    func updateClipboard(imageURL: String) {
        if let data = try? Data(contentsOf: URL(string: imageURL)!), let image = NSImage(data: data) {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.writeObjects([image])
        }
    }
    
    func refreshEndpointAndConnect() {
        if self.currentEndpoint == Config.shared.endpoint {
            return
        }
        self.isConnected = false
        self.currentEndpoint = Config.shared.endpoint
        self.startReconnectTimer()
    }
    
    deinit {
        print("deallocated")
        reconnectTimer?.invalidate()
    }
}

extension WebSocketManager: WebSocketDelegate {
    func didReceive(event: WebSocketEvent, client: WebSocketClient) {
        DispatchQueue.main.async {
            switch event {
            case .connected:
                print("connected")
                self.isConnected = true
                self.reconnectTimer?.invalidate()
            case .disconnected, .error:
                print("disconnected")
                self.isConnected = false
                self.startReconnectTimer()
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
}
