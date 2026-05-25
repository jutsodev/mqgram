// MARK: MQGram - Activity Logger and Statistics
// Comprehensive logging and statistics system for blocked activities
import Foundation
import Postbox

/// Types of activities that can be blocked
public enum MQBlockedActivityType: String, CaseIterable {
    case typingText = "typing_text"
    case recordingVoice = "recording_voice"
    case uploadingVoice = "uploading_voice"
    case recordingVideo = "recording_video"
    case uploadingVideo = "uploading_video"
    case uploadingPhoto = "uploading_photo"
    case uploadingFile = "uploading_file"
    case choosingLocation = "choosing_location"
    case choosingContact = "choosing_contact"
    case playingGame = "playing_game"
    case recordingRound = "recording_round"
    case uploadingRound = "uploading_round"
    case speakingInGroupCall = "speaking_in_group_call"
    case choosingSticker = "choosing_sticker"
    case emojiInteraction = "emoji_interaction"
    case emojiReaction = "emoji_reaction"
    case readReceipt = "read_receipt"
    case storyView = "story_view"
    case onlineStatus = "online_status"
    case screenshot = "screenshot"
    case draft = "draft"
    
    public var displayName: String {
        switch self {
        case .typingText: return "Typing Text"
        case .recordingVoice: return "Recording Voice"
        case .uploadingVoice: return "Uploading Voice"
        case .recordingVideo: return "Recording Video"
        case .uploadingVideo: return "Uploading Video"
        case .uploadingPhoto: return "Uploading Photo"
        case .uploadingFile: return "Uploading File"
        case .choosingLocation: return "Choosing Location"
        case .choosingContact: return "Choosing Contact"
        case .playingGame: return "Playing Game"
        case .recordingRound: return "Recording Round Video"
        case .uploadingRound: return "Uploading Round Video"
        case .speakingInGroupCall: return "Speaking in Group Call"
        case .choosingSticker: return "Choosing Sticker"
        case .emojiInteraction: return "Emoji Interaction"
        case .emojiReaction: return "Emoji Reaction"
        case .readReceipt: return "Read Receipt"
        case .storyView: return "Story View"
        case .onlineStatus: return "Online Status"
        case .screenshot: return "Screenshot"
        case .draft: return "Draft"
        }
    }
    
    public var displayNameRu: String {
        switch self {
        case .typingText: return "Набор текста"
        case .recordingVoice: return "Запись голосового"
        case .uploadingVoice: return "Загрузка голосового"
        case .recordingVideo: return "Запись видео"
        case .uploadingVideo: return "Загрузка видео"
        case .uploadingPhoto: return "Загрузка фото"
        case .uploadingFile: return "Загрузка файла"
        case .choosingLocation: return "Выбор локации"
        case .choosingContact: return "Выбор контакта"
        case .playingGame: return "Игра"
        case .recordingRound: return "Запись круглого видео"
        case .uploadingRound: return "Загрузка круглого видео"
        case .speakingInGroupCall: return "Голос в звонке"
        case .choosingSticker: return "Выбор стикера"
        case .emojiInteraction: return "Эмодзи взаимодействие"
        case .emojiReaction: return "Эмодзи реакция"
        case .readReceipt: return "Прочтение"
        case .storyView: return "Просмотр истории"
        case .onlineStatus: return "Онлайн статус"
        case .screenshot: return "Скриншот"
        case .draft: return "Черновик"
        }
    }
}

/// Single blocked activity record
public struct MQBlockedActivityRecord: Codable {
    public let type: String
    public let timestamp: Date
    public let peerId: Int64?
    public let peerName: String?
    public let blockedBy: String // Which setting blocked it
    
    public init(type: MQBlockedActivityType, peerId: Int64? = nil, peerName: String? = nil, blockedBy: String) {
        self.type = type.rawValue
        self.timestamp = Date()
        self.peerId = peerId
        self.peerName = peerName
        self.blockedBy = blockedBy
    }
}

/// Statistics for blocked activities
public struct MQBlockedActivityStatistics: Codable {
    public var totalBlocked: Int
    public var blockedByType: [String: Int]
    public var blockedByPeer: [Int64: Int]
    public var blockedBySetting: [String: Int]
    public var lastBlockedDate: Date?
    public var firstBlockedDate: Date?
    
    public init() {
        self.totalBlocked = 0
        self.blockedByType = [:]
        self.blockedByPeer = [:]
        self.blockedBySetting = [:]
        self.lastBlockedDate = nil
        self.firstBlockedDate = nil
    }
    
