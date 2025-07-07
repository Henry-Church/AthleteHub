import SwiftUI
import UniformTypeIdentifiers

struct TrainingCalendarView: View {
    @EnvironmentObject var scheduleManager: TrainingScheduleManager
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedDate = Date()
    @State private var showingAddSheet = false
    @State private var trainingToEdit: ScheduledTraining?
    @State private var showingImporter = false

    private var dayTrainings: [ScheduledTraining] {
        scheduleManager.trainings.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }

    private var weekTrainings: [Date: [ScheduledTraining]] {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate)) ?? selectedDate
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek) ?? startOfWeek
        let trainings = scheduleManager.trainings.filter { $0.date >= startOfWeek && $0.date < endOfWeek }
        return Dictionary(grouping: trainings) { calendar.startOfDay(for: $0.date) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DatePicker("", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .padding(8)
                .background(Color.yellow.opacity(0.3))
                .cornerRadius(12)

            if dayTrainings.isEmpty {
                Text("No trainings scheduled")
                    .foregroundColor(.secondary)
            } else {
                ForEach(dayTrainings) { training in
                    HStack {
                        Text(training.title)
                        Spacer()
                        Text(training.date, style: .time)
                            .foregroundColor(.secondary)
                    }
                    .padding(8)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                    .onTapGesture {
                        trainingToEdit = training
                    }
                }
                .onDelete(perform: delete)
            }

            Button(action: { showingAddSheet = true }) {
                Label("Add Training", systemImage: "plus")
            }
            .sheet(isPresented: $showingAddSheet) {
                AddTrainingView(date: selectedDate)
                    .environmentObject(scheduleManager)
            }
            .sheet(item: $trainingToEdit) { training in
                AddTrainingView(training: training)
                    .environmentObject(scheduleManager)
            }

            Button(action: { showingImporter = true }) {
                Label("Import Trainings", systemImage: "tray.and.arrow.down")
            }
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [UTType(filenameExtension: "ics") ?? .data]
            ) { result in
                switch result {
                case .success(let url):
                    scheduleManager.importTrainings(from: url)
                case .failure:
                    break
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Week Overview")
                    .font(.headline)

                if weekTrainings.isEmpty {
                    Text("No trainings this week")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(weekTrainings.keys.sorted(), id: \.self) { day in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(day, style: .date)
                                .fontWeight(.semibold)
                            ForEach(weekTrainings[day] ?? []) { training in
                                HStack {
                                    Text(training.title)
                                    Spacer()
                                    Text(training.date, style: .time)
                                        .foregroundColor(.secondary)
                                }
                                .onTapGesture {
                                    trainingToEdit = training
                                }
                            }
                        }
                        .padding(8)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color(.secondarySystemBackground) : Color.white)
        .cornerRadius(20)
        .shadow(color: Color.yellow.opacity(0.3), radius: 8, x: 0, y: 4)
        .padding()
    }

    private func delete(at offsets: IndexSet) {
        let ids = offsets.map { dayTrainings[$0].id }
        scheduleManager.trainings.removeAll { ids.contains($0.id) }
    }
}

struct AddTrainingView: View {
    @EnvironmentObject var scheduleManager: TrainingScheduleManager
    @Environment(\.dismiss) var dismiss

    var training: ScheduledTraining?

    @State private var date: Date
    @State private var time: Date

    // MARK: - Workout Details
    @State private var selectedSport: Sport = Sport.all.first!
    @State private var selectedLocation: WorkoutLocation = .unknown
    @State private var workoutType: WorkoutTypeOption = .time
    @State private var goalValue: Double = 10
    @State private var workoutName: String
    @State private var descriptionText: String = ""

    init(training: ScheduledTraining? = nil, date: Date = Date()) {
        self.training = training
        _date = State(initialValue: training?.date ?? date)
        _time = State(initialValue: training?.date ?? Date())
        _workoutName = State(initialValue: training?.title ?? "")
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Workout")) {
                    NavigationLink(destination: SportSelectionView(selectedSport: $selectedSport)) {
                        HStack {
                            Label {
                                Text("Sport")
                            } icon: {
                                Image(systemName: selectedSport.systemImage)
                                    .foregroundColor(selectedSport.accentColor)
                            }
                            Spacer()
                            Text(selectedSport.name)
                                .foregroundColor(.primary)
                        }
                    }

                    NavigationLink(destination: LocationSelectionView(selectedLocation: $selectedLocation)) {
                        HStack {
                            Label("Location", systemImage: "mappin.and.ellipse")
                            Spacer()
                            Text(selectedLocation.rawValue)
                                .foregroundColor(.blue)
                        }
                    }

                    NavigationLink(destination: TypeSelectionView(workoutType: $workoutType)) {
                        HStack {
                            Label("Type", systemImage: "clock")
                            Spacer()
                            Text(workoutType.rawValue)
                                .foregroundColor(.accentColor)
                        }
                    }
                }

                Section(header: Text("Schedule")) {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                }

                if workoutType == .custom {
                    Section(header: Text("Name")) {
                        TextField("Add Workout Name", text: $workoutName)
                    }
                }

                Section(header: Text("Description")) {
                    TextEditor(text: $descriptionText)
                        .frame(minHeight: 100)
                }

                if workoutType == .time {
                    Section(header: Text("Time")) {
                        HStack {
                            Text("Time")
                            Spacer()
                            Stepper(value: $goalValue, in: 1...240, step: 1) {
                                Text("\(Int(goalValue)) min")
                            }
                            .labelsHidden()
                        }
                    }
                } else if workoutType == .distance {
                    Section(header: Text("Distance")) {
                        HStack {
                            Text("Distance")
                            Spacer()
                            Stepper(value: $goalValue, in: 0.5...100, step: 0.5) {
                                Text("\(goalValue, specifier: "%.1f") mi")
                            }
                            .labelsHidden()
                        }
                    }
                } else if workoutType == .custom {
                    Section {
                        Button(action: { /* Add interval action */ }) {
                            Label("Add Interval", systemImage: "plus")
                        }
                    }
                }
            }
            .navigationBarTitle(training == nil ? "New Training" : "Edit Training", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save", action: saveTraining)
            )
        }
    }

    private func saveTraining() {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: date)
        let t = Calendar.current.dateComponents([.hour, .minute], from: time)
        comps.hour = t.hour
        comps.minute = t.minute
        let combined = Calendar.current.date(from: comps) ?? date

        let title = workoutName.isEmpty ? selectedSport.name : workoutName

        if let training = training {
            scheduleManager.updateTraining(training, date: combined, title: title)
        } else {
            scheduleManager.addTraining(date: combined, title: title)
        }
        dismiss()
    }
}

