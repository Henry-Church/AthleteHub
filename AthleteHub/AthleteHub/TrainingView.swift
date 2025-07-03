// TrainingView.swift

import SwiftUI
import Charts
import FirebaseAuth
import HealthKit


struct TrainingView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var healthManager: HealthManager
    @State private var showingSetGoals = false
    @State private var showingManualEntry = false
    
    
    let customYellow = Color(red: 1.0, green: 0.84, blue: 0.2)

    var body: some View {
        let backgroundColor = colorScheme == .dark ? customYellow.opacity(0.1) : Color(.systemGray6)
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Text("Training Dashboard")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    Spacer()
                    HStack(spacing: 8) {
                        Button(action: { showingSetGoals = true }) {
                            Image(systemName: "target")
                                .padding(8)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(8)
                        }

                        Button(action: { showingManualEntry = true }) {
                            Image(systemName: "square.and.pencil")
                                .padding(8)
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal)

                OverallTrainingScoreCard(score: Int(calculateOverallTrainingScore()), colorScheme: colorScheme)
                    .padding(.horizontal)

                TrainingInsightsCardImproved(
                    insights: generateTrainingInsights(),
                    colorScheme: colorScheme
                )
                .padding(.horizontal)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    
                    TrainingMetricCard(
                        title: "Total Calories",
                        icon: "flame.fill",
                        current: healthManager.totalCalories ?? 0,
                        goal: healthManager.dailyGoals["Calories"] ?? 0,
                        colorScheme: colorScheme,
                        shadowColor: customYellow
                    )

                    TrainingMetricCard(
                        title: "Steps",
                        icon: "shoeprints.fill",
                        current: healthManager.steps ?? 0,
                        goal: healthManager.dailyGoals["Steps"] ?? 0,
                        colorScheme: colorScheme,
                        shadowColor: customYellow
                    )

                    TrainingMetricCard(
                        title: "Exercise Minutes",
                        icon: "clock",
                        current: healthManager.exerciseMinutes ?? 0,
                        goal: healthManager.dailyGoals["ExerciseMinutes"] ?? 0,
                        colorScheme: colorScheme,
                        shadowColor: customYellow
                    )

                    TrainingMetricCard(
                        title: "Distance (km)",
                        icon: "figure.walk",
                        current: healthManager.distance ?? 0,
                        goal: healthManager.dailyGoals["Distance"] ?? 0,
                        colorScheme: colorScheme,
                        shadowColor: customYellow
                    )
                }
                .padding(.horizontal)

                RecentWorkoutsCard(healthManager: healthManager, colorScheme: colorScheme)
                
                // 7-Day Training Score Trend
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Overall Training – 7 Day Trends")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Spacer()
                        Button(action: {
                            showingManualEntry = true
                        }) {
                            Image(systemName: "plus.circle")
                        }
                    }
                    .padding(.horizontal)

                    if healthManager.trainingScores.isEmpty {
                        Text("No training scores yet.")
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    } else {
                        Chart(healthManager.trainingScores) { entry in
                            LineMark(
                                x: .value("Date", entry.date),
                                y: .value("Score", entry.score)
                            )
                            PointMark(
                                x: .value("Date", entry.date),
                                y: .value("Score", entry.score)
                            )
                        }
                        .chartYScale(domain: 0...100)
                        .frame(height: 200)
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .background(backgroundColor.edgesIgnoringSafeArea(.all))
        .sheet(isPresented: $showingSetGoals) {
            SetGoalsView().environmentObject(healthManager)
        }
        .sheet(isPresented: $showingManualEntry) {
            ManualTrainingEntryView()
                .environmentObject(healthManager)
        }
    }

    private func generateTrainingInsights() -> [String] {
        var insights: [String] = []

        if let calories = healthManager.totalCalories,
           let goal = healthManager.dailyGoals["Calories"], goal > 0 {
            let percent = calories / goal * 100
            insights.append(percent >= 100 ?
                "You’ve hit your daily calorie goal of \(Int(goal)) kcal." :
                "You’re at \(Int(percent))% of your calorie goal.")
        } else {
            insights.append("No calorie data yet.")
        }

        if let steps = healthManager.steps,
           let goal = healthManager.dailyGoals["Steps"], goal > 0 {
            let percent = steps / goal * 100
            insights.append(percent >= 100 ?
                "Step goal achieved! \(Int(steps)) steps today." :
                "You’re at \(Int(percent))% of your step goal.")
        } else {
            insights.append("No step data yet.")
        }

        if let distance = healthManager.distance,
           let goal = healthManager.dailyGoals["Distance"], goal > 0 {
            let percent = distance / goal * 100
            insights.append(percent >= 100 ?
                "Distance goal met! \(String(format: "%.1f", distance)) km covered." :
                "\(String(format: "%.1f", distance)) km today, \(Int(percent))% of your goal.")
        } else {
            insights.append("No distance data yet.")
        }

        if let minutes = healthManager.exerciseMinutes,
           let goal = healthManager.dailyGoals["ExerciseMinutes"], goal > 0 {
            let percent = minutes / goal * 100
            insights.append(percent >= 100 ?
                "Exercise goal achieved with \(Int(minutes)) minutes today." :
                "\(Int(minutes)) minutes of exercise — \(Int(percent))% of your goal.")
        } else {
            insights.append("No exercise minutes data yet.")
        }

        return insights
        

    }

    private func calculateOverallTrainingScore() -> Double {
        let calorieScore = min((healthManager.totalCalories ?? 0) / max(healthManager.dailyGoals["Calories"] ?? 1, 1), 1) * 25
        let stepScore = min((healthManager.steps ?? 0) / max(healthManager.dailyGoals["Steps"] ?? 1, 1), 1) * 25
        let distanceScore = min((healthManager.distance ?? 0) / max(healthManager.dailyGoals["Distance"] ?? 1, 1), 1) * 25
        let minutesScore = min((healthManager.exerciseMinutes ?? 0) / max(healthManager.dailyGoals["ExerciseMinutes"] ?? 1, 1), 1) * 25

        return calorieScore + stepScore + distanceScore + minutesScore
    }
}

