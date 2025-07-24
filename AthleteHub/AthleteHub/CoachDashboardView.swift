import SwiftUI
import FirebaseFirestore
import Charts

struct AthleteRef: Identifiable {
    /// Readable identifier for the athlete, typically their profile name.
    var id: String
    /// Firebase UID for loading the full profile.
    var uid: String
    var name: String
}

/// Comprehensive metrics summary for a single athlete.
struct AthleteMetrics {
    var trainingScore: Int
    var recoveryScore: Int
    var nutritionScore: Int
    var overallScore: Int
    var weeklyTrend: [Int]
    var lastWorkout: String?
    var riskLevel: RiskLevel
    
    enum RiskLevel {
        case low, medium, high
        
        var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .orange
            case .high: return .red
            }
        }
        
        var text: String {
            switch self {
            case .low: return "Low Risk"
            case .medium: return "Monitor"
            case .high: return "High Risk"
            }
        }
    }
}

struct CoachDashboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var coachSelection: CoachSelection
    @State var athleteMetrics: [String: AthleteMetrics] = [:]
    @State var selectedView: DashboardView = .overview
    @State var searchName = ""
    @State var searchResults: [AthleteRef] = []
    @State var suggestedAthletes: [AthleteRef] = []
    @State var errorMessage: String?
    @State var showingAthleteDetail = false

    @Environment(\.colorScheme) var colorScheme
    
    enum DashboardView: String, CaseIterable, Hashable {
        case overview = "Overview"
        case performance = "Performance"
        case alerts = "Alerts"
    }
    
    var cardBackground: Color {
        colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 24) {
                    // Header with Coach Info
                    coachHeaderSection
                    
                    // Dashboard View Selector
                    dashboardViewSelector
                    
                    // Main Content based on selected view
                    switch selectedView {
                    case .overview:
                        overviewContent
                    case .performance:
                        performanceContent
                    case .alerts:
                        alertsContent
                    }
                    
                    // Add Athlete Section
                    addAthleteSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(colorScheme == .dark ? Color.black : Color(.systemGroupedBackground))
            .navigationTitle("Coach Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { authViewModel.signOut() }) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .onAppear {
                loadAthletes()
                fetchSuggestedAthletes()
                loadAllAthleteMetrics()
            }
        }
    }

    // MARK: - Athlete Loading
    private func loadAthletes() {
        let coachId = authViewModel.userProfile.uid
        coachSelection.loadAthletes(for: coachId)
        loadAllAthleteMetrics()
    }

    func loadMetrics(for athlete: AthleteRef) {
        let db = Firestore.firestore()
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: today)

        db.collection("users")
            .document("roles")
            .collection("athletes")
            .document(athlete.uid)
            .collection("days")
            .document(dateString)
            .getDocument { snapshot, _ in
                if let data = snapshot?.data() {
                    let training = data["trainingScore"] as? Int ?? 0
                    let recovery = data["recoveryScore"] as? Int ?? 0
                    let nutrition = data["nutritionScore"] as? Int ?? 50 // Default value
                    let overall = (training + recovery + nutrition) / 3
                    
                    // Generate mock weekly trend data
                    let weeklyTrend = (0..<7).map { _ in Int.random(in: 40...90) }
                    
                    // Determine risk level based on scores
                    let riskLevel: AthleteMetrics.RiskLevel
                    if overall >= 70 && recovery >= 60 {
                        riskLevel = .low
                    } else if overall >= 50 || recovery >= 40 {
                        riskLevel = .medium
                    } else {
                        riskLevel = .high
                    }
                    
                    let metrics = AthleteMetrics(
                        trainingScore: training,
                        recoveryScore: recovery,
                        nutritionScore: nutrition,
                        overallScore: overall,
                        weeklyTrend: weeklyTrend,
                        lastWorkout: "Running - 5km",
                        riskLevel: riskLevel
                    )
                    
                    DispatchQueue.main.async {
                        self.athleteMetrics[athlete.uid] = metrics
                    }
                } else {
                    // Create default metrics for new athletes
                    let defaultMetrics = AthleteMetrics(
                        trainingScore: 0,
                        recoveryScore: 0,
                        nutritionScore: 0,
                        overallScore: 0,
                        weeklyTrend: Array(repeating: 0, count: 7),
                        lastWorkout: nil,
                        riskLevel: .medium
                    )
                    
                    DispatchQueue.main.async {
                        self.athleteMetrics[athlete.uid] = defaultMetrics
                    }
                }
            }
    }

    // MARK: - Athlete Search & Add
     func searchForName() {
        let db = Firestore.firestore()
        let trimmed = searchName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            searchResults = []
            return
        }
        db.collection("users")
            .document("roles")
            .collection("athletes")
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
                                uid: $0.documentID,
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
        db.collection("users")
            .document("roles")
            .collection("athletes")
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
                            uid: $0.documentID,
                            name: $0.data()["name"] as? String ?? "Athlete"
                        )
                    }
                }
            }
    }

    func addFoundAthlete(_ athlete: AthleteRef) {
        let db = Firestore.firestore()
        let coachId = authViewModel.userProfile.uid
        guard !coachId.isEmpty else { return }
        db.collection("users")
            .document("roles")
            .collection("coaches").document(coachId)
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

struct AthleteDetailView: View {
    let athleteId: String
    @StateObject private var profile = UserProfile()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
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
            .navigationTitle(profile.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .environmentObject(profile)
        .onAppear {
            profile.loadFromFirestore(for: athleteId)
        }
    }
}
