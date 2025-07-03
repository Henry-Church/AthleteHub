import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var userProfile: UserProfile
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var healthManager: HealthManager


    var cardBackground: Color {
        colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground)
    }

    var sectionBackground: Color {
        colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemGray6)
    }

    var calculatedAge: Int {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        if let dobDate = formatter.date(from: userProfile.birthDate) {
            return Calendar.current.dateComponents([.year], from: dobDate, to: Date()).year ?? 0
        }
        return 0
    }

    private func progress(from percentage: String?) -> Double? {
        guard let text = percentage?.replacingOccurrences(of: "%", with: ""),
              let value = Double(text) else { return nil }
        return min(value / 100.0, 1.0)
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hey, \(userProfile.name)!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("Here’s your personalized dashboard")
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                        StatCard(title: "Age", value: "\(calculatedAge)", color: .blue, cardBackground: cardBackground)
                        StatCard(title: "BMI", value: String(format: "%.1f", userProfile.bmi), color: .purple, cardBackground: cardBackground)
                        StatCard(title: "Height", value: "\(Int(userProfile.height)) cm", color: .green, cardBackground: cardBackground)
                        StatCard(title: "Weight", value: "\(Int(userProfile.weight)) kg", color: .orange, cardBackground: cardBackground)
                    }
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Daily Metrics")
                            .font(.headline)
                            .padding(.horizontal)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            DashboardMetricCard(
                                icon: "flame",
                                value: userProfile.caloriesConsumed ?? "--",
                                label: "Calories",
                                sublabel: userProfile.caloriesStatus ?? "",
                                progress: progress(from: userProfile.caloriesPercentage),
                                colorScheme: colorScheme,
                                cardBackground: cardBackground)
                            DashboardMetricCard(
                                icon: "drop.fill",
                                value: userProfile.waterIntake ?? "--",
                                label: "Water Intake",
                                sublabel: userProfile.waterStatus ?? "",
                                progress: progress(from: userProfile.waterPercentage),
                                colorScheme: colorScheme,
                                cardBackground: cardBackground)
                            DashboardMetricCard(
                                icon: "fork.knife",
                                value: userProfile.proteinIntake ?? "--",
                                label: "Protein",
                                sublabel: userProfile.proteinStatus ?? "",
                                progress: progress(from: userProfile.proteinPercentage),
                                colorScheme: colorScheme,
                                cardBackground: cardBackground)
                            DashboardMetricCard(
                                icon: "leaf.fill",
                                value: userProfile.carbsIntake ?? "--",
                                label: "Carbs",
                                sublabel: userProfile.carbsStatus ?? "",
                                progress: progress(from: userProfile.carbsPercentage),
                                colorScheme: colorScheme,
                                cardBackground: cardBackground)
                        }
                        .padding(.horizontal)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recent Activity")
                            .font(.headline)
                            .padding(.horizontal)

                        if userProfile.trainingLog.isEmpty {
                            VStack {
                                Spacer()
                                Text("No training sessions yet")
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .frame(height: 150)
                            .frame(maxWidth: .infinity)
                            .background(sectionBackground)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                            .padding(.horizontal)
                        } else {
                            ForEach(userProfile.trainingLog, id: \.self) { session in
                                HStack {
                                    Image(systemName: "figure.walk")
                                    Text(session)
                                    Spacer()
                                }
                                .padding()
                                .background(cardBackground)
                                .cornerRadius(8)
                                .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .frame(minHeight: geometry.size.height)
                .padding(.vertical)
            }
            .background(colorScheme == .dark ? Color.black : Color(.systemGroupedBackground))
            .ignoresSafeArea(edges: .bottom)
        }
    }
}

struct DashboardMetricCard: View {
    let icon: String
    let value: String
    let label: String
    let sublabel: String
    let progress: Double?
    let colorScheme: ColorScheme
    let cardBackground: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.primary)
                Spacer()
            }

            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            if !sublabel.isEmpty {
                Text(sublabel)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            if let progress = progress {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .frame(height: 6)
                    .padding(.top, 4)

                Text(String(format: "%.0f%%", progress * 100))
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .frame(height: 120)
        .background(cardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    let cardBackground: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(height: 80)
        .frame(maxWidth: .infinity)
        .background(cardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}
