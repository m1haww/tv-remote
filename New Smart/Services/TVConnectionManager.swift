import SwiftUI
import Combine
import SmartView

class TVConnectionManager: ObservableObject {
    static let shared = TVConnectionManager()

    @Published var isConnectedToTV: Bool = false
    @Published var connectedTV: DiscoveredTV?
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var samsungTVService: Service?
    @Published var connectionError: String?

    private let tvController = TVController.shared
    private var connectionTimer: Timer?

    private init() {}

    enum ConnectionStatus {
        case disconnected
        case connecting
        case connected
        case failed
    }

    @MainActor
    func connectToTV(_ tv: DiscoveredTV) {
        print("📡 TVConnectionManager: Starting connection to \(tv.name) at \(tv.ipAddress)")
        connectionStatus = .connecting
        connectionError = nil

        // Clear any existing connection
        disconnectFromTV()

        connectedTV = tv

        // Connect TVController to the TV
        print("🔗 TVConnectionManager: Initializing WebSocket connection...")

        // Set up connection status callback
        tvController.connectionStatusChanged = { [weak self] isConnected in
            if isConnected {
                self?.connectionStatus = .connected
                self?.isConnectedToTV = true
                print("✅ TVConnectionManager: WebSocket connection established!")
            } else if self?.connectionStatus != .connecting {
                self?.connectionStatus = .disconnected
                self?.isConnectedToTV = false
                self?.connectedTV = nil
                self?.samsungTVService = nil
                print("❌ TVConnectionManager: WebSocket connection lost!")
            }
        }

        tvController.connectToTV(ipAddress: tv.ipAddress)

        samsungTVService = NetworkScanner.shared.getSamsungTVService(for: tv)
        connectionStatus = .connecting
        isConnectedToTV = false
    }

    @MainActor
    func connectSamsungTVService(_ service: Service, discoveredTV: DiscoveredTV) {
        print("📺 TVConnectionManager: Connecting Samsung TV service for \(discoveredTV.name)")
        samsungTVService = service

        connectToTV(discoveredTV)
    }
    
    func disconnectFromTV() {
        // Clean up connection timer
        connectionTimer?.invalidate()
        connectionTimer = nil

        let tvName = connectedTV?.name ?? "Unknown TV"

        // Disconnect from WebSocket
        tvController.disconnectTV()

        // Reset all connection state
        connectedTV = nil
        isConnectedToTV = false
        connectionStatus = .disconnected
        connectionError = nil
        samsungTVService = nil

        print("🔌 TVConnectionManager: Disconnected from TV: \(tvName)")
    }
    
    func toggleConnection() {
        if isConnectedToTV {
            disconnectFromTV()
        } else {
            print("🔍 Looking for TVs to connect...")
        }
    }
    
    func sendTVCommand(_ command: TVCommand) {
        print("🎮 TVConnectionManager: Received command \(command)")
        print("📊 TVConnectionManager: Check connection status - isConnected: \(isConnectedToTV)")
        
        guard isConnectedToTV else {
            print("❌ TVConnectionManager: No TV connected - cannot send command \(command)")
            return
        }
        
        print("✅ TVConnectionManager: Forwarding command \(command) to TVController")
        tvController.sendCommand(command)
    }
    
    func sendTextToTV(_ text: String) {
        print("⌨️ TVConnectionManager: Received text '\(text)'")
        print("📊 TVConnectionManager: Check connection status - isConnected: \(isConnectedToTV)")
        
        guard isConnectedToTV else {
            print("❌ TVConnectionManager: No TV connected - cannot send text")
            return
        }
        
        print("✅ TVConnectionManager: Forwarding text '\(text)' to TVController")
        tvController.sendText(text)
    }
}
