import SwiftUI
import SwiftData

struct MainView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @AppStorage("userAllergyProfile") var profileData: Data = Data()
    @State private var showingScience = false
    @State private var showingSettings = false
    @State private var showingProfile = false
    
    var body: some View {
        TabView {
            // Dashboard Tab
            NavigationStack {
                ScrollView {
                    VStack(spacing: 30) {
                        DashboardHeader(
                            showingScience: $showingScience,
                            showingProfile: $showingProfile,
                            showingSettings: $showingSettings
                        )
                        
                        PollenTreeView(scenario: viewModel.currentScenario)
                            .padding(.horizontal)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("Animated Cypress Tree showing current pollen risk level")
                        
                        RiskScoreDisplay(assessment: viewModel.assessment)
                        
                        AllergenLevelsSection(measurements: viewModel.currentScenario.environment.measurements)
                        
                        WeatherIndicatorsSection(environment: viewModel.currentScenario.environment)
                        
                        DailyAdviceSection(assessment: viewModel.assessment)
                    }
                }
                .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
                .sheet(isPresented: $showingScience) { ScienceInfoView() }
                .sheet(isPresented: $showingProfile) { ProfileManagementView(viewModel: viewModel) }
                .sheet(isPresented: $showingSettings) { GeneralSettingsView() }
            }
            .tabItem { Label("Forecast", systemImage: "leaf.fill") }
            
            PollenMapView(profile: viewModel.profile)
                .tabItem { Label("Map", systemImage: "map.fill") }
            
            SymptomJournalView(viewModel: viewModel)
                .tabItem { Label("Journal", systemImage: "doc.text.fill") }
        }
        .accentColor(.blue)
    }
}

// MARK: - Sub-views

struct DashboardHeader: View {
    @Binding var showingScience: Bool
    @Binding var showingProfile: Bool
    @Binding var showingSettings: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Run, Pollen")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .accessibilityAddTraits(.isHeader)
                
                HStack(spacing: 4) {
                    Image(systemName: "location.fill").font(.caption)
                    Text("Beijing, China").font(.subheadline.bold())
                }
                .foregroundColor(.secondary)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Current location: Beijing, China")
            }
            Spacer()
            
            HStack(spacing: 16) {
                HeaderButton(icon: "book.closed.fill", label: "View Science Mechanics") { showingScience = true }
                HeaderButton(icon: "person.crop.circle.fill", label: "Edit Allergy Profile") { showingProfile = true }
                HeaderButton(icon: "gearshape.fill", label: "App Settings") { showingSettings = true }
            }
        }
        .padding(.horizontal)
        .padding(.top)
    }
}

struct HeaderButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.primary)
        }
        .accessibilityLabel(label)
    }
}

struct RiskScoreDisplay: View {
    let assessment: RiskAssessment
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Personal Risk Score")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .tracking(1.2)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(Int(assessment.normalizedScore))")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                Text("/ 100")
                    .font(.title2.bold())
                    .foregroundColor(.secondary.opacity(0.5))
            }
            
            Text(assessment.riskLevel.rawValue)
                .font(.headline)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(assessment.riskLevel.color.opacity(0.1))
                .foregroundColor(assessment.riskLevel.color)
                .cornerRadius(20)
        }
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Your personal risk score is \(Int(assessment.normalizedScore)) out of 100, which is \(assessment.riskLevel.rawValue)")
    }
}

struct AllergenLevelsSection: View {
    let measurements: [PollenMeasurement]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Current Pollen Levels")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(measurements) { measurement in
                        AllergenLevelCard(measurement: measurement)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct WeatherIndicatorsSection: View {
    let environment: EnvironmentalData
    
    var body: some View {
        HStack(spacing: 20) {
            WeatherStatView(icon: "wind", value: "\(Int(environment.windSpeed))", unit: "mph", label: "Wind")
                .accessibilityLabel("Wind speed: \(Int(environment.windSpeed)) miles per hour")
            
            WeatherStatView(icon: "humidity", value: "\(Int(environment.humidity))", unit: "%", label: "Humidity")
                .accessibilityLabel("Humidity: \(Int(environment.humidity)) percent")
            
            WeatherStatView(
                icon: weatherIcon(for: environment.weatherVisual),
                value: weatherLabel(for: environment.weatherVisual),
                unit: "",
                label: "Condition",
                isTextValue: true
            )
            .accessibilityLabel("Weather condition: \(weatherLabel(for: environment.weatherVisual))")
        }
        .padding(.horizontal)
    }
    
    private func weatherIcon(for type: WeatherType) -> String {
        switch type {
        case .clear: return "sun.max.fill"
        case .windy: return "wind"
        case .rainy: return "cloud.rain.fill"
        case .thunderstorm: return "cloud.bolt.rain.fill"
        case .snowy: return "snow"
        }
    }
    
    private func weatherLabel(for type: WeatherType) -> String {
        switch type {
        case .clear: return "Clear"
        case .windy: return "Windy"
        case .rainy: return "Rainy"
        case .thunderstorm: return "Storm"
        case .snowy: return "Snowy"
        }
    }
}

struct DailyAdviceSection: View {
    let assessment: RiskAssessment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Daily Advice")
                .font(.headline)
                .padding(.horizontal)
                .accessibilityAddTraits(.isHeader)
            
