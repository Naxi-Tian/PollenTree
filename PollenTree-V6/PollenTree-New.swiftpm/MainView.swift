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
                        // Header with Location
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Run, Pollen")
                                    .font(.system(size: 34, weight: .bold, design: .rounded))
                                    .accessibilityAddTraits(.isHeader)
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "location.fill")
                                        .font(.caption)
                                    Text("Beijing, China")
                                        .font(.subheadline.bold())
                                }
                                .foregroundColor(.secondary)
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel("Current location: Beijing, China")
                            }
                            Spacer()
                            
                            HStack(spacing: 16) {
                                Button {
                                    showingScience = true
                                } label: {
                                    Image(systemName: "book.closed.fill")
                                        .font(.title2)
                                        .foregroundColor(.primary)
                                }
                                .accessibilityLabel("View Science Mechanics")
                                
                                Button {
                                    showingProfile = true
                                } label: {
                                    Image(systemName: "person.crop.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.primary)
                                }
                                .accessibilityLabel("Edit Allergy Profile")
                                
                                Button {
                                    showingSettings = true
                                } label: {
                                    Image(systemName: "gearshape.fill")
                                        .font(.title2)
                                        .foregroundColor(.primary)
                                }
                                .accessibilityLabel("App Settings")
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top)
                        
                        // Main Tree Visualization
                        PollenTreeView(scenario: viewModel.currentScenario)
                            .padding(.horizontal)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("Animated Cypress Tree showing current pollen risk level")
                        
                        // Risk Score Display
                        VStack(spacing: 12) {
                            Text("Personal Risk Score")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .tracking(1.2)
                            
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("\(Int(viewModel.assessment.normalizedScore))")
                                    .font(.system(size: 72, weight: .bold, design: .rounded))
                                Text("/ 100")
                                    .font(.title2.bold())
                                    .foregroundColor(.secondary.opacity(0.5))
                            }
                            
                            Text(viewModel.assessment.riskLevel.rawValue)
                                .font(.headline)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .background(viewModel.assessment.riskLevel.color.opacity(0.1))
                                .foregroundColor(viewModel.assessment.riskLevel.color)
                                .cornerRadius(20)
                        }
                        .padding(.vertical, 10)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Your personal risk score is \(Int(viewModel.assessment.normalizedScore)) out of 100, which is \(viewModel.assessment.riskLevel.rawValue)")
                        
                        // Raw Allergen Data Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Current Pollen Levels")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(viewModel.currentScenario.environment.measurements) { measurement in
                                        AllergenLevelCard(measurement: measurement)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // Weather Indicators
                        HStack(spacing: 20) {
                            WeatherStatView(
                                icon: "wind", 
                                value: "\(Int(viewModel.currentScenario.environment.windSpeed))", 
                                unit: "mph", 
                                label: "Wind"
                            )
                            .accessibilityLabel("Wind speed: \(Int(viewModel.currentScenario.environment.windSpeed)) miles per hour")
                            
                            WeatherStatView(
                                icon: "humidity", 
                                value: "\(Int(viewModel.currentScenario.environment.humidity))", 
                                unit: "%", 
                                label: "Humidity"
                            )
                            .accessibilityLabel("Humidity: \(Int(viewModel.currentScenario.environment.humidity)) percent")
                            
                            WeatherStatView(
                                icon: weatherIcon(for: viewModel.currentScenario.environment.weatherVisual), 
                                value: weatherLabel(for: viewModel.currentScenario.environment.weatherVisual), 
                                unit: "", 
                                label: "Condition",
                                isTextValue: true
                            )
                            .accessibilityLabel("Weather condition: \(weatherLabel(for: viewModel.currentScenario.environment.weatherVisual))")
                        }
                        .padding(.horizontal)
                        
                        // Recommendations
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Daily Advice")
                                .font(.headline)
                                .padding(.horizontal)
                                .accessibilityAddTraits(.isHeader)
                            
                            ForEach(viewModel.assessment.recommendations, id: \.self) { advice in
                                RecommendationRow(text: advice)
                                    .accessibilityLabel("Advice: \(advice)")
                            }
                        }
                        .padding(.bottom, 30)
                    }
                }
                .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
                .sheet(isPresented: $showingScience) {
                    ScienceInfoView()
                }
                .sheet(isPresented: $showingProfile) {
                    ProfileManagementView(profile: $viewModel.profile)
                }
                .sheet(isPresented: $showingSettings) {
                    GeneralSettingsView()
                }
            }
            .tabItem {
                Label("Forecast", systemImage: "leaf.fill")
            }
            
            // Map Tab
            PollenMapView(profile: viewModel.profile)
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                }
            
            // Journal Tab
            SymptomJournalView()
                .tabItem {
                    Label("Journal", systemImage: "doc.text.fill")
                }
        }
        .accentColor(.green)
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
                .foregroundColor(.green)
            
            VStack(spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value)
                        .font(isTextValue ? .headline : .title3.bold())
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(20)
        .accessibilityElement(children: .combine)
    }
}

