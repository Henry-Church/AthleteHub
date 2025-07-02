import SwiftUI
import HealthKit
import Charts

struct OverallRecoveryScoreCard: View {
    let score: Int
    let colorScheme: ColorScheme

    var statusText: String {
        if score >= 80 {
            return "Excellent"
        } else if score >= 50 {
            return "Moderate"
        } else {
            return "Needs Rest"
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
            Image(systemName: "bed.double.fill")
                .font(.largeTitle)
                .foregroundColor(.white)

            VStack(alignment: .leading) {
                Text("Overall Recovery Score")
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
        .background(Color.purple)
        .cornerRadius(16)
        .padding(.horizontal)
    }
}


struct RecoveryView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var userProfile: UserProfile
    @EnvironmentObject var healthManager: HealthManager
    @State private var showingSetRecoveryGoals = false
    @State private var showingManualEntry = false

    var recoveryCards: [AnyView] {
        [
            AnyView(
            RecoverySleepDurationCard(
                    title: "Sleep Duration",
                    value: String(format: "%.1f hrs", healthManager.sleepDuration ?? 0),
                    stages: healthManager.sleepStages,
                    colorScheme: colorScheme
                )),
            AnyView(
                SleepQualityCard(
                    score: Int(healthManager.sleepQualityScore ?? 0),
                    colorScheme: colorScheme
                )
            ),
            AnyView(
                RecoveryMetricCard(
                    title: "Stress Level",
                    actual: healthManager.stressLevel ?? 0,
                    goal: 30,
                    unit: "score",
                    colorScheme: colorScheme
                )
            ),
            AnyView(
                RecoveryMetricCard(
                    title: "Resting HR",
                    actual: healthManager.restingHeartRate ?? 0,
                    goal: nil,
                    unit: "bpm",
                    colorScheme: colorScheme
                )
            ),
            AnyView(
                HRVChartCard(
                    values: healthManager.hrvWeek,
                    colorScheme: colorScheme
                )
                .gridCellColumns(2)
            )
        ]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Recovery Dashboard")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        Spacer()
                        HStack(spacing: 12) {
                            Button(action: {
                                showingSetRecoveryGoals = true
                            }) {
                                Image(systemName: "target")
                                    .padding(8)
                                    .background(Color.purple.opacity(0.2))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }

                            Button(action: {
                                showingManualEntry = true
                            }) {
                                Image(systemName: "pencil")
                                    .padding(8)
                                    .background(Color.purple.opacity(0.2))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }

                    OverallRecoveryScoreCard(
                        score: Int(userProfile.overallRecoveryScore?.replacingOccurrences(of: "%", with: "") ?? "0") ?? 0,
                        colorScheme: colorScheme
                    )
                }
                .padding(.horizontal)

                RecoveryChartCard(title: "Sleep Stage Timeline", colorScheme: colorScheme) {
                    if !healthManager.sleepStages.isEmpty {
                        SleepStageHypnogramView(
                            sleepSamples: healthManager.rawSleepSamples,
                            colorScheme: colorScheme
                        )
                        .frame(height: 140)
                    } else {
                        Text("Data not available")
                            .foregroundColor(.secondary)
                            .frame(height: 150)
                            .frame(maxWidth: .infinity)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                    }
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(Array(recoveryCards.enumerated()), id: \.offset) { _, view in
                        view
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(
            (colorScheme == .dark ? Color.purple.opacity(0.2) : Color.purple.opacity(0.05))
                .edgesIgnoringSafeArea(.all)
        )
        .sheet(isPresented: $showingSetRecoveryGoals) {
            SetRecoveryGoalsView()
        }
        .sheet(isPresented: $showingManualEntry) {
            ManualRecoveryEntryView()
        }
        .onAppear {
            healthManager.fetchAllData()
        }
    }
}

struct RecoverySleepDurationCard: View {
    let title: String
    let value: String
    let stages: [SleepStage]
    let colorScheme: ColorScheme

private var cardBackground: Color {
    colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground)
}
    private let validStageNames = ["Awake", "REM Sleep", "Light Sleep", "Deep Sleep"]

    private var filteredStages: [SleepStage] {
        stages.filter { validStageNames.contains($0.stage) }
    }

    private var totalDuration: Double {
        filteredStages.reduce(0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label(title, systemImage: "bed.double.fill")
                    .font(.headline)
                Spacer()
            }

            Text(value)
                .font(.caption)
                .foregroundColor(.secondary)

            GeometryReader { geometry in
                HStack(spacing: 0) {
                    ForEach(filteredStages.sorted(by: { $0.startDate < $1.startDate })) { stage in
                        Rectangle()
                            .fill(stageColor(for: stage.stage))
                            .frame(width: barWidth(for: stage, totalWidth: geometry.size.width), height: 8)
                    }
                }
                .cornerRadius(4)
            }
            .frame(height: 8)
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .frame(height: 180)
        .background(cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.purple.opacity(0.15), radius: 8, x: 0, y: 4)
    }

    private func barWidth(for stage: SleepStage, totalWidth: CGFloat) -> CGFloat {
        guard totalDuration > 0 else { return 0 }
        let duration = stage.endDate.timeIntervalSince(stage.startDate)
        return CGFloat(duration / totalDuration) * totalWidth
    }

    private func stageColor(for stage: String) -> Color {
        switch stage {
        case "Awake":
            return Color.pink.opacity(0.4)
        case "REM Sleep":
            return Color.purple
        case "Light Sleep":
            return Color.blue.opacity(0.5)
        case "Deep Sleep":
            return Color.blue
        default:
            return Color.gray
        }
    }
}


struct RecoveryMetricCard: View {
    let title: String
    let actual: Double
    let goal: Double?
    let unit: String
    let colorScheme: ColorScheme

    var progress: Double {
        guard let goal = goal, goal > 0 else { return 0 }
        return min(actual / goal, 1)
    }

    var cardBackground: Color {
        colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
            }

            Text(goal != nil ?
                 "\(Int(actual)) / \(Int(goal!)) \(unit)" :
                 "\(Int(actual)) \(unit)")
                .font(.caption)
                .foregroundColor(.secondary)

            if let _ = goal {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .purple))
                    .frame(height: 8)
                    .cornerRadius(4)

                Text(String(format: "%.0f%%", progress * 100))
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.purple)
            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .frame(height: 180)
        .background(cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.purple.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}




struct RecoveryChartCard<Content: View>: View {
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
        .shadow(color: Color.purple.opacity(0.4), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
    }
}

struct SetRecoveryGoalsView: View {
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("sleepGoal") var sleepGoal: Double = 8.0
    @AppStorage("hrvGoal") var hrvGoal: Double = 80
    @AppStorage("restingHRGoal") var restingHRGoal: Double = 60

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Sleep")) {
                    Stepper(value: $sleepGoal, in: 0...12, step: 0.25) {
                        Text("Sleep Goal: \(String(format: "%.2f", sleepGoal)) hrs")
                    }
                }

