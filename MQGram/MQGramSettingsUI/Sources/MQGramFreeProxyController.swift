// MARK: MQGram - Free Proxy
import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramPresentationData
import ItemListUI
import PresentationDataUtils
import AccountContext
import TelegramCore

private struct FreeProxyState: Equatable {
    var proxies: [MQGramProxyServer]
    var connectingId: String?
    var connectedId: String?
    var isLoading: Bool
    var isAdmin: Bool
    var isConfigured: Bool

    init(userId: Int64 = 0) {
        self.proxies = []
        self.connectingId = nil
        self.connectedId = nil
        self.isLoading = true
        self.isAdmin = MQGramProxyAPI.isAdmin(userId: userId)
        self.isConfigured = MQGramProxyAPI.isConfigured
    }
}

private final class MQGramFreeProxyArguments {
    let connectProxy: (MQGramProxyServer) -> Void
    let deleteProxy: (MQGramProxyServer) -> Void
    let addProxy: () -> Void
    let configureAPI: () -> Void

    init(connectProxy: @escaping (MQGramProxyServer) -> Void, deleteProxy: @escaping (MQGramProxyServer) -> Void, addProxy: @escaping () -> Void, configureAPI: @escaping () -> Void) {
        self.connectProxy = connectProxy
        self.deleteProxy = deleteProxy
        self.addProxy = addProxy
        self.configureAPI = configureAPI
    }
}

private enum MQGramFreeProxySection: Int32 {
    case info
    case proxy
    case admin
    case setup
    case footer
}

private enum MQGramFreeProxyEntryId: Hashable {
    case headerInfo
    case proxyHeader
    case proxy(String)
    case loading
    case empty
    case addProxy
    case adminHeader
    case setupHeader
    case configureAPI
    case footer
}

private enum MQGramFreeProxyEntry: ItemListNodeEntry {
    case headerInfo(String)
    case proxyHeader(String)
    case proxyItem(Int32, MQGramProxyServer, String?, String?)
    case loading(Int32)
    case empty(Int32, String)
    case adminHeader(String)
    case addProxy(Int32)
    case setupHeader(String)
    case configureAPI(Int32)
    case footer(String)

    var section: ItemListSectionId {
        switch self {
        case .headerInfo:
            return MQGramFreeProxySection.info.rawValue
        case .proxyHeader, .proxyItem, .loading, .empty:
            return MQGramFreeProxySection.proxy.rawValue
        case .adminHeader, .addProxy:
            return MQGramFreeProxySection.admin.rawValue
        case .setupHeader, .configureAPI:
            return MQGramFreeProxySection.setup.rawValue
        case .footer:
            return MQGramFreeProxySection.footer.rawValue
        }
    }

    var stableId: MQGramFreeProxyEntryId {
        switch self {
        case .headerInfo:
            return .headerInfo
        case .proxyHeader:
            return .proxyHeader
        case let .proxyItem(_, proxy, _, _):
            return .proxy(proxy.id)
        case .loading:
            return .loading
        case .empty:
            return .empty
        case .adminHeader:
            return .adminHeader
        case .addProxy:
            return .addProxy
        case .setupHeader:
            return .setupHeader
        case .configureAPI:
            return .configureAPI
        case .footer:
            return .footer
        }
    }

    static func ==(lhs: MQGramFreeProxyEntry, rhs: MQGramFreeProxyEntry) -> Bool {
        switch lhs {
        case let .headerInfo(lText):
            if case let .headerInfo(rText) = rhs, lText == rText { return true } else { return false }
        case let .proxyHeader(lText):
            if case let .proxyHeader(rText) = rhs, lText == rText { return true } else { return false }
        case let .proxyItem(lIdx, lProxy, lConnecting, lConnected):
            if case let .proxyItem(rIdx, rProxy, rConnecting, rConnected) = rhs,
               lIdx == rIdx, lProxy == rProxy, lConnecting == rConnecting, lConnected == rConnected {
                return true
            }
            return false
        case let .loading(lIdx):
            if case let .loading(rIdx) = rhs, lIdx == rIdx { return true } else { return false }
        case let .empty(lIdx, lText):
            if case let .empty(rIdx, rText) = rhs, lIdx == rIdx, lText == rText { return true } else { return false }
        case let .adminHeader(lText):
            if case let .adminHeader(rText) = rhs, lText == rText { return true } else { return false }
        case let .addProxy(lIdx):
            if case let .addProxy(rIdx) = rhs, lIdx == rIdx { return true } else { return false }
        case let .setupHeader(lText):
            if case let .setupHeader(rText) = rhs, lText == rText { return true } else { return false }
        case let .configureAPI(lIdx):
            if case let .configureAPI(rIdx) = rhs, lIdx == rIdx { return true } else { return false }
        case let .footer(lText):
            if case let .footer(rText) = rhs, lText == rText { return true } else { return false }
        }
    }

