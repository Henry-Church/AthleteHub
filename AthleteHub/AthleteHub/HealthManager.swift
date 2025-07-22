import Foundation
import HealthKit
import FirebaseFirestore
import FirebaseAuth

struct TrainingScore: Identifiable, Codable {
    var id: String = UUID().uuidString
    var date: Date
    var score: Int
}

struct SleepStage: Identifiable {
    var id = UUID()
    var stage: String
    var startDate: Date
    var endDate: Date

    var duration: Double {
        return endDate.timeIntervalSince(startDate) / 60 // duration in minutes
    }
}


class HealthManager: ObservableObject {
    let healthStore = HKHealthStore()
    @Published var isAuthorized = false
    @Published var isConnected = UserDefaults.standard.bool(forKey: "healthConnected")

    @Published var activeCalories: Double?
    @Published var totalCalories: Double?
    @Published var weeklyDistance: Double?
    @Published var weeklyHours: Double?
    @Published var exerciseMinutes: Double?
    @Published var distance: Double?
    @Published var restingHeartRate: Double?
    @Published var hrv: Double?
    @Published var hrvWeek: [Double] = []
    @Published var restingHRWeek: [Double] = []
    @Published var bloodOxygen: Double?
    @Published var bloodOxygenWeek: [Double] = []
    @Published var sleepDuration: Double?
    @Published var sleepQuality: String = "Unknown"
    @Published var sleepStages: [SleepStage] = []
    @Published var steps: Double?
    @Published var vo2Max: Double?
    @Published var bodyMass: Double?
    @Published var height: Double?
    @Published var waterIntake: Double?
    @Published var caloriesConsumed: Double?
    @Published var proteinIntake: Double?
    @Published var carbsIntake: Double?
    @Published var fatIntake: Double?
    @Published var fiberIntake: Double?
    @Published var dailyGoals: [String: Double] = [:]
    @Published var trainingScores: [TrainingScore] = []
    /// Scores for the last seven days including today, sorted by date
    var lastSevenScores: [TrainingScore] {
        let start = Calendar.current.date(byAdding: .day, value: -6, to: Date()) ?? Date()
        return trainingScores
            .filter { $0.date >= Calendar.current.startOfDay(for: start) }
            .sorted { $0.date < $1.date }
    }
  
