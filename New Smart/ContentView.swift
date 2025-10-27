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
    
    var body: some View {
        ZStack {
            Color(hex: "16171D").ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Global TV Connection Status Bar
                if tvConnectionManager.isConnectedToTV {
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
                    .transition(.move(edge: .top))
                    
                    Spacer()
                        .frame(height: 10)
                }
                
                TabView(selection: $selectedTab) {
                RemoteView()
                    .tabItem {
                        Image("remote")
                            .renderingMode(.template)
                        Text("Remote")
                    }
                    .tag(0)

                AppsView()
                    .tabItem {
                        Image("apps")
                            .renderingMode(.template)
                        Text("Apps")
                    }
                    .tag(1)

                CastView()
                    .tabItem {
                        Image("cast")
                            .renderingMode(.template)
                        Text("Cast")
                    }
                    .tag(2)

                SettingsView()
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
    }
}
