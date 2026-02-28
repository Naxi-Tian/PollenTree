import Foundation
import CoreLocation

struct MockDataService {
    
    // Helper function to keep our data entry clean and ensure all 8 allergens are tracked daily.
    private static func createMeasurements(cedar: Double, birch: Double, oak: Double, other: Double, grass: Double, ragweed: Double, mugwort: Double, pigweed: Double) -> [PollenMeasurement] {
        return [
            PollenMeasurement(type: .cedarCypress, count: cedar),
            PollenMeasurement(type: .birch, count: birch),
            PollenMeasurement(type: .oak, count: oak),
            PollenMeasurement(type: .otherTree, count: other),
            PollenMeasurement(type: .grass, count: grass),
            PollenMeasurement(type: .ragweed, count: ragweed),
            PollenMeasurement(type: .mugwort, count: mugwort),
            PollenMeasurement(type: .pigweed, count: pigweed)
        ]
    }
    
    // Simulated Beijing Mid-March Week
    static let beijingMidMarchWeek: [Scenario] = [
        Scenario(name: "Mon", environment: EnvironmentalData(measurements: createMeasurements(cedar: 350, birch: 40, oak: 10, other: 50, grass: 2, ragweed: 0, mugwort: 0, pigweed: 0), humidity: 30, windSpeed: 10, isThunderstorm: false, weatherVisual: .clear)),
        Scenario(name: "Tue", environment: EnvironmentalData(measurements: createMeasurements(cedar: 500, birch: 120, oak: 25, other: 80, grass: 5, ragweed: 0, mugwort: 0, pigweed: 0), humidity: 25, windSpeed: 15, isThunderstorm: false, weatherVisual: .windy)),
        Scenario(name: "Wed", environment: EnvironmentalData(measurements: createMeasurements(cedar: 850, birch: 300, oak: 40, other: 120, grass: 10, ragweed: 0, mugwort: 0, pigweed: 0), humidity: 20, windSpeed: 22, isThunderstorm: false, weatherVisual: .windy)),
        Scenario(name: "Thu", environment: EnvironmentalData(measurements: createMeasurements(cedar: 45, birch: 10, oak: 2, other: 15, grass: 0, ragweed: 0, mugwort: 0, pigweed: 0), humidity: 75, windSpeed: 6, isThunderstorm: false, weatherVisual: .rainy)),
        Scenario(name: "Fri", environment: EnvironmentalData(measurements: createMeasurements(cedar: 200, birch: 80, oak: 30, other: 60, grass: 5, ragweed: 0, mugwort: 0, pigweed: 0), humidity: 45, windSpeed: 8, isThunderstorm: false, weatherVisual: .clear)),
        Scenario(name: "Sat", environment: EnvironmentalData(measurements: createMeasurements(cedar: 400, birch: 250, oak: 100, other: 90, grass: 15, ragweed: 0, mugwort: 0, pigweed: 0), humidity: 40, windSpeed: 12, isThunderstorm: false, weatherVisual: .clear)),
        Scenario(name: "Sun", environment: EnvironmentalData(measurements: createMeasurements(cedar: 450, birch: 350, oak: 150, other: 110, grass: 45, ragweed: 2, mugwort: 5, pigweed: 2), humidity: 85, windSpeed: 18, isThunderstorm: true, weatherVisual: .thunderstorm))
    ]
    
    // Generate a full month of mock data for March
    static func generateMarchMockData() -> [Scenario] {
        var marchData: [Scenario] = []
        let calendar = Calendar.current
        let year = 2026
        let month = 3
        
        for day in 1...31 {
            var components = DateComponents()
            components.year = year
            components.month = month
            components.day = day
            guard let date = calendar.date(from: components) else { continue }
            
            let weekday = calendar.component(.weekday, from: date)
            let dayName = calendar.shortWeekdaySymbols[weekday - 1]
            
            // Create varying pollen levels throughout the month
            // Early March: High Cedar, Low Birch
            // Late March: Lower Cedar, High Birch
            let progress = Double(day) / 31.0
            let cedarBase = 800.0 * (1.0 - progress * 0.5)
            let birchBase = 600.0 * progress
            let oakBase = 200.0 * progress
            
            // Add some randomness
            let randomFactor = Double.random(in: 0.7...1.3)
            let isRainy = Double.random(in: 0...1) < 0.2
            let isWindy = !isRainy && Double.random(in: 0...1) < 0.3
            
            let measurements = createMeasurements(
                cedar: isRainy ? cedarBase * 0.1 : cedarBase * randomFactor,
                birch: isRainy ? birchBase * 0.1 : birchBase * randomFactor,
                oak: isRainy ? oakBase * 0.1 : oakBase * randomFactor,
                other: 100 * randomFactor,
                grass: 20 * progress * randomFactor,
                ragweed: 0,
                mugwort: 0,
                pigweed: 0
            )
            
            let weather: WeatherType = isRainy ? .rainy : (isWindy ? .windy : .clear)
            let humidity = isRainy ? Double.random(in: 70...90) : Double.random(in: 20...50)
            let wind = isWindy ? Double.random(in: 15...25) : Double.random(in: 5...12)
            
            marchData.append(Scenario(
                name: "\(dayName) \(day)",
                environment: EnvironmentalData(
                    measurements: measurements,
                    humidity: humidity,
                    windSpeed: wind,
                    isThunderstorm: isRainy && Double.random(in: 0...1) < 0.3,
                    weatherVisual: weather
                )
            ))
        }
        return marchData
    }
    