                Section(header: Text("Heart Rate Variability")) {
                    Stepper(value: $hrvGoal, in: 10...150, step: 1) {
                        Text("HRV Goal: \(Int(hrvGoal)) ms")
                    }
                }

                Section(header: Text("Resting Heart Rate")) {
                    Stepper(value: $restingHRGoal, in: 30...100, step: 1) {
                        Text("Resting HR Goal: \(Int(restingHRGoal)) bpm")
                    }
                }
            }
            .navigationTitle("Set Recovery Goals")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}



struct SleepQualityCard: View {
    let score: Int              // 0 to 100 sleep score
    let colorScheme: ColorScheme

    @State private var animatedProgress: Double = 0.0

    private var statusText: String {
        switch score {
        case 80...100: return "Excellent"
        case 50..<80: return "Moderate"
        default: return "Poor"
        }
    }

    private var statusColor: Color {
        switch score {
        case 80...100: return .green
        case 50..<80: return .yellow
        default: return .red
        }
    }

    private var progress: Double {
        min(Double(score) / 100.0, 1.0)
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Label("Sleep Quality", systemImage: "moon.zzz.fill")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }

            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                    .frame(width: 100, height: 100)

                Circle()
                    .trim(from: 0, to: CGFloat(animatedProgress))
                    .stroke(statusColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 100, height: 100)

                VStack {
                    Text("\(score)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(statusColor)
                    Text(statusText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

        }
        .padding()
        .frame(maxWidth: .infinity)
        .frame(height: 180)
        .background(colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.purple.opacity(0.15), radius: 8, x: 0, y: 4)
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                animatedProgress = progress
            }
        }
    }
}

struct HRVChartCard: View {
    let values: [Double]
    let colorScheme: ColorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("HRV Avg (7d)")
                .font(.headline)

            if #available(iOS 16.0, *) {
                Chart {
                    ForEach(values.indices, id: \.self) { i in
                        LineMark(
                            x: .value("Day", i),
                            y: .value("HRV", values[i])
                        )
                        PointMark(
                            x: .value("Day", i),
                            y: .value("HRV", values[i])
                        )
                    }
                }
                .chartYScale(domain: 0...(values.max() ?? 1))
                .frame(height: 120)
            } else {
                Text("Available on iOS 16+")
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .frame(height: 180)
        .background(colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.purple.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}

struct ManualRecoveryEntryView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var healthManager: HealthManager

    @State private var sleepDuration: Double = 0
    @State private var sleepScore: Int = 0
    @State private var hrv: Int = 0
    @State private var restingHR: Int = 0
    @State private var stressLevel: Int = 0

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Sleep")) {
                    Stepper(value: $sleepDuration, in: 0...12, step: 0.25) {
                        Text("Sleep Duration: \(String(format: "%.2f", sleepDuration)) hrs")
                    }

                    Stepper(value: $sleepScore, in: 0...100, step: 1) {
                        Text("Sleep Score: \(sleepScore)/100")
                    }
                }

                Section(header: Text("Heart & Stress")) {
                    Stepper(value: $hrv, in: 10...150, step: 1) {
                        Text("HRV: \(hrv) ms")
                    }

                    Stepper(value: $restingHR, in: 30...100, step: 1) {
                        Text("Resting HR: \(restingHR) bpm")
                    }

                    Stepper(value: $stressLevel, in: 0...30, step: 1) {
                        Text("Stress Level: \(stressLevel)")
                    }
                }
            }
            .navigationTitle("Manual Recovery Entry")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    healthManager.saveManualRecoveryEntry(
                        sleepDuration: sleepDuration,
                        sleepScore: sleepScore,
                        hrv: hrv,
                        restingHR: restingHR,
                        stressLevel: stressLevel
                    )
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}