    mutating public func recordBlock(type: MQBlockedActivityType, peerId: Int64?, blockedBy: String) {
        self.totalBlocked += 1
        self.blockedByType[type.rawValue, default: 0] += 1
        if let peerId = peerId {
            self.blockedByPeer[peerId, default: 0] += 1
        }
        self.blockedBySetting[blockedBy, default: 0] += 1
        
        let now = Date()
        self.lastBlockedDate = now
        if self.firstBlockedDate == nil {
            self.firstBlockedDate = now
        }
    }
}

/// Main activity logger
public final class MQGramActivityLogger {
    public static let shared = MQGramActivityLogger()
    
    private let statisticsKey = "MQGram.activityStatistics"
    private let recentRecordsKey = "MQGram.recentActivityRecords"
    private let maxRecentRecords = 1000
    
    private var statistics: MQBlockedActivityStatistics
    private var recentRecords: [MQBlockedActivityRecord]
    
    private let queue = DispatchQueue(label: "com.mqgram.activitylogger", qos: .utility)
    
    private init() {
        // Load statistics
        if let data = UserDefaults.standard.data(forKey: statisticsKey),
           let stats = try? JSONDecoder().decode(MQBlockedActivityStatistics.self, from: data) {
            self.statistics = stats
        } else {
            self.statistics = MQBlockedActivityStatistics()
        }
        
        // Load recent records
        if let data = UserDefaults.standard.data(forKey: recentRecordsKey),
           let records = try? JSONDecoder().decode([MQBlockedActivityRecord].self, from: data) {
            self.recentRecords = records
        } else {
            self.recentRecords = []
        }
    }
    
    // MARK: - Logging
    
    /// Log a blocked activity
    public func logBlockedActivity(
        type: MQBlockedActivityType,
        peerId: Int64? = nil,
        peerName: String? = nil,
        blockedBy: String
    ) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            // Create record
            let record = MQBlockedActivityRecord(
                type: type,
                peerId: peerId,
                peerName: peerName,
                blockedBy: blockedBy
            )
            
            // Add to recent records
            self.recentRecords.insert(record, at: 0)
            if self.recentRecords.count > self.maxRecentRecords {
                self.recentRecords.removeLast()
            }
            
            // Update statistics
            self.statistics.recordBlock(type: type, peerId: peerId, blockedBy: blockedBy)
            
            // Save
            self.save()
            
