import Foundation

/// What to show at launch.
public enum OnboardingDecision: Sendable, Hashable {
    /// The user has not finished onboarding yet.
    case onboarding
    /// The user finished onboarding and has updated from `previous` to a new release.
    case whatsNew(previous: AppVersion)
    /// Nothing to show.
    case nothing
}

/// Whether a "What's New" screen is due.
public enum WhatsNewDecision: Sendable, Hashable {
    /// No version has been recorded yet: a fresh install, or the first launch with OnboardingKit.
    case firstLaunch
    /// The app was updated from `previous` to a new release.
    case show(previous: AppVersion)
    /// The current version, or a newer one, was already seen.
    case upToDate
}

/// Decides whether to show onboarding or "What's New", and remembers what the user has seen.
///
/// The gate has no UI and no side effects until you call one of the `mark…` methods, so it is easy
/// to test and to use with screens of your own.
///
/// ```swift
/// let gate = OnboardingGate()                       // UserDefaults.standard, minor releases
///
/// switch gate.decision(for: AppVersion.current!) {
/// case .onboarding: showOnboarding = true
/// case .whatsNew(let previous): showWhatsNew = true
/// case .nothing: break
/// }
///
/// gate.markOnboardingCompleted(version: .current)   // also counts as having seen this version
/// gate.markWhatsNewSeen(version: "2.1")
/// ```
public struct OnboardingGate: Sendable {
    public let storage: any OnboardingStorage
    /// Prefix of the storage keys. Use different prefixes for independent flows in one app.
    public let keyPrefix: String
    /// Which version change counts as a new release. `.minor` by default.
    public var granularity: VersionGranularity

    public init(
        storage: any OnboardingStorage = UserDefaultsOnboardingStorage(),
        keyPrefix: String = "OnboardingKit",
        granularity: VersionGranularity = .minor
    ) {
        self.storage = storage
        self.keyPrefix = keyPrefix
        self.granularity = granularity
    }

    var onboardingKey: String { "\(keyPrefix).onboardingCompletedVersion" }
    var lastSeenKey: String { "\(keyPrefix).lastSeenVersion" }

    // MARK: State

    /// `true` once `markOnboardingCompleted(version:)` has been called.
    public var hasCompletedOnboarding: Bool {
        storage.string(forKey: onboardingKey) != nil
    }

    /// The app version in which the user finished onboarding, if it was known.
    public var onboardingCompletedVersion: AppVersion? {
        storage.string(forKey: onboardingKey).flatMap(AppVersion.init(string:))
    }

    /// The newest version whose onboarding or "What's New" the user has seen.
    public var lastSeenVersion: AppVersion? {
        storage.string(forKey: lastSeenKey).flatMap(AppVersion.init(string:))
    }

    // MARK: Decisions

    /// `true` until onboarding is marked as completed.
    public var shouldShowOnboarding: Bool {
        !hasCompletedOnboarding
    }

    /// Whether the "What's New" screen for `current` is due.
    public func whatsNewDecision(for current: AppVersion) -> WhatsNewDecision {
        guard let previous = lastSeenVersion else { return .firstLaunch }
        return current.isNewRelease(comparedTo: previous, granularity: granularity) ? .show(previous: previous) : .upToDate
    }

    /// `true` when the app was updated to a new release since the user last saw a "What's New" screen.
    public func shouldShowWhatsNew(for current: AppVersion) -> Bool {
        if case .show = whatsNewDecision(for: current) { return true }
        return false
    }

    /// Onboarding first, then "What's New" for updates, otherwise nothing.
    public func decision(for current: AppVersion) -> OnboardingDecision {
        if shouldShowOnboarding { return .onboarding }
        switch whatsNewDecision(for: current) {
        case .show(let previous): return .whatsNew(previous: previous)
        case .firstLaunch, .upToDate: return .nothing
        }
    }

    // MARK: Recording

    /// Records that the user finished (or skipped) onboarding. `version` also counts as seen, so the
    /// "What's New" screen for the version they installed does not follow right after onboarding.
    public func markOnboardingCompleted(version: AppVersion? = AppVersion.current) {
        storage.set(version?.description ?? "", forKey: onboardingKey)
        if let version { markWhatsNewSeen(version: version) }
    }

    /// Records that the user has seen what is new in `version`. Never moves back to an older version,
    /// so running an older build (a TestFlight downgrade, say) does not show old news again later.
    public func markWhatsNewSeen(version: AppVersion) {
        if let lastSeenVersion, lastSeenVersion >= version { return }
        storage.set(version.description, forKey: lastSeenKey)
    }

    /// Forgets everything, so onboarding shows again on the next check. Useful for a debug menu.
    public func reset() {
        storage.set(nil, forKey: onboardingKey)
        storage.set(nil, forKey: lastSeenKey)
    }
}
