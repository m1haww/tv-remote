//
//  RemoteView.swift
//  Smart TV
//
//  Created by Mihail Ozun on 13.10.2025.
//

import SwiftUI

struct RemoteView: View {
    @EnvironmentObject var tvConnectionManager: TVConnectionManager
    @State private var isTargetSelected = true
    @State private var showKeyboard = false
    @State private var keyboardText = ""
    @State private var showTVList = false
    
    var body: some View {
        ZStack {
            Color(hex: "16171D").ignoresSafeArea()
            
            VStack(spacing: 25) {
                // TV Remote Header Card
                Button(action: {
                    if tvConnectionManager.connectedTV == nil {
                        showTVList = true
                    }
                }) {
                HStack(spacing: 15) {
                    // Icon with gradient background
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color(hex: "B917FF"), Color(hex: "7511EB")]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        
                        Image("Broadcast")
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                    }
                    .frame(width: 60, height: 60)
                    .padding(.leading, 0.5)
                    
                    // Title and status
                    VStack(alignment: .leading, spacing: 4) {
                        Text(tvConnectionManager.connectedTV?.name ?? "TV Remote")
                            .foregroundColor(.white)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        HStack(spacing: 8) {
                            Text(tvConnectionManager.isConnectedToTV ? "Connected" : "Tap to connect")
                                .foregroundColor(tvConnectionManager.isConnectedToTV ? .blue : .blue)
                                .font(.subheadline)
                            
                            if tvConnectionManager.isConnectedToTV {
                                Button("Disconnect") {
                                    tvConnectionManager.disconnectFromTV()
                                }
                                .foregroundColor(.red)
                                .font(.caption)
                            }
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
                        .fill(Color(hex: "2A2A3A"))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Color(hex: "110E19"), lineWidth: 1)
                )
                .padding(.horizontal, 20)
                
                
                    
                
                // Top Control Buttons
                HStack(spacing: 20) {
                    CustomImageButton(imageName: "Broadcast", size: 70,
                                      cornerRadius: 25)
                    
                    // Toggle container for target and cast buttons
                    ZStack {
                        // Background container
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color(hex: "3D3D5C"))
                            .frame(width: 160, height: 70)
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color(hex: "110E19"), lineWidth: 1)
                            )
                        // Moving purple background
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color(hex: "7511EB"))
                            .frame(width: 80, height: 70)
                            .offset(x: isTargetSelected ? -40 : 40, y: 0)
                            .animation(.easeInOut(duration: 0.3), value: isTargetSelected)
                        
                        // Buttons
                        HStack(spacing: 0) {
                            Button(action: {
                                isTargetSelected = true
                            }) {
                                Image("remote control")
                                    .resizable()
                                    .renderingMode(.template)
                                    .foregroundColor(.white)
                                    .frame(width: 28, height: 28)
                                    .frame(width: 80, height: 70)
                            }
                            
                            Button(action: {
                                isTargetSelected = false
                            }) {
                                Image("touchpad")
                                    .resizable()
                                    .renderingMode(.template)
                                    .foregroundColor(.white)
                                    .frame(width: 28, height: 28)
                                    .frame(width: 80, height: 70)
                            }
                        }
                    }
                    
                    Button(action: {
                        showKeyboard = true
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color(hex: "3D3D5C"))
                                .frame(width: 70, height: 70)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(Color(hex: "110E19"), lineWidth: 1)
                                )
                            
