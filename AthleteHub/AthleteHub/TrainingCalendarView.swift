import SwiftUI

struct TrainingCalendarView: View {
    @EnvironmentObject var scheduleManager: TrainingScheduleManager
    @Environment(\.colorScheme) var colorScheme
    @State private var displayedMonth = Calendar.current.startOfMonth(for: Date())
    @State private var selectedDate = Date()
    @State private var showingAddSheet = false

    private var monthFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "LLLL yyyy"
        return f
    }

    private var dayFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f
    }

    private var weekdaySymbols: [String] {
        var symbols = Calendar.current.shortWeekdaySymbols
        let firstWeekday = Calendar.current.firstWeekday - 1
        return Array(symbols[firstWeekday...] + symbols[..<firstWeekday])
    }

    private var monthDates: [Date] {
        let calendar = Calendar.current
        let firstOfMonth = calendar.startOfMonth(for: displayedMonth)
        let weekday = calendar.component(.weekday, from: firstOfMonth)
        let start = calendar.date(byAdding: .day, value: -(weekday - calendar.firstWeekday), to: firstOfMonth) ?? firstOfMonth
        return (0..<42).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    private func trainings(for date: Date) -> [ScheduledTraining] {
        scheduleManager.trainings.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    private func isCurrentMonth(_ date: Date) -> Bool {
        Calendar.current.isDate(date, equalTo: displayedMonth, toGranularity: .month)
    }

    var body: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button(action: {
                    displayedMonth = Calendar.current.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
                }) {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                Text(monthFormatter.string(from: displayedMonth))
                    .font(.headline)
                Spacer()
                Button(action: {
                    displayedMonth = Calendar.current.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
                }) {
                    Image(systemName: "chevron.right")
                }
            }

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                ForEach(monthDates, id: \.self) { date in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(dayFormatter.string(from: date))
                            .font(.caption)
                            .foregroundColor(isCurrentMonth(date) ? .primary : .secondary)
                        ForEach(trainings(for: date)) { t in
                            Text(t.title)
                                .font(.caption2)
                                .lineLimit(2)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(6)
                    .frame(minHeight: 80, alignment: .topLeading)
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

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        self.date(from: dateComponents([.year, .month], from: date)) ?? date
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