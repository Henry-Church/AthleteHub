import SwiftUI

struct TrainingCalendarView: View {
    @EnvironmentObject var scheduleManager: TrainingScheduleManager
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedDate = Date()
    @State private var showingAddSheet = false

    private var shortFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "E d"
        return f
    }

    private var startOfWeek: Date {
        Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
    }

    private var upcomingDates: [Date] {
        (0..<14).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: startOfWeek) }
    }

    private func trainings(for date: Date) -> [ScheduledTraining] {
        scheduleManager.trainings.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    var body: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

        VStack(alignment: .leading, spacing: 12) {
            Text("Upcoming Trainings")
                .font(.headline)
                .foregroundColor(.primary)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(upcomingDates, id: \.self) { date in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(shortFormatter.string(from: date))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        ForEach(trainings(for: date)) { t in
                            Text(t.title)
                                .font(.caption2)
                                .lineLimit(2)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(6)
                    .frame(minHeight: 100, alignment: .topLeading)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                    .onTapGesture {
                        selectedDate = date
                        showingAddSheet = true
                    }
                }
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color(.secondarySystemBackground) : Color.white)
        .cornerRadius(16)
        .shadow(color: Color.yellow.opacity(0.3), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
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
