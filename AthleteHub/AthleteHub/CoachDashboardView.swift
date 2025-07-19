import SwiftUI
import FirebaseFirestore

struct AthleteRef: Identifiable {
    /// Readable identifier for the athlete, typically their profile name.
    var id: String
    /// Firebase UID for loading the full profile.
    var uid: String
    var name: String
}

/// Lightweight metrics summary for a single athlete.
struct AthleteMetrics {
    var trainingScore: Int
    var recoveryScore: Int
}

struct CoachDashboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var athletes: [AthleteRef] = []
    @State private var selectedIndex: Int = 0
    @State private var metrics: AthleteMetrics? = nil

    @State private var searchName = ""
    @State private var searchResults: [AthleteRef] = []
    @State private var suggestedAthletes: [AthleteRef] = []
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if !athletes.isEmpty {
                        Picker("Athlete", selection: $selectedIndex) {
                            ForEach(athletes.indices, id: \.\u2060self) { idx in
                                Text(athletes[idx].name).tag(idx)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .onChange(of: selectedIndex) { _ in
                            loadMetrics(for: athletes[selectedIndex])
                        }
                        .padding(.horizontal)
                    }

                    if let m = metrics {
                        HStack(spacing: 16) {
                            MetricCard(title: "Training", value: "\(m.trainingScore)")
                            MetricCard(title: "Recovery", value: "\(m.recoveryScore)")
                        }
                        .padding(.horizontal)
                    } else if !athletes.isEmpty {
                        Text("No metrics available")
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    } else {
                        Text("No athletes added yet")
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }

                    Divider().padding(.vertical)

                    VStack(alignment: .leading, spacing: 12) {
                        TextField("Add athlete by name", text: $searchName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: searchName) { _ in searchForName() }

                        if !searchResults.isEmpty {
                            ForEach(searchResults) { result in
                                HStack {
                                    Text(result.name)
                                    Spacer()
                                    Button("Add") { addFoundAthlete(result) }
                                }
                            }
                        } else if !searchName.isEmpty {
                            Text(errorMessage ?? "No athletes found")
                                .foregroundColor(.red)
                        } else if !suggestedAthletes.isEmpty {
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
                    }
                    .padding(.horizontal)
                }
                .onAppear {
                    loadAthletes()
                    fetchSuggestedAthletes()
                }
            }
            .navigationTitle("Coach Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { authViewModel.signOut() }) {
                        Text("Sign Out")
                    }
                }
            }
        }
    }

    // MARK: - Athlete Loading
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
                    if !athletes.isEmpty {
                        loadMetrics(for: athletes[selectedIndex])
                    }
                }
            }
    }

    private func loadMetrics(for athlete: AthleteRef) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        let db = Firestore.firestore()
        db.collection("users")
            .document(athlete.uid)
            .collection("days")
            .document(today)
            .getDocument { snapshot, _ in
                if let data = snapshot?.data() {
                    let training = (data["trainingScore"] as? Int) ?? Int((data["trainingScore"] as? Double) ?? 0)
                    let recovery = (data["recoveryScore"] as? Int) ?? Int((data["recoveryScore"] as? Double) ?? 0)
                    metrics = AthleteMetrics(trainingScore: training, recoveryScore: recovery)
                } else {
                    metrics = nil
                }
            }
    }

    // MARK: - Athlete Search & Add
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
                                id: $0.data()["profileId"] as? String ?? "",
                                uid: $0.reference.parent.parent?.documentID ?? "",
                                name: $0.data()["name"] as? String ?? "Athlete"
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
                            id: $0.data()["profileId"] as? String ?? "",
                            uid: $0.reference.parent.parent?.documentID ?? "",
                            name: $0.data()["name"] as? String ?? "Athlete"
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
}

// Simple visual card used for metric display
struct MetricCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
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
