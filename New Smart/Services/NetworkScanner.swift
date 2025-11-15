import Foundation
import Network
import SmartView
import Darwin

@MainActor
class NetworkScanner: ObservableObject, ServiceSearchDelegate {
    @Published var discoveredTVs: [DiscoveredTV] = []
    @Published var isScanning: Bool = false
    
    static var shared: NetworkScanner = NetworkScanner()
    
    private init() {}
    
    private var serviceSearch: ServiceSearch?

    private var samsungTVServices: [String: Service] = [:]
    
    func startDiscovery() {
        isScanning = true
        discoveredTVs.removeAll()

        discoverSamsungTVs()
    }
    
    private func discoverSamsungTVs() {
        print("📺 Starting Samsung TV discovery with SmartView SDK...")

        serviceSearch = Service.search()
        serviceSearch?.delegate = self

        serviceSearch?.start()
    }
    
    func stopDiscovery() {
        print("⏹️ Network scan completed")
        isScanning = false
        serviceSearch?.stop()
    }

    func getSamsungTVService(for discoveredTV: DiscoveredTV) -> Service? {
        return samsungTVServices[discoveredTV.id]
    }

    func clearSamsungTVServices() {
        samsungTVServices.removeAll()
        print("🧹 Cleared all Samsung TV services")
    }

    nonisolated func onServiceFound(_ service: Service) {
        Task { @MainActor in
            print("📺 Samsung TV discovered via SmartView: \(service.name)")

            guard !self.discoveredTVs.contains(where: { $0.name.contains(service.name) }) else {
                print("ℹ️ TV already in list: \(service.name)")
                return
            }
            
            service.getDeviceInfo(5, completionHandler: {
                (deviceInfo, error) -> Void in

                guard let device = deviceInfo?["device"] as? [String: Any] else {
                    print("❌ Failed to get device info for \(service.name)")
                    return
                }

                let wifiMac = device["wifiMac"] as? String
                let discoveredTV = DiscoveredTV(
                    id: service.id,
                    name: service.name,
                    manufacturer: "Samsung",
                    ipAddress: service.uri,
                    modelName: "Samsung",
                    macAddress: wifiMac
                )
                
                self.samsungTVServices[service.id] = service
                
                DispatchQueue.main.async {
                    self.discoveredTVs.append(discoveredTV)
                }
                print("✅ Added Samsung TV: \(service.name)")
            })
        }
    }

    nonisolated func onServiceLost(_ service: Service) {
        Task { @MainActor in
            print("📺 Samsung TV lost: \(service.name)")

            self.discoveredTVs.removeAll(where: { $0.name.contains(service.name) })
            self.samsungTVServices.removeValue(forKey: service.uri)
            print("📺 Removed Samsung TV service for IP: \(service.uri)")
        }
    }

    nonisolated func onStart() {
        Task { @MainActor in
            print("✅ SmartView service search started")
            print("🔧 DEBUG: onStart() delegate method called - discovery is active")
        }
    }

    nonisolated func onStop() {
        Task { @MainActor in
            print("⏹️ SmartView service search stopped")
            print("🔧 DEBUG: onStop() delegate method called")
        }
    }
}
