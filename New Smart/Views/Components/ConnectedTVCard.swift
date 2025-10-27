//
//  ConnectedTVCard.swift
//  Smart TV
//
//  Created by Mihail Ozun on 25.10.2025.
//

import SwiftUI

struct ConnectedTVCard: View {
    @EnvironmentObject var tvConnectionManager: TVConnectionManager
    
    var body: some View {
        Button(action: {
            // Could add disconnect functionality
        }) {
            HStack(spacing: 15) {
                // Chrome icon in white container
                Image("chrome")
                    .resizable()
                    .frame(width: 28, height: 28)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(.white)
                    )
                .padding(.leading, 0.5)
                
                // Title and status
                VStack(alignment: .leading, spacing: 4) {
                    Text(tvConnectionManager.connectedTV?.name ?? "TV Name")
                        .foregroundColor(.white)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 8) {
                        Text("Connected")
                            .foregroundColor(Color(hex: "00FF2F"))
                            .font(.subheadline)
                    }
                }
                
                Spacer()
            }
        }
        .padding(.leading, 6)
        .padding(.trailing, 30)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color(hex: "B917FF"), Color(hex: "7511EB")]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 25)
                .stroke(Color(hex: "110E19"), lineWidth: 1)
        )
        .padding(.horizontal, 15)
    }
}

#Preview {
    ZStack {
        Color(hex: "16171D").ignoresSafeArea()
        ConnectedTVCard()
            .environmentObject(TVConnectionManager.shared)
    }
}
