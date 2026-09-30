import CoreGraphics
import Testing
@testable import OnboardingKit

@Suite("Page navigation")
struct OnboardingPagerTests {
    @Test func startsOnTheFirstPage() {
        let pager = OnboardingPager(pageCount: 3)
        #expect(pager.index == 0)
        #expect(pager.isFirstPage)
        #expect(!pager.isLastPage)
        #expect(!pager.canGoBack)
        #expect(!pager.isFinished)
        #expect(pager.progress == 0)
    }

    @Test func nextWalksThroughThePagesThenFinishes() {
        var pager = OnboardingPager(pageCount: 3)
        pager.next()
        #expect(pager.index == 1)
        #expect(pager.progress == 0.5)

        pager.next()
        #expect(pager.index == 2)
        #expect(pager.isLastPage)
        #expect(!pager.isFinished)

        pager.next()
        #expect(pager.index == 2)
        #expect(pager.isFinished)
    }

    @Test func previousStopsAtTheFirstPage() {
        var pager = OnboardingPager(pageCount: 3, index: 1)
        pager.previous()
        #expect(pager.index == 0)
        pager.previous()
        #expect(pager.index == 0)
        #expect(!pager.isFinished)
    }

    @Test func jumpsAreClamped() {
        var pager = OnboardingPager(pageCount: 4)
        pager.go(to: 2)
        #expect(pager.index == 2)
        pager.go(to: 99)
        #expect(pager.index == 3)
        pager.go(to: -5)
        #expect(pager.index == 0)

        // Assigning directly, as a TabView selection binding does, is clamped too.
        pager.index = 7
        #expect(pager.index == 3)
    }

    @Test func initialIndexIsClamped() {
        #expect(OnboardingPager(pageCount: 3, index: 10).index == 2)
        #expect(OnboardingPager(pageCount: 3, index: -1).index == 0)
    }

    @Test func skipFinishesFromAnyPage() {
        var pager = OnboardingPager(pageCount: 5, index: 1)
        pager.skip()
        #expect(pager.isFinished)
        #expect(pager.index == 1)

        pager.reset()
        #expect(!pager.isFinished)
        #expect(pager.index == 0)
    }

    @Test func singleAndEmptyPageLists() {
        var single = OnboardingPager(pageCount: 1)
        #expect(single.isFirstPage && single.isLastPage)
        #expect(single.progress == 1)
        single.next()
        #expect(single.isFinished)

        var empty = OnboardingPager(pageCount: -2)
        #expect(empty.pageCount == 0)
        #expect(empty.index == 0)
        empty.next()
        #expect(empty.isFinished)
    }
}

@Suite("Release notes selection")
struct WhatsNewReleaseTests {
    let releases = [
        WhatsNew(version: "2.0", features: []),
        WhatsNew(version: "2.1", features: []),
        WhatsNew(version: "3.0", features: []),
    ]

    func pick(current: AppVersion, previous: AppVersion?, granularity: VersionGranularity = .minor) -> AppVersion? {
        WhatsNew.release(in: releases, current: current, previous: previous, granularity: granularity)?.version
    }

    @Test func picksTheNotesOfTheRunningRelease() {
        #expect(pick(current: "2.1", previous: "2.0") == AppVersion(2, 1))
        #expect(pick(current: "2.1.3", previous: "1.4") == AppVersion(2, 1))
    }

    @Test func versionWithoutNotesShowsTheLatestUnseenNotes() {
        #expect(pick(current: "2.2", previous: "2.0") == AppVersion(2, 1))
    }

    @Test func nothingWhenEverythingWasSeen() {
        #expect(pick(current: "2.2", previous: "2.1") == nil)
        #expect(pick(current: "2.1.5", previous: "2.1") == nil)
    }

    @Test func neverShowsNotesFromTheFuture() {
        #expect(pick(current: "1.9", previous: "1.0") == nil)
        #expect(pick(current: "2.9", previous: nil) == AppVersion(2, 1))
    }

    @Test func patchGranularityComparesPatchVersions() {
        let patches = [WhatsNew(version: "2.1.1", features: [])]
        let picked = WhatsNew.release(in: patches, current: "2.1.1", previous: "2.1.0", granularity: .patch)
        #expect(picked?.version == AppVersion(2, 1, 1))
        #expect(WhatsNew.release(in: patches, current: "2.1.1", previous: "2.1.0") == nil)
    }

    @Test func emptyListShowsNothing() {
        #expect(WhatsNew.release(in: [], current: "5.0", previous: nil) == nil)
    }
}

@Suite("Adaptive layout")
struct LayoutTests {
    @Test(arguments: [
        (CGSize(width: 402, height: 874), false),   // iPhone portrait
        (CGSize(width: 440, height: 956), false),   // iPhone Pro Max portrait
        (CGSize(width: 956, height: 440), true),    // iPhone Pro Max landscape
        (CGSize(width: 744, height: 1133), true),   // iPad mini portrait
        (CGSize(width: 1032, height: 1376), true),  // iPad Pro 13-inch portrait
        (CGSize(width: 800, height: 600), true),    // Mac window
    ])
    func twoColumnsFromSevenHundredPoints(size: CGSize, isWide: Bool) {
        #expect(OnboardingLayout.isWide(size) == isWide)
    }
}
