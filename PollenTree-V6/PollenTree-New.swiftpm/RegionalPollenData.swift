import Foundation
import CoreLocation

struct RegionalPollenData: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let environment: EnvironmentalData
    
    // Computed RiskAssessment using existing RiskEngine
    // Note: For simplicity in this mock, we use a default profile or pass one in
    func calculateAssessment(for profile: AllergyProfile) -> RiskAssessment {
        return PollenRiskEngine.calculateRisk(environment: environment, profile: profile)
    }
}
