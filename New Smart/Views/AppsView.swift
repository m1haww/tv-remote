import SwiftUI
import SmartView
import Network

struct AppsView: View {
    @EnvironmentObject var tvConnectionManager: TVConnectionManager
    @StateObject private var appLauncher = SamsungTVAppLauncher()
    @StateObject private var networkScanner = NetworkScanner.shared
    @State private var showTVList = false

    private var isSamsungTV: Bool {
        guard let connectedTV = tvConnectionManager.connectedTV else { return false }
        return connectedTV.manufacturer.lowercased().contains("samsung")
    }

    var body: some View {
        ZStack {
            Color(hex: "16171D").ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                AppBar(title: "TV Remote")
                
                if tvConnectionManager.isConnectedToTV {
                    // Connected TV Banner
                    ConnectedTVCard()
                    
                    // Apps Grid
                    VStack(spacing: 16) {
                        if isSamsungTV {
                            HStack {
                                Image(systemName: "tv")
                                    .foregroundColor(.green)
                                Text("Samsung TV Apps")
                                    .foregroundColor(.white)
                                    .font(.headline)
                                Spacer()
                            }
                            .padding(.horizontal, 16)

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                                ForEach(SamsungTVAppLauncher.samsungTVApps) { app in
                                    SamsungAppView(
                                        app: app,
                                        isConnecting: appLauncher.isConnecting,
                                        onLaunch: {
                                            launchSamsungApp(app)
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 16)
                        } else {
                            // Generic apps for non-Samsung TVs
                            HStack {
                                Image(systemName: "tv")
                                    .foregroundColor(.orange)
                                Text("TV Apps (View Only)")
                                    .foregroundColor(.white)
                                    .font(.headline)
                                Spacer()
                            }
                            .padding(.horizontal, 16)

                            Text("App launching is available for Samsung TVs only")
                                .foregroundColor(.gray)
                                .font(.caption)
                                .padding(.horizontal, 16)

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                                ForEach(SamsungTVAppLauncher.samsungTVApps) { app in
                                    StreamingAppView(
                                        imageName: app.imageName,
                                        backgroundColor: app.backgroundColorSwiftUI
                                    )
                                    .opacity(0.6)
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.top, 20)
                } else {
                    // No Connection Screen
                    VStack(spacing: 30) {
                        Spacer()
                        
                        Image("no connection")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 120, height: 120)
                        
                        VStack(spacing: 10) {
                            Text("There is no connection")
                                .foregroundColor(.white)
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("Connect your phone to your TV to continue")
                                .foregroundColor(.gray)
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            showTVList = true
                        }) {
                            Text("Connect")
                                .foregroundColor(.white)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .frame(height: 60)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color(hex: "B917FF"), Color(hex: "7511EB")]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .cornerRadius(25)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
                
                Spacer()
            }
        }
        .sheet(isPresented: $showTVList) {
            TVListView(isPresented: $showTVList)
                .environmentObject(tvConnectionManager)
        }
        .alert("App Launch Error", isPresented: .constant(appLauncher.connectionError != nil)) {
            Button("OK") {
                appLauncher.connectionError = nil
            }
        } message: {
            if let error = appLauncher.connectionError {
                Text(error)
            }
        }
    }

    private func launchSamsungApp(_ app: TVApp) {
        print("🚀 AppsView: Launching Samsung TV app: \(app.name)")

        guard let connectedTV = tvConnectionManager.connectedTV else {
            print("❌ AppsView: No connected TV")
            return
        }

        if let samsungService = tvConnectionManager.samsungTVService {
            let channelID: String = "com.samsung.multiscreen.helloworld"

            guard let msApplication = samsungService.createApplication(app.id as AnyObject, channelURI: channelID, args: nil) else {
                print("Failed to create MSApplication")
                      return
            }
            msApplication.connectionTimeout = 5.0
            // Attributes is optional
            let attr: [String:String] = ["userID":"idTest","userPW":"pwTest"]

            // Connect to the tv application.
            // Note: This will also launch the tv application if not already launched
            msApplication.connect(attr) { (client, error) -> Void in
                if client != nil {
                    print("App connected")
                } else {
                    print("App cannot connect: \(error)")
                }
                }

            // Disconnect from the application
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {
                let eventID: String = "fireMissile"
                let msgData: [String : AnyObject] = ["speed" : "100" as AnyObject]
                
                msApplication.publish(event: eventID, message: msgData as AnyObject?)
            })
            
//            msApplication.disconnect()
            
        

            // Install the application on the TV.
            // Note: This will only bring up the installation page on the TV.
            //       The user will still have to acknowledge by selecting "install" using the TV remote.
//            msApplication.install({ (success, error) -> Void in
//                if success == true {
//                    print("Application.install Success")
//                } else {
//                    print("Application.install Error : \(error)")
//                }
//            })
        } else {
            print("Service is nil now...")
        }
        

            // Disconnect from the application
//            msApplication.disconnect()
//        }
        // Fallback to getting service from NetworkScanner
//        else if let samsungService = networkScanner.getSamsungTVService(for: connectedTV) {
//            print("✅ AppsView: Using Samsung TV service from NetworkScanner")
//            appLauncher.connectToService(samsungService)
//            appLauncher.launchApp(app)
//        }
//        else {
//            print("❌ AppsView: No Samsung TV service available for \(connectedTV.name)")
//            print("💡 AppsView: This may happen if TV was discovered via network scan instead of SmartView SDK")
//        }
    }
}

// MARK: - Samsung TV App View
struct SamsungAppView: View {
    let app: TVApp
    let isConnecting: Bool
    let onLaunch: () -> Void

    var body: some View {
        Button(action: onLaunch) {
            VStack(spacing: 8) {
                ZStack {
                    // Background with app image
                    Image(app.imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 85)
                        .clipped()
                        .cornerRadius(20)
                        .overlay(
                            // Loading overlay
                            ZStack {
                                if isConnecting {
                                    Color.black.opacity(0.6)
                                        .cornerRadius(20)

                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(.white)
                                }
                            }
                        )

                    // Samsung TV launch indicator
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "tv")
                                .font(.caption2)
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Color.green.opacity(0.8))
                                .clipShape(Circle())
                        }
                        Spacer()
                    }
                    .padding(6)
                }

                Text(app.name)
                    .foregroundColor(.white)
                    .font(.caption)
                    .lineLimit(1)
            }
        }
        .disabled(isConnecting)
        .scaleEffect(isConnecting ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isConnecting)
    }
}

struct StreamingAppView: View {
    
    let imageName: String
    let backgroundColor: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Background with app image as full container
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 120, height: 85)
                    .clipped()
                    .cornerRadius(20)
            }
            
        
        }
    }
}


#Preview {
    AppsView()
        .environmentObject(TVConnectionManager.shared)
}
