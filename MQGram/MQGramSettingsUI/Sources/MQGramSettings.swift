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
        case readAfterActions
        case customIndicators
        case contentProtectionBypass
        case antiEdit
        case disableAds
        case businessFeatures
        case localPremium
        case unlimitedAccounts
        case hidePhoneNumber
        case confirmCalls
        case silentMessages
        // Hide UI elements
        case hideNavigationBar
        case hideFavoriteChats
        case hideRecentCalls
        case hideDevices
        case hideChatFolders
        case hideNotificationsSettings
        case hidePrivacySettings
        case hideDataSettings
        case hideAppearanceSettings
        case hideLanguageSettings
        case hideStickersSettings
        case hidePowerSaving
        // Wallet tab options
        case pinWalletTab
        case redDeleteIcon
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

    public var readAfterActions: Bool {
        get { bool(for: .readAfterActions) }
        set { setBool(newValue, for: .readAfterActions) }
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

    public var businessFeatures: Bool {
        get { bool(for: .businessFeatures) }
        set { setBool(newValue, for: .businessFeatures) }
    }

    public var localPremium: Bool {
        get { bool(for: .localPremium) }
        set { setBool(newValue, for: .localPremium) }
    }

    public var unlimitedAccounts: Bool {
        get { bool(for: .unlimitedAccounts) }
        set { setBool(newValue, for: .unlimitedAccounts) }
    }

    public var hidePhoneNumber: Bool {
        get { bool(for: .hidePhoneNumber) }
        set { setBool(newValue, for: .hidePhoneNumber) }
    }

    public var confirmCalls: Bool {
        get { bool(for: .confirmCalls) }
        set { setBool(newValue, for: .confirmCalls) }
    }

    public var silentMessages: Bool {
        get { bool(for: .silentMessages) }
        set { setBool(newValue, for: .silentMessages) }
    }

    public var hideNavigationBar: Bool {
        get { bool(for: .hideNavigationBar) }
        set { setBool(newValue, for: .hideNavigationBar) }
    }

    public var hideFavoriteChats: Bool {
        get { bool(for: .hideFavoriteChats) }
        set { setBool(newValue, for: .hideFavoriteChats) }
    }

    public var hideRecentCalls: Bool {
        get { bool(for: .hideRecentCalls) }
        set { setBool(newValue, for: .hideRecentCalls) }
    }

    public var hideDevices: Bool {
        get { bool(for: .hideDevices) }
        set { setBool(newValue, for: .hideDevices) }
    }

    public var hideChatFolders: Bool {
        get { bool(for: .hideChatFolders) }
        set { setBool(newValue, for: .hideChatFolders) }
    }

    public var hideNotificationsSettings: Bool {
        get { bool(for: .hideNotificationsSettings) }
        set { setBool(newValue, for: .hideNotificationsSettings) }
    }

    public var hidePrivacySettings: Bool {
        get { bool(for: .hidePrivacySettings) }
        set { setBool(newValue, for: .hidePrivacySettings) }
    }

    public var hideDataSettings: Bool {
        get { bool(for: .hideDataSettings) }
        set { setBool(newValue, for: .hideDataSettings) }
    }

    public var hideAppearanceSettings: Bool {
        get { bool(for: .hideAppearanceSettings) }
        set { setBool(newValue, for: .hideAppearanceSettings) }
    }

    public var hideLanguageSettings: Bool {
        get { bool(for: .hideLanguageSettings) }
        set { setBool(newValue, for: .hideLanguageSettings) }
    }

    public var hideStickersSettings: Bool {
        get { bool(for: .hideStickersSettings) }
        set { setBool(newValue, for: .hideStickersSettings) }
    }

    public var hidePowerSaving: Bool {
        get { bool(for: .hidePowerSaving) }
        set { setBool(newValue, for: .hidePowerSaving) }
    }

    public var pinWalletTab: Bool {
        get { bool(for: .pinWalletTab) }
        set { setBool(newValue, for: .pinWalletTab) }
    }

    public var redDeleteIcon: Bool {
        get { bool(for: .redDeleteIcon) }
        set { setBool(newValue, for: .redDeleteIcon) }
    }
}
