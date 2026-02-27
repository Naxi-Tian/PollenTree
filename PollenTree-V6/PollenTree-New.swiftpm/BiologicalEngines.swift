import Foundation
import SwiftUI

struct PollenRiskEngine {
    private static let eMax = 5000.0
    private static let moderateExposureThreshold = 250.0
    private static let veryHighThreshold = 1000.0 // Threshold for nonlinear spike
    
    static func calculateRisk(environment: EnvironmentalData, profile: AllergyProfile) -> RiskAssessment {
        var totalBaseExposure = 0.0
        var maxIndividualExposure = 0.0
        var dominantAllergen: PollenType? = nil
        var hasVeryHighConcentration = false
        
        for measurement in environment.measurements {
            if profile.isAllergicTo(measurement.type) {
                let exposure = measurement.count * potencyWeight(for: measurement.type)
                totalBaseExposure += exposure
                
                if measurement.count > veryHighThreshold {
                    hasVeryHighConcentration = true
                }
                
                if exposure > maxIndividualExposure {
                    maxIndividualExposure = exposure
                    dominantAllergen = measurement.type
                }
            }
        }
        
        if totalBaseExposure == 0 {
            return RiskAssessment(normalizedScore: 0, riskLevel: .low, dominantAllergen: nil, isThunderstormAsthmaRisk: false, userSensitizedAllergens: profile.allergyTypes)
        }
        
        let highestSeverity = dominantAllergen.flatMap { profile.severityMapping[$0] } ?? .unknown
        let personalizedExposure = totalBaseExposure * sensitivityMultiplier(for: highestSeverity)
        
        let weatherMultiplier: Double
        let isThunderstormRisk = environment.isThunderstorm && environment.humidity > 80.0 && environment.windSpeed > 15.0 && totalBaseExposure > moderateExposureThreshold
        
        if isThunderstormRisk {
            // Thunderstorm Asthma amplification: General 1.5x, Severe Sensitivity 1.7x
            weatherMultiplier = highestSeverity == .severe ? 1.7 : 1.5
        } else {
            weatherMultiplier = windModifier(for: environment.windSpeed) * humidityModifier(for: environment.humidity)
        }
        
        var adjustedExposure = personalizedExposure * weatherMultiplier
        
        // Threshold Amplification (Nonlinear Spike)
        if hasVeryHighConcentration {
            adjustedExposure *= 1.2
        }
        
        // Final Normalization using logarithmic compression for stability
        let rawScore = 100.0 * (log(1.0 + adjustedExposure) / log(1.0 + eMax))
        let normalizedScore = min(max(rawScore, 0.0), 100.0)
        
        return RiskAssessment(
            normalizedScore: normalizedScore,
            riskLevel: RiskLevel(score: normalizedScore),
            dominantAllergen: dominantAllergen,
            isThunderstormAsthmaRisk: isThunderstormRisk,
            userSensitizedAllergens: profile.allergyTypes
        )
    }
    
    private static func potencyWeight(for type: PollenType) -> Double {
        switch type {
        case .ragweed: return 1.9
        case .birch, .mugwort, .cedarCypress: return 1.8
        case .grass: return 1.6
        case .pigweed: return 1.5
        case .oak: return 1.3
        case .otherTree: return 1.0
        }
    }
    
    private static func sensitivityMultiplier(for severity: Severity) -> Double {
        switch severity {
        case .mild: return 0.6 // Updated to match vision: 1 -> 0.6
        case .moderate: return 1.0 // Updated to match vision: 3 -> 1.0
        case .severe: return 1.8 // Updated to match vision: 5 -> 1.8
        case .unknown: return 1.0
        }
        // Note: The vision had 5 levels, but the app uses 3 (Mild, Moderate, Severe).
        // Mapping: Mild -> 1/2, Moderate -> 3, Severe -> 4/5.
    }
    
    private static func windModifier(for speed: Double) -> Double {
        if speed < 5.0 { return 0.9 }
        if speed <= 15.0 { return 1.0 }
        return 1.2
    }
    
    private static func humidityModifier(for humidity: Double) -> Double {
        if humidity < 40.0 { return 0.9 }
        if humidity <= 80.0 { return 1.0 }
        return 1.1
    }
}

struct RecommendationEngine {
    static func generateRecommendations(from assessment: RiskAssessment) -> RecommendationSet {
        var recs: RecommendationSet
        
        if assessment.isThunderstormAsthmaRisk {
            recs = RecommendationSet(
                outdoorAdvice: "DANGER: Thunderstorm Asthma conditions detected. Stay indoors with windows closed.",
                requiresMask: true,
                medicationReminder: "CRITICAL: Keep rescue inhalers on your person immediately.",
                foodSuggestion: "Focus on warm anti-inflammatory liquids like ginger or turmeric tea."
            )
        } else {
            switch assessment.riskLevel {
            case .low:
                recs = RecommendationSet(outdoorAdvice: "Perfect day to be outside. Enjoy the fresh air!", requiresMask: false, medicationReminder: "No preventative medication needed.", foodSuggestion: "Maintain a normal, balanced diet.")
            case .moderate:
                recs = RecommendationSet(outdoorAdvice: "Safe for most activities. Limit prolonged intense exercise.", requiresMask: false, medicationReminder: "Keep non-drowsy antihistamines handy.", foodSuggestion: "Incorporate Vitamin C-rich foods.")
            case .high:
                recs = RecommendationSet(outdoorAdvice: "Limit outdoor time. Keep windows closed.", requiresMask: true, medicationReminder: "Take your daily preventative antihistamine.", foodSuggestion: "Eat foods high in Omega-3s to manage inflammation.")
            case .severe:
                recs = RecommendationSet(outdoorAdvice: "Stay indoors as much as possible.", requiresMask: true, medicationReminder: "Take preventative medication now.", foodSuggestion: "Focus on quercetin-rich foods (apples, onions).")
            }
        }
        
        if let dominant = assessment.dominantAllergen, assessment.userSensitizedAllergens.contains(dominant) {
            let reactiveFoods = crossReactiveFoods(for: dominant)
            if !reactiveFoods.isEmpty {
                recs.foodSuggestion += "\n\n⚠️ Note: High \(dominant.rawValue) pollen may trigger Oral Allergy Syndrome. Be cautious with raw \(reactiveFoods.joined(separator: ", "))."
            }
        }
        
        return recs
    }
    
    private static func crossReactiveFoods(for pollen: PollenType) -> [String] {
        switch pollen {
        case .birch: return ["apple", "pear", "peach", "carrot", "almond"]
        case .ragweed: return ["melon", "banana", "cucumber", "zucchini"]
        case .mugwort: return ["celery", "carrot", "parsley"]
        case .grass: return ["melon", "tomato", "orange"]
        default: return []
        }
    }
}
