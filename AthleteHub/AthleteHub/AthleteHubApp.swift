//
//  AthleteHubApp.swift
//  AthleteHub
//
//  Created by Henry Church on 28/06/2025.
//

import SwiftUI
import Firebase
import GoogleSignIn

@main
struct AthleteHubApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var healthManager = HealthManager()
    @State private var isLoading = true

    var body: some Scene {
        WindowGroup {
            if isLoading {
                SplashView()
                    .onAppear {
                        // Simulate any setup / initialization delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            isLoading = false
                        }
                    }
            } else {
                MainView()
                    .environmentObject(authViewModel)
                    .environmentObject(authViewModel.userProfile)
                    .environmentObject(healthManager)
            }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}