struct TrainingInsightsCardImproved: View {
    let insights: [String]
    let colorScheme: ColorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Training Insights")
                    .font(.headline)
                    .foregroundColor(.primary)
            }

            ForEach(insights, id: \.self) { insight in
                HStack(alignment: .top) {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.green)
                    Text(insight)
                        .font(.footnote)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(20)
    }
}




struct TrainingMetricCard: View {
    let title: String
    let icon: String
    let current: Double
    let goal: Double?
    let colorScheme: ColorScheme
    let shadowColor: Color

    var percent: Double {
        (goal != nil && goal! > 0) ? min(current / goal!, 1) : 0
    }

    var statusColor: Color {
        if percent >= 1 {
            return .green
        } else if percent >= 0.5 {
            return .yellow
        } else {
            return .red
        }
    }

    var statusText: String {
        if percent >= 1 {
            return "Excellent"
        } else if percent >= 0.5 {
            return "Almost"
        } else {
            return "Poor"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.primary)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Text(statusText)
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(6)
                    .background(statusColor)
                    .cornerRadius(8)
            }

            if goal != nil {
                Text("\(Int(current)) / \(Int(goal ?? 0))")
                    .font(.caption)
                    .foregroundColor(.gray)

                ProgressView(value: percent)
                    .progressViewStyle(LinearProgressViewStyle(tint: .gray))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
            } else {
                Text("\(Int(current))")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
        .cornerRadius(12)
        .shadow(color: shadowColor.opacity(0.4), radius: 8, x: 0, y: 4)
    }
}

struct OverallTrainingScoreCard: View {
    let score: Int
    let colorScheme: ColorScheme

    var statusText: String {
        if score >= 80 {
            return "Excellent"
        } else if score >= 50 {
            return "Almost"
        } else {
            return "Poor"
        }
    }

    var statusColor: Color {
        if score >= 80 {
            return .green
        } else if score >= 50 {
            return .yellow
        } else {
            return .red
        }
    }

    var body: some View {
        HStack {
            Image(systemName: "figure.run")
                .font(.largeTitle)
                .foregroundColor(.black)

            VStack(alignment: .leading) {
                Text("Overall Training Score")
                    .font(.headline)
                    .foregroundColor(.black)

                Text("\(score)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.black)
            }

            Spacer()

            Text(statusText)
                .font(.caption)
                .fontWeight(.bold)
                .padding(8)
                .background(statusColor)
                .foregroundColor(.black)
                .cornerRadius(12)
        }
        .padding()
        .background(Color.yellow)
        .cornerRadius(20)
    }
}





struct SetGoalsView: View {
    @EnvironmentObject var healthManager: HealthManager
    @Environment(\.presentationMode) var presentationMode

