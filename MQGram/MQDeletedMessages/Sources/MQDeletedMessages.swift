// MARK: MQGram - Deleted Messages Manager (ported from GLEGram/SGDeletedMessages)
// Comprehensive local database + remote sync for deleted/edited messages
import Foundation
import Postbox
import TelegramCore
import SwiftSignalKit
import MQGramDatabase

private func peerDisplayName(_ peer: Peer?) -> String {
    guard let peer = peer else { return "" }
    if let user = peer as? TelegramUser {
        let first = user.firstName ?? ""
        let last = user.lastName ?? ""
        if !first.isEmpty && !last.isEmpty {
            return "\(first) \(last)"
        }
        return first.isEmpty ? last : first
    }
    if let group = peer as? TelegramGroup {
        return group.title
    }
    if let channel = peer as? TelegramChannel {
        return channel.title
    }
    return ""
}

private let messageNamespaceCloud: Int32 = 0
private let messageNamespaceSavedDeleted: Int32 = 1338

// MARK: - Deleted Message Info

public struct MQDeletedMessageInfo {
    public let messageId: MessageId
    public let peerId: PeerId
    public let authorId: PeerId?
    public let authorName: String?
    public let peerName: String?
    public let text: String
    public let originalText: String?
    public let editHistory: [String]
    public let timestamp: Int32
    public let deletedAt: Date
    public let hasMedia: Bool
    public let mediaTypes: [String]
    public let forwardAuthor: String?
    public let groupingKey: Int64?
    public let threadId: Int64?
    public let flags: MessageFlags

    public init(message: Message, deletedAt: Date = Date()) {
        self.messageId = message.id
        self.peerId = message.id.peerId
        self.authorId = message.author?.id
        self.authorName = message.author.flatMap { peerDisplayName($0) }
        self.peerName = nil
        self.text = message.text
        let attr = message.mqDeletedAttribute
        self.originalText = attr.originalText
        self.editHistory = attr.editHistory
        self.timestamp = message.timestamp
        self.deletedAt = deletedAt
        self.hasMedia = !message.media.isEmpty
        self.mediaTypes = message.media.compactMap { media -> String? in
            if media is TelegramMediaImage { return "image" }
            if let file = media as? TelegramMediaFile {
                if file.isVideo { return "video" }
                if file.isVoice { return "voice" }
                if file.isVideoMessage { return "video_message" }
                if file.isSticker { return "sticker" }
                if file.isAnimated { return "gif" }
                if file.isMusic { return "music" }
                return "file"
            }
            if media is TelegramMediaMap { return "location" }
            if media is TelegramMediaContact { return "contact" }
            if media is TelegramMediaPoll { return "poll" }
            if media is TelegramMediaDice { return "dice" }
            if media is TelegramMediaAction { return "action" }
            return nil
        }
        if let forwardInfo = message.forwardInfo {
            self.forwardAuthor = forwardInfo.author.flatMap { peerDisplayName($0) }
        } else {
            self.forwardAuthor = nil
        }
        self.groupingKey = message.groupingKey
        self.threadId = message.threadId
        self.flags = message.flags
    }
}

// MARK: - Peer Deleted Messages Group

public struct MQDeletedMessagesPeerGroup {
    public let peer: Peer?
    public let peerId: PeerId
    public let messages: [Message]
    public let totalCount: Int
    public let latestTimestamp: Int32
    public let earliestTimestamp: Int32
    public let hasMediaMessages: Bool
    public let textOnlyCount: Int
    public let mediaCount: Int

    public init(peer: Peer?, peerId: PeerId, messages: [Message]) {
        self.peer = peer
        self.peerId = peerId
        self.messages = messages.sorted { $0.timestamp > $1.timestamp }
        self.totalCount = messages.count
        self.latestTimestamp = self.messages.first?.timestamp ?? 0
        self.earliestTimestamp = self.messages.last?.timestamp ?? 0
        self.hasMediaMessages = messages.contains { !$0.media.isEmpty }
        self.textOnlyCount = messages.filter { $0.media.isEmpty && !$0.text.isEmpty }.count
        self.mediaCount = messages.filter { !$0.media.isEmpty }.count
    }
}

// MARK: - Search Filter

public struct MQDeletedMessagesFilter {
    public var peerId: PeerId?
    public var authorId: PeerId?
    public var searchText: String?
    public var dateFrom: Date?
    public var dateTo: Date?
    public var hasMedia: Bool?
    public var mediaType: String?
    public var limit: Int
    public var offset: Int

    public init(
        peerId: PeerId? = nil,
        authorId: PeerId? = nil,
        searchText: String? = nil,
        dateFrom: Date? = nil,
        dateTo: Date? = nil,
        hasMedia: Bool? = nil,
        mediaType: String? = nil,
        limit: Int = 100,
        offset: Int = 0
    ) {
        self.peerId = peerId
        self.authorId = authorId
        self.searchText = searchText
        self.dateFrom = dateFrom
        self.dateTo = dateTo
        self.hasMedia = hasMedia
        self.mediaType = mediaType
        self.limit = limit
        self.offset = offset
    }
}

