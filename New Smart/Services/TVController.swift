import Foundation
import Network
import SwiftUI

class TVController: NSObject, ObservableObject, URLSessionWebSocketDelegate {
    static let shared = TVController()
    
    private var currentIP: String?
    private var webSocketTask: URLSessionWebSocketTask?
    private var isConnected = false
    private let appName = "SamsungTvRemote"
    private var pingTimer: Timer?

    @AppStorage("tvToken") private var savedToken: String = "13545017"

    var connectionStatusChanged: ((Bool) -> Void)?

    private lazy var customURLSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 30.0
        config.waitsForConnectivity = false
        config.allowsCellularAccess = true
        config.networkServiceType = .default

        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    private override init() {}

    var isWebSocketConnected: Bool {
        return isConnected
    }

    private func extractIPFromURL(_ urlString: String) -> String {
        var cleanString = urlString.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleanString.hasPrefix("http://") {
            cleanString = String(cleanString.dropFirst(7))
        } else if cleanString.hasPrefix("https://") {
            cleanString = String(cleanString.dropFirst(8))
        }

        let components = cleanString.components(separatedBy: ":")
        if let ipPart = components.first {
            let ipComponents = ipPart.components(separatedBy: "/")
            if let ip = ipComponents.first {
                return ip
            }
        }

        return cleanString
    }
    
    func wakeOnLan(tv: DiscoveredTV) {
        guard let macAddress: String = tv.macAddress else { return }
        let macBytes = macAddress.split(separator: ":").compactMap { UInt8($0, radix: 16) }
        guard macBytes.count == 6 else { return }
        
        var packet = Data(repeating: 0xFF, count: 6)
        for _ in 0..<16 { packet.append(contentsOf: macBytes) }
        
        let connection = NWConnection(host: "255.255.255.255", port: 9, using: .udp)
        connection.stateUpdateHandler = { state in
            if case .ready = state {
                connection.send(content: packet, completion: .contentProcessed({ error in
                    if let error = error {
                        print("WOL send error: \(error)")
                    } else {
                        print("Wake-on-LAN packet sent")
                    }
                    connection.cancel()
                }))
            }
        }
        connection.start(queue: .global())
    }

    func connectToTV(ipAddress: String) {
        print("🔗 TVController: Ready to connect to Samsung TV at \(ipAddress)")
        currentIP = ipAddress

        connectWebSocket()
    }

    private func connectWebSocket() {
        guard let ipString = currentIP else {
            print("❌ TVController: No IP address for WebSocket connection")
            return
        }

        let cleanIP = extractIPFromURL(ipString)

        let encodedAppName = Data(appName.utf8).base64EncodedString()

        let wsURLString: String
        if !savedToken.isEmpty {
            wsURLString = "wss://\(cleanIP):8002/api/v2/channels/samsung.remote.control?name=\(encodedAppName)&token=\(savedToken)"
            print("🔑 TVController: Using saved token in connection URL")
        } else {
            wsURLString = "wss://\(cleanIP):8002/api/v2/channels/samsung.remote.control?name=\(encodedAppName)"
            print("🔑 TVController: Connecting without token (initial connection)")
        }

        print("📡 WebSocket URL: \(wsURLString)")

        guard let wsURL = URL(string: wsURLString) else {
            print("❌ TVController: Invalid WebSocket URL: \(wsURLString)")
            return
        }

        print("✅ TVController: Connecting to Samsung TV WebSocket")

        webSocketTask = customURLSession.webSocketTask(with: wsURL)
        webSocketTask?.resume()

        print("✅ TVController: WebSocket connection initiated")
    }

    private func handleWebSocketDisconnection() {
        print("🔌 TVController: Handling WebSocket disconnection")
        isConnected = false

        // Stop ping timer
        DispatchQueue.main.async {
            self.pingTimer?.invalidate()
            self.pingTimer = nil
        }

        print("📢 TVController: Notifying about disconnection (was previously connected)")
        DispatchQueue.main.async {
            self.connectionStatusChanged?(false)
        }
    }

