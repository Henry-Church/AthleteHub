


import SwiftUI

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
    
    private var overallNutritionScore: Int {
        let percentages = [
            userProfile.caloriesPercentage,
            userProfile.proteinPercentage,
            userProfile.carbsPercentage,
            userProfile.fatPercentage,
            userProfile.waterPercentage,
            userProfile.fiberPercentage
        ]
        let values = percentages.compactMap { percentage(from: $0) }
        guard !values.isEmpty else { return 0 }
        return Int(values.reduce(0, +) / Double(values.count))
    }
    
    private func generateNutritionInsights() -> [String] {
        func message(for percent: Double, metric: String) -> String {
            if percent >= 100 { return "\(metric.capitalized) goal met." }
            return "\(Int(percent))% of \(metric) goal."
        }
        
        var insights: [String] = []
        if let p = percentage(from: userProfile.caloriesPercentage) {
            insights.append(message(for: p, metric: "calorie"))
        } else {
            insights.append("No calorie data yet.")
        }
        if let p = percentage(from: userProfile.proteinPercentage) {
            insights.append(message(for: p, metric: "protein"))
        }
        if let p = percentage(from: userProfile.waterPercentage) {
            insights.append(message(for: p, metric: "water"))
        }
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
                        value:      "\(userProfile.caloriesConsumed  ?? "0") kcal",
                        goal:       "\(userProfile.caloriesGoal      ?? "0") kcal",
                        percentage: userProfile.caloriesPercentage  ?? "0%",
                        colorScheme: colorScheme
                    ) {
                        activeMetric = .calories
                        showingManualEntry = true
                    }

                    // — Protein
                    NutritionRingCard(
                        title:      "Protein",
                        icon:       "bolt.fill",
                        value:      "\(userProfile.proteinIntake    ?? "0") g",
                        goal:       "\(userProfile.proteinGoal      ?? "0") g",
                        percentage: userProfile.proteinPercentage  ?? "0%",
                        colorScheme: colorScheme
                    ) {
                        activeMetric = .protein
                        showingManualEntry = true
                    }

                    // — Carbs
                    NutritionRingCard(
                        title:      "Carbs",
                        icon:       "leaf.fill",
                        value:      "\(userProfile.carbsIntake      ?? "0") g",
                        goal:       "\(userProfile.carbsGoal        ?? "0") g",
                        percentage: userProfile.carbsPercentage    ?? "0%",
                        colorScheme: colorScheme
                    ) {
                        activeMetric = .carbs
                        showingManualEntry = true
                    }

                    // — Fat
                    NutritionRingCard(
                        title:      "Fat",
                        icon:       "drop.fill",
                        value:      "\(userProfile.fatIntake        ?? "0") g",
                        goal:       "\(userProfile.fatGoal          ?? "0") g",
                        percentage: userProfile.fatPercentage      ?? "0%",
                        colorScheme: colorScheme
                    ) {
                        activeMetric = .fat
                        showingManualEntry = true
                    }
                }
                .padding(.horizontal)

                WaterIntakeCard(
                    intake:      userProfile.waterIntake  ?? "0",
                    goal:        userProfile.waterGoal    ?? "0",
                    percentage:  userProfile.waterPercentage ?? "0%",
                    colorScheme: colorScheme
                ) {
                    activeMetric = .water
                    showingManualEntry = true
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
                ManualNutritionEntryView().environmentObject(userProfile)
            }
            .sheet(item: $activeMetric) { metric in
                MetricDetailView(metric: metric).environmentObject(userProfile)
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
        
        var body: some View {
            VStack(spacing: 16) {
                HStack {
                    Label(title, systemImage: icon)
                        .font(.headline)
                    Spacer()
                }
                
                ZStack {
                    // background track
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                        .frame(width: 100, height: 100)
                    
                    // progress arc
                    Circle()
                        .trim(from: 0, to: animatedProgress)
                        .stroke(ringColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 100, height: 100)
                    
                    // center text
                    VStack(spacing: 2) {
                        Text(value)
                            .font(.title2).bold()
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .foregroundColor(ringColor)
                        Text("/ \(goal)")
                            .font(.caption)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .foregroundColor(.secondary)
                    }
                }
                
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
            .onAppear {
                withAnimation(.easeOut(duration: 1.2)) {
                    animatedProgress = progress
                }
            }
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
            .onAppear {
                withAnimation(.easeOut(duration: 1.2)) {
                    animatedProgress = progress
                }
            }
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
        
        @State private var calories: String = ""
        @State private var protein: String = ""
        @State private var carbs: String = ""
        @State private var fat: String = ""
        @State private var water: String = ""
        @State private var fiber: String = ""
        
        var body: some View {
            NavigationView {
                ScrollView {
                    VStack(spacing: 16) {
                        Group {
                            TextField("Calories", text: $calories)
                            TextField("Protein (g)", text: $protein)
                            TextField("Carbs (g)", text: $carbs)
                            TextField("Fat (g)", text: $fat)
                            TextField("Water (L)", text: $water)
                            TextField("Fiber (g)", text: $fiber)
                        }
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button(action: saveEntry) {
                            Text("Save")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .padding(.top, 10)
                    }
                    .padding()
                }
                .navigationTitle("Manual Nutrition Entry")
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
        
        private func saveEntry() {
            userProfile.caloriesConsumed = calories
            userProfile.proteinIntake = protein
            userProfile.carbsIntake = carbs
            userProfile.fatIntake = fat
            userProfile.waterIntake = water
            userProfile.fiberIntake = fiber
            userProfile.loadFromFirestore()
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    // MARK: - MetricType Enum
    
    enum MetricType: String, Identifiable {
        case calories
        case protein
        case carbs
        case fat
        case water
        
        var id: String { rawValue }
        
        var title: String {
            switch self {
            case .calories: return "Calories"
            case .protein:  return "Protein"
            case .carbs:    return "Carbohydrates"
            case .fat:      return "Fat"
            case .water:    return "Water"
            }
        }
    }
    
    // MARK: - MetricDetailView
    
    struct MetricDetailView: View {
        let metric: MetricType
        @EnvironmentObject var userProfile: UserProfile
        @Environment(\.presentationMode) var presentationMode
        @Environment(\.colorScheme) var colorScheme
        
        @State private var value: String = ""
        
        var body: some View {
            NavigationView {
                VStack(spacing: 20) {
                    metricCard
                        .frame(height: 180)
                    
                    TextField("Enter \(metric.title)", text: $value)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    Button("Save") {
                        save()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .padding()
                    
                    Spacer()
                }
                .navigationTitle(metric.title)
                .navigationBarItems(trailing: Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                })
                .onAppear { value = currentValue }
            }
        }
        
        private var metricCard: some View {
            switch metric {
            case .calories:
                return AnyView(NutritionRingCard(title: "Calories", icon: "flame.fill", value: userProfile.caloriesConsumed ?? "0", goal: userProfile.caloriesGoal ?? "0 cal", percentage: userProfile.caloriesPercentage ?? "0%", colorScheme: colorScheme))
            case .protein:
                return AnyView(NutritionRingCard(title: "Protein", icon: "bolt.fill", value: userProfile.proteinIntake ?? "0", goal: userProfile.proteinGoal ?? "0 g", percentage: userProfile.proteinPercentage ?? "0%", colorScheme: colorScheme))
            case .carbs:
                return AnyView(NutritionRingCard(title: "Carbohydrates", icon: "leaf.fill", value: userProfile.carbsIntake ?? "0", goal: userProfile.carbsGoal ?? "0 g", percentage: userProfile.carbsPercentage ?? "0%", colorScheme: colorScheme))
            case .fat:
                return AnyView(NutritionRingCard(title: "Fat", icon: "chart.pie.fill", value: userProfile.fatIntake ?? "0", goal: userProfile.fatGoal ?? "0 g", percentage: userProfile.fatPercentage ?? "0%", colorScheme: colorScheme))
            case .water:
                return AnyView(WaterIntakeCard(intake: userProfile.waterIntake ?? "0", goal: userProfile.waterGoal ?? "0 L", percentage: userProfile.waterPercentage ?? "0%", colorScheme: colorScheme))
            }
        }
        
        private var currentValue: String {
            switch metric {
            case .calories: return userProfile.caloriesConsumed ?? ""
            case .protein:  return userProfile.proteinIntake ?? ""
            case .carbs:    return userProfile.carbsIntake ?? ""
            case .fat:      return userProfile.fatIntake ?? ""
            case .water:    return userProfile.waterIntake ?? ""
            }
        }
        
        private func save() {
            switch metric {
            case .calories: userProfile.caloriesConsumed = value
            case .protein:  userProfile.proteinIntake = value
            case .carbs:    userProfile.carbsIntake = value
            case .fat:      userProfile.fatIntake = value
            case .water:    userProfile.waterIntake = value
            }
            userProfile.loadFromFirestore()
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
                    userProfile.loadFromFirestore()
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
