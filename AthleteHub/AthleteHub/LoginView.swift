// LoginView.swift

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var email = ""
    @State private var password = ""
    @State private var showSignUp = false

    var textFieldBackground: Color {
        colorScheme == .dark ? Color(.systemGray5) : Color(.secondarySystemBackground)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Image(systemName: "flame.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .foregroundColor(.accentColor)
                    .padding(.top, 40)

                Text("Login")
                    .font(.title)
                    .fontWeight(.bold)

                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "envelope")
                            .foregroundColor(.gray)
                        TextField("Email ID", text: $email)
                            .autocapitalization(.none)
                    }
                    .padding()
                    .background(textFieldBackground)
                    .cornerRadius(8)

                    HStack {
                        Image(systemName: "lock")
                            .foregroundColor(.gray)
                        SecureField("Password", text: $password)
                        Spacer()
                        Button("Forgot?") {
                            // Handle forgot password
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    .padding()
                    .background(textFieldBackground)
                    .cornerRadius(8)
                }
                .padding(.horizontal)

                Button(action: {
                    authViewModel.signIn(email: email, password: password)
                }) {
                    Text("Login")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.horizontal)

                HStack {
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.gray.opacity(0.3))
                    Text("OR")
                        .foregroundColor(.gray)
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.gray.opacity(0.3))
                }
                .padding(.horizontal)

                SignInWithAppleButton(.signIn, onRequest: { request in
                    authViewModel.handleAppleRequest(request: request)
                }, onCompletion: { result in
                    authViewModel.handleAppleCompletion(result: result)
                })
                .frame(height: 45)
                .cornerRadius(8)
                .padding(.horizontal)

                HStack {
                    Text("New to AthleteHub?")
                        .foregroundColor(.secondary)
                    Button("Register") {
                        showSignUp = true
                    }
                    .foregroundColor(.blue)
                }
                .font(.footnote)

                Spacer()
            }
            .sheet(isPresented: $showSignUp) {
                SignUpView()
                    .environmentObject(authViewModel)
            }
        }
    }
}
