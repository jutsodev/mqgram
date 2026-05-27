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
        // Detailed typing actions
        case ghostTypingText
        case ghostRecordingVoice
        case ghostUploadingVoice
        case ghostRecordingVideo
        case ghostUploadingVideo
        case ghostUploadingPhoto
        case ghostUploadingFile
        case ghostChoosingLocation
        case ghostChoosingContact
        case ghostPlayingGame
        case ghostRecordingRound
        case ghostUploadingRound
        case ghostSpeakingInGroupCall
        case ghostChoosingSticker
        case ghostEmojiInteraction
        case ghostEmojiReaction
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
        
        // MQGram Advanced Features (новые функции)
        case messageSendingDelay
        case messageSendingDelayRandom
        case messageSendingDelaySeconds
        case fakePremium
        case fakeStarsBalance
        case antiCaps
        case autoTranslate
        case autoFormat
        case squareAvatars
        case deletedMessageTransparency
        case secretMediaSaver
        case onlyReadWhenReplying
        case onlyReadWhenReacting
        case hideReactions
        case hideCommentButton
        case readUntilMessage
        case showEditHistory
        case antiSelfDestructSavePhotos
        case antiSelfDestructSaveVideos
        
        // MQGram v2 Features
        case alwaysOnline
        case alwaysOffline
        case customFont
        case customFontName
        case videoBackground
        case videoBackgroundPath
        case showPeerId
        case showRegDate
        case fullRussianUI
        case fakeStarsBalanceAmount
    }

    private let defaults: UserDefaults
    private static let debugLogging = true

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
        self.defaults.synchronize()
        if Self.debugLogging {
            let keyString = "MQGram.\(key.rawValue)"
            print("🔧 MQGram: Set \(keyString) = \(value)")
            print("🔧 MQGram: Verify \(keyString) = \(self.defaults.bool(forKey: keyString))")
        }
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

    public var ghostTypingText: Bool {
        get { bool(for: .ghostTypingText) }
        set { setBool(newValue, for: .ghostTypingText) }
    }

    public var ghostRecordingVoice: Bool {
        get { bool(for: .ghostRecordingVoice) }
        set { setBool(newValue, for: .ghostRecordingVoice) }
    }

    public var ghostUploadingVoice: Bool {
        get { bool(for: .ghostUploadingVoice) }
        set { setBool(newValue, for: .ghostUploadingVoice) }
    }

    public var ghostRecordingVideo: Bool {
        get { bool(for: .ghostRecordingVideo) }
        set { setBool(newValue, for: .ghostRecordingVideo) }
    }

    public var ghostUploadingVideo: Bool {
        get { bool(for: .ghostUploadingVideo) }
        set { setBool(newValue, for: .ghostUploadingVideo) }
    }

    public var ghostUploadingPhoto: Bool {
        get { bool(for: .ghostUploadingPhoto) }
        set { setBool(newValue, for: .ghostUploadingPhoto) }
    }

    public var ghostUploadingFile: Bool {
        get { bool(for: .ghostUploadingFile) }
        set { setBool(newValue, for: .ghostUploadingFile) }
    }

    public var ghostChoosingLocation: Bool {
        get { bool(for: .ghostChoosingLocation) }
        set { setBool(newValue, for: .ghostChoosingLocation) }
    }

    public var ghostChoosingContact: Bool {
        get { bool(for: .ghostChoosingContact) }
        set { setBool(newValue, for: .ghostChoosingContact) }
    }

    public var ghostPlayingGame: Bool {
        get { bool(for: .ghostPlayingGame) }
        set { setBool(newValue, for: .ghostPlayingGame) }
    }

    public var ghostRecordingRound: Bool {
        get { bool(for: .ghostRecordingRound) }
        set { setBool(newValue, for: .ghostRecordingRound) }
    }

    public var ghostUploadingRound: Bool {
        get { bool(for: .ghostUploadingRound) }
        set { setBool(newValue, for: .ghostUploadingRound) }
    }

    public var ghostSpeakingInGroupCall: Bool {
        get { bool(for: .ghostSpeakingInGroupCall) }
        set { setBool(newValue, for: .ghostSpeakingInGroupCall) }
    }

    public var ghostChoosingSticker: Bool {
        get { bool(for: .ghostChoosingSticker) }
        set { setBool(newValue, for: .ghostChoosingSticker) }
    }

    public var ghostEmojiInteraction: Bool {
        get { bool(for: .ghostEmojiInteraction) }
        set { setBool(newValue, for: .ghostEmojiInteraction) }
    }

    public var ghostEmojiReaction: Bool {
        get { bool(for: .ghostEmojiReaction) }
        set { setBool(newValue, for: .ghostEmojiReaction) }
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
    
    // MARK: - New Features Properties
    
    public var messageSendingDelay: Bool {
        get { bool(for: .messageSendingDelay) }
        set { setBool(newValue, for: .messageSendingDelay) }
    }
    
    public var messageSendingDelayRandom: Bool {
        get { bool(for: .messageSendingDelayRandom) }
        set { setBool(newValue, for: .messageSendingDelayRandom) }
    }
    
    public var messageSendingDelaySeconds: Bool {
        get { bool(for: .messageSendingDelaySeconds) }
        set { setBool(newValue, for: .messageSendingDelaySeconds) }
    }
    
    public var fakePremium: Bool {
        get { bool(for: .fakePremium) }
        set { setBool(newValue, for: .fakePremium) }
    }
    
    public var fakeStarsBalance: Bool {
        get { bool(for: .fakeStarsBalance) }
        set { setBool(newValue, for: .fakeStarsBalance) }
    }
    
    public var antiCaps: Bool {
        get { bool(for: .antiCaps) }
        set { setBool(newValue, for: .antiCaps) }
    }
    
    public var autoTranslate: Bool {
        get { bool(for: .autoTranslate) }
        set { setBool(newValue, for: .autoTranslate) }
    }
    
    public var autoFormat: Bool {
        get { bool(for: .autoFormat) }
        set { setBool(newValue, for: .autoFormat) }
    }
    
    public var squareAvatars: Bool {
        get { bool(for: .squareAvatars) }
        set { setBool(newValue, for: .squareAvatars) }
    }
    
    public var deletedMessageTransparency: Bool {
        get { bool(for: .deletedMessageTransparency) }
        set { setBool(newValue, for: .deletedMessageTransparency) }
    }
    
    public var secretMediaSaver: Bool {
        get { bool(for: .secretMediaSaver) }
        set { setBool(newValue, for: .secretMediaSaver) }
    }
    
    public var onlyReadWhenReplying: Bool {
        get { bool(for: .onlyReadWhenReplying) }
        set { setBool(newValue, for: .onlyReadWhenReplying) }
    }
    
    public var onlyReadWhenReacting: Bool {
        get { bool(for: .onlyReadWhenReacting) }
        set { setBool(newValue, for: .onlyReadWhenReacting) }
    }
    
    public var hideReactions: Bool {
        get { bool(for: .hideReactions) }
        set { setBool(newValue, for: .hideReactions) }
    }
    
    public var hideCommentButton: Bool {
        get { bool(for: .hideCommentButton) }
        set { setBool(newValue, for: .hideCommentButton) }
    }
    
    public var readUntilMessage: Bool {
        get { bool(for: .readUntilMessage) }
        set { setBool(newValue, for: .readUntilMessage) }
    }
    
    public var showEditHistory: Bool {
        get { bool(for: .showEditHistory) }
        set { setBool(newValue, for: .showEditHistory) }
    }
    
    public var antiSelfDestructSavePhotos: Bool {
        get { bool(for: .antiSelfDestructSavePhotos) }
        set { setBool(newValue, for: .antiSelfDestructSavePhotos) }
    }
    
    public var antiSelfDestructSaveVideos: Bool {
        get { bool(for: .antiSelfDestructSaveVideos) }
        set { setBool(newValue, for: .antiSelfDestructSaveVideos) }
    }
    
    // MARK: - v2 Features Properties
    
    public var alwaysOnline: Bool {
        get { bool(for: .alwaysOnline) }
        set { setBool(newValue, for: .alwaysOnline) }
    }
    
    public var alwaysOffline: Bool {
        get { bool(for: .alwaysOffline) }
        set { setBool(newValue, for: .alwaysOffline) }
    }
    
    public var customFont: Bool {
        get { bool(for: .customFont) }
        set { setBool(newValue, for: .customFont) }
    }
    
    public var customFontName: String {
        get { self.defaults.string(forKey: "MQGram.customFontName") ?? "" }
        set { self.defaults.set(newValue, forKey: "MQGram.customFontName"); self.defaults.synchronize() }
    }
    
    public var videoBackground: Bool {
        get { bool(for: .videoBackground) }
        set { setBool(newValue, for: .videoBackground) }
    }
    
    public var showPeerId: Bool {
        get { bool(for: .showPeerId) }
        set { setBool(newValue, for: .showPeerId) }
    }
    
    public var showRegDate: Bool {
        get { bool(for: .showRegDate) }
        set { setBool(newValue, for: .showRegDate) }
    }
    
    public var fullRussianUI: Bool {
        get { bool(for: .fullRussianUI) }
        set { setBool(newValue, for: .fullRussianUI) }
    }
    
    public var videoBackgroundPath: String {
        get { self.defaults.string(forKey: "MQGram.videoBackgroundPath") ?? "" }
        set { self.defaults.set(newValue, forKey: "MQGram.videoBackgroundPath"); self.defaults.synchronize() }
    }
    
    public var fakeStarsBalanceAmount: String {
        get { self.defaults.string(forKey: "MQGram.fakeStarsBalanceAmount") ?? "999999" }
        set { self.defaults.set(newValue, forKey: "MQGram.fakeStarsBalanceAmount"); self.defaults.synchronize() }
    }
}