    private func receiveMessage() {
        guard webSocketTask != nil else {
            print("📭 TVController: Stopped listening - WebSocket task is nil")
            return
        }

        webSocketTask?.receive { [weak self] result in
            switch result {
            case .failure(let error):
                print("❌ TVController: WebSocket receive error: \(error)")

                self?.handleWebSocketDisconnection()
            case .success(let message):
                switch message {
                case .string(let text):
                    print("📨 TVController: Received message: \(text)")
                    self?.handleReceivedMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        print("📨 TVController: Received data message: \(text)")
                        self?.handleReceivedMessage(text)
                    }
                @unknown default:
                    print("📨 TVController: Received unknown message type")
                }

                self?.receiveMessage()
            }
        }
    }

    private func handleReceivedMessage(_ message: String) {
        if let messageData = message.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: messageData) as? [String: Any] {
            if let event = json["event"] as? String {
                switch event {
                case "ms.channel.connect":
                    if let data = json["data"] as? [String: Any], let clients = data["clients"] as? [[String: Any]], let client = clients.first {
                        if let attributes = client["attributes"] as? [String: String] {
                            self.savedToken = attributes["token"] ?? ""
                            self.isConnected = true
                            print("Saved token: \(self.savedToken) and isConnected: \(self.isConnected)")

                            DispatchQueue.main.async {
                                self.connectionStatusChanged?(true)
                            }
                        }
                    }
                default:
                    print("Caught an unknown event: \(event)")
                }
            }
        }
    }

    private func handleConnectionTimeout() {
        print("🔄 TVController: Handling connection timeout")
        isConnected = false

        // Stop ping timer
        DispatchQueue.main.async {
            self.pingTimer?.invalidate()
            self.pingTimer = nil
        }

        // Cancel current WebSocket connection
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
    }

    func ping() {
        webSocketTask?.sendPing { error in
            if let error = error {
                print("❌ TVController: Error sending ping: \(error)")
            } else {
                print("🏓 TVController: Ping sent successfully")
            }
        }
    }

    private func sendMessage(_ message: [String: Any]) {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: message),
                  let jsonString = String(data: jsonData, encoding: .utf8) else {
                print("❌ TVController: Failed to serialize message")
                return
            }
        
        print("Sent message to the server:")
        print(message)

        webSocketTask?.send(.string(jsonString)) { error in
            if let error = error {
                print("❌ TVController: Failed to send message: \(error)")
            }
        }
    }

    func sendCommand(_ command: TVCommand) {
        print("🎮 TVController: Command request - \(command)")

        guard isConnected else {
            print("❌ TVController: Not connected to TV - cannot send \(command)")
            return
        }

        let keyCode = mapCommandToKeyCode(command)
        sendRemoteKey(keyCode)
    }

    private func mapCommandToKeyCode(_ command: TVCommand) -> String {
        switch command {
        case .powerToggle:
            return "KEY_POWER"
        case .home:
            return "KEY_HOME"
        case .back:
            return "KEY_RETURN"
        case .up:
            return "KEY_UP"
        case .down:
            return "KEY_DOWN"
        case .left:
            return "KEY_LEFT"
        case .right:
            return "KEY_RIGHT"
        case .select:
            return "KEY_ENTER"
        case .volumeUp:
            return "KEY_VOLUP"
        case .volumeDown:
            return "KEY_VOLDOWN"
        case .mute:
            return "KEY_MUTE"
        case .playPause:
            return "KEY_PLAYPAUSE"
        case .next:
            return "KEY_FF"
        case .previous:
            return "KEY_REWIND"
        }
    }

    private func sendRemoteKey(_ key: String) {
        let command: [String: Any] = [
            "method": "ms.remote.control",
            "params": [
                "Cmd": "Click",
                "DataOfCmd": key,
                "Option": "false",
                "TypeOfRemote": "SendRemoteKey"
            ]
        ]

        print("📤 TVController: Sending key command: \(key)")
        sendMessage(command)
    }

    func sendText(_ text: String) {
        print("⌨️ TVController: Text request - '\(text)'")

        guard isConnected else {
            print("❌ TVController: Not connected to TV - cannot send text")
            return
        }

        let textCommand: [String: Any] = [
            "method": "ms.remote.control",
            "params": [
                "Cmd": text,
                "DataOfCmd": "InputString",
                "TypeOfRemote": "SendInputString"
            ]
        ]

        print("📤 TVController: Sending text: \(text)")
        sendMessage(textCommand)
    }

    func disconnectTV() {
        print("🔌 TVController: Disconnecting from TV")

        if isConnected {
            // Send disconnect message
            let disconnectMessage: [String: Any] = [
                "method": "ms.channel.disconnect"
            ]
            sendMessage(disconnectMessage)
        }

        // Stop ping timer
        DispatchQueue.main.async {
            self.pingTimer?.invalidate()
            self.pingTimer = nil
        }

        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        currentIP = nil
        isConnected = false
        print("🔌 TVController: Disconnected")

        // Notify connection manager that we're disconnected
        DispatchQueue.main.async {
            self.connectionStatusChanged?(false)
        }
    }

    // MARK: - URLSessionWebSocketDelegate

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("🟢 TVController: WebSocket connection opened successfully")
        ping()

        // Start periodic ping timer (every 30 seconds)
        DispatchQueue.main.async {
            self.pingTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
                self.ping()
            }
        }

        receiveMessage()
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        let reasonString = reason.flatMap { String(data: $0, encoding: .utf8) } ?? "Unknown"
        print("🔴 TVController: WebSocket connection closed with code: \(closeCode.rawValue), reason: \(reasonString)")

        // Stop ping timer
        DispatchQueue.main.async {
            self.pingTimer?.invalidate()
            self.pingTimer = nil
        }

        handleWebSocketDisconnection()
    }

    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if isLocalIPAddress(challenge.protectionSpace.host) {
            if let serverTrust = challenge.protectionSpace.serverTrust {
                let credential = URLCredential(trust: serverTrust)
                print("🔒 TVController: Bypassing SSL verification for Samsung TV at \(challenge.protectionSpace.host) (equivalent to sslopt CERT_NONE)")
                completionHandler(.useCredential, credential)
            } else {
                completionHandler(.useCredential, nil)
            }
        } else {
            print("🔒 TVController: Using standard SSL verification for external connection")
            completionHandler(.performDefaultHandling, nil)
        }
    }

    private func isLocalIPAddress(_ host: String) -> Bool {
        return host.hasPrefix("192.168.") ||
               host.hasPrefix("10.") ||
               host.hasPrefix("172.16.") ||
               host.hasPrefix("172.17.") ||
               host.hasPrefix("172.18.") ||
               host.hasPrefix("172.19.") ||
               host.hasPrefix("172.20.") ||
               host.hasPrefix("172.21.") ||
               host.hasPrefix("172.22.") ||
               host.hasPrefix("172.23.") ||
               host.hasPrefix("172.24.") ||
               host.hasPrefix("172.25.") ||
               host.hasPrefix("172.26.") ||
               host.hasPrefix("172.27.") ||
               host.hasPrefix("172.28.") ||
               host.hasPrefix("172.29.") ||
               host.hasPrefix("172.30.") ||
               host.hasPrefix("172.31.") ||
               host == "localhost" ||
               host == "127.0.0.1"
    }
}

enum TVCommand {
    case powerToggle
    case home
    case back
    case up
    case down
    case left
    case right
    case select
    case volumeUp
    case volumeDown
    case mute
    case playPause
    case next
    case previous
}
