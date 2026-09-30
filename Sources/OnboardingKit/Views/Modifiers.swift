import SwiftUI

// MARK: - Onboarding

extension View {
    /// Presents your own onboarding screen full screen (a sheet on the Mac) while `isPresented` is `true`.
    /// Dismiss it from inside with `@Environment(\.dismiss)`.
    public func onboarding<Content: View>(
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(OnboardingPresentationModifier(isPresented: isPresented, onDismiss: onDismiss, presented: content))
    }

    /// Presents a paged intro full screen (a sheet on the Mac) while `isPresented` is `true`.
    ///
    /// ```swift
    /// ContentView()
    ///     .onboarding(isPresented: $showsIntro, pages: pages)
    /// ```
    public func onboarding(
        isPresented: Binding<Bool>,
        pages: [OnboardingPage],
        style: OnboardingStyle = OnboardingStyle(),
        onFinish: (() -> Void)? = nil
    ) -> some View {
        onboarding(isPresented: isPresented, onDismiss: onFinish) {
            PresentedOnboardingView(pages: pages, style: style)
        }
    }

    /// Presents a paged intro once: on the first launch, until the user finishes or skips it.
    ///
    /// ```swift
    /// ContentView()
    ///     .onboarding(pages: pages)          // UserDefaults, current app version
    /// ```
    ///
    /// - Parameters:
    ///   - gate: Where the state is kept and which updates count. `UserDefaults.standard` by default.
    ///   - version: Recorded as seen when the intro is finished, so "What's New" for it does not follow.
    ///   - onFinish: Called after the intro is dismissed.
    public func onboarding(
        pages: [OnboardingPage],
        gate: OnboardingGate = OnboardingGate(),
        version: AppVersion? = AppVersion.current,
        style: OnboardingStyle = OnboardingStyle(),
        onFinish: (() -> Void)? = nil
    ) -> some View {
        onboarding(gate: gate, version: version, onFinish: onFinish) {
            PresentedOnboardingView(pages: pages, style: style)
        }
    }

    /// Presents your own onboarding screen once, for example a `WelcomeView`.
    /// Dismiss it from inside with `@Environment(\.dismiss)`; dismissing records it as completed.
    public func onboarding<Content: View>(
        gate: OnboardingGate = OnboardingGate(),
        version: AppVersion? = AppVersion.current,
        onFinish: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(GatedOnboardingModifier(gate: gate, version: version, onFinish: onFinish, presented: content))
    }
}

// MARK: - What's New

extension View {
    /// Presents a "What's New" sheet while `isPresented` is `true`.
    public func whatsNew(
        _ whatsNew: WhatsNew,
        isPresented: Binding<Bool>,
        image: OnboardingImage? = nil,
        style: OnboardingStyle = OnboardingStyle(),
        onDismiss: (() -> Void)? = nil
    ) -> some View {
        sheet(isPresented: isPresented, onDismiss: onDismiss) {
            PresentedWhatsNewView(whatsNew: whatsNew, image: image, style: style)
                .onboardingSheetFrame()
        }
    }

    /// Presents a "What's New" sheet once per release, after an update.
    ///
    /// Shows `release` when the app was updated to a new release (by default a new minor version)
    /// and `release` is newer than the version the user saw last. A fresh install only records the
    /// version, unless `showsOnFirstLaunch` is `true`.
    public func whatsNew(
        _ release: WhatsNew,
        gate: OnboardingGate = OnboardingGate(),
        version: AppVersion? = AppVersion.current,
        showsOnFirstLaunch: Bool = false,
        image: OnboardingImage? = nil,
        style: OnboardingStyle = OnboardingStyle()
    ) -> some View {
        whatsNew([release], gate: gate, version: version, showsOnFirstLaunch: showsOnFirstLaunch, image: image, style: style)
    }