    // Expanded China-wide Regional Mock Data
    static let regionalPollenData: [RegionalPollenData] = [
        // North China
        RegionalPollenData(name: "Beijing", coordinate: CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074), environment: EnvironmentalData(measurements: createMeasurements(cedar: 600, birch: 200, oak: 50, other: 100, grass: 10, ragweed: 0, mugwort: 0, pigweed: 0), humidity: 30, windSpeed: 12, isThunderstorm: false, weatherVisual: .clear)),
        RegionalPollenData(name: "Tianjin", coordinate: CLLocationCoordinate2D(latitude: 39.1255, longitude: 117.1901), environment: EnvironmentalData(measurements: createMeasurements(cedar: 450, birch: 150, oak: 40, other: 80, grass: 8, ragweed: 0, mugwort: 0, pigweed: 0), humidity: 35, windSpeed: 14, isThunderstorm: false, weatherVisual: .clear)),
        
        // East China
        RegionalPollenData(name: "Shanghai", coordinate: CLLocationCoordinate2D(latitude: 31.2304, longitude: 121.4737), environment: EnvironmentalData(measurements: createMeasurements(cedar: 100, birch: 50, oak: 200, other: 150, grass: 80, ragweed: 10, mugwort: 5, pigweed: 5), humidity: 65, windSpeed: 10, isThunderstorm: false, weatherVisual: .clear)),
        RegionalPollenData(name: "Hangzhou", coordinate: CLLocationCoordinate2D(latitude: 30.2741, longitude: 120.1551), environment: EnvironmentalData(measurements: createMeasurements(cedar: 80, birch: 40, oak: 180, other: 120, grass: 100, ragweed: 15, mugwort: 8, pigweed: 8), humidity: 70, windSpeed: 8, isThunderstorm: false, weatherVisual: .rainy)),
        RegionalPollenData(name: "Nanjing", coordinate: CLLocationCoordinate2D(latitude: 32.0603, longitude: 118.7969), environment: EnvironmentalData(measurements: createMeasurements(cedar: 120, birch: 60, oak: 220, other: 140, grass: 70, ragweed: 12, mugwort: 6, pigweed: 6), humidity: 60, windSpeed: 12, isThunderstorm: false, weatherVisual: .clear)),
        
        // South China
        RegionalPollenData(name: "Guangzhou", coordinate: CLLocationCoordinate2D(latitude: 23.1291, longitude: 113.2644), environment: EnvironmentalData(measurements: createMeasurements(cedar: 50, birch: 20, oak: 100, other: 300, grass: 150, ragweed: 30, mugwort: 20, pigweed: 20), humidity: 85, windSpeed: 15, isThunderstorm: true, weatherVisual: .thunderstorm)),
        RegionalPollenData(name: "Shenzhen", coordinate: CLLocationCoordinate2D(latitude: 22.5431, longitude: 114.0579), environment: EnvironmentalData(measurements: createMeasurements(cedar: 40, birch: 15, oak: 90, other: 280, grass: 140, ragweed: 25, mugwort: 18, pigweed: 18), humidity: 80, windSpeed: 18, isThunderstorm: true, weatherVisual: .thunderstorm)),
        
        // Central China
        RegionalPollenData(name: "Wuhan", coordinate: CLLocationCoordinate2D(latitude: 30.5928, longitude: 114.3055), environment: EnvironmentalData(measurements: createMeasurements(cedar: 200, birch: 100, oak: 150, other: 180, grass: 60, ragweed: 20, mugwort: 15, pigweed: 15), humidity: 55, windSpeed: 10, isThunderstorm: false, weatherVisual: .clear)),
        
        // Southwest China
        RegionalPollenData(name: "Chengdu", coordinate: CLLocationCoordinate2D(latitude: 30.5728, longitude: 104.0668), environment: EnvironmentalData(measurements: createMeasurements(cedar: 150, birch: 80, oak: 120, other: 200, grass: 90, ragweed: 10, mugwort: 10, pigweed: 10), humidity: 75, windSpeed: 5, isThunderstorm: false, weatherVisual: .clear)),
        RegionalPollenData(name: "Chongqing", coordinate: CLLocationCoordinate2D(latitude: 29.5630, longitude: 106.5516), environment: EnvironmentalData(measurements: createMeasurements(cedar: 130, birch: 70, oak: 110, other: 190, grass: 85, ragweed: 8, mugwort: 8, pigweed: 8), humidity: 80, windSpeed: 6, isThunderstorm: false, weatherVisual: .clear)),
        
        // Northwest China
        RegionalPollenData(name: "Xi'an", coordinate: CLLocationCoordinate2D(latitude: 34.3416, longitude: 108.9398), environment: EnvironmentalData(measurements: createMeasurements(cedar: 400, birch: 180, oak: 60, other: 90, grass: 30, ragweed: 5, mugwort: 5, pigweed: 5), humidity: 30, windSpeed: 15, isThunderstorm: false, weatherVisual: .windy)),
        
        // Northeast China
        RegionalPollenData(name: "Harbin", coordinate: CLLocationCoordinate2D(latitude: 45.8038, longitude: 126.5350), environment: EnvironmentalData(measurements: createMeasurements(cedar: 50, birch: 600, oak: 40, other: 100, grass: 10, ragweed: 0, mugwort: 0, pigweed: 0), humidity: 40, windSpeed: 18, isThunderstorm: false, weatherVisual: .windy))
    ]
}
