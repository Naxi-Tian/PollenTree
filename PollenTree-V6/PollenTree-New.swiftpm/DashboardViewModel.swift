import SwiftUI
import SwiftData

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var currentScenario: Scenario
    @Published var profile: AllergyProfile
    
    @Published private(set) var riskScore: Double = 0.0
    @Published private(set) var riskLevel: RiskLevel = .low
    @Published private(set) var dominantAllergen: PollenType? = nil
    @Published private(set) var isThunderstormAsthmaRisk: Bool = false
    @Published private(set) var recommendations: [String] = []
    
    private var marchScenarios: [Scenario] = []
    
    struct Assessment {
        let normalizedScore: Double
        let riskLevel: RiskLevel
        let dominantAllergen: PollenType?
        let isThunderstormAsthmaRisk: Bool
        let recommendations: [String]
    }
    
    var assessment: Assessment {
        Assessment(
            normalizedScore: riskScore,
            riskLevel: riskLevel,
            dominantAllergen: dominantAllergen,
            isThunderstormAsthmaRisk: isThunderstormAsthmaRisk,
            recommendations: recommendations
        )
    }
    
    init() {
        self.marchScenarios = MockDataService.generateMarchMockData()
        // Default to today's date in March if possible, otherwise first day
        let day = Calendar.current.component(.day, from: Date())
        let index = (day >= 1 && day <= 31) ? day - 1 : 0
        self.currentScenario = marchScenarios[index]
        self.profile = AllergyProfile.load()
        orchestrateCalculations()
    }
    
    func orchestrateCalculations() {
        let assessmentResult = PollenRiskEngine.calculateRisk(environment: currentScenario.environment, profile: profile)
        let recs = RecommendationEngine.generateRecommendations(from: assessmentResult)
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
            self.riskScore = assessmentResult.normalizedScore
            self.riskLevel = assessmentResult.riskLevel
            self.dominantAllergen = assessmentResult.dominantAllergen
            self.isThunderstormAsthmaRisk = assessmentResult.isThunderstormAsthmaRisk
            
            var adviceList: [String] = []
            adviceList.append(recs.outdoorAdvice)
            if recs.requiresMask {
                adviceList.append("Wearing a mask is highly recommended today.")
            }
            adviceList.append(recs.medicationReminder)
            adviceList.append(recs.foodSuggestion)
            self.recommendations = adviceList
        }
    }
    
    func updateScenario(_ newScenario: Scenario) {
        self.currentScenario = newScenario
        orchestrateCalculations()
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }
    
    // Learning logic: Adjust profile based on symptom logs
    func learnFromLogs(_ logs: [SymptomLog]) {
        guard profile.hasTestedBefore == .notSure else { return }
        
        var allergenImpact: [PollenType: Double] = [:]
        
        for log in logs {
            let totalSeverity = Double(log.sneezing + log.itchyEyes + log.congestion)
            if totalSeverity > 0 {
                // Find which allergens were high on this day
                // In a real app, we'd fetch historical data. Here we use the log's captured data.
                if let dominant = log.historicalDominantAllergen {
                    allergenImpact[dominant, default: 0] += totalSeverity
                }
            }
        }
        
        // Update severity mapping based on impact
        var updatedMapping = profile.severityMapping
        for (type, impact) in allergenImpact {
            if impact > 15 {
                updatedMapping[type] = .severe
            } else if impact > 5 {
                updatedMapping[type] = .moderate
            } else {
                updatedMapping[type] = .mild
            }
        }
        
        if updatedMapping != profile.severityMapping {
            profile.severityMapping = updatedMapping
            profile.save()
            orchestrateCalculations()
        }
    }
}
