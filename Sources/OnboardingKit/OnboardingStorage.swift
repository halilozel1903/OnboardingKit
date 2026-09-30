import Foundation

/// Where `OnboardingGate` keeps what the user has already seen: two short strings.
///
/// Use `UserDefaultsOnboardingStorage` (the default), `InMemoryOnboardingStorage` for tests and
/// previews, or your own type to sync the state through iCloud key-value storage or a server.
public protocol OnboardingStorage: Sendable {
    func string(forKey key: String) -> String?
    /// Stores `value`, or removes the key when `value` is `nil`.
    func set(_ value: String?, forKey key: String)
}

/// Stores the onboarding state in `UserDefaults`.
public final class UserDefaultsOnboardingStorage: OnboardingStorage, @unchecked Sendable {
    // UserDefaults is thread-safe.
    public let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func string(forKey key: String) -> String? {
        defaults.string(forKey: key)
    }

    public func set(_ value: String?, forKey key: String) {
        if let value {
            defaults.set(value, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }
}

/// Keeps the onboarding state in memory. Handy for tests, previews and screenshots.
public final class InMemoryOnboardingStorage: OnboardingStorage, @unchecked Sendable {
    private let lock = NSLock()
    private var values: [String: String]

    public init(_ values: [String: String] = [:]) {
        self.values = values
    }

    public func string(forKey key: String) -> String? {
        lock.lock()
        defer { lock.unlock() }
        return values[key]
    }

    public func set(_ value: String?, forKey key: String) {
        lock.lock()
        defer { lock.unlock() }
        values[key] = value
    }

    /// A copy of everything stored, for assertions in tests.
    public var snapshot: [String: String] {
        lock.lock()
        defer { lock.unlock() }
        return values
    }
}
