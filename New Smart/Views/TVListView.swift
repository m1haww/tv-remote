import SwiftUI
import Combine

struct TVListView: View {
    @EnvironmentObject var tvConnectionManager: TVConnectionManager
    @StateObject private var discoveryService = NetworkScanner.shared
    @Binding var isPresented: Bool
    @State private var showingConnectionAlert = false
    @State private var tvToConnect: DiscoveredTV?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "16171D").ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        Button(action: {
                            discoveryService.stopDiscovery()
                            isPresented = false
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(Color(hex: "DCCBFF"))
                                .font(.title2)
                        }
                        
                        Spacer()
                        
                        Text("Available TVs")
                            .foregroundColor(.white)
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: {
                            if !discoveryService.isScanning {
                                discoveryService.startDiscovery()
                            }
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(Color(hex: "DCCBFF"))
                                .font(.title2)
                        }
                        .disabled(discoveryService.isScanning)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 30)
                    
                    // Scanning indicator
                    if discoveryService.isScanning {
                        HStack(spacing: 15) {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(Color(hex: "7511EB"))
                            
                            Text("Searching for TVs...")
                                .foregroundColor(.gray)
                                .font(.subheadline)
                        }
                        .padding()
                    }
                    
                    // TV List
                    if discoveryService.discoveredTVs.isEmpty && !discoveryService.isScanning {
                        VStack(spacing: 30) {
                            Spacer()
                            
                            VStack(spacing: 20) {
                                Text("Your connections")
                                    .foregroundColor(.white)
                                    .font(.title)
                                    .fontWeight(.semibold)
                                
                                Text("Make sure your phone and TV are connected to the same Wi-Fi network.")
                                    .foregroundColor(.gray)
                                    .font(.subheadline)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                                
                                Image("no connection")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 120, height: 120)
                                
                                Text("We are looking for a device")
                                    .foregroundColor(Color(hex: "9037F7"))
                                    .font(.title2)
                                    .fontWeight(.semibold)
                            }
                            
                            Spacer()
                        }
                    } 
                     else {
                         ScrollView {
                             LazyVStack(spacing: 15) {
                                 ForEach(discoveryService.discoveredTVs) { tv in
                                     TVDeviceRow(tv: tv) {
                                         tvToConnect = tv
                                         showingConnectionAlert = true
                                     }
                                 }
                             }
                             .padding(.horizontal, 20)
                         }
                     }
                    
                    Spacer()
                }
            }
        }
        .onAppear {
            discoveryService.startDiscovery()
        }
        .onDisappear {
            discoveryService.stopDiscovery()
        }
        .alert("Connect to TV?", isPresented: $showingConnectionAlert) {
            Button("Connect") {
                if let tv = tvToConnect {
                    connectToSelectedTV(tv)
                    isPresented = false
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let tv = tvToConnect {
                Text("Connect to \(tv.name) at \(tv.ipAddress)?")
            }
        }
    }

    // MARK: - Samsung TV Connection Logic
    private func connectToSelectedTV(_ tv: DiscoveredTV) {
        print("🔗 TVListView: Connecting to selected TV: \(tv.name)")

        // Check if it's a Samsung TV and we have a service for it
        if tv.manufacturer.lowercased().contains("samsung"),
           let samsungService = discoveryService.getSamsungTVService(for: tv) {
            
            print("Service uri: ====")
            print(samsungService.uri)
            print("📺 TVListView: Connecting to Samsung TV with SmartView service")
            tvConnectionManager.connectSamsungTVService(samsungService, discoveredTV: tv)
        } else {
            print("🖥️ TVListView: Connecting to non-Samsung TV or Samsung TV without service")
            tvConnectionManager.connectToTV(tv)
        }
    }
}

struct TVDeviceRow: View {
    let tv: DiscoveredTV
    let onSelect: () -> Void
    
    var body: some View {
        HStack(spacing: 15) {
            // TV Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "B917FF"), Color(hex: "7511EB")]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 60, height: 50)
                
                Image("Broadcast")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(tv.name)
                    .foregroundColor(.white)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(tv.ipAddress)
                    .foregroundColor(.gray)
                    .font(.subheadline)
                
                if let modelName = tv.modelName, !modelName.isEmpty {
                    Text(modelName)
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }
            
            Spacer()
            
            // Connect arrow
            Image(systemName: "chevron.right")
                .foregroundColor(Color(hex: "DCCBFF"))
                .font(.headline)
                .fontWeight(.medium)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(hex: "3D3D5C"))
        )
        .onTapGesture {
            onSelect()
        }
    }
}