                            Image("keyboard")
                                .resizable()
                                .renderingMode(.template)
                                .foregroundColor(Color(hex: "DCCBFF"))
                                .frame(width: 28, height: 28)
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // Directional Pad or Coming Soon
                if isTargetSelected {
                    DirectionalPad()
                } else {
                    VStack(spacing: 20) {
                        Text("Coming Soon")
                            .foregroundColor(.white)
                            .font(.title)
                            .fontWeight(.semibold)
                        
                        Text("Touchpad functionality will be available in future updates")
                            .foregroundColor(.gray)
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(height: 250)
                }
                
                // Bottom Control Buttons - 4 rows x 3 columns
                VStack(spacing: 15) {
                    // Row 1
                    HStack(spacing: 15) {
                        RemoteButton(icon: "arrow.uturn.left") {
                            print("Back pressed")
                        }
                        .frame(maxWidth: .infinity)
                        
                        PowerButton(action: {
                            print("Power pressed")
                        })
                        .frame(maxWidth: .infinity)
                        
                        RemoteButton(icon: "house") {
                            print("Home pressed")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 20)
                    
                    // Row 2
                    HStack(spacing: 15) {
                        RemoteButton(icon: "goforward") {
                            print("Forward pressed")
                        }
                        .frame(maxWidth: .infinity)
                        
                        RemoteButton(icon: "mic") {
                            // Mic functionality can be added later
                        }
                        .frame(maxWidth: .infinity)
                        
                        RemoteButton(icon: "asterisk") {
                            // Asterisk functionality can be added later
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 20)
                    
                    // Row 3
                    HStack(spacing: 15) {
                        RemoteButton(icon: "backward.end") {
                            print("Previous pressed")
                        }
                        .frame(maxWidth: .infinity)
                        
                        RemoteButton(icon: "playpause") {
                            tvConnectionManager.sendTVCommand(.playPause)
                        }
                        .frame(maxWidth: .infinity)
                        
                        RemoteButton(icon: "forward.end") {
                            print("Next pressed")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 20)
                    
                    // Row 4
                    HStack(spacing: 15) {
                        RemoteButton(icon: "minus") {
                            tvConnectionManager.sendTVCommand(.volumeDown)
                        }
                        .frame(maxWidth: .infinity)
                        
                        RemoteButton(icon: "speaker.slash") {
                            tvConnectionManager.sendTVCommand(.mute)
                        }
                        .frame(maxWidth: .infinity)
                        
                        RemoteButton(icon: "plus") {
                            tvConnectionManager.sendTVCommand(.volumeUp)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer()
            }
            
            // Keyboard Bottom Sheet
            if showKeyboard {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showKeyboard = false
                    }
                
                VStack {
                    Spacer()
                    
                    VStack(spacing: 20) {
                        // Handle indicator
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 40, height: 6)
                            .padding(.top, 10)
                        
                        Text("Keyboard")
                            .foregroundColor(.white)
                            .font(.title2)
                            .fontWeight(.medium)
                            .padding(.top, 10)
                        
                        TextField("Enter the text", text: $keyboardText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color(hex: "7511EB"), lineWidth: 2)
                            )
                            .foregroundColor(.white)
                            .font(.body)
                            .padding(.horizontal, 20)
                        
                        Button(action: {
                            if !keyboardText.isEmpty {
                                print("Sending text: \(keyboardText)")
                            }
                            showKeyboard = false
                            keyboardText = ""
                        }) {
                            Text("Done")
                                .foregroundColor(.white)
                                .font(.body)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    Group {
                                        if keyboardText.isEmpty {
                                            RoundedRectangle(cornerRadius: 15)
                                                .fill(Color(hex: "3D3D5C"))
                                        } else {
                                            RoundedRectangle(cornerRadius: 15)
                                                .fill(
                                                    LinearGradient(
                                                        gradient: Gradient(colors: [Color(hex: "9037F7"), Color(hex: "6814CB")]),
                                                        startPoint: .top,
                                                        endPoint: .bottom
                                                    )
                                                )
                                        }
                                    }
                                )
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color(hex: "16171D"))
                    )
                }
                .transition(.move(edge: .bottom))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showKeyboard)
        .sheet(isPresented: $showTVList) {
            TVListView(isPresented: $showTVList)
                .environmentObject(tvConnectionManager)
        }
    }
}

struct DirectionalPad: View {
    @State private var pressedButton: String? = nil
    
    var body: some View {
        ZStack {
            // Background image
            Image("Button")
                .resizable()
                .frame(width: 250, height: 250)
            
            // Center OK text
            Text("OK")
                .foregroundColor(Color(hex: "DCCBFF"))
                .font(.title2)
                .fontWeight(.medium)
                .opacity(pressedButton == "OK" ? 0.5 : 1.0)
                .scaleEffect(pressedButton == "OK" ? 0.95 : 1.0)
            
            // Directional arrows
            VStack {
                // Top arrow
                Image(systemName: "chevron.up")
                    .foregroundColor(Color(hex: "DCCBFF"))
                    .font(.title)
                    .fontWeight(.semibold)
                    .opacity(pressedButton == "up" ? 0.5 : 1.0)
                    .scaleEffect(pressedButton == "up" ? 0.9 : 1.0)
                
                Spacer()
                
                HStack {
                    // Left arrow
                    Image(systemName: "chevron.left")
                        .foregroundColor(Color(hex: "DCCBFF"))
                        .font(.title)
                        .fontWeight(.semibold)
                        .opacity(pressedButton == "left" ? 0.5 : 1.0)
                        .scaleEffect(pressedButton == "left" ? 0.9 : 1.0)
                    
                    Spacer()
                    
                    // Right arrow
                    Image(systemName: "chevron.right")
                        .foregroundColor(Color(hex: "DCCBFF"))
                        .font(.title)
                        .fontWeight(.semibold)
                        .opacity(pressedButton == "right" ? 0.5 : 1.0)
                        .scaleEffect(pressedButton == "right" ? 0.9 : 1.0)
                }
                
                Spacer()
                
                // Bottom arrow
                Image(systemName: "chevron.down")
                    .foregroundColor(Color(hex: "DCCBFF"))
                    .font(.title)
                    .fontWeight(.semibold)
                    .opacity(pressedButton == "down" ? 0.5 : 1.0)
                    .scaleEffect(pressedButton == "down" ? 0.9 : 1.0)
            }
            .frame(width: 230, height: 230)
            
            
            // Invisible buttons overlay
            VStack(spacing: 0) {
                // Up button
                Button(action: {
                    print("Up pressed")
                }) {
                    Color.clear
                        .frame(width: 80, height: 70)
                }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            pressedButton = "up"
                        }
                        .onEnded { _ in
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                pressedButton = nil
                            }
                        }
                )
                
