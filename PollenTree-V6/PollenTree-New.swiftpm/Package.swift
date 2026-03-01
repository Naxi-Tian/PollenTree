// swift-tools-version: 5.9

import PackageDescription
import AppleProductTypes

let package = Package(
    name: "RunPollen",
    platforms: [
        .iOS("17.0")
    ],
    products: [
        .iOSApplication(
            name: "Run, Pollen",
            targets: ["AppModule"],
            displayVersion: "3.0.0",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .flower),
            accentColor: .presetColor(.green),
            supportedDeviceFamilies: [
                .pad,
                .phone
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight,
                .landscapeLeft,
                .portraitUpsideDown(.when(deviceFamilies: [.pad]))
            ],
            capabilities: [
                .appPrivacyReport(explanationString: "We track your symptoms to provide personalized allergy insights."),
                .localNetwork(explanationString: "Required for map and location services.")
            ]
        )
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            path: ".",
            swiftSettings: [
                .enableUpcomingFeature("BareSlashRegexLiterals")
            ]
        )
    ]
)