    /// Last seven days including today, ensuring every day has a value
    var lastSevenScoresFilled: [TrainingScore] {
        let calendar = Calendar.current
        return (0..<7).map { offset in
            let day = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -6 + offset, to: Date())!)
            let score = trainingScores.first { calendar.isDate($0.date, inSameDayAs: day) }?.score ?? 0
            return TrainingScore(date: day, score: score)
        }
    }
  
    @Published var recentWorkouts: [HKWorkout] = []
    @Published var recoveryScore: Double? = nil
    @Published var stressLevel: Double? = nil
    @Published var sleepQualityScore: Int? = nil
    @Published var rawSleepSamples: [HKCategorySample] = []



    private let db = Firestore.firestore()
    private var timer: Timer?
    private var resetTimer: Timer?
    
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd" // or use "yyyy-MM-dd HH:mm" if you want timestamp granularity
        return formatter
    }()
    
    var userId: String {
        Auth.auth().currentUser?.uid ?? "unknown_user"
    }


    init() {
        loadGoals()
        fetchTrainingScores()
        if isConnected {
            startAutoRefresh()
        }
        scheduleDailyReset()
    }

    func calculateOverallTrainingScore() -> Double {
        let calorieScore = min((totalCalories ?? 0) / max(dailyGoals["Calories"] ?? 1, 1), 1) * 25
        let stepScore = min((steps ?? 0) / max(dailyGoals["Steps"] ?? 1, 1), 1) * 25
        let distanceScore = min((distance ?? 0) / max(dailyGoals["Distance"] ?? 1, 1), 1) * 25
        let minutesScore = min((exerciseMinutes ?? 0) / max(dailyGoals["ExerciseMinutes"] ?? 1, 1), 1) * 25

        return calorieScore + stepScore + distanceScore + minutesScore
    }

    /// Calculates a recovery score from sleep, HRV and stress metrics
    /// - Returns: score as 0-100
    func calculateOverallRecoveryScore() -> Double {
        let defaults = UserDefaults.standard
        let sleepGoal = defaults.double(forKey: "sleepGoal")
        let hrvGoal = defaults.double(forKey: "hrvGoal")
        let restingGoal = defaults.double(forKey: "restingHRGoal")

        let sleepQuality = Double(sleepQualityScore ?? 0)
        let sleepDurationScore = sleepGoal > 0 ? min((sleepDuration ?? 0) / sleepGoal, 1) * 100 : 0
        let hrvScore = hrvGoal > 0 ? min((hrv ?? 0) / hrvGoal, 1) * 100 : 0

        var restingScore: Double = 0
        if restingGoal > 0, let resting = restingHeartRate {
            let ratio = resting / restingGoal
            restingScore = max(0, min(2 - ratio, 1)) * 100
        }

        let stressScore: Double
        if let stress = stressLevel {
            stressScore = max(0, 1 - (stress / 30)) * 100
        } else {
            stressScore = 0
        }

        let scores = [sleepQuality, sleepDurationScore, hrvScore, restingScore, stressScore]

        guard scores.contains(where: { $0 > 0 }) else {
            recoveryScore = 0
            return 0
        }

        let overall = scores.reduce(0, +) / Double(scores.count)
        recoveryScore = overall
        return overall
    }

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        let typesToRead: Set = [
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .basalEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!,
            HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .vo2Max)!,
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .height)!,
            HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!,
            HKObjectType.quantityType(forIdentifier: .dietaryWater)!,
            HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed)!,
            HKObjectType.quantityType(forIdentifier: .dietaryProtein)!,
            HKObjectType.quantityType(forIdentifier: .dietaryCarbohydrates)!,
            HKObjectType.quantityType(forIdentifier: .dietaryFatTotal)!,
            HKObjectType.quantityType(forIdentifier: .dietaryFiber)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.workoutType() // Needed for HKWorkout (includes totalDistance)
        ]

        healthStore.requestAuthorization(toShare: [], read: typesToRead) { success, _ in
            DispatchQueue.main.async {
                self.isAuthorized = success
                self.isConnected = success
                UserDefaults.standard.set(success, forKey: "healthConnected")
                if success {
                    self.startAutoRefresh()
                }
                completion(success)
            }
        }
    }


    func startAutoRefresh() {
        fetchAllData()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { _ in
            self.fetchAllData()
        }
    }

    func scheduleDailyReset() {
        resetTimer?.invalidate()
        let now = Date()
        let calendar = Calendar.current
        if let nextMidnight = calendar.nextDate(after: now, matching: DateComponents(hour: 0, minute: 0, second: 0), matchingPolicy: .nextTime) {
            let interval = nextMidnight.timeIntervalSince(now)
            resetTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
                guard let self = self else { return }
                if let uid = Auth.auth().currentUser?.uid {
                    self.saveDailyMetricsToFirestore(userId: uid)
                }
                self.resetDailyMetrics()
                self.scheduleDailyReset()
            }
        }
    }

    private func resetDailyMetrics() {
        activeCalories = nil
        totalCalories = nil
        exerciseMinutes = nil
        distance = nil
        steps = nil
        waterIntake = nil
        caloriesConsumed = nil
        proteinIntake = nil
        carbsIntake = nil
        fatIntake = nil
        fiberIntake = nil
    }

    func fetchAllData() {
        fetchActiveEnergyBurned { _ in self.save() }
        fetchTotalCalories { _ in self.save() }
        fetchWeeklyDistance { _ in self.save() }
        fetchWeeklyHours { _ in self.save() }

        fetchWorkoutDistance { _ in self.save() }
        fetchWorkoutDuration { _ in self.save() }

        fetchRestingHeartRate { _ in self.save() }
        fetchHRV { _ in self.save() }
        fetchHRVWeek() // No completion handler — consider adding one for reliability
        fetchRestingHRWeek()
        fetchBloodOxygen { _ in self.save() }
        fetchBloodOxygenWeek()

        fetchSteps { _ in self.save() }
        fetchVO2Max { _ in self.save() }
        fetchBodyMass { _ in self.save() }
        fetchHeight { _ in self.save() }

        fetchSleepData { _ in self.save() }
        fetchWorkouts { _ in self.save() }
        fetchWaterIntake { _ in self.save() }
        fetchCaloriesConsumed { _ in self.save() }
        fetchProteinIntake { _ in self.save() }
        fetchCarbsIntake { _ in self.save() }
        fetchFatIntake { _ in self.save() }
        fetchFiberIntake { _ in self.save() }
    }


    func saveDailyMetricsToFirestore(userId: String) {
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: today)

        let recovery = calculateOverallRecoveryScore()
        let trainingScore = calculateOverallTrainingScore()

        let dayDoc = db.collection("users")
            .document("roles")
            .collection("athletes")
            .document(userId)
            .collection("days")
            .document(dateString)

        dayDoc.setData([
            "date": dateString,
            "trainingScore": trainingScore,
            "recoveryScore": recovery
        ], merge: true) { error in
            if let error = error {
                print("❌ Error saving day summary: \(error.localizedDescription)")
            } else {
                print("✅ Saved summary for \(dateString)")
                self.updateDailyTrainingScore(Int(trainingScore))
            }
        }

        let trainingMetrics: [String: Any] = [
            "activeCalories": activeCalories ?? 0,
            "totalCalories": totalCalories ?? 0,
            "exerciseMinutes": exerciseMinutes ?? 0,
            "distance": distance ?? 0,
            "steps": steps ?? 0,
            "vo2Max": vo2Max ?? 0,
            "bodyMass": bodyMass ?? 0,
            "height": height ?? 0,
            "weeklyDistance": weeklyDistance ?? 0,
            "weeklyHours": weeklyHours ?? 0
        ]
        dayDoc.setData(["trainingMetrics": trainingMetrics], merge: true)


        let recoveryMetrics: [String: Any] = [
            "restingHeartRate": restingHeartRate ?? 0,
            "hrv": hrv ?? 0,
            "sleepDuration": sleepDuration ?? 0,
            "sleepQuality": sleepQuality,
            "sleepQualityScore": sleepQualityScore ?? 0,
            "stressLevel": stressLevel ?? 0,
            "hrvWeek": hrvWeek,
            "bloodOxygen": bloodOxygen ?? 0,
            "bloodOxygenWeek": bloodOxygenWeek
        ]

        dayDoc.setData(["recoveryMetrics": recoveryMetrics], merge: true)

        let nutritionMetrics: [String: Any] = [
            "waterIntake": waterIntake ?? 0,
            "caloriesConsumed": caloriesConsumed ?? 0,
            "proteinIntake": proteinIntake ?? 0,
            "carbsIntake": carbsIntake ?? 0,
            "fatIntake": fatIntake ?? 0,
            "fiberIntake": fiberIntake ?? 0
        ]

        dayDoc.setData(["nutritionMetrics": nutritionMetrics], merge: true)
    }
    
    

    func writeSampleToAppleHealth(type: HKQuantityTypeIdentifier, value: Double, unit: HKUnit, date: Date = Date()) {
        guard let quantityType = HKObjectType.quantityType(forIdentifier: type) else { return }

        let quantity = HKQuantity(unit: unit, doubleValue: value)
        let sample = HKQuantitySample(type: quantityType, quantity: quantity, start: date, end: date)

        healthStore.save(sample) { success, error in
            if success {
                print("✅ Saved \(type.rawValue) to Apple Health")
            } else if let error = error {
                print("❌ Failed to save \(type.rawValue): \(error.localizedDescription)")
            }
        }
    }

    func saveManualEntryToFirebaseAndHealth(
        calorieInput: Double?,
        stepInput: Double?,
        exerciseMinutesInput: Double?,
        distanceInput: Double?,
        hrvInput: Double?
    ) {
        if let c = calorieInput {
            totalCalories = c
            writeSampleToAppleHealth(type: .activeEnergyBurned, value: c, unit: .kilocalorie())
        }
        if let s = stepInput {
            steps = s
            writeSampleToAppleHealth(type: .stepCount, value: s, unit: .count())
        }
        if let m = exerciseMinutesInput {
            exerciseMinutes = m
            writeSampleToAppleHealth(type: .appleExerciseTime, value: m, unit: .minute())
        }
        if let d = distanceInput {
            distance = d
            writeSampleToAppleHealth(type: .distanceWalkingRunning, value: d * 1000, unit: .meter())
        }
        if let h = hrvInput {
            hrv = h
            writeSampleToAppleHealth(type: .heartRateVariabilitySDNN, value: h, unit: HKUnit(from: "ms"))
        }

        if let uid = Auth.auth().currentUser?.uid {
            saveDailyMetricsToFirestore(userId: uid)
        }
    }

    func saveDailyNutritionEntry(
        calories: Double?,
        protein: Double?,
        carbs: Double?,
        fat: Double?,
        water: Double?,
        fiber: Double?
    ) {
        if let c = calories { caloriesConsumed = (caloriesConsumed ?? 0) + c }
        if let p = protein { proteinIntake = (proteinIntake ?? 0) + p }
        if let ca = carbs { carbsIntake = (carbsIntake ?? 0) + ca }
        if let f = fat { fatIntake = (fatIntake ?? 0) + f }
        if let w = water {
            waterIntake = (waterIntake ?? 0) + w
        }
        if let fi = fiber { fiberIntake = (fiberIntake ?? 0) + fi }

        if let uid = Auth.auth().currentUser?.uid {
            saveDailyMetricsToFirestore(userId: uid)
        }
    }

    private func save() {
        if let userId = Auth.auth().currentUser?.uid {
            saveDailyMetricsToFirestore(userId: userId)
        }
    }

    func saveManualRecoveryEntry(sleepDuration: Double, sleepScore: Int, hrv: Int, restingHR: Int, stressLevel: Int) {
        // ✅ Update local state
        self.sleepDuration = sleepDuration
        self.sleepQualityScore = sleepScore
        self.hrv = Double(hrv)
        self.restingHeartRate = Double(restingHR)
        self.stressLevel = Double(stressLevel)

        // ✅ Save to Firebase
        let date = Date()
        let score = calculateOverallRecoveryScore()
        let recoveryData: [String: Any] = [
            "sleepDuration": sleepDuration,
            "sleepScore": sleepScore,
            "hrv": hrv,
            "restingHR": restingHR,
            "stressLevel": stressLevel,
            "recoveryScore": score,
            "timestamp": Timestamp(date: date)
        ]

        db.collection("users")
            .document("roles")
            .collection("athletes")
            .document(userId)
            .collection("days")
            .document(dateFormatter.string(from: date))
            .setData(["recoveryMetrics": recoveryData], merge: true)

        // also update aggregated daily metrics
        saveDailyMetricsToFirestore(userId: userId)
    }



    func fetchActiveEnergyBurned(completion: @escaping (Double?) -> Void) {
        guard let type = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return completion(nil) }
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            let value = result?.sumQuantity()?.doubleValue(for: .kilocalorie())
            DispatchQueue.main.async {
                self.activeCalories = value
                completion(value)
            }
        }
        healthStore.execute(query)
    }

    func fetchTotalCalories(completion: @escaping (Double?) -> Void) {
        guard let activeType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned),
              let basalType = HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned) else { return completion(nil) }

        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)

        let group = DispatchGroup()
        var active: Double = 0
        var basal: Double = 0

        group.enter()
        let activeQuery = HKStatisticsQuery(quantityType: activeType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            active = result?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
            group.leave()
        }

        group.enter()
        let basalQuery = HKStatisticsQuery(quantityType: basalType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            basal = result?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
            group.leave()
        }

        healthStore.execute(activeQuery)
        healthStore.execute(basalQuery)

        group.notify(queue: .main) {
            let total = active + basal
            self.totalCalories = total
            completion(total)
        }
    }

    func fetchWeeklyDistance(completion: @escaping (Double?) -> Void) {
        let workoutType = HKObjectType.workoutType()
        let startOfWeek = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        let predicate = HKQuery.predicateForSamples(withStart: startOfWeek, end: Date(), options: .strictStartDate)

        let query = HKSampleQuery(sampleType: workoutType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
            guard let workouts = samples as? [HKWorkout], error == nil else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            let meters = workouts.reduce(0.0) { $0 + ($1.totalDistance?.doubleValue(for: .meter()) ?? 0) }
            let km = meters / 1000

            DispatchQueue.main.async {
                self.weeklyDistance = km
                completion(km)
            }
        }

        healthStore.execute(query)
    }

    func fetchWeeklyHours(completion: @escaping (Double?) -> Void) {
        guard let type = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime) else { return completion(nil) }
        let startOfWeek = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        let predicate = HKQuery.predicateForSamples(withStart: startOfWeek, end: Date(), options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            let minutes = result?.sumQuantity()?.doubleValue(for: .minute()) ?? 0
            let hours = minutes / 60
            DispatchQueue.main.async {
                self.weeklyHours = hours
                completion(hours)
            }
        }
        healthStore.execute(query)
    }

    func fetchDailyDistance(completion: @escaping (Double?) -> Void) {
    guard let type = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else {
        return completion(nil)
    }

    let startOfDay = Calendar.current.startOfDay(for: Date())
    let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)

    let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
        let meters = result?.sumQuantity()?.doubleValue(for: .meter()) ?? 0
        let km = meters / 1000

        DispatchQueue.main.async {
            self.distance = km
            completion(km)
        }
    }

    healthStore.execute(query)
}

