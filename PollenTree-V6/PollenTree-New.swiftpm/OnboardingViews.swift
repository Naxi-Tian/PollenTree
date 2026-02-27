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
                Text("Welcome to PollenTree")
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
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(PollenType.allCases) { type in
                        AllergenDiagramCard(type: type, isSelected: selectedAllergens.contains(type)) {
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
                .padding(20)
            }
            
            NavigationLink {
                VisualSeveritySetupView(selectedAllergens: selectedAllergens)
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
            VStack(spacing: 2) {
                Capsule().fill(Color.gray.opacity(0.2)).frame(width: 8, height: 40)
                HStack(spacing: 10) {
                    Circle().fill(Color.green.opacity(0.4)).frame(width: 20, height: 20)
                    Circle().fill(Color.green.opacity(0.4)).frame(width: 20, height: 20)
                }
            }
        case .oak:
            ZStack {
                Image(systemName: "leaf.fill").font(.system(size: 40)).foregroundColor(.green.opacity(0.7))
                Circle().fill(Color.brown.opacity(0.6)).frame(width: 15, height: 15).offset(y: 15)
            }
        case .grass:
            HStack(alignment: .bottom, spacing: 4) {
                Capsule().fill(Color.green.opacity(0.6)).frame(width: 4, height: 40)
                Capsule().fill(Color.green.opacity(0.8)).frame(width: 4, height: 50)
                Capsule().fill(Color.green.opacity(0.5)).frame(width: 4, height: 35)
            }
        case .ragweed, .mugwort, .pigweed:
            ZStack {
                ForEach(0..<5) { i in
                    Capsule()
                        .fill(Color.yellow.opacity(0.6))
                        .frame(width: 6, height: 30)
                        .rotationEffect(.degrees(Double(i) * 72))
                }
                Circle().fill(Color.orange.opacity(0.8)).frame(width: 12, height: 12)
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
    @State private var severityMapping: [PollenType: Severity] = [:]
    @AppStorage("hasCompletedSetup") var hasCompletedSetup: Bool = false
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("How sensitive are you?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text("This helps us calibrate your risk score.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 20)
            .accessibilityElement(children: .combine)
            
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
                                Text(severity.rawValue).tag(severity)
                            }
                        }
                        .pickerStyle(.segmented)
                        .accessibilityLabel("Severity for \(type.rawValue)")
                    }
                    .padding(.vertical, 8)
                }
            }
            .listStyle(PlainListStyle())
            
            Button {
                let profile = AllergyProfile(
                    allergyTypes: selectedAllergens,
                    severityMapping: severityMapping,
                    hasTestedBefore: .notSure
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
                severityMapping[type] = .moderate
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
