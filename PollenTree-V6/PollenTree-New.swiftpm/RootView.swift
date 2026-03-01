import SwiftUI

struct RootView: View {
    @AppStorage("hasCompletedSetup") var hasCompletedSetup: Bool = false
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("appLanguage") private var appLanguage = "English"
    @AppStorage("useAutoTheme") private var useAutoTheme = true
    @State private var isLaunching = true
    
    private var isDaytime: Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        return hour >= 6 && hour < 18
    }
    
    var body: some View {
        ZStack {
            if isLaunching {
                CypressLaunchView()
                    .transition(.opacity)
                    .onAppear {
                        // Extended launch animation duration to 4.5 seconds for better visibility
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                            withAnimation(.easeInOut(duration: 1.0)) {
                                isLaunching = false
                            }
                        }
                    }
            } else {
                Group {
                    if hasCompletedSetup {
                        MainView()
                            .transition(.opacity)
                    } else {
                        NavigationStack {
                            OnboardingWelcomeView()
                        }
                        .transition(.opacity)
                    }
                }
                .animation(.easeInOut, value: hasCompletedSetup)
            }
        }
        .preferredColorScheme(useAutoTheme ? (isDaytime ? .light : .dark) : (isDarkMode ? .dark : .light))
        .environment(\.locale, Locale(identifier: appLanguage == "Chinese" ? "zh-Hans" : "en"))
    }
}
