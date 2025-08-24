//
//  LoginView.swift
//  VendorVault
//
//  Created by Matthew Chan on 7/20/25.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var authService = AuthService()
    @State private var email = ""
    @State private var password = ""
    @State private var isRegistering = false
    @State private var showForgotPassword = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // TCG Background
                TCGGradients.cardBackground
                    .ignoresSafeArea()
                
                VStack(spacing: TCGSpacing.xxxl) {
                    Spacer()
                    
                    // App Logo and Title
                    VStack(spacing: TCGSpacing.xl) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 80))
                            .foregroundColor(TCGTheme.primary)
                            .shadow(color: TCGTheme.primary.opacity(0.3), radius: 10, x: 0, y: 5)
                        
                        Text("VendorVault")
                            .font(TCGTypography.titleLarge)
                            .foregroundColor(TCGTheme.textPrimary)
                            .fontWeight(.bold)
                        
                        Text(isRegistering ? "Create your account" : "Welcome back")
                            .font(TCGTypography.titleMedium)
                            .foregroundColor(TCGTheme.textSecondary)
                    }
                    
                    // Form
                    VStack(spacing: TCGSpacing.xl) {
                        // Email field
                        VStack(alignment: .leading, spacing: TCGSpacing.sm) {
                            Text("Email")
                                .font(TCGTypography.headline)
                                .foregroundColor(TCGTheme.textPrimary)
                            
                            TextField("Enter your email", text: $email)
                                .textFieldStyle(TCGTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        
                        // Password field
                        VStack(alignment: .leading, spacing: TCGSpacing.sm) {
                            Text("Password")
                                .font(TCGTypography.headline)
                                .foregroundColor(TCGTheme.textPrimary)
                            
                            SecureField("Enter your password", text: $password)
                                .textFieldStyle(TCGTextFieldStyle())
                        }
                        
                        // Forgot Password (only show on login)
                        if !isRegistering {
                            Button("Forgot Password?") {
                                showForgotPassword = true
                            }
                            .font(TCGTypography.caption)
                            .foregroundColor(TCGTheme.primary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        
                        // Action Button
                        Button(action: {
                            Task {
                                await performAction()
                            }
                        }) {
                            HStack {
                                if authService.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                }
                                
                                Text(authService.isLoading ? "Please wait..." : (isRegistering ? "Create Account" : "Sign In"))
                                    .font(TCGTypography.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(TCGSpacing.lg)
                        }
                        .tcgButtonStyle()
                        .disabled(authService.isLoading || email.isEmpty || password.isEmpty)
                        .opacity((email.isEmpty || password.isEmpty) ? 0.6 : 1.0)
                        
                        // Toggle between login and register
                        Button(action: {
                            withAnimation(TCGAnimation.easeInOut) {
                                isRegistering.toggle()
                                email = ""
                                password = ""
                                authService.errorMessage = nil
                            }
                        }) {
                            Text(isRegistering ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                                .font(TCGTypography.body)
                                .foregroundColor(TCGTheme.primary)
                        }
                    }
                    .padding(.horizontal, TCGSpacing.xxxl)
                    
                    Spacer()
                }
            }
            .alert("Error", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $showForgotPassword) {
                ForgotPasswordView(authService: authService)
            }
            .onChange(of: authService.errorMessage) { errorMessage in
                if let error = errorMessage {
                    alertMessage = error
                    showAlert = true
                }
            }
        }
        .preferredColorScheme(.light)
    }
    
    private func performAction() async {
        guard !email.isEmpty && !password.isEmpty else { return }
        
        do {
            if isRegistering {
                try await authService.signUp(email: email, password: password)
            } else {
                try await authService.signIn(email: email, password: password)
            }
        } catch {
            // Error is handled by the authService and displayed via alert
        }
    }
}

struct TCGTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(TCGSpacing.md)
            .background(TCGTheme.secondaryBackground)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(TCGTheme.cardBorderLight, lineWidth: 1)
            )
            .foregroundColor(TCGTheme.textPrimary)
            .font(TCGTypography.body)
    }
}

struct ForgotPasswordView: View {
    @ObservedObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isSuccess = false
    
    var body: some View {
        NavigationView {
            ZStack {
                TCGGradients.cardBackground
                    .ignoresSafeArea()
                
                VStack(spacing: TCGSpacing.xxxl) {
                    Spacer()
                    
                    VStack(spacing: TCGSpacing.xl) {
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 60))
                            .foregroundColor(TCGTheme.primary)
                        
                        Text("Reset Password")
                            .font(TCGTypography.titleLarge)
                            .foregroundColor(TCGTheme.textPrimary)
                        
                        Text("Enter your email address and we'll send you a link to reset your password")
                            .font(TCGTypography.body)
                            .foregroundColor(TCGTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, TCGSpacing.xxxl)
                    }
                    
                    VStack(spacing: TCGSpacing.xl) {
                        VStack(alignment: .leading, spacing: TCGSpacing.sm) {
                            Text("Email")
                                .font(TCGTypography.headline)
                                .foregroundColor(TCGTheme.textPrimary)
                            
                            TextField("Enter your email", text: $email)
                                .textFieldStyle(TCGTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        
                        Button(action: {
                            Task {
                                await resetPassword()
                            }
                        }) {
                            HStack {
                                if authService.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                }
                                
                                Text(authService.isLoading ? "Sending..." : "Send Reset Link")
                                    .font(TCGTypography.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(TCGSpacing.lg)
                        }
                        .tcgButtonStyle()
                        .disabled(authService.isLoading || email.isEmpty)
                        .opacity(email.isEmpty ? 0.6 : 1.0)
                    }
                    .padding(.horizontal, TCGSpacing.xxxl)
                    
                    Spacer()
                }
            }
            .navigationTitle("Reset Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(TCGTheme.primary)
                }
            }
            .alert(isSuccess ? "Success" : "Error", isPresented: $showAlert) {
                Button("OK", role: .cancel) {
                    if isSuccess {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
            .onChange(of: authService.errorMessage) { errorMessage in
                if let error = errorMessage {
                    alertMessage = error
                    isSuccess = false
                    showAlert = true
                }
            }
        }
        .preferredColorScheme(.light)
    }
    
    private func resetPassword() async {
        guard !email.isEmpty else { return }
        
        do {
            try await authService.resetPassword(email: email)
            alertMessage = "Password reset email sent! Check your inbox."
            isSuccess = true
            showAlert = true
        } catch {
            // Error is handled by the authService
        }
    }
} 