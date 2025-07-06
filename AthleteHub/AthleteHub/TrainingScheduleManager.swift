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
