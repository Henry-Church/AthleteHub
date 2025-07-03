// NutritionView.swift

import SwiftUI

struct NutritionView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var userProfile: UserProfile
    @EnvironmentObject var healthManager: HealthManager

    @State private var showingSetGoals = false
    @State private var showingManualEntry = false

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
            if percent >= 100 { return "\(metric) goal met." }
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

                // Charts at Top
                NutritionChartCard(title: "Overall Nutrition Score", colorScheme: colorScheme) {
                    if userProfile.dailyIntakeTrendsAvailable {
                        // Insert real chart here
                    } else {
                        Text("Data not available")
                            .foregroundColor(.secondary)
                            .frame(height: 150)
                            .frame(maxWidth: .infinity)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                    }
                }

                NutritionChartCard(title: "7-Day Nutrition Trends", colorScheme: colorScheme) {
                    if userProfile.dailyIntakeTrendsAvailable {
                        // Insert real chart here
                    } else {
                        Text("Data not available")
                            .foregroundColor(.secondary)
                            .frame(height: 150)
                            .frame(maxWidth: .infinity)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                    }
                }

                // Metric Cards Below
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    NutritionMetricCard(
                        title: "Calories",
                        value: userProfile.caloriesConsumed ?? "0",
                        goal: userProfile.caloriesGoal ?? "0 cal",
                        percentage: userProfile.caloriesPercentage ?? "0%",
                        status: userProfile.caloriesStatus ?? "Data not available",
                        colorScheme: colorScheme
                    )

                    NutritionMetricCard(
                        title: "Protein",
                        value: userProfile.proteinIntake ?? "0",
                        goal: userProfile.proteinGoal ?? "0 g",
                        percentage: userProfile.proteinPercentage ?? "0%",
                        status: userProfile.proteinStatus ?? "Data not available",
                        colorScheme: colorScheme
                    )

                    NutritionMetricCard(
                        title: "Carbs",
                        value: userProfile.carbsIntake ?? "0",
                        goal: userProfile.carbsGoal ?? "0 g",
                        percentage: userProfile.carbsPercentage ?? "0%",
                        status: userProfile.carbsStatus ?? "Data not available",
                        colorScheme: colorScheme
                    )

                    NutritionMetricCard(
                        title: "Fat",
                        value: userProfile.fatIntake ?? "0",
                        goal: userProfile.fatGoal ?? "0 g",
                        percentage: userProfile.fatPercentage ?? "0%",
                        status: userProfile.fatStatus ?? "Data not available",
                        colorScheme: colorScheme
                    )

                    NutritionMetricCard(
                        title: "Water",
                        value: userProfile.waterIntake ?? "0",
                        goal: userProfile.waterGoal ?? "0 L",
                        percentage: userProfile.waterPercentage ?? "0%",
                        status: userProfile.waterStatus ?? "Data not available",
                        colorScheme: colorScheme
                    )

                    NutritionMetricCard(
                        title: "Fiber",
                        value: userProfile.fiberIntake ?? "0",
                        goal: userProfile.fiberGoal ?? "0 g",
                        percentage: userProfile.fiberPercentage ?? "0%",
                        status: userProfile.fiberStatus ?? "Data not available",
                        colorScheme: colorScheme
                    )
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color.white.edgesIgnoringSafeArea(.all))
        .sheet(isPresented: $showingSetGoals) {
            SetNutritionGoalsView()
                .environmentObject(userProfile)
        }
        .sheet(isPresented: $showingManualEntry) {
            ManualNutritionEntryView()
                .environmentObject(userProfile)
        }
    }
}

struct NutritionMetricCard: View {
    let title: String
    let value: String
    let goal: String
    let percentage: String
    let status: String
    let colorScheme: ColorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text(status)
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(10)
            }

            HStack(alignment: .firstTextBaseline) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                Text("/\(goal)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            ProgressView(value: Double(percentage.dropLast()) ?? 0, total: 100)
                .accentColor(.black)

            Text("\(percentage) of daily target")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
        .cornerRadius(12)
        .shadow(color: Color.green.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

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
                    TextField("Calories", text: $calorieGoal)
                        .keyboardType(.decimalPad)
                    TextField("Protein (g)", text: $proteinGoal)
                        .keyboardType(.decimalPad)
                    TextField("Carbs (g)", text: $carbGoal)
                        .keyboardType(.decimalPad)
                    TextField("Fat (g)", text: $fatGoal)
                        .keyboardType(.decimalPad)
                    TextField("Water (L)", text: $waterGoal)
                        .keyboardType(.decimalPad)
                    TextField("Fiber (g)", text: $fiberGoal)
                        .keyboardType(.decimalPad)
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
                userProfile.saveToFirestore()
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

struct ManualNutritionEntryView: View {
    @EnvironmentObject var userProfile: UserProfile
    @Environment(\.presentationMode) var presentationMode

    @State private var calories: String = ""
    @State private var protein: String = ""
    @State private var carbs: String = ""
    @State private var fat: String = ""
    @State private var water: String = ""
    @State private var fiber: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Today's Intake")) {
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
            }
            .navigationTitle("Manual Nutrition Entry")
            .navigationBarItems(trailing: Button("Save") {
                userProfile.caloriesConsumed = calories
                userProfile.proteinIntake = protein
                userProfile.carbsIntake = carbs
                userProfile.fatIntake = fat
                userProfile.waterIntake = water
                userProfile.fiberIntake = fiber
                userProfile.saveToFirestore()
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
}