func fetchWorkoutDistance(completion: @escaping (Double?) -> Void) {
    let workoutType = HKObjectType.workoutType()
    let startOfDay = Calendar.current.startOfDay(for: Date())
    let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)

    let query = HKSampleQuery(sampleType: workoutType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
        guard let workouts = samples as? [HKWorkout], error == nil else {
            DispatchQueue.main.async {
                completion(nil)
            }
            return
        }

        let meters = workouts.reduce(0.0) { $0 + ($1.totalDistance?.doubleValue(for: .meter()) ?? 0) }
        let km = meters / 1000

        DispatchQueue.main.async {
            self.distance = km
            completion(km)
        }
    }

    healthStore.execute(query)
}
    
    func fetchWorkouts(completion: @escaping ([HKWorkout]) -> Void = { _ in }) {
        let workoutType = HKObjectType.workoutType()
        let startDate = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date.distantPast
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        let query = HKSampleQuery(sampleType: workoutType,
                                  predicate: predicate,
                                  limit: 10,
                                  sortDescriptors: [sortDescriptor]) { (_, samples, error) in
            DispatchQueue.main.async {
                if let workouts = samples as? [HKWorkout] {
                    self.recentWorkouts = workouts
                    completion(workouts)
                } else {
                    print("❌ Error fetching workouts: \(error?.localizedDescription ?? "Unknown error")")
                    self.recentWorkouts = []
                    completion([])
                }
            }
        }

        healthStore.execute(query)
    }


    func fetchWorkoutDuration(completion: @escaping (Double?) -> Void) {
        let workoutType = HKObjectType.workoutType()
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        let query = HKSampleQuery(sampleType: workoutType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, error in
            guard let workouts = samples as? [HKWorkout], error == nil else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            let totalDuration = workouts.reduce(0.0) { $0 + $1.duration }
            let totalMinutes = totalDuration / 60

            DispatchQueue.main.async {
                self.exerciseMinutes = totalMinutes
                completion(totalMinutes)
            }
        }

        healthStore.execute(query)
    }



    func fetchRestingHeartRate(completion: @escaping (Double?) -> Void) {
        fetchLatestQuantitySample(type: .restingHeartRate, unit: HKUnit.count().unitDivided(by: .minute())) {
            self.restingHeartRate = $0
            completion($0)
        }
    }

    func fetchHRV(completion: @escaping (Double?) -> Void) {
        fetchLatestQuantitySample(type: .heartRateVariabilitySDNN, unit: HKUnit(from: "ms")) {
            self.hrv = $0
            completion($0)
        }
    }

    func fetchHRVWeek(completion: @escaping ([Double]) -> Void = { _ in }) {
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
            return completion([])
        }

        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: endDate)) ?? endDate

        var interval = DateComponents()
        interval.day = 1

        let query = HKStatisticsCollectionQuery(
            quantityType: type,
            quantitySamplePredicate: HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate),
            options: .discreteAverage,
            anchorDate: calendar.startOfDay(for: startDate),
            intervalComponents: interval)

        query.initialResultsHandler = { _, results, _ in
            var values: [Double] = []
            if let stats = results {
                stats.enumerateStatistics(from: startDate, to: endDate) { stat, _ in
                    let value = stat.averageQuantity()?.doubleValue(for: HKUnit(from: "ms")) ?? 0
                    values.append(value)
                }
            }
            DispatchQueue.main.async {
                self.hrvWeek = values
                completion(values)
            }
        }

        healthStore.execute(query)
    }

    func fetchRestingHRWeek(completion: @escaping ([Double]) -> Void = { _ in }) {
        guard let type = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) else {
            return completion([])
        }

        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: endDate)) ?? endDate

        var interval = DateComponents()
        interval.day = 1

        let query = HKStatisticsCollectionQuery(
            quantityType: type,
            quantitySamplePredicate: HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate),
            options: .discreteAverage,
            anchorDate: calendar.startOfDay(for: startDate),
            intervalComponents: interval)

        query.initialResultsHandler = { _, results, _ in
            var values: [Double] = []
            if let stats = results {
                stats.enumerateStatistics(from: startDate, to: endDate) { stat, _ in
                    let value = stat.averageQuantity()?.doubleValue(for: HKUnit.count().unitDivided(by: .minute())) ?? 0
                    values.append(value)
                }
            }
            DispatchQueue.main.async {
                self.restingHRWeek = values
                completion(values)
            }
        }

        healthStore.execute(query)
    }

    func fetchBloodOxygen(completion: @escaping (Double?) -> Void) {
        fetchLatestQuantitySample(type: .oxygenSaturation, unit: HKUnit.percent()) { value in
            let percent = (value ?? 0) * 100
            self.bloodOxygen = value != nil ? percent : nil
            completion(self.bloodOxygen)
        }
    }

    func fetchBloodOxygenWeek(completion: @escaping ([Double]) -> Void = { _ in }) {
        guard let type = HKQuantityType.quantityType(forIdentifier: .oxygenSaturation) else {
            return completion([])
        }

        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: endDate)) ?? endDate

        var interval = DateComponents()
        interval.day = 1

        let query = HKStatisticsCollectionQuery(
            quantityType: type,
            quantitySamplePredicate: HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate),
            options: .discreteAverage,
            anchorDate: calendar.startOfDay(for: startDate),
            intervalComponents: interval)

        query.initialResultsHandler = { _, results, _ in
            var values: [Double] = []
            if let stats = results {
                stats.enumerateStatistics(from: startDate, to: endDate) { stat, _ in
                    let val = stat.averageQuantity()?.doubleValue(for: HKUnit.percent()) ?? 0
                    values.append(val * 100)
                }
            }
            DispatchQueue.main.async {
                self.bloodOxygenWeek = values
                completion(values)
            }
        }

        healthStore.execute(query)
    }

    func fetchSteps(completion: @escaping (Double?) -> Void) {
        guard let type = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return completion(nil) }
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            let value = result?.sumQuantity()?.doubleValue(for: .count())
            DispatchQueue.main.async {
                self.steps = value
                completion(value)
            }
        }
        healthStore.execute(query)
    }

    func fetchVO2Max(completion: @escaping (Double?) -> Void) {
        fetchLatestQuantitySample(type: .vo2Max, unit: HKUnit(from: "mL/(kg*min)")) {
            self.vo2Max = $0
            completion($0)
        }
    }

    func fetchBodyMass(completion: @escaping (Double?) -> Void) {
        fetchLatestQuantitySample(type: .bodyMass, unit: HKUnit.gramUnit(with: .kilo)) {
            self.bodyMass = $0
            completion($0)
        }
    }

    func fetchHeight(completion: @escaping (Double?) -> Void) {
        fetchLatestQuantitySample(type: .height, unit: .meter()) {
            self.height = $0
            completion($0)
        }
    }

    func fetchCaloriesConsumed(completion: @escaping (Double?) -> Void) {
        guard let type = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed) else {
            return completion(nil)
        }
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            let cals = result?.sumQuantity()?.doubleValue(for: .kilocalorie())
            DispatchQueue.main.async {
                self.caloriesConsumed = cals
                completion(cals)
            }
        }
        healthStore.execute(query)
    }

    func fetchProteinIntake(completion: @escaping (Double?) -> Void) {
        guard let type = HKQuantityType.quantityType(forIdentifier: .dietaryProtein) else {
            return completion(nil)
        }
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            let grams = result?.sumQuantity()?.doubleValue(for: .gram())
            DispatchQueue.main.async {
                self.proteinIntake = grams
                completion(grams)
            }
        }
        healthStore.execute(query)
    }

    func fetchCarbsIntake(completion: @escaping (Double?) -> Void) {
        guard let type = HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates) else {
            return completion(nil)
        }
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            let grams = result?.sumQuantity()?.doubleValue(for: .gram())
            DispatchQueue.main.async {
                self.carbsIntake = grams
                completion(grams)
            }
        }
        healthStore.execute(query)
    }

    func fetchFatIntake(completion: @escaping (Double?) -> Void) {
        guard let type = HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal) else {
            return completion(nil)
        }
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            let grams = result?.sumQuantity()?.doubleValue(for: .gram())
            DispatchQueue.main.async {
                self.fatIntake = grams
                completion(grams)
            }
        }
        healthStore.execute(query)
    }

    func fetchFiberIntake(completion: @escaping (Double?) -> Void) {
        guard let type = HKQuantityType.quantityType(forIdentifier: .dietaryFiber) else {
            return completion(nil)
        }
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            let grams = result?.sumQuantity()?.doubleValue(for: .gram())
            DispatchQueue.main.async {
                self.fiberIntake = grams
                completion(grams)
            }
        }
        healthStore.execute(query)
    }

    func fetchWaterIntake(completion: @escaping (Double?) -> Void) {
        guard let type = HKQuantityType.quantityType(forIdentifier: .dietaryWater) else {
            return completion(nil)
        }
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            let liters = result?.sumQuantity()?.doubleValue(for: .liter())
            DispatchQueue.main.async {
                self.waterIntake = liters
                completion(liters)
            }
        }
        healthStore.execute(query)
    }

    func fetchSleepData(completion: @escaping (Double?) -> Void) {
        guard let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            completion(nil)
            return
        }

        // Only fetch sleep for the last 24 hours to avoid displaying multiple nights
        let startDate = Date().addingTimeInterval(-24 * 60 * 60)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date())

        let query = HKSampleQuery(
            sampleType: type,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [NSSortDescriptor(key: "startDate", ascending: true)]
        ) { _, results, _ in
            guard let samples = results as? [HKCategorySample], !samples.isEmpty else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            // Group samples by the day they ended and select the group with the
            // longest total duration. This avoids showing multiple nights of
            // data in the sleep timeline.
            let calendar = Calendar.current
            let grouped = Dictionary(grouping: samples) { calendar.startOfDay(for: $0.endDate) }
            let selectedSamples = grouped.max { a, b in
                let durA = a.value.reduce(0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
                let durB = b.value.reduce(0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
                return durA < durB
            }?.value ?? []

            var totalSleep: Double = 0
            var awakeDuration: Double = 0
            var deepDuration: Double = 0
            var remDuration: Double = 0
            var lightDuration: Double = 0
            var awakenings: Int = 0
            var sleepStageDurations: [String: Double] = [:]
            var sleepStages: [SleepStage] = []
            
            for sample in selectedSamples {
                let duration = sample.endDate.timeIntervalSince(sample.startDate) / 3600.0
                let stageValue = HKCategoryValueSleepAnalysis(rawValue: sample.value)
                let stage = self.stageDescription(for: sample.value)
                
                if let stageValue = stageValue {
                    switch stageValue {
                    case .awake:
                        awakeDuration += duration
                        if let last = sleepStages.last, last.stage != "Awake" {
                            awakenings += 1
                        }
                    case .asleepDeep:
                        deepDuration += duration
                        totalSleep += duration
                    case .asleepREM:
                        remDuration += duration
                        totalSleep += duration
                    case .asleepCore, .asleepUnspecified:
                        lightDuration += duration
                        totalSleep += duration
                    default:
                        break
                    }
                }
                
                sleepStageDurations[stage, default: 0.0] += duration
                sleepStages.append(SleepStage(stage: stage, startDate: sample.startDate, endDate: sample.endDate))
            }
            
            let totalTime = totalSleep + awakeDuration
            let durationScore = min(totalSleep / 8.0, 1.0) * 40.0
            let awakeScore = max(0.0, 1.0 - (awakeDuration / max(totalTime, 1))) * 20.0
            let awakeningScore = max(0.0, 1.0 - (Double(awakenings) / 10.0)) * 20.0
            let deepScore = min(deepDuration / 1.5, 1.0) * 10.0
            let totalStageSleep = max(deepDuration + remDuration + lightDuration, 1.0)
            let idealDist = (deep: 0.25, rem: 0.25, light: 0.5)
            let diff = abs(idealDist.deep - deepDuration / totalStageSleep) +
                       abs(idealDist.rem - remDuration / totalStageSleep) +
                       abs(idealDist.light - lightDuration / totalStageSleep)
            let balanceScore = max(0.0, 1.0 - diff) * 10.0
            let qualityScore = Int(durationScore + awakeScore + awakeningScore + deepScore + balanceScore)
            let quality: String
            if qualityScore >= 80 {
                quality = "Good"
            } else if qualityScore >= 60 {
                quality = "Fair"
            } else {
                quality = "Poor"
            }

            DispatchQueue.main.async {
                self.sleepDuration = totalSleep
                self.sleepQuality = quality
                self.sleepQualityScore = qualityScore
                self.sleepStages = sleepStages
                self.rawSleepSamples = selectedSamples

                // ✅ Upload to Firebase
                self.uploadSleepToFirebase(duration: totalSleep, quality: quality, stages: sleepStageDurations)

                completion(totalSleep)
            }
        }

        healthStore.execute(query)
    }




    private func fetchLatestQuantitySample(type identifier: HKQuantityTypeIdentifier, unit: HKUnit, completion: @escaping (Double?) -> Void) {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return }
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, results, _ in
            let value = (results?.first as? HKQuantitySample)?.quantity.doubleValue(for: unit)
            DispatchQueue.main.async { completion(value) }
        }
        healthStore.execute(query)
    }

    func stageDescription(for value: Int) -> String {
        switch HKCategoryValueSleepAnalysis(rawValue: value) {
        case .awake:
            return "Awake"
        case .asleepCore:
            return "Light Sleep"
        case .asleepREM:
            return "REM Sleep"
        case .asleepDeep:
            return "Deep Sleep"
        case .inBed:
            return "In Bed"
        case .asleepUnspecified:
            return "Light Sleep" // Optional fallback
        default:
            return "Unknown"
        }
    }

    func addTrainingScore(_ score: Int) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let newScore = TrainingScore(date: Date(), score: score)
        try? db.collection("users")
            .document("roles")
            .collection("athletes")
            .document(uid)
            .collection("trainingScores")
            .document(newScore.id)
            .setData(from: newScore)
    }

    func updateDailyTrainingScore(_ score: Int) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let calendar = Calendar.current
        if let existing = trainingScores.first(where: { calendar.isDate($0.date, inSameDayAs: Date()) }) {
            try? db.collection("users")
                .document("roles")
                .collection("athletes")
                .document(uid)
                .collection("trainingScores")
                .document(existing.id)
                .setData(["date": existing.date, "score": score], merge: true)
        } else {
            addTrainingScore(score)
        }
    }

    func fetchTrainingScores() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let startDate = Calendar.current.date(byAdding: .day, value: -6, to: Date()) ?? Date()
        let startString = dateFormatter.string(from: startDate)

        db.collection("users")
            .document("roles")
            .collection("athletes")
            .document(uid)
            .collection("days")
            .whereField("date", isGreaterThanOrEqualTo: startString)
            .order(by: "date", descending: false)
            .addSnapshotListener { snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                self.trainingScores = docs.compactMap { doc in
                    let data = doc.data()
                    guard let dateStr = data["date"] as? String,
                          let scoreAny = data["trainingScore"],
                          let date = self.dateFormatter.date(from: dateStr) else {
                        return nil
                    }

                    let score: Int
                    if let s = scoreAny as? Int {
                        score = s
                    } else if let d = scoreAny as? Double {
                        score = Int(d)
                    } else {
                        score = 0
                    }

                    return TrainingScore(id: doc.documentID, date: date, score: score)
                }
            }
    }

    func setGoal(for metric: String, value: Double) {
        dailyGoals[metric] = value
        UserDefaults.standard.set(dailyGoals, forKey: "dailyGoals")

        if let uid = Auth.auth().currentUser?.uid {
            db.collection("users")
                .document("roles")
                .collection("athletes")
                .document(uid)
                .collection("goals")
                .document("data")
                .setData([metric: value], merge: true)
        }
    }

    func loadGoals() {
        if let saved = UserDefaults.standard.dictionary(forKey: "dailyGoals") as? [String: Double] {
            dailyGoals = saved
        }

        if let uid = Auth.auth().currentUser?.uid {
            db.collection("users")
                .document("roles")
                .collection("athletes")
                .document(uid)
                .collection("goals")
                .document("data")
                .getDocument { snapshot, _ in
                    if let data = snapshot?.data() as? [String: Double] {
                        DispatchQueue.main.async {
                            self.dailyGoals = data
                            UserDefaults.standard.set(data, forKey: "dailyGoals")
                        }
                    }
                }
        }
    }
    
    func disconnectHealthKit() {
        isConnected = false
        isAuthorized = false
        UserDefaults.standard.set(false, forKey: "healthConnected")
        timer?.invalidate()
        print("❌ Disconnected from Apple Health")
    }
    
    func uploadSleepToFirebase(duration: Double, quality: String, stages: [String: Double]) {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayKey = dateFormatter.string(from: Date())

        let ref = Firestore.firestore()
            .collection("users")
            .document("roles")
            .collection("athletes")
            .document(userId)
            .collection("days")
            .document(todayKey)

        let data: [String: Any] = [
            "sleepDuration": duration,
            "sleepQuality": quality,
            "sleepStages": stages
        ]
        ref.setData(["recoveryMetrics": ["sleep": data]], merge: true)
    }

}

extension HKWorkoutActivityType {
    var name: String {
        switch self {
        case .running: return "Running"
        case .cycling: return "Cycling"
        case .walking: return "Walking"
        case .rowing: return "Rowing"
        case .swimming: return "Swimming"
        case .functionalStrengthTraining: return "Strength Training"
        case .highIntensityIntervalTraining: return "HIIT"
        case .yoga: return "Yoga"
        default: return "Other"
        }
    }

    var iconName: String {
        switch self {
        case .running: return "figure.run"
        case .cycling: return "bicycle"
        case .walking: return "figure.walk"
        case .rowing: return "figure.rower"
        case .swimming: return "drop.fill"
        case .functionalStrengthTraining: return "dumbbell.fill"
        case .highIntensityIntervalTraining: return "bolt.fill"
        case .yoga: return "figure.cooldown"
        default: return "figure.flexibility"
        }
    }
}
