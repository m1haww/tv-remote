//
//  AppBar.swift
//  Smart TV
//
//  Created by Mihail Ozun on 25.10.2025.
//

import SwiftUI

struct AppBar: View {
    let title: String
    
    var body: some View {
        HStack {
            Image("Broadcast")
                .resizable()
                .renderingMode(.template)
                .foregroundColor(Color(hex: "575876"))
                .frame(width: 24, height: 24)
            
            Spacer()
            
            Text(title)
                .foregroundColor(.white)
                .font(.title2)
                .fontWeight(.medium)
            
            Spacer()
            
            Spacer()
                .frame(width: 30)
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 32)
    }
}

#Preview {
    ZStack {
        Color(hex: "16171D").ignoresSafeArea()
        AppBar(title: "TV Remote")
    }
}