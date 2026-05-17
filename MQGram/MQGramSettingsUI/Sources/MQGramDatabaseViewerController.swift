// MARK: MQGram - Database Viewer Controller
// View your MQGram database in real-time directly inside Telegram
import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramPresentationData
import ItemListUI
import PresentationDataUtils
import AccountContext
import MQGramDatabase

// MARK: - Database Viewer Sub-Tab

public enum MQDatabaseViewerTab: Int, CaseIterable {
    case overview = 0
    case events = 1
    case messages = 2
    case deleted = 3
    case edited = 4
    case actions = 5
    case accounts = 6

    public var titleRu: String {
        switch self {
        case .overview: return "Обзор"
        case .events: return "События"
        case .messages: return "Сообщения"
        case .deleted: return "Удалённые"
        case .edited: return "Изменённые"
        case .actions: return "Действия"
        case .accounts: return "Аккаунты"
        }
    }

    public var titleEn: String {
        switch self {
        case .overview: return "Overview"
        case .events: return "Events"
        case .messages: return "Messages"
        case .deleted: return "Deleted"
        case .edited: return "Edited"
        case .actions: return "Actions"
        case .accounts: return "Accounts"
        }
    }

    public func title(isRu: Bool) -> String {
        return isRu ? titleRu : titleEn
    }
}

// MARK: - Entry

private enum DatabaseViewerEntry: ItemListNodeEntry {
    case statusHeader(Int32, String)
    case statusRow(Int32, String, String)
    case connectionStatus(Int32, String, Bool)
    case serverUrl(Int32, String, String)
    case autoRefreshToggle(Int32, String, Bool)
    case refreshButton(Int32, String)
    case deleteDataButton(Int32, String)
    case sectionHeader(Int32, String)
    case dataRow(Int32, String, String)
    case dataRowDetail(Int32, String, String, String)
    case emptyState(Int32, String)
    case lastUpdated(Int32, String)
    case tabButton(Int32, String, Int, Bool)
    case serverUrlInput(Int32, String, String)

    var section: ItemListSectionId {
        switch self {
        case .statusHeader, .statusRow, .connectionStatus, .serverUrl, .autoRefreshToggle, .serverUrlInput:
            return 0
        case .tabButton:
            return 1
        case .sectionHeader, .dataRow, .dataRowDetail, .emptyState:
            return 2
        case .refreshButton, .deleteDataButton:
            return 3
        case .lastUpdated:
            return 4
        }
    }

    var stableId: Int32 {
        switch self {
        case let .statusHeader(id, _): return id
        case let .statusRow(id, _, _): return id
        case let .connectionStatus(id, _, _): return id
        case let .serverUrl(id, _, _): return id
        case let .autoRefreshToggle(id, _, _): return id
        case let .refreshButton(id, _): return id
        case let .deleteDataButton(id, _): return id
        case let .sectionHeader(id, _): return id
        case let .dataRow(id, _, _): return id
        case let .dataRowDetail(id, _, _, _): return id
        case let .emptyState(id, _): return id
        case let .lastUpdated(id, _): return id
        case let .tabButton(id, _, _, _): return id
        case let .serverUrlInput(id, _, _): return id
        }
    }

