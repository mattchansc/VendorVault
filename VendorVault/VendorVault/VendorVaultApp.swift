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
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
