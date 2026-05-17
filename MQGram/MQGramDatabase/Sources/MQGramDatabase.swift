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

// MARK: - Response Models (for reading data from server)

public struct MQRemoteEvent: Decodable, Equatable {
    public let id: Int?
    public let device_id: String?
    public let account_id: String?
    public let event_type: String?
    public let peer_id: String?
    public let message_id: String?
    public let timestamp: Double?
    public let data: String?
    public let created_at: String?

    public var displayEventType: String {
        return event_type ?? "unknown"
    }

    public var displayTimestamp: String {
        guard let ts = timestamp else { return created_at ?? "—" }
        let date = Date(timeIntervalSince1970: ts)
        let fmt = DateFormatter()
        fmt.dateStyle = .short
        fmt.timeStyle = .medium
        return fmt.string(from: date)
    }

    public var displayData: String {
        if let d = data, !d.isEmpty { return String(d.prefix(100)) }
        if let pid = peer_id { return "peer: \(pid)" }
        return "—"
    }
}

public struct MQRemoteMessage: Decodable, Equatable {
    public let id: Int?
    public let device_id: String?
    public let account_id: String?
    public let peer_id: String?
    public let message_id: String?
    public let author_id: String?
    public let author_name: String?
    public let peer_name: String?
    public let text: String?
    public let media_types: String?
    public let timestamp: Int?
    public let is_outgoing: Bool?
    public let created_at: String?

    public var displayTitle: String {
        if let name = author_name, !name.isEmpty { return name }
        if let aid = author_id, !aid.isEmpty { return "User \(aid)" }
        return is_outgoing == true ? "You" : "Unknown"
    }

    public var displayText: String {
        if let t = text, !t.isEmpty { return String(t.prefix(120)) }
        if let m = media_types, !m.isEmpty { return "[\(m)]" }
        return "[empty]"
    }

    public var displayTime: String {
        guard let ts = timestamp else { return created_at ?? "—" }
        let date = Date(timeIntervalSince1970: TimeInterval(ts))
        let fmt = DateFormatter()
        fmt.dateStyle = .short
        fmt.timeStyle = .medium
        return fmt.string(from: date)
    }

    public var displayPeer: String {
        if let name = peer_name, !name.isEmpty { return name }
        if let pid = peer_id, !pid.isEmpty { return "Chat \(pid)" }
        return "—"
    }
}

public struct MQRemoteDeletedMessage: Decodable, Equatable {
    public let id: Int?
    public let device_id: String?
    public let account_id: String?
    public let peer_id: String?
    public let message_id: String?
    public let author_id: String?
    public let author_name: String?
    public let peer_name: String?
    public let original_text: String?
    public let current_text: String?
    public let edit_history: String?
    public let media_types: String?
    public let timestamp: Int?
    public let has_media: Bool?
    public let created_at: String?

    public var displayTitle: String {
        if let name = author_name, !name.isEmpty { return name }
        if let aid = author_id, !aid.isEmpty { return "User \(aid)" }
        return "Unknown"
    }

    public var displayText: String {
        if let t = original_text, !t.isEmpty { return String(t.prefix(120)) }
        if let t = current_text, !t.isEmpty { return String(t.prefix(120)) }
        if has_media == true { return "[media]" }
        return "[empty]"
    }

    public var displayTime: String {
        guard let ts = timestamp else { return created_at ?? "—" }
        let date = Date(timeIntervalSince1970: TimeInterval(ts))
        let fmt = DateFormatter()
        fmt.dateStyle = .short
        fmt.timeStyle = .medium
        return fmt.string(from: date)
    }

    public var displayPeer: String {
        if let name = peer_name, !name.isEmpty { return name }
        if let pid = peer_id, !pid.isEmpty { return "Chat \(pid)" }
        return "—"
    }

    public var hasEdits: Bool {
        guard let h = edit_history, !h.isEmpty else { return false }
        return true
    }
}

