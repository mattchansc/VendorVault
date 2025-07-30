//
//  VendorVaultApp.swift
//  VendorVault
//
//  Created by Matthew Chan on 7/20/25.
//

import SwiftUI
import FirebaseCore

@main
struct VendorVaultApp: App {
    @StateObject private var authService = AuthService()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            if authService.isAuthenticated {
                ContentView()
                    .environmentObject(authService)
            } else {
                LoginView()
                    .environmentObject(authService)
            }
        }
    }
}
