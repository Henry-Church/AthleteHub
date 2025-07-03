// NutritionView.swift

import SwiftUI

struct NutritionView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var userProfile: UserProfile
    @EnvironmentObject var healthManager: HealthManager


    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Nutrition Dashboard")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
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
