import SwiftUI
import Charts

// MARK: - Performance Ring Component
struct PerformanceRing: View {
    let title: String
    let value: Int
    let maxValue: Int
    let color: Color
    let icon: String
    
    private var progress: Double {
        Double(value) / Double(maxValue)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 6)
                    .frame(width: 70, height: 70)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 70, height: 70)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: progress)
                
                VStack(spacing: 2) {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(color)
                    Text("\(value)")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
            }
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Quick Stat Card
struct QuickStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    let progress: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 20))
                Spacer()
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: min(progress, 1.0))
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .frame(height: 4)
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Health Metric Card
struct HealthMetricCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    let trend: TrendDirection
    
    enum TrendDirection {
        case up, down, stable
        
        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .stable: return "minus"
            }
        }
        
        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            case .stable: return .gray
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 16))
                Spacer()
                Image(systemName: trend.icon)
                    .foregroundColor(trend.color)
                    .font(.system(size: 12))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                Text(unit)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
    }
}

// MARK: - Training Trend Chart
struct TrainingTrendChart: View {
    let scores: [TrainingScore]
    
    var body: some View {
        Chart(scores) { score in
            LineMark(
                x: .value("Date", score.date),
                y: .value("Score", score.score)
            )
            .foregroundStyle(.blue)
            .lineStyle(StrokeStyle(lineWidth: 3))
            
            AreaMark(
                x: .value("Date", score.date),
                y: .value("Score", score.score)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [.blue.opacity(0.3), .blue.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            PointMark(
                x: .value("Date", score.date),
                y: .value("Score", score.score)
            )
            .foregroundStyle(.blue)
            .symbolSize(30)
        }
        .chartYScale(domain: 0...100)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.weekday(.abbreviated))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
    }
}

// MARK: - Achievement Badge
struct AchievementBadge: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let isUnlocked: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? color.opacity(0.2) : Color.gray.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isUnlocked ? color : .gray)
                
                if isUnlocked {
                    Circle()
                        .stroke(color, lineWidth: 2)
                        .frame(width: 60, height: 60)
                }
            }
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(isUnlocked ? .primary : .secondary)
                Text(description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .multilineTextAlignment(.center)
        }
        .frame(width: 80)
        .opacity(isUnlocked ? 1.0 : 0.6)
        .scaleEffect(isUnlocked ? 1.0 : 0.95)
        .animation(.easeInOut(duration: 0.3), value: isUnlocked)
    }
}

// MARK: - Weekly Summary Row
struct WeeklySummaryRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 18))
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Achievements View
struct AchievementsView: View {
    @Environment(\.dismiss) private var dismiss
    
    let achievements = [
        Achievement(title: "Step Master", description: "Walk 10,000 steps in a day", icon: "figure.walk", color: .green, isUnlocked: true),
        Achievement(title: "Hydration Hero", description: "Meet daily water goal", icon: "drop.fill", color: .blue, isUnlocked: true),
        Achievement(title: "Sleep Champion", description: "Get 8+ hours of sleep", icon: "moon.fill", color: .purple, isUnlocked: false),
        Achievement(title: "Calorie Crusher", description: "Meet daily calorie goal", icon: "flame.fill", color: .orange, isUnlocked: true),
        Achievement(title: "Workout Warrior", description: "Complete 5 workouts in a week", icon: "figure.strengthtraining.traditional", color: .red, isUnlocked: false),
        Achievement(title: "Distance Destroyer", description: "Run 50km in a week", icon: "location.fill", color: .cyan, isUnlocked: false),
        Achievement(title: "Heart Health Hero", description: "Maintain healthy resting HR", icon: "heart.fill", color: .pink, isUnlocked: true),
        Achievement(title: "Recovery Master", description: "Achieve 90+ recovery score", icon: "bed.double.fill", color: .mint, isUnlocked: false)
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                    ForEach(achievements) { achievement in
                        AchievementCard(achievement: achievement)
                    }
                }
                .padding()
            }
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct Achievement: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let color: Color
    let isUnlocked: Bool
}

struct AchievementCard: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? achievement.color.opacity(0.2) : Color.gray.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: achievement.icon)
                    .font(.system(size: 32))
                    .foregroundColor(achievement.isUnlocked ? achievement.color : .gray)
                
                if achievement.isUnlocked {
                    Circle()
                        .stroke(achievement.color, lineWidth: 3)
                        .frame(width: 80, height: 80)
                }
            }
            
            VStack(spacing: 4) {
                Text(achievement.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(achievement.isUnlocked ? .primary : .secondary)
                    .multilineTextAlignment(.center)
                
                Text(achievement.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .opacity(achievement.isUnlocked ? 1.0 : 0.6)
        .scaleEffect(achievement.isUnlocked ? 1.0 : 0.95)
    }
}
