import SwiftUI
import Charts

// MARK: - Coach Dashboard Extensions
extension CoachDashboardView {
    
    // MARK: - Coach Header Section
    var coachHeaderSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome back, Coach!")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Managing \(coachSelection.athletes.count) athletes")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                // Team Performance Score
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 6)
                        .frame(width: 70, height: 70)
                    
                    Circle()
                        .trim(from: 0, to: teamPerformanceScore / 100)
                        .stroke(
                            LinearGradient(
                                colors: [.green, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 70, height: 70)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1.0), value: teamPerformanceScore)
                    
                    VStack(spacing: 1) {
                        Text("\(Int(teamPerformanceScore))")
                            .font(.headline)
                            .fontWeight(.bold)
                        Text("Team")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Quick Team Stats
            HStack(spacing: 20) {
                TeamStatItem(title: "Active", value: "\(activeAthletes)", color: .green)
                TeamStatItem(title: "At Risk", value: "\(atRiskAthletes)", color: .orange)
                TeamStatItem(title: "Alerts", value: "\(alertCount)", color: .red)
            }
        }
        .padding(20)
        .background(cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Dashboard View Selector
    var dashboardViewSelector: some View {
        Picker("Dashboard View", selection: Binding<CoachDashboardView.DashboardView>(
    get: { selectedView },
    set: { selectedView = $0 }
)) {
            ForEach(DashboardView.allCases, id: \.self) { view in
                Text(view.rawValue).tag(view)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal, 4)
    }
    
    // MARK: - Overview Content
    var overviewContent: some View {
        VStack(spacing: 20) {
            // Athletes Grid
            if !coachSelection.athletes.isEmpty {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                    ForEach(coachSelection.athletes.indices, id: \.self) { index in
                        let athlete = coachSelection.athletes[index]
                        AthleteOverviewCard(
                            athlete: athlete,
                            metrics: athleteMetrics[athlete.uid],
                            onTap: {
                                coachSelection.selectedIndex = index
                                showingAthleteDetail = true
                            }
                        )
                    }
                }
            } else {
                EmptyStateView(
                    title: "No Athletes Yet",
                    subtitle: "Add athletes to start monitoring their performance",
                    icon: "person.3.fill"
                )
            }
        }
    }
    
    // MARK: - Performance Content
    var performanceContent: some View {
        VStack(spacing: 20) {
            // Team Performance Chart
            TeamPerformanceChart(athleteMetrics: athleteMetrics, athletes: coachSelection.athletes)
            
            // Performance Leaderboard
            PerformanceLeaderboard(athleteMetrics: athleteMetrics, athletes: coachSelection.athletes)
        }
    }
    
    // MARK: - Alerts Content
    var alertsContent: some View {
        VStack(spacing: 16) {
            ForEach(generateAlerts(), id: \.id) { alert in
                AlertCard(alert: alert)
            }
            
            if generateAlerts().isEmpty {
                EmptyStateView(
                    title: "No Alerts",
                    subtitle: "All athletes are performing well",
                    icon: "checkmark.shield.fill"
                )
            }
        }
    }
    
    // MARK: - Add Athlete Section
    var addAthleteSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add New Athlete")
                .font(.headline)
                .padding(.horizontal, 4)
            
            VStack(alignment: .leading, spacing: 12) {
                TextField("Search athlete by name", text: $searchName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: searchName) { _ in searchForName() }
                
                if !searchResults.isEmpty {
                    ForEach(searchResults) { result in
                        AthleteSearchResult(athlete: result) {
                            addFoundAthlete(result)
                        }
                    }
                } else if !searchName.isEmpty {
                    Text(errorMessage ?? "No athletes found")
                        .foregroundColor(.red)
                        .font(.caption)
                } else if !suggestedAthletes.isEmpty {
                    Text("Suggested Athletes")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    ForEach(suggestedAthletes.prefix(3)) { suggestion in
                        AthleteSearchResult(athlete: suggestion) {
                            addFoundAthlete(suggestion)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Computed Properties
    var teamPerformanceScore: Double {
        let scores = athleteMetrics.values.map { Double($0.overallScore) }
        return scores.isEmpty ? 0 : scores.reduce(0, +) / Double(scores.count)
    }
    
    var activeAthletes: Int {
        athleteMetrics.values.filter { $0.riskLevel == .low }.count
    }
    
    var atRiskAthletes: Int {
        athleteMetrics.values.filter { $0.riskLevel == .medium || $0.riskLevel == .high }.count
    }
    
    var alertCount: Int {
        generateAlerts().count
    }
    
    // MARK: - Helper Methods
    func loadAllAthleteMetrics() {
        for athlete in coachSelection.athletes {
            loadMetrics(for: athlete)
        }
    }
    
    func generateAlerts() -> [Alert] {
        var alerts: [Alert] = []
        
        for (uid, metrics) in athleteMetrics {
            let athlete = coachSelection.athletes.first { $0.uid == uid }
            let name = athlete?.name ?? "Unknown"
            
            if metrics.riskLevel == .high {
                alerts.append(Alert(
                    id: UUID(),
                    title: "High Risk Alert",
                    message: "\(name) shows concerning metrics",
                    severity: .high,
                    athleteName: name
                ))
            }
            
            if metrics.recoveryScore < 30 {
                alerts.append(Alert(
                    id: UUID(),
                    title: "Poor Recovery",
                    message: "\(name) has low recovery score (\(metrics.recoveryScore))",
                    severity: .medium,
                    athleteName: name
                ))
            }
            
            if metrics.trainingScore < 40 {
                alerts.append(Alert(
                    id: UUID(),
                    title: "Low Training Performance",
                    message: "\(name) is underperforming in training",
                    severity: .medium,
                    athleteName: name
                ))
            }
        }
        
        return alerts.sorted { $0.severity.rawValue > $1.severity.rawValue }
    }
}

// MARK: - Supporting Views

struct TeamStatItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct AthleteOverviewCard: View {
    let athlete: AthleteRef
    let metrics: AthleteMetrics?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(athlete.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Spacer()
                    if let metrics = metrics {
                        RiskIndicator(level: metrics.riskLevel)
                    }
                }
                
                if let metrics = metrics {
                    VStack(spacing: 8) {
                        MetricRow(title: "Overall", value: metrics.overallScore, color: .blue)
                        MetricRow(title: "Training", value: metrics.trainingScore, color: .orange)
                        MetricRow(title: "Recovery", value: metrics.recoveryScore, color: .green)
                    }
                    
                    if let lastWorkout = metrics.lastWorkout {
                        Text("Last: \(lastWorkout)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("Loading metrics...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MetricRow: View {
    let title: String
    let value: Int
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text("\(value)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

struct RiskIndicator: View {
    let level: AthleteMetrics.RiskLevel
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(level.color)
                .frame(width: 8, height: 8)
            Text(level.text)
                .font(.caption2)
                .foregroundColor(level.color)
        }
    }
}

struct TeamPerformanceChart: View {
    let athleteMetrics: [String: AthleteMetrics]
    let athletes: [AthleteRef]
    
    var chartData: [ChartDataPoint] {
        athletes.compactMap { athlete in
            guard let metrics = athleteMetrics[athlete.uid] else { return nil }
            return ChartDataPoint(name: athlete.name, value: metrics.overallScore)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Team Performance")
                .font(.headline)
                .padding(.horizontal, 4)
            
            Chart(chartData) { dataPoint in
                BarMark(
                    x: .value("Athlete", dataPoint.name),
                    y: .value("Score", dataPoint.value)
                )
                .foregroundStyle(.blue)
            }
            .frame(height: 200)
            .chartYScale(domain: 0...100)
        }
        .padding(20)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let name: String
    let value: Int
}

struct PerformanceLeaderboard: View {
    let athleteMetrics: [String: AthleteMetrics]
    let athletes: [AthleteRef]
    
    var sortedAthletes: [(AthleteRef, AthleteMetrics)] {
        athletes.compactMap { athlete in
            guard let metrics = athleteMetrics[athlete.uid] else { return nil }
            return (athlete, metrics)
        }.sorted { $0.1.overallScore > $1.1.overallScore }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Leaderboard")
                .font(.headline)
                .padding(.horizontal, 4)
            
            VStack(spacing: 8) {
                ForEach(Array(sortedAthletes.enumerated()), id: \.offset) { index, athleteData in
                    LeaderboardRow(
                        rank: index + 1,
                        athlete: athleteData.0,
                        metrics: athleteData.1
                    )
                }
            }
        }
        .padding(20)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

struct LeaderboardRow: View {
    let rank: Int
    let athlete: AthleteRef
    let metrics: AthleteMetrics
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank
            Text("\(rank)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(rank <= 3 ? .orange : .secondary)
                .frame(width: 30)
            
            // Athlete Info
            VStack(alignment: .leading, spacing: 2) {
                Text(athlete.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                RiskIndicator(level: metrics.riskLevel)
            }
            
            Spacer()
            
            // Score
            Text("\(metrics.overallScore)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.blue)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct Alert: Identifiable {
    let id: UUID
    let title: String
    let message: String
    let severity: Severity
    let athleteName: String
    
    enum Severity: Int {
        case low = 1, medium = 2, high = 3
        
        var color: Color {
            switch self {
            case .low: return .blue
            case .medium: return .orange
            case .high: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .low: return "info.circle.fill"
            case .medium: return "exclamationmark.triangle.fill"
            case .high: return "exclamationmark.octagon.fill"
            }
        }
    }
}

struct AlertCard: View {
    let alert: Alert
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: alert.severity.icon)
                .foregroundColor(alert.severity.color)
                .font(.system(size: 20))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(alert.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(alert.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(alert.athleteName)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(alert.severity.color.opacity(0.2))
                .cornerRadius(6)
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct AthleteSearchResult: View {
    let athlete: AthleteRef
    let onAdd: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(athlete.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("ID: \(athlete.id)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Add") {
                onAdd()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct EmptyStateView: View {
    let title: String
    let subtitle: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}