            // Debug log
            #if DEBUG
            print("🔒 MQGram: Blocked \(type.displayName) for peer \(peerId ?? 0) by \(blockedBy)")
            #endif
        }
    }
    
    /// Log multiple blocked activities at once
    public func logBlockedActivities(_ activities: [(type: MQBlockedActivityType, peerId: Int64?, peerName: String?, blockedBy: String)]) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            for activity in activities {
                let record = MQBlockedActivityRecord(
                    type: activity.type,
                    peerId: activity.peerId,
                    peerName: activity.peerName,
                    blockedBy: activity.blockedBy
                )
                
                self.recentRecords.insert(record, at: 0)
                self.statistics.recordBlock(type: activity.type, peerId: activity.peerId, blockedBy: activity.blockedBy)
            }
            
            // Trim records
            if self.recentRecords.count > self.maxRecentRecords {
                self.recentRecords = Array(self.recentRecords.prefix(self.maxRecentRecords))
            }
            
            self.save()
        }
    }
    
    // MARK: - Statistics
    
    /// Get current statistics
    public func getStatistics() -> MQBlockedActivityStatistics {
        return queue.sync {
            return self.statistics
        }
    }
    
    /// Get recent records
    public func getRecentRecords(limit: Int = 100) -> [MQBlockedActivityRecord] {
        return queue.sync {
            return Array(self.recentRecords.prefix(limit))
        }
    }
    
    /// Get records for specific peer
    public func getRecordsForPeer(_ peerId: Int64, limit: Int = 100) -> [MQBlockedActivityRecord] {
        return queue.sync {
            return self.recentRecords
                .filter { $0.peerId == peerId }
                .prefix(limit)
                .map { $0 }
        }
    }
    
    /// Get records for specific type
    public func getRecordsForType(_ type: MQBlockedActivityType, limit: Int = 100) -> [MQBlockedActivityRecord] {
        return queue.sync {
            return self.recentRecords
                .filter { $0.type == type.rawValue }
                .prefix(limit)
                .map { $0 }
        }
    }
    
    /// Get total blocked count
    public func getTotalBlockedCount() -> Int {
        return queue.sync {
            return self.statistics.totalBlocked
        }
    }
    
    /// Get blocked count for specific type
    public func getBlockedCount(for type: MQBlockedActivityType) -> Int {
        return queue.sync {
            return self.statistics.blockedByType[type.rawValue] ?? 0
        }
    }
    
    /// Get blocked count for specific peer
    public func getBlockedCount(forPeer peerId: Int64) -> Int {
        return queue.sync {
            return self.statistics.blockedByPeer[peerId] ?? 0
        }
    }
    
    /// Get top blocked activity types
    public func getTopBlockedTypes(limit: Int = 10) -> [(type: String, count: Int)] {
        return queue.sync {
            return self.statistics.blockedByType
                .sorted { $0.value > $1.value }
                .prefix(limit)
                .map { ($0.key, $0.value) }
        }
    }
    
    /// Get top peers with blocked activities
    public func getTopBlockedPeers(limit: Int = 10) -> [(peerId: Int64, count: Int)] {
        return queue.sync {
            return self.statistics.blockedByPeer
                .sorted { $0.value > $1.value }
                .prefix(limit)
                .map { ($0.key, $0.value) }
        }
    }
    
    /// Get statistics by setting
    public func getBlockedBySetting() -> [String: Int] {
        return queue.sync {
            return self.statistics.blockedBySetting
        }
    }
    
    // MARK: - Management
    
    /// Clear all statistics and records
    public func clearAll() {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            self.statistics = MQBlockedActivityStatistics()
            self.recentRecords = []
            self.save()
            
            #if DEBUG
            print("🗑️ MQGram: Cleared all activity logs")
            #endif
        }
    }
    
    /// Clear records older than specified date
    public func clearRecordsOlderThan(_ date: Date) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            let oldCount = self.recentRecords.count
            self.recentRecords = self.recentRecords.filter { $0.timestamp >= date }
            let newCount = self.recentRecords.count
            
            self.save()
            
            #if DEBUG
            print("🗑️ MQGram: Cleared \(oldCount - newCount) old records")
            #endif
        }
    }
    
    /// Export statistics as JSON
    public func exportStatisticsJSON() -> String? {
        return queue.sync {
            guard let data = try? JSONEncoder().encode(self.statistics),
                  let json = String(data: data, encoding: .utf8) else {
                return nil
            }
            return json
        }
    }
    
    /// Export recent records as JSON
    public func exportRecordsJSON(limit: Int = 1000) -> String? {
        return queue.sync {
            let records = Array(self.recentRecords.prefix(limit))
            guard let data = try? JSONEncoder().encode(records),
                  let json = String(data: data, encoding: .utf8) else {
                return nil
            }
            return json
        }
    }
    
    // MARK: - Private
    
    private func save() {
        // Save statistics
        if let data = try? JSONEncoder().encode(self.statistics) {
            UserDefaults.standard.set(data, forKey: self.statisticsKey)
        }
        
        // Save recent records
        if let data = try? JSONEncoder().encode(self.recentRecords) {
            UserDefaults.standard.set(data, forKey: self.recentRecordsKey)
        }
        
        UserDefaults.standard.synchronize()
    }
}

// MARK: - Formatted Statistics

extension MQBlockedActivityStatistics {
    /// Get formatted summary
    public func formattedSummary(languageCode: String) -> String {
        let isRu = languageCode.lowercased().hasPrefix("ru")
        
        var summary = ""
        
        if isRu {
            summary += "📊 Статистика блокировки активностей\n\n"
            summary += "Всего заблокировано: \(totalBlocked)\n"
            
            if let first = firstBlockedDate {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .short
                summary += "Первая блокировка: \(formatter.string(from: first))\n"
            }
            
            if let last = lastBlockedDate {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .short
                summary += "Последняя блокировка: \(formatter.string(from: last))\n"
            }
            
            summary += "\nТоп активностей:\n"
        } else {
            summary += "📊 Activity Blocking Statistics\n\n"
            summary += "Total blocked: \(totalBlocked)\n"
            
            if let first = firstBlockedDate {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .short
                summary += "First block: \(formatter.string(from: first))\n"
            }
            
            if let last = lastBlockedDate {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .short
                summary += "Last block: \(formatter.string(from: last))\n"
            }
            
            summary += "\nTop activities:\n"
        }
        
        let topTypes = blockedByType.sorted { $0.value > $1.value }.prefix(5)
        for (type, count) in topTypes {
            if let activityType = MQBlockedActivityType(rawValue: type) {
                let name = isRu ? activityType.displayNameRu : activityType.displayName
                summary += "  • \(name): \(count)\n"
            }
        }
        
        return summary
    }
}
