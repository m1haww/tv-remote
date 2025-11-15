import Foundation
import SwiftUI
import SmartView

@MainActor
class SamsungTVAppLauncher: ObservableObject {
    private var connectedService: Service?
    private var connectedApplications: [String: Application] = [:]

    @Published var isConnecting: Bool = false
    @Published var connectionError: String?

    static let samsungTVApps: [TVApp] = [
        TVApp(
            id: "111299001912",
            name: "YouTube",
            imageName: "youtube",
            backgroundColor: "#FF0000"
        ),
        TVApp(
            id: "3201907018807",
            name: "Netflix",
            imageName: "netflix",
            backgroundColor: "#E50914"
        ),
        TVApp(
            id: "3201901017640",        
            name: "Disney+",
            imageName: "disneyplus",
            backgroundColor: "#113CCF"
        ),
        TVApp(
            id: "3201512006785",
            name: "Amazon Prime Video",
            imageName: "primevideo",
            backgroundColor: "#00A8E1"
        ),
        TVApp(
            id: "3201601007625",
            name: "Hulu",
            imageName: "hulu",
            backgroundColor: "#1CE783"
        ),
        TVApp(
            id: "3201601007230",
            name: "HBO Max",
            imageName: "hbomax",
            backgroundColor: "#8A2BE2"
        ),
        TVApp(
            id: "3201506003488",
            name: "Twitch",
            imageName: "twitch",
            backgroundColor: "#9146FF"
        ),
        TVApp(
            id: "111012010001",
            name: "Samsung Internet",
            imageName: "browser_samsung",
            backgroundColor: "#1428A0"
        ),
        TVApp(
            id: "org.tizen.browser",
            name: "Web Browser",
            imageName: "chrome",
            backgroundColor: "#4285F4"
        )
    ]

    func connectToService(_ service: Service) {
        self.connectedService = service
        print("📱 SamsungTVAppLauncher: Connected to Samsung TV service")
    }

    func launchApp(_ app: TVApp) {
        print("🚀 SamsungTVAppLauncher: Attempting to launch \(app.name) (ID: \(app.id))")

        guard let service = connectedService else {
            print("❌ SamsungTVAppLauncher: No Samsung TV service connected")
            connectionError = "Not connected to Samsung TV"
            return
        }

        isConnecting = true
        connectionError = nil

        let channelURI = "com.samsung.multiscreen.tvapp.\(app.name.lowercased())"

        guard let msApplication = service.createApplication(app.id as AnyObject, channelURI: channelURI, args: nil) else {
            print("❌ SamsungTVAppLauncher: Failed to create application for \(app.name)")
            isConnecting = false
            connectionError = "Failed to create application"
            return
        }

        msApplication.connectionTimeout = 5.0

        print("🔗 SamsungTVAppLauncher: Connecting to \(app.name) application...")

        msApplication.connect([:] as [String : String]) { [weak self] (client, error) in
            DispatchQueue.main.async {
                guard let self = self else { return }

                if error == nil {
                    print("✅ SamsungTVAppLauncher: Successfully launched \(app.name)")
                    self.connectedApplications[app.id] = msApplication

                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        msApplication.disconnect()
                        self.connectedApplications.removeValue(forKey: app.id)
                        print("🔌 SamsungTVAppLauncher: Disconnected from \(app.name) application")
                    }
                } else {
                    print("❌ SamsungTVAppLauncher: Failed to connect to \(app.name) application: \(error?.localizedDescription ?? "Unknown error")")
                    self.connectionError = "Failed to launch \(app.name): \(error?.localizedDescription ?? "Unknown error")"
                }

                self.isConnecting = false
            }
        }
    }

    func installApp(_ app: TVApp) {
        print("📦 SamsungTVAppLauncher: Attempting to install \(app.name)")

        guard let service = connectedService else {
            print("❌ SamsungTVAppLauncher: No Samsung TV service connected")
            connectionError = "Not connected to Samsung TV"
            return
        }

        let channelURI = "com.samsung.multiscreen.tvapp.\(app.name.lowercased())"

        guard let msApplication = service.createApplication(app.id as AnyObject, channelURI: channelURI, args: nil) else {
            print("❌ SamsungTVAppLauncher: Failed to create application for installation")
            connectionError = "Failed to create application"
            return
        }

        msApplication.install { success, error in
            DispatchQueue.main.async {
                if success {
                    print("✅ SamsungTVAppLauncher: Installation page opened for \(app.name)")
                } else {
                    print("❌ SamsungTVAppLauncher: Installation failed for \(app.name): \(error?.localizedDescription ?? "Unknown error")")
                    self.connectionError = "Installation failed: \(error?.localizedDescription ?? "Unknown error")"
                }
            }
        }
    }

    func disconnectAllApps() {
        print("🔌 SamsungTVAppLauncher: Disconnecting all applications")

        for (appId, application) in connectedApplications {
            application.disconnect()
            print("🔌 SamsungTVAppLauncher: Disconnected from app \(appId)")
        }

        connectedApplications.removeAll()
        connectedService = nil
    }
}

struct TVApp: Identifiable, Equatable {
    let id: String
    let name: String
    let imageName: String
    let backgroundColor: String

    var backgroundColorSwiftUI: Color {
        return Color(hex: backgroundColor)
    }
}

