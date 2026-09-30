/// Navigation state of a paged intro: which page is showing and whether the user is done.
///
/// `OnboardingView` uses it internally; use it directly to build a pager of your own.
///
/// ```swift
/// var pager = OnboardingPager(pageCount: 3)
/// pager.next()         // page 1
/// pager.next()         // page 2, the last one
/// pager.next()         // isFinished == true
/// ```
public struct OnboardingPager: Sendable, Hashable {
    /// Number of pages. Never negative.
    public let pageCount: Int

    /// The current page, always kept within `0..<pageCount` (0 when there are no pages).
    public var index: Int {
        didSet { index = Self.clamped(index, pageCount: pageCount) }
    }

    /// `true` after `next()` on the last page, or after `skip()`.
    public private(set) var isFinished: Bool

    public init(pageCount: Int, index: Int = 0) {
        self.pageCount = max(0, pageCount)
        self.index = Self.clamped(index, pageCount: max(0, pageCount))
        self.isFinished = false
    }

    public var isFirstPage: Bool { index == 0 }
    public var isLastPage: Bool { index >= pageCount - 1 }
    public var canGoBack: Bool { index > 0 }

    /// 0 on the first page, 1 on the last. 1 when there is at most one page.
    public var progress: Double {
        pageCount > 1 ? Double(index) / Double(pageCount - 1) : 1
    }

    /// Moves to the next page, or finishes on the last page.
    public mutating func next() {
        if isLastPage {
            isFinished = true
        } else {
            index += 1
        }
    }

    /// Moves to the previous page. Does nothing on the first page.
    public mutating func previous() {
        if canGoBack { index -= 1 }
    }

    /// Jumps to `page`, clamped to the valid range.
    public mutating func go(to page: Int) {
        index = page
    }

    /// Ends the intro early.
    public mutating func skip() {
        isFinished = true
    }

    /// Back to the first page, not finished.
    public mutating func reset() {
        index = 0
        isFinished = false
    }

    static func clamped(_ index: Int, pageCount: Int) -> Int {
        min(max(0, index), max(0, pageCount - 1))
    }
}
