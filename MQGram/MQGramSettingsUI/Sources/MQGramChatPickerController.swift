// MARK: MQGram - Chat Picker Controller
import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramPresentationData
import ItemListUI
import PresentationDataUtils
import AccountContext
import TelegramCore

private final class MQGramChatPickerArguments {
    let togglePeer: (EnginePeer.Id) -> Void

    init(togglePeer: @escaping (EnginePeer.Id) -> Void) {
        self.togglePeer = togglePeer
    }
}

private struct MQGramChatPickerState: Equatable {
    var peers: [MQGramChatPickerPeerInfo]
    var lockedPeerIds: Set<Int64>
}

private struct MQGramChatPickerPeerInfo: Equatable {
    var id: EnginePeer.Id
    var title: String
    var isGroup: Bool
    var isChannel: Bool
}

private enum MQGramChatPickerSection: Int32 {
    case chats
}

private enum MQGramChatPickerEntryId: Hashable {
    case header
    case peer(EnginePeer.Id)
    case empty
}

private enum MQGramChatPickerEntry: ItemListNodeEntry {
    case header(String)
    case peer(Int32, MQGramChatPickerPeerInfo, Bool)
    case empty(String)

    var section: ItemListSectionId {
        return MQGramChatPickerSection.chats.rawValue
    }

    var stableId: MQGramChatPickerEntryId {
        switch self {
        case .header: return .header
        case let .peer(_, info, _): return .peer(info.id)
        case .empty: return .empty
        }
    }

    static func ==(lhs: MQGramChatPickerEntry, rhs: MQGramChatPickerEntry) -> Bool {
        switch lhs {
        case let .header(lText):
            if case let .header(rText) = rhs, lText == rText { return true } else { return false }
        case let .peer(lId, lInfo, lSelected):
            if case let .peer(rId, rInfo, rSelected) = rhs, lId == rId, lInfo == rInfo, lSelected == rSelected { return true } else { return false }
        case let .empty(lText):
            if case let .empty(rText) = rhs, lText == rText { return true } else { return false }
        }
    }

    static func <(lhs: MQGramChatPickerEntry, rhs: MQGramChatPickerEntry) -> Bool {
        return lhs.sortIndex < rhs.sortIndex
    }

    var sortIndex: Int32 {
        switch self {
        case .header: return -1
        case let .peer(id, _, _): return id
        case .empty: return 0
        }
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let args = arguments as! MQGramChatPickerArguments
        switch self {
        case let .header(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .peer(_, info, isSelected):
            let icon: String
            if info.isChannel {
                icon = "📢"
            } else if info.isGroup {
                icon = "👥"
            } else {
                icon = "💬"
            }
            return ItemListCheckboxItem(
                presentationData: presentationData,
                title: "\(icon) \(info.title)",
                style: .left,
                checked: isSelected,
                zeroSeparatorInsets: false,
                sectionId: self.section,
                action: {
                    args.togglePeer(info.id)
                }
            )
        case let .empty(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        }
    }
}

private func mqgramChatPickerEntries(state: MQGramChatPickerState) -> [MQGramChatPickerEntry] {
    var entries: [MQGramChatPickerEntry] = []

    entries.append(.header("ВЫБЕРИТЕ ЧАТЫ ДЛЯ ЗАЩИТЫ"))

    if state.peers.isEmpty {
        entries.append(.empty("Нет доступных чатов"))
    } else {
        var id: Int32 = 0
        for peer in state.peers {
            let isLocked = state.lockedPeerIds.contains(peer.id.id._internalGetInt64Value())
            entries.append(.peer(id, peer, isLocked))
            id += 1
        }
    }

    return entries
}

func mqgramChatPickerController(context: AccountContext, completion: @escaping () -> Void) -> ViewController {
    let statePromise = ValuePromise<MQGramChatPickerState>(ignoreRepeated: true)

    let chatListSignal = context.engine.messages.chatList(group: .root, count: 100)
    |> take(1)

    let _ = chatListSignal.startStandalone(next: { chatList in
        var peers: [MQGramChatPickerPeerInfo] = []
        for item in chatList.items {
            let peer = item.renderedPeer.peer
            guard let peer = peer else { continue }

            let title: String
            switch peer {
            case let .legacyGroup(group):
                title = group.title
            case let .channel(channel):
                title = channel.title
            case let .user(user):
                title = [user.firstName, user.lastName].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " ")
            default:
                continue
            }

            let isGroup: Bool
            let isChannel: Bool
            switch peer {
            case .legacyGroup:
                isGroup = true
                isChannel = false
            case let .channel(channel):
                if case .group = channel.info {
                    isGroup = true
                    isChannel = false
                } else {
                    isGroup = false
                    isChannel = true
                }
            default:
                isGroup = false
                isChannel = false
            }

            if !title.isEmpty {
                peers.append(MQGramChatPickerPeerInfo(
                    id: peer.id,
                    title: title,
                    isGroup: isGroup,
                    isChannel: isChannel
                ))
            }
        }

        let lockedIds = Set(MQGramPasscodeManager.shared.lockedPeerIds)
        statePromise.set(MQGramChatPickerState(peers: peers, lockedPeerIds: lockedIds))
    })

    let arguments = MQGramChatPickerArguments(
        togglePeer: { peerId in
            let int64Id = peerId.id._internalGetInt64Value()
            if MQGramPasscodeManager.shared.isPeerLocked(int64Id) {
                MQGramPasscodeManager.shared.removeLockedPeer(int64Id)
            } else {
                MQGramPasscodeManager.shared.addLockedPeer(int64Id)
            }
            let lockedIds = Set(MQGramPasscodeManager.shared.lockedPeerIds)
            statePromise.set(MQGramChatPickerState(peers: [], lockedPeerIds: lockedIds))

            let _ = chatListSignal.startStandalone(next: { chatList in
                var peers: [MQGramChatPickerPeerInfo] = []
                for item in chatList.items {
                    let peer = item.renderedPeer.peer
                    guard let peer = peer else { continue }

                    let title: String
                    switch peer {
                    case let .legacyGroup(group):
                        title = group.title
                    case let .channel(channel):
                        title = channel.title
                    case let .user(user):
                        title = [user.firstName, user.lastName].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " ")
                    default:
                        continue
                    }

                    let isGroup: Bool
                    let isChannel: Bool
                    switch peer {
                    case .legacyGroup:
                        isGroup = true
                        isChannel = false
                    case let .channel(channel):
                        if case .group = channel.info {
                            isGroup = true
                            isChannel = false
                        } else {
                            isGroup = false
                            isChannel = true
                        }
                    default:
                        isGroup = false
                        isChannel = false
                    }

                    if !title.isEmpty {
                        peers.append(MQGramChatPickerPeerInfo(
                            id: peer.id,
                            title: title,
                            isGroup: isGroup,
                            isChannel: isChannel
                        ))
                    }
                }

                let currentLockedIds = Set(MQGramPasscodeManager.shared.lockedPeerIds)
                statePromise.set(MQGramChatPickerState(peers: peers, lockedPeerIds: currentLockedIds))
            })

            completion()
        }
    )

    let signal = combineLatest(context.sharedContext.presentationData, statePromise.get())
    |> map { presentationData, pickerState -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text("Выбор чатов"),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)
        )

        let entries = mqgramChatPickerEntries(state: pickerState)

        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: entries,
            style: .blocks
        )

        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    return controller
}