    static func <(lhs: MQGramFreeProxyEntry, rhs: MQGramFreeProxyEntry) -> Bool {
        return lhs.sortIndex < rhs.sortIndex
    }

    var sortIndex: Int32 {
        switch self {
        case .headerInfo: return 0
        case .proxyHeader: return 1
        case let .proxyItem(idx, _, _, _): return 10 + idx
        case .loading: return 5
        case .empty: return 5
        case .setupHeader: return 500
        case .configureAPI: return 501
        case .adminHeader: return 1000
        case .addProxy: return 1001
        case .footer: return 9999
        }
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let args = arguments as! MQGramFreeProxyArguments
        switch self {
        case let .headerInfo(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .proxyHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .proxyItem(_, proxy, connectingId, connectedId):
            let label: String
            let style: ItemListDisclosureStyle
            if connectedId == proxy.id {
                label = "✓ Подключено"
                style = .none
            } else if connectingId == proxy.id {
                label = "Подключение..."
                style = .none
            } else {
                label = "Подключиться"
                style = .arrow
            }
            return ItemListDisclosureItem(
                presentationData: presentationData,
                title: proxy.name,
                label: label,
                sectionId: self.section,
                style: .blocks,
                disclosureStyle: style,
                action: {
                    args.connectProxy(proxy)
                }
            )
        case .loading:
            return ItemListTextItem(presentationData: presentationData, text: .plain("Загрузка..."), sectionId: self.section)
        case let .empty(_, text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .adminHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case .addProxy:
            return ItemListDisclosureItem(
                presentationData: presentationData,
                title: "Добавить прокси",
                titleColor: .accent,
                label: "",
                sectionId: self.section,
                style: .blocks,
                disclosureStyle: .arrow,
                action: {
                    args.addProxy()
                }
            )
        case let .setupHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case .configureAPI:
            return ItemListDisclosureItem(
                presentationData: presentationData,
                title: "Настроить API сервер",
                titleColor: .accent,
                label: "",
                sectionId: self.section,
                style: .blocks,
                disclosureStyle: .arrow,
                action: {
                    args.configureAPI()
                }
            )
        case let .footer(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        }
    }
}

private func mqgramFreeProxyEntries(state: FreeProxyState) -> [MQGramFreeProxyEntry] {
    var entries: [MQGramFreeProxyEntry] = []

    entries.append(.headerInfo("Бесплатные прокси-серверы для обхода блокировок. Нажмите на сервер чтобы подключиться."))
    entries.append(.proxyHeader("ПРОКСИ-СЕРВЕРЫ"))

    if state.isLoading {
        entries.append(.loading(0))
    } else if state.proxies.isEmpty {
        entries.append(.empty(0, "Нет доступных прокси-серверов."))
    } else {
        for (index, proxy) in state.proxies.enumerated() {
            entries.append(.proxyItem(Int32(index), proxy, state.connectingId, state.connectedId))
        }
    }

    if state.isAdmin {
        entries.append(.adminHeader("АДМИНИСТРАТОР"))
        entries.append(.addProxy(0))
    }

    if !state.isConfigured || state.isAdmin {
        entries.append(.setupHeader("НАСТРОЙКИ"))
        entries.append(.configureAPI(0))
    }

    entries.append(.footer("Прокси подключается через MTProto и не требует установки дополнительных приложений. Весь трафик шифруется."))

    return entries
}

public func mqgramFreeProxyController(context: AccountContext) -> ViewController {
    let userId = context.account.peerId.id._internalGetInt64Value()
    let statePromise = ValuePromise<FreeProxyState>(FreeProxyState(userId: userId), ignoreRepeated: true)
    var state = FreeProxyState(userId: userId)

    func updateState(_ f: (inout FreeProxyState) -> Void) {
        f(&state)
        statePromise.set(state)
    }

    func loadProxies() {
        updateState { $0.isLoading = true }
        MQGramProxyAPI.shared.fetchProxies { proxies in
            updateState {
                $0.proxies = proxies
                $0.isLoading = false
                $0.isConfigured = MQGramProxyAPI.isConfigured
                $0.isAdmin = MQGramProxyAPI.isAdmin(userId: userId)
            }
        }
    }

    var _presentControllerImpl: ((ViewController, Any?) -> Void)?
    var pushControllerImpl: ((ViewController) -> Void)?

    let arguments = MQGramFreeProxyArguments(
        connectProxy: { proxy in
            updateState { $0.connectingId = proxy.id }

            let proxyUrl = "https://t.me/proxy?server=\(proxy.server)&port=\(proxy.port)&secret=\(proxy.secret)"
            context.sharedContext.openExternalUrl(context: context, urlContext: .generic, url: proxyUrl, forceExternal: false, presentationData: context.sharedContext.currentPresentationData.with { $0 }, navigationController: context.sharedContext.mainWindow?.viewController as? NavigationController, dismissInput: {})

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                updateState {
                    $0.connectedId = proxy.id
                    $0.connectingId = nil
                }
            }
        },
        deleteProxy: { proxy in
            MQGramProxyAPI.shared.deleteProxy(id: proxy.id) { success in
                if success {
                    loadProxies()
                }
            }
        },
        addProxy: {
            let presentationData = context.sharedContext.currentPresentationData.with { $0 }
            let controller = mqgramAddProxyController(context: context, presentationData: presentationData) {
                loadProxies()
            }
            pushControllerImpl?(controller)
        },
        configureAPI: {
            let presentationData = context.sharedContext.currentPresentationData.with { $0 }
            let controller = mqgramConfigureAPIController(context: context, presentationData: presentationData) {
                updateState {
                    $0.isConfigured = MQGramProxyAPI.isConfigured
                    $0.isAdmin = MQGramProxyAPI.isAdmin(userId: userId)
                }
                loadProxies()
            }
            pushControllerImpl?(controller)
        }
    )

    let signal = combineLatest(context.sharedContext.presentationData, statePromise.get())
    |> map { presentationData, proxyState -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text("Free Proxy"),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)
        )

        let entries = mqgramFreeProxyEntries(state: proxyState)

        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: entries,
            style: .blocks
        )

        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    _presentControllerImpl = { [weak controller] c, a in
        controller?.present(c, in: .window(.root), with: a as? ViewControllerPresentationArguments)
    }
    pushControllerImpl = { [weak controller] c in
        controller?.push(c)
    }