// MARK: - Statistics

public struct MQDeletedMessagesStats {
    public let totalDeletedMessages: Int
    public let totalPeersWithDeleted: Int
    public let totalMediaMessages: Int
    public let totalTextMessages: Int
    public let totalEditedBeforeDelete: Int
    public let storageSizeBytes: Int64
    public let oldestDeletedTimestamp: Int32?
    public let newestDeletedTimestamp: Int32?
    public let topPeersByCount: [(peerId: PeerId, peer: Peer?, count: Int)]
    public let mediaTypeBreakdown: [String: Int]

    public init(
        totalDeletedMessages: Int = 0,
        totalPeersWithDeleted: Int = 0,
        totalMediaMessages: Int = 0,
        totalTextMessages: Int = 0,
        totalEditedBeforeDelete: Int = 0,
        storageSizeBytes: Int64 = 0,
        oldestDeletedTimestamp: Int32? = nil,
        newestDeletedTimestamp: Int32? = nil,
        topPeersByCount: [(peerId: PeerId, peer: Peer?, count: Int)] = [],
        mediaTypeBreakdown: [String: Int] = [:]
    ) {
        self.totalDeletedMessages = totalDeletedMessages
        self.totalPeersWithDeleted = totalPeersWithDeleted
        self.totalMediaMessages = totalMediaMessages
        self.totalTextMessages = totalTextMessages
        self.totalEditedBeforeDelete = totalEditedBeforeDelete
        self.storageSizeBytes = storageSizeBytes
        self.oldestDeletedTimestamp = oldestDeletedTimestamp
        self.newestDeletedTimestamp = newestDeletedTimestamp
        self.topPeersByCount = topPeersByCount
        self.mediaTypeBreakdown = mediaTypeBreakdown
    }
}

// MARK: - Export Format

public enum MQExportFormat {
    case json
    case csv
    case text
}

// MARK: - Exported Data

public struct MQExportedData {
    public let format: MQExportFormat
    public let data: Data
    public let filename: String
    public let messageCount: Int
}

// MARK: - Main Manager

public struct MQDeletedMessages {
    public static var showDeletedMessages: Bool {
        return UserDefaults.standard.bool(forKey: "MQGram.antiRevoke")
    }

    private static func savedDeletedId(for originalId: MessageId) -> MessageId {
        return MessageId(peerId: originalId.peerId, namespace: messageNamespaceSavedDeleted, id: originalId.id)
    }

    // MARK: - Core Snapshot Logic

    private static func saveSnapshotIfPossible(
        originalId: MessageId,
        transaction: Transaction,
        transformAttributes: ((Message, inout [MessageAttribute]) -> Void)?
    ) -> Bool {
        if originalId.namespace == messageNamespaceSavedDeleted {
            return false
        }

        guard let message = transaction.getMessage(originalId) else {
            return false
        }

        let snapshotId = savedDeletedId(for: originalId)
        if transaction.messageExists(id: snapshotId) {
            return true
        }

        let storeForwardInfo = message.forwardInfo.flatMap(StoreMessageForwardInfo.init)
        var attributes = message.attributes
        var hasDeletedAttribute = false
        for attribute in attributes {
            if let deletedAttribute = attribute as? MQDeletedMessageAttribute {
                deletedAttribute.isDeleted = true
                if deletedAttribute.originalText == nil {
                    deletedAttribute.originalText = message.text
                }
                deletedAttribute.originalNamespace = originalId.namespace
                deletedAttribute.originalId = originalId.id
                hasDeletedAttribute = true
                break
            }
        }
        if !hasDeletedAttribute {
            attributes.append(MQDeletedMessageAttribute(isDeleted: true, originalText: message.text, originalNamespace: originalId.namespace, originalId: originalId.id))
        }

        transformAttributes?(message, &attributes)

        let storeMessage = StoreMessage(
            id: snapshotId,
            customStableId: nil,
            globallyUniqueId: nil,
            groupingKey: message.groupingKey,
            threadId: message.threadId,
            timestamp: message.timestamp,
            flags: StoreMessageFlags(message.flags),
            tags: message.tags,
            globalTags: message.globalTags,
            localTags: message.localTags,
            forwardInfo: storeForwardInfo,
            authorId: message.author?.id,
            text: message.text,
            attributes: attributes,
            media: message.media
        )
        let _ = transaction.addMessages([storeMessage], location: .UpperHistoryBlock)

        syncDeletedMessageToRemote(message: message, originalId: originalId)

        return true
    }

    // MARK: - Remote Sync

