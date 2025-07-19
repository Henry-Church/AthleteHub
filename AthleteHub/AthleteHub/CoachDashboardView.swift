import SwiftUI
import FirebaseFirestore

struct AthleteRef: Identifiable {
    /// Readable identifier for the athlete, typically their profile name.
    var id: String
    /// Firebase UID for loading the full profile.
    var uid: String
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
                    NavigationLink(destination: AthleteDetailView(athleteId: athlete.uid)) {
                        Text(athlete.name)
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .onAppear {
                    loadAthletes()
                    fetchSuggestedAthletes()
                }

                Button(action: {
                    authViewModel.signOut()
                }) {
                    HStack {
                        Image(systemName: "arrow.backward.square")
                        Text("Sign Out")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .background(Color.red)
                    .cornerRadius(8)
                }
                .padding(.horizontal)
                .padding(.bottom)
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
    db.collectionGroup("profile")
        .whereField("role", isEqualTo: "Athlete")
        .limit(to: 50)
        .getDocuments { snapshot, _ in
            if let docs = snapshot?.documents {
                let filtered = docs.filter {
                    let name = ($0.data()["name"] as? String ?? "").lowercased()
                    return name.hasPrefix(trimmed.lowercased())
                }
                if !filtered.isEmpty {
                    searchResults = filtered.map {
                        AthleteRef(
                            id:   $0.data()["profileId"] as? String ?? "",
                            uid:  $0.reference.parent.parent?.documentID ?? "",
                            name: $0.data()["name"]      as? String ?? "Athlete"
                        )
                    }
                    errorMessage = nil
                } else {
                    searchResults = []
                    errorMessage = "No athletes found"
                }
            }
        }
}

private func fetchSuggestedAthletes() {
    let db = Firestore.firestore()
    db.collectionGroup("profile")
        .whereField("role", isEqualTo: "Athlete")
        .limit(to: 20)
        .getDocuments { snapshot, _ in
            if let docs = snapshot?.documents {
                let sorted = docs.sorted { lhs, rhs in
                    let left = lhs.data()["name"] as? String ?? ""
                    let right = rhs.data()["name"] as? String ?? ""
                    return left < right
                }
                suggestedAthletes = sorted.prefix(5).map {
                    AthleteRef(
                        id:   $0.data()["profileId"] as? String ?? "",
                        uid:  $0.reference.parent.parent?.documentID ?? "",
                        name: $0.data()["name"]      as? String ?? "Athlete"
                    )
                }
            }
        }
}

    private func addFoundAthlete(_ athlete: AthleteRef) {
        let db = Firestore.firestore()
        let coachId = authViewModel.userProfile.uid
        guard !coachId.isEmpty else { return }
        db.collection("coaches").document(coachId)
            .collection("athletes").document(athlete.id)
            .setData([
                "name": athlete.name,
                "uid": athlete.uid
            ]) { _ in
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
                    athletes = docs.map {
                        AthleteRef(
                            id: $0.documentID,
                            uid: $0.data()["uid"] as? String ?? "",
                            name: $0.data()["name"] as? String ?? "Athlete"
                        )
                    }
                }
            }
    }
}


struct AthleteDetailView: View {
    let athleteId: String
    @StateObject private var profile = UserProfile()

    var body: some View {
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
        }
        .environmentObject(profile)
        .onAppear {
            profile.uid = athleteId
            profile.loadFromFirestore()
        }
    }
}