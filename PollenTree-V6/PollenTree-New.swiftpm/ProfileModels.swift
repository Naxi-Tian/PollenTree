import Foundation
import SwiftUI
import SwiftData

enum PollenType: String, Codable, CaseIterable, Identifiable, Hashable {
    var id: String { rawValue }
    case cedarCypress = "Cedar/Cypress"
    case birch = "Birch"
    case oak = "Oak"
    case otherTree = "Other Trees"
    case grass = "Grass"
    case ragweed = "Ragweed"
    case mugwort = "Mugwort"
    case pigweed = "Pigweed"
    
    var sfSymbol: String {
        switch self {
            case .cedarCypress, .birch, .oak, .otherTree: return "tree.fill"
            case .grass: return "leaf.fill"
            case .ragweed, .mugwort, .pigweed: return "camera.macro"
        }
    }
}

enum Severity: String, Codable, CaseIterable, Identifiable {
    var id: String { rawValue }
    case mild = "Mild"
    case moderate = "Moderate"
    case severe = "Severe"
    case unknown = "I don't know"
}

enum TestStatus: String, Codable, CaseIterable, Identifiable {
    var id: String { rawValue }
    case yes = "Yes"
    case no = "No"
    case notSure = "Not Sure"
}

// MARK: - Symptom Journaling Models
enum SymptomSeverity: Int, Codable, CaseIterable, Identifiable {
    var id: Int { rawValue }
    case none = 0
    case mild = 1
    case moderate = 2
    case severe = 3
    
    var label: String {
        switch self {
        case .none: return "None"
        case .mild: return "Mild"
        case .moderate: return "Moderate"
        case .severe: return "Severe"
        }
    }
    
    var color: Color {
        switch self {
        case .none: return .gray
        case .mild: return .green
        case .moderate: return .orange
        case .severe: return .red
        }
    }
}

@Model
final class SymptomLog: Identifiable {
    var id: UUID
    var date: Date
    var sneezing: Int // Store as Int for SwiftData compatibility
    var itchyEyes: Int
    var congestion: Int
    var notes: String
    
    // For historical correlation
    var historicalRiskScore: Double?
    var historicalDominantAllergenRaw: String?
    
    var historicalDominantAllergen: PollenType? {
        get { historicalDominantAllergenRaw.flatMap { PollenType(rawValue: $0) } }
        set { historicalDominantAllergenRaw = newValue?.rawValue }
    }
    
    init(date: Date = Date(), 
         sneezing: SymptomSeverity = .none, 
         itchyEyes: SymptomSeverity = .none, 
         congestion: SymptomSeverity = .none, 
         notes: String = "",
         historicalRiskScore: Double? = nil,
         historicalDominantAllergen: PollenType? = nil) {
        self.id = UUID()
        self.date = date
        self.sneezing = sneezing.rawValue
        self.itchyEyes = itchyEyes.rawValue
        self.congestion = congestion.rawValue
        self.notes = notes
        self.historicalRiskScore = historicalRiskScore
        self.historicalDominantAllergenRaw = historicalDominantAllergen?.rawValue
    }
    
    var sneezingSeverity: SymptomSeverity {
        SymptomSeverity(rawValue: sneezing) ?? .none
    }
    
    var itchyEyesSeverity: SymptomSeverity {
        SymptomSeverity(rawValue: itchyEyes) ?? .none
    }
    
    var congestionSeverity: SymptomSeverity {
        SymptomSeverity(rawValue: congestion) ?? .none
    }
}

struct AllergyProfile: Codable, Equatable {
    var allergyTypes: Set<PollenType> = []
    var severityMapping: [PollenType: Severity] = [:]
    var hasTestedBefore: TestStatus = .notSure
    
    func isAllergicTo(_ type: PollenType) -> Bool {
        return allergyTypes.contains(type)
    }
    
    // Helper to save profile
    func save() {
        if let encoded = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(encoded, forKey: "userAllergyProfile")
        }
    }
    
    static func load() -> AllergyProfile {
        guard let data = UserDefaults.standard.data(forKey: "userAllergyProfile"),
              let decoded = try? JSONDecoder().decode(AllergyProfile.self, from: data) else {
            return AllergyProfile()
        }
        return decoded
    }
}
