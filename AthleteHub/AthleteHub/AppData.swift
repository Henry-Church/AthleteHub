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
    func resetDailyNutritionIfNeeded() {
        let last = UserDefaults.standard.object(forKey: lastResetKey) as? Date ?? .distantPast
        if !Calendar.current.isDateInToday(last) {
            caloriesConsumed = "0"
            proteinIntake = "0"
            carbsIntake = "0"
            fatIntake = "0"
            waterIntake = "0"
            fiberIntake = "0"
            UserDefaults.standard.set(Date(), forKey: lastResetKey)
        }
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
    func loadFromFirestore() {
        guard let currentUser = Auth.auth().currentUser else { return }
        self.uid = currentUser.uid
        self.email = currentUser.email ?? ""
        
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let data = snapshot?.data() {
                DispatchQueue.main.async {
                    self.name = data["name"] as? String ?? self.name
                    self.role = data["role"] as? String ?? self.role
                    self.phone = data["phone"] as? String ?? self.phone
                    self.birthDate = data["birthDate"] as? String ?? self.birthDate
                    self.sex = data["sex"] as? String ?? self.sex
                    self.height = data["height"] as? Double ?? self.height
                    self.weight = data["weight"] as? Double ?? self.weight
                    self.age = data["age"] as? Int ?? self.age
                    
                    self.sleepDuration = data["sleepDuration"] as? String
                    self.sleepDurationStatus = data["sleepDurationStatus"] as? String
                    self.sleepDurationDescription = data["sleepDurationDescription"] as? String
                    self.sleepQuality = data["sleepQuality"] as? String
                    self.sleepQualityStatus = data["sleepQualityStatus"] as? String
                    self.sleepQualityDescription = data["sleepQualityDescription"] as? String
                    self.stressLevel = data["stressLevel"] as? String
                    self.stressLevelStatus = data["stressLevelStatus"] as? String
                    self.stressLevelDescription = data["stressLevelDescription"] as? String
                    self.restingHeartRate = data["restingHeartRate"] as? String
                    self.restingHeartRateStatus = data["restingHeartRateStatus"] as? String
                    self.restingHeartRateDescription = data["restingHeartRateDescription"] as? String
                    self.hrv = data["hrv"] as? String
                    self.hrvStatus = data["hrvStatus"] as? String
                    self.hrvDescription = data["hrvDescription"] as? String
                    self.overallRecoveryScore = data["overallRecoveryScore"] as? String
                    self.overallRecoveryStatus = data["overallRecoveryStatus"] as? String
                    self.overallRecoveryDescription = data["overallRecoveryDescription"] as? String
                    self.recoveryTrendsAvailable = data["recoveryTrendsAvailable"] as? Bool ?? false
                    self.sleepPhaseAnalysisAvailable = data["sleepPhaseAnalysisAvailable"] as? Bool ?? false
                    
                    self.caloriesConsumed = data["caloriesConsumed"] as? String
                    self.caloriesGoal = data["caloriesGoal"] as? String
                    self.caloriesStatus = data["caloriesStatus"] as? String
                    self.caloriesDescription = data["caloriesDescription"] as? String
                    
                    self.proteinIntake = data["proteinIntake"] as? String
                    self.proteinGoal = data["proteinGoal"] as? String
                    self.proteinStatus = data["proteinStatus"] as? String
                    self.proteinDescription = data["proteinDescription"] as? String
                    
                    self.carbsIntake = data["carbsIntake"] as? String
                    self.carbsGoal = data["carbsGoal"] as? String
                    self.carbsStatus = data["carbsStatus"] as? String
                    self.carbsDescription = data["carbsDescription"] as? String
                    
                    self.fatIntake = data["fatIntake"] as? String
                    self.fatGoal = data["fatGoal"] as? String
                    self.fatStatus = data["fatStatus"] as? String
                    self.fatDescription = data["fatDescription"] as? String
                    
                    self.waterIntake = data["waterIntake"] as? String
                    self.waterGoal = data["waterGoal"] as? String
                    self.waterStatus = data["waterStatus"] as? String
                    self.waterDescription = data["waterDescription"] as? String

                    self.resetDailyNutritionIfNeeded()
                }
            }
        }
    }
}
