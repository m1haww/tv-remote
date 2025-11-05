import Foundation
import Network

class TVController: ObservableObject {
    private var currentIP: String?
    private var webSocketTask: URLSessionWebSocketTask?
    private var isConnected = false
    private let appName = "Smart TV Remote"

    // Public property to check WebSocket connection status
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

        // Split by : to separate IP from port/path
        let components = cleanString.components(separatedBy: ":")
        if let ipPart = components.first {
            // Further clean by removing any path components
            let ipComponents = ipPart.components(separatedBy: "/")
            if let ip = ipComponents.first {
                return ip
            }
        }

        // Fallback: return original string if parsing fails
        return cleanString
    }
    
    private func wakeOnLan(tv: DiscoveredTV) {
        guard let macAddress: String = tv.macAddress else { return }
        let macBytes = macAddress.split(separator: ":").compactMap { UInt8($0, radix: 16) }
        guard macBytes.count == 6 else { return }
        
        // Create magic packet: 6 x 0xFF + 16 x MAC
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

        // Connect to Samsung TV WebSocket for remote control
        connectWebSocket()
    }

    private func connectWebSocket() {
        guard let ipString = currentIP else {
            print("❌ TVController: No IP address for WebSocket connection")
            return
        }

        let cleanIP = extractIPFromURL(ipString)

        let encodedAppName = Data(appName.utf8).base64EncodedString()
        let wsURLString = "ws://\(cleanIP):8001/api/v2/channels/samsung.remote.control?name=\(encodedAppName)"

        print("📡 WebSocket URL: \(wsURLString)")

        guard let wsURL = URL(string: wsURLString) else {
            print("❌ TVController: Invalid WebSocket URL: \(wsURLString)")
            return
        }

        print("✅ TVController: Connecting to Samsung TV WebSocket")

        webSocketTask = URLSession.shared.webSocketTask(with: wsURL)
        webSocketTask?.resume()

        receiveMessage()

//        sendHandshake()

        print("✅ TVController: WebSocket connection initiated")
    }

    private func sendHandshake() {
        let handshake: [String: Any] = [
            "method": "ms.channel.connect",
            "params": [
                "clientAttributes": [
                    "name": Data(appName.utf8).base64EncodedString(),
                    "version": "1.0.0"
                ],
                "connectMode": [
                    "connectType": "ws_pairing"
                ]
            ]
        ]

        sendMessage(handshake)
    }

    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .failure(let error):
                print("❌ TVController: WebSocket receive error: \(error)")
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

                // Continue listening for more messages
                self?.receiveMessage()
            }
        }
    }

    private func handleReceivedMessage(_ message: String) {
        // Parse the JSON response to check connection status
        if let data = message.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {

            if let event = json["event"] as? String {
                if event == "ms.channel.connect" {
                    if let result = json["result"] as? [String: Any],
                       let clientKey = result["clientKey"] as? String {
                        print("✅ TVController: Connected to Samsung TV! Client key: \(clientKey)")
                        isConnected = true
                    }
                } else if event == "ms.channel.clientConnect" {
                    print("✅ TVController: Client connected to Samsung TV")
                    isConnected = true
                }
            }
        }
    }

    private func sendMessage(_ message: [String: Any]) {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: message) else {
            print("❌ TVController: Failed to serialize message")
            return
        }

        webSocketTask?.send(.data(jsonData)) { error in
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
        let message: [String: Any] = [
            "method": "ms.remote.control",
            "params": [
                "Cmd": "Click",
                "DataOfCmd": key,
                "Option": "false",
                "TypeOfRemote": "SendRemoteKey"
            ]
        ]

        print("📤 TVController: Sending key command: \(key)")
        sendMessage(message)
    }

    func sendText(_ text: String) {
        print("⌨️ TVController: Text request - '\(text)'")

        guard isConnected else {
            print("❌ TVController: Not connected to TV - cannot send text")
            return
        }

        let message: [String: Any] = [
            "method": "ms.remote.control",
            "params": [
                "Cmd": "InputString",
                "DataOfCmd": text,
                "TypeOfRemote": "SendInputString"
            ]
        ]

        print("📤 TVController: Sending text: \(text)")
        sendMessage(message)
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

        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        currentIP = nil
        isConnected = false
        print("🔌 TVController: Disconnected")
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
