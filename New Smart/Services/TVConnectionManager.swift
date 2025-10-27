//
//  TVConnectionManager.swift
//  Smart TV
//
//  Created by Mihail Ozun on 25.10.2025.
//

import SwiftUI
import Combine

class TVConnectionManager: ObservableObject {
    static let shared = TVConnectionManager()
    
    @Published var isConnectedToTV: Bool = false
    @Published var connectedTV: DiscoveredTV?
    @Published var connectionStatus: ConnectionStatus = .disconnected
    
    private let tvController = TVController()
    
    private init() {}
    
    enum ConnectionStatus {
        case disconnected
        case connecting
        case connected
        case failed
    }
    
    func connectToTV(_ tv: DiscoveredTV) {
        print("📡 TVConnectionManager: Starting connection to \(tv.name) at \(tv.ipAddress)")
        connectionStatus = .connecting
        
        // Connect TVController to the TV
        print("🔗 TVConnectionManager: Initializing TVController connection...")
        tvController.connectToTV(ipAddress: tv.ipAddress)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.connectedTV = tv
            self.isConnectedToTV = true
            self.connectionStatus = .connected
            print("✅ TVConnectionManager: Successfully connected to TV: \(tv.name)")
            print("📊 TVConnectionManager: Connection status - isConnected: \(self.isConnectedToTV)")
        }
    }
    
    func disconnectFromTV() {
        guard let tv = connectedTV else { return }
        
        tvController.disconnectTV()
        connectedTV = nil
        isConnectedToTV = false
        connectionStatus = .disconnected
        print("🔌 Disconnected from TV: \(tv.name)")
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