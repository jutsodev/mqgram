// MARK: MQGram - Deleted Message Attribute (ported from GLEGram/SGDeletedMessageAttribute)
import Foundation
import Postbox

public final class MQDeletedMessageAttribute: MessageAttribute, Equatable {
    public var isDeleted: Bool
    public var originalText: String?
    public var editHistory: [String]
    public var originalNamespace: Int32?
    public var originalId: Int32?

    public init(isDeleted: Bool = false, originalText: String? = nil, editHistory: [String] = [], originalNamespace: Int32? = nil, originalId: Int32? = nil) {
        self.isDeleted = isDeleted
        self.originalText = originalText
        self.editHistory = editHistory
        self.originalNamespace = originalNamespace
        self.originalId = originalId
    }

    public init(decoder: PostboxDecoder) {
        self.isDeleted = decoder.decodeInt32ForKey("d", orElse: 0) != 0
        self.originalText = decoder.decodeOptionalStringForKey("ot")
        self.editHistory = decoder.decodeOptionalStringArrayForKey("eh") ?? []
        self.originalNamespace = decoder.decodeOptionalInt32ForKey("on")
        self.originalId = decoder.decodeOptionalInt32ForKey("oi")
    }

    public func encode(_ encoder: PostboxEncoder) {
        encoder.encodeInt32(self.isDeleted ? 1 : 0, forKey: "d")
        if let originalText = self.originalText {
            encoder.encodeString(originalText, forKey: "ot")
        }
        if !editHistory.isEmpty {
            encoder.encodeStringArray(editHistory, forKey: "eh")
        }
        if let originalNamespace = self.originalNamespace {
            encoder.encodeInt32(originalNamespace, forKey: "on")
        }
        if let originalId = self.originalId {
            encoder.encodeInt32(originalId, forKey: "oi")
        }
    }

    public static func ==(lhs: MQDeletedMessageAttribute, rhs: MQDeletedMessageAttribute) -> Bool {
        return lhs.isDeleted == rhs.isDeleted && lhs.originalText == rhs.originalText && lhs.editHistory == rhs.editHistory && lhs.originalNamespace == rhs.originalNamespace && lhs.originalId == rhs.originalId
    }

    public func allEditVersions(currentText: String) -> [String] {
        var versions: [String] = []
        if let ot = originalText, !ot.isEmpty {
            versions.append(ot)
        }
        for h in editHistory where !h.isEmpty && h != versions.last {
            versions.append(h)
        }
        if !currentText.isEmpty && currentText != versions.last {
            versions.append(currentText)
        }
        return versions
    }
}

// MARK: - Extension for Message
public extension Message {
    var mqDeletedAttribute: MQDeletedMessageAttribute {
        for attribute in self.attributes {
            if let deletedAttribute = attribute as? MQDeletedMessageAttribute {
                return deletedAttribute
            }
        }
        return MQDeletedMessageAttribute()
    }
}

// MARK: - Extension for Transaction
public extension Transaction {
    func updateMQDeletedAttribute(messageId: MessageId, _ block: (inout MQDeletedMessageAttribute) -> Void) {
        self.updateMessage(messageId) { message in
            var attributes = message.attributes
            attributes.updateMQDeletedAttribute(block)
            let storeForwardInfo = message.forwardInfo.flatMap(StoreMessageForwardInfo.init)
            return .update(StoreMessage(
                id: message.id,
                customStableId: nil,
                globallyUniqueId: message.globallyUniqueId,
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
            ))
        }
    }
}

// MARK: - Extension for StoreMessage
public extension StoreMessage {
    func updatingMQDeletedAttributeOnEdit(previousMessage: Message) -> StoreMessage {
        let newAttr = self.attributes.compactMap { $0 as? MQDeletedMessageAttribute }.first
        let attr = newAttr ?? previousMessage.mqDeletedAttribute

        if attr.originalText == nil {
            attr.originalText = previousMessage.text
        }
        let prev = previousMessage.text
        if !prev.isEmpty {
            let last = attr.editHistory.last ?? attr.originalText
            if prev != last {
                attr.editHistory.append(prev)
            }
        }

        var attributes = self.attributes
        attributes.updateMQDeletedAttribute {
            $0 = attr
        }

        return self.withUpdatedAttributes(attributes)
    }
}

// MARK: - Extension for Array<MessageAttribute>
extension Array where Element == MessageAttribute {
    mutating func updateMQDeletedAttribute(_ block: (inout MQDeletedMessageAttribute) -> Void) {
        for (index, attribute) in self.enumerated() {
            if var deletedAttribute = attribute as? MQDeletedMessageAttribute {
                block(&deletedAttribute)
                self[index] = deletedAttribute
                return
            }
        }

        var deletedAttribute = MQDeletedMessageAttribute()
        block(&deletedAttribute)
        self.append(deletedAttribute)
    }
}
