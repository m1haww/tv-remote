//
//  SettingsView.swift
//  Smart TV
//
//  Created by Mihail Ozun on 20.10.2025.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        ZStack {
            Color(hex: "16171D").ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 0) {
                // Header
                AppBar(title: "TV Remote")
                
                VStack(alignment: .leading, spacing: 20) {
                    // Feedback Section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Feedback")
                            .foregroundColor(.white.opacity(0.6))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.horizontal, 25)
                        
                        VStack(spacing: 15) {
                            SettingRowNew(
                                imageName: "pencil",
                                iconColor: Color(hex: "F026E9"),
                                title: "Write a review"
                            )
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color(hex: "2A2A3A"))
                            )
                            .padding(.horizontal, 25)
                            
                            SettingRowNew(
                                imageName: "chat",
                                iconColor: Color(hex: "F0BD26"),
                                title: "Contact us"
                            )
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color(hex: "2A2A3A"))
                            )
                            .padding(.horizontal, 25)
                        }
                    }
                    
                    // Support Section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Support")
                            .foregroundColor(.white.opacity(0.6))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.horizontal, 25)
                        
                        VStack(spacing: 15) {
                            SettingRowNew(
                                imageName: "terms",
                                iconColor: Color(hex: "26BAF0"),
                                title: "Terms of use"
                            )
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color(hex: "2A2A3A"))
                            )
                            .padding(.horizontal, 25)
                            
                            SettingRowNew(
                                imageName: "privacy-policy",
                                iconColor: Color(hex: "8826F0"),
                                title: "Privacy policy"
                            )
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color(hex: "2A2A3A"))
                            )
                            .padding(.horizontal, 25)
                        }
                    }
                }
                
                Spacer()
            }
        }
    }
}

struct SettingRowNew: View {
    let imageName: String
    let iconColor: Color
    let title: String
    
    var body: some View {
        Button(action: {
            // Action for each setting row
        }) {
            HStack(spacing: 20) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(iconColor)
                        .frame(width: 40, height: 40)
                    
                    Image(imageName)
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                }
                
                Text(title)
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .medium))
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.4))
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.horizontal, 25)
            .padding(.vertical, 20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
