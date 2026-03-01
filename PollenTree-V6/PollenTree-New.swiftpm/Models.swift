import Foundation
import SwiftUI

enum WeatherType: String, Hashable {
        case clear, windy, rainy, thunderstorm, snowy
}

struct PollenMeasurement: Identifiable, Equatable, Hashable {
        let id = UUID()
        let type: PollenType
        let count: Double
}

struct EnvironmentalData: Equatable, Hashable {
        let measurements: [PollenMeasurement]
        let humidity: Double
        let windSpeed: Double
        let isThunderstorm: Bool
        let weatherVisual: WeatherType
        
        static func == (lhs: EnvironmentalData, rhs: EnvironmentalData) -> Bool {
                lhs.humidity == rhs.humidity && lhs.windSpeed == rhs.windSpeed && lhs.isThunderstorm == rhs.isThunderstorm
            }
}

struct Scenario: Identifiable, Equatable, Hashable {
        let id = UUID()
        let name: String
        let environment: EnvironmentalData
        
        static func == (lhs: Scenario, rhs: Scenario) -> Bool {
                lhs.id == rhs.id
            }
        
        func hash(into hasher: inout Hasher) {
                hasher.combine(id)
            }
}

struct RiskAssessment {
        let normalizedScore: Double
        let riskLevel: RiskLevel
        let dominantAllergen: PollenType?
        let isThunderstormAsthmaRisk: Bool
        let userSensitizedAllergens: Set<PollenType>
}

struct RecommendationSet {
        let outdoorAdvice: String
        let requiresMask: Bool
        let medicationReminder: String
        var foodSuggestion: String
}

enum RiskLevel: String {
        case low = "Low Risk"
        case moderate = "Moderate"
        case high = "High Risk"
        case severe = "Severe"
        
        init(score: Double) {
                switch score {
                    case 0...25: self = .low
                    case 26...50: self = .moderate
                    case 51...75: self = .high
                    default: self = .severe
                    }
            }
        
        var color: Color {
            switch self {
            case .low: return .green
            case .moderate: return .yellow
            case .high: return .orange
            case .severe: return .red
            }
        }
}
