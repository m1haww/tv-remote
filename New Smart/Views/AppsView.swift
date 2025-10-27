//
//  AppsView.swift
//  Smart TV
//
//  Created by Mihail Ozun on 13.10.2025.
//

import SwiftUI

struct AppsView: View {
    @EnvironmentObject var tvConnectionManager: TVConnectionManager
    @State private var showTVList = false
    
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
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                        
                        StreamingAppView( imageName: "youtube", backgroundColor: .white)
                        StreamingAppView(imageName: "netflix", backgroundColor: .black)
                        StreamingAppView( imageName: "disnep", backgroundColor: Color(hex: "1E3A8A"))
                        StreamingAppView(imageName: "hulu", backgroundColor: Color(hex: "1DB954"))
                        StreamingAppView(imageName: "hbomax", backgroundColor: .black)
                        StreamingAppView( imageName: "amigo", backgroundColor: .black)
                        StreamingAppView(imageName: "twitch", backgroundColor: Color(hex: "9146FF"))
                    }
                    .padding(.horizontal, 16)
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
