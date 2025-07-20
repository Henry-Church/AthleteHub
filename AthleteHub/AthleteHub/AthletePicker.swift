import SwiftUI

struct AthletePicker: View {
    @EnvironmentObject var coachSelection: CoachSelection

    var body: some View {
        if !coachSelection.athletes.isEmpty {
            Picker("Athlete", selection: $coachSelection.selectedIndex) {
                ForEach(coachSelection.athletes.indices, id: \.self) { idx in
                    Text(coachSelection.athletes[idx].name).tag(idx)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding(.horizontal)
        }
    }
}
