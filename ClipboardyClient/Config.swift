//
//  Config.swift
//  ClipboardyClient
//
//  Created by lunks on 15/10/23.
//
import Foundation

let defaultServerEndpoint = "ws://ubuntu.local:3000"
let serverEndpointKey = "WebSocketEndpoint"

class Config {
    static let shared = Config()
    
    private init() {}
    
    var endpoint: String {
        get {
            UserDefaults.standard.string(forKey: serverEndpointKey) ?? defaultServerEndpoint
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: serverEndpointKey)
        }
    }
}
