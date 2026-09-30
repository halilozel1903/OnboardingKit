import SwiftUI

/// An Apple-style welcome screen: "Welcome to" and the app name, a list of features with icons,
/// an optional privacy note and a Continue button.
///
/// On iPad and Mac the header and button sit on the left and the features on the right.
///
/// ```swift
/// WelcomeView(appName: "Trailmark", features: [
///     OnboardingFeature(systemImage: "map", title: "Offline maps",
///                       subtitle: "Download a region and navigate without a signal."),
///     OnboardingFeature(systemImage: "cloud.sun.fill", title: "Trail weather",
///                       subtitle: "Hourly forecasts for the summit."),
/// ]) {
///     showsWelcome = false
/// }
/// ```
public struct WelcomeView: View {
    private let title: LocalizedStringResource
    private let appName: LocalizedStringResource?
    private let image: OnboardingImage?
    private let features: [OnboardingFeature]
    private let footnote: LocalizedStringResource?
    private let style: OnboardingStyle
    private let onContinue: () -> Void

    /// - Parameters:
    ///   - title: The first line, "Welcome to" by default.
    ///   - appName: The second line, drawn in the tint.
    ///   - image: An optional icon above the title, for example your app icon from the asset catalog.
    ///   - features: The rows of the list.
    ///   - footnote: Small print above the button, such as a privacy note.
    ///   - style: Tint and button label (`continueTitle`).
    ///   - onContinue: Called when the user taps the button.
    public init(
        title: LocalizedStringResource = "Welcome to",
        appName: LocalizedStringResource? = nil,
        image: OnboardingImage? = nil,
        features: [OnboardingFeature],
        footnote: LocalizedStringResource? = nil,
        style: OnboardingStyle = OnboardingStyle(),
        onContinue: @escaping () -> Void
    ) {
        self.title = title
        self.appName = appName
        self.image = image
        self.features = features
        self.footnote = footnote
        self.style = style
        self.onContinue = onContinue
    }

    public var body: some View {
        FeatureListScreen(
            features: features,
            footnote: footnote,
            buttonTitle: style.continueTitle,
            style: style,
            action: onContinue
        ) { alignment in
            FeatureListHeader(
                image: image,
                title: title,
                highlight: appName,
                caption: nil,
                tint: style.tint,
                alignment: alignment
            )
        }
    }
}

/// The "What's New" screen for one release: the title, the version and the new features.
///
/// ```swift
/// WhatsNewView(WhatsNew(version: "2.1", features: [
///     OnboardingFeature(systemImage: "sparkles", title: "Smart suggestions",
///                       subtitle: "Trails picked for your pace."),
/// ])) {
///     showsWhatsNew = false
/// }
/// ```
public struct WhatsNewView: View {
    private let whatsNew: WhatsNew
    private let image: OnboardingImage?
    private let style: OnboardingStyle
    private let onContinue: () -> Void

    /// - Parameters:
    ///   - whatsNew: The release and its features.
    ///   - image: An optional icon above the title.
    ///   - style: Tint and button label (`continueTitle`).
    ///   - onContinue: Called when the user taps the button.
    public init(
        _ whatsNew: WhatsNew,
        image: OnboardingImage? = nil,
        style: OnboardingStyle = OnboardingStyle(),
        onContinue: @escaping () -> Void
    ) {
        self.whatsNew = whatsNew
        self.image = image
        self.style = style
        self.onContinue = onContinue
    }

    public var body: some View {
        FeatureListScreen(
            features: whatsNew.features,
            footnote: nil,
            buttonTitle: style.continueTitle,
            style: style,
            action: onContinue
        ) { alignment in
            FeatureListHeader(
                image: image,
                title: whatsNew.title,
                highlight: nil,
                caption: LocalizedStringResource("Version \(whatsNew.version.shortDescription)"),
                tint: style.tint,
                alignment: alignment
            )
        }
    }
}