    @State private var calorieGoal: String = ""
    @State private var stepGoal: String = ""
    @State private var exerciseMinutesGoal: String = ""
    @State private var distanceGoal: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Set Your Daily Goals")) {
                    HStack {
                        Image(systemName: "flame.fill").foregroundColor(.red)
                        TextField("Calorie Goal", text: $calorieGoal).keyboardType(.numberPad)
                    }
                    HStack {
                        Image(systemName: "shoeprints.fill").foregroundColor(.blue)
                        TextField("Step Goal", text: $stepGoal).keyboardType(.numberPad)
                    }
                    HStack {
                        Image(systemName: "clock").foregroundColor(.orange)
                        TextField("Exercise Minutes", text: $exerciseMinutesGoal).keyboardType(.decimalPad)
                    }
                    HStack {
                        Image(systemName: "figure.walk").foregroundColor(.green)
                        TextField("Distance (km)", text: $distanceGoal).keyboardType(.decimalPad)
                    }
                }
            }
            .navigationTitle("Set Goals")
            .navigationBarItems(trailing: Button("Save") {
                if let calories = Double(calorieGoal) {
                    healthManager.setGoal(for: "Calories", value: calories)
                }
                if let steps = Double(stepGoal) {
                    healthManager.setGoal(for: "Steps", value: steps)
                }
                if let minutes = Double(exerciseMinutesGoal) {
                    healthManager.setGoal(for: "ExerciseMinutes", value: minutes)
                }
                if let distance = Double(distanceGoal) {
                    healthManager.setGoal(for: "Distance", value: distance)
                }
                presentationMode.wrappedValue.dismiss()
            })
            .onAppear {
                if let goal = healthManager.dailyGoals["Calories"] {
                    calorieGoal = String(Int(goal))
                }
                if let goal = healthManager.dailyGoals["Steps"] {
                    stepGoal = String(Int(goal))
                }
                if let goal = healthManager.dailyGoals["ExerciseMinutes"] {
                    exerciseMinutesGoal = String(format: "%.0f", goal)
                }
                if let goal = healthManager.dailyGoals["Distance"] {
                    distanceGoal = String(format: "%.1f", goal)
                }
            }
        }
    }
}


struct ManualTrainingEntryView: View {
    
    @EnvironmentObject var healthManager: HealthManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var calories: String = ""
    @State private var steps: String = ""
    @State private var minutes: String = ""
    @State private var distance: String = ""
    
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Enter Training Data")) {
                    TextField("Calories (kcal)", text: $calories)
                        .keyboardType(.decimalPad)
                    
                    TextField("Steps", text: $steps)
                        .keyboardType(.numberPad)
                    
                    TextField("Exercise Minutes", text: $minutes)
                        .keyboardType(.decimalPad)
                    
                    TextField("Distance (km)", text: $distance)
                        .keyboardType(.decimalPad)
                }
                Button("Save") {
                    if let calories = Double(calories) {
                        healthManager.totalCalories = calories
                    }
                    if let steps = Double(steps) {
                        healthManager.steps = steps
                    }
                    if let minutes = Double(minutes) {
                        healthManager.exerciseMinutes = minutes
                    }
                    if let distance = Double(distance) {
                        healthManager.distance = distance
                    }
                    
                    if let userId = Auth.auth().currentUser?.uid {
                        healthManager.saveDailyMetricsToFirestore(userId: userId)
                    }
                    
                    presentationMode.wrappedValue.dismiss()
                }
                .navigationTitle("Manual Entry")
                .navigationBarItems(trailing: Button("Save") {
                    if let cal = Double(calories) {
                        healthManager.activeCalories = cal
                        healthManager.totalCalories = cal + (healthManager.totalCalories ?? 0 - (healthManager.activeCalories ?? 0))
                    }
                    if let st = Double(steps) {
                        healthManager.steps = st
                    }
                    if let min = Double(minutes) {
                        healthManager.exerciseMinutes = min
                    }
                    if let dist = Double(distance) {
                        healthManager.distance = dist
                    }
                    
                    presentationMode.wrappedValue.dismiss()
                })
            }
        }
    }
}

