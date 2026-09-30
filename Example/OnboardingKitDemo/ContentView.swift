import OnboardingKit
import SwiftUI

/// Trailmark's home screen, with a section to open every OnboardingKit screen by hand.
struct ContentView: View {
    @State private var showsIntro = false
    @State private var showsWelcome = false
    @State private var showsWhatsNew = false
    @State private var didReset = false

    var body: some View {
        NavigationStack {
            List {
                Section("Nearby trails") {
                    ForEach(DemoContent.trails) { trail in
                        TrailRow(trail: trail)
                    }
                }

                Section {
                    Button("Show the paged intro", systemImage: "rectangle.stack") {
                        showsIntro = true
                    }
                    Button("Show the welcome screen", systemImage: "hand.wave") {
                        showsWelcome = true
                    }
                    Button("Show What's New", systemImage: "sparkles") {
                        showsWhatsNew = true
                    }
                    Button("Show onboarding on next launch", systemImage: "arrow.counterclockwise", role: .destructive) {
                        DemoContent.gate.reset()
                        didReset = true
                    }
                } header: {
                    Text("OnboardingKit")
                } footer: {
                    Text(didReset
                        ? "Done. Quit and reopen the app to see the intro again."
                        : "The intro appears on the first launch, What's New after an update to a new release.")
                }
            }
            .navigationTitle("Trailmark")
        }
        .tint(DemoContent.forest)
        .onboarding(isPresented: $showsIntro, pages: DemoContent.pages, style: DemoContent.style)
        .onboarding(isPresented: $showsWelcome) {
            WelcomeSheet()
        }
        .whatsNew(DemoContent.latestRelease, isPresented: $showsWhatsNew, style: DemoContent.style)
    }
}

/// A `WelcomeView` presented with `.onboarding(isPresented:content:)`: it dismisses itself.
struct WelcomeSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        WelcomeView(
            appName: "Trailmark",
            image: .systemImage("mountain.2.fill"),
            features: DemoContent.welcomeFeatures,
            footnote: DemoContent.welcomeFootnote,
            style: DemoContent.style
        ) {
            dismiss()
        }
    }
}

struct TrailRow: View {
    let trail: Trail

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: trail.symbol)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(DemoContent.forest.gradient, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(trail.name)
                    .font(.headline)
                Text("\(trail.region) · \(trail.distance.formatted(.number.precision(.fractionLength(1)))) km · \(trail.climb) m climb")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
