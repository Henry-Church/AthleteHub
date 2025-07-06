import SwiftUI

struct TrainingCalendarView: View {
    @EnvironmentObject var scheduleManager: TrainingScheduleManager
    @State private var selectedDate = Date()
    @State private var showingAddSheet = false

    private var dayFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "E, MMM d"
        return f
    }

    private var upcomingDates: [Date] {
        (0..<14).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: Date()) }
    }

    private func trainings(for date: Date) -> [ScheduledTraining] {
        scheduleManager.trainings.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(upcomingDates, id: \.self) { date in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(dayFormatter.string(from: date))
                            .font(.headline)
                        Spacer()
                        Button(action: {
                            selectedDate = date
                            showingAddSheet = true
                        }) {
                            Image(systemName: "plus.circle")
                        }
                    }
                    if trainings(for: date).isEmpty {
                        Text("No trainings")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    } else {
                        ForEach(trainings(for: date)) { t in
                            Text(t.title)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(4)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(4)
                        }
                    }
                }
            }
        }
        .padding()
        .sheet(isPresented: $showingAddSheet) {
            AddTrainingView(date: selectedDate)
                .environmentObject(scheduleManager)
        }
    }
}

struct AddTrainingView: View {
    @EnvironmentObject var scheduleManager: TrainingScheduleManager
    @Environment(\.dismiss) var dismiss
    @State var date: Date
    @State private var time = Date()
    @State private var title = ""

    var body: some View {
        NavigationView {
            Form {
                TextField("Title", text: $title)
                DatePicker("Date", selection: $date, displayedComponents: .date)
                DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
            }
            .navigationTitle("New Training")
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
                        scheduleManager.addTraining(date: combined, title: title)
                        dismiss()
                    }
                }
            }
        }
    }
}
