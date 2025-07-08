import SwiftUI
import FirebaseFirestore

struct AthleteRef: Identifiable {
    var id: String
    var name: String
}

struct CoachDashboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var searchEmail = ""
    @State private var foundAthlete: AthleteRef?
    @State private var errorMessage: String?
    @State private var athletes: [AthleteRef] = []

    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                HStack {
                    TextField("Athlete email", text: $searchEmail)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    Button("Find") {
                        errorMessage = nil
                        foundAthlete = nil
                        findAthlete()
                    }
                    .disabled(searchEmail.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding()

                // Search result / error
                if let athlete = foundAthlete {
                    Button("Add \(athlete.name)") {
                        addFoundAthlete(athlete)
                        // clear the search
                        searchEmail = ""
                        foundAthlete = nil
                    }
                    .padding(.bottom)
                } else if let message = errorMessage {
                    Text(message)
                        .foregroundColor(.red)
                        .padding(.bottom)
                }

                // Existing athletes list
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

private func findAthlete() {
    let db = Firestore.firestore()
    db.collection("users")
        .whereField("email", isEqualTo: searchEmail)
        .whereField("role", isEqualTo: "Athlete")
        .getDocuments { snapshot, error in
            if let error = error {
                // handle Firestore error
                errorMessage = error.localizedDescription
                foundAthlete = nil
            } else if let doc = snapshot?.documents.first {
                foundAthlete = AthleteRef(
                    id: doc.documentID,
                    name: doc.data()["name"] as? String ?? "Athlete"
                )
                errorMessage = nil
            } else {
                // no matching athlete
                foundAthlete = nil
                errorMessage = "Athlete not found"
            }
        }
}

  private func addFoundAthlete(_ athlete: AthleteRef) {
    let db = Firestore.firestore()
    let coachId = authViewModel.userProfile.uid
    guard !coachId.isEmpty else { return }

    db.collection("coaches")
        .document(coachId)
        .collection("athletes")
        .document(athlete.id)
        .setData(["name": athlete.name]) { error in
            if let error = error {
                // Optionally handle write error
                errorMessage = error.localizedDescription
            }
            // Reload the list and clear the search UI
            loadAthletes()
            foundAthlete = nil
            searchEmail = ""
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
