import SwiftUI

/// A paged intro: one page per screen with a large icon, a title and a description, page dots,
/// a Continue button that becomes Get Started on the last page, and a Skip button.
///
/// Swipe between pages on iPhone and iPad; use the arrow keys or the Back button on the Mac.
/// From 700 points wide (iPad, Mac) each page lays out in two columns.
///
/// ```swift
/// OnboardingView(pages: [
///     OnboardingPage(systemImage: "map.fill", title: "Find your next trail",
///                    subtitle: "Thousands of hand-picked hikes.", tint: .green),
///     OnboardingPage(systemImage: "figure.hiking", title: "Track every step", tint: .orange),
/// ]) {
///     showsOnboarding = false
/// }
/// ```
public struct OnboardingView: View {
    private let pages: [OnboardingPage]
    private let style: OnboardingStyle
    private let onFinish: () -> Void
    @State private var pager: OnboardingPager
    @FocusState private var isFocused: Bool

    /// - Parameters:
    ///   - pages: The pages, in order.
    ///   - style: Tint and button labels.
    ///   - initialPage: The page to start on.
    ///   - onFinish: Called when the user taps the button on the last page or taps Skip.
    public init(
        pages: [OnboardingPage],
        style: OnboardingStyle = OnboardingStyle(),
        initialPage: Int = 0,
        onFinish: @escaping () -> Void
    ) {
        self.pages = pages
        self.style = style
        self.onFinish = onFinish
        _pager = State(initialValue: OnboardingPager(pageCount: pages.count, index: initialPage))
    }

    public var body: some View {
        GeometryReader { proxy in
            let isWide = OnboardingLayout.isWide(proxy.size)
            let heroSize = isWide ? min(240, proxy.size.height * 0.35) : min(168, proxy.size.height * 0.22)
            VStack(spacing: 0) {
                topBar
                pageContent(isWide: isWide, heroSize: heroSize)
                controls(isWide: isWide)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .background {
            OnboardingBackground(tint: currentTint, showsGlow: style.showsBackgroundGlow)
                .animation(.easeInOut, value: pager.index)
        }
        #if os(iOS)
        .sensoryFeedback(.selection, trigger: pager.index)
        #endif
        #if os(macOS)
        .focusable()
        .focusEffectDisabled()
        .focused($isFocused)
        .onAppear { isFocused = true }
        .onKeyPress(.rightArrow) {
            advance()
            return .handled
        }
        .onKeyPress(.leftArrow) {
            withAnimation(.snappy) { pager.previous() }
            return .handled
        }
        #endif
    }

    // MARK: Parts

    private var currentTint: Color {
        guard pages.indices.contains(pager.index) else { return style.tint }
        return pages[pager.index].tint ?? style.tint
    }

    private var topBar: some View {
        HStack {
            #if os(macOS)
            Button {
                withAnimation(.snappy) { pager.previous() }
            } label: {
                Label("Back", systemImage: "chevron.left")
            }
            .onboardingGlassButtonStyle()
            .opacity(pager.canGoBack ? 1 : 0)
            .disabled(!pager.canGoBack)
            #endif
            Spacer()
            if style.showsSkipButton {
                Button {
                    guard !pager.isFinished else { return }
                    pager.skip()
                    onFinish()
                } label: {
                    Text(style.skipTitle)
                        .font(.body.weight(.semibold))
                }
                .onboardingGlassButtonStyle()
                .buttonBorderShape(.capsule)
                .tint(currentTint)
                .opacity(pager.isLastPage ? 0 : 1)
                .disabled(pager.isLastPage)
                .animation(.easeInOut, value: pager.isLastPage)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .frame(minHeight: 56)
    }

    @ViewBuilder
    private func pageContent(isWide: Bool, heroSize: CGFloat) -> some View {
        #if os(iOS)
        TabView(selection: $pager.index) {
            ForEach(pages.indices, id: \.self) { index in
                OnboardingPageView(
                    page: pages[index],
                    tint: pages[index].tint ?? style.tint,
                    isWide: isWide,
                    heroSize: heroSize
                )
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        #else
        ZStack {
            if pages.indices.contains(pager.index) {
                OnboardingPageView(page: pages[pager.index], tint: currentTint, isWide: isWide, heroSize: heroSize)
                    .id(pager.index)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .trailing)),
                        removal: .opacity.combined(with: .move(edge: .leading))
                    ))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        #endif
    }

    private func controls(isWide: Bool) -> some View {
        VStack(spacing: 24) {
            OnboardingPageIndicator(count: pages.count, index: pager.index, tint: currentTint)
            OnboardingPrimaryButton(
                title: pager.isLastPage ? style.finishTitle : style.continueTitle,
                tint: currentTint,
                action: advance
            )
            .frame(maxWidth: isWide ? 360 : CGFloat.infinity)
            .animation(.snappy, value: pager.isLastPage)
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, isWide ? 40 : 16)
    }

    // MARK: Actions

    /// Next page, or finish on the last one. Finishes only once, however often the button is tapped.
    private func advance() {
        guard !pager.isFinished else { return }
        withAnimation(.snappy) { pager.next() }
        if pager.isFinished { onFinish() }
    }
}

/// One page: the hero image above the text, or beside it in the wide layout.
struct OnboardingPageView: View {
    let page: OnboardingPage
    let tint: Color
    let isWide: Bool
    let heroSize: CGFloat

    var body: some View {
        Group {
            if isWide {
                HStack(spacing: 56) {
                    OnboardingHero(image: page.image, tint: tint, size: heroSize)
                    text(alignment: .leading, textAlignment: .leading)
                        .frame(maxWidth: 440, alignment: .leading)
                }
                .padding(.horizontal, 48)
            } else {
                VStack(spacing: 40) {
                    OnboardingHero(image: page.image, tint: tint, size: heroSize)
                    text(alignment: .center, textAlignment: .center)
                }
                .padding(.horizontal, 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }

    private func text(alignment: HorizontalAlignment, textAlignment: TextAlignment) -> some View {
        VStack(alignment: alignment, spacing: 14) {
            Text(page.title)
                .font(.largeTitle.bold())
                .accessibilityAddTraits(.isHeader)
            if let subtitle = page.subtitle {
                Text(subtitle)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
        .multilineTextAlignment(textAlignment)
        .fixedSize(horizontal: false, vertical: true)
    }
}