struct SleepStageHypnogramView: View {
    let sleepSamples: [HKCategorySample]
    let colorScheme: ColorScheme

    private let stageOrder: [HKCategoryValueSleepAnalysis] = [
        .awake,         // Light pink
        .asleepREM,     // Magenta
        .asleepCore,    // Light blue
        .asleepDeep     // Blue
    ]

    // Filter to only the sleep stages we display (ignore "in bed" and unknown values)
    private var filteredSamples: [HKCategorySample] {
        sleepSamples.compactMap { sample in
            guard let stage = HKCategoryValueSleepAnalysis(rawValue: sample.value) else { return nil }
            return stageOrder.contains(stage) ? sample : nil
        }
    }

    // Pre-compute sequential offsets for each valid sample so the chart spans
    // the exact total duration of shown stages instead of the entire query range
    private var timelineEntries: [(stage: HKCategoryValueSleepAnalysis, start: TimeInterval, duration: TimeInterval)] {
        var offset: TimeInterval = 0
        var result: [(HKCategoryValueSleepAnalysis, TimeInterval, TimeInterval)] = []
        for sample in filteredSamples.sorted(by: { $0.startDate < $1.startDate }) {
            guard let stage = HKCategoryValueSleepAnalysis(rawValue: sample.value) else { continue }
            let duration = sample.endDate.timeIntervalSince(sample.startDate)
            result.append((stage, offset, duration))
            offset += duration
        }
        return result
    }

    private var totalDuration: TimeInterval {
        timelineEntries.reduce(0) { $0 + $1.duration }
    }

    var body: some View {
        GeometryReader { geometry in
            let labelWidth: CGFloat = 48
            let timeHeight: CGFloat = 16
            let chartWidth = geometry.size.width - labelWidth
            let chartHeight = geometry.size.height - timeHeight
            let rowHeight = chartHeight / CGFloat(stageOrder.count)

            guard totalDuration > 0 else {
                return AnyView(EmptyView())
            }

            // Display up to 9 hours on the timeline starting at 0h
            let chartHours: Double = 9
            let totalSeconds = chartHours * 3600
            let hourTicks = stride(from: 0.0, through: totalSeconds, by: 3600).map { $0 }

            // Group the timeline entries by stage for easy drawing
            let groupedByStage = Dictionary(grouping: timelineEntries, by: { $0.stage })

return AnyView(
    ZStack(alignment: .topLeading) {
        // Sleep stage bars
        ForEach(stageOrder.indices, id: \.self) { index in
            let stage = stageOrder[index]
            let entries = groupedByStage[stage] ?? []

            ForEach(entries.indices, id: \.self) { i in
                let entry = entries[i]
                let startOffset = CGFloat(entry.start / totalSeconds) * chartWidth
                let width = CGFloat(entry.duration / totalSeconds) * chartWidth
                let yOffset = CGFloat(index) * rowHeight

                RoundedRectangle(cornerRadius: 4)
                    .fill(stageColor(for: stage))
                    .frame(width: width, height: rowHeight * 0.6)
                    .offset(x: labelWidth + startOffset, y: yOffset + rowHeight * 0.2)
            }
        }

        // Stage labels
        ForEach(stageOrder.indices, id: \.self) { index in
            Text(stageName(for: stageOrder[index]))
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(width: labelWidth - 4, alignment: .leading)
                .offset(x: 0, y: CGFloat(index) * rowHeight + rowHeight * 0.2)
        }

        // Time labels
        ForEach(hourTicks.indices, id: \.self) { i in
            let tick = hourTicks[i]
            let x = labelWidth + CGFloat(tick / totalSeconds) * chartWidth
            Text("\(Int(tick / 3600))h")
                .font(.caption2)
                .foregroundColor(.secondary)
                .offset(x: x - 10, y: chartHeight + 2)
        }
    })
        .frame(height: 140)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    }

    private func stageColor(for stage: HKCategoryValueSleepAnalysis) -> Color {
        switch stage {
        case .awake:
            return Color.pink.opacity(0.4)    // Light pink
        case .asleepREM:
            return Color.purple
        case .asleepCore:
            return Color.blue.opacity(0.5)
        case .asleepDeep:
            return Color.blue
        default:
            return Color.gray
        }
    }

    private func stageName(for stage: HKCategoryValueSleepAnalysis) -> String {
        switch stage {
        case .awake: return "Awake"
        case .asleepREM: return "REM"
        case .asleepCore: return "Light"
        case .asleepDeep: return "Deep"
        default: return ""
        }
    }
}

