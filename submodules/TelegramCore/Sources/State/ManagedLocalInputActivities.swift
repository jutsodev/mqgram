import Foundation
import Postbox
import SwiftSignalKit
import TelegramApi
import MtProtoKit


public struct PeerActivitySpace: Hashable {
    public enum Category: Equatable, Hashable {
        case global
        case thread(Int64)
        case voiceChat
    }
    
    public var peerId: PeerId
    public var category: Category
    
    public init(peerId: PeerId, category: Category) {
        self.peerId = peerId
        self.category = category
    }
}

struct PeerInputActivityRecord: Equatable {
    let activity: PeerInputActivity
    let updateId: Int32
}

private final class ManagedLocalTypingActivitiesContext {
    private var disposables: [PeerActivitySpace: (PeerInputActivityRecord, MetaDisposable)] = [:]
    
    func update(activities: [PeerActivitySpace: [(PeerId, PeerInputActivityRecord)]]) -> (start: [(PeerActivitySpace, PeerInputActivityRecord?, MetaDisposable)], dispose: [MetaDisposable]) {
        var start: [(PeerActivitySpace, PeerInputActivityRecord?, MetaDisposable)] = []
        var dispose: [MetaDisposable] = []
        
        var validPeerIds = Set<PeerActivitySpace>()
        for (peerId, record) in activities {
            if let activity = record.first?.1 {
                validPeerIds.insert(peerId)
                
                let currentRecord = self.disposables[peerId]
                if currentRecord == nil || currentRecord!.0 != activity {
                    if let disposable = currentRecord?.1 {
                        dispose.append(disposable)
                    }
                    
                    let disposable = MetaDisposable()
                    start.append((peerId, activity, disposable))
                    
                    self.disposables[peerId] = (activity, disposable)
                }
            }
        }
        
        var removePeerIds: [PeerActivitySpace] = []
        for key in self.disposables.keys {
            if !validPeerIds.contains(key) {
                removePeerIds.append(key)
            }
        }
        
        for peerId in removePeerIds {
            dispose.append(self.disposables[peerId]!.1)
            self.disposables.removeValue(forKey: peerId)
        }
        
        return (start, dispose)
    }
    
    func dispose() {
        for (_, record) in self.disposables {
            record.1.dispose()
        }
        self.disposables.removeAll()
    }
}

func managedLocalTypingActivities(activities: Signal<[PeerActivitySpace: [(PeerId, PeerInputActivityRecord)]], NoError>, postbox: Postbox, network: Network, accountPeerId: PeerId) -> Signal<Void, NoError> {
    return Signal { subscriber in
        let context = Atomic(value: ManagedLocalTypingActivitiesContext())
        let disposable = activities.start(next: { activities in
            let (start, dispose) = context.with { context in
                return context.update(activities: activities)
            }
            
            for disposable in dispose {
                disposable.dispose()
            }
            
            for (peerId, activity, disposable) in start {
                var threadId: Int64?
                switch peerId.category {
                case let .thread(id):
                    threadId = id
                default:
                    break
                }
                disposable.set(requestActivity(postbox: postbox, network: network, accountPeerId: accountPeerId, peerId: peerId.peerId, threadId: threadId, activity: activity?.activity).start())
            }
        })
        return ActionDisposable {
            disposable.dispose()
            
            context.with { context -> Void in
                context.dispose()
            }
        }
    }
}

private func actionFromActivity(_ activity: PeerInputActivity?) -> Api.SendMessageAction {
    if let activity = activity {
        switch activity {
            case .typingText:
                return .sendMessageTypingAction
            case .recordingVoice:
                return .sendMessageRecordAudioAction
            case .playingGame:
                return .sendMessageGamePlayAction
            case let .uploadingFile(progress):
                return .sendMessageUploadDocumentAction(.init(progress: progress))
            case let .uploadingPhoto(progress):
                return .sendMessageUploadPhotoAction(.init(progress: progress))
            case let .uploadingVideo(progress):
                return .sendMessageUploadVideoAction(.init(progress: progress))
            case .recordingInstantVideo:
                return .sendMessageRecordRoundAction
            case let .uploadingInstantVideo(progress):
                return .sendMessageUploadRoundAction(.init(progress: progress))
            case .speakingInGroupCall:
                return .speakingInGroupCallAction
            case .choosingSticker:
                return .sendMessageChooseStickerAction
            case let .interactingWithEmoji(emoticon, messageId, interaction):
                return .sendMessageEmojiInteraction(.init(emoticon: emoticon, msgId: messageId.id, interaction: interaction?.apiDataJson ?? .dataJSON(.init(data: ""))))
            case let .seeingEmojiInteraction(emoticon):
                return .sendMessageEmojiInteractionSeen(.init(emoticon: emoticon))
            // MARK: MQGram - Support for choosing contact and location
            case .choosingContact:
                return .sendMessageChooseContactAction
            case .choosingLocation:
                return .sendMessageGeoLocationAction
        }
    } else {
        return .sendMessageCancelAction
    }
}

