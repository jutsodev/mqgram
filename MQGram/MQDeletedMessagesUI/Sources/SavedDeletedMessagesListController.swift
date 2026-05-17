// MARK: MQGram - Saved Deleted Messages List Controller
import Foundation
import UIKit
import Display
import SwiftSignalKit
import Postbox
import TelegramCore
import TelegramPresentationData
import ItemListUI
import PresentationDataUtils
import AccountContext
import MQDeletedMessages

// MARK: - Entry

private enum SavedDeletedListEntry: ItemListNodeEntry {
    case search(id: Int, query: String)
    case empty(id: Int, text: String)
    case peerHeader(id: Int, sectionIndex: Int32, text: String)
    case messageRow(id: Int, sectionIndex: Int32, text: String, dateText: String, peerId: PeerId, messageId: MessageId, searchableText: String)
    case deleteAction(id: Int, sectionIndex: Int32, text: String, peerId: PeerId)
    case clearAll(id: Int, text: String)
    case stats(id: Int, text: String)

    var stableId: Int {
        switch self {
        case .search(let id, _): return id
        case .empty(let id, _): return id
        case .peerHeader(let id, _, _): return id
        case .messageRow(let id, _, _, _, _, _, _): return id
        case .deleteAction(let id, _, _, _): return id
        case .clearAll(let id, _): return id
        case .stats(let id, _): return id
        }
    }

    var section: ItemListSectionId {
        switch self {
        case .search: return 0
        case .empty: return 0
        case .stats: return 0
        case .clearAll: return 9999
        case .peerHeader(_, let s, _): return s
        case .messageRow(_, let s, _, _, _, _, _): return s
        case .deleteAction(_, let s, _, _): return s
        }
    }

    static func < (lhs: SavedDeletedListEntry, rhs: SavedDeletedListEntry) -> Bool {
        lhs.stableId < rhs.stableId
    }

    static func == (lhs: SavedDeletedListEntry, rhs: SavedDeletedListEntry) -> Bool {
        switch (lhs, rhs) {
        case let (.search(a, q1), .search(b, q2)): return a == b && q1 == q2
        case let (.empty(a, t1), .empty(b, t2)): return a == b && t1 == t2
        case let (.peerHeader(a, s1, t1), .peerHeader(b, s2, t2)): return a == b && s1 == s2 && t1 == t2
        case let (.messageRow(a, s1, t1, d1, p1, m1, _), .messageRow(b, s2, t2, d2, p2, m2, _)): return a == b && s1 == s2 && t1 == t2 && d1 == d2 && p1 == p2 && m1 == m2
        case let (.deleteAction(a, s1, t1, p1), .deleteAction(b, s2, t2, p2)): return a == b && s1 == s2 && t1 == t2 && p1 == p2
        case let (.clearAll(a, t1), .clearAll(b, t2)): return a == b && t1 == t2
        case let (.stats(a, t1), .stats(b, t2)): return a == b && t1 == t2
        default: return false
        }
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let args = arguments as! SavedDeletedListArguments
        switch self {
        case .search(_, let query):
            return ItemListSingleLineInputItem(
                presentationData: presentationData,
                title: NSAttributedString(string: ""),
                text: query,
                placeholder: presentationData.strings.Common_Search,
                type: .regular(capitalization: false, autocorrection: false),
                spacing: 0.0,
                clearType: .always,
                tag: nil,
                sectionId: section,
                textUpdated: { args.searchUpdated($0) },
                action: {}
            )
        case .empty(_, let text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: section)
        case .peerHeader(_, _, let text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: section)
        case .messageRow(_, _, let text, let dateText, let peerId, let messageId, _):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                title: text,
                label: dateText,
                sectionId: section,
                style: .blocks,
                action: { args.openMessage(peerId, messageId) }
            )
        case .deleteAction(_, _, let text, let peerId):
            return ItemListActionItem(
                presentationData: presentationData,
                title: text,
                kind: .destructive,
                alignment: .natural,
                sectionId: section,
                style: .blocks,
                action: { args.deleteMessagesForPeer(peerId) }
            )
        case .clearAll(_, let text):
            return ItemListActionItem(
                presentationData: presentationData,
                title: text,
                kind: .destructive,
                alignment: .center,
                sectionId: section,
                style: .blocks,
                action: { args.clearAll() }
            )
        case .stats(_, let text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: section)
        }
    }
}

// MARK: - Arguments

private final class SearchQueryRef {
    var value: String = ""
}

private final class SavedDeletedListArguments {
    let searchQueryRef: SearchQueryRef
    var searchQuery: String { searchQueryRef.value }
    let searchUpdated: (String) -> Void
    let deleteMessagesForPeer: (PeerId) -> Void
    let openMessage: (PeerId, MessageId) -> Void
    let clearAll: () -> Void

