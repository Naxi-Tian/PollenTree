import SwiftUI

struct RootView: View {
    @AppStorage("hasCompletedSetup") var hasCompletedSetup: Bool = false
    @State private var isLaunching = true
    
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
    }
}
