import SwiftUI
import SwiftData

@main
struct PollenTreeApp: App {
        var body: some Scene {
                WindowGroup {
                        RootView()
                            .modelContainer(for: [SymptomLog.self])
                    }
            }
}

