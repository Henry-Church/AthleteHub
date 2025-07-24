import SwiftUI
import Charts

struct DashboardView: View {
    @EnvironmentObject var userProfile: UserProfile
    @EnvironmentObject var coachSelection: CoachSelection
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var healthManager: HealthManager
    
    @State private var selectedTimeframe: TimeFrame = .week
    @State private var showingAchievements = false
    
    enum TimeFrame: String, CaseIterable {
        case day = "Today"
        case week = "Week"
        case month = "Month"
    }

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
    
    private var overallScore: Double {
        let training = healthManager.calculateOverallTrainingScore()
        let recovery = healthManager.calculateOverallRecoveryScore()
        return (training + recovery) / 2
    }

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 24) {
                    // Header Section with Overall Score
                    headerSection
                    
                    // Performance Ring Section
                    performanceRingsSection
                    
                    // Quick Stats Grid
                    quickStatsSection
                    
                    // Training Trends Chart
                    trainingTrendsSection
                    
                    // Health Metrics Overview
                    healthMetricsSection
                    
                    // Recent Achievements
                    achievementsSection
                    
                    // Weekly Summary
                    weeklySummarySection
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(colorScheme == .dark ? Color.black : Color(.systemGroupedBackground))
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAchievements.toggle() }) {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(.yellow)
                    }
                }
            }
            .sheet(isPresented: $showingAchievements) {
                AchievementsView()
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hello, \(userProfile.name.components(separatedBy: " ").first ?? "Athlete")!")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Ready to crush your goals today?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                // Overall Score Circle
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: overallScore / 100)
                        .stroke(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1.0), value: overallScore)
                    
                    VStack(spacing: 2) {
                        Text("\(Int(overallScore))")
                            .font(.title3)
                            .fontWeight(.bold)
                        Text("Score")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(20)
        .background(cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Performance Rings
    private var performanceRingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's Performance")
                .font(.headline)
                .padding(.horizontal, 4)
            
            HStack(spacing: 20) {
                PerformanceRing(
                    title: "Training",
                    value: Int(healthManager.calculateOverallTrainingScore()),
                    maxValue: 100,
                    color: .orange,
                    icon: "figure.run"
                )
                
                PerformanceRing(
                    title: "Recovery",
                    value: Int(healthManager.calculateOverallRecoveryScore()),
                    maxValue: 100,
                    color: .green,
                    icon: "bed.double.fill"
                )
                
                PerformanceRing(
                    title: "Nutrition",
                    value: Int((progress(from: userProfile.caloriesPercentage) ?? 0) * 100),
                    maxValue: 100,
                    color: .blue,
                    icon: "fork.knife"
                )
            }
        }
        .padding(20)
        .background(cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Quick Stats
    private var quickStatsSection: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
            QuickStatCard(
                title: "Steps",
                value: "\(Int(healthManager.steps ?? 0))",
                subtitle: "of \(Int(healthManager.dailyGoals["Steps"] ?? 10000))",
                icon: "figure.walk",
                color: .green,
                progress: (healthManager.steps ?? 0) / (healthManager.dailyGoals["Steps"] ?? 10000)
            )
            
            QuickStatCard(
                title: "Calories",
                value: "\(Int(healthManager.totalCalories ?? 0))",
                subtitle: "burned",
                icon: "flame.fill",
                color: .orange,
                progress: (healthManager.totalCalories ?? 0) / (healthManager.dailyGoals["Calories"] ?? 2000)
            )
            
            QuickStatCard(
                title: "Sleep",
                value: String(format: "%.1fh", (healthManager.sleepDuration ?? 0) / 60),
                subtitle: "last night",
                icon: "moon.fill",
                color: .purple,
                progress: (healthManager.sleepDuration ?? 0) / (8 * 60) // 8 hours in minutes
            )
            
            QuickStatCard(
                title: "Water",
                value: "\(userProfile.waterIntake ?? "0")L",
                subtitle: "of \(userProfile.waterGoal ?? "2.5")L",
                icon: "drop.fill",
                color: .blue,
                progress: progress(from: userProfile.waterPercentage) ?? 0
            )
        }
    }
    
    // MARK: - Training Trends
    private var trainingTrendsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Training Trends")
                    .font(.headline)
                Spacer()
                Picker("Timeframe", selection: $selectedTimeframe) {
                    ForEach(TimeFrame.allCases, id: \.self) { timeframe in
                        Text(timeframe.rawValue).tag(timeframe)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 200)
            }
            .padding(.horizontal, 4)
            
            TrainingTrendChart(scores: healthManager.lastSevenScoresFilled)
                .frame(height: 200)
        }
        .padding(20)
        .background(cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Health Metrics
    private var healthMetricsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Health Metrics")
                .font(.headline)
                .padding(.horizontal, 4)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                HealthMetricCard(
                    title: "Heart Rate",
                    value: "\(Int(healthManager.restingHeartRate ?? 0))",
                    unit: "bpm",
                    icon: "heart.fill",
                    color: .red,
                    trend: .stable
                )
                
                HealthMetricCard(
                    title: "HRV",
                    value: "\(Int(healthManager.hrv ?? 0))",
                    unit: "ms",
                    icon: "waveform.path.ecg",
                    color: .green,
                    trend: .up
                )
                
                HealthMetricCard(
                    title: "VO2 Max",
                    value: String(format: "%.1f", healthManager.vo2Max ?? 0),
                    unit: "ml/kg/min",
                    icon: "lungs.fill",
                    color: .blue,
                    trend: .up
                )
            }
        }
        .padding(20)
        .background(cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Achievements
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Achievements")
                    .font(.headline)
                Spacer()
                Button("View All") {
                    showingAchievements = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            .padding(.horizontal, 4)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    AchievementBadge(
                        title: "Step Master",
                        description: "10,000 steps",
                        icon: "figure.walk",
                        color: .green,
                        isUnlocked: (healthManager.steps ?? 0) >= 10000
                    )
                    
                    AchievementBadge(
                        title: "Hydration Hero",
                        description: "Daily water goal",
                        icon: "drop.fill",
                        color: .blue,
                        isUnlocked: (progress(from: userProfile.waterPercentage) ?? 0) >= 1.0
                    )
                    
                    AchievementBadge(
                        title: "Sleep Champion",
                        description: "8+ hours sleep",
                        icon: "moon.fill",
                        color: .purple,
                        isUnlocked: (healthManager.sleepDuration ?? 0) >= 480 // 8 hours in minutes
                    )
                    
                    AchievementBadge(
                        title: "Calorie Crusher",
                        description: "Daily calorie goal",
                        icon: "flame.fill",
                        color: .orange,
                        isUnlocked: (progress(from: userProfile.caloriesPercentage) ?? 0) >= 1.0
                    )
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(20)
        .background(cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Weekly Summary
    private var weeklySummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("This Week's Summary")
                .font(.headline)
                .padding(.horizontal, 4)
            
            VStack(spacing: 12) {
                WeeklySummaryRow(
                    title: "Workouts Completed",
                    value: "\(healthManager.recentWorkouts.count)",
                    icon: "figure.strengthtraining.traditional",
                    color: .orange
                )
                
                WeeklySummaryRow(
                    title: "Average Training Score",
                    value: "\(Int(healthManager.lastSevenScores.map { $0.score }.reduce(0, +) / max(healthManager.lastSevenScores.count, 1)))",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green
                )
                
                WeeklySummaryRow(
                    title: "Total Distance",
                    value: String(format: "%.1f km", (healthManager.weeklyDistance ?? 0) / 1000),
                    icon: "location.fill",
                    color: .blue
                )
                
                WeeklySummaryRow(
                    title: "Active Hours",
                    value: String(format: "%.1fh", healthManager.weeklyHours ?? 0),
                    icon: "clock.fill",
                    color: .purple
                )
            }
        }
        .padding(20)
        .background(cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
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
