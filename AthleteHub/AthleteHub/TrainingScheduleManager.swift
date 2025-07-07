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
/// Attempts to parse a variety of `DTSTART` formats so that events
/// from most calendar apps are recognised. Only `SUMMARY` and `DTSTART` fields are used.
func importTrainings(from url: URL) {
    guard let text = try? String(contentsOf: url) else { return }

    var imported: [ScheduledTraining] = []
    var currentTitle: String?
    var currentDate: Date?

    // UTC timestamp, e.g. 20250707T183200Z
    let utcFormatter = DateFormatter()
    utcFormatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
    utcFormatter.timeZone = TimeZone(secondsFromGMT: 0)

    // Local timestamp, e.g. 20250707T183200
    let localFormatter = DateFormatter()
    localFormatter.dateFormat = "yyyyMMdd'T'HHmmss"

    // Date-only, e.g. 20250707
    let dateOnlyFormatter = DateFormatter()
    dateOnlyFormatter.dateFormat = "yyyyMMdd"

    for line in text.components(separatedBy: .newlines) {
        switch true {
        case line.hasPrefix("BEGIN:VEVENT"):
            currentTitle = nil
            currentDate = nil

        case line.hasPrefix("SUMMARY:"):
            // drop "SUMMARY:" prefix
            currentTitle = String(line.dropFirst("SUMMARY:".count))

        case line.hasPrefix("DTSTART"):
            if let colon = line.firstIndex(of: ":") {
                let value = String(line[line.index(after: colon)...])
                currentDate =
                    utcFormatter.date(from: value) ?:
                    localFormatter.date(from: value) ?:
                    dateOnlyFormatter.date(from: value)
            }

        case line.hasPrefix("END:VEVENT"):
            if let date = currentDate, let title = currentTitle {
                imported.append(ScheduledTraining(date: date, title: title))
            }

        default:
            continue
        }
    }

    guard !imported.isEmpty else { return }
    // Merge and sort
    trainings.append(contentsOf: imported)
    trainings.sort { $0.date < $1.date }

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