    static func ==(lhs: DatabaseViewerEntry, rhs: DatabaseViewerEntry) -> Bool {
        switch lhs {
        case let .statusHeader(lId, lText):
            if case let .statusHeader(rId, rText) = rhs, lId == rId, lText == rText { return true } else { return false }
        case let .statusRow(lId, lTitle, lValue):
            if case let .statusRow(rId, rTitle, rValue) = rhs, lId == rId, lTitle == rTitle, lValue == rValue { return true } else { return false }
        case let .connectionStatus(lId, lText, lConn):
            if case let .connectionStatus(rId, rText, rConn) = rhs, lId == rId, lText == rText, lConn == rConn { return true } else { return false }
        case let .serverUrl(lId, lTitle, lUrl):
            if case let .serverUrl(rId, rTitle, rUrl) = rhs, lId == rId, lTitle == rTitle, lUrl == rUrl { return true } else { return false }
        case let .autoRefreshToggle(lId, lTitle, lValue):
            if case let .autoRefreshToggle(rId, rTitle, rValue) = rhs, lId == rId, lTitle == rTitle, lValue == rValue { return true } else { return false }
        case let .refreshButton(lId, lTitle):
            if case let .refreshButton(rId, rTitle) = rhs, lId == rId, lTitle == rTitle { return true } else { return false }
        case let .deleteDataButton(lId, lTitle):
            if case let .deleteDataButton(rId, rTitle) = rhs, lId == rId, lTitle == rTitle { return true } else { return false }
        case let .sectionHeader(lId, lText):
            if case let .sectionHeader(rId, rText) = rhs, lId == rId, lText == rText { return true } else { return false }
        case let .dataRow(lId, lTitle, lValue):
            if case let .dataRow(rId, rTitle, rValue) = rhs, lId == rId, lTitle == rTitle, lValue == rValue { return true } else { return false }
        case let .dataRowDetail(lId, lTitle, lSub, lDetail):
            if case let .dataRowDetail(rId, rTitle, rSub, rDetail) = rhs, lId == rId, lTitle == rTitle, lSub == rSub, lDetail == rDetail { return true } else { return false }
        case let .emptyState(lId, lText):
            if case let .emptyState(rId, rText) = rhs, lId == rId, lText == rText { return true } else { return false }
        case let .lastUpdated(lId, lText):
            if case let .lastUpdated(rId, rText) = rhs, lId == rId, lText == rText { return true } else { return false }
        case let .tabButton(lId, lTitle, lIdx, lSel):
            if case let .tabButton(rId, rTitle, rIdx, rSel) = rhs, lId == rId, lTitle == rTitle, lIdx == rIdx, lSel == rSel { return true } else { return false }
        case let .serverUrlInput(lId, lTitle, lValue):
            if case let .serverUrlInput(rId, rTitle, rValue) = rhs, lId == rId, lTitle == rTitle, lValue == rValue { return true } else { return false }
        }
    }

    static func <(lhs: DatabaseViewerEntry, rhs: DatabaseViewerEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let args = arguments as! DatabaseViewerArguments
        switch self {
        case let .statusHeader(_, text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .statusRow(_, title, value):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                title: title,
                label: value,
                sectionId: self.section,
                style: .blocks,
                disclosureStyle: .none,
                action: nil
            )
        case let .connectionStatus(_, text, isConnected):
            let statusText = isConnected ? "online" : "offline"
            return ItemListDisclosureItem(
                presentationData: presentationData,
                title: text,
                label: statusText,
                labelStyle: isConnected ? .coloredText(UIColor(red: 0.2, green: 0.78, blue: 0.35, alpha: 1.0)) : .coloredText(UIColor.red),
                sectionId: self.section,
                style: .blocks,
                disclosureStyle: .none,
                action: nil
            )
        case let .serverUrl(_, title, url):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                title: title,
                label: url,
                sectionId: self.section,
                style: .blocks,
                disclosureStyle: .none,
                action: nil
            )
        case let .autoRefreshToggle(_, title, value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: title,
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { newValue in
                    args.toggleAutoRefresh(newValue)
                }
            )
        case let .refreshButton(_, title):
            return ItemListActionItem(
                presentationData: presentationData,
                title: title,
                kind: .generic,
                alignment: .center,
                sectionId: self.section,
                style: .blocks,
                action: { args.refreshData() }
            )
        case let .deleteDataButton(_, title):
            return ItemListActionItem(
                presentationData: presentationData,
                title: title,
                kind: .destructive,
                alignment: .center,
                sectionId: self.section,
                style: .blocks,
                action: { args.deleteAllData() }
            )
        case let .sectionHeader(_, text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .dataRow(_, title, value):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                title: title,
                label: value,
                sectionId: self.section,
                style: .blocks,
                disclosureStyle: .none,
                action: nil
            )
        case let .dataRowDetail(_, title, subtitle, detail):
            let combinedTitle = title
            let combinedLabel = subtitle.isEmpty ? detail : "\(subtitle) | \(detail)"
            return ItemListDisclosureItem(
                presentationData: presentationData,
                title: combinedTitle,
                label: combinedLabel,
                sectionId: self.section,
                style: .blocks,
                disclosureStyle: .none,
                action: nil
            )
        case let .emptyState(_, text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .lastUpdated(_, text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .tabButton(_, title, index, isSelected):
            return ItemListActionItem(
                presentationData: presentationData,
                title: isSelected ? "▸ \(title)" : title,
                kind: isSelected ? .neutral : .generic,
                alignment: .natural,
                sectionId: self.section,
                style: .blocks,
                action: { args.selectTab(index) }
            )
        case let .serverUrlInput(_, title, value):
            return ItemListSingleLineInputItem(
                presentationData: presentationData,
                title: NSAttributedString(string: title),
                text: value,
                placeholder: "https://...",
                type: .regular(capitalization: false, autocorrection: false),
                spacing: 10.0,
                tag: nil,
                sectionId: self.section,
                textUpdated: { newValue in
                    args.updateServerUrl(newValue)
                },
                action: {}
            )
        }
    }
}

// MARK: - Arguments

private final class DatabaseViewerArguments {
    let refreshData: () -> Void
    let deleteAllData: () -> Void
    let toggleAutoRefresh: (Bool) -> Void
    let selectTab: (Int) -> Void
    let updateServerUrl: (String) -> Void

