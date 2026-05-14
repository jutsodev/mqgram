// MARK: MQGram
import Foundation

public final class MQGramSettings {
    public static let shared = MQGramSettings()

    public enum Key: String, CaseIterable {
        case antiSelfDestruct
        case antiRevoke
        case ghostMode
        case customIndicators
        case contentProtectionBypass
        case antiEdit
        case disableAds
    }

    private let defaults: UserDefaults

    private init() {
        self.defaults = UserDefaults.standard
        // All features default to false
        var registry: [String: Any] = [:]
        for key in Key.allCases {
            registry["MQGram.\(key.rawValue)"] = false
        }
        self.defaults.register(defaults: registry)
    }

    public func bool(for key: Key) -> Bool {
        return self.defaults.bool(forKey: "MQGram.\(key.rawValue)")
    }

    public func setBool(_ value: Bool, for key: Key) {
        self.defaults.set(value, forKey: "MQGram.\(key.rawValue)")
    }

    public var antiSelfDestruct: Bool {
        get { bool(for: .antiSelfDestruct) }
        set { setBool(newValue, for: .antiSelfDestruct) }
    }

    public var antiRevoke: Bool {
        get { bool(for: .antiRevoke) }
        set { setBool(newValue, for: .antiRevoke) }
    }

    public var ghostMode: Bool {
        get { bool(for: .ghostMode) }
        set { setBool(newValue, for: .ghostMode) }
    }

    public var customIndicators: Bool {
        get { bool(for: .customIndicators) }
        set { setBool(newValue, for: .customIndicators) }
    }

    public var contentProtectionBypass: Bool {
        get { bool(for: .contentProtectionBypass) }
        set { setBool(newValue, for: .contentProtectionBypass) }
    }

    public var antiEdit: Bool {
        get { bool(for: .antiEdit) }
        set { setBool(newValue, for: .antiEdit) }
    }

    public var disableAds: Bool {
        get { bool(for: .disableAds) }
        set { setBool(newValue, for: .disableAds) }
    }
}
