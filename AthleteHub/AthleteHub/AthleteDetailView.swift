import SwiftUI

struct AthleteDetailView: View {
    let athleteId: String
    @StateObject private var profile = UserProfile()

    var body: some View {
        DashboardView()
            .environmentObject(profile)
            .onAppear {
                profile.loadFromFirestore(for: athleteId)
            }
    }
}
