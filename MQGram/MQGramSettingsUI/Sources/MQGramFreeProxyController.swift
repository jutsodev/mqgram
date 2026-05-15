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

private enum ProxyConnectionState: Equatable {
    case idle
    case connecting
    case connected
}

private final class MQGramFreeProxyArguments {
    let connect: () -> Void

    init(connect: @escaping () -> Void) {
        self.connect = connect
    }
}

private enum MQGramFreeProxySection: Int32 {
    case header
    case proxy
    case footer
}

private enum MQGramFreeProxyEntry: ItemListNodeEntry {
    case headerInfo(String)
    case proxyHeader(String)
    case proxyItem(Int32, String, ProxyConnectionState)
    case footer(String)

    var section: ItemListSectionId {
        switch self {
        case .headerInfo:
            return MQGramFreeProxySection.header.rawValue
        case .proxyHeader, .proxyItem:
            return MQGramFreeProxySection.proxy.rawValue
        case .footer:
            return MQGramFreeProxySection.footer.rawValue
        }
    }

    var stableId: Int32 {
        switch self {
        case .headerInfo:
            return 0
        case .proxyHeader:
            return 1
        case let .proxyItem(id, _, _):
            return 100 + id
        case .footer:
            return 9999
        }
    }

    static func ==(lhs: MQGramFreeProxyEntry, rhs: MQGramFreeProxyEntry) -> Bool {
        switch lhs {
        case let .headerInfo(lText):
            if case let .headerInfo(rText) = rhs, lText == rText { return true } else { return false }
        case let .proxyHeader(lText):
            if case let .proxyHeader(rText) = rhs, lText == rText { return true } else { return false }
        case let .proxyItem(lId, lTitle, lState):
            if case let .proxyItem(rId, rTitle, rState) = rhs,
               lId == rId, lTitle == rTitle, lState == rState {
                return true
            }
            return false
        case let .footer(lText):
            if case let .footer(rText) = rhs, lText == rText { return true } else { return false }
        }
    }

    static func <(lhs: MQGramFreeProxyEntry, rhs: MQGramFreeProxyEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let args = arguments as! MQGramFreeProxyArguments
        switch self {
        case let .headerInfo(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: MQGramFreeProxySection.header.rawValue)
        case let .proxyHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: MQGramFreeProxySection.proxy.rawValue)
        case let .proxyItem(_, title, state):
            let label: String
            switch state {
            case .idle:
                label = "Подключиться"
            case .connecting:
                label = "Подключение..."
            case .connected:
                label = "✓ Подключено"
            }
            return ItemListDisclosureItem(
                presentationData: presentationData,
                title: title,
                label: label,
                sectionId: MQGramFreeProxySection.proxy.rawValue,
                style: .blocks,
                disclosureStyle: state == .idle ? .arrow : .none,
                action: {
                    args.connect()
                }
            )
        case let .footer(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: MQGramFreeProxySection.footer.rawValue)
        }
    }
}

private func mqgramFreeProxyEntries(state: ProxyConnectionState) -> [MQGramFreeProxyEntry] {
    var entries: [MQGramFreeProxyEntry] = []

    entries.append(.headerInfo("Бесплатный прокси-сервер для обхода блокировок. Нажмите на сервер чтобы подключиться."))
    entries.append(.proxyHeader("ПРОКСИ-СЕРВЕРЫ"))
    entries.append(.proxyItem(0, "🇷🇺 Россия — Обход Блокировок", state))
    entries.append(.footer("Прокси подключается через MTProto и не требует установки дополнительных приложений. Весь трафик шифруется."))

    return entries
}

public func mqgramFreeProxyController(context: AccountContext) -> ViewController {
    let statePromise = ValuePromise<ProxyConnectionState>(.idle, ignoreRepeated: true)

    let arguments = MQGramFreeProxyArguments(connect: {
        statePromise.set(.connecting)

        let proxyUrl = "https://t.me/proxy?server=jutsovpn.online&port=443&secret=93f906b4bf5e0344bfa129f889a02cd3"
        context.sharedContext.openExternalUrl(context: context, urlContext: .generic, url: proxyUrl, forceExternal: false, presentationData: context.sharedContext.currentPresentationData.with { $0 }, navigationController: context.sharedContext.mainWindow?.viewController as? NavigationController, dismissInput: {})

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            statePromise.set(.connected)
        }
    })

    let signal = combineLatest(context.sharedContext.presentationData, statePromise.get())
    |> map { presentationData, connectionState -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text("Free Proxy"),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)
        )

        let entries = mqgramFreeProxyEntries(state: connectionState)

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