    /// Presents a "What's New" sheet once per release, picking the right notes from `releases`:
    /// the newest release the user has not seen that is not newer than the running version.
    ///
    /// ```swift
    /// ContentView()
    ///     .whatsNew([release20, release21])
    /// ```
    public func whatsNew(
        _ releases: [WhatsNew],
        gate: OnboardingGate = OnboardingGate(),
        version: AppVersion? = AppVersion.current,
        showsOnFirstLaunch: Bool = false,
        image: OnboardingImage? = nil,
        style: OnboardingStyle = OnboardingStyle()
    ) -> some View {
        modifier(GatedWhatsNewModifier(
            releases: releases,
            gate: gate,
            version: version,
            showsOnFirstLaunch: showsOnFirstLaunch,
            image: image,
            style: style
        ))
    }
}

// MARK: - Implementation

/// Full screen cover on iOS, sheet on macOS.
struct OnboardingPresentationModifier<Presented: View>: ViewModifier {
    @Binding var isPresented: Bool
    let onDismiss: (() -> Void)?
    let presented: () -> Presented

    func body(content: Content) -> some View {
        #if os(iOS)
        content.fullScreenCover(isPresented: $isPresented, onDismiss: onDismiss) {
            presented()
        }
        #else
        content.sheet(isPresented: $isPresented, onDismiss: onDismiss) {
            presented()
                .onboardingSheetFrame()
        }
        #endif
    }
}

struct GatedOnboardingModifier<Presented: View>: ViewModifier {
    let gate: OnboardingGate
    let version: AppVersion?
    let onFinish: (() -> Void)?
    let presented: () -> Presented

    @State private var isPresented = false
    @State private var hasEvaluated = false

    func body(content: Content) -> some View {
        content
            .modifier(OnboardingPresentationModifier(
                isPresented: $isPresented,
                onDismiss: {
                    gate.markOnboardingCompleted(version: version)
                    onFinish?()
                },
                presented: presented
            ))
            .onAppear {
                guard !hasEvaluated else { return }
                hasEvaluated = true
                guard gate.shouldShowOnboarding else { return }
                // Show the intro instantly, so the app's content does not flash before it.
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    isPresented = true
                }
            }
    }
}

struct GatedWhatsNewModifier: ViewModifier {
    let releases: [WhatsNew]
    let gate: OnboardingGate
    let version: AppVersion?
    let showsOnFirstLaunch: Bool
    let image: OnboardingImage?
    let style: OnboardingStyle

    @State private var presented: WhatsNew?
    @State private var hasEvaluated = false

    func body(content: Content) -> some View {
        content
            .sheet(item: $presented, onDismiss: {
                if let version { gate.markWhatsNewSeen(version: version) }
            }) { release in
                PresentedWhatsNewView(whatsNew: release, image: image, style: style)
                    .onboardingSheetFrame()
            }
            .onAppear {
                guard !hasEvaluated else { return }
                hasEvaluated = true
                presented = evaluate()
            }
    }

    /// The release to show now, or `nil` (after recording the version when nothing is due).
    private func evaluate() -> WhatsNew? {
        guard let version else { return nil }
        let previous: AppVersion?
        switch gate.whatsNewDecision(for: version) {
        case .upToDate:
            return nil
        case .firstLaunch:
            guard showsOnFirstLaunch else {
                gate.markWhatsNewSeen(version: version)
                return nil
            }
            previous = nil
        case .show(let last):
            previous = last
        }
        guard let release = WhatsNew.release(in: releases, current: version, previous: previous, granularity: gate.granularity) else {
            gate.markWhatsNewSeen(version: version)
            return nil
        }
        return release
    }
}

/// `OnboardingView` that dismisses its presentation when finished.
struct PresentedOnboardingView: View {
    let pages: [OnboardingPage]
    let style: OnboardingStyle
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        OnboardingView(pages: pages, style: style) {
            dismiss()
        }
    }
}

/// `WhatsNewView` that dismisses its sheet when the user taps Continue.
struct PresentedWhatsNewView: View {
    let whatsNew: WhatsNew
    let image: OnboardingImage?
    let style: OnboardingStyle
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        WhatsNewView(whatsNew, image: image, style: style) {
            dismiss()
        }
    }
}

extension View {
    /// Gives sheets a sensible size on the Mac, where they otherwise shrink to fit their content.
    @ViewBuilder
    func onboardingSheetFrame() -> some View {
        #if os(macOS)
        frame(minWidth: 640, idealWidth: 800, minHeight: 540, idealHeight: 640)
        #else
        self
        #endif
    }
}