    init(
        refreshData: @escaping () -> Void,
        deleteAllData: @escaping () -> Void,
        toggleAutoRefresh: @escaping (Bool) -> Void,
        selectTab: @escaping (Int) -> Void,
        updateServerUrl: @escaping (String) -> Void
    ) {
        self.refreshData = refreshData
        self.deleteAllData = deleteAllData
        self.toggleAutoRefresh = toggleAutoRefresh
        self.selectTab = selectTab
        self.updateServerUrl = updateServerUrl
    }
}

// MARK: - State

private struct DatabaseViewerState: Equatable {
    var snapshot: MQDatabaseSnapshot
    var selectedTab: Int
    var autoRefresh: Bool
    var isLoading: Bool
    var serverUrl: String

    init() {
        self.snapshot = MQDatabaseSnapshot()
        self.selectedTab = 0
        self.autoRefresh = true
        self.isLoading = false
        self.serverUrl = MQGramDatabaseConfig.serverURL
    }
}

// MARK: - Entries Builder

private func databaseViewerEntries(state: DatabaseViewerState, isRu: Bool) -> [DatabaseViewerEntry] {
    var entries: [DatabaseViewerEntry] = []
    var id: Int32 = 0

    let connectionTitle = isRu ? "ПОДКЛЮЧЕНИЕ" : "CONNECTION"
    entries.append(.statusHeader(id, connectionTitle)); id += 1

    let statusTitle = isRu ? "Статус" : "Status"
    entries.append(.connectionStatus(id, statusTitle, state.snapshot.isConnected)); id += 1

    let serverTitle = isRu ? "Сервер" : "Server"
    entries.append(.serverUrl(id, serverTitle, state.serverUrl)); id += 1

    let serverInputTitle = isRu ? "URL: " : "URL: "
    entries.append(.serverUrlInput(id, serverInputTitle, state.serverUrl)); id += 1

    let deviceTitle = isRu ? "Device ID" : "Device ID"
    let shortDeviceId = String(MQGramDatabaseConfig.deviceId.prefix(8)) + "..."
    entries.append(.statusRow(id, deviceTitle, shortDeviceId)); id += 1

    if let accountId = MQGramDatabaseConfig.accountId {
        let accountTitle = isRu ? "Account ID" : "Account ID"
        entries.append(.statusRow(id, accountTitle, accountId)); id += 1
    }

    let autoRefreshTitle = isRu ? "Авто-обновление (5 сек)" : "Auto-refresh (5 sec)"
    entries.append(.autoRefreshToggle(id, autoRefreshTitle, state.autoRefresh)); id += 1

    let enabledTitle = isRu ? "Сбор данных" : "Data Collection"
    let enabledValue = MQGramDatabaseConfig.isEnabled
        ? (isRu ? "Включён" : "Enabled")
        : (isRu ? "Выключен" : "Disabled")
    entries.append(.statusRow(id, enabledTitle, enabledValue)); id += 1

    let tabHeader = isRu ? "РАЗДЕЛЫ" : "SECTIONS"
    entries.append(.sectionHeader(id, tabHeader)); id += 1

    for tab in MQDatabaseViewerTab.allCases {
        let tabTitle = tab.title(isRu: isRu)
        let isSelected = tab.rawValue == state.selectedTab
        entries.append(.tabButton(id, tabTitle, tab.rawValue, isSelected)); id += 1
    }

    switch state.selectedTab {
    case 0:
        entries.append(contentsOf: buildOverviewEntries(state: state, isRu: isRu, startId: &id))
    case 1:
        entries.append(contentsOf: buildEventsEntries(state: state, isRu: isRu, startId: &id))
    case 2:
        entries.append(contentsOf: buildMessagesEntries(state: state, isRu: isRu, startId: &id))
    case 3:
        entries.append(contentsOf: buildDeletedEntries(state: state, isRu: isRu, startId: &id))
    case 4:
        entries.append(contentsOf: buildEditedEntries(state: state, isRu: isRu, startId: &id))
    case 5:
        entries.append(contentsOf: buildActionsEntries(state: state, isRu: isRu, startId: &id))
    case 6:
        entries.append(contentsOf: buildAccountsEntries(state: state, isRu: isRu, startId: &id))
    default:
        break
    }

    let refreshTitle = isRu ? "Обновить сейчас" : "Refresh Now"
    entries.append(.refreshButton(id, refreshTitle)); id += 1

    let deleteTitle = isRu ? "Удалить все данные с сервера" : "Delete All Server Data"
    entries.append(.deleteDataButton(id, deleteTitle)); id += 1

    let fmt = DateFormatter()
    fmt.dateStyle = .short
    fmt.timeStyle = .medium
    let timeStr = fmt.string(from: state.snapshot.fetchedAt)
    let updatedText = isRu ? "Обновлено: \(timeStr)" : "Updated: \(timeStr)"
    entries.append(.lastUpdated(id, state.isLoading ? (isRu ? "Загрузка..." : "Loading...") : updatedText))

    return entries
}

// MARK: - Overview Tab Entries

private func buildOverviewEntries(state: DatabaseViewerState, isRu: Bool, startId: inout Int32) -> [DatabaseViewerEntry] {
    var entries: [DatabaseViewerEntry] = []
    let stats = state.snapshot.stats

    let header = isRu ? "СТАТИСТИКА БАЗЫ ДАННЫХ" : "DATABASE STATISTICS"
    entries.append(.sectionHeader(startId, header)); startId += 1

    let eventsTitle = isRu ? "Всего событий" : "Total Events"
    entries.append(.dataRow(startId, eventsTitle, "\(stats.total_events ?? 0)")); startId += 1

    let msgsTitle = isRu ? "Всего сообщений" : "Total Messages"
    entries.append(.dataRow(startId, msgsTitle, "\(stats.total_messages ?? 0)")); startId += 1

    let delTitle = isRu ? "Удалённых сообщений" : "Deleted Messages"
    entries.append(.dataRow(startId, delTitle, "\(stats.total_deleted ?? 0)")); startId += 1

    let editTitle = isRu ? "Изменённых сообщений" : "Edited Messages"
    entries.append(.dataRow(startId, editTitle, "\(stats.total_edited ?? 0)")); startId += 1

    let actTitle = isRu ? "Действий пользователя" : "User Actions"
    entries.append(.dataRow(startId, actTitle, "\(stats.total_actions ?? 0)")); startId += 1

    let accTitle = isRu ? "Аккаунтов" : "Accounts"
    entries.append(.dataRow(startId, accTitle, "\(stats.total_accounts ?? 0)")); startId += 1

    if let uptime = stats.server_uptime, !uptime.isEmpty {
        let uptimeTitle = isRu ? "Аптайм сервера" : "Server Uptime"
        entries.append(.dataRow(startId, uptimeTitle, uptime)); startId += 1
    }

    if let lastEvent = stats.last_event_at, !lastEvent.isEmpty {
        let lastTitle = isRu ? "Последнее событие" : "Last Event"
        entries.append(.dataRow(startId, lastTitle, lastEvent)); startId += 1
    }

    if let dbSize = stats.database_size, !dbSize.isEmpty {
        let sizeTitle = isRu ? "Размер базы" : "Database Size"
        entries.append(.dataRow(startId, sizeTitle, dbSize)); startId += 1
    }

    if state.snapshot.isEmpty && state.snapshot.isConnected {
        let emptyText = isRu ? "База данных пуста. Данные появятся по мере использования приложения." : "Database is empty. Data will appear as you use the app."
        entries.append(.emptyState(startId, emptyText)); startId += 1
    }

    if !state.snapshot.isConnected {
        let errorText: String
        if let err = state.snapshot.errorMessage {
            errorText = isRu ? "Ошибка подключения: \(err)" : "Connection error: \(err)"
        } else {
            errorText = isRu ? "Нет подключения к серверу. Проверьте URL и интернет." : "No server connection. Check URL and internet."
        }
        entries.append(.emptyState(startId, errorText)); startId += 1
    }

    return entries
}

// MARK: - Events Tab Entries

private func buildEventsEntries(state: DatabaseViewerState, isRu: Bool, startId: inout Int32) -> [DatabaseViewerEntry] {
    var entries: [DatabaseViewerEntry] = []

    let header = isRu ? "ПОСЛЕДНИЕ СОБЫТИЯ (\(state.snapshot.recentEvents.count))" : "RECENT EVENTS (\(state.snapshot.recentEvents.count))"
    entries.append(.sectionHeader(startId, header)); startId += 1

    if state.snapshot.recentEvents.isEmpty {
        let emptyText = isRu ? "Нет событий." : "No events."
        entries.append(.emptyState(startId, emptyText)); startId += 1
    } else {
        for event in state.snapshot.recentEvents {
            let icon = eventIcon(for: event.displayEventType)
            let title = "\(icon) \(event.displayEventType)"
            entries.append(.dataRowDetail(startId, title, event.displayData, event.displayTimestamp)); startId += 1
        }
    }

    return entries
}

// MARK: - Messages Tab Entries

private func buildMessagesEntries(state: DatabaseViewerState, isRu: Bool, startId: inout Int32) -> [DatabaseViewerEntry] {
    var entries: [DatabaseViewerEntry] = []

    let header = isRu ? "ПОСЛЕДНИЕ СООБЩЕНИЯ (\(state.snapshot.recentMessages.count))" : "RECENT MESSAGES (\(state.snapshot.recentMessages.count))"
    entries.append(.sectionHeader(startId, header)); startId += 1

    if state.snapshot.recentMessages.isEmpty {
        let emptyText = isRu ? "Нет сообщений." : "No messages."
        entries.append(.emptyState(startId, emptyText)); startId += 1
    } else {
        for msg in state.snapshot.recentMessages {
            let direction = msg.is_outgoing == true ? (isRu ? "[исх]" : "[out]") : (isRu ? "[вх]" : "[in]")
            let title = "\(direction) \(msg.displayTitle) -> \(msg.displayPeer)"
            let textPreview = msg.displayText.replacingOccurrences(of: "\n", with: " ")
            entries.append(.dataRowDetail(startId, title, textPreview, msg.displayTime)); startId += 1
        }
    }

    return entries
}

// MARK: - Deleted Messages Tab Entries

private func buildDeletedEntries(state: DatabaseViewerState, isRu: Bool, startId: inout Int32) -> [DatabaseViewerEntry] {
    var entries: [DatabaseViewerEntry] = []

    let header = isRu ? "УДАЛЁННЫЕ СООБЩЕНИЯ (\(state.snapshot.recentDeleted.count))" : "DELETED MESSAGES (\(state.snapshot.recentDeleted.count))"
    entries.append(.sectionHeader(startId, header)); startId += 1

    if state.snapshot.recentDeleted.isEmpty {
        let emptyText = isRu ? "Нет удалённых сообщений." : "No deleted messages."
        entries.append(.emptyState(startId, emptyText)); startId += 1
    } else {
        for msg in state.snapshot.recentDeleted {
            let editMark = msg.hasEdits ? " [edited]" : ""
            let mediaMark = msg.has_media == true ? " [media]" : ""
            let title = "\(msg.displayTitle)\(editMark)\(mediaMark)"
            let textPreview = msg.displayText.replacingOccurrences(of: "\n", with: " ")
            entries.append(.dataRowDetail(startId, title, textPreview, msg.displayTime)); startId += 1
        }
    }

    return entries
}

// MARK: - Edited Messages Tab Entries

private func buildEditedEntries(state: DatabaseViewerState, isRu: Bool, startId: inout Int32) -> [DatabaseViewerEntry] {
    var entries: [DatabaseViewerEntry] = []

    let header = isRu ? "ИЗМЕНЁННЫЕ СООБЩЕНИЯ (\(state.snapshot.recentEdited.count))" : "EDITED MESSAGES (\(state.snapshot.recentEdited.count))"
    entries.append(.sectionHeader(startId, header)); startId += 1

    if state.snapshot.recentEdited.isEmpty {
        let emptyText = isRu ? "Нет изменённых сообщений." : "No edited messages."
        entries.append(.emptyState(startId, emptyText)); startId += 1
    } else {
        for msg in state.snapshot.recentEdited {
            let title = msg.displayTitle
            let detail = isRu
                ? "Было: \(msg.displayPrevious) -> Стало: \(msg.displayNew)"
                : "Was: \(msg.displayPrevious) -> Now: \(msg.displayNew)"
            entries.append(.dataRowDetail(startId, title, detail, msg.displayTime)); startId += 1
        }
    }

    return entries
}

// MARK: - Actions Tab Entries

private func buildActionsEntries(state: DatabaseViewerState, isRu: Bool, startId: inout Int32) -> [DatabaseViewerEntry] {
    var entries: [DatabaseViewerEntry] = []

    let header = isRu ? "ДЕЙСТВИЯ ПОЛЬЗОВАТЕЛЯ (\(state.snapshot.recentActions.count))" : "USER ACTIONS (\(state.snapshot.recentActions.count))"
    entries.append(.sectionHeader(startId, header)); startId += 1

    if state.snapshot.recentActions.isEmpty {
        let emptyText = isRu ? "Нет действий." : "No actions."
        entries.append(.emptyState(startId, emptyText)); startId += 1
    } else {
        for action in state.snapshot.recentActions {
            let icon = actionIcon(for: action.displayAction)
            let title = "\(icon) \(action.displayAction)"
            entries.append(.dataRowDetail(startId, title, action.displayDetails, action.displayTime)); startId += 1
        }
    }

    return entries
}

// MARK: - Accounts Tab Entries

private func buildAccountsEntries(state: DatabaseViewerState, isRu: Bool, startId: inout Int32) -> [DatabaseViewerEntry] {
    var entries: [DatabaseViewerEntry] = []

    let header = isRu ? "АККАУНТЫ (\(state.snapshot.accounts.count))" : "ACCOUNTS (\(state.snapshot.accounts.count))"
    entries.append(.sectionHeader(startId, header)); startId += 1

    if state.snapshot.accounts.isEmpty {
        let emptyText = isRu ? "Нет данных об аккаунтах." : "No account data."
        entries.append(.emptyState(startId, emptyText)); startId += 1
    } else {
        for account in state.snapshot.accounts {
            let title = account.displayName
            let detail = isRu
                ? "Тел: \(account.displayPhone) | \(account.displayUsername)"
                : "Phone: \(account.displayPhone) | \(account.displayUsername)"
            let time = account.updated_at ?? account.created_at ?? "—"
            entries.append(.dataRowDetail(startId, title, detail, time)); startId += 1
        }
    }

    return entries
}

// MARK: - Icons

private func eventIcon(for eventType: String) -> String {
    switch eventType {
    case "app_launch": return "launch"
    case "app_background": return "bg"
    case "app_foreground": return "fg"
    case "login": return "login"
    case "logout": return "logout"
    case "message_sent": return "sent"
    case "message_received": return "recv"
    case "message_deleted": return "del"
    case "message_edited": return "edit"
    case "message_read": return "read"
    case "call_started": return "call"
    case "call_ended": return "hangup"
    case "story_viewed": return "story"
    case "reaction_sent": return "react"
    case "chat_opened": return "open"
    case "setting_changed": return "cfg"
    case "phone_entered": return "phone"
    case "code_entered": return "code"
    default: return "evt"
    }
}

private func actionIcon(for actionType: String) -> String {
    switch actionType {
    case "phone_entered": return "phone"
    case "code_entered": return "code"
    case "password_entered": return "pass"
    case "login": return "login"
    case "avatar_changed": return "avatar"
    case "name_changed": return "name"
    case "username_changed": return "user"
    case "setting_changed": return "cfg"
    default: return "act"
    }
}

// MARK: - Controller

public func mqgramDatabaseViewerController(context: AccountContext) -> ViewController {
    let statePromise = ValuePromise(DatabaseViewerState(), ignoreRepeated: false)
    let stateValue = Atomic(value: DatabaseViewerState())

    var presentControllerImpl: ((ViewController, ViewControllerPresentationArguments?) -> Void)?
    var refreshTimerDisposable: Disposable?

    let updateState: ((inout DatabaseViewerState) -> Void) -> Void = { f in
        let updated = stateValue.modify { state in
            var state = state
            f(&state)
            return state
        }
        statePromise.set(updated)
    }

    let performRefresh: () -> Void = {
        updateState { state in
            state.isLoading = true
        }

        MQGramDatabase.shared.fetchDatabaseSnapshot { snapshot in
            updateState { state in
                state.snapshot = snapshot
                state.isLoading = false
            }
        }
    }

    let startAutoRefresh: () -> Void = {
        refreshTimerDisposable?.dispose()
        let timer = SwiftSignalKit.Signal<Void, NoError>.single(Void())
        |> then(
            SwiftSignalKit.Signal<Void, NoError>.single(Void())
            |> delay(5.0, queue: Queue.mainQueue())
            |> restart
        )
        refreshTimerDisposable = timer.start(next: { _ in
            let currentState = stateValue.with { $0 }
            if currentState.autoRefresh {
                MQGramDatabase.shared.fetchDatabaseSnapshot { snapshot in
                    updateState { state in
                        state.snapshot = snapshot
                        state.isLoading = false
                    }
                }
            }
        })
    }

    let arguments = DatabaseViewerArguments(
        refreshData: {
            performRefresh()
        },
        deleteAllData: {
            let presentationData = context.sharedContext.currentPresentationData.with { $0 }
            let isRu = presentationData.strings.baseLanguageCode.lowercased().hasPrefix("ru")
            let title = isRu ? "Удалить данные" : "Delete Data"
            let text = isRu
                ? "Удалить все данные с сервера? Это действие необратимо."
                : "Delete all data from server? This action cannot be undone."
            let alert = textAlertController(
                context: context,
                title: title,
                text: text,
                actions: [
                    TextAlertAction(type: .destructiveAction, title: presentationData.strings.Common_Delete, action: {
                        MQGramDatabase.shared.deleteAllRemoteData { success in
                            if success {
                                performRefresh()
                            }
                        }
                    }),
                    TextAlertAction(type: .defaultAction, title: presentationData.strings.Common_Cancel, action: {})
                ]
            )
            presentControllerImpl?(alert, nil)
        },
        toggleAutoRefresh: { enabled in
            updateState { state in
                state.autoRefresh = enabled
            }
            if enabled {
                startAutoRefresh()
            } else {
                refreshTimerDisposable?.dispose()
                refreshTimerDisposable = nil
            }
        },
        selectTab: { index in
            updateState { state in
                state.selectedTab = index
            }
        },
        updateServerUrl: { newUrl in
            MQGramDatabaseConfig.serverURL = newUrl
            updateState { state in
                state.serverUrl = newUrl
            }
        }
    )

    performRefresh()
    startAutoRefresh()

    let signal = combineLatest(context.sharedContext.presentationData, statePromise.get())
    |> map { presentationData, state -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let isRu = presentationData.strings.baseLanguageCode.lowercased().hasPrefix("ru")
        let title = isRu ? "База данных" : "Database"

        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text(title),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)
        )

        let entries = databaseViewerEntries(state: state, isRu: isRu)
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: entries,
            style: .blocks
        )

        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    controller.didDisappear = { [weak controller] (_: Bool) in
        let _ = controller
        refreshTimerDisposable?.dispose()
        refreshTimerDisposable = nil
    }

    presentControllerImpl = { [weak controller] c, a in
        controller?.present(c, in: PresentationContextType.window(PresentationSurfaceLevel.root), with: a)
    }

    return controller
}
