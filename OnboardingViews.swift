import SwiftUI

struct VisualSeveritySetupView: View {
    @State private var selectedSeverity: Int?

    var body: some View {
        VStack {
            LearningModeSection()
            SeverityPickerSection(selectedSeverity: $selectedSeverity)
        }
        .padding()
    }
}

struct LearningModeSection: View {
    var body: some View {
        // Content for the learning mode section here
        Text("Learning Mode Section")
    }
}

struct SeverityPickerSection: View {
    @Binding var selectedSeverity: Int?

    var body: some View {
        // Content for the severity picker section here
        Text("Severity Picker Section")
    }
}