    init(
        searchQueryRef: SearchQueryRef,
        searchUpdated: @escaping (String) -> Void,
        deleteMessagesForPeer: @escaping (PeerId) -> Void,
        openMessage: @escaping (PeerId, MessageId) -> Void,
        clearAll: @escaping () -> Void
    ) {
        self.searchQueryRef = searchQueryRef
        self.searchUpdated = searchUpdated
        self.deleteMessagesForPeer = deleteMessagesForPeer
        self.openMessage = openMessage
        self.clearAll = clearAll
    }
}

// MARK: - Date formatting

private let dateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateStyle = .medium
    f.timeStyle = .short
    return f
}()

// MARK: - Entries builder

private func savedDeletedListEntries(
    data: [(peer: Peer?, peerId: PeerId, messages: [Message])],
    lang: String
) -> [SavedDeletedListEntry] {
    var entries: [SavedDeletedListEntry] = []
    var id = 0

    entries.append(.search(id: id, query: ""))
    id += 1

    if data.isEmpty {
        let text = lang == "ru"
            ? "Нет сохранённых удалённых сообщений."
            : "No saved deleted messages."
        entries.append(.empty(id: id, text: text))
        return entries
    }

    var totalMessages = 0
    for group in data {
        totalMessages += group.messages.count
    }
    let statsText = lang == "ru"
        ? "Всего: \(totalMessages) удалённых сообщений из \(data.count) чатов"
        : "Total: \(totalMessages) deleted messages from \(data.count) chats"
    entries.append(.stats(id: id, text: statsText))
    id += 1

    var sectionIndex: Int32 = 0
    for group in data {
        let peerName: String
        if let peer = group.peer {
            peerName = peer.debugDisplayTitle
        } else {
            peerName = "Peer \(group.peerId.id._internalGetInt64Value())"
        }
        sectionIndex += 1
        let countStr = lang == "ru" ? "\(group.messages.count) сообщ." : "\(group.messages.count) msg"
        entries.append(.peerHeader(id: id, sectionIndex: sectionIndex, text: "\(peerName.uppercased()) (\(countStr))"))
        id += 1

        for message in group.messages {
            let text: String
            if message.text.isEmpty {
                text = lang == "ru" ? "[медиа]" : "[media]"
            } else {
                text = String(message.text.prefix(120)).replacingOccurrences(of: "\n", with: " ")
            }
            let attr = message.mqDeletedAttribute
            let searchableText = (message.text + " " + (attr.originalText ?? "")).trimmingCharacters(in: .whitespacesAndNewlines)
            let date = dateFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(message.timestamp)))
            entries.append(.messageRow(id: id, sectionIndex: sectionIndex, text: text, dateText: date, peerId: group.peerId, messageId: message.id, searchableText: searchableText))
            id += 1
        }

        let deleteText = lang == "ru" ? "Удалить все для этого чата" : "Delete all for this chat"
        entries.append(.deleteAction(id: id, sectionIndex: sectionIndex, text: deleteText, peerId: group.peerId))
        id += 1
    }

    let clearText = lang == "ru" ? "Очистить все удалённые" : "Clear All Deleted Messages"
    entries.append(.clearAll(id: 99999, text: clearText))

    return entries
}

private func filterSavedDeletedListEntries(_ entries: [SavedDeletedListEntry], by searchQuery: String?, lang: String) -> [SavedDeletedListEntry] {
    guard let query = searchQuery?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), !query.isEmpty else {
        return entries
    }
    var sectionIdsWithMatches: Set<Int32> = []
    for entry in entries {
        switch entry {
        case .search, .empty, .clearAll, .stats:
            break
        case .peerHeader(_, let s, let text):
            if text.lowercased().contains(query) { sectionIdsWithMatches.insert(s) }
        case .messageRow(_, let s, _, let dateText, _, _, let searchableText):
            if searchableText.lowercased().contains(query) || dateText.lowercased().contains(query) { sectionIdsWithMatches.insert(s) }
        case .deleteAction(_, let s, let text, _):
            if text.lowercased().contains(query) { sectionIdsWithMatches.insert(s) }
        }
    }
    var filtered: [SavedDeletedListEntry] = []
    for entry in entries {
        switch entry {
        case .search:
            filtered.append(entry)
        case .empty, .stats:
            continue
        case .clearAll:
            filtered.append(entry)
        case .peerHeader(_, let s, _), .messageRow(_, let s, _, _, _, _, _), .deleteAction(_, let s, _, _):
            if sectionIdsWithMatches.contains(s) {
                filtered.append(entry)
            }
        }
    }
    if filtered.count <= 2 {
        let noResultsText = lang == "ru" ? "Ничего не найдено." : "No results."
        filtered.insert(.empty(id: Int.max - 1, text: noResultsText), at: 1)
    }
    return filtered
}

// MARK: - Controller

