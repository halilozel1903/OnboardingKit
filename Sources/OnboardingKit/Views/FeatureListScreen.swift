import SwiftUI

/// The layout shared by `WelcomeView` and `WhatsNewView`: a header, a list of features and a button.
///
/// Compact: everything in one centered column that scrolls, with the button pinned to the bottom.
/// Wide (iPad, Mac): the header and the button on the left, the features on the right.
struct FeatureListScreen<Header: View>: View {
    let features: [OnboardingFeature]
    let footnote: LocalizedStringResource?
    let buttonTitle: LocalizedStringResource
    let style: OnboardingStyle
    let action: () -> Void
    @ViewBuilder let header: (HorizontalAlignment) -> Header

    var body: some View {
        GeometryReader { proxy in
            if OnboardingLayout.isWide(proxy.size) {
                wide
                    .frame(width: proxy.size.width, height: proxy.size.height)
            } else {
                compact
                    .frame(width: proxy.size.width, height: proxy.size.height)
            }
        }
        .background {
            OnboardingBackground(tint: style.tint, showsGlow: style.showsBackgroundGlow)
        }
    }

    // MARK: Compact

    private var compact: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 44) {
                    header(.center)
                        .multilineTextAlignment(.center)
                    featureList(spacing: 28)
                }
                .padding(.horizontal, 32)
                .padding(.top, 48)
                .padding(.bottom, 24)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)

            VStack(spacing: 16) {
                footnoteView
                    .multilineTextAlignment(.center)
                OnboardingPrimaryButton(title: buttonTitle, tint: style.tint, action: action)
                    .frame(maxWidth: 480)
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 16)
        }
    }

    // MARK: Wide

    private var wide: some View {
        HStack(alignment: .center, spacing: 64) {
            VStack(alignment: .leading, spacing: 32) {
                header(.leading)
                    .multilineTextAlignment(.leading)
                footnoteView
                    .multilineTextAlignment(.leading)
                OnboardingPrimaryButton(title: buttonTitle, tint: style.tint, action: action)
                    .frame(maxWidth: 320)
            }
            .frame(maxWidth: 400, alignment: .leading)

            ViewThatFits(in: .vertical) {
                featureList(spacing: 36)
                ScrollView {
                    featureList(spacing: 36)
                        .padding(.vertical, 24)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            .frame(maxWidth: 460)
        }
        .padding(.horizontal, 56)
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Parts

    private func featureList(spacing: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: spacing) {
            ForEach(features) { feature in
                OnboardingFeatureRow(feature: feature, tint: style.tint)
            }
        }
    }

    @ViewBuilder
    private var footnoteView: some View {
        if let footnote {
            Text(footnote)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// A title in the primary color above a highlighted line in the tint, with an optional hero image.
struct FeatureListHeader: View {
    let image: OnboardingImage?
    let title: LocalizedStringResource
    let highlight: LocalizedStringResource?
    let caption: LocalizedStringResource?
    let tint: Color
    let alignment: HorizontalAlignment

    var body: some View {
        VStack(alignment: alignment, spacing: 20) {
            if let image {
                OnboardingHero(image: image, tint: tint, size: 88)
            }
            VStack(alignment: alignment, spacing: 4) {
                Text(title)
                    .font(.largeTitle.bold())
                    .foregroundStyle(.primary)
                if let highlight {
                    Text(highlight)
                        .font(.largeTitle.bold())
                        .foregroundStyle(tint)
                }
                if let caption {
                    Text(caption)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .padding(.top, 6)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
        }
    }
}
