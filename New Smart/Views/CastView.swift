//
//  CastView.swift
//  Smart TV
//
//  Created by Mihail Ozun on 13.10.2025.
//

import SwiftUI

struct CastView: View {
    @EnvironmentObject var tvConnectionManager: TVConnectionManager
    @State private var showTVList = false
    
    var body: some View {
        ZStack {
            Color(hex: "16171D").ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                AppBar(title: "TV Remote")
                
                if tvConnectionManager.isConnectedToTV {
                    // Connected TV Card
                    ConnectedTVCard()
                    
                    Spacer()
                        .frame(height: 15)
                    
                    // Cast Options Grid
                    VStack(spacing: 20) {
                        HStack(spacing: 20) {
                            CastOptionCard(
                                imageName: "photos",
                                title: "Photos",
                                subtitle: "Cast Photos",
                                color: Color(hex: "7511EB"),
                                isEnabled: true
                            )
                            
                            CastOptionCard(
                                imageName: "video",
                                title: "Videos", 
                                subtitle: "Cast Videos",
                                color: Color(hex: "7511EB"),
                                isEnabled: true
                            )
                        }
                        
                        HStack(spacing: 20) {
                            CastOptionCard(
                                imageName: "playlist",
                                title: "Music",
                                subtitle: "Cast Music",
                                color: Color(hex: "7511EB"),
                                isEnabled: true
                            )
                            
                            CastOptionCard(
                                imageName: "open-folder",
                                title: "Documents",
                                subtitle: "Cast Documents", 
                                color: Color(hex: "7511EB"),
                                isEnabled: true
                            )
                        }
                    }
                    .padding(.horizontal, 20)
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
    }
}

struct CastOptionCard: View {
    let imageName: String
    let title: String
    let subtitle: String
    let color: Color
    let isEnabled: Bool
    
    var body: some View {
        Button(action: {
            if isEnabled {
                print("Cast \(title) selected")
            }
        }) {
            VStack(spacing: 15) {
                Image(imageName)
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(isEnabled ? color : .gray)
                    .frame(width: 40, height: 40)
                
                VStack(spacing: 4) {
                    Text(title)
                        .foregroundColor(isEnabled ? .white : .gray)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(isEnabled ? subtitle : "Connect TV first")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 25)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(hex: isEnabled ? "3D3D5C" : "2A2A2A"))
            )
        }
        .disabled(!isEnabled)
    }
}

#Preview {
    CastView()
        .environmentObject(TVConnectionManager.shared)
}