struct RecommendationRow: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.green.opacity(0.1))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: "checkmark")
                        .font(.caption.bold())
                        .foregroundColor(.green)
                )
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

struct ScienceInfoView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.1))
                            .frame(width: 120, height: 120)
                        Image(systemName: "microscope")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                    }
                    .padding(.top)
                    .accessibilityHidden(true)
                    
                    VStack(alignment: .leading, spacing: 24) {
                        ScienceSection(
                            title: "Biological Modeling",
                            description: "Our engine uses a multi-factor mathematical model to calculate your risk. It's not just about the count; it's about the biology.",
                            icon: "chart.bar.doc.horizontal",
                            color: .blue
                        )
                        
                        ScienceSection(
                            title: "Species Sensitivity",
                            description: "Different trees have different 'allergenicity' weights. For example, Birch and Ragweed are weighted higher than Pine because they trigger more severe immune responses.",
                            icon: "leaf.fill",
                            color: .green
                        )
                        
                        ScienceSection(
                            title: "Atmospheric Physics",
                            description: "Wind speed and humidity directly affect how pollen grains travel. Dry, windy days increase dispersal, while rain 'washes' the air.",
                            icon: "wind",
                            color: .teal
                        )
                        
                        ScienceSection(
                            title: "Thunderstorm Asthma",
                            description: "During storms, pollen grains can burst into tiny sub-particles that penetrate deeper into the lungs. We apply a 1.7x multiplier during these events.",
                            icon: "cloud.bolt.fill",
                            color: .purple
                        )
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 40)
            }
            .navigationTitle("The Science")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct ScienceSection: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.1))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
            }
            .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(description)")
    }
}

struct ProfileManagementView: View {
    @Binding var profile: AllergyProfile
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Allergy Profile")) {
                    NavigationLink {
                        EditAllergensView(profile: $profile)
                    } label: {
                        HStack {
                            Image(systemName: "leaf.fill")
                                .foregroundColor(.green)
                                .frame(width: 24)
                            Text("Edit My Triggers")
                        }
                    }
                    
                    NavigationLink {
                        EditSeverityView(profile: $profile)
                    } label: {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                                .foregroundColor(.orange)
                                .frame(width: 24)
                            Text("Adjust Sensitivity")
                        }
                    }
                }
                
                Section(header: Text("Medical History")) {
                    Picker("Formal Allergy Test", selection: $profile.hasTestedBefore) {
                        ForEach(TestStatus.allCases) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                    .onChange(of: profile.hasTestedBefore) {
                        profile.save()
                    }
                }
            }
            .navigationTitle("Allergy Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { 
                        profile.save()
                        dismiss() 
                    }
                }
            }
        }
        .accentColor(.green)
    }
}

struct GeneralSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("appLanguage") private var appLanguage = "English"
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Appearance")) {
                    Toggle("Dark Mode", isOn: $isDarkMode)
                }
                
                Section(header: Text("Preferences")) {
                    Picker("Language", selection: $appLanguage) {
                        Text("English").tag("English")
                        Text("Chinese").tag("Chinese")
                    }
                }
                
                Section(header: Text("App Info")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("3.0.0").foregroundColor(.secondary)
                    }
                    
                    Button(role: .destructive) {
                        UserDefaults.standard.removeObject(forKey: "userAllergyProfile")
                        UserDefaults.standard.set(false, forKey: "hasCompletedSetup")
                    } label: {
                        Text("Reset All Data")
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
        .accentColor(.green)
    }
}
