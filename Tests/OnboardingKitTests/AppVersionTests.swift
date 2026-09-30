import Foundation
import Testing
@testable import OnboardingKit

@Suite("AppVersion parsing and comparison")
struct AppVersionTests {
    @Test(arguments: [
        ("1", AppVersion(1, 0, 0)),
        ("1.2", AppVersion(1, 2, 0)),
        ("1.2.3", AppVersion(1, 2, 3)),
        ("v2.0", AppVersion(2, 0, 0)),
        ("V10.4.1", AppVersion(10, 4, 1)),
        ("  3.1  ", AppVersion(3, 1, 0)),
        ("2.1.0+482", AppVersion(2, 1, 0)),
        ("1.0.0-beta.2", AppVersion(1, 0, 0, prerelease: ["beta", "2"])),
        ("4.0-rc-1+build.7", AppVersion(4, 0, 0, prerelease: ["rc-1"])),
    ])
    func parsesValidVersions(input: String, expected: AppVersion) {
        #expect(AppVersion(string: input) == expected)
    }

    @Test(arguments: ["", " ", "v", "a.b", "1..2", "1.2.", ".1", "1.2.3.4", "-1", "1.-2", "1.2-", "1.2-beta..1", "1.2-bèta", "1,2"])
    func rejectsInvalidVersions(input: String) {
        #expect(AppVersion(string: input) == nil)
    }

    @Test func descriptions() {
        #expect(AppVersion(2, 1).description == "2.1.0")
        #expect(AppVersion(2, 1).shortDescription == "2.1")
        #expect(AppVersion(2, 1, 3).shortDescription == "2.1.3")
        #expect(AppVersion(3, 0, 0, prerelease: ["beta", "1"]).description == "3.0.0-beta.1")
        #expect(AppVersion(3, 0, 0, prerelease: ["beta", "1"]).shortDescription == "3.0.0-beta.1")
    }

    @Test func negativeNumbersAreClampedAndEmptyIdentifiersDropped() {
        let version = AppVersion(-1, -2, -3, prerelease: ["", "rc"])
        #expect(version == AppVersion(0, 0, 0, prerelease: ["rc"]))
    }

    @Test func stringLiteral() {
        let version: AppVersion = "2.1"
        #expect(version == AppVersion(2, 1, 0))
    }

    @Test func numericComparisonNotLexical() {
        #expect(AppVersion(1, 10) > AppVersion(1, 9))
        #expect(AppVersion(2, 0, 0) > AppVersion(1, 99, 99))
        #expect(AppVersion(1, 2, 10) > AppVersion(1, 2, 9))
        #expect(AppVersion(1, 2) == AppVersion(string: "1.2.0"))
    }

    /// The precedence example from the Semantic Versioning specification, item 11.
    @Test func prereleasePrecedenceFollowsSemver() throws {
        let strings = [
            "1.0.0-alpha", "1.0.0-alpha.1", "1.0.0-alpha.beta", "1.0.0-beta",
            "1.0.0-beta.2", "1.0.0-beta.11", "1.0.0-rc.1", "1.0.0",
        ]
        let ordered = strings.compactMap { AppVersion(string: $0) }
        try #require(ordered.count == strings.count)

        for (lower, higher) in zip(ordered, ordered.dropFirst()) {
            #expect(lower < higher, "\(lower) should come before \(higher)")
            #expect(!(higher < lower))
        }
        #expect(ordered.shuffled().sorted() == ordered)
    }

    @Test func releaseIsNotLessThanItself() {
        let version = AppVersion(1, 0)
        #expect(!(version < version))
        #expect(!version.isPrerelease)
        #expect(AppVersion(1, 0, 0, prerelease: ["beta"]).isPrerelease)
    }

    @Test func truncation() {
        let version = AppVersion(2, 1, 3, prerelease: ["beta"])
        #expect(version.truncated(to: .major) == AppVersion(2))
        #expect(version.truncated(to: .minor) == AppVersion(2, 1))
        #expect(version.truncated(to: .patch) == AppVersion(2, 1, 3))
    }

    @Test func newReleaseDependsOnGranularity() {
        let previous = AppVersion(2, 1, 0)
        #expect(AppVersion(2, 2, 0).isNewRelease(comparedTo: previous))
        #expect(AppVersion(3, 0, 0).isNewRelease(comparedTo: previous))
        #expect(!AppVersion(2, 1, 5).isNewRelease(comparedTo: previous))
        #expect(AppVersion(2, 1, 5).isNewRelease(comparedTo: previous, granularity: .patch))
        #expect(!AppVersion(2, 9, 0).isNewRelease(comparedTo: previous, granularity: .major))
        #expect(!AppVersion(2, 0, 0).isNewRelease(comparedTo: previous))
        #expect(!previous.isNewRelease(comparedTo: previous, granularity: .patch))
    }

    @Test func codableAsString() throws {
        let versions = [AppVersion(2, 1, 0), AppVersion(3, 0, 0, prerelease: ["rc", "1"])]
        let data = try JSONEncoder().encode(versions)
        #expect(String(decoding: data, as: UTF8.self) == #"["2.1.0","3.0.0-rc.1"]"#)
        let decoded = try JSONDecoder().decode([AppVersion].self, from: data)
        #expect(decoded == versions)
    }

    @Test func decodingAnInvalidStringThrows() {
        let data = Data(#"["two"]"#.utf8)
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode([AppVersion].self, from: data)
        }
    }
}