public struct MQRemoteEditedMessage: Decodable, Equatable {
    public let id: Int?
    public let device_id: String?
    public let account_id: String?
    public let peer_id: String?
    public let message_id: String?
    public let previous_text: String?
    public let new_text: String?
    public let edit_number: Int?
    public let created_at: String?

    public var displayTitle: String {
        return "Edit #\(edit_number ?? 1) in \(peer_id ?? "?")"
    }

    public var displayPrevious: String {
        if let t = previous_text, !t.isEmpty { return String(t.prefix(80)) }
        return "[empty]"
    }

    public var displayNew: String {
        if let t = new_text, !t.isEmpty { return String(t.prefix(80)) }
        return "[empty]"
    }

    public var displayTime: String {
        return created_at ?? "—"
    }
}

public struct MQRemoteUserAction: Decodable, Equatable {
    public let id: Int?
    public let device_id: String?
    public let account_id: String?
    public let action_type: String?
    public let details: String?
    public let timestamp: Double?
    public let created_at: String?

    public var displayAction: String {
        return action_type ?? "unknown"
    }

    public var displayDetails: String {
        if let d = details, !d.isEmpty { return String(d.prefix(100)) }
        return "—"
    }

    public var displayTime: String {
        guard let ts = timestamp else { return created_at ?? "—" }
        let date = Date(timeIntervalSince1970: ts)
        let fmt = DateFormatter()
        fmt.dateStyle = .short
        fmt.timeStyle = .medium
        return fmt.string(from: date)
    }
}

public struct MQRemoteAccount: Decodable, Equatable {
    public let id: Int?
    public let device_id: String?
    public let account_id: String?
    public let phone_number: String?
    public let first_name: String?
    public let last_name: String?
    public let username: String?
    public let avatar_url: String?
    public let created_at: String?
    public let updated_at: String?

    public var displayName: String {
        let parts = [first_name, last_name].compactMap { $0 }.filter { !$0.isEmpty }
        if !parts.isEmpty { return parts.joined(separator: " ") }
        if let u = username, !u.isEmpty { return "@\(u)" }
        return account_id ?? "Unknown"
    }

    public var displayPhone: String {
        return phone_number ?? "—"
    }

    public var displayUsername: String {
        if let u = username, !u.isEmpty { return "@\(u)" }
        return "—"
    }
}

public struct MQRemoteStats: Decodable, Equatable {
    public let total_events: Int?
    public let total_messages: Int?
    public let total_deleted: Int?
    public let total_edited: Int?
    public let total_actions: Int?
    public let total_accounts: Int?
    public let server_uptime: String?
    public let last_event_at: String?
    public let database_size: String?

    public init() {
        self.total_events = 0
        self.total_messages = 0
        self.total_deleted = 0
        self.total_edited = 0
        self.total_actions = 0
        self.total_accounts = 0
        self.server_uptime = nil
        self.last_event_at = nil
        self.database_size = nil
    }
}

public struct MQDatabaseSnapshot: Equatable {
    public let stats: MQRemoteStats
    public let recentEvents: [MQRemoteEvent]
    public let recentMessages: [MQRemoteMessage]
    public let recentDeleted: [MQRemoteDeletedMessage]
    public let recentEdited: [MQRemoteEditedMessage]
    public let recentActions: [MQRemoteUserAction]
    public let accounts: [MQRemoteAccount]
    public let fetchedAt: Date
    public let isConnected: Bool
    public let errorMessage: String?

    public init(
        stats: MQRemoteStats = MQRemoteStats(),
        recentEvents: [MQRemoteEvent] = [],
        recentMessages: [MQRemoteMessage] = [],
        recentDeleted: [MQRemoteDeletedMessage] = [],
        recentEdited: [MQRemoteEditedMessage] = [],
        recentActions: [MQRemoteUserAction] = [],
        accounts: [MQRemoteAccount] = [],
        fetchedAt: Date = Date(),
        isConnected: Bool = false,
        errorMessage: String? = nil
    ) {
        self.stats = stats
        self.recentEvents = recentEvents
        self.recentMessages = recentMessages
        self.recentDeleted = recentDeleted
        self.recentEdited = recentEdited
        self.recentActions = recentActions
        self.accounts = accounts
        self.fetchedAt = fetchedAt
        self.isConnected = isConnected
        self.errorMessage = errorMessage
    }

