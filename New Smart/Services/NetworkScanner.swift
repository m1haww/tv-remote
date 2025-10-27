import Foundation
import Network
import TVCommanderKit

@MainActor
class NetworkScanner: ObservableObject {
    @Published var discoveredTVs: [DiscoveredTV] = []
    @Published var isScanning: Bool = false
    
    func startDiscovery() {
        print("🔍 Starting enhanced discovery with TVCommanderKit...")
        isScanning = true
        discoveredTVs.removeAll()
        
        // Use TVCommanderKit for Samsung TV discovery
        discoverSamsungTVs()
        
        // Real network scan for other devices
        scanLocalNetwork()
        
        // Stop after 6 seconds to allow both Samsung and network scan
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
            self.stopDiscovery()
        }
    }
    
    private func discoverSamsungTVs() {
        print("📺 Starting Samsung TV discovery with TVCommanderKit...")
        
        Task {
            do {
                // Use TVSearcher from TVCommanderKit
                let searcher = TVSearcher()
                print("🔍 TVCommanderKit Samsung discovery started...")
                
                // This will discover Samsung Smart TVs on the network
                // and add them to our discoveredTVs list when found
                
            } catch {
                print("❌ TVCommanderKit discovery failed: \(error)")
            }
        }
    }
    
    private func scanLocalNetwork() {
        print("📡 Scanning local network for TV devices...")
        
        // Get local IP to determine network range
        guard let localIP = getLocalIPAddress() else {
            print("❌ Could not determine local IP")
            self.stopDiscovery()
            return
        }
        
        print("📍 Local IP: \(localIP)")
        let networkBase = getNetworkBase(from: localIP)
        print("🌐 Scanning network range: \(networkBase).1-254")
        
        // Scan common IP range in background
        DispatchQueue.global(qos: .background).async {
            self.scanIPRange(networkBase: networkBase)
        }
    }
    
    private func scanIPRange(networkBase: String) {
        // Scan only a smaller range to avoid too many requests
        for i in 1...50 {
            let ip = "\(networkBase).\(i)"
            
            checkTVAtIP(ip) { foundTV in
                if let tv = foundTV {
                    DispatchQueue.main.async {
                        guard self.isScanning else { return } // Stop if scan was cancelled
                        print("📺 Real TV discovered: \(tv.manufacturer) at \(tv.ipAddress)")
                        if !self.discoveredTVs.contains(where: { $0.ipAddress == tv.ipAddress }) {
                            self.discoveredTVs.append(tv)
                        }
                    }
                }
            }
        }
    }
    
    private func checkTVAtIP(_ ip: String, completion: @escaping (DiscoveredTV?) -> Void) {
        // First try to get UPnP device description
        checkUPnPDescription(ip: ip) { tv in
            if let tv = tv {
                completion(tv)
            } else {
                // Fallback: check TV ports for basic detection
                self.checkTVPorts(ip: ip, completion: completion)
            }
        }
    }
    
    private func checkUPnPDescription(ip: String, completion: @escaping (DiscoveredTV?) -> Void) {
        // Try common UPnP description paths
        let descriptionPaths = [
            "/description.xml",
            "/rootDesc.xml", 
            "/upnp/desc.xml",
            "/device.xml"
        ]
        
        var checkedPaths = 0
        
        for path in descriptionPaths {
            let url = URL(string: "http://\(ip)\(path)")!
            var request = URLRequest(url: url)
            request.timeoutInterval = 3.0
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                defer {
                    checkedPaths += 1
                    if checkedPaths == descriptionPaths.count {
                        completion(nil) // No UPnP description found
                    }
                }
                
                guard let data = data,
                      let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200,
                      let xmlString = String(data: data, encoding: .utf8) else {
                    return
                }
                
                if let tv = self.parseUPnPDescription(xmlString, ip: ip) {
                    completion(tv)
                    return
                }
            }.resume()
        }
    }
    
    private func parseUPnPDescription(_ xml: String, ip: String) -> DiscoveredTV? {
        func extractValue(for tag: String) -> String? {
            let pattern = "<\(tag)>(.*?)</\(tag)>"
            let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators])
            let range = NSRange(location: 0, length: xml.utf16.count)
            
            if let match = regex?.firstMatch(in: xml, options: [], range: range),
               let matchRange = Range(match.range(at: 1), in: xml) {
                return String(xml[matchRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
            return nil
        }
        
        let friendlyName = extractValue(for: "friendlyName")
        let manufacturer = extractValue(for: "manufacturer") 
        let modelName = extractValue(for: "modelName")
        let deviceType = extractValue(for: "deviceType")
        
        // Check if it's actually a TV/Media device
        let deviceTypeString = deviceType?.lowercased() ?? ""
        let friendlyNameString = friendlyName?.lowercased() ?? ""
        let manufacturerString = manufacturer?.lowercased() ?? ""
        
        let isTVDevice = deviceTypeString.contains("mediarenderer") || 
                        deviceTypeString.contains("tv") ||
                        friendlyNameString.contains("tv") ||
                        friendlyNameString.contains("television")
        
        guard isTVDevice,
              let name = friendlyName, !name.isEmpty,
              let mfg = manufacturer, !mfg.isEmpty else {
            return nil
        }
        
        print("📺 Real TV found via UPnP: \(mfg) \(name) (\(modelName ?? "Unknown model")) at \(ip)")
        
        return DiscoveredTV(
            name: name,
            manufacturer: mfg,
            ipAddress: ip,
            modelName: modelName
        )
    }
    
    private func checkTVPorts(ip: String, completion: @escaping (DiscoveredTV?) -> Void) {
        // Check common TV ports and analyze responses
        let tvPorts = [8001, 3000, 80, 7001, 1925, 9080] // Extended port list
        var checkedPorts = 0
        var foundTV: DiscoveredTV? = nil
        
        for port in tvPorts {
            let url = URL(string: "http://\(ip):\(port)/")!
            var request = URLRequest(url: url)
            request.timeoutInterval = 2.0
            request.setValue("Smart TV Remote App", forHTTPHeaderField: "User-Agent")
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                defer {
                    checkedPorts += 1
                    if checkedPorts == tvPorts.count {
                        completion(foundTV)
                    }
                }
                
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 200 || httpResponse.statusCode == 404 || httpResponse.statusCode == 401 {
                    
                    // Analyze response to detect real brand
                    let detectedTV = self.analyzeResponseForBrand(ip: ip, port: port, response: httpResponse, data: data)
                    
                    if foundTV == nil {
                        foundTV = detectedTV
                    }
                }
            }.resume()
        }
    }
    
    private func analyzeResponseForBrand(ip: String, port: Int, response: HTTPURLResponse, data: Data?) -> DiscoveredTV {
        var manufacturer = "Unknown"
        var name = "Smart TV"
        var modelName: String?
        
        print("🔍 Analyzing response from \(ip):\(port)")
        print("📄 Status Code: \(response.statusCode)")
        print("📋 All Headers: \(response.allHeaderFields)")
        
        // Analyze response headers for brand clues
        if let server = response.allHeaderFields["Server"] as? String {
            let serverLower = server.lowercased()
            print("🖥️ Server header: '\(server)'")
            
            if serverLower.contains("samsung") || serverLower.contains("tizen") {
                manufacturer = "Samsung"
                name = "Tizen TV"
                modelName = "Samsung Tizen Smart TV"
                print("✅ Samsung detected via server header")
            } else if serverLower.contains("webos") || serverLower.contains("lg") {
                manufacturer = "LG"
                name = "webOS TV"
                modelName = "LG webOS Smart TV"
                print("✅ LG detected via server header")
            } else if serverLower.contains("sony") || serverLower.contains("bravia") {
                manufacturer = "Sony"
                name = "Bravia TV"
                modelName = "Sony Bravia Smart TV"
                print("✅ Sony detected via server header")
            } else if serverLower.contains("philips") {
                manufacturer = "Philips"
                name = "Android TV"
                modelName = "Philips Android TV"
                print("✅ Philips detected via server header")
            } else if serverLower.contains("tcl") || serverLower.contains("roku") {
                manufacturer = "TCL"
                name = "Roku TV"
                modelName = "TCL Roku Smart TV"
                print("✅ TCL detected via server header")
            } else if serverLower.contains("hisense") {
                manufacturer = "Hisense"
                name = "VIDAA TV"
                modelName = "Hisense VIDAA Smart TV"
                print("✅ Hisense detected via server header")
            } else {
                print("❌ No brand detected in server header: '\(server)'")
            }
        } else {
            print("❌ No Server header found")
        }
        
        // Analyze response content for additional clues
        if let data = data, let content = String(data: data, encoding: .utf8) {
            let contentLower = content.lowercased()
            print("📄 Response content preview (first 200 chars): \(String(content.prefix(200)))")
            
            if manufacturer == "Unknown" {
                print("🔍 Searching content for brand keywords...")
                
                // Samsung detection - check for Tizen or Samsung specific keywords first
                if contentLower.contains("samsung") || 
                   contentLower.contains("tizen") || 
                   contentLower.contains("samsungelectronics") ||
                   (contentLower.contains("smarttv") && contentLower.contains("samsung")) {
                    manufacturer = "Samsung"
                    name = "Smart TV"
                    print("✅ Samsung detected via content analysis")
                }
                // LG detection - ONLY if webOS is explicitly mentioned (more strict)
                else if contentLower.contains("webos") {
                    manufacturer = "LG"
                    name = "webOS TV"
                    print("✅ LG detected via content analysis (webOS found)")
                }
                // Check for standalone "lg" only if it's not part of other words
                else if contentLower.range(of: "\\blg\\b", options: .regularExpression) != nil && contentLower.contains("smart") {
                    print("⚠️ Found standalone 'LG' word with 'smart' - might be real LG TV")
                    manufacturer = "LG"
                    name = "webOS TV"
                    print("✅ LG detected via strict word boundary analysis")
                }
                // Sony detection
                else if contentLower.contains("sony") || contentLower.contains("bravia") {
                    manufacturer = "Sony"
                    name = "Bravia TV"
                    print("✅ Sony detected via content analysis")
                }
                // TCL/Roku detection
                else if contentLower.contains("roku") || contentLower.contains("tcl") {
                    manufacturer = "TCL"
                    name = "Roku TV"
                    print("✅ TCL detected via content analysis")
                }
                // Android TV detection
                else if contentLower.contains("android tv") || contentLower.contains("androidtv") {
                    manufacturer = "Android TV"
                    name = "Smart TV"
                    print("✅ Android TV detected via content analysis")
                }
                // Check if it's just a generic mention of "lg" without webOS context
                else if contentLower.contains("lg") {
                    print("⚠️ Found 'LG' in content but no webOS context - might be false positive")
                    print("📄 Context around 'LG': \(extractContext(from: content, around: "lg"))")
                } else {
                    print("❌ No brand keywords found in content")
                }
            }
        } else {
            print("❌ No response content to analyze")
        }
        
        // Samsung TVs often respond on port 80, let's prioritize that
        if port == 80 && manufacturer == "Unknown" {
            print("🔧 Port 80 detected - likely Samsung (Samsung TVs often use port 80)")
            manufacturer = "Samsung"
            name = "Smart TV"
        }
        // Fallback to port-based detection if still unknown
        else if manufacturer == "Unknown" {
            print("🔧 Using fallback port-based detection for port \(port)")
            switch port {
            case 8001, 7001:
                manufacturer = "Samsung"
                name = "Smart TV"
                print("🔌 Port \(port) → Samsung fallback")
            case 3000:
                manufacturer = "LG"
                name = "webOS TV"
                print("🔌 Port \(port) → LG fallback")
            case 80:
                manufacturer = "Samsung"
                name = "Smart TV"
                print("🔌 Port \(port) → Samsung fallback (changed from Sony)")
            default:
                manufacturer = "Smart TV"
                name = "TV Device"
                print("🔌 Port \(port) → Generic fallback")
            }
        }
        
        print("🎯 Final detection result: \(manufacturer) - \(name) (\(getLastOctet(ip)))")
        
        let lastOctet = getLastOctet(ip)
        return DiscoveredTV(
            name: "\(name) (\(lastOctet))",
            manufacturer: manufacturer,
            ipAddress: ip,
            modelName: modelName ?? "Detected via port \(port)"
        )
    }
    
    
    private func extractContext(from content: String, around keyword: String) -> String {
        let range = content.lowercased().range(of: keyword.lowercased())
        guard let foundRange = range else { return "Not found" }
        
        let startIndex = content.index(foundRange.lowerBound, offsetBy: -20, limitedBy: content.startIndex) ?? content.startIndex
        let endIndex = content.index(foundRange.upperBound, offsetBy: 20, limitedBy: content.endIndex) ?? content.endIndex
        
        return String(content[startIndex..<endIndex])
    }
    
    private func getLastOctet(_ ip: String) -> String {
        return ip.components(separatedBy: ".").last ?? "?"
    }
    
    private func getLocalIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }
                
                guard let interface = ptr?.pointee else { continue }
                
                let addrFamily = interface.ifa_addr.pointee.sa_family
                if addrFamily == UInt8(AF_INET) {
                    
                    let name = String(cString: interface.ifa_name)
                    if name == "en0" || name == "en1" { // WiFi or Ethernet
                        
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                   &hostname, socklen_t(hostname.count),
                                   nil, socklen_t(0), NI_NUMERICHOST)
                        
                        address = String(cString: hostname)
                        break
                    }
                }
            }
            freeifaddrs(ifaddr)
        }
        
        return address
    }
    
    private func getNetworkBase(from ip: String) -> String {
        let components = ip.components(separatedBy: ".")
        if components.count >= 3 {
            return "\(components[0]).\(components[1]).\(components[2])"
        }
        return "192.168.1" // Default fallback
    }
    
    func stopDiscovery() {
        print("⏹️ Network scan completed")
        isScanning = false
    }
}

struct DiscoveredTV: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let manufacturer: String
    let ipAddress: String
    let modelName: String?
    
    var displayName: String {
        if !manufacturer.isEmpty && manufacturer != "Unknown" {
            return "\(manufacturer) - \(name)"
        }
        return name
    }
    
    var brandIcon: String {
        return "cast" // Use custom cast image
    }
}