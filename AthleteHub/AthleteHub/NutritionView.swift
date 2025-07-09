


import SwiftUI

// Utility helpers shared across nutrition views
fileprivate func intakeValue(_ healthValue: Double?, fallback: String?) -> Double {
    healthValue ?? Double(fallback ?? "0") ?? 0
}

fileprivate func percent(intake: Double, goal: String?) -> String {
    let g = Double(goal ?? "0") ?? 0
    guard g > 0 else { return "0%" }
    return "\(Int((intake / g) * 100))%"
}

// MARK: - NutritionView

struct NutritionView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var userProfile: UserProfile
    @EnvironmentObject var healthManager: HealthManager
    
    @State private var showingSetGoals = false
    @State private var showingManualEntry = false
    @State private var activeMetric: MetricType?

    private func percentage(from text: String?) -> Double? {
        guard let stripped = text?.replacingOccurrences(of: "%", with: ""),
              let value = Double(stripped) else { return nil }
        return value
    }

    private func intakeValue(_ healthValue: Double?, fallback: String?) -> Double {
        healthValue ?? Double(fallback ?? "0") ?? 0
    }

    private func percent(intake: Double, goal: String?) -> String {
        let g = Double(goal ?? "0") ?? 0
        guard g > 0 else { return "0%" }
        return "\(Int((intake / g) * 100))%"
    }
    
    private var overallNutritionScore: Int {
        let metrics: [Double] = [
            percent(intake: intakeValue(healthManager.caloriesConsumed, fallback: userProfile.caloriesConsumed), goal: userProfile.caloriesGoal),
            percent(intake: intakeValue(healthManager.proteinIntake, fallback: userProfile.proteinIntake), goal: userProfile.proteinGoal),
            percent(intake: intakeValue(healthManager.carbsIntake, fallback: userProfile.carbsIntake), goal: userProfile.carbsGoal),
            percent(intake: intakeValue(healthManager.fatIntake, fallback: userProfile.fatIntake), goal: userProfile.fatGoal),
            percent(intake: intakeValue(healthManager.waterIntake, fallback: userProfile.waterIntake), goal: userProfile.waterGoal),
            percent(intake: intakeValue(healthManager.fiberIntake, fallback: userProfile.fiberIntake), goal: userProfile.fiberGoal)
        ].compactMap { Double($0.replacingOccurrences(of: "%", with: "")) }
        guard !metrics.isEmpty else { return 0 }
        return Int(metrics.reduce(0, +) / Double(metrics.count))
    }
    
    private func generateNutritionInsights() -> [String] {
        func message(for percent: Double, metric: String) -> String {
            if percent >= 100 { return "\(metric.capitalized) goal met." }
            return "\(Int(percent))% of \(metric) goal."
        }
        
        var insights: [String] = []
        let cals = intakeValue(healthManager.caloriesConsumed, fallback: userProfile.caloriesConsumed)
        let calsPct = Double(percent(intake: cals, goal: userProfile.caloriesGoal).replacingOccurrences(of: "%", with: "")) ?? 0
        if calsPct > 0 {
            insights.append(message(for: calsPct, metric: "calorie"))
        } else {
            insights.append("No calorie data yet.")
        }

        let protein = intakeValue(healthManager.proteinIntake, fallback: userProfile.proteinIntake)
        let proteinPct = Double(percent(intake: protein, goal: userProfile.proteinGoal).replacingOccurrences(of: "%", with: "")) ?? 0
        if proteinPct > 0 { insights.append(message(for: proteinPct, metric: "protein")) }

        let water = intakeValue(healthManager.waterIntake, fallback: userProfile.waterIntake)
        let waterPct = Double(percent(intake: water, goal: userProfile.waterGoal).replacingOccurrences(of: "%", with: "")) ?? 0
        if waterPct > 0 { insights.append(message(for: waterPct, metric: "water")) }
        return insights
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Text("Nutrition Dashboard")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    Spacer()
                    HStack(spacing: 12) {
                        Button(action: { showingSetGoals = true }) {
                            Image(systemName: "target")
                                .padding(8)
                                .background(Color.green.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        Button(action: { showingManualEntry = true }) {
                            Image(systemName: "square.and.pencil")
                                .padding(8)
                                .background(Color.green.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                .padding(.horizontal)
                
                OverallNutritionScoreCard(score: overallNutritionScore, colorScheme: colorScheme)
                    .padding(.horizontal)
                
                NutritionInsightsCard(insights: generateNutritionInsights(), colorScheme: colorScheme)
                    .padding(.horizontal)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    // — Calories
                    NutritionRingCard(
                        title:      "Calories",
                        icon:       "flame.fill",
                        value:      String(format: "%.0f kcal", intakeValue(healthManager.caloriesConsumed, fallback: userProfile.caloriesConsumed)),
                        goal:       "\(userProfile.caloriesGoal      ?? "0") kcal",
                        percentage: percent(intake: intakeValue(healthManager.caloriesConsumed, fallback: userProfile.caloriesConsumed), goal: userProfile.caloriesGoal),
                        colorScheme: colorScheme
                    ) {
                        activeMetric = .calories
                    }

                    // — Protein
                    NutritionRingCard(
                        title:      "Protein",
                        icon:       "bolt.fill",
                        value:      String(format: "%.0f g", intakeValue(healthManager.proteinIntake, fallback: userProfile.proteinIntake)),
                        goal:       "\(userProfile.proteinGoal      ?? "0") g",
                        percentage: percent(intake: intakeValue(healthManager.proteinIntake, fallback: userProfile.proteinIntake), goal: userProfile.proteinGoal),
                        colorScheme: colorScheme
                    ) {
                        activeMetric = .protein
                    }

                    // — Carbs
                    NutritionRingCard(
                        title:      "Carbs",
                        icon:       "leaf.fill",
                        value:      String(format: "%.0f g", intakeValue(healthManager.carbsIntake, fallback: userProfile.carbsIntake)),
                        goal:       "\(userProfile.carbsGoal        ?? "0") g",
                        percentage: percent(intake: intakeValue(healthManager.carbsIntake, fallback: userProfile.carbsIntake), goal: userProfile.carbsGoal),
                        colorScheme: colorScheme
                    ) {
                        activeMetric = .carbs
                    }

                    // — Fat
                    NutritionRingCard(
                        title:      "Fat",
                        icon:       "drop.fill",
                        value:      String(format: "%.0f g", intakeValue(healthManager.fatIntake, fallback: userProfile.fatIntake)),
                        goal:       "\(userProfile.fatGoal          ?? "0") g",
                        percentage: percent(intake: intakeValue(healthManager.fatIntake, fallback: userProfile.fatIntake), goal: userProfile.fatGoal),
                        colorScheme: colorScheme
                    ) {
                        activeMetric = .fat
                    }
                }
                .padding(.horizontal)

                WaterIntakeCard(
                    intake:      String(format: "%.1f", intakeValue(healthManager.waterIntake, fallback: userProfile.waterIntake)),
                    goal:        userProfile.waterGoal    ?? "0",
                    percentage:  percent(intake: intakeValue(healthManager.waterIntake, fallback: userProfile.waterIntake), goal: userProfile.waterGoal),
                    colorScheme: colorScheme
                ) {
                    activeMetric = .water
                }
                .padding(.horizontal)
                    
                    NutritionChartCard(title: "7-Day Nutrition Trends", colorScheme: colorScheme) {
                        if userProfile.dailyIntakeTrendsAvailable {
                            Text("Chart will go here")
                                .frame(height: 150)
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Data not available")
                                .foregroundColor(.secondary)
                                .frame(height: 150)
                                .frame(maxWidth: .infinity)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color(UIColor.systemBackground).edgesIgnoringSafeArea(.all))
            .sheet(isPresented: $showingSetGoals) {
                SetNutritionGoalsView().environmentObject(userProfile)
            }
            .sheet(isPresented: $showingManualEntry) {
                ManualNutritionEntryView()
                    .environmentObject(userProfile)
                    .environmentObject(healthManager)
            }
            .sheet(item: $activeMetric) { metric in
                MetricDetailView(metric: metric)
                    .environmentObject(userProfile)
                    .environmentObject(healthManager)
            }
            .onAppear {
                userProfile.resetDailyNutritionIfNeeded()
            }
        }
    }
    
    
    // The rest of the supporting views like NutritionRingCard, WaterIntakeCard, etc. will be appended below...
    
    // MARK: - NutritionRingCard
    
struct NutritionRingCard: View {
    let title: String
    let icon: String
    let value: String       // e.g. "1,200 kcal"
    let goal: String        // e.g. "2,000 kcal"
    let percentage: String  // e.g. "60%"
    let colorScheme: ColorScheme
    var onTap: () -> Void = {}

    // 1) Fixed diameter for the ring
    private let diameter: CGFloat = 100

    @State private var animatedProgress: Double = 0

    // 0…1
    private var progress: Double {
        (Double(percentage.replacingOccurrences(of: "%", with: "")) ?? 0) / 100
    }

    // map progress → red/yellow/green
    private var ringColor: Color {
        switch progress {
        case ..<0.5:   return .red
        case ..<0.8:   return .yellow
        default:       return .green
        }
    }

    private func animateProgress() {
        withAnimation(.easeOut(duration: 1.2)) {
            animatedProgress = progress
        }
    }

    var body: some View {
        VStack(spacing: 16) {
          // Title row
          HStack {
            Label(title, systemImage: icon)
              .font(.headline)
            Spacer()
          }

          // Ring + center text
          ZStack {
            Circle()
              .stroke(Color.gray.opacity(0.2), lineWidth: 10)
              .frame(width: diameter, height: diameter)

            Circle()
              .trim(from: 0, to: animatedProgress)
              .stroke(ringColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
              .rotationEffect(.degrees(-90))
              .frame(width: diameter, height: diameter)

            // 2) Constrain text to 70% of diameter and allow tightening
            VStack(spacing: 2) {
              Text(value)
                .font(.title2).bold()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .allowsTightening(true)
                .layoutPriority(1)
                .frame(width: diameter * 0.7)

              Text("/ \(goal)")
                .font(.caption)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .allowsTightening(true)
                .frame(width: diameter * 0.7)
                .foregroundColor(.secondary)
            }
          }

          // Footer label
          Text("\(percentage) of daily target")
            .font(.caption2)
            .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 180)
        .background(colorScheme == .dark
                    ? Color(.secondarySystemBackground)
                    : Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.green.opacity(0.3), radius: 8, x: 0, y: 4)
        .onAppear { animateProgress() }
        .onChange(of: progress) { _ in animateProgress() }
        .onTapGesture { onTap() }
    }
}
    
    
    // MARK: - WaterIntakeCard
    
    struct WaterIntakeCard: View {
        let intake: String     // e.g. "1.2"
        let goal: String       // e.g. "2.0"
        let percentage: String // e.g. "60%"
        let colorScheme: ColorScheme
        var onTap: () -> Void = {}
        
        @State private var animatedProgress: Double = 0
        
        private var progress: Double {
            (Double(percentage.replacingOccurrences(of: "%", with: "")) ?? 0) / 100
        }
        
        // ring is always blue for water intake
        private var ringColor: Color { .blue }
        
        private var numericIntake: Double {
            Double(intake) ?? 0
        }
        private var numericGoal: Double {
            Double(goal) ?? 0
        }
        private var remaining: Double {
            max(numericGoal - numericIntake, 0)
        }
        
        private func animateProgress() {
                    withAnimation(.easeOut(duration: 1.2)) {
                        animatedProgress = progress
                    }
                }
        
        var body: some View {
            VStack(spacing: 16) {
                HStack {
                    Label("Water", systemImage: "drop.fill")
                        .font(.headline)
                    Spacer()
                }
                
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                        .frame(width: 100, height: 100)
                    
                    Circle()
                        .trim(from: 0, to: animatedProgress)
                        .stroke(ringColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 100, height: 100)
                    
                    VStack(spacing: 2) {
                        Text(String(format: "%.1f L", numericIntake))
                            .font(.title2).bold()
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .foregroundColor(ringColor)
                        Text(String(format: "/ %.1f L", numericGoal))
                            .font(.caption)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text("\(percentage) of goal")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(String(format: "%.1f L remaining", remaining))
                    .font(.caption2)
                    .foregroundColor(ringColor)
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 180)
            .background(colorScheme == .dark
                        ? Color(.secondarySystemBackground)
                        : Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.green.opacity(0.3), radius: 8, x: 0, y: 4)
            .onAppear { animateProgress() }
            .onChange(of: progress) { _ in animateProgress() }
            .onTapGesture { onTap() }
        }
    }
    // MARK: - NutritionChartCard
    
    struct NutritionChartCard<Content: View>: View {
        let title: String
        let content: Content
        let colorScheme: ColorScheme
        
        init(title: String, colorScheme: ColorScheme, @ViewBuilder content: () -> Content) {
            self.title = title
            self.content = content()
            self.colorScheme = colorScheme
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                content
            }
            .padding()
            .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
            .cornerRadius(12)
            .shadow(color: Color.green.opacity(0.3), radius: 8, x: 0, y: 4)
            .padding(.horizontal)
        }
    }
    
    // MARK: - Supporting Cards
    
    struct OverallNutritionScoreCard: View {
        let score: Int
        let colorScheme: ColorScheme
        
        private var statusText: String {
            if score >= 80 { return "Excellent" }
            else if score >= 50 { return "Moderate" }
            else { return "Needs Work" }
        }
        
        private var statusColor: Color {
            if score >= 80 { return .green }
            else if score >= 50 { return .yellow }
            else { return .red }
        }
        
        var body: some View {
            HStack {
                Image(systemName: "leaf")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                
                VStack(alignment: .leading) {
                    Text("Overall Nutrition Score")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("\(score)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Text(statusText)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(8)
                    .background(statusColor.opacity(0.9))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()
            .background(Color.green)
            .cornerRadius(12)
            .shadow(color: Color.green.opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }
    
    struct NutritionInsightsCard: View {
        let insights: [String]
        let colorScheme: ColorScheme
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.green)
                    Text("Nutrition Insights")
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
            .background(colorScheme == .dark ? Color(.secondarySystemBackground) : Color.white)
            .cornerRadius(20)
            .shadow(color: Color.green.opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }
    
    // MARK: - Manual Entry
    
    struct ManualNutritionEntryView: View {
        @Environment(\.presentationMode) var presentationMode
        @EnvironmentObject var userProfile: UserProfile
        @EnvironmentObject var healthManager: HealthManager

        @State private var mealName: String = ""
        @State private var calories: String = ""
        @State private var protein: String = ""
        @State private var carbs: String = ""
        @State private var fat: String = ""
        @State private var water: String = ""
        @State private var fiber: String = ""
        
        var body: some View {
            NavigationView {
                Form {
                    Section(header: Text("Meal")) {
                        TextField("Meal Name", text: $mealName)
                    }

                    Section(header: Text("Nutrients")) {
                        TextField("Calories", text: $calories)
                            .keyboardType(.decimalPad)
                        TextField("Protein (g)", text: $protein)
                            .keyboardType(.decimalPad)
                        TextField("Carbs (g)", text: $carbs)
                            .keyboardType(.decimalPad)
                        TextField("Fat (g)", text: $fat)
                            .keyboardType(.decimalPad)
                        TextField("Water (L)", text: $water)
                            .keyboardType(.decimalPad)
                        TextField("Fiber (g)", text: $fiber)
                            .keyboardType(.decimalPad)
                    }

                    Section {
                        HStack {
                            Button("Reset") { resetFields() }
                                .frame(maxWidth: .infinity)

                            Button("Add Meal") { addMeal() }
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .navigationTitle("Add Meal")
                .navigationBarItems(trailing: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                })
                .onAppear {
                    calories = userProfile.caloriesConsumed ?? ""
                    protein = userProfile.proteinIntake ?? ""
                    carbs = userProfile.carbsIntake ?? ""
                    fat = userProfile.fatIntake ?? ""
                    water = userProfile.waterIntake ?? ""
                    fiber = userProfile.fiberIntake ?? ""
                }
            }
        }

        private func resetFields() {
            mealName = ""
            calories = ""
            protein = ""
            carbs = ""
            fat = ""
            water = ""
            fiber = ""
        }

        private func addMeal() {
            func add(_ current: String?, with value: String) -> String {
                let total = (Double(current ?? "0") ?? 0) + (Double(value) ?? 0)
                return String(format: "%.0f", total)
            }

            userProfile.caloriesConsumed = add(userProfile.caloriesConsumed, with: calories)
            userProfile.proteinIntake = add(userProfile.proteinIntake, with: protein)
            userProfile.carbsIntake = add(userProfile.carbsIntake, with: carbs)
            userProfile.fatIntake = add(userProfile.fatIntake, with: fat)
            userProfile.waterIntake = add(userProfile.waterIntake, with: water)
            userProfile.fiberIntake = add(userProfile.fiberIntake, with: fiber)

            healthManager.saveDailyNutritionEntry(
                calories: Double(calories),
                protein: Double(protein),
                carbs: Double(carbs),
                fat: Double(fat),
                water: Double(water),
                fiber: Double(fiber)
            )

            if !mealName.isEmpty {
                userProfile.meals.append(mealName)
            }

            presentationMode.wrappedValue.dismiss()
        }
    }

    // MARK: - Metric Detail

    enum MetricType: String, Identifiable {
        case calories, protein, carbs, fat, water

        var id: String { rawValue }

        var title: String {
            switch self {
            case .calories: return "Calories"
            case .protein:  return "Protein"
            case .carbs:    return "Carbs"
            case .fat:      return "Fat"
            case .water:    return "Water"
            }
        }

        var unit: String {
            switch self {
            case .calories: return "kcal"
            case .water:    return "L"
            default:        return "g"
            }
        }

        var step: Double {
            switch self {
            case .calories: return 50
            case .water:    return 0.1
            default:        return 1
            }
        }

        var format: String { self == .water ? "%.1f" : "%.0f" }
    }

    struct MetricDetailView: View {
        let metric: MetricType
        @EnvironmentObject var userProfile: UserProfile
        @EnvironmentObject var healthManager: HealthManager
        @Environment(\.presentationMode) var presentationMode
        @Environment(\.colorScheme) var colorScheme

        @State private var amount: Double = 0

        var body: some View {
            NavigationView {
                VStack(spacing: 20) {
                    metricCard
                        .frame(height: 180)

                    Stepper(value: $amount, in: 0...10000, step: metric.step) {
                        Text("Add \(String(format: metric.format, amount)) \(metric.unit)")
                    }
                    .padding()

                    Button("Save") {
                        addAmount()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.bottom)

                    Spacer()
                }
                .navigationTitle(metric.title)
                .navigationBarItems(trailing: Button("Close") { presentationMode.wrappedValue.dismiss() })
            }
        }

        private var metricCard: some View {
            switch metric {
            case .calories:
                let intake = intakeValue(healthManager.caloriesConsumed, fallback: userProfile.caloriesConsumed)
                return AnyView(NutritionRingCard(title: "Calories", icon: "flame.fill", value: String(format: "%.0f", intake), goal: userProfile.caloriesGoal ?? "0 cal", percentage: percent(intake: intake, goal: userProfile.caloriesGoal), colorScheme: colorScheme))
            case .protein:
                let intake = intakeValue(healthManager.proteinIntake, fallback: userProfile.proteinIntake)
                return AnyView(NutritionRingCard(title: "Protein", icon: "bolt.fill", value: String(format: "%.0f", intake), goal: userProfile.proteinGoal ?? "0 g", percentage: percent(intake: intake, goal: userProfile.proteinGoal), colorScheme: colorScheme))
            case .carbs:
                let intake = intakeValue(healthManager.carbsIntake, fallback: userProfile.carbsIntake)
                return AnyView(NutritionRingCard(title: "Carbs", icon: "leaf.fill", value: String(format: "%.0f", intake), goal: userProfile.carbsGoal ?? "0 g", percentage: percent(intake: intake, goal: userProfile.carbsGoal), colorScheme: colorScheme))
            case .fat:
                let intake = intakeValue(healthManager.fatIntake, fallback: userProfile.fatIntake)
                return AnyView(NutritionRingCard(title: "Fat", icon: "drop.fill", value: String(format: "%.0f", intake), goal: userProfile.fatGoal ?? "0 g", percentage: percent(intake: intake, goal: userProfile.fatGoal), colorScheme: colorScheme))
            case .water:
                let intake = healthManager.waterIntake ?? Double(userProfile.waterIntake ?? "0") ?? 0
                let pct = {
                    let goal = Double(userProfile.waterGoal ?? "0") ?? 1
                    return "\(Int((intake / goal) * 100))%"
                }()
                return AnyView(WaterIntakeCard(intake: String(format: "%.1f", intake), goal: userProfile.waterGoal ?? "0 L", percentage: pct, colorScheme: colorScheme))
            }
        }

        private var currentValue: Double {
            switch metric {
            case .calories:
                return intakeValue(healthManager.caloriesConsumed, fallback: userProfile.caloriesConsumed)
            case .protein:
                return intakeValue(healthManager.proteinIntake, fallback: userProfile.proteinIntake)
            case .carbs:
                return intakeValue(healthManager.carbsIntake, fallback: userProfile.carbsIntake)
            case .fat:
                return intakeValue(healthManager.fatIntake, fallback: userProfile.fatIntake)
            case .water:
                return healthManager.waterIntake ?? Double(userProfile.waterIntake ?? "0") ?? 0
            }
        }

        private var currentFormatted: String {
            "\(String(format: metric.format, currentValue)) \(metric.unit)"
        }

        private func addAmount() {
            let newValue = currentValue + amount
            switch metric {
            case .calories:
                userProfile.caloriesConsumed = String(format: "%.0f", newValue)
                healthManager.saveDailyNutritionEntry(calories: amount, protein: nil, carbs: nil, fat: nil, water: nil, fiber: nil)
            case .protein:
                userProfile.proteinIntake = String(format: "%.0f", newValue)
                healthManager.saveDailyNutritionEntry(calories: nil, protein: amount, carbs: nil, fat: nil, water: nil, fiber: nil)
            case .carbs:
                userProfile.carbsIntake = String(format: "%.0f", newValue)
                healthManager.saveDailyNutritionEntry(calories: nil, protein: nil, carbs: amount, fat: nil, water: nil, fiber: nil)
            case .fat:
                userProfile.fatIntake = String(format: "%.0f", newValue)
                healthManager.saveDailyNutritionEntry(calories: nil, protein: nil, carbs: nil, fat: amount, water: nil, fiber: nil)
            case .water:
                userProfile.waterIntake = String(format: "%.1f", newValue)
                healthManager.saveDailyNutritionEntry(calories: nil, protein: nil, carbs: nil, fat: nil, water: amount, fiber: nil)
            }
        }
    }
    
    
    // MARK: - SetNutritionGoalsView
    
    struct SetNutritionGoalsView: View {
        @EnvironmentObject var userProfile: UserProfile
        @Environment(\.presentationMode) var presentationMode
        
        @State private var calorieGoal: String = ""
        @State private var proteinGoal: String = ""
        @State private var carbGoal: String = ""
        @State private var fatGoal: String = ""
        @State private var waterGoal: String = ""
        @State private var fiberGoal: String = ""
        
        var body: some View {
            NavigationView {
                Form {
                    Section(header: Text("Daily Goals")) {
                        TextField("Calories", text: $calorieGoal).keyboardType(.decimalPad)
                        TextField("Protein (g)", text: $proteinGoal).keyboardType(.decimalPad)
                        TextField("Carbs (g)", text: $carbGoal).keyboardType(.decimalPad)
                        TextField("Fat (g)", text: $fatGoal).keyboardType(.decimalPad)
                        TextField("Water (L)", text: $waterGoal).keyboardType(.decimalPad)
                        TextField("Fiber (g)", text: $fiberGoal).keyboardType(.decimalPad)
                    }
                }
                .navigationTitle("Set Nutrition Goals")
                .navigationBarItems(trailing: Button("Save") {
                    userProfile.caloriesGoal = calorieGoal
                    userProfile.proteinGoal = proteinGoal
                    userProfile.carbsGoal = carbGoal
                    userProfile.fatGoal = fatGoal
                    userProfile.waterGoal = waterGoal
                    userProfile.fiberGoal = fiberGoal
                    userProfile.saveGoalsToFirestore()
                    presentationMode.wrappedValue.dismiss()
                })
                .onAppear {
                    calorieGoal = userProfile.caloriesGoal ?? ""
                    proteinGoal = userProfile.proteinGoal ?? ""
                    carbGoal = userProfile.carbsGoal ?? ""
                    fatGoal = userProfile.fatGoal ?? ""
                    waterGoal = userProfile.waterGoal ?? ""
                    fiberGoal = userProfile.fiberGoal ?? ""
                }
            }
        }
    }
