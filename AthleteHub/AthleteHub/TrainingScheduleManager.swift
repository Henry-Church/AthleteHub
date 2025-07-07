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

    /// Import trainings from an iCalendar (.ics) file.
    /// Only `DTSTART` and `SUMMARY` fields are parsed.
    func importTrainings(from url: URL) {
        guard let text = try? String(contentsOf: url) else { return }

        var currentTitle: String?
        var currentDate: Date?
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

        for line in text.components(separatedBy: .newlines) {
            if line.hasPrefix("BEGIN:VEVENT") {
                currentTitle = nil
                currentDate = nil
            } else if line.hasPrefix("SUMMARY:") {
                currentTitle = String(line.dropFirst(8))
            } else if line.hasPrefix("DTSTART") {
                if let range = line.range(of: ":") {
                    let value = String(line[range.upperBound...])
                    currentDate = dateFormatter.date(from: value)
                }
            } else if line.hasPrefix("END:VEVENT") {
                if let date = currentDate, let title = currentTitle {
                    trainings.append(ScheduledTraining(date: date, title: title))
                }
            }
        }

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
