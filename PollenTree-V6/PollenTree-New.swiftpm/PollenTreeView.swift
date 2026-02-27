import SwiftUI

// MARK: - Precomputed Physics Data
struct Drop: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let length: CGFloat
}

struct RainData {
    static let shared = RainData()
    let drops: [Drop]
    init() {
        var temp = [Drop]()
        for _ in 0..<80 {
            temp.append(Drop(x: CGFloat.random(in: -150...600), y: CGFloat.random(in: -100...600), length: CGFloat.random(in: 15...35)))
        }
        drops = temp
    }
}

struct PollenParticle: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let isYellow: Bool
    let isBlurred: Bool
    let speedMultiplier: Double
    let driftOffset: Double
}

struct PollenData {
    static let shared = PollenData()
    let particles: [PollenParticle]
    init() {
        var temp = [PollenParticle]()
        for _ in 0..<100 { 
            temp.append(PollenParticle(
                x: CGFloat.random(in: 0...800),
                y: CGFloat.random(in: -50...300),
                size: CGFloat.random(in: 2...5),
                isYellow: Bool.random(),
                isBlurred: Bool.random(),
                speedMultiplier: Double.random(in: 0.5...1.5),
                driftOffset: Double.random(in: 0...Double.pi * 2)
            ))
        }
        particles = temp
    }
}

// MARK: - The View
struct PollenTreeView: View {
    let scenario: Scenario
    