public func savedDeletedMessagesListController(context: AccountContext) -> ViewController {
    var presentControllerImpl: ((ViewController, ViewControllerPresentationArguments?) -> Void)?
    var pushControllerImpl: ((ViewController) -> Void)?
    let reloadPromise = ValuePromise(true, ignoreRepeated: false)
    let searchQueryPromise = ValuePromise("", ignoreRepeated: false)
    let searchQueryRef = SearchQueryRef()

    let arguments = SavedDeletedListArguments(
        searchQueryRef: searchQueryRef,
        searchUpdated: { value in
            searchQueryRef.value = value
            searchQueryPromise.set(value)
        },
        deleteMessagesForPeer: { peerId in
            let presentationData = context.sharedContext.currentPresentationData.with { $0 }
            let lang = presentationData.strings.baseLanguageCode
            let title = lang == "ru" ? "Удалить" : "Delete"
            let text = lang == "ru"
                ? "Удалить все сохранённые удалённые сообщения для этого чата?"
                : "Delete all saved deleted messages for this chat?"
            let alert = textAlertController(
                context: context,
                title: title,
                text: text,
                actions: [
                    TextAlertAction(type: .destructiveAction, title: presentationData.strings.Common_Delete, action: {
                        let _ = (MQDeletedMessages.getAllSavedDeletedMessages(postbox: context.account.postbox)
                        |> mapToSignal { groups -> Signal<Void, NoError> in
                            var idsToDelete: [MessageId] = []
                            for group in groups where group.peerId == peerId {
                                idsToDelete.append(contentsOf: group.messages.map { $0.id })
                            }
                            return MQDeletedMessages.deleteSavedDeletedMessages(ids: idsToDelete, postbox: context.account.postbox)
                        }
                        |> deliverOnMainQueue).start(completed: {
                            reloadPromise.set(true)
                        })
                    }),
                    TextAlertAction(type: .defaultAction, title: presentationData.strings.Common_Cancel, action: {})
                ]
            )
            presentControllerImpl?(alert, nil)
        },
        openMessage: { peerId, messageId in
            let chatController = context.sharedContext.makeChatController(
                context: context,
                chatLocation: .peer(id: peerId),
                subject: .message(id: .id(messageId), highlight: nil, timecode: nil, setupReply: false),
                botStart: nil,
                mode: .standard(.default),
                params: nil
            )
            pushControllerImpl?(chatController)
        },
        clearAll: {
            let presentationData = context.sharedContext.currentPresentationData.with { $0 }
            let lang = presentationData.strings.baseLanguageCode
            let title = lang == "ru" ? "Очистить все" : "Clear All"
            let text = lang == "ru"
                ? "Удалить все сохранённые удалённые сообщения? Это действие необратимо."
                : "Delete all saved deleted messages? This action cannot be undone."
            let alert = textAlertController(
                context: context,
                title: title,
                text: text,
                actions: [
                    TextAlertAction(type: .destructiveAction, title: presentationData.strings.Common_Delete, action: {
                        let _ = (MQDeletedMessages.clearAllDeletedMessages(postbox: context.account.postbox)
                        |> deliverOnMainQueue).start(next: { _ in
                            reloadPromise.set(true)
                        })
                    }),
                    TextAlertAction(type: .defaultAction, title: presentationData.strings.Common_Cancel, action: {})
                ]
            )
            presentControllerImpl?(alert, nil)
        }
    )

    let dataSignal = reloadPromise.get()
    |> mapToSignal { _ -> Signal<[(peer: Peer?, peerId: PeerId, messages: [Message])], NoError> in
        return MQDeletedMessages.getAllSavedDeletedMessages(postbox: context.account.postbox)
    }

    let signal = combineLatest(dataSignal, searchQueryPromise.get(), context.sharedContext.presentationData)
    |> map { data, searchQuery, presentationData -> (ItemListControllerState, (ItemListNodeState, SavedDeletedListArguments)) in
        let lang = presentationData.strings.baseLanguageCode
        let title = lang == "ru" ? "Корзина" : "Recycle Bin"
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text(title),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)
        )
        let allEntries = savedDeletedListEntries(data: data, lang: lang)
        let entriesWithQuery = allEntries.map { entry -> SavedDeletedListEntry in
            if case .search(let id, _) = entry { return .search(id: id, query: searchQuery) }
            return entry
        }
        let entries = filterSavedDeletedListEntries(entriesWithQuery, by: searchQuery, lang: lang)
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: entries,
            style: .blocks,
            ensureVisibleItemTag: nil,
            initialScrollToItem: nil
        )
        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    presentControllerImpl = { [weak controller] c, a in
        controller?.present(c, in: PresentationContextType.window(PresentationSurfaceLevel.root), with: a)
    }
    pushControllerImpl = { [weak controller] c in
        controller?.navigationController?.pushViewController(c, animated: true)
    }
    return controller
}