private func requestActivity(postbox: Postbox, network: Network, accountPeerId: PeerId, peerId: PeerId, threadId: Int64?, activity: PeerInputActivity?) -> Signal<Void, NoError> {
    // MARK: MQGram - Comprehensive Ghost Mode Activity Blocking
    // This function blocks sending typing/activity indicators based on detailed user preferences
    
    // Check if activity should be blocked
    if let activity = activity {
        // Master ghost mode check - blocks ALL activities
        let ghostModeEnabled = UserDefaults.standard.bool(forKey: "MQGram.ghostMode")
        let ghostTypingActionsEnabled = UserDefaults.standard.bool(forKey: "MQGram.ghostTypingActions")
        
        // If master switches are on, block everything
        if ghostModeEnabled || ghostTypingActionsEnabled {
            return .complete()
        }
        
        // Detailed per-activity checks
        switch activity {
        case .typingText:
            // Block typing text indicator
            if UserDefaults.standard.bool(forKey: "MQGram.ghostTypingText") {
                return .complete()
            }
            
        case .recordingVoice:
            // Block recording voice message indicator
            if UserDefaults.standard.bool(forKey: "MQGram.ghostRecordingVoice") {
                return .complete()
            }
            
        case .uploadingFile:
            // Block uploading file indicator
            if UserDefaults.standard.bool(forKey: "MQGram.ghostUploadingFile") {
                return .complete()
            }
            
        case .uploadingPhoto:
            // Block uploading photo indicator
            if UserDefaults.standard.bool(forKey: "MQGram.ghostUploadingPhoto") {
                return .complete()
            }
            
        case .uploadingVideo:
            // Block uploading video indicator
            if UserDefaults.standard.bool(forKey: "MQGram.ghostUploadingVideo") {
                return .complete()
            }
            
        case .recordingInstantVideo:
            // Block recording round video indicator
            if UserDefaults.standard.bool(forKey: "MQGram.ghostRecordingRound") {
                return .complete()
            }
            
        case .uploadingInstantVideo:
            // Block uploading round video indicator
            if UserDefaults.standard.bool(forKey: "MQGram.ghostUploadingRound") {
                return .complete()
            }
            
        case .playingGame:
            // Block playing game indicator
            if UserDefaults.standard.bool(forKey: "MQGram.ghostPlayingGame") {
                return .complete()
            }
            
        case .speakingInGroupCall:
            // Block speaking in group call indicator
            if UserDefaults.standard.bool(forKey: "MQGram.ghostSpeakingInGroupCall") {
                return .complete()
            }
            
        case .choosingSticker:
            // Block choosing sticker indicator
            if UserDefaults.standard.bool(forKey: "MQGram.ghostChoosingSticker") {
                return .complete()
            }
            
        case .interactingWithEmoji:
            // Block emoji interaction indicator
            if UserDefaults.standard.bool(forKey: "MQGram.ghostEmojiInteraction") {
                return .complete()
            }
            // Legacy check for backwards compatibility
            if UserDefaults.standard.bool(forKey: "MQGram.ghostEmojiInteractions") {
                return .complete()
            }
            
        case .seeingEmojiInteraction:
            // Block seeing emoji interaction indicator
            if UserDefaults.standard.bool(forKey: "MQGram.ghostEmojiInteraction") {
                return .complete()
            }
            // Legacy check for backwards compatibility
            if UserDefaults.standard.bool(forKey: "MQGram.ghostEmojiInteractions") {
                return .complete()
            }
            
        case .choosingContact:
            // Block choosing contact indicator
            if UserDefaults.standard.bool(forKey: "MQGram.ghostChoosingContact") {
                return .complete()
            }
            
        case .choosingLocation:
            // Block choosing location indicator
            if UserDefaults.standard.bool(forKey: "MQGram.ghostChoosingLocation") {
                return .complete()
            }
        }
    }
    
    // Original Telegram logic - only execute if not blocked by MQGram
    return postbox.transaction { transaction -> Signal<Void, NoError> in
        if let peer = transaction.getPeer(peerId) {
            if peerId == accountPeerId {
                return .complete()
            }
            if let channel = peer as? TelegramChannel, case .broadcast = channel.info {
                if let activity = activity {
                    switch activity {
                    case .speakingInGroupCall:
                        break
                    default:
                        return .complete()
                    }
                }
            }
            if let _ = peer as? TelegramUser {
                if let presence = transaction.getPeerPresence(peerId: peerId) as? TelegramUserPresence {
                    switch presence.status {
                    case .none, .lastWeek, .lastMonth:
                        return .complete()
                    case .recently:
                        break
                    case let .present(statusTimestamp):
                        let timestamp = Int32(CFAbsoluteTimeGetCurrent() + NSTimeIntervalSince1970)
                        if statusTimestamp < timestamp - 30 {
                            return .complete()
                        }
                    }
                } else {
                    return .complete()
                }
            }
            
            if let inputPeer = apiInputPeer(peer) {
                var flags: Int32 = 0
                let topMessageId = threadId.flatMap { Int32(clamping: $0) }
                if topMessageId != nil {
                    flags |= 1 << 0
                }
                return network.request(Api.functions.messages.setTyping(flags: flags, peer: inputPeer, topMsgId: topMessageId, action: actionFromActivity(activity)))
                |> `catch` { _ -> Signal<Api.Bool, NoError> in
                    return .single(.boolFalse)
                }
                |> mapToSignal { _ -> Signal<Void, NoError> in
                    return .complete()
                }
            } else if let peer = peer as? TelegramSecretChat, activity == .typingText {
                let _ = PeerId(peer.id.toInt64())
                return network.request(Api.functions.messages.setEncryptedTyping(peer: .inputEncryptedChat(.init(chatId: Int32(peer.id.id._internalGetInt64Value()), accessHash: peer.accessHash)), typing: .boolTrue))
                |> `catch` { _ -> Signal<Api.Bool, NoError> in
                    return .single(.boolFalse)
                }
                |> mapToSignal { _ -> Signal<Void, NoError> in
                    return .complete()
                }
            } else {
                return .complete()
            }
        } else {
            return .complete()
        }
    } |> switchToLatest
}
