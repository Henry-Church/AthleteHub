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
    @State private var suggestedAthletes: [AthleteRef] = []
    @State private var errorMessage: String?
    @State private var athletes: [AthleteRef] = []

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    TextField("Athlete name", text: $searchName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: searchName) { _ in searchForName() }
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
                } else if !searchName.isEmpty {
                    Text(errorMessage ?? "No athletes found")
                        .foregroundColor(.red)
                        .padding(.horizontal)
                } else if !suggestedAthletes.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Suggested")
                            .font(.headline)
                        ForEach(suggestedAthletes) { suggestion in
                            HStack {
                                Text(suggestion.name)
                                Spacer()
                                Button("Add") { addFoundAthlete(suggestion) }
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                List(athletes) { athlete in
                    NavigationLink(destination: AthleteDetailView(athleteId: athlete.id)) {
                        Text(athlete.name)
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .onAppear {
                    loadAthletes()
                    fetchSuggestedAthletes()
                }
            }
            .navigationTitle("Coach Dashboard")
        }
    }

    private func searchForName() {
        let db = Firestore.firestore()
        let trimmed = searchName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            searchResults = []
            return
        }
        db.collection("users")
            .whereField("role", isEqualTo: "Athlete")
            .order(by: "name")
            .start(at: [trimmed])
            .end(at: [trimmed + "\u{f8ff}"])
            .limit(to: 10)
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

    private func fetchSuggestedAthletes() {
        let db = Firestore.firestore()
        db.collection("users")
            .whereField("role", isEqualTo: "Athlete")
            .order(by: "name")
            .limit(to: 5)
            .getDocuments { snapshot, _ in
                if let docs = snapshot?.documents {
                    suggestedAthletes = docs.map { AthleteRef(id: $0.documentID, name: $0.data()["name"] as? String ?? "Athlete") }
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
        let coachId = authViewModel.userProfile.uid
        guard !coachId.isEmpty else { return }
        db.collection("coaches").document(coachId)
            .collection("athletes")
            .getDocuments { snapshot, _ in
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