import Foundation
import SwiftUI

/// An image for a page or a header: an SF Symbol or an image from your asset catalog.
public enum OnboardingImage: Sendable, Hashable {
    /// An SF Symbol, drawn white on a tile in the page's tint.
    case systemImage(String)
    /// An image from the app's asset catalog, drawn as is.
    case asset(String)
}

/// One page of the paged intro (`OnboardingView`).
public struct OnboardingPage: Identifiable, Sendable {
    public var id: UUID
    public var image: OnboardingImage
    public var title: LocalizedStringResource
    public var subtitle: LocalizedStringResource?
    /// The page's accent color. `nil` uses the style's tint.
    public var tint: Color?

    public init(
        image: OnboardingImage,
        title: LocalizedStringResource,
        subtitle: LocalizedStringResource? = nil,
        tint: Color? = nil
    ) {
        self.id = UUID()
        self.image = image
        self.title = title
        self.subtitle = subtitle
        self.tint = tint
    }

    public init(
        systemImage: String,
        title: LocalizedStringResource,
        subtitle: LocalizedStringResource? = nil,
        tint: Color? = nil
    ) {
        self.init(image: .systemImage(systemImage), title: title, subtitle: subtitle, tint: tint)
    }
}

/// One row of a feature list: an icon, a title and a short description.
public struct OnboardingFeature: Identifiable, Sendable {
    public var id: UUID
    public var systemImage: String
    public var title: LocalizedStringResource
    public var subtitle: LocalizedStringResource
    /// The icon's color. `nil` uses the style's tint.
    public var tint: Color?

    public init(
        systemImage: String,
        title: LocalizedStringResource,
        subtitle: LocalizedStringResource,
        tint: Color? = nil
    ) {
        self.id = UUID()
        self.systemImage = systemImage
        self.title = title
        self.subtitle = subtitle
        self.tint = tint
    }
}

/// The contents of a "What's New" screen for one release.
public struct WhatsNew: Identifiable, Sendable {
    public var version: AppVersion
    public var title: LocalizedStringResource
    public var features: [OnboardingFeature]

    public var id: AppVersion { version }

    public init(version: AppVersion, title: LocalizedStringResource = "What's New", features: [OnboardingFeature]) {
        self.version = version
        self.title = title
        self.features = features
    }

    /// The release notes to show after updating from `previous` to `current`: the newest release that is
    /// not newer than `current` and is newer than `previous`, both compared at `granularity`.
    ///
    /// With releases for 2.0 and 2.1, updating from 1.4 to 2.1.2 shows 2.1, updating from 2.1 to 2.1.2
    /// shows nothing, and a version without notes of its own (2.2) shows the latest notes the user has not seen.
    public static func release(
        in releases: [WhatsNew],
        current: AppVersion,
        previous: AppVersion?,
        granularity: VersionGranularity = .minor
    ) -> WhatsNew? {
        let currentRelease = current.truncated(to: granularity)
        let previousRelease = previous?.truncated(to: granularity)
        return releases
            .filter { release in
                let version = release.version.truncated(to: granularity)
                guard version <= currentRelease else { return false }
                guard let previousRelease else { return true }
                return version > previousRelease
            }
            .max { $0.version < $1.version }
    }
}

/// Colors and labels shared by every OnboardingKit screen.
public struct OnboardingStyle: Sendable {
    /// Accent color of buttons, icons and the background glow.
    public var tint: Color
    /// Label of the button that moves to the next page.
    public var continueTitle: LocalizedStringResource
    /// Label of the button on the last page.
    public var finishTitle: LocalizedStringResource
    /// Label of the button that ends the intro early.
    public var skipTitle: LocalizedStringResource
    /// Shows the skip button on every page but the last.
    public var showsSkipButton: Bool
    /// A soft wash of the tint behind the content.
    public var showsBackgroundGlow: Bool

    public init(
        tint: Color = .accentColor,
        continueTitle: LocalizedStringResource = "Continue",
        finishTitle: LocalizedStringResource = "Get Started",
        skipTitle: LocalizedStringResource = "Skip",
        showsSkipButton: Bool = true,
        showsBackgroundGlow: Bool = true
    ) {
        self.tint = tint
        self.continueTitle = continueTitle
        self.finishTitle = finishTitle
        self.skipTitle = skipTitle
        self.showsSkipButton = showsSkipButton
        self.showsBackgroundGlow = showsBackgroundGlow
    }
}

/// Layout decisions shared by the screens.
enum OnboardingLayout {
    /// Width from which the screens switch to two columns: iPad in any orientation, Mac windows,
    /// iPhone Pro Max in landscape.
    static let wideWidth: CGFloat = 700

    static func isWide(_ size: CGSize) -> Bool {
        size.width >= wideWidth
    }
}
