import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var webSocketManager: WebSocketManager
    @State var serverEndpoint: String
    
    init(webSocketManager: WebSocketManager) {
        self.webSocketManager = webSocketManager
        self._serverEndpoint = State(initialValue: Config.shared.endpoint)
    }
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "network")
                    .foregroundColor(.gray)
                TextField("Server Endpoint", text: $serverEndpoint)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding()
            
            Spacer()
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Save") {
                    Config.shared.endpoint = serverEndpoint
                    webSocketManager.refreshEndpointAndConnect()
                    print("Endpoint saved: \(self.serverEndpoint)")
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .padding()
        .frame(width: 400, height: 200)
    }
}
