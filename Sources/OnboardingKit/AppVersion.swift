import Foundation

/// A semantic version such as `2.1.0` or `3.0.0-beta.2`.
///
/// Versions compare by the rules of [Semantic Versioning](https://semver.org): major, then minor,
/// then patch, and a pre-release (`2.0.0-beta`) comes before its release (`2.0.0`).
/// Build metadata (`+1234`) is accepted and ignored.
///
/// ```swift
/// AppVersion(string: "2.1")          // 2.1.0
/// AppVersion(string: "v3.0.0-rc.1")  // 3.0.0-rc.1
/// let version: AppVersion = "2.1"    // string literal
/// AppVersion.current                 // CFBundleShortVersionString of the app
/// ```
public struct AppVersion: Sendable, Hashable, Comparable, CustomStringConvertible {
    public var major: Int
    public var minor: Int
    public var patch: Int
    /// Dot-separated pre-release identifiers, for example `["beta", "2"]` for `-beta.2`. Empty for a release.
    public var prerelease: [String]

    public init(_ major: Int, _ minor: Int = 0, _ patch: Int = 0, prerelease: [String] = []) {
        self.major = max(0, major)
        self.minor = max(0, minor)
        self.patch = max(0, patch)
        self.prerelease = prerelease.filter { !$0.isEmpty }
    }

    /// Parses `"2"`, `"2.1"`, `"2.1.3"`, `"v2.1"`, `"2.1.0-beta.2"` or `"2.1.0+42"`.
    /// Returns `nil` for anything else, such as `""`, `"2.x"`, `"1..2"` or `"1.2.3.4"`.
    public init?(string: String) {
        var text = Substring(string.trimmingCharacters(in: .whitespacesAndNewlines))
        if let first = text.first, first == "v" || first == "V" {
            text = text.dropFirst()
        }
        if let plus = text.firstIndex(of: "+") {
            text = text[..<plus]
        }

        var identifiers: [String] = []
        if let dash = text.firstIndex(of: "-") {
            let tail = text[text.index(after: dash)...]
            identifiers = tail.split(separator: ".", omittingEmptySubsequences: false).map(String.init)
            guard !identifiers.isEmpty, identifiers.allSatisfy(Self.isValidIdentifier) else { return nil }
            text = text[..<dash]
        }

        let parts = text.split(separator: ".", omittingEmptySubsequences: false)
        guard (1...3).contains(parts.count) else { return nil }
        var numbers: [Int] = []
        for part in parts {
            guard !part.isEmpty, part.allSatisfy(Self.isDigit), let number = Int(part) else { return nil }
            numbers.append(number)
        }
        while numbers.count < 3 { numbers.append(0) }
        self.init(numbers[0], numbers[1], numbers[2], prerelease: identifiers)
    }

    /// The version of the running app, read from `CFBundleShortVersionString`.
    public static var current: AppVersion? {
        guard let string = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String else {
            return nil
        }
        return AppVersion(string: string)
    }

    /// `true` for a pre-release such as `2.0.0-beta`.
    public var isPrerelease: Bool { !prerelease.isEmpty }

    public var description: String {
        let core = "\(major).\(minor).\(patch)"
        return prerelease.isEmpty ? core : core + "-" + prerelease.joined(separator: ".")
    }

    /// The version as people read it: `2.1` for `2.1.0`, `2.1.3` for `2.1.3`, `3.0` for `3.0.0`.
    public var shortDescription: String {
        patch == 0 && prerelease.isEmpty ? "\(major).\(minor)" : description
    }

    public static func < (lhs: AppVersion, rhs: AppVersion) -> Bool {
        if lhs.major != rhs.major { return lhs.major < rhs.major }
        if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
        if lhs.patch != rhs.patch { return lhs.patch < rhs.patch }
        return prereleasePrecedes(lhs.prerelease, rhs.prerelease)
    }

    /// Semantic Versioning precedence of pre-release identifiers.
    static func prereleasePrecedes(_ lhs: [String], _ rhs: [String]) -> Bool {
        switch (lhs.isEmpty, rhs.isEmpty) {
        case (true, _):
            // A release never comes before anything with the same core version.
            return false
        case (false, true):
            return true
        case (false, false):
            for (left, right) in zip(lhs, rhs) where left != right {
                switch (Int(left), Int(right)) {
                case let (leftNumber?, rightNumber?):
                    if leftNumber != rightNumber { return leftNumber < rightNumber }
                    return left < right
                case (.some, .none):
                    return true
                case (.none, .some):
                    return false
                case (.none, .none):
                    return left < right
                }
            }
            return lhs.count < rhs.count
        }
    }

    private static func isDigit(_ character: Character) -> Bool {
        character.isASCII && character.isNumber
    }

    private static func isValidIdentifier(_ identifier: String) -> Bool {
        guard !identifier.isEmpty else { return false }
        return identifier.allSatisfy { character in
            character.isASCII && (character.isLetter || character.isNumber || character == "-")
        }
    }
}

extension AppVersion: ExpressibleByStringLiteral {
    /// `let version: AppVersion = "2.1"`. An invalid literal stops debug builds and becomes `0.0.0` in release builds.
    public init(stringLiteral value: String) {
        guard let version = AppVersion(string: value) else {
            assertionFailure("\"\(value)\" is not a valid version")
            self = AppVersion(0)
            return
        }
        self = version
    }
}

extension AppVersion: Codable {
    /// Decodes from a string such as `"2.1.0"`.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        guard let version = AppVersion(string: string) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "\"\(string)\" is not a valid version")
        }
        self = version
    }

    /// Encodes as a string such as `"2.1.0"`.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}

/// Which part of a version has to change for an update to count as a new release.
public enum VersionGranularity: String, Sendable, Hashable, CaseIterable {
    /// Only `1.x` → `2.0` counts.
    case major
    /// `2.0` → `2.1` counts, `2.1.0` → `2.1.1` does not. The default: bug fix releases stay quiet.
    case minor
    /// Every `x.y.z` change counts.
    case patch
}

extension AppVersion {
    /// The version cut down to `granularity`, without its pre-release: `2.1.3` becomes `2.1.0` for `.minor`.
    public func truncated(to granularity: VersionGranularity) -> AppVersion {
        switch granularity {
        case .major: AppVersion(major)
        case .minor: AppVersion(major, minor)
        case .patch: AppVersion(major, minor, patch)
        }
    }

    /// `true` when this version is a newer release than `previous` at the given granularity.
    ///
    /// ```swift
    /// AppVersion("2.1").isNewRelease(comparedTo: "2.0")                        // true
    /// AppVersion("2.1.1").isNewRelease(comparedTo: "2.1")                      // false
    /// AppVersion("2.1.1").isNewRelease(comparedTo: "2.1", granularity: .patch) // true
    /// ```
    public func isNewRelease(comparedTo previous: AppVersion, granularity: VersionGranularity = .minor) -> Bool {
        truncated(to: granularity) > previous.truncated(to: granularity)
    }
}