            ForEach(assessment.recommendations, id: \.self) { advice in
                RecommendationRow(text: advice, riskLevel: assessment.riskLevel)
                    .accessibilityLabel("Advice: \(advice)")
            }
        }
        .padding(.bottom, 30)
    }
}

struct AllergenLevelCard: View {
    let measurement: PollenMeasurement
    
    var body: some View {
        VStack(spacing: 10) {
            AllergenDiagram(type: measurement.type)
                .scaleEffect(0.4)
                .frame(width: 30, height: 30)
            
            VStack(spacing: 2) {
                Text(measurement.type.rawValue)
                    .font(.caption2.bold())
                    .foregroundColor(.secondary)
                Text("\(Int(measurement.count))")
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.bold)
            }
        }
        .frame(width: 85, height: 100)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
}

struct WeatherStatView: View {
    let icon: String
    let value: String
    let unit: String
    let label: String
    var isTextValue: Bool = false
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            VStack(spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.system(isTextValue ? .headline : .title3, design: .rounded))
                        .fontWeight(.bold)
                    if !unit.isEmpty {
                        Text(unit).font(.caption2).foregroundColor(.secondary)
                    }
                }
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(1.0)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
}

struct RecommendationRow: View {
    let text: String
    let riskLevel: RiskLevel
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(riskLevel.color.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: adviceIcon(for: text))
                    .foregroundColor(riskLevel.color)
                    .font(.system(size: 18, weight: .bold))
            }
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineLimit(2)
            
            Spacer()
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal)
        .shadow(color: riskLevel.color.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private func adviceIcon(for text: String) -> String {
        if text.contains("mask") { return "facemask.fill" }
        if text.contains("windows") { return "window.shade.closed" }
        if text.contains("outdoor") || text.contains("Avoid") { return "exclamationmark.triangle.fill" }
        if text.contains("purifier") { return "air.purifier" }
        if text.contains("shower") { return "shower.fill" }
        return "info.circle.fill"
    }
}

struct ProfileManagementView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("Allergen Triggers") {
                    ForEach(PollenType.allCases) { type in
                        MultipleSelectionRow(
                            title: type.rawValue,
                            isSelected: viewModel.profile.allergyTypes.contains(type)
                        ) {
                            if viewModel.profile.allergyTypes.contains(type) {
                                viewModel.profile.allergyTypes.remove(type)
                            } else {
                                viewModel.profile.allergyTypes.insert(type)
                            }
                            viewModel.profile.save()
                            viewModel.refreshAssessment()
                        }
                    }
                }
                
                Section("Sensitivity Levels") {
                    ForEach(Array(viewModel.profile.allergyTypes).sorted(by: { $0.rawValue < $1.rawValue })) { type in
                        Picker(type.rawValue, selection: Binding(
                            get: { viewModel.profile.severityMapping[type] ?? .moderate },
                            set: { 
                                viewModel.profile.severityMapping[type] = $0
                                viewModel.profile.save()
                                viewModel.refreshAssessment()
                            }
                        )) {
                            ForEach(Severity.allCases) { severity in
                                Text(severity.rawValue).tag(severity)
                            }
                        }
                    }
                }
                
                Section("Allergy Test Status") {
                    Toggle("I have taken a clinical test", isOn: Binding(
                        get: { viewModel.profile.hasTakenTest },
                        set: { 
                            viewModel.profile.hasTakenTest = $0
                            viewModel.profile.save()
                            viewModel.refreshAssessment()
                        }
                    ))
                }
            }
            .navigationTitle("Allergy Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct GeneralSettingsView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("appLanguage") private var appLanguage = "English"
    @AppStorage("useAutoTheme") private var useAutoTheme = true
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("Appearance") {
                    Toggle("Automatic (Day/Night)", isOn: $useAutoTheme)
                    if !useAutoTheme {
                        Toggle("Dark Mode", isOn: $isDarkMode)
                    }
                }
                
                Section("Localization") {
                    Picker("Language", selection: $appLanguage) {
                        Text("English").tag("English")
                        Text("Chinese").tag("Chinese")
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.2.0").foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct ScienceInfoView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    ScienceCard(
                        title: "Biological Modeling",
                        icon: "chart.bar.doc.horizontal",
                        color: .blue,
                        description: "Our engine uses species-specific potency weights. For example, Ragweed is weighted at 1.9x due to its high allergenicity compared to standard tree pollen."
                    )
                    
                    ScienceCard(
                        title: "Species Sensitivity",
                        icon: "leaf.fill",
                        color: .green,
                        description: "The model adjusts risk based on your personal sensitivity. A 'Moderate' count for a highly sensitive user triggers a 'High' risk alert."
                    )
                    
                    ScienceCard(
                        title: "Atmospheric Physics",
                        icon: "wind",
                        color: .teal,
                        description: "Wind speed and humidity are factored in. High wind increases dispersal, while high humidity can cause pollen grains to burst, increasing bioavailability."
                    )
                    
                    ScienceCard(
                        title: "Thunderstorm Asthma",
                        icon: "cloud.bolt.rain.fill",
                        color: .purple,
                        description: "During storms, osmotic shock causes pollen to rupture into tiny sub-particles that penetrate deeper into the lungs, triggering severe reactions."
                    )
                }
                .padding()
            }
            .navigationTitle("Science Mechanics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
        }
    }
}

struct ScienceCard: View {
    let title: String
    let icon: String
    let color: Color
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(.headline)
            }
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}