    private static func syncDeletedMessageToRemote(message: Message, originalId: MessageId) {
        let attr = message.mqDeletedAttribute
        let info = MQDeletedMessageInfo(message: message)

        MQGramDatabase.shared.logDeletedMessage(
            peerId: String(originalId.peerId.id._internalGetInt64Value()),
            messageId: String(originalId.id),
            authorId: info.authorId.map { String($0.id._internalGetInt64Value()) },
            authorName: info.authorName,
            peerName: info.peerName,
            originalText: attr.originalText ?? message.text,
            currentText: message.text,
            editHistory: attr.editHistory.isEmpty ? nil : attr.editHistory,
            mediaTypes: info.mediaTypes.isEmpty ? nil : info.mediaTypes,
            timestamp: Int(message.timestamp),
            hasMedia: info.hasMedia
        )

        MQGramDatabase.shared.logEvent(
            type: .messageDeleted,
            peerId: String(originalId.peerId.id._internalGetInt64Value()),
            messageId: String(originalId.id),
            data: message.text.isEmpty ? nil : String(message.text.prefix(200))
        )
    }

    // MARK: - Public: Save Snapshots

    public static func saveSnapshots(
        ids: [MessageId],
        transaction: Transaction,
        transformAttributes: ((Message, inout [MessageAttribute]) -> Void)? = nil
    ) -> Set<MessageId> {
        guard showDeletedMessages, !ids.isEmpty else { return Set() }

        var result = Set<MessageId>()
        result.reserveCapacity(ids.count)

        for id in ids {
            if saveSnapshotIfPossible(originalId: id, transaction: transaction, transformAttributes: transformAttributes) {
                result.insert(id)
            }
        }
        return result
    }

    // MARK: - Public: Save Snapshots For Global IDs

    public static func saveSnapshotsForGlobalIds(
        _ globalIds: [Int32],
        transaction: Transaction,
        transformAttributes: ((Message, inout [MessageAttribute]) -> Void)? = nil
    ) {
        guard showDeletedMessages else { return }
        for globalId in globalIds {
            if let id = transaction.messageIdsForGlobalIds([globalId]).first {
                _ = saveSnapshotIfPossible(originalId: id, transaction: transaction, transformAttributes: transformAttributes)
            }
        }
    }

    // MARK: - Public: Save Snapshots And Return IDs To Delete

    public static func saveSnapshotsAndReturnIdsToDelete(ids: [MessageId], transaction: Transaction) -> [MessageId] {
        _ = saveSnapshots(ids: ids, transaction: transaction, transformAttributes: nil)
        return ids
    }

    // MARK: - Public: Query Helpers

    public static func isMessageDeleted(_ message: Message) -> Bool {
        return message.mqDeletedAttribute.isDeleted
    }

    public static func getOriginalText(_ message: Message) -> String? {
        return message.mqDeletedAttribute.originalText
    }

    public static func getEditHistory(_ message: Message) -> [String] {
        return message.mqDeletedAttribute.editHistory
    }

    public static func getAllEditVersions(_ message: Message) -> [String] {
        return message.mqDeletedAttribute.allEditVersions(currentText: message.text)
    }

    public static func isInSavedDeletedNamespace(_ message: Message) -> Bool {
        return message.id.namespace == messageNamespaceSavedDeleted
    }

    public static func getOriginalMessageId(_ message: Message) -> MessageId? {
        let attr = message.mqDeletedAttribute
        guard let ns = attr.originalNamespace, let oid = attr.originalId else { return nil }
        return MessageId(peerId: message.id.peerId, namespace: ns, id: oid)
    }

    // MARK: - Public: Storage Size

