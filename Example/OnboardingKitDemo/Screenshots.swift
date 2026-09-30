import OnboardingKit
import SwiftUI

/// Scenes used by CI to capture the README screenshots on iPhone and iPad.
/// Launch with `-screenshot <scene>`; normal launches are unaffected.
enum ScreenshotScene: String {
    /// The Apple-style welcome screen with the feature list.
    case welcome
    /// The first page of the paged intro.
    case intro
    /// The "What's New" screen for version 2.1.
    case whatsnew

    static var current: ScreenshotScene? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-screenshot"), arguments.indices.contains(index + 1) else {
            return nil
        }
        return ScreenshotScene(rawValue: arguments[index + 1])
    }

    @MainActor
    @ViewBuilder
    var content: some View {
        switch self {
        case .welcome:
            WelcomeView(
                appName: "Trailmark",
                image: .systemImage("mountain.2.fill"),
                features: DemoContent.welcomeFeatures,
                footnote: DemoContent.welcomeFootnote,
                style: DemoContent.style
            ) {}
        case .intro:
            OnboardingView(pages: DemoContent.pages, style: DemoContent.style) {}
        case .whatsnew:
            WhatsNewView(DemoContent.latestRelease, style: DemoContent.style) {}
        }
    }
}
