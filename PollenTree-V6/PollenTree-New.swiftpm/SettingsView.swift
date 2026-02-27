import SwiftUI

// This file now contains the detailed editing views for the Allergy Profile
// The main entry points are in MainView.swift as ProfileManagementView and GeneralSettingsView

struct EditAllergensView: View {
    @Binding var profile: AllergyProfile
    
    var body: some View {
        List {
            ForEach(PollenType.allCases) { type in
                MultipleSelectionRow(title: type.rawValue, isSelected: profile.allergyTypes.contains(type)) {
                    if profile.allergyTypes.contains(type) {
                        profile.allergyTypes.remove(type)
                        profile.severityMapping.removeValue(forKey: type)
                    } else {
                        profile.allergyTypes.insert(type)
                        profile.severityMapping[type] = .moderate
                    }
                    profile.save()
                }
                .accessibilityLabel("\(type.rawValue), \(profile.allergyTypes.contains(type) ? "Selected" : "Not selected")")
                .accessibilityHint("Double tap to toggle selection")
            }
        }
        .navigationTitle("My Triggers")
    }
}

struct EditSeverityView: View {
    @Binding var profile: AllergyProfile
    
    var body: some View {
        List {
            if profile.allergyTypes.isEmpty {
                Text("No allergens selected. Go back to select your triggers first.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(Array(profile.allergyTypes).sorted(by: { $0.rawValue < $1.rawValue })) { type in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(type.rawValue).font(.headline)
                        
                        Picker("Severity for \(type.rawValue)", selection: Binding(
                            get: { profile.severityMapping[type] ?? .moderate },
                            set: { 
                                profile.severityMapping[type] = $0
                                profile.save()
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
