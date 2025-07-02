//
//  SplashView.swift
//  AthleteHub
//
//  Created by Henry Church on 28/06/2025.
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            Color("AccentColor").edgesIgnoringSafeArea(.all)
            VStack {
                Image(systemName: "flame.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.white)
                Text("AthleteHub")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .bold()
            }
        }
    }
}
