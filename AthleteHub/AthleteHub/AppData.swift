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
    @Published var caloriesConsumed: String? = nil
    @Published var caloriesGoal: String? = nil
    @Published var caloriesPercentage: String? = nil
    @Published var caloriesStatus: String? = nil
    @Published var caloriesDescription: String? = nil
    
    @Published var proteinIntake: String? = nil
    @Published var proteinGoal: String? = nil
    @Published var proteinPercentage: String? = nil
    @Published var proteinStatus: String? = nil
    @Published var proteinDescription: String? = nil
    
    @Published var carbsIntake: String? = nil
    @Published var carbsGoal: String? = nil
    @Published var carbsPercentage: String? = nil
    @Published var carbsStatus: String? = nil
    @Published var carbsDescription: String? = nil
    
    @Published var fatIntake: String? = nil
    @Published var fatGoal: String? = nil
    @Published var fatPercentage: String? = nil
    @Published var fatStatus: String? = nil
    @Published var fatDescription: String? = nil
    
    @Published var waterIntake: String? = nil
    @Published var waterGoal: String? = nil
    @Published var waterPercentage: String? = nil
    @Published var waterStatus: String? = nil
    @Published var waterDescription: String? = nil
    
    @Published var fiberIntake: String? = nil
    @Published var fiberGoal: String? = nil
    @Published var fiberPercentage: String? = nil
    @Published var fiberStatus: String? = nil
    @Published var fiberDescription: String? = nil
    
    @Published var macronutrientBreakdownAvailable: Bool = false
    @Published var dailyIntakeTrendsAvailable: Bool = false
    
    // Logs
    @Published var trainingLog: [String] = []
    @Published var meals: [String] = []
    @Published var recoveryActivities: [String] = []
    
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
                    self.caloriesPercentage = data["caloriesPercentage"] as? String
                    self.caloriesStatus = data["caloriesStatus"] as? String
                    self.caloriesDescription = data["caloriesDescription"] as? String
                    self.proteinIntake = data["proteinIntake"] as? String
                    self.proteinGoal = data["proteinGoal"] as? String
                    self.proteinPercentage = data["proteinPercentage"] as? String
                    self.proteinStatus = data["proteinStatus"] as? String
                    self.proteinDescription = data["proteinDescription"] as? String
                    self.carbsIntake = data["carbsIntake"] as? String
                    self.carbsGoal = data["carbsGoal"] as? String
                    self.carbsPercentage = data["carbsPercentage"] as? String
                    self.carbsStatus = data["carbsStatus"] as? String
                    self.carbsDescription = data["carbsDescription"] as? String
                    self.fatIntake = data["fatIntake"] as? String
                    self.fatGoal = data["fatGoal"] as? String
                    self.fatPercentage = data["fatPercentage"] as? String
                    self.fatStatus = data["fatStatus"] as? String
                    self.fatDescription = data["fatDescription"] as? String
                    self.waterIntake = data["waterIntake"] as? String
                    self.waterGoal = data["waterGoal"] as? String
                    self.waterPercentage = data["waterPercentage"] as? String
                    self.waterStatus = data["waterStatus"] as? String
                    self.waterDescription = data["waterDescription"] as? String
                    self.fiberIntake = data["fiberIntake"] as? String
                    self.fiberGoal = data["fiberGoal"] as? String
                    self.fiberPercentage = data["fiberPercentage"] as? String
                    self.fiberStatus = data["fiberStatus"] as? String
                    self.fiberDescription = data["fiberDescription"] as? String
                    self.macronutrientBreakdownAvailable = data["macronutrientBreakdownAvailable"] as? Bool ?? false
                    self.dailyIntakeTrendsAvailable = data["dailyIntakeTrendsAvailable"] as? Bool ?? false
                    self.trainingLog = data["trainingLog"] as? [String] ?? []
                    self.meals = data["meals"] as? [String] ?? []
                    self.recoveryActivities = data["recoveryActivities"] as? [String] ?? []
                }
            }
        }
    }
    
    func saveToFirestore() {
        guard !uid.isEmpty else { return }
        let db = Firestore.firestore()
        db.collection("users").document(uid).setData([
            "name": name,
            "role": role,
            "phone": phone,
            "birthDate": birthDate,
            "sex": sex,
            "height": height,
            "weight": weight,
            "age": age,
            "sleepDuration": sleepDuration ?? "",
            "sleepDurationStatus": sleepDurationStatus ?? "",
            "sleepDurationDescription": sleepDurationDescription ?? "",
            "sleepQuality": sleepQuality ?? "",
            "sleepQualityStatus": sleepQualityStatus ?? "",
            "sleepQualityDescription": sleepQualityDescription ?? "",
            "stressLevel": stressLevel ?? "",
            "stressLevelStatus": stressLevelStatus ?? "",
            "stressLevelDescription": stressLevelDescription ?? "",
            "restingHeartRate": restingHeartRate ?? "",
            "restingHeartRateStatus": restingHeartRateStatus ?? "",
            "restingHeartRateDescription": restingHeartRateDescription ?? "",
            "hrv": hrv ?? "",
            "hrvStatus": hrvStatus ?? "",
            "hrvDescription": hrvDescription ?? "",
            "overallRecoveryScore": overallRecoveryScore ?? "",
            "overallRecoveryStatus": overallRecoveryStatus ?? "",
            "overallRecoveryDescription": overallRecoveryDescription ?? "",
            "recoveryTrendsAvailable": recoveryTrendsAvailable,
            "sleepPhaseAnalysisAvailable": sleepPhaseAnalysisAvailable,
            "caloriesConsumed": caloriesConsumed ?? "",
            "caloriesGoal": caloriesGoal ?? "",
            "caloriesPercentage": caloriesPercentage ?? "",
            "caloriesStatus": caloriesStatus ?? "",
            "caloriesDescription": caloriesDescription ?? "",
            "proteinIntake": proteinIntake ?? "",
            "proteinGoal": proteinGoal ?? "",
            "proteinPercentage": proteinPercentage ?? "",
            "proteinStatus": proteinStatus ?? "",
            "proteinDescription": proteinDescription ?? "",
            "carbsIntake": carbsIntake ?? "",
            "carbsGoal": carbsGoal ?? "",
            "carbsPercentage": carbsPercentage ?? "",
            "carbsStatus": carbsStatus ?? "",
            "carbsDescription": carbsDescription ?? "",
            "fatIntake": fatIntake ?? "",
            "fatGoal": fatGoal ?? "",
            "fatPercentage": fatPercentage ?? "",
            "fatStatus": fatStatus ?? "",
            "fatDescription": fatDescription ?? "",
            "waterIntake": waterIntake ?? "",
            "waterGoal": waterGoal ?? "",
            "waterPercentage": waterPercentage ?? "",
            "waterStatus": waterStatus ?? "",
            "waterDescription": waterDescription ?? "",
            "fiberIntake": fiberIntake ?? "",
            "fiberGoal": fiberGoal ?? "",
            "fiberPercentage": fiberPercentage ?? "",
            "fiberStatus": fiberStatus ?? "",
            "fiberDescription": fiberDescription ?? "",
            "macronutrientBreakdownAvailable": macronutrientBreakdownAvailable,
            "dailyIntakeTrendsAvailable": dailyIntakeTrendsAvailable,
            "trainingLog": trainingLog,
            "meals": meals,
            "recoveryActivities": recoveryActivities
        ], merge: true) { error in
            if let error = error {
                print("Error saving user data: \(error.localizedDescription)")
            } else {
                print("Successfully saved user data!")
            }
        }
    }
}
