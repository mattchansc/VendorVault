//
//  AuthService.swift
//  VendorVault
//
//  Created by Matthew Chan on 7/20/25.
//

import Foundation
import FirebaseAuth
import Combine

class AuthService: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init() {
        // Listen for authentication state changes
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.user = user
                self?.isAuthenticated = user != nil
            }
        }
    }
    
    // MARK: - Sign Up
    func signUp(email: String, password: String) async throws {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            await MainActor.run {
                self.user = result.user
                self.isAuthenticated = true
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
            throw error
        }
    }
    
    // MARK: - Sign In
    func signIn(email: String, password: String) async throws {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            await MainActor.run {
                self.user = result.user
                self.isAuthenticated = true
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
            throw error
        }
    }
    
    // MARK: - Sign Out
    func signOut() {
        do {
            try Auth.auth().signOut()
            user = nil
            isAuthenticated = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Reset Password
    func resetPassword(email: String) async throws {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
            await MainActor.run {
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
            throw error
        }
    }
} 