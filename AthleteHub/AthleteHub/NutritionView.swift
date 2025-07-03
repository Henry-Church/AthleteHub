// NutritionView.swift

import SwiftUI

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

                // Score & Insights
                OverallNutritionScoreCard(score: overallNutritionScore, colorScheme: colorScheme)
                    .padding(.horizontal)

                NutritionInsightsCard(insights: generateNutritionInsights(), colorScheme: colorScheme)
                    .padding(.horizontal)

                // Macronutrient and Water Cards
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    NutritionRingCard(
                        title: "Calories",
                        icon: "flame.fill",
                        value: userProfile.caloriesConsumed ?? "0",
                        goal: userProfile.caloriesGoal ?? "0 cal",
                        percentage: userProfile.caloriesPercentage ?? "0%",
                        ringColor: .orange,
                        colorScheme: colorScheme
                    )

                    NutritionRingCard(
                        title: "Protein",
                        icon: "bolt.fill",
                        value: userProfile.proteinIntake ?? "0",
                        goal: userProfile.proteinGoal ?? "0 g",
                        percentage: userProfile.proteinPercentage ?? "0%",
                        ringColor: .red,
                        colorScheme: colorScheme
                    )

                    NutritionRingCard(
                        title: "Carbs",
                        icon: "leaf.fill",
                        value: userProfile.carbsIntake ?? "0",
                        goal: userProfile.carbsGoal ?? "0 g",
                        percentage: userProfile.carbsPercentage ?? "0%",
                        ringColor: .yellow,
                        colorScheme: colorScheme
                    )

                    NutritionRingCard(
                        title: "Fat",
                        icon: "chart.pie.fill",
                        value: userProfile.fatIntake ?? "0",
                        goal: userProfile.fatGoal ?? "0 g",
                        percentage: userProfile.fatPercentage ?? "0%",
                        ringColor: .purple,
                        colorScheme: colorScheme
                    )
                }
                .padding(.horizontal)

                WaterIntakeCard(
                    intake: userProfile.waterIntake ?? "0",
                    goal: userProfile.waterGoal ?? "0 L",
                    percentage: userProfile.waterPercentage ?? "0%",
                    colorScheme: colorScheme
                )
                .padding(.horizontal)

                // Trends
                NutritionChartCard(title: "7-Day Nutrition Trends", colorScheme: colorScheme) {
                    if userProfile.dailyIntakeTrendsAvailable {
                        // TODO: Insert actual chart view
                    } else {
                        Text("Data not available")
                            .foregroundColor(.secondary)
                            .frame(height: 150)
                            .frame(maxWidth: .infinity)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                    }
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

struct NutritionRingCard: View {
    let title: String
    let icon: String
    let value: String
    let goal: String
    let percentage: String
    let ringColor: Color
    let colorScheme: ColorScheme

    @State private var animatedProgress: Double = 0.0

    private var progress: Double {
        (Double(percentage.replacingOccurrences(of: "%", with: "")) ?? 0) / 100.0
    }

    var body: some View {
        VStack(spacing: 16) {
            // Title
            HStack {
                Label(title, systemImage: icon)
                    .font(.headline)
                Spacer()
            }

            // Circular ring
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                    .frame(width: 100, height: 100)

                Circle()
                    .trim(from: 0, to: CGFloat(animatedProgress))
                    .stroke(ringColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 100, height: 100)

                VStack {
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("/\(goal)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Percentage text
            Text("\(percentage) of daily target")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .frame(height: 180)
        .background(
            colorScheme == .dark
            ? Color(.secondarySystemBackground)
            : Color(.systemBackground)
        )
        .cornerRadius(16)
        .shadow(color: ringColor.opacity(0.3), radius: 8, x: 0, y: 4)
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animatedProgress = progress
            }
        }
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

import SwiftUI

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
        userProfile.saveToFirestore()
        presentationMode.wrappedValue.dismiss()
    }
}

