import SwiftUI
import FirebaseFirestore

class CoachSelection: ObservableObject {
    @Published var athletes: [AthleteRef] = []
    @Published var selectedIndex: Int = 0 {
        didSet { loadSelectedAthlete() }
    }
    @Published var athleteProfile = UserProfile()

    func loadAthletes(for coachId: String) {
        guard !coachId.isEmpty else { return }
        Firestore.firestore()
            .collection("coaches").document(coachId)
            .collection("athletes")
            .getDocuments { snapshot, _ in
                if let docs = snapshot?.documents {
                    DispatchQueue.main.async {
                        self.athletes = docs.map {
                            AthleteRef(
                                id: $0.documentID,
                                uid: $0.data()["uid"] as? String ?? "",
                                name: $0.data()["name"] as? String ?? "Athlete"
                            )
                        }
                        if !self.athletes.isEmpty {
                            self.selectedIndex = min(self.selectedIndex, self.athletes.count - 1)
                            self.loadSelectedAthlete()
                        }
                    }
                }
            }
    }

    func loadSelectedAthlete() {
        guard selectedIndex < athletes.count else { return }
        athleteProfile.loadFromFirestore(for: athletes[selectedIndex].uid)
    }
}
