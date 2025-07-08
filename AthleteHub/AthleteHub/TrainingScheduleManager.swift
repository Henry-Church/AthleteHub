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

import Foundation

/// Represents a scheduled training session
struct ScheduledTraining: Identifiable, Codable {
    let id: UUID
    var date: Date
    var title: String
    
    init(id: UUID = UUID(), date: Date, title: String) {
        self.id = id
        self.date = date
        self.title = title
    }
}

/// Manages the list of scheduled trainings, persisting to UserDefaults
class TrainingScheduleManager: ObservableObject {
    @Published var trainings: [ScheduledTraining] = []
    
    private let saveKey = "ScheduledTrainings"
    
    init() {
        load()
    }
    
    /// Save current trainings array to UserDefaults
    private func save() {
        if let data = try? JSONEncoder().encode(trainings) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }
    
    /// Load trainings array from UserDefaults
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: saveKey),
              let decoded = try? JSONDecoder().decode([ScheduledTraining].self, from: data) else {
            trainings = []
            return
        }
        trainings = decoded
    }
    
    /// Add a new training session
    func addTraining(date: Date, title: String) {
        let newTraining = ScheduledTraining(date: date, title: title)
        trainings.append(newTraining)
        trainings.sort { $0.date < $1.date }
        save()
    }
    
    /// Update an existing training's date and title
    func updateTraining(_ training: ScheduledTraining, date: Date, title: String) {
        if let index = trainings.firstIndex(where: { $0.id == training.id }) {
            trainings[index].date = date
            trainings[index].title = title
            trainings.sort { $0.date < $1.date }
            save()
        }
    }
    
    /// Remove training(s) at specified offsets
    func removeTraining(at offsets: IndexSet) {
        trainings.remove(atOffsets: offsets)
        save()
    }
    
    /// Import trainings from an iCalendar (.ics) file.
    /// Parses SUMMARY and DTSTART fields. Supports UTC, local, and date-only formats.
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
                if let colon = line.firstIndex(of: ":") {
                    let value = String(line[line.index(after: colon)...])
                    currentDate = utcFormatter.date(from: value)
                        ?? localFormatter.date(from: value)
                        ?? dateOnlyFormatter.date(from: value)
                }
            } else if line.hasPrefix("END:VEVENT") {
                if let date = currentDate, let title = currentTitle {
                    imported.append(ScheduledTraining(date: date, title: title))
                }
            }
        }

        guard !imported.isEmpty else { return }
        trainings.append(contentsOf: imported)
        trainings.sort { $0.date < $1.date }
        save()
    }
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
