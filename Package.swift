// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "OnboardingKit",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(name: "OnboardingKit", targets: ["OnboardingKit"]),
    ],
    targets: [
        .target(name: "OnboardingKit"),
        .testTarget(name: "OnboardingKitTests", dependencies: ["OnboardingKit"]),
    ]
)