    public static func storageSizeBytes(mediaBoxBasePath: String) -> Int64 {
        let attachmentsPath = mediaBoxBasePath + "/saved-deleted-attachments"
        guard let enumerator = FileManager.default.enumerator(
            at: URL(fileURLWithPath: attachmentsPath),
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else { return 0 }
        var total: Int64 = 0
        for case let url as URL in enumerator {
            total += Int64((try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
        }
        return total
    }

    public static func formattedStorageSize(mediaBoxBasePath: String) -> String {
        let bytes = storageSizeBytes(mediaBoxBasePath: mediaBoxBasePath)
        if bytes < 1024 {
            return "\(bytes) B"
        } else if bytes < 1024 * 1024 {
            return String(format: "%.1f KB", Double(bytes) / 1024.0)
        } else if bytes < 1024 * 1024 * 1024 {
            return String(format: "%.1f MB", Double(bytes) / (1024.0 * 1024.0))
        } else {
            return String(format: "%.2f GB", Double(bytes) / (1024.0 * 1024.0 * 1024.0))
        }
    }

    // MARK: - Public: Get All Saved Deleted Messages (Grouped)

    public static func getAllSavedDeletedMessages(
        postbox: Postbox
    ) -> Signal<[(peer: Peer?, peerId: PeerId, messages: [Message])], NoError> {
        return postbox.transaction { transaction -> [(peer: Peer?, peerId: PeerId, messages: [Message])] in
            var result: [(peer: Peer?, peerId: PeerId, messages: [Message])] = []
            let allPeerIds = transaction.chatListGetAllPeerIds()
            for peerId in allPeerIds {
                var messages: [Message] = []
                transaction.scanMessageAttributes(peerId: peerId, namespace: messageNamespaceSavedDeleted, limit: Int.max) { messageId, _ in
                    if let message = transaction.getMessage(messageId) {
                        messages.append(message)
                    }
                    return true
                }
                if !messages.isEmpty {
                    messages.sort { $0.timestamp > $1.timestamp }
                    let peer = transaction.getPeer(peerId)
                    result.append((peer: peer, peerId: peerId, messages: messages))
                }
            }
            result.sort { ($0.messages.first?.timestamp ?? 0) > ($1.messages.first?.timestamp ?? 0) }
            return result
        }
    }

    // MARK: - Public: Get Grouped Peer Data

    public static func getGroupedDeletedMessages(
        postbox: Postbox
    ) -> Signal<[MQDeletedMessagesPeerGroup], NoError> {
        return postbox.transaction { transaction -> [MQDeletedMessagesPeerGroup] in
            var groups: [MQDeletedMessagesPeerGroup] = []
            let allPeerIds = transaction.chatListGetAllPeerIds()
            for peerId in allPeerIds {
                var messages: [Message] = []
                transaction.scanMessageAttributes(peerId: peerId, namespace: messageNamespaceSavedDeleted, limit: Int.max) { messageId, _ in
                    if let message = transaction.getMessage(messageId) {
                        messages.append(message)
                    }
                    return true
                }
                if !messages.isEmpty {
                    let peer = transaction.getPeer(peerId)
                    groups.append(MQDeletedMessagesPeerGroup(peer: peer, peerId: peerId, messages: messages))
                }
            }
            groups.sort { $0.latestTimestamp > $1.latestTimestamp }
            return groups
        }
    }

    // MARK: - Public: Get Deleted Messages For Peer

    public static func getDeletedMessagesForPeer(
        postbox: Postbox,
        peerId: PeerId,
        limit: Int = Int.max
    ) -> Signal<[Message], NoError> {
        return postbox.transaction { transaction -> [Message] in
            var messages: [Message] = []
            var count = 0
            transaction.scanMessageAttributes(peerId: peerId, namespace: messageNamespaceSavedDeleted, limit: Int.max) { messageId, _ in
                if count >= limit { return false }
                if let message = transaction.getMessage(messageId) {
                    messages.append(message)
                    count += 1
                }
                return true
            }
            messages.sort { $0.timestamp > $1.timestamp }
            return messages
        }
    }

    // MARK: - Public: Count Deleted Messages

    public static func countDeletedMessages(
        postbox: Postbox
    ) -> Signal<Int, NoError> {
        return postbox.transaction { transaction -> Int in
            var count = 0
            let allPeerIds = transaction.chatListGetAllPeerIds()
            for peerId in allPeerIds {
                transaction.scanMessageAttributes(peerId: peerId, namespace: messageNamespaceSavedDeleted, limit: Int.max) { _, _ in
                    count += 1
                    return true
                }
            }
            return count
        }
    }

    // MARK: - Public: Count Deleted Messages For Peer

    public static func countDeletedMessagesForPeer(
        postbox: Postbox,
        peerId: PeerId
    ) -> Signal<Int, NoError> {
        return postbox.transaction { transaction -> Int in
            var count = 0
            transaction.scanMessageAttributes(peerId: peerId, namespace: messageNamespaceSavedDeleted, limit: Int.max) { _, _ in
                count += 1
                return true
            }
            return count
        }
    }

    // MARK: - Public: Search Deleted Messages

    public static func searchDeletedMessages(
        postbox: Postbox,
        filter: MQDeletedMessagesFilter
    ) -> Signal<[Message], NoError> {
        return postbox.transaction { transaction -> [Message] in
            var allMessages: [Message] = []
            let peerIds: [PeerId]
            if let filteredPeerId = filter.peerId {
                peerIds = [filteredPeerId]
            } else {
                peerIds = transaction.chatListGetAllPeerIds()
            }

            for peerId in peerIds {
                transaction.scanMessageAttributes(peerId: peerId, namespace: messageNamespaceSavedDeleted, limit: Int.max) { messageId, _ in
                    if let message = transaction.getMessage(messageId) {
                        allMessages.append(message)
                    }
                    return true
                }
            }

            var filtered = allMessages

            if let searchText = filter.searchText, !searchText.isEmpty {
                let lowered = searchText.lowercased()
                filtered = filtered.filter { msg in
                    if msg.text.lowercased().contains(lowered) { return true }
                    let attr = msg.mqDeletedAttribute
                    if let ot = attr.originalText, ot.lowercased().contains(lowered) { return true }
                    for h in attr.editHistory {
                        if h.lowercased().contains(lowered) { return true }
                    }
                    return false
                }
            }

            if let authorId = filter.authorId {
                filtered = filtered.filter { $0.author?.id == authorId }
            }

            if let dateFrom = filter.dateFrom {
                let ts = Int32(dateFrom.timeIntervalSince1970)
                filtered = filtered.filter { $0.timestamp >= ts }
            }

            if let dateTo = filter.dateTo {
                let ts = Int32(dateTo.timeIntervalSince1970)
                filtered = filtered.filter { $0.timestamp <= ts }
            }

            if let hasMedia = filter.hasMedia {
                filtered = filtered.filter { hasMedia ? !$0.media.isEmpty : $0.media.isEmpty }
            }

            if let mediaType = filter.mediaType {
                filtered = filtered.filter { msg in
                    for media in msg.media {
                        switch mediaType {
                        case "image": if media is TelegramMediaImage { return true }
                        case "video": if let f = media as? TelegramMediaFile, f.isVideo { return true }
                        case "voice": if let f = media as? TelegramMediaFile, f.isVoice { return true }
                        case "file": if media is TelegramMediaFile { return true }
                        case "sticker": if let f = media as? TelegramMediaFile, f.isSticker { return true }
                        case "location": if media is TelegramMediaMap { return true }
                        case "contact": if media is TelegramMediaContact { return true }
                        default: break
                        }
                    }
                    return false
                }
            }

            filtered.sort { $0.timestamp > $1.timestamp }

            if filter.offset > 0 {
                filtered = Array(filtered.dropFirst(filter.offset))
            }
            if filter.limit < filtered.count {
                filtered = Array(filtered.prefix(filter.limit))
            }

            return filtered
        }
    }

    // MARK: - Public: Get Statistics

    public static func getStatistics(
        postbox: Postbox,
        mediaBoxBasePath: String
    ) -> Signal<MQDeletedMessagesStats, NoError> {
        return postbox.transaction { transaction -> MQDeletedMessagesStats in
            var totalCount = 0
            var mediaCount = 0
            var textCount = 0
            var editedCount = 0
            var oldestTs: Int32?
            var newestTs: Int32?
            var peerCounts: [PeerId: Int] = [:]
            var mediaBreakdown: [String: Int] = [:]

            let allPeerIds = transaction.chatListGetAllPeerIds()
            for peerId in allPeerIds {
                var peerCount = 0
                transaction.scanMessageAttributes(peerId: peerId, namespace: messageNamespaceSavedDeleted, limit: Int.max) { messageId, _ in
                    if let message = transaction.getMessage(messageId) {
                        totalCount += 1
                        peerCount += 1

                        if message.media.isEmpty {
                            if !message.text.isEmpty { textCount += 1 }
                        } else {
                            mediaCount += 1
                            for media in message.media {
                                let typeName: String
                                if media is TelegramMediaImage {
                                    typeName = "image"
                                } else if let file = media as? TelegramMediaFile {
                                    if file.isVideo { typeName = "video" }
                                    else if file.isVoice { typeName = "voice" }
                                    else if file.isSticker { typeName = "sticker" }
                                    else if file.isMusic { typeName = "music" }
                                    else { typeName = "file" }
                                } else if media is TelegramMediaMap {
                                    typeName = "location"
                                } else if media is TelegramMediaContact {
                                    typeName = "contact"
                                } else if media is TelegramMediaPoll {
                                    typeName = "poll"
                                } else {
                                    typeName = "other"
                                }
                                mediaBreakdown[typeName, default: 0] += 1
                            }
                        }

                        let attr = message.mqDeletedAttribute
                        if !attr.editHistory.isEmpty { editedCount += 1 }

                        if oldestTs == nil || message.timestamp < (oldestTs ?? Int32.max) {
                            oldestTs = message.timestamp
                        }
                        if newestTs == nil || message.timestamp > (newestTs ?? 0) {
                            newestTs = message.timestamp
                        }
                    }
                    return true
                }
                if peerCount > 0 {
                    peerCounts[peerId] = peerCount
                }
            }

            let sortedPeers = peerCounts.sorted { $0.value > $1.value }
            let topPeers = sortedPeers.prefix(20).map { entry -> (peerId: PeerId, peer: Peer?, count: Int) in
                let peer = transaction.getPeer(entry.key)
                return (peerId: entry.key, peer: peer, count: entry.value)
            }

            let storageSize = storageSizeBytes(mediaBoxBasePath: mediaBoxBasePath)

            return MQDeletedMessagesStats(
                totalDeletedMessages: totalCount,
                totalPeersWithDeleted: peerCounts.count,
                totalMediaMessages: mediaCount,
                totalTextMessages: textCount,
                totalEditedBeforeDelete: editedCount,
                storageSizeBytes: storageSize,
                oldestDeletedTimestamp: oldestTs,
                newestDeletedTimestamp: newestTs,
                topPeersByCount: topPeers,
                mediaTypeBreakdown: mediaBreakdown
            )
        }
    }

    // MARK: - Public: Delete Specific Saved Messages

    public static func deleteSavedDeletedMessages(
        ids: [MessageId],
        postbox: Postbox
    ) -> Signal<Void, NoError> {
        return postbox.transaction { transaction -> Void in
            if !ids.isEmpty {
                transaction.deleteMessages(ids, forEachMedia: { _ in })
            }
        }
    }

    // MARK: - Public: Delete By Peer

    public static func deleteAllForPeer(
        postbox: Postbox,
        peerId: PeerId
    ) -> Signal<Int, NoError> {
        return postbox.transaction { transaction -> Int in
            var idsToDelete: [MessageId] = []
            transaction.scanMessageAttributes(peerId: peerId, namespace: messageNamespaceSavedDeleted, limit: Int.max) { messageId, _ in
                idsToDelete.append(messageId)
                return true
            }
            let count = idsToDelete.count
            if !idsToDelete.isEmpty {
                transaction.deleteMessages(idsToDelete, forEachMedia: { _ in })
            }
            return count
        }
    }

    // MARK: - Public: Delete By Date Range

    public static func deleteByDateRange(
        postbox: Postbox,
        before: Date? = nil,
        after: Date? = nil
    ) -> Signal<Int, NoError> {
        return postbox.transaction { transaction -> Int in
            var idsToDelete: [MessageId] = []
            let allPeerIds = transaction.chatListGetAllPeerIds()
            let beforeTs = before.map { Int32($0.timeIntervalSince1970) }
            let afterTs = after.map { Int32($0.timeIntervalSince1970) }

            for peerId in allPeerIds {
                transaction.scanMessageAttributes(peerId: peerId, namespace: messageNamespaceSavedDeleted, limit: Int.max) { messageId, _ in
                    if let message = transaction.getMessage(messageId) {
                        var shouldDelete = true
                        if let bts = beforeTs, message.timestamp > bts { shouldDelete = false }
                        if let ats = afterTs, message.timestamp < ats { shouldDelete = false }
                        if shouldDelete { idsToDelete.append(messageId) }
                    }
                    return true
                }
            }
            let count = idsToDelete.count
            if !idsToDelete.isEmpty {
                transaction.deleteMessages(idsToDelete, forEachMedia: { _ in })
            }
            return count
        }
    }

    // MARK: - Public: Clear All

    public static func clearAllDeletedMessages(
        postbox: Postbox
    ) -> Signal<Int, NoError> {
        return postbox.transaction { transaction -> Int in
            let attachmentsPath = postbox.mediaBox.basePath + "/saved-deleted-attachments"
            let _ = try? FileManager.default.removeItem(atPath: attachmentsPath)
            let _ = try? FileManager.default.createDirectory(atPath: attachmentsPath, withIntermediateDirectories: true, attributes: nil)

            var messageIdsToDelete: [MessageId] = []
            let allPeerIds = transaction.chatListGetAllPeerIds()
            for peerId in allPeerIds {
                transaction.scanMessageAttributes(peerId: peerId, namespace: messageNamespaceSavedDeleted, limit: Int.max) { messageId, _ in
                    messageIdsToDelete.append(messageId)
                    return true
                }
            }

            let count = messageIdsToDelete.count
            if !messageIdsToDelete.isEmpty {
                transaction.deleteMessages(messageIdsToDelete, forEachMedia: { _ in })
            }

            return count
        }
    }

    // MARK: - Public: Auto-Cleanup Old Messages

    public static func autoCleanup(
        postbox: Postbox,
        maxAge: TimeInterval,
        maxCount: Int? = nil
    ) -> Signal<Int, NoError> {
        return postbox.transaction { transaction -> Int in
            let cutoff = Int32(Date().timeIntervalSince1970 - maxAge)
            var allEntries: [(messageId: MessageId, timestamp: Int32)] = []

            let allPeerIds = transaction.chatListGetAllPeerIds()
            for peerId in allPeerIds {
                transaction.scanMessageAttributes(peerId: peerId, namespace: messageNamespaceSavedDeleted, limit: Int.max) { messageId, _ in
                    if let message = transaction.getMessage(messageId) {
                        allEntries.append((messageId: messageId, timestamp: message.timestamp))
                    }
                    return true
                }
            }

            var idsToDelete: [MessageId] = []

            for entry in allEntries where entry.timestamp < cutoff {
                idsToDelete.append(entry.messageId)
            }

            if let maxCount = maxCount, allEntries.count > maxCount {
                let sorted = allEntries.sorted { $0.timestamp < $1.timestamp }
                let excess = allEntries.count - maxCount
                for i in 0..<excess {
                    let id = sorted[i].messageId
                    if !idsToDelete.contains(id) {
                        idsToDelete.append(id)
                    }
                }
            }

            let count = idsToDelete.count
            if !idsToDelete.isEmpty {
                transaction.deleteMessages(idsToDelete, forEachMedia: { _ in })
            }
            return count
        }
    }

    // MARK: - Public: Export

    public static func exportDeletedMessages(
        postbox: Postbox,
        format: MQExportFormat,
        filter: MQDeletedMessagesFilter? = nil
    ) -> Signal<MQExportedData?, NoError> {
        return postbox.transaction { transaction -> MQExportedData? in
            var allMessages: [Message] = []
            let peerIds: [PeerId]
            if let filterPeerId = filter?.peerId {
                peerIds = [filterPeerId]
            } else {
                peerIds = transaction.chatListGetAllPeerIds()
            }

            for peerId in peerIds {
                transaction.scanMessageAttributes(peerId: peerId, namespace: messageNamespaceSavedDeleted, limit: Int.max) { messageId, _ in
                    if let message = transaction.getMessage(messageId) {
                        allMessages.append(message)
                    }
                    return true
                }
            }

            allMessages.sort { $0.timestamp > $1.timestamp }

            if allMessages.isEmpty { return nil }

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

            switch format {
            case .json:
                var entries: [[String: Any]] = []
                for msg in allMessages {
                    let attr = msg.mqDeletedAttribute
                    let peer = transaction.getPeer(msg.id.peerId)
                    var entry: [String: Any] = [
                        "message_id": Int(msg.id.id),
                        "peer_id": Int(msg.id.peerId.id._internalGetInt64Value()),
                        "peer_name": peerDisplayName(peer),
                        "text": msg.text,
                        "timestamp": Int(msg.timestamp),
                        "date": dateFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(msg.timestamp))),
                        "has_media": !msg.media.isEmpty,
                        "is_deleted": attr.isDeleted
                    ]
                    if let ot = attr.originalText { entry["original_text"] = ot }
                    if !attr.editHistory.isEmpty { entry["edit_history"] = attr.editHistory }
                    if let author = msg.author {
                        entry["author_id"] = Int(author.id.id._internalGetInt64Value())
                        entry["author_name"] = peerDisplayName(author)
                    }
                    entries.append(entry)
                }

                if let data = try? JSONSerialization.data(withJSONObject: entries, options: [.prettyPrinted, .sortedKeys]) {
                    return MQExportedData(format: .json, data: data, filename: "mqgram_deleted_messages.json", messageCount: allMessages.count)
                }

            case .csv:
                var csv = "message_id,peer_id,peer_name,author_name,text,original_text,timestamp,date,has_media\n"
                for msg in allMessages {
                    let attr = msg.mqDeletedAttribute
                    let peer = transaction.getPeer(msg.id.peerId)
                    let peerName = peerDisplayName(peer).replacingOccurrences(of: ",", with: ";")
                    let authorName = peerDisplayName(msg.author).replacingOccurrences(of: ",", with: ";")
                    let text = msg.text.replacingOccurrences(of: ",", with: ";").replacingOccurrences(of: "\n", with: " ")
                    let origText = (attr.originalText ?? "").replacingOccurrences(of: ",", with: ";").replacingOccurrences(of: "\n", with: " ")
                    let dateStr = dateFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(msg.timestamp)))
                    csv += "\(msg.id.id),\(msg.id.peerId.id._internalGetInt64Value()),\(peerName),\(authorName),\(text),\(origText),\(msg.timestamp),\(dateStr),\(!msg.media.isEmpty)\n"
                }
                if let data = csv.data(using: .utf8) {
                    return MQExportedData(format: .csv, data: data, filename: "mqgram_deleted_messages.csv", messageCount: allMessages.count)
                }

            case .text:
                var text = "MQGram Deleted Messages Export\n"
                text += "Generated: \(dateFormatter.string(from: Date()))\n"
                text += "Total: \(allMessages.count) messages\n"
                text += String(repeating: "=", count: 60) + "\n\n"
                for msg in allMessages {
                    let attr = msg.mqDeletedAttribute
                    let peer = transaction.getPeer(msg.id.peerId)
                    let pn = peerDisplayName(peer)
                    let peerName = pn.isEmpty ? "Unknown" : pn
                    let an = peerDisplayName(msg.author)
                    let authorName = an.isEmpty ? "Unknown" : an
                    let dateStr = dateFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(msg.timestamp)))
                    text += "[\(dateStr)] \(peerName) | \(authorName):\n"
                    if let ot = attr.originalText, ot != msg.text {
                        text += "  Original: \(ot)\n"
                    }
                    if !msg.text.isEmpty {
                        text += "  Text: \(msg.text)\n"
                    }
                    if !attr.editHistory.isEmpty {
                        text += "  Edit history: \(attr.editHistory.joined(separator: " -> "))\n"
                    }
                    if !msg.media.isEmpty {
                        text += "  Media: \(msg.media.count) item(s)\n"
                    }
                    text += String(repeating: "-", count: 40) + "\n"
                }
                if let data = text.data(using: .utf8) {
                    return MQExportedData(format: .text, data: data, filename: "mqgram_deleted_messages.txt", messageCount: allMessages.count)
                }
            }

            return nil
        }
    }

    // MARK: - Public: Restore Message To Chat

    public static func restoreMessageToChat(
        postbox: Postbox,
        savedMessageId: MessageId
    ) -> Signal<Bool, NoError> {
        return postbox.transaction { transaction -> Bool in
            guard let message = transaction.getMessage(savedMessageId) else { return false }
            guard savedMessageId.namespace == messageNamespaceSavedDeleted else { return false }

            let attr = message.mqDeletedAttribute
            guard let origNs = attr.originalNamespace, let origId = attr.originalId else { return false }

            let originalMessageId = MessageId(peerId: savedMessageId.peerId, namespace: origNs, id: origId)
            if transaction.messageExists(id: originalMessageId) { return false }

            var restoredAttributes = message.attributes
            restoredAttributes.updateMQDeletedAttribute { a in
                a.isDeleted = false
            }

            let storeForwardInfo = message.forwardInfo.flatMap(StoreMessageForwardInfo.init)
            let storeMessage = StoreMessage(
                id: originalMessageId,
                customStableId: nil,
                globallyUniqueId: nil,
                groupingKey: message.groupingKey,
                threadId: message.threadId,
                timestamp: message.timestamp,
                flags: StoreMessageFlags(message.flags),
                tags: message.tags,
                globalTags: message.globalTags,
                localTags: message.localTags,
                forwardInfo: storeForwardInfo,
                authorId: message.author?.id,
                text: message.text,
                attributes: restoredAttributes,
                media: message.media
            )
            let _ = transaction.addMessages([storeMessage], location: .UpperHistoryBlock)
            return true
        }
    }

    // MARK: - Public: Check If Message Has Saved Snapshot

    public static func hasSavedSnapshot(
        postbox: Postbox,
        originalId: MessageId
    ) -> Signal<Bool, NoError> {
        return postbox.transaction { transaction -> Bool in
            let snapshotId = savedDeletedId(for: originalId)
            return transaction.messageExists(id: snapshotId)
        }
    }

    // MARK: - Public: Get Deleted Messages Count Per Peer (for badge)

    public static func getDeletedCountsPerPeer(
        postbox: Postbox
    ) -> Signal<[PeerId: Int], NoError> {
        return postbox.transaction { transaction -> [PeerId: Int] in
            var counts: [PeerId: Int] = [:]
            let allPeerIds = transaction.chatListGetAllPeerIds()
            for peerId in allPeerIds {
                var count = 0
                transaction.scanMessageAttributes(peerId: peerId, namespace: messageNamespaceSavedDeleted, limit: Int.max) { _, _ in
                    count += 1
                    return true
                }
                if count > 0 {
                    counts[peerId] = count
                }
            }
            return counts
        }
    }

    // MARK: - Public: Get Recent Deleted Messages (cross-peer)

    public static func getRecentDeletedMessages(
        postbox: Postbox,
        limit: Int = 50
    ) -> Signal<[Message], NoError> {
        return postbox.transaction { transaction -> [Message] in
            var allMessages: [Message] = []
            let allPeerIds = transaction.chatListGetAllPeerIds()
            for peerId in allPeerIds {
                transaction.scanMessageAttributes(peerId: peerId, namespace: messageNamespaceSavedDeleted, limit: Int.max) { messageId, _ in
                    if let message = transaction.getMessage(messageId) {
                        allMessages.append(message)
                    }
                    return true
                }
            }
            allMessages.sort { $0.timestamp > $1.timestamp }
            return Array(allMessages.prefix(limit))
        }
    }

    // MARK: - Public: Observe Deleted Messages Count (live)

    public static func observeDeletedMessagesCount(
        postbox: Postbox
    ) -> Signal<Int, NoError> {
        return countDeletedMessages(postbox: postbox)
        |> then(
            postbox.combinedView(keys: [])
            |> mapToSignal { _ -> Signal<Int, NoError> in
                return countDeletedMessages(postbox: postbox)
            }
        )
    }

    // MARK: - Public: Sync Edited Message To Remote

    public static func syncEditedMessageToRemote(
        peerId: PeerId,
        messageId: MessageId,
        previousText: String?,
        newText: String?,
        editNumber: Int
    ) {
        MQGramDatabase.shared.logEditedMessage(
            peerId: String(peerId.id._internalGetInt64Value()),
            messageId: String(messageId.id),
            previousText: previousText,
            newText: newText,
            editNumber: editNumber
        )

        MQGramDatabase.shared.logEvent(
            type: .messageEdited,
            peerId: String(peerId.id._internalGetInt64Value()),
            messageId: String(messageId.id),
            data: newText.map { String($0.prefix(200)) }
        )
    }

    // MARK: - Public: Log Incoming Message To Remote

    public static func logIncomingMessage(
        message: Message
    ) {
        let info = MQDeletedMessageInfo(message: message)
        MQGramDatabase.shared.logMessage(
            peerId: String(message.id.peerId.id._internalGetInt64Value()),
            messageId: String(message.id.id),
            authorId: info.authorId.map { String($0.id._internalGetInt64Value()) },
            authorName: info.authorName,
            peerName: info.peerName,
            text: message.text.isEmpty ? nil : message.text,
            mediaTypes: info.mediaTypes.isEmpty ? nil : info.mediaTypes,
            timestamp: Int(message.timestamp),
            isOutgoing: message.flags.contains(.Incoming) ? false : true
        )
    }
}
