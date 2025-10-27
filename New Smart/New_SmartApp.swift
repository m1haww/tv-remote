
//
//  Smart_TVApp.swift
//  Smart TV
//
//  Created by Mihail Ozun on 13.10.2025.
//

import SwiftUI

@main
struct New_SmartApp: App {
    @StateObject private var tvConnectionManager = TVConnectionManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(tvConnectionManager)
        }
    }
}
