import SwiftUI
import MapKit

struct PollenMapView: View {
    @StateObject private var viewModel = MapViewModel()
    let profile: AllergyProfile
    
    // Initial position for China
    @State private var position: MapCameraPosition = .camera(
        MapCamera(
            centerCoordinate: CLLocationCoordinate2D(latitude: 35.0, longitude: 105.0),
            distance: 5000000,
            heading: 0,
            pitch: 0
        )
    )
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $position) {
                ForEach(viewModel.regions) { region in
                    Annotation(region.name, coordinate: region.coordinate) {
                        let assessment = viewModel.getAssessment(for: region, profile: profile)
                        let color = viewModel.color(for: assessment.riskLevel)
                        
                        VStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .fill(color.opacity(0.3))
                                    .frame(width: 44, height: 44)
                                
                                Circle()
                                    .fill(color)
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Circle().stroke(Color.white, lineWidth: 2)
                                    )
                                
                                if region.environment.isThunderstorm {
                                    Image(systemName: "bolt.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(.white)
                                }
                            }
                            .scaleEffect(assessment.riskLevel == .severe ? 1.2 : 1.0)
                            .onTapGesture {
                                viewModel.selectedRegion = region
                            }
                        }
                    }
                }
            }
            .mapStyle(.standard(elevation: .flat))
            .ignoresSafeArea(edges: .top)
            
            // Legend
            VStack(spacing: 12) {
                HStack(spacing: 20) {
                    LegendItem(color: .green, label: "Low")
                    LegendItem(color: .yellow, label: "Moderate")
                    LegendItem(color: .orange, label: "High")
                    LegendItem(color: .red, label: "Severe")
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 20)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(20)
                .shadow(radius: 5)
            }
            .padding(.bottom, 20)
        }
        .sheet(item: $viewModel.selectedRegion) { region in
            RegionDetailView(region: region, assessment: viewModel.getAssessment(for: region, profile: profile))
                .presentationDetents([.medium])
        }
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(label).font(.caption).foregroundColor(.secondary)
        }
    }
}

struct RegionDetailView: View {
    let region: RegionalPollenData
    let assessment: RiskAssessment
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(region.name)
                        .font(.title2.bold())
                    Text("Regional Risk Assessment")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: assessment.normalizedScore / 100)
                        .stroke(assessment.riskLevel.color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(Int(assessment.normalizedScore))")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                }
                .frame(width: 80, height: 80)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(assessment.riskLevel.rawValue)
                        .font(.headline)
                        .foregroundColor(assessment.riskLevel.color)
                    
                    if let dominant = assessment.dominantAllergen {
                        Text("Dominant: \(dominant.rawValue)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)
            
            if assessment.isThunderstormAsthmaRisk {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text("Thunderstorm Asthma Risk Detected")
                        .font(.subheadline.bold())
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.red.opacity(0.1))
                .foregroundColor(.red)
                .cornerRadius(12)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Environmental Factors")
                    .font(.headline)
                
                HStack {
                    WeatherStatMini(icon: "wind", text: "\(Int(region.environment.windSpeed)) mph")
                    Spacer()
                    WeatherStatMini(icon: "humidity", text: "\(Int(region.environment.humidity))%")
                    Spacer()
                    WeatherStatMini(
                        icon: region.environment.isThunderstorm ? "cloud.bolt.rain.fill" : "sun.max.fill",
                        text: region.environment.isThunderstorm ? "Storm" : "Clear",
                        color: region.environment.isThunderstorm ? .red : .orange
                    )
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)
            
            Spacer()
        }
        .padding(24)
    }
}



struct WeatherStatMini: View {
    let icon: String
    let text: String
    var color: Color = .green
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.subheadline)
            Text(text)
                .font(.caption.bold())
                .foregroundColor(.primary)
        }
    }
}
