// MainView.swift

import SwiftUI

struct MainView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var coachSelection: CoachSelection

    var body: some View {
        Group {
            if authViewModel.user != nil {
                if authViewModel.userProfile.role == "Coach" {
                    TabView {
                        CoachDashboardView()
                            .environmentObject(coachSelection)
                            .tabItem {
                                Image(systemName: "person.3.fill")
                                Text("Athletes")
                            }

                        TrainingView()
                            .environmentObject(coachSelection.athleteProfile)
                            .tabItem {
                                Image(systemName: "figure.walk")
                                Text("Training")
                            }

                        NutritionView()
                            .environmentObject(coachSelection.athleteProfile)
                            .tabItem {
                                Image(systemName: "fork.knife")
                                Text("Nutrition")
                            }

                        RecoveryView()
                            .environmentObject(coachSelection.athleteProfile)
                            .tabItem {
                                Image(systemName: "bed.double")
                                Text("Recovery")
                            }

                        ProfileView()
                            .tabItem {
                                Image(systemName: "person.crop.circle")
                                Text("Profile")
                            }
                    }
                    .edgesIgnoringSafeArea(.all)
                } else {
                    TabView {
                        DashboardView()
                            .tabItem {
                                Image(systemName: "house.fill")
                                Text("Dashboard")
                            }

                    TrainingView()
                        .tabItem {
                            Image(systemName: "figure.walk")
                            Text("Training")
                        }

                    NutritionView()
                        .tabItem {
                            Image(systemName: "fork.knife")
                            Text("Nutrition")
                        }

                    RecoveryView()
                        .tabItem {
                            Image(systemName: "bed.double")
                            Text("Recovery")
                        }

                        ProfileView()
                            .tabItem {
                                Image(systemName: "person.crop.circle")
                                Text("Profile")
                            }
                    }
                    .edgesIgnoringSafeArea(.all)
                }
            } else {
                LoginView()
            }
        }
    }
}
