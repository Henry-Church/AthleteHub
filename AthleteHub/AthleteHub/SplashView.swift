//
//  SplashView.swift
//  AthleteHub
//
//  Created by Henry Church on 28/06/2025.
//

import SwiftUI

struct SplashView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            Color(red: 0.987, green: 0.147, blue: 0.194).ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image("flame")
                    .resizable()
                    .scaledToFit()
                    .frame(width: animate ? 80 : 64, height: animate ? 80 : 64)
                    .scaleEffect(animate ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.6).repeatCount(2, autoreverses: true), value: animate)
                
                Text("AthleteHub")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                    .opacity(animate ? 1 : 0)
                    .animation(.easeIn(duration: 1.2), value: animate)
            }
        }
        .onAppear {
            animate = true
        }
    }
}
