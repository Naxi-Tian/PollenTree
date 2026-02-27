import SwiftUI
import MapKit

@MainActor
class MapViewModel: ObservableObject {
    @Published var regions: [RegionalPollenData] = MockDataService.regionalPollenData
    @Published var selectedRegion: RegionalPollenData?
    
    // Map region state
    @Published var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.92, longitude: 116.44),
        span: MKCoordinateSpan(latitudeDelta: 0.4, longitudeDelta: 0.4)
    )
    
    func getAssessment(for region: RegionalPollenData, profile: AllergyProfile) -> RiskAssessment {
        return region.calculateAssessment(for: profile)
    }
    
    func color(for level: RiskLevel) -> Color {
        switch level {
        case .low: return Color.green
        case .moderate: return Color.yellow
        case .high: return Color.orange
        case .severe: return Color.red
        }
    }
}
