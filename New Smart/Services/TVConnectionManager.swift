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

    private let tvController = TVController()
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

        // Store the TV we're trying to connect to
        connectedTV = tv

        // Connect TVController to the TV
        print("🔗 TVConnectionManager: Initializing WebSocket connection...")
        tvController.connectToTV(ipAddress: tv.ipAddress)
        
        samsungTVService = NetworkScanner.shared.getSamsungTVService(for: tv)
//        connectionStatus = .connected
//        isConnectedToTV = true

        // Set a timeout for the connection attempt
//        connectionTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { [weak self] _ in
//            self?.handleConnectionTimeout()
//        }

        // Check connection status periodically
//        checkConnectionStatus()
    }

    private func checkConnectionStatus() {
        // Check if WebSocket connection is established
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if self.tvController.isWebSocketConnected {
                self.handleSuccessfulConnection()
            } else {
                // Retry logic - try one more time
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    if self.tvController.isWebSocketConnected {
                        self.handleSuccessfulConnection()
                    } else {
                        self.handleConnectionFailure("Failed to establish WebSocket connection")
                    }
                }
            }
        }
    }

    private func handleSuccessfulConnection() {
        guard let tv = connectedTV else { return }

        connectionTimer?.invalidate()
        connectionTimer = nil

        isConnectedToTV = true
        connectionStatus = .connected
        connectionError = nil

        print("✅ TVConnectionManager: Successfully connected to TV: \(tv.name)")
        print("📊 TVConnectionManager: Connection status - isConnected: \(isConnectedToTV)")
    }

    private func handleConnectionTimeout() {
        print("⏰ TVConnectionManager: Connection timeout")
        handleConnectionFailure("Connection timeout - make sure the TV is on and connected to the same network")
    }

    private func handleConnectionFailure(_ error: String) {
        connectionTimer?.invalidate()
        connectionTimer = nil

        isConnectedToTV = false
        connectionStatus = .failed
        connectionError = error

        print("❌ TVConnectionManager: Connection failed - \(error)")

        // Clean up the connection attempt
        tvController.disconnectTV()
    }

    @MainActor
    func connectSamsungTVService(_ service: Service, discoveredTV: DiscoveredTV) {
        print("📺 TVConnectionManager: Connecting Samsung TV service for \(discoveredTV.name)")
        samsungTVService = service

        // For Samsung TVs discovered via SmartView, we still use WebSocket for remote control
        // The SmartView service is used for app launching and other advanced features
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
            // This would typically show the TV selection view
            print("🔍 Looking for TVs to connect...")
        }
    }
    
    // MARK: - TV Control Functions
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