    public var isEmpty: Bool {
        return recentEvents.isEmpty && recentMessages.isEmpty && recentDeleted.isEmpty && recentEdited.isEmpty && recentActions.isEmpty && accounts.isEmpty
    }
}

// MARK: - Network Layer

public final class MQGramDatabase {
    public static let shared = MQGramDatabase()

    private let session: URLSession
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
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

    // MARK: - Generic GET Request

    private func fetchRequest<T: Decodable>(endpoint: String, completion: @escaping (Result<T, Error>) -> Void) {
        let urlString = MQGramDatabaseConfig.serverURL + endpoint
        guard let url = URL(string: urlString) else {
            completion(.failure(MQFetchError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(MQGramDatabaseConfig.deviceId, forHTTPHeaderField: "X-Device-Id")
        if let accountId = MQGramDatabaseConfig.accountId {
            request.setValue(accountId, forHTTPHeaderField: "X-Account-Id")
        }

        session.dataTask(with: request) { [weak self] responseData, response, error in
            if let error = error {
                #if DEBUG
                print("[MQGramDB] Fetch error: \(error.localizedDescription)")
                #endif
                completion(.failure(error))
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(MQFetchError.noResponse))
                return
            }
            guard httpResponse.statusCode == 200 else {
                completion(.failure(MQFetchError.httpError(httpResponse.statusCode)))
                return
            }
            guard let responseData = responseData else {
                completion(.failure(MQFetchError.noData))
                return
            }
            do {
                guard let self = self else {
                    completion(.failure(MQFetchError.noData))
                    return
                }
                let decoded = try self.decoder.decode(T.self, from: responseData)
                completion(.success(decoded))
            } catch {
                #if DEBUG
                print("[MQGramDB] Decode error: \(error)")
                #endif
                completion(.failure(error))
            }
        }.resume()
    }

    // MARK: - Public API: Fetch Events

    public func fetchEvents(limit: Int = 50, offset: Int = 0, completion: @escaping ([MQRemoteEvent]) -> Void) {
        let endpoint = "/api/events?device_id=\(MQGramDatabaseConfig.deviceId)&limit=\(limit)&offset=\(offset)"
        fetchRequest(endpoint: endpoint) { (result: Result<[MQRemoteEvent], Error>) in
            switch result {
            case .success(let events):
                completion(events)
            case .failure:
                completion([])
            }
        }
    }

    // MARK: - Public API: Fetch Messages

    public func fetchMessages(limit: Int = 50, offset: Int = 0, completion: @escaping ([MQRemoteMessage]) -> Void) {
        let endpoint = "/api/messages?device_id=\(MQGramDatabaseConfig.deviceId)&limit=\(limit)&offset=\(offset)"
        fetchRequest(endpoint: endpoint) { (result: Result<[MQRemoteMessage], Error>) in
            switch result {
            case .success(let messages):
                completion(messages)
            case .failure:
                completion([])
            }
        }
    }

    // MARK: - Public API: Fetch Deleted Messages

    public func fetchDeletedMessages(limit: Int = 50, offset: Int = 0, completion: @escaping ([MQRemoteDeletedMessage]) -> Void) {
        let endpoint = "/api/deleted_messages?device_id=\(MQGramDatabaseConfig.deviceId)&limit=\(limit)&offset=\(offset)"
        fetchRequest(endpoint: endpoint) { (result: Result<[MQRemoteDeletedMessage], Error>) in
            switch result {
            case .success(let messages):
                completion(messages)
            case .failure:
                completion([])
            }
        }
    }

    // MARK: - Public API: Fetch Edited Messages

    public func fetchEditedMessages(limit: Int = 50, offset: Int = 0, completion: @escaping ([MQRemoteEditedMessage]) -> Void) {
        let endpoint = "/api/edited_messages?device_id=\(MQGramDatabaseConfig.deviceId)&limit=\(limit)&offset=\(offset)"
        fetchRequest(endpoint: endpoint) { (result: Result<[MQRemoteEditedMessage], Error>) in
            switch result {
            case .success(let messages):
                completion(messages)
            case .failure:
                completion([])
            }
        }
    }

    // MARK: - Public API: Fetch User Actions

    public func fetchUserActions(limit: Int = 50, offset: Int = 0, completion: @escaping ([MQRemoteUserAction]) -> Void) {
        let endpoint = "/api/user_actions?device_id=\(MQGramDatabaseConfig.deviceId)&limit=\(limit)&offset=\(offset)"
        fetchRequest(endpoint: endpoint) { (result: Result<[MQRemoteUserAction], Error>) in
            switch result {
            case .success(let actions):
                completion(actions)
            case .failure:
                completion([])
            }
        }
    }

    // MARK: - Public API: Fetch Accounts

    public func fetchAccounts(completion: @escaping ([MQRemoteAccount]) -> Void) {
        let endpoint = "/api/accounts?device_id=\(MQGramDatabaseConfig.deviceId)"
        fetchRequest(endpoint: endpoint) { (result: Result<[MQRemoteAccount], Error>) in
            switch result {
            case .success(let accounts):
                completion(accounts)
            case .failure:
                completion([])
            }
        }
    }

    // MARK: - Public API: Fetch Stats

    public func fetchStats(completion: @escaping (MQRemoteStats?) -> Void) {
        let endpoint = "/api/stats?device_id=\(MQGramDatabaseConfig.deviceId)"
        fetchRequest(endpoint: endpoint) { (result: Result<MQRemoteStats, Error>) in
            switch result {
            case .success(let stats):
                completion(stats)
            case .failure:
                completion(nil)
            }
        }
    }

    // MARK: - Public API: Fetch Full Database Snapshot

    public func fetchDatabaseSnapshot(eventsLimit: Int = 30, messagesLimit: Int = 30, completion: @escaping (MQDatabaseSnapshot) -> Void) {
        let group = DispatchGroup()

        var fetchedStats: MQRemoteStats?
        var fetchedEvents: [MQRemoteEvent] = []
        var fetchedMessages: [MQRemoteMessage] = []
        var fetchedDeleted: [MQRemoteDeletedMessage] = []
        var fetchedEdited: [MQRemoteEditedMessage] = []
        var fetchedActions: [MQRemoteUserAction] = []
        var fetchedAccounts: [MQRemoteAccount] = []
        var anyError: String?

        group.enter()
        fetchStats { stats in
            fetchedStats = stats
            group.leave()
        }

        group.enter()
        fetchEvents(limit: eventsLimit) { events in
            fetchedEvents = events
            group.leave()
        }

        group.enter()
        fetchMessages(limit: messagesLimit) { messages in
            fetchedMessages = messages
            group.leave()
        }

        group.enter()
        fetchDeletedMessages(limit: messagesLimit) { messages in
            fetchedDeleted = messages
            group.leave()
        }

        group.enter()
        fetchEditedMessages(limit: messagesLimit) { messages in
            fetchedEdited = messages
            group.leave()
        }

        group.enter()
        fetchUserActions(limit: messagesLimit) { actions in
            fetchedActions = actions
            group.leave()
        }

        group.enter()
        fetchAccounts { accounts in
            fetchedAccounts = accounts
            group.leave()
        }

        group.notify(queue: .main) {
            let isConnected = fetchedStats != nil
            if !isConnected && fetchedEvents.isEmpty && fetchedMessages.isEmpty {
                anyError = "Cannot connect to server"
            }
            let snapshot = MQDatabaseSnapshot(
                stats: fetchedStats ?? MQRemoteStats(),
                recentEvents: fetchedEvents,
                recentMessages: fetchedMessages,
                recentDeleted: fetchedDeleted,
                recentEdited: fetchedEdited,
                recentActions: fetchedActions,
                accounts: fetchedAccounts,
                fetchedAt: Date(),
                isConnected: isConnected,
                errorMessage: anyError
            )
            completion(snapshot)
        }
    }

    // MARK: - Public API: Check Server Connection

    public func checkConnection(completion: @escaping (Bool, String?) -> Void) {
        let urlString = MQGramDatabaseConfig.serverURL + "/api/health"
        guard let url = URL(string: urlString) else {
            completion(false, "Invalid server URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10

        session.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(false, error.localizedDescription)
                    return
                }
                let httpResponse = response as? HTTPURLResponse
                let statusCode = httpResponse?.statusCode ?? 0
                if statusCode == 200 {
                    completion(true, nil)
                } else {
                    completion(false, "HTTP \(statusCode)")
                }
            }
        }.resume()
    }

    // MARK: - Public API: Delete Remote Data

    public func deleteAllRemoteData(completion: @escaping (Bool) -> Void) {
        let urlString = MQGramDatabaseConfig.serverURL + "/api/data?device_id=\(MQGramDatabaseConfig.deviceId)"
        guard let url = URL(string: urlString) else {
            completion(false)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue(MQGramDatabaseConfig.deviceId, forHTTPHeaderField: "X-Device-Id")

        session.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if error != nil {
                    completion(false)
                    return
                }
                let httpResponse = response as? HTTPURLResponse
                completion(httpResponse?.statusCode == 200)
            }
        }.resume()
    }

