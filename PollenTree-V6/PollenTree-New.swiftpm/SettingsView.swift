import SwiftUI

// This file now contains the detailed editing views for the Allergy Profile
// The main entry points are in MainView.swift as ProfileManagementView and GeneralSettingsView

struct EditAllergensView: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        List {
            ForEach(PollenType.allCases) { type in
                MultipleSelectionRow(title: type.rawValue, isSelected: viewModel.profile.allergyTypes.contains(type)) {
                    if viewModel.profile.allergyTypes.contains(type) {
                        viewModel.profile.allergyTypes.remove(type)
                        viewModel.profile.severityMapping.removeValue(forKey: type)
                    } else {
                        viewModel.profile.allergyTypes.insert(type)
                        viewModel.profile.severityMapping[type] = .moderate
                    }
                    viewModel.profile.save()
                    viewModel.orchestrateCalculations()
                }
                .accessibilityLabel("\(type.rawValue), \(viewModel.profile.allergyTypes.contains(type) ? "Selected" : "Not selected")")
                .accessibilityHint("Double tap to toggle selection")
            }
        }
        .navigationTitle("My Triggers")
    }
}

struct EditSeverityView: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        List {
            if viewModel.profile.allergyTypes.isEmpty {
                Text("No allergens selected. Go back to select your triggers first.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(Array(viewModel.profile.allergyTypes).sorted(by: { $0.rawValue < $1.rawValue })) { type in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(type.rawValue).font(.headline)
                        
                        Picker("Severity for \(type.rawValue)", selection: Binding(
                            get: { viewModel.profile.severityMapping[type] ?? .moderate },
                            set: { 
                                viewModel.profile.severityMapping[type] = $0
                                viewModel.profile.save()
                                viewModel.orchestrateCalculations()
                            }
                        )) {
                            ForEach(Severity.allCases) { severity in
                                Text(severity.rawValue).tag(severity)
                            }
                        }
                        .pickerStyle(.segmented)
                        .accessibilityLabel("Severity for \(type.rawValue)")
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle("Sensitivity")
    }
}