    loadProxies()

    return controller
}

// MARK: - Add Proxy Controller

private enum AddProxySection: Int32 {
    case fields
}

private enum AddProxyEntryId: Hashable {
    case nameField
    case serverField
    case portField
    case secretField
}

private struct AddProxyFormState: Equatable {
    var name: String = ""
    var server: String = ""
    var port: String = ""
    var secret: String = ""
}

private enum AddProxyEntry: ItemListNodeEntry {
    case nameField(String, String)
    case serverField(String, String)
    case portField(String, String)
    case secretField(String, String)

    var section: ItemListSectionId {
        return AddProxySection.fields.rawValue
    }

    var stableId: AddProxyEntryId {
        switch self {
        case .nameField: return .nameField
        case .serverField: return .serverField
        case .portField: return .portField
        case .secretField: return .secretField
        }
    }

    static func ==(lhs: AddProxyEntry, rhs: AddProxyEntry) -> Bool {
        switch lhs {
        case let .nameField(lTitle, lValue):
            if case let .nameField(rTitle, rValue) = rhs, lTitle == rTitle, lValue == rValue { return true } else { return false }
        case let .serverField(lTitle, lValue):
            if case let .serverField(rTitle, rValue) = rhs, lTitle == rTitle, lValue == rValue { return true } else { return false }
        case let .portField(lTitle, lValue):
            if case let .portField(rTitle, rValue) = rhs, lTitle == rTitle, lValue == rValue { return true } else { return false }
        case let .secretField(lTitle, lValue):
            if case let .secretField(rTitle, rValue) = rhs, lTitle == rTitle, lValue == rValue { return true } else { return false }
        }
    }

    static func <(lhs: AddProxyEntry, rhs: AddProxyEntry) -> Bool {
        return lhs.sortIndex < rhs.sortIndex
    }

