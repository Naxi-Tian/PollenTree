import SwiftUI

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var currentScenario: Scenario
    @Published var profile: AllergyProfile
    
    @Published private(set) var riskScore: Double = 0.0
    @Published private(set) var riskLevel: RiskLevel = .low
    @Published private(set) var dominantAllergen: PollenType? = nil
    @Published private(set) var isThunderstormAsthmaRisk: Bool = false
    @Published private(set) var recommendations: [String] = []
    
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
    
    init(initialScenario: Scenario = MockDataService.beijingMidMarchWeek[0]) {
        self.currentScenario = initialScenario
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
            
            // Map RecommendationSet to [String]
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
}
