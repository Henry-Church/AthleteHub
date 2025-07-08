import SwiftUI
import FirebaseFirestore

struct AthleteRef: Identifiable {
    var id: String
    var name: String
}

struct CoachDashboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var searchName = ""
    @State private var searchResults: [AthleteRef] = []
    @State private var errorMessage: String?
    @State private var athletes: [AthleteRef] = []

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    TextField("Athlete name", text: $searchName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button("Find") { findAthletes() }
                }
                .padding()

                if !searchResults.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Results")
                            .font(.headline)
                        ForEach(searchResults) { result in
                            HStack {
                                Text(result.name)
                                Spacer()
                                Button("Add") { addFoundAthlete(result) }
                            }
                        }
                    }
                    .padding(.horizontal)
                } else if let message = errorMessage {
                    Text(message).foregroundColor(.red)
                }

                List(athletes) { athlete in
                    NavigationLink(destination: AthleteDetailView(athleteId: athlete.id)) {
                        Text(athlete.name)
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .onAppear { loadAthletes() }
            }
            .navigationTitle("Coach Dashboard")
        }
    }

    private func findAthletes() {
        let db = Firestore.firestore()
        db.collection("users")
            .whereField("name", isEqualTo: searchName)
            .whereField("role", isEqualTo: "Athlete")
            .getDocuments { snapshot, _ in
                if let docs = snapshot?.documents, !docs.isEmpty {
                    searchResults = docs.map { AthleteRef(id: $0.documentID, name: $0.data()["name"] as? String ?? "Athlete") }
                    errorMessage = nil
                } else {
                    searchResults = []
                    errorMessage = "No athletes found"
                }
            }
    }

    private func addFoundAthlete(_ athlete: AthleteRef) {
        let db = Firestore.firestore()
        let coachId = authViewModel.userProfile.uid
        guard !coachId.isEmpty else { return }
        db.collection("coaches").document(coachId)
            .collection("athletes").document(athlete.id)
            .setData(["name": athlete.name]) { _ in
                loadAthletes()
                searchResults.removeAll { $0.id == athlete.id }
                searchName = ""
            }
    }

    private func loadAthletes() {
        let db = Firestore.firestore()
        guard !authViewModel.userProfile.uid.isEmpty else { return }
        db.collection("coaches").document(authViewModel.userProfile.uid)
            .collection("athletes").getDocuments { snapshot, _ in
                if let docs = snapshot?.documents {
                    athletes = docs.map { AthleteRef(id: $0.documentID, name: $0.data()["name"] as? String ?? "Athlete") }
                }
            }
    }
}

struct AthleteDetailView: View {
    let athleteId: String
    @StateObject private var profile = UserProfile()

    var body: some View {
        DashboardView()
            .environmentObject(profile)
            .onAppear {
                profile.uid = athleteId
                profile.loadFromFirestore()
            }
    }
}