    var sortIndex: Int32 {
        switch self {
        case .nameField: return 0
        case .serverField: return 1
        case .portField: return 2
        case .secretField: return 3
        }
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let args = arguments as! AddProxyArguments
        switch self {
        case let .nameField(title, value):
            return ItemListSingleLineInputItem(presentationData: presentationData, title: NSAttributedString(string: title), text: value, placeholder: "🇷🇺 Россия", sectionId: self.section, textUpdated: { text in
                args.updateName(text)
            }, action: {})
        case let .serverField(title, value):
            return ItemListSingleLineInputItem(presentationData: presentationData, title: NSAttributedString(string: title), text: value, placeholder: "proxy.example.com", sectionId: self.section, textUpdated: { text in
                args.updateServer(text)
            }, action: {})
        case let .portField(title, value):
            return ItemListSingleLineInputItem(presentationData: presentationData, title: NSAttributedString(string: title), text: value, placeholder: "443", sectionId: self.section, textUpdated: { text in
                args.updatePort(text)
            }, action: {})
        case let .secretField(title, value):
            return ItemListSingleLineInputItem(presentationData: presentationData, title: NSAttributedString(string: title), text: value, placeholder: "secret hex", sectionId: self.section, textUpdated: { text in
                args.updateSecret(text)
            }, action: {})
        }
    }
}

private final class AddProxyArguments {
    let updateName: (String) -> Void
    let updateServer: (String) -> Void
    let updatePort: (String) -> Void
    let updateSecret: (String) -> Void

    init(updateName: @escaping (String) -> Void, updateServer: @escaping (String) -> Void, updatePort: @escaping (String) -> Void, updateSecret: @escaping (String) -> Void) {
        self.updateName = updateName
        self.updateServer = updateServer
        self.updatePort = updatePort
        self.updateSecret = updateSecret
    }
}

private func addProxyEntries(state: AddProxyFormState) -> [AddProxyEntry] {
    return [
        .nameField("Имя: ", state.name),
        .serverField("Сервер: ", state.server),
        .portField("Порт: ", state.port),
        .secretField("Секрет: ", state.secret),
    ]
}

func mqgramAddProxyController(context: AccountContext, presentationData: PresentationData, completion: @escaping () -> Void) -> ViewController {
    let formState = ValuePromise<AddProxyFormState>(AddProxyFormState(), ignoreRepeated: true)
    var currentFormState = AddProxyFormState()

    func updateForm(_ f: (inout AddProxyFormState) -> Void) {
        f(&currentFormState)
        formState.set(currentFormState)
    }

    let arguments = AddProxyArguments(
        updateName: { text in updateForm { $0.name = text } },
        updateServer: { text in updateForm { $0.server = text } },
        updatePort: { text in updateForm { $0.port = text } },
        updateSecret: { text in updateForm { $0.secret = text } }
    )

    var dismissImpl: (() -> Void)?

    let signal = combineLatest(context.sharedContext.presentationData, formState.get())
    |> map { presentationData, form -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let rightButton = ItemListNavigationButton(content: .text("Сохранить"), style: .bold, enabled: !form.name.isEmpty && !form.server.isEmpty && !form.port.isEmpty && !form.secret.isEmpty, action: {
            guard let port = Int(currentFormState.port) else { return }
            MQGramProxyAPI.shared.addProxy(name: currentFormState.name, server: currentFormState.server, port: port, secret: currentFormState.secret) { proxy in
                if proxy != nil {
                    completion()
                    dismissImpl?()
                }
            }
        })

        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text("Добавить прокси"),
            leftNavigationButton: nil,
            rightNavigationButton: rightButton,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)
        )

        let entries = addProxyEntries(state: form)

        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: entries,
            style: .blocks
        )

        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    dismissImpl = { [weak controller] in
        controller?.navigationController?.popViewController(animated: true)
    }
    return controller
}

// MARK: - Configure API Controller

private enum ConfigureAPISection: Int32 {
    case fields
    case info
}

private enum ConfigureAPIEntryId: Hashable {
    case urlField
    case tokenField
    case info
}

private struct ConfigureAPIFormState: Equatable {
    var baseURL: String
    var adminToken: String

    init() {
        self.baseURL = UserDefaults.standard.string(forKey: "MQGram.proxyAPIBaseURL") ?? ""
        self.adminToken = UserDefaults.standard.string(forKey: "MQGram.proxyAdminToken") ?? ""
    }
}

