import SwiftUI
import SwiftData

@main
struct RunPollenApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: SymptomLog.self)
    }
}
