import OnboardingKit
import SwiftUI

/// Sample content for Trailmark, a made-up hiking app.
enum DemoContent {
    static let forest = Color(red: 0.12, green: 0.55, blue: 0.36)

    static let style = OnboardingStyle(tint: forest)

    /// One gate for the whole app, kept in `UserDefaults.standard`.
    static let gate = OnboardingGate()

    static let pages: [OnboardingPage] = [
        OnboardingPage(
            systemImage: "map.fill",
            title: "Find your next trail",
            subtitle: "Browse 40,000 hand-picked hikes with distance, climb and fresh trail reports.",
            tint: forest
        ),
        OnboardingPage(
            systemImage: "figure.hiking",
            title: "Track every step",
            subtitle: "Record distance, pace and elevation, even when there is no signal.",
            tint: .orange
        ),
        OnboardingPage(
            systemImage: "person.2.fill",
            title: "Hike together",
            subtitle: "Share your live location with friends and meet at the summit.",
            tint: .indigo
        ),
    ]

    static let welcomeFeatures: [OnboardingFeature] = [
        OnboardingFeature(
            systemImage: "map",
            title: "Offline maps",
            subtitle: "Download any region and navigate without a connection."
        ),
        OnboardingFeature(
            systemImage: "chart.line.uptrend.xyaxis",
            title: "Elevation profiles",
            subtitle: "See every climb and descent before you set off."
        ),
        OnboardingFeature(
            systemImage: "cloud.sun.fill",
            title: "Summit weather",
            subtitle: "Hourly forecasts for the top of the trail, not just the car park."
        ),
        OnboardingFeature(
            systemImage: "checkmark.shield.fill",
            title: "Safety check-ins",
            subtitle: "Let someone know when you start and when you are back."
        ),
    ]

    static let welcomeFootnote: LocalizedStringResource =
        "Your hikes stay on this device unless you choose to share them."

    static let releases: [WhatsNew] = [
        WhatsNew(version: "2.0", features: [
            OnboardingFeature(
                systemImage: "applewatch",
                title: "Apple Watch app",
                subtitle: "Start, pause and finish hikes from your wrist."
            ),
            OnboardingFeature(
                systemImage: "square.and.arrow.down",
                title: "GPX import",
                subtitle: "Bring routes from any other app or website."
            ),
        ]),
        latestRelease,
    ]

    static let latestRelease = WhatsNew(version: "2.1", title: "What's New in Trailmark", features: [
        OnboardingFeature(
            systemImage: "sparkles",
            title: "Smart suggestions",
            subtitle: "Trails picked for your pace and the time you have.",
            tint: .purple
        ),
        OnboardingFeature(
            systemImage: "sunset.fill",
            title: "Sunset alerts",
            subtitle: "A reminder to head back with enough daylight left.",
            tint: .orange
        ),
        OnboardingFeature(
            systemImage: "photo.stack.fill",
            title: "Share cards",
            subtitle: "A summary card of your hike with the map, the climb and your photos.",
            tint: .pink
        ),
        OnboardingFeature(
            systemImage: "figure.hiking",
            title: "Group hikes",
            subtitle: "Invite friends, see who is ahead and regroup at the next junction.",
            tint: .blue
        ),
    ])

    static let trails: [Trail] = [
        Trail(name: "Ridge Loop", region: "Blue Mountains", distance: 12.4, climb: 640, symbol: "mountain.2.fill"),
        Trail(name: "Lakeside Path", region: "Lake District", distance: 7.8, climb: 180, symbol: "water.waves"),
        Trail(name: "Pine Valley", region: "Black Forest", distance: 15.2, climb: 820, symbol: "tree.fill"),
        Trail(name: "Coastal Cliffs", region: "Cornwall", distance: 9.6, climb: 410, symbol: "sun.haze.fill"),
    ]
}

struct Trail: Identifiable {
    let name: String
    let region: String
    let distance: Double
    let climb: Int
    let symbol: String

    var id: String { name }
}
