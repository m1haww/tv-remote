//
//  ContentView.swift
//  Smart TV
//
//  Created by Mihail Ozun on 13.10.2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var tvConnectionManager: TVConnectionManager
    @State private var selectedTab = 0
    @State private var showNotification = false

    var body: some View {
        ZStack {
            Color(hex: "16171D").ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $selectedTab) {
                TabContentWrapper(showNotification: $showNotification) {
                    RemoteView()
                }
                .tabItem {
                    Image("remote")
                        .renderingMode(.template)
                    Text("Remote")
                }
                .tag(0)

                TabContentWrapper(showNotification: $showNotification) {
                    AppsView()
                }
                .tabItem {
                    Image("apps")
                        .renderingMode(.template)
                    Text("Apps")
                }
                .tag(1)

                TabContentWrapper(showNotification: $showNotification) {
                    CastView()
                }
                .tabItem {
                    Image("cast")
                        .renderingMode(.template)
                    Text("Cast")
                }
                .tag(2)

                TabContentWrapper(showNotification: $showNotification) {
                    SettingsView()
                }
                .tabItem {
                    Image("settings")
                        .renderingMode(.template)
                    Text("Settings")
                }
                .tag(3)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: tvConnectionManager.isConnectedToTV)
        .accentColor(Color(hex: "7C3AED"))
        .preferredColorScheme(.dark)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithTransparentBackground()
            appearance.backgroundColor = UIColor(Color(hex: "16171D"))
            appearance.selectionIndicatorTintColor = UIColor(Color(hex: "7C3AED"))
            appearance.shadowColor = UIColor.clear

            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        .onChange(of: tvConnectionManager.isConnectedToTV) { newValue in
            if newValue {
                // Show notification when connected
                showNotification = true

                // Auto-dismiss after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation {
                        showNotification = false
                    }
                }
            } else {
                // Hide immediately when disconnected
                showNotification = false
            }
        }
    }
}

// Wrapper view to add notification to each tab
struct TabContentWrapper<Content: View>: View {
    @EnvironmentObject var tvConnectionManager: TVConnectionManager
    @Binding var showNotification: Bool
    let content: Content

    init(showNotification: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self._showNotification = showNotification
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .top) {
            content

            // Top notification bar
            if showNotification && tvConnectionManager.isConnectedToTV {
                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "tv.fill")
                            .foregroundColor(.blue)
                            .font(.caption)

                        Text("Connected to \(tvConnectionManager.connectedTV?.name ?? "TV")")
                            .foregroundColor(.white)
                            .font(.caption)
                            .fontWeight(.medium)

                        Spacer()

                        Circle()
                            .fill(.blue)
                            .frame(width: 8, height: 8)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(hex: "2A2A3A"))

                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(999)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showNotification)
    }
}