// MARK: - Models

struct Sport: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let systemImage: String
    let accentColor: Color

    static let all: [Sport] = [
        Sport(name: "Running", systemImage: "figure.run", accentColor: .blue),
        Sport(name: "Indoor Rowing", systemImage: "figure.rower", accentColor: .yellow),
        Sport(name: "Cycling", systemImage: "bicycle", accentColor: .orange),
        Sport(name: "Swimming", systemImage: "figure.pool.swim", accentColor: .teal)
    ]
}

enum WorkoutLocation: String, CaseIterable, Identifiable {
    case unknown = "Unknown"
    case indoor = "Indoor"
    case outdoor = "Outdoor"

    var id: String { rawValue }
}

enum WorkoutTypeOption: String, CaseIterable, Identifiable {
    case time = "Time"
    case distance = "Distance"
    case custom = "Custom"

    var id: String { rawValue }
}

// MARK: - Selection Views

struct SportSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedSport: Sport

    var body: some View {
        List {
            Section(header: Text("Recently Used")) {
                ForEach([selectedSport], id: \.<Sport>) { sport in
                    SportRow(sport: sport, selectedSport: $selectedSport)
                }
            }
            Section(header: Text("All Sports")) {
                ForEach(Sport.all) { sport in
                    SportRow(sport: sport, selectedSport: $selectedSport)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Sport")
    }
}

struct SportRow: View {
    let sport: Sport
    @Binding var selectedSport: Sport
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Button(action: {
            selectedSport = sport
            dismiss()
        }) {
            HStack {
                Image(systemName: sport.systemImage)
                Text(sport.name)
                Spacer()
                if selectedSport == sport {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                }
            }
        }
    }
}

struct LocationSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedLocation: WorkoutLocation

    var body: some View {
        List {
            ForEach(WorkoutLocation.allCases) { loc in
                Button(action: {
                    selectedLocation = loc
                    dismiss()
                }) {
                    HStack {
                        Text(loc.rawValue)
                        Spacer()
                        if selectedLocation == loc {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Location")
    }
}

struct TypeSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var workoutType: WorkoutTypeOption

    var body: some View {
        List {
            ForEach(WorkoutTypeOption.allCases) { type in
                Button(action: {
                    workoutType = type
                    dismiss()
                }) {
                    HStack {
                        Text(type.rawValue)
                        Spacer()
                        if workoutType == type {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Type")
    }
}
