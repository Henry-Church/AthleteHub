//
//  ContentLoader.swift
//  AthleteHub
//
//  Created by Henry Church on 28/06/2025.
//

import SwiftUI

struct ContentLoader: View {
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                SplashView()
            } else {
                MainView()
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    isLoading = false
                }
            }
        }
    }
}
