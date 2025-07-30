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
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.black, Color.blue.opacity(0.8)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    // App Logo and Title
                    VStack(spacing: 20) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 80, design: .rounded))
                            .foregroundColor(.cyan)
                            .shadow(color: .cyan.opacity(0.5), radius: 10, x: 0, y: 5)
                        
                        Text("VendorVault")
                            .font(.modernLargeTitle())
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                        
                        Text(isRegistering ? "Create your account" : "Welcome back")
                            .font(.modernTitle2())
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    // Form
                    VStack(spacing: 20) {
                        // Email field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.modernSubheadline())
                                .foregroundColor(.white)
                            
                            TextField("Enter your email", text: $email)
                                .textFieldStyle(CustomTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        
                        // Password field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.modernSubheadline())
                                .foregroundColor(.white)
                            
                            SecureField("Enter your password", text: $password)
                                .textFieldStyle(CustomTextFieldStyle())
                        }
                        
                        // Forgot Password (only show on login)
                        if !isRegistering {
                            Button("Forgot Password?") {
                                showForgotPassword = true
                            }
                            .font(.modernCaption())
                            .foregroundColor(.cyan)
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
                                    .font(.modernHeadline())
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [.cyan, .blue]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .shadow(color: .cyan.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .disabled(authService.isLoading || email.isEmpty || password.isEmpty)
                        .opacity((email.isEmpty || password.isEmpty) ? 0.6 : 1.0)
                        
                        // Toggle between login and register
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isRegistering.toggle()
                                email = ""
                                password = ""
                                authService.errorMessage = nil
                            }
                        }) {
                            Text(isRegistering ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                                .font(.modernSubheadline())
                                .foregroundColor(.cyan)
                        }
                    }
                    .padding(.horizontal, 40)
                    
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
        .preferredColorScheme(.dark)
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

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            .foregroundColor(.white)
            .font(.modernBody())
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
                LinearGradient(
                    gradient: Gradient(colors: [Color.black, Color.blue.opacity(0.8)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    VStack(spacing: 20) {
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 60, design: .rounded))
                            .foregroundColor(.cyan)
                        
                        Text("Reset Password")
                            .font(.modernLargeTitle())
                            .foregroundColor(.white)
                        
                        Text("Enter your email address and we'll send you a link to reset your password")
                            .font(.modernBody())
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.modernSubheadline())
                                .foregroundColor(.white)
                            
                            TextField("Enter your email", text: $email)
                                .textFieldStyle(CustomTextFieldStyle())
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
                                    .font(.modernHeadline())
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [.cyan, .blue]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                        }
                        .disabled(authService.isLoading || email.isEmpty)
                        .opacity(email.isEmpty ? 0.6 : 1.0)
                    }
                    .padding(.horizontal, 40)
                    
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
                    .foregroundColor(.cyan)
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
        .preferredColorScheme(.dark)
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