                HStack(spacing: 0) {
                    // Left button
                    Button(action: {
                        print("Left pressed")
                    }) {
                        Color.clear
                            .frame(width: 70, height: 80)
                    }
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                pressedButton = "left"
                            }
                            .onEnded { _ in
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    pressedButton = nil
                                }
                            }
                    )
                    
                    // Center OK button
                    Button(action: {
                        print("OK pressed")
                    }) {
                        Color.clear
                            .frame(width: 140, height: 80)
                    }
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                pressedButton = "OK"
                            }
                            .onEnded { _ in
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    pressedButton = nil
                                }
                            }
                    )
                    
                    // Right button
                    Button(action: {
                        print("Right pressed")
                    }) {
                        Color.clear
                            .frame(width: 70, height: 80)
                    }
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                pressedButton = "right"
                            }
                            .onEnded { _ in
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    pressedButton = nil
                                }
                            }
                    )
                }
                
                // Down button
                Button(action: {
                    print("Down pressed")
                }) {
                    Color.clear
                        .frame(width: 80, height: 70)
                }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            pressedButton = "down"
                        }
                        .onEnded { _ in
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                pressedButton = nil
                            }
                        }
                )
            }
        }
        .animation(.easeInOut(duration: 0.1), value: pressedButton)
    }
}

struct RemoteButton: View {
    let icon: String
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat
    let isSelected: Bool
    let action: () -> Void
    
    init(icon: String, width: CGFloat = 75, height: CGFloat = 45, cornerRadius: CGFloat = 20, isSelected: Bool = false, action: @escaping () -> Void = {}) {
        self.icon = icon
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
        self.isSelected = isSelected
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(isSelected ? Color(hex: "7511EB") : Color(hex: "3D3D5C"))
                    .frame(maxWidth: .infinity, idealHeight: height)
                
                Image(systemName: icon)
                    .foregroundColor(Color(hex: "DCCBFF"))
                    .font(.title)
            }
        }
    }
}

struct CustomImageButton: View {
    let imageName: String
    let size: CGFloat
    let cornerRadius: CGFloat
    let isSelected: Bool
    
    init(imageName: String, size: CGFloat, cornerRadius: CGFloat = 20, isSelected: Bool = false) {
        self.imageName = imageName
        self.size = size
        self.cornerRadius = cornerRadius
        self.isSelected = isSelected
    }
    
    var body: some View {
        Button(action: {
            if imageName == "Broadcast" {
                print("🖥️ Starting screen mirroring to TV...")
                startScreenMirroring()
            }
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(hex: "3D3D5C"))
                    .frame(width: size, height: size)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color(hex: "110E19"), lineWidth: 1)
                    )
                
                Image(imageName)
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(Color(hex: "DCCBFF"))
                    .frame(width: size * 0.4, height: size * 0.4)
            }
        }
    }
}

struct PowerButton: View {
    let action: () -> Void
    
    init(action: @escaping () -> Void = {}) {
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Image("Button Power")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipped()
                    .cornerRadius(20)
                
                Image(systemName: "power")
                    .foregroundColor(Color(hex: "DCCBFF"))
                    .font(.title2)
            }
            .padding(.horizontal, 5)
        }
    }
}

func startScreenMirroring() {
    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let window = windowScene.windows.first else {
        print("❌ Could not get window scene")
        return
    }
    
    // Open iOS Control Center programmatically for AirPlay
    if let url = URL(string: "prefs:root=WIFI") {
        UIApplication.shared.open(url)
        print("📱 Opened Settings - User can manually start AirPlay from Control Center")
    } else {
        // Alternative: Show alert with instructions
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "Screen Mirroring", 
                message: "To mirror your screen:\n1. Open Control Center\n2. Tap Screen Mirroring\n3. Select your TV", 
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            window.rootViewController?.present(alert, animated: true)
        }
    }
}

#Preview {
    RemoteView()
        .environmentObject(TVConnectionManager.shared)
}