    private var isDaytime: Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        return hour >= 6 && hour < 18
    }
    
    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let wind = scenario.environment.windSpeed
            
            ZStack {
                backgroundColor(for: scenario.environment.weatherVisual)
                    .ignoresSafeArea()
                
                celestialBody(time: time, weather: scenario.environment.weatherVisual)
                
                cloudsLayer(time: time, wind: wind)
                
                if scenario.environment.weatherVisual == .rainy || scenario.environment.weatherVisual == .thunderstorm {
                    rainLayer(time: time)
                }
                
                ZStack {
                    pollenLayer(time: time, wind: wind)
                    integratedTree(time: time, wind: wind)
                }
                .offset(y: 25)
                
                groundLayer
            }
        }
        .frame(height: 300)
        .cornerRadius(24)
        .clipped()
    }
    
    private func backgroundColor(for weather: WeatherType) -> Color {
        if isDaytime {
            switch weather {
            case .clear, .windy:
                return Color(red: 0.5, green: 0.7, blue: 0.9).opacity(0.2)
            case .rainy, .thunderstorm:
                return Color(red: 0.3, green: 0.4, blue: 0.5).opacity(0.3)
            case .snowy:
                return Color.white.opacity(0.2)
            }
        } else {
            return Color(red: 0.05, green: 0.1, blue: 0.2).opacity(0.4)
        }
    }
    
    private func celestialBody(time: TimeInterval, weather: WeatherType) -> some View {
        Group {
            if isDaytime {
                ZStack {
                    Circle()
                        .fill(Color.yellow.opacity(0.3))
                        .frame(width: 80, height: 80)
                        .blur(radius: 15)
                    
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 50))
                        .foregroundColor(Color.yellow)
                        .shadow(color: .orange, radius: 5)
                }
                .offset(x: -110, y: -80)
                .zIndex(-1)
            } else {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 70, height: 70)
                        .blur(radius: 10)
                    
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 45))
                        .foregroundColor(Color(red: 0.9, green: 0.9, blue: 1.0))
                        .shadow(color: .blue.opacity(0.3), radius: 5)
                }
                .offset(x: -110, y: -90)
                .zIndex(-1)
            }
        }
    }
    
    private func cloudsLayer(time: TimeInterval, wind: Double) -> some View {
        let speed = 4.0 + (wind * 1.2)
        let wrapWidth: CGFloat = 600.0
        let offset = CGFloat(time * speed).truncatingRemainder(dividingBy: wrapWidth)
        
        return ZStack {
            CloudGroup().offset(x: offset)
            CloudGroup().offset(x: offset - wrapWidth)
        }
    }
    
    private func rainLayer(time: TimeInterval) -> some View {
        let speed = 500.0
        let wrapHeight: CGFloat = 600.0
        let offset = CGFloat(time * speed).truncatingRemainder(dividingBy: wrapHeight)
        
        return ZStack {
            RainGroup().offset(y: offset)
            RainGroup().offset(y: offset - wrapHeight)
        }
    }
    
    private func pollenLayer(time: TimeInterval, wind: Double) -> some View {
        let totalPollen = scenario.environment.measurements.reduce(0) { $0 + $1.count }
        let particleCount = min(Int(totalPollen / 10), 100)
        
        let isWashedOut = scenario.environment.weatherVisual == .rainy || scenario.environment.weatherVisual == .thunderstorm
        let baseOpacity = isWashedOut ? 0.1 : 0.7
        
        return ZStack {
            ForEach(PollenData.shared.particles.prefix(particleCount)) { p in
                let speed = (15.0 + (wind * 6.0)) * p.speedMultiplier
                let wrapWidth: CGFloat = 800.0
                let xOffset = (p.x + CGFloat(time * speed)).truncatingRemainder(dividingBy: wrapWidth) - 400
                let yDrift = sin(time * 1.5 + p.driftOffset) * 12.0
                
                Circle()
                    .fill(p.isYellow ? Color.yellow.opacity(baseOpacity) : Color.green.opacity(baseOpacity * 0.6))
                    .frame(width: p.size, height: p.size)
                    .blur(radius: p.isBlurred ? 0.5 : 0)
                    .offset(x: xOffset, y: p.y + yDrift)
            }
        }
    }
    
    private func integratedTree(time: TimeInterval, wind: Double) -> some View {
        let swaySpeed = 1.2 + (wind / 12.0)
        let maxAngle = wind > 15 ? 5.0 : (wind > 5 ? 2.5 : 0.8)
        let swayAngle = sin(time * swaySpeed) * maxAngle
        
        return VStack(spacing: -38) {
            // Leaves
            ForEach(0..<4, id: \.self) { index in
                Capsule()
                    .fill(LinearGradient(colors: [Color.green.opacity(0.95), Color(red: 0.02, green: 0.25, blue: 0.02)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 38.0 + (CGFloat(index) * 18.0), height: 75.0 + (CGFloat(index) * 12.0))
                    .shadow(color: .black.opacity(0.12), radius: 3, y: 3)
            }
            // Trunk - Now integrated into the same VStack and rotation
            Rectangle()
                .fill(LinearGradient(colors: [Color(red: 0.35, green: 0.18, blue: 0.08), .black.opacity(0.85)], startPoint: .leading, endPoint: .trailing))
                .frame(width: 22, height: 40)
        }
        .rotationEffect(.degrees(swayAngle), anchor: .bottom)
    }
    
    struct CloudGroup: View {
        var body: some View {
            ZStack {
                Image(systemName: "cloud.fill").font(.system(size: 55)).foregroundColor(Color.gray.opacity(0.15))
                    .offset(x: 30, y: -110)
                Image(systemName: "cloud.fill").font(.system(size: 85)).foregroundColor(Color.gray.opacity(0.12))
                    .offset(x: 220, y: -130)
            }
        }
    }
    
    struct RainGroup: View {
        var body: some View {
            ZStack {
                ForEach(RainData.shared.drops) { drop in
                    Capsule().fill(Color.blue.opacity(0.35)).frame(width: 1.2, height: drop.length)
                        .offset(x: drop.x, y: drop.y).rotationEffect(.degrees(8))
                }
            }
        }
    }
    
    private var groundLayer: some View {
        VStack {
            Spacer()
            ZStack(alignment: .bottom) {
                Ellipse()
                    .fill(LinearGradient(colors: [Color(red: 0.25, green: 0.15, blue: 0.05), .black.opacity(0.75)], startPoint: .top, endPoint: .bottom))
                    .frame(width: 260, height: 35)
                    .offset(y: 18) 
                
                if scenario.environment.measurements.contains(where: { ($0.type == .grass || $0.type == .ragweed) && $0.count > 50 }) {
                    HStack(spacing: 45) {
                        Image(systemName: "leaf.fill").foregroundColor(Color.green.opacity(0.55)).font(.title3)
                        Image(systemName: "leaf.fill").foregroundColor(Color.green.opacity(0.35)).font(.body).offset(y: 4)
                        Image(systemName: "leaf.fill").foregroundColor(Color.green.opacity(0.65)).font(.title2)
                    }
                    .offset(y: 4)
                }
            }
        }
    }
}

// MARK: - Launch Animation View
struct CypressLaunchView: View {
    @State private var isAnimating = false
    @State private var textOpacity = 0.0
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground).ignoresSafeArea()
            
            VStack(spacing: 60) {
                ZStack(alignment: .bottom) {
                    VStack(spacing: -25) {
                        ForEach(0..<4, id: \.self) { index in
                            Capsule()
                                .fill(LinearGradient(colors: [Color.green.opacity(0.85), Color(red: 0.1, green: 0.4, blue: 0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: isAnimating ? (40.0 + (CGFloat(index) * 20.0)) : 0, 
                                       height: isAnimating ? (80.0 + (CGFloat(index) * 12.0)) : 0)
                                .scaleEffect(isAnimating ? 1 : 0)
                                .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(Double(3 - index) * 0.25), value: isAnimating)
                        }
                        Rectangle()
                            .fill(Color.brown)
                            .frame(width: isAnimating ? 22 : 0, height: isAnimating ? 40 : 0)
                            .animation(.spring().delay(1.0), value: isAnimating)
                    }
                }
                .frame(height: 250)
                
                VStack(spacing: 15) {
                    Text("PollenTree")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                    Text("Your Personal Allergy Forecast")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .opacity(textOpacity)
            }
        }
        .onAppear {
            isAnimating = true
            withAnimation(.easeIn(duration: 2.0).delay(1.2)) {
                textOpacity = 1.0
            }
        }
    }
}