private enum ConfigureAPIEntry: ItemListNodeEntry {
    case urlField(String, String)
    case tokenField(String, String)
    case info(String)

    var section: ItemListSectionId {
        switch self {
        case .urlField, .tokenField:
            return ConfigureAPISection.fields.rawValue
        case .info:
            return ConfigureAPISection.info.rawValue
        }
    }

    var stableId: ConfigureAPIEntryId {
        switch self {
        case .urlField: return .urlField
        case .tokenField: return .tokenField
        case .info: return .info
        }
    }

    static func ==(lhs: ConfigureAPIEntry, rhs: ConfigureAPIEntry) -> Bool {
        switch lhs {
        case let .urlField(lTitle, lValue):
            if case let .urlField(rTitle, rValue) = rhs, lTitle == rTitle, lValue == rValue { return true } else { return false }
        case let .tokenField(lTitle, lValue):
            if case let .tokenField(rTitle, rValue) = rhs, lTitle == rTitle, lValue == rValue { return true } else { return false }
        case let .info(lText):
            if case let .info(rText) = rhs, lText == rText { return true } else { return false }
        }
    }

    static func <(lhs: ConfigureAPIEntry, rhs: ConfigureAPIEntry) -> Bool {
        return lhs.sortIndex < rhs.sortIndex
    }

    var sortIndex: Int32 {
        switch self {
        case .urlField: return 0
        case .tokenField: return 1
        case .info: return 100
        }
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let args = arguments as! ConfigureAPIArguments
        switch self {
        case let .urlField(title, value):
            return ItemListSingleLineInputItem(presentationData: presentationData, title: NSAttributedString(string: title), text: value, placeholder: "https://your-server.com", sectionId: self.section, textUpdated: { text in
                args.updateURL(text)
            }, action: {})
        case let .tokenField(title, value):
            return ItemListSingleLineInputItem(presentationData: presentationData, title: NSAttributedString(string: title), text: value, placeholder: "Только для админа", sectionId: self.section, textUpdated: { text in
                args.updateToken(text)
            }, action: {})
        case let .info(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        }
    }
}

private final class ConfigureAPIArguments {
    let updateURL: (String) -> Void
    let updateToken: (String) -> Void

    init(updateURL: @escaping (String) -> Void, updateToken: @escaping (String) -> Void) {
        self.updateURL = updateURL
        self.updateToken = updateToken
    }
}

private func configureAPIEntries(state: ConfigureAPIFormState) -> [ConfigureAPIEntry] {
    return [
        .urlField("URL: ", state.baseURL),
        .tokenField("Токен: ", state.adminToken),
        .info("Укажите URL вашего API сервера. Токен администратора нужен только если вы хотите управлять списком прокси (добавлять/удалять). Обычным пользователям токен не нужен."),
    ]
}

func mqgramConfigureAPIController(context: AccountContext, presentationData: PresentationData, completion: @escaping () -> Void) -> ViewController {
    let formState = ValuePromise<ConfigureAPIFormState>(ConfigureAPIFormState(), ignoreRepeated: true)
    var currentFormState = ConfigureAPIFormState()

    func updateForm(_ f: (inout ConfigureAPIFormState) -> Void) {
        f(&currentFormState)
        formState.set(currentFormState)
    }

    let arguments = ConfigureAPIArguments(
        updateURL: { text in updateForm { $0.baseURL = text } },
        updateToken: { text in updateForm { $0.adminToken = text } }
    )

    var dismissImpl: (() -> Void)?

    let signal = combineLatest(context.sharedContext.presentationData, formState.get())
    |> map { presentationData, form -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let rightButton = ItemListNavigationButton(content: .text("Сохранить"), style: .bold, enabled: !form.baseURL.isEmpty, action: {
            MQGramProxyAPI.configure(baseURL: currentFormState.baseURL, adminToken: currentFormState.adminToken)
            completion()
            dismissImpl?()
        })

        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text("Настройки API"),
            leftNavigationButton: nil,
            rightNavigationButton: rightButton,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)
        )

        let entries = configureAPIEntries(state: form)

        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: entries,
            style: .blocks
        )

        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    dismissImpl = { [weak controller] in
        controller?.navigationController?.popViewController(animated: true)
    }
    return controller
}
