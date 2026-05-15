// MARK: MQGram
import Foundation

public final class MQGramSettings {
    public static let shared = MQGramSettings()

    public enum Key: String, CaseIterable {
        case antiSelfDestruct
        case antiRevoke
        case ghostMode
        case ghostReadReceipts
        case ghostStories
        case ghostContentReads
        case ghostPersonalActions
        case ghostScreenshots
        case ghostDrafts
        case ghostEmojiInteractions
        case ghostReactions
        case ghostStickerActivity
        case ghostOnlineStatus
        case ghostTypingActions
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

    public var ghostReadReceipts: Bool {
        get { bool(for: .ghostReadReceipts) }
        set { setBool(newValue, for: .ghostReadReceipts) }
    }

    public var ghostStories: Bool {
        get { bool(for: .ghostStories) }
        set { setBool(newValue, for: .ghostStories) }
    }

    public var ghostContentReads: Bool {
        get { bool(for: .ghostContentReads) }
        set { setBool(newValue, for: .ghostContentReads) }
    }

    public var ghostPersonalActions: Bool {
        get { bool(for: .ghostPersonalActions) }
        set { setBool(newValue, for: .ghostPersonalActions) }
    }

    public var ghostScreenshots: Bool {
        get { bool(for: .ghostScreenshots) }
        set { setBool(newValue, for: .ghostScreenshots) }
    }

    public var ghostDrafts: Bool {
        get { bool(for: .ghostDrafts) }
        set { setBool(newValue, for: .ghostDrafts) }
    }

    public var ghostEmojiInteractions: Bool {
        get { bool(for: .ghostEmojiInteractions) }
        set { setBool(newValue, for: .ghostEmojiInteractions) }
    }

    public var ghostReactions: Bool {
        get { bool(for: .ghostReactions) }
        set { setBool(newValue, for: .ghostReactions) }
    }

    public var ghostStickerActivity: Bool {
        get { bool(for: .ghostStickerActivity) }
        set { setBool(newValue, for: .ghostStickerActivity) }
    }

    public var ghostOnlineStatus: Bool {
        get { bool(for: .ghostOnlineStatus) }
        set { setBool(newValue, for: .ghostOnlineStatus) }
    }

    public var ghostTypingActions: Bool {
        get { bool(for: .ghostTypingActions) }
        set { setBool(newValue, for: .ghostTypingActions) }
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