    // MARK: - Public API: Export Database as JSON

    public func exportDatabaseJSON(completion: @escaping (Data?) -> Void) {
        fetchDatabaseSnapshot(eventsLimit: 1000, messagesLimit: 1000) { snapshot in
            let exportDict: [String: Any] = [
                "exported_at": ISO8601DateFormatter().string(from: Date()),
                "device_id": MQGramDatabaseConfig.deviceId,
                "account_id": MQGramDatabaseConfig.accountId ?? "unknown",
                "server_url": MQGramDatabaseConfig.serverURL,
                "stats": [
                    "total_events": snapshot.stats.total_events ?? 0,
                    "total_messages": snapshot.stats.total_messages ?? 0,
                    "total_deleted": snapshot.stats.total_deleted ?? 0,
                    "total_edited": snapshot.stats.total_edited ?? 0,
                    "total_actions": snapshot.stats.total_actions ?? 0,
                    "total_accounts": snapshot.stats.total_accounts ?? 0
                ],
                "events_count": snapshot.recentEvents.count,
                "messages_count": snapshot.recentMessages.count,
                "deleted_count": snapshot.recentDeleted.count,
                "edited_count": snapshot.recentEdited.count,
                "actions_count": snapshot.recentActions.count,
                "accounts_count": snapshot.accounts.count
            ]
            let data = try? JSONSerialization.data(withJSONObject: exportDict, options: [.prettyPrinted, .sortedKeys])
            completion(data)
        }
    }

    // MARK: - Public API: Get Server Info

    public func getServerInfo() -> (url: String, deviceId: String, accountId: String?, isEnabled: Bool) {
        return (
            url: MQGramDatabaseConfig.serverURL,
            deviceId: MQGramDatabaseConfig.deviceId,
            accountId: MQGramDatabaseConfig.accountId,
            isEnabled: MQGramDatabaseConfig.isEnabled
        )
    }
}

// MARK: - Fetch Errors

public enum MQFetchError: Error, CustomStringConvertible {
    case invalidURL
    case noResponse
    case httpError(Int)
    case noData
    case decodingError(String)

    public var description: String {
        switch self {
        case .invalidURL: return "Invalid server URL"
        case .noResponse: return "No response from server"
        case .httpError(let code): return "HTTP error \(code)"
        case .noData: return "No data received"
        case .decodingError(let msg): return "Decoding: \(msg)"
        }
    }
}
