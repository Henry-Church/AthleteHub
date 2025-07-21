//
//  AppData.swift
//  AthleteHub
//
//  Created by Henry Church on 28/06/2025.
//

import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

class UserProfile: ObservableObject {
    @Published var uid: String = ""
    /// Identifier based on the user's display name. This mirrors the name field
    /// so athletes can be referenced directly by a readable ID.
    @Published var profileId: String = ""
    @Published var name: String = "Athlete"
    @Published var role: String = "Athlete"
    @Published var profileImage: UIImage? = nil
    
    // Personal Info
    @Published var email: String = ""
    @Published var phone: String = ""
    @Published var birthDate: String = ""
    @Published var sex: String = ""
    @Published var height: Double = 0
    @Published var weight: Double = 0
    @Published var age: Int = 0
    
    var bmi: Double {
        if height > 0 {
            return weight / ((height / 100) * (height / 100))
        }
        return 0.0
    }
    
    // Recovery Metrics
    @Published var sleepDuration: String? = nil
    @Published var sleepDurationStatus: String? = nil
    @Published var sleepDurationDescription: String? = nil
    
    @Published var sleepQuality: String? = nil
    @Published var sleepQualityStatus: String? = nil
    @Published var sleepQualityDescription: String? = nil
    
    @Published var stressLevel: String? = nil
    @Published var stressLevelStatus: String? = nil
    @Published var stressLevelDescription: String? = nil
    
    @Published var restingHeartRate: String? = nil
    @Published var restingHeartRateStatus: String? = nil
    @Published var restingHeartRateDescription: String? = nil
    
    @Published var hrv: String? = nil
    @Published var hrvStatus: String? = nil
    @Published var hrvDescription: String? = nil
    
    @Published var overallRecoveryScore: String? = nil
    @Published var overallRecoveryStatus: String? = nil
    @Published var overallRecoveryDescription: String? = nil
    
    @Published var recoveryTrendsAvailable: Bool = false
    @Published var sleepPhaseAnalysisAvailable: Bool = false
    
    // Nutrition Metrics
    @Published var caloriesConsumed: String? {
        didSet { recalcCaloriesPercentage() }
    }
    @Published var caloriesGoal: String? {
        didSet { recalcCaloriesPercentage() }
    }
    @Published var caloriesPercentage: String?
    @Published var caloriesStatus: String?
    @Published var caloriesDescription: String?
    
    @Published var proteinIntake: String? {
        didSet { recalcProteinPercentage() }
    }
    @Published var proteinGoal: String? {
        didSet { recalcProteinPercentage() }
    }
    @Published var proteinPercentage: String?
    @Published var proteinStatus: String?
    @Published var proteinDescription: String?
    
    @Published var carbsIntake: String? {
        didSet { recalcCarbsPercentage() }
    }
    @Published var carbsGoal: String? {
        didSet { recalcCarbsPercentage() }
    }
    @Published var carbsPercentage: String?
    @Published var carbsStatus: String?
    @Published var carbsDescription: String?
    
    @Published var fatIntake: String? {
        didSet { recalcFatPercentage() }
    }
    @Published var fatGoal: String? {
        didSet { recalcFatPercentage() }
    }
    @Published var fatPercentage: String?
    @Published var fatStatus: String?
    @Published var fatDescription: String?
    
    @Published var waterIntake: String? {
        didSet { recalcWaterPercentage() }
    }
    @Published var waterGoal: String? {
        didSet { recalcWaterPercentage() }
    }
    @Published var waterPercentage: String?
    @Published var waterStatus: String?
    @Published var waterDescription: String?
    
    @Published var fiberIntake: String? {
        didSet { recalcFiberPercentage() }
    }
    @Published var fiberGoal: String? {
        didSet { recalcFiberPercentage() }
    }
    @Published var fiberPercentage: String?
    @Published var fiberStatus: String?
    @Published var fiberDescription: String?
    
    @Published var macronutrientBreakdownAvailable: Bool = false
    @Published var dailyIntakeTrendsAvailable: Bool = false
    
    // Logs
    @Published var trainingLog: [String] = []
    @Published var meals: [String] = []
    @Published var recoveryActivities: [String] = []

    private let lastResetKey = "lastNutritionResetDate"

    /// Reset daily nutrition fields if the stored date is not today.
    ///
    /// This ensures metrics such as calories or water intake start at zero each
    /// day while persistent attributes like height, weight or age remain
    /// unchanged. The logged meals array is also cleared so that meals do not
    /// carry over into the following day.
    func resetDailyNutritionIfNeeded() {
        let last = UserDefaults.standard.object(forKey: lastResetKey) as? Date ?? .distantPast
        guard !Calendar.current.isDateInToday(last) else { return }

        caloriesConsumed = "0"
        proteinIntake = "0"
        carbsIntake = "0"
        fatIntake = "0"
        waterIntake = "0"
        fiberIntake = "0"
        meals.removeAll()

        UserDefaults.standard.set(Date(), forKey: lastResetKey)
    }
    
    // MARK: - Percentage Calculations
    private func recalcCaloriesPercentage() {
        let consumed = Double(caloriesConsumed ?? "") ?? 0
        let goal     = Double(caloriesGoal     ?? "") ?? 1
        let pct      = Int((consumed / goal) * 100)
        caloriesPercentage = "\(pct)%"
    }
    
