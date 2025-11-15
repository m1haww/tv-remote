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

                        Text("Your connects")
                            .foregroundColor(.white)
                            .font(.headline)

                        Spacer()

                        if discoveryService.isScanning {
                            ProgressView()
                                .scaleEffect(1.2)
                                .tint(.white)
                        } else {
                            // Empty space to maintain layout
                            Color.clear
                                .frame(width: 24, height: 24)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 30)
                    
                    
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
            // TV Name
            Text(tv.name)
                .foregroundColor(.white)
                .font(.body)
                .fontWeight(.medium)
                .lineLimit(1)

            Spacer()

            // Cast Icon
            Image(systemName: "tv")
                .foregroundColor(.white)
                .font(.title3)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(hex: "3D3D5C"))
        )
        .onTapGesture {
            onSelect()
        }
    }
}
