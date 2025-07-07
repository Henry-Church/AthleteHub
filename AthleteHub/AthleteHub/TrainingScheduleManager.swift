import Foundation
import SwiftUI

struct ScheduledTraining: Identifiable, Codable, Equatable {
    var id = UUID()
    var date: Date
    var title: String
}

class TrainingScheduleManager: ObservableObject {
    @Published var trainings: [ScheduledTraining] = []

    init() {
        load()
    }

    func addTraining(date: Date, title: String) {
        trainings.append(ScheduledTraining(date: date, title: title))
        save()
    }

    func updateTraining(_ training: ScheduledTraining, date: Date, title: String) {
        if let index = trainings.firstIndex(where: { $0.id == training.id }) {
            trainings[index].date = date
            trainings[index].title = title
            save()
        }
    }

    func removeTraining(at offsets: IndexSet) {
        trainings.remove(atOffsets: offsets)
        save()
    }

    /// Import trainings from an iCalendar (.ics) file. Attempts to parse a
    /// variety of `DTSTART` formats so that events from most calendar apps are
    /// recognised.
    func importTrainings(from url: URL) {
        guard let text = try? String(contentsOf: url) else { return }

        var imported: [ScheduledTraining] = []
        var currentTitle: String?
        var currentDate: Date?

        let utcFormatter = DateFormatter()
        utcFormatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        utcFormatter.timeZone = TimeZone(secondsFromGMT: 0)

        let localFormatter = DateFormatter()
        localFormatter.dateFormat = "yyyyMMdd'T'HHmmss"

        let dateOnlyFormatter = DateFormatter()
        dateOnlyFormatter.dateFormat = "yyyyMMdd"

        for line in text.components(separatedBy: .newlines) {
            if line.hasPrefix("BEGIN:VEVENT") {
                currentTitle = nil
                currentDate = nil
            } else if line.hasPrefix("SUMMARY:") {
                currentTitle = String(line.dropFirst("SUMMARY:".count))
            } else if line.hasPrefix("DTSTART") {
                if let range = line.range(of: ":") {
                    let value = String(line[range.upperBound...])
                    currentDate =
                        utcFormatter.date(from: value) ??
                        localFormatter.date(from: value) ??
                        dateOnlyFormatter.date(from: value)
                }
            } else if line.hasPrefix("END:VEVENT") {
                if let d = currentDate, let title = currentTitle {
                    imported.append(ScheduledTraining(date: d, title: title))
                }
            }
        }

        guard !imported.isEmpty else { return }

        trainings.append(contentsOf: imported)
        trainings = trainings.sorted { $0.date < $1.date }
        save()
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: "scheduledTrainings"),
           let decoded = try? JSONDecoder().decode([ScheduledTraining].self, from: data) {
            trainings = decoded
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(trainings) {
            UserDefaults.standard.set(data, forKey: "scheduledTrainings")
        }
    }
}
