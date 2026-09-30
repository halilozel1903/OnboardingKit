import Foundation
import Testing
@testable import OnboardingKit

@Suite("OnboardingGate decisions and storage")
struct OnboardingGateTests {
    func makeGate(granularity: VersionGranularity = .minor) -> OnboardingGate {
        OnboardingGate(storage: InMemoryOnboardingStorage(), granularity: granularity)
    }

    @Test func firstLaunchShowsOnboarding() {
        let gate = makeGate()
        #expect(gate.shouldShowOnboarding)
        #expect(!gate.hasCompletedOnboarding)
        #expect(gate.lastSeenVersion == nil)
        #expect(gate.decision(for: "1.0") == .onboarding)
        #expect(gate.whatsNewDecision(for: "1.0") == .firstLaunch)
        #expect(!gate.shouldShowWhatsNew(for: "1.0"))
    }

    @Test func completingOnboardingRecordsTheVersion() {
        let gate = makeGate()
        gate.markOnboardingCompleted(version: "2.0.1")
        #expect(gate.hasCompletedOnboarding)
        #expect(!gate.shouldShowOnboarding)
        #expect(gate.onboardingCompletedVersion == AppVersion(2, 0, 1))
        #expect(gate.lastSeenVersion == AppVersion(2, 0, 1))
        #expect(gate.decision(for: "2.0.1") == .nothing)
    }

    @Test func completingWithoutAVersionStillCounts() {
        let gate = makeGate()
        gate.markOnboardingCompleted(version: nil)
        #expect(gate.hasCompletedOnboarding)
        #expect(gate.onboardingCompletedVersion == nil)
        #expect(gate.lastSeenVersion == nil)
        #expect(gate.decision(for: "3.0") == .nothing)
    }

    @Test func minorUpdateShowsWhatsNewOnce() {
        let gate = makeGate()
        gate.markOnboardingCompleted(version: "2.0")
        #expect(gate.decision(for: "2.1") == .whatsNew(previous: AppVersion(2, 0)))
        #expect(gate.shouldShowWhatsNew(for: "2.1"))

        gate.markWhatsNewSeen(version: "2.1")
        #expect(gate.decision(for: "2.1") == .nothing)
        #expect(gate.whatsNewDecision(for: "2.1") == .upToDate)
    }

    @Test func patchUpdateIsQuietByDefault() {
        let gate = makeGate()
        gate.markOnboardingCompleted(version: "2.1.0")
        #expect(gate.decision(for: "2.1.4") == .nothing)
    }

    @Test func patchGranularityShowsBugFixReleases() {
        let gate = makeGate(granularity: .patch)
        gate.markOnboardingCompleted(version: "2.1.0")
        #expect(gate.decision(for: "2.1.4") == .whatsNew(previous: AppVersion(2, 1, 0)))
    }

    @Test func majorGranularityIgnoresMinorReleases() {
        let gate = makeGate(granularity: .major)
        gate.markOnboardingCompleted(version: "2.0")
        #expect(gate.decision(for: "2.7") == .nothing)
        #expect(gate.decision(for: "3.0") == .whatsNew(previous: AppVersion(2, 0)))
    }

    @Test func downgradeShowsNothingAndDoesNotRewind() {
        let gate = makeGate()
        gate.markOnboardingCompleted(version: "3.0")
        #expect(gate.decision(for: "2.5") == .nothing)

        gate.markWhatsNewSeen(version: "2.5")
        #expect(gate.lastSeenVersion == AppVersion(3, 0))
    }

    @Test func onboardingComesBeforeWhatsNew() {
        let gate = makeGate()
        gate.markWhatsNewSeen(version: "1.0")
        #expect(gate.whatsNewDecision(for: "2.0") == .show(previous: AppVersion(1, 0)))
        #expect(gate.decision(for: "2.0") == .onboarding)
    }

    @Test func resetForgetsEverything() {
        let storage = InMemoryOnboardingStorage()
        let gate = OnboardingGate(storage: storage)
        gate.markOnboardingCompleted(version: "1.0")
        #expect(!storage.snapshot.isEmpty)

        gate.reset()
        #expect(storage.snapshot.isEmpty)
        #expect(gate.decision(for: "1.0") == .onboarding)
    }

    @Test func keyPrefixesKeepFlowsApart() {
        let storage = InMemoryOnboardingStorage()
        let main = OnboardingGate(storage: storage)
        let editor = OnboardingGate(storage: storage, keyPrefix: "EditorTour")
        main.markOnboardingCompleted(version: "1.0")
        #expect(!main.shouldShowOnboarding)
        #expect(editor.shouldShowOnboarding)
        #expect(storage.snapshot.keys.sorted() == ["OnboardingKit.lastSeenVersion", "OnboardingKit.onboardingCompletedVersion"])
    }

    @Test func corruptStoredValuesAreIgnored() {
        let storage = InMemoryOnboardingStorage(["OnboardingKit.lastSeenVersion": "garbage"])
        let gate = OnboardingGate(storage: storage)
        #expect(gate.lastSeenVersion == nil)
        #expect(gate.whatsNewDecision(for: "1.0") == .firstLaunch)

        gate.markWhatsNewSeen(version: "1.0")
        #expect(gate.lastSeenVersion == AppVersion(1, 0))
    }

    @Test func userDefaultsStorage() throws {
        let suite = "OnboardingKitTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        let gate = OnboardingGate(storage: UserDefaultsOnboardingStorage(defaults: defaults))
        #expect(gate.shouldShowOnboarding)
        gate.markOnboardingCompleted(version: "1.4")
        #expect(defaults.string(forKey: "OnboardingKit.lastSeenVersion") == "1.4.0")

        // A new gate over the same defaults sees the same state, like the next launch would.
        let nextLaunch = OnboardingGate(storage: UserDefaultsOnboardingStorage(defaults: defaults))
        #expect(nextLaunch.decision(for: "1.5") == .whatsNew(previous: AppVersion(1, 4)))

        nextLaunch.reset()
        #expect(defaults.string(forKey: "OnboardingKit.lastSeenVersion") == nil)
        #expect(defaults.string(forKey: "OnboardingKit.onboardingCompletedVersion") == nil)
    }
}
