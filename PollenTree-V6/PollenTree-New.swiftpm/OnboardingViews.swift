import SwiftUI

struct OnboardingWelcomeView: View {
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 200, height: 200)
                
                Image(systemName: "leaf.arrow.triangle.circlepath")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
            }
            .accessibilityHidden(true)
            
            VStack(spacing: 16) {
                Text("Welcome to Run, Pollen")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                
                Text("Personalized biological forecasting to help you breathe easier every day.")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .accessibilityElement(children: .combine)
            
            Spacer()
            
            NavigationLink {
                VisualAllergenSelectionView()
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
            .accessibilityLabel("Get Started with setup")
        }
    }
}

struct VisualAllergenSelectionView: View {
    @State private var selectedAllergens: Set<PollenType> = []
    @State private var isNotSure = false
    
    let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("What triggers you?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text("Select the allergens you are sensitive to.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 20)
            .accessibilityElement(children: .combine)
            
            ScrollView {
                VStack(spacing: 20) {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(PollenType.allCases) { type in
                            AllergenDiagramCard(type: type, isSelected: selectedAllergens.contains(type)) {
                                if isNotSure { isNotSure = false }
                                if selectedAllergens.contains(type) {
                                    selectedAllergens.remove(type)
                                } else {
                                    selectedAllergens.insert(type)
                                }
                            }
                            .accessibilityLabel("\(type.rawValue), \(selectedAllergens.contains(type) ? "Selected" : "Not selected")")
                            .accessibilityHint("Double tap to toggle selection")
                        }
                    }
                    
                    Divider().padding(.vertical, 10)
                    
                    Button {
                        withAnimation {
                            isNotSure.toggle()
                            if isNotSure {
                                selectedAllergens = Set(PollenType.allCases)
                            } else {
                                selectedAllergens = []
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: isNotSure ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(isNotSure ? .green : .secondary)
                            Text("I'm not sure")
                                .font(.headline)
                                .foregroundColor(isNotSure ? .green : .primary)
                            Spacer()
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(isNotSure ? Color.green.opacity(0.1) : Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(isNotSure ? Color.green : Color.clear, lineWidth: 2)
                        )
                    }
                    .padding(.horizontal, 20)
                    .accessibilityLabel("I'm not sure option. Selecting this will enable learning mode for all allergens.")
                }
                .padding(.bottom, 20)
            }
            
            NavigationLink {
                VisualSeveritySetupView(selectedAllergens: selectedAllergens, isLearningMode: isNotSure)
            } label: {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedAllergens.isEmpty ? Color.gray : Color.green)
                    .cornerRadius(16)
            }
            .disabled(selectedAllergens.isEmpty)
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
            .accessibilityLabel("Continue to severity setup")
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AllergenDiagramCard: View {
    let type: PollenType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.green.opacity(0.1) : Color(UIColor.secondarySystemGroupedBackground))
                        .frame(height: 120)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(isSelected ? Color.green : Color.clear, lineWidth: 2)
                        )
                    
                    AllergenDiagram(type: type)
                }
                
                Text(type.rawValue)
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(isSelected ? .bold : .medium)
                    .foregroundColor(isSelected ? .green : .primary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AllergenDiagram: View {
    let type: PollenType
    
    var body: some View {
        switch type {
        case .cedarCypress:
            VStack(spacing: -10) {
                Triangle().fill(Color.green.opacity(0.8)).frame(width: 30, height: 40)
                Triangle().fill(Color.green.opacity(0.6)).frame(width: 40, height: 50)
            }
        case .birch:
            ZStack {
                Capsule().fill(Color.gray.opacity(0.3)).frame(width: 6, height: 60)
                VStack(spacing: 12) {
                    HStack(spacing: 15) {
                        Circle().fill(Color.green.opacity(0.5)).frame(width: 18, height: 18)
                        Circle().fill(Color.green.opacity(0.5)).frame(width: 18, height: 18)
                    }
                    HStack(spacing: 15) {
                        Circle().fill(Color.green.opacity(0.5)).frame(width: 18, height: 18)
                        Circle().fill(Color.green.opacity(0.5)).frame(width: 18, height: 18)
                    }
                }
            }
        case .oak:
            ZStack {
                Image(systemName: "leaf.fill").font(.system(size: 45)).foregroundColor(.green.opacity(0.7))
                Circle().fill(Color.brown.opacity(0.8)).frame(width: 18, height: 18).offset(y: 18)
            }
        case .grass:
            HStack(alignment: .bottom, spacing: 4) {
                Capsule().fill(Color.green.opacity(0.6)).frame(width: 4, height: 40)
                Capsule().fill(Color.green.opacity(0.8)).frame(width: 4, height: 50)
                Capsule().fill(Color.green.opacity(0.5)).frame(width: 4, height: 35)
            }
        case .ragweed:
            VStack(spacing: 2) {
                ForEach(0..<3) { _ in
                    HStack(spacing: 4) {
                        Circle().fill(Color.yellow.opacity(0.8)).frame(width: 8, height: 8)
                        Circle().fill(Color.yellow.opacity(0.8)).frame(width: 8, height: 8)
                    }
                }
                Capsule().fill(Color.green.opacity(0.4)).frame(width: 4, height: 20)
            }
        case .mugwort:
            ZStack {
                ForEach(0..<6) { i in
                    Capsule()
                        .fill(Color.green.opacity(0.5))
                        .frame(width: 4, height: 35)
                        .rotationEffect(.degrees(Double(i) * 30))
                }
                Circle().fill(Color.gray.opacity(0.3)).frame(width: 10, height: 10)
            }
        case .pigweed:
            VStack(spacing: -5) {
                Circle().fill(Color.red.opacity(0.4)).frame(width: 15, height: 15)
                Circle().fill(Color.red.opacity(0.4)).frame(width: 20, height: 20)
                Circle().fill(Color.red.opacity(0.4)).frame(width: 25, height: 25)
                Capsule().fill(Color.green.opacity(0.3)).frame(width: 4, height: 15)
            }
        case .otherTree:
            Image(systemName: "tree.fill").font(.system(size: 45)).foregroundColor(.green.opacity(0.5))
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct VisualSeveritySetupView: View {
    let selectedAllergens: Set<PollenType>
    let isLearningMode: Bool
    @State private var severityMapping: [PollenType: Severity] = [:]
    @AppStorage("hasCompletedSetup") var hasCompletedSetup: Bool = false
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text(isLearningMode ? "Learning Mode Enabled" : "How sensitive are you?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text(isLearningMode ? "We'll start with equal sensitivity and learn from your logs." : "This helps us calibrate your risk score.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top, 20)
            .accessibilityElement(children: .combine)
            
            if !isLearningMode {
                List {
                    ForEach(Array(selectedAllergens).sorted(by: { $0.rawValue < $1.rawValue })) { type in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                AllergenDiagram(type: type).scaleEffect(0.5).frame(width: 30, height: 30)
                                Text(type.rawValue).font(.headline)
                            }
                            .accessibilityHidden(true)
                            
                            Picker("Severity for \(type.rawValue)", selection: Binding(
                                get: { severityMapping[type] ?? .moderate },
                                set: { severityMapping[type] = $0 }
                            )) {
                                ForEach(Severity.allCases) { severity in
                                    Text(severity.label).tag(severity)
                                }
                            }
                            .pickerStyle(.segmented)
                            .accessibilityLabel("Severity for \(type.rawValue)")
                        }
                        .padding(.vertical, 8)
                    }
                }
                .listStyle(PlainListStyle())
            } else {
                Spacer()
                VStack(spacing: 20) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 80))
                        .foregroundColor(.green)
                    Text("Run, Pollen will analyze your symptom logs against real-time pollen data to identify your triggers automatically.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                Spacer()
            }
            
            Button {
                let profile = AllergyProfile(
                    allergyTypes: selectedAllergens,
                    severityMapping: severityMapping,
                    hasTestedBefore: isLearningMode ? .notSure : .notSure
                )
                profile.save()
                withAnimation {
                    hasCompletedSetup = true
                }
            } label: {
                Text("Complete Setup")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
            .accessibilityLabel("Complete Setup and go to Dashboard")
        }
        .onAppear {
            for type in selectedAllergens {
                severityMapping[type] = isLearningMode ? .moderate : .moderate
            }
        }
    }
}

struct MultipleSelectionRow: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundColor(.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.green)
                }
            }
        }
        .accessibilityLabel("\(title), \(isSelected ? "Selected" : "Not selected")")
    }
}