    private func recalcProteinPercentage() {
        let consumed = Double(proteinIntake ?? "") ?? 0
        let goal     = Double(proteinGoal   ?? "") ?? 1
        let pct      = Int((consumed / goal) * 100)
        proteinPercentage = "\(pct)%"
    }
    
    private func recalcCarbsPercentage() {
        let consumed = Double(carbsIntake ?? "") ?? 0
        let goal     = Double(carbsGoal   ?? "") ?? 1
        let pct      = Int((consumed / goal) * 100)
        carbsPercentage = "\(pct)%"
    }
    
    private func recalcFatPercentage() {
        let consumed = Double(fatIntake ?? "") ?? 0
        let goal     = Double(fatGoal   ?? "") ?? 1
        let pct      = Int((consumed / goal) * 100)
        fatPercentage = "\(pct)%"
    }
    
    private func recalcWaterPercentage() {
        let consumed = Double(waterIntake ?? "") ?? 0
        let goal     = Double(waterGoal   ?? "") ?? 1
        let pct      = Int((consumed / goal) * 100)
        waterPercentage = "\(pct)%"
    }
    
    private func recalcFiberPercentage() {
        let consumed = Double(fiberIntake ?? "") ?? 0
        let goal     = Double(fiberGoal   ?? "") ?? 1
        let pct      = Int((consumed / goal) * 100)
        fiberPercentage = "\(pct)%"
    }
    
    // MARK: - Firestore Integration
    /// Load persistent profile data and nutrition goals from Firestore.
    /// - Parameter uid: Optional UID to load a different user's profile. If nil,
    ///   the currently authenticated user's data is loaded.
    func loadFromFirestore(for uid: String? = nil) {
        if let override = uid {
            self.uid = override
        } else if let currentUser = Auth.auth().currentUser {
            self.uid = currentUser.uid
            self.email = currentUser.email ?? ""
        }
        guard !self.uid.isEmpty else { return }

        let db = Firestore.firestore()

        var loaded = false
        func load(from rolePath: String) {
            let ref = db.collection("users")
                .collection(rolePath)
                .document(self.uid)
                .collection("profileData")
            ref.document("info").getDocument { snapshot, _ in
                if let data = snapshot?.data(), !loaded {
                    DispatchQueue.main.async {
                        let first = data["firstName"] as? String ?? ""
                        let last = data["lastName"] as? String ?? ""
                        let combined = "\(first) \(last)".trimmingCharacters(in: .whitespaces)
                        self.name = combined.isEmpty ? (data["name"] as? String ?? self.name) : combined
                        self.profileId = data["profileId"] as? String ?? self.name
                        self.role = rolePath == "coaches" ? "Coach" : "Athlete"
                        self.phone = data["phone"] as? String ?? self.phone
                        self.birthDate = data["birthDate"] as? String ?? self.birthDate
                        self.sex = data["sex"] as? String ?? self.sex
                        self.height = data["height"] as? Double ?? self.height
                        self.weight = data["weight"] as? Double ?? self.weight
                        self.age = data["age"] as? Int ?? self.age
                    }
                    loaded = true
                    ref.document("goals").getDocument { snap, _ in
                        if let g = snap?.data() {
                            DispatchQueue.main.async {
                                self.caloriesGoal = g["caloriesGoal"] as? String ?? self.caloriesGoal
                                self.proteinGoal = g["proteinGoal"] as? String ?? self.proteinGoal
                                self.carbsGoal = g["carbsGoal"] as? String ?? self.carbsGoal
                                self.fatGoal = g["fatGoal"] as? String ?? self.fatGoal
                                self.waterGoal = g["waterGoal"] as? String ?? self.waterGoal
                                self.fiberGoal = g["fiberGoal"] as? String ?? self.fiberGoal
                            }
                        }
                    }
                }
            }
        }

        load(from: "athletes")
        load(from: "coaches")

        resetDailyNutritionIfNeeded()
    }

    /// Persist core profile fields to Firestore under `profile/info`.
    func saveToFirestore() {
        guard !uid.isEmpty else { return }
        let data: [String: Any] = [
            "name": name,
            "profileId": profileId,
            "role": role,
            "phone": phone,
            "birthDate": birthDate,
            "sex": sex,
            "height": height,
            "weight": weight,
            "age": age
        ]

        let rolePath = role.lowercased() == "coach" ? "coaches" : "athletes"

        let parts = name.split(separator: " ", maxSplits: 1)
        let first = String(parts.first ?? "")
        let last = parts.count > 1 ? String(parts.last ?? "") : ""

        var fullData = data
        fullData["firstName"] = first
        fullData["lastName"] = last

        Firestore.firestore()
            .collection("users")
            .collection(rolePath)
            .document(uid)
            .collection("profileData")
            .document("info")
            .setData(fullData, merge: true)
    }

    /// Save all nutrition goal values under `profile/goals`.
    func saveGoalsToFirestore() {
        guard !uid.isEmpty else { return }
        let data: [String: Any] = [
            "caloriesGoal": caloriesGoal ?? "",
            "proteinGoal": proteinGoal ?? "",
            "carbsGoal": carbsGoal ?? "",
            "fatGoal": fatGoal ?? "",
            "waterGoal": waterGoal ?? "",
            "fiberGoal": fiberGoal ?? ""
        ]

        let rolePath = role.lowercased() == "coach" ? "coaches" : "athletes"
        Firestore.firestore()
            .collection("users")
            .collection(rolePath)
            .document(uid)
            .collection("profileData")
            .document("goals")
            .setData(data, merge: true)
    }
}
