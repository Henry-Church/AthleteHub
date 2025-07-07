import SwiftUI

struct TrainingCalendarView: View {
    @EnvironmentObject var scheduleManager: TrainingScheduleManager
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedDate = Date()
    @State private var showingAddSheet = false
    @State private var trainingToEdit: ScheduledTraining?

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
    @State private var title: String

    init(training: ScheduledTraining? = nil, date: Date = Date()) {
        self.training = training
        _date = State(initialValue: training?.date ?? date)
        _time = State(initialValue: training?.date ?? Date())
        _title = State(initialValue: training?.title ?? "")
    }

    var body: some View {
        NavigationView {
            Form {
                TextField("Title", text: $title)
                DatePicker("Date", selection: $date, displayedComponents: .date)
                DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
            }
            .navigationTitle(training == nil ? "New Training" : "Edit Training")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        var comps = Calendar.current.dateComponents([.year, .month, .day], from: date)
                        let t = Calendar.current.dateComponents([.hour, .minute], from: time)
                        comps.hour = t.hour
                        comps.minute = t.minute
                        let combined = Calendar.current.date(from: comps) ?? date
                        if let training = training {
                            scheduleManager.updateTraining(training, date: combined, title: title)
                        } else {
                            scheduleManager.addTraining(date: combined, title: title)
                        }
                        dismiss()
                    }
                }
            }
        }
    }
}
