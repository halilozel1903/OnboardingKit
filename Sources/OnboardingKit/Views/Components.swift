import SwiftUI

/// Capsule page dots with the current page drawn wider, like the system page control.
public struct OnboardingPageIndicator: View {
    private let count: Int
    private let index: Int
    private let tint: Color

    public init(count: Int, index: Int, tint: Color = .accentColor) {
        self.count = max(0, count)
        self.index = index
        self.tint = tint
    }

    public var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { page in
                Capsule()
                    .fill(page == index ? tint : Color.secondary.opacity(0.3))
                    .frame(width: page == index ? 24 : 8, height: 8)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .onboardingGlass(in: Capsule())
        .animation(.snappy, value: index)
        .accessibilityElement()
        .accessibilityLabel(Text("Page \(index + 1) of \(count)"))
    }
}

/// The large button at the bottom of every screen: Liquid Glass on iOS 26 and macOS 26,
/// a bordered prominent capsule before.
struct OnboardingPrimaryButton: View {
    let title: LocalizedStringResource
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .controlSize(.large)
        .buttonBorderShape(.capsule)
        .onboardingProminentButtonStyle()
        .tint(tint)
        .keyboardShortcut(.defaultAction)
    }
}

/// An SF Symbol on a rounded tile in the tint, or an asset image.
struct OnboardingHero: View {
    let image: OnboardingImage
    let tint: Color
    let size: CGFloat

    var body: some View {
        Group {
            switch image {
            case .systemImage(let name):
                RoundedRectangle(cornerRadius: size * 0.27, style: .continuous)
                    .fill(tint.gradient)
                    .overlay {
                        Image(systemName: name)
                            .font(.system(size: size * 0.44, weight: .semibold))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.white)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: size * 0.27, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                    }
                    .shadow(color: tint.opacity(0.35), radius: size * 0.12, y: size * 0.06)
            case .asset(let name):
                Image(name)
                    .resizable()
                    .scaledToFit()
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// One row of a feature list: tinted icon, bold title, secondary description.
struct OnboardingFeatureRow: View {
    let feature: OnboardingFeature
    let tint: Color
    @ScaledMetric(relativeTo: .title) private var iconSize: CGFloat = 30

    var body: some View {
        HStack(alignment: .center, spacing: 18) {
            Image(systemName: feature.systemImage)
                .font(.system(size: iconSize))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(feature.tint ?? tint)
                .frame(width: iconSize * 1.6)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(feature.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(feature.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
    }
}

/// The screen background with an optional soft wash of the tint from the top.
struct OnboardingBackground: View {
    let tint: Color
    let showsGlow: Bool

    var body: some View {
        ZStack {
            Rectangle().fill(.background)
            if showsGlow {
                LinearGradient(
                    colors: [tint.opacity(0.22), tint.opacity(0.06), .clear],
                    startPoint: .top,
                    endPoint: .center
                )
                RadialGradient(
                    colors: [tint.opacity(0.18), .clear],
                    center: .topTrailing,
                    startRadius: 0,
                    endRadius: 520
                )
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

extension View {
    /// Liquid Glass on iOS 26 / macOS 26, a thin material before.
    @ViewBuilder
    func onboardingGlass(in shape: some Shape) -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            glassEffect(.regular, in: shape)
        } else {
            background(.ultraThinMaterial, in: shape)
        }
    }

    /// `.glassProminent` on iOS 26 / macOS 26, `.borderedProminent` before.
    @ViewBuilder
    func onboardingProminentButtonStyle() -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            buttonStyle(.glassProminent)
        } else {
            buttonStyle(.borderedProminent)
        }
    }

    /// `.glass` on iOS 26 / macOS 26, `.bordered` before.
    @ViewBuilder
    func onboardingGlassButtonStyle() -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            buttonStyle(.glass)
        } else {
            buttonStyle(.bordered)
        }
    }
}
