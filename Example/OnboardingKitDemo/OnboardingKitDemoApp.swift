import OnboardingKit
import SwiftUI

@main
struct OnboardingKitDemoApp: App {
    var body: some Scene {
        WindowGroup {
            if let scene = ScreenshotScene.current {
                // Screenshot scenes show one screen directly and never touch the stored state.
                scene.content
            } else {
                ContentView()
                    // First launch: the paged intro. Later updates: What's New, once per release.
                    .onboarding(pages: DemoContent.pages, gate: DemoContent.gate, style: DemoContent.style)
                    .whatsNew(DemoContent.releases, gate: DemoContent.gate, style: DemoContent.style)
            }
        }
    }
}
