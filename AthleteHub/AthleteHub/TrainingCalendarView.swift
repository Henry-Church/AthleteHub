import SwiftUI

struct TrainingCalendarView: View {
    @EnvironmentObject var scheduleManager: TrainingScheduleManager
    @State private var displayedMonth = Date()
    @State private var selectedDate = Date()
    @State private var showingAddSheet = false

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: displayedMonth)
    }

    private func trainings(for date: Date) -> [ScheduledTraining] {
        scheduleManager.trainings.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    private func daysForMonth() -> [Date?] {
        guard
            let monthFirstDay = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: displayedMonth))
        else { return [] }

        let daysRange = Calendar.current.range(of: .day, in: .month, for: displayedMonth) ?? 1...30
        let firstWeekday = Calendar.current.component(.weekday, from: monthFirstDay)
        var days: [Date?] = Array(repeating: nil, count: (firstWeekday - Calendar.current.firstWeekday + 7) % 7)
        days += daysRange.compactMap { day -> Date? in
            Calendar.current.date(byAdding: .day, value: day - 1, to: monthFirstDay)
        }
        let rows = Int(ceil(Double(days.count) / 7.0))
        days += Array(repeating: nil, count: rows * 7 - days.count)
        return days
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button(action: { displayedMonth = Calendar.current.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth }) {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                Text(monthTitle)
                    .font(.headline)
                Spacer()
                Button(action: { displayedMonth = Calendar.current.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth }) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.horizontal)

            let columns = Array(repeating: GridItem(.flexible()), count: 7)
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(["Sun","Mon","Tue","Wed","Thu","Fri","Sat"], id: \.
self) { day in
                    Text(day)
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
                ForEach(daysForMonth(), id: \.
self) { date in
                    if let actualDate = date {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(Calendar.current.component(.day, from: actualDate))")
                                .font(.caption2)
                                .fontWeight(.bold)
                            ForEach(trainings(for: actualDate).prefix(2)) { t in
                                Text(t.title)
                                    .font(.caption2)
                                    .lineLimit(1)
                            }
                            if trainings(for: actualDate).count > 2 {
                                Text("...")
                                    .font(.caption2)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 40, alignment: .topLeading)
                        .padding(4)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(4)
                        .onTapGesture {
                            selectedDate = actualDate
                            showingAddSheet = true
                        }
                    } else {
                        Color.clear.frame(height: 40)
                    }
                }
            }

            Button(action: {
                selectedDate = Date()
                showingAddSheet = true
            }) {
                Label("Add Training", systemImage: "plus")
            }
            .padding(.top, 8)
            .sheet(isPresented: $showingAddSheet) {
                AddTrainingView(date: selectedDate)
                    .environmentObject(scheduleManager)
            }
        }
        .padding()
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