struct RecentWorkoutsCard: View {
    @ObservedObject var healthManager: HealthManager
    let colorScheme: ColorScheme
    @State private var expandedWorkoutID: Int?
    @State private var selectedWorkout: HKWorkout?
    @State private var showingWorkoutDetail = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Workouts")
                .font(.headline)
                .foregroundColor(.white)

            if healthManager.recentWorkouts.isEmpty {
                Text("Data not available")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(healthManager.recentWorkouts.prefix(3), id: \.startDate) { workout in
                    Button(action: {
                        selectedWorkout = workout
                        showingWorkoutDetail = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: workout.workoutActivityType.iconName)
                                .frame(width: 24, height: 24)

                            VStack(alignment: .leading) {
                                Text(workout.workoutActivityType.name)
                                    .font(.subheadline)
                                    .foregroundColor(.white)

                                Text(formattedDateTime(workout.startDate))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 4)
                    }

                    Divider().background(Color.white.opacity(0.2))
                }

            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
        .sheet(isPresented: $showingWorkoutDetail) {
            if let workout = selectedWorkout {
                WorkoutDetailView(workout: workout)
    }
        
            }
        }

    

    func formattedDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}


struct WorkoutDetailView: View {
    let workout: HKWorkout
    @Environment(\.dismiss) var dismiss
    @State private var isSharing = false

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Workout")) {
                    HStack {
                        Image(systemName: workout.workoutActivityType.iconName)
                            .foregroundColor(.blue)
                        Text(workout.workoutActivityType.name)
                            .font(.headline)
                    }

                    Text("Date: \(formattedDate(workout.startDate))")
                }

                Section(header: Text("Details")) {
                    Text("Start Time: \(formattedTime(workout.startDate))")
                    Text("End Time: \(formattedTime(workout.endDate))")
                    Text("Duration: \(Int(workout.duration / 60)) min")
                    Text("Calories Burned: \(Int(workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0)) kcal")

                    if let distance = workout.totalDistance?.doubleValue(for: .meter()) {
                        let formattedSpeed = formatSpeed(distance: distance, duration: workout.duration, type: workout.workoutActivityType)
                        Text("Distance: \(String(format: "%.2f", distance / 1000)) km")
                        Text("Avg Speed: \(formattedSpeed)")
                    }
                }
            }
            .navigationTitle("Workout Details")
            .navigationBarItems(trailing: Button("Share") {
                isSharing = true
            })
            .sheet(isPresented: $isSharing) {
                if let summary = generateShareSummary() {
                    ActivityView(activityItems: [summary])
                }
            }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }

    private func formattedTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: date)
    }

    private func formatSpeed(distance: Double, duration: TimeInterval, type: HKWorkoutActivityType) -> String {
        guard duration > 0 else { return "—" }

        switch type {
        case .cycling:
            let speedKph = (distance / 1000) / (duration / 3600)
            return String(format: "%.1f km/h", speedKph)

        case .running:
            let pace = duration / (distance / 1000)
            let min = Int(pace / 60)
            let sec = Int(pace.truncatingRemainder(dividingBy: 60))
            return String(format: "%d:%02d min/km", min, sec)

        case .rowing:
            let pace500 = duration / (distance / 500)
            let min = Int(pace500 / 60)
            let sec = Int(pace500.truncatingRemainder(dividingBy: 60))
            return String(format: "%d:%02d min/500m", min, sec)

        default:
            return "N/A"
        }
    }

    private func generateShareSummary() -> String? {
        guard workout.duration > 0 else { return nil }

        let calories = Int(workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0)
        let durationMin = Int(workout.duration / 60)
        let distance = workout.totalDistance?.doubleValue(for: .meter()) ?? 0
        let distanceKm = String(format: "%.2f", distance / 1000)
        let speed = formatSpeed(distance: distance, duration: workout.duration, type: workout.workoutActivityType)

        return """
        Workout Summary:
        Type: \(workout.workoutActivityType.name)
        Date: \(formattedDate(workout.startDate))
        Duration: \(durationMin) min
        Calories: \(calories) kcal
        Distance: \(distanceKm) km
        Avg Speed: \(speed)
        """
    }
}


struct ActivityView: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
