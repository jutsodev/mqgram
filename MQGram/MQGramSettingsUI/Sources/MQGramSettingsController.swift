// MARK: MQGram
import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramPresentationData
import ItemListUI
import PresentationDataUtils
import AccountContext
import TelegramCore

private final class MQGramArguments {
    let toggleSetting: (MQGramSettings.Key, Bool) -> Void
    let openFreeProxy: () -> Void
    let openSwiftgram: () -> Void

    init(toggleSetting: @escaping (MQGramSettings.Key, Bool) -> Void, openFreeProxy: @escaping () -> Void, openSwiftgram: @escaping () -> Void) {
        self.toggleSetting = toggleSetting
        self.openFreeProxy = openFreeProxy
        self.openSwiftgram = openSwiftgram
    }
}

private enum MQGramSection: Int32 {
    case links
    case stable
    case beta
    case footer
}

private enum MQGramEntry: ItemListNodeEntry {
    case linksHeader(String)
    case freeProxy(Int32)
    case swiftgramLink(Int32)
    case stableHeader(String)
    case toggle(Int32, MQGramSection, MQGramSettings.Key, String, String?, Bool)
    case betaHeader(String)
    case footer(String)

    var section: ItemListSectionId {
        switch self {
        case .linksHeader, .freeProxy, .swiftgramLink:
            return MQGramSection.links.rawValue
        case .stableHeader:
            return MQGramSection.stable.rawValue
        case .betaHeader:
            return MQGramSection.beta.rawValue
        case .footer:
            return MQGramSection.footer.rawValue
        case let .toggle(_, section, _, _, _, _):
            return section.rawValue
        }
    }

    var stableId: Int32 {
        switch self {
        case .linksHeader:
            return -100
        case let .freeProxy(id):
            return id
        case let .swiftgramLink(id):
            return id
        case .stableHeader:
            return 0
        case let .toggle(id, _, _, _, _, _):
            return id
        case .betaHeader:
            return 1000
        case .footer:
            return 9999
        }
    }

    static func ==(lhs: MQGramEntry, rhs: MQGramEntry) -> Bool {
        switch lhs {
        case let .linksHeader(lText):
            if case let .linksHeader(rText) = rhs, lText == rText { return true } else { return false }
        case let .freeProxy(lId):
            if case let .freeProxy(rId) = rhs, lId == rId { return true } else { return false }
        case let .swiftgramLink(lId):
            if case let .swiftgramLink(rId) = rhs, lId == rId { return true } else { return false }
        case let .stableHeader(lText):
            if case let .stableHeader(rText) = rhs, lText == rText { return true } else { return false }
        case let .betaHeader(lText):
            if case let .betaHeader(rText) = rhs, lText == rText { return true } else { return false }
        case let .footer(lText):
            if case let .footer(rText) = rhs, lText == rText { return true } else { return false }
        case let .toggle(lId, lSection, lKey, lTitle, lText, lValue):
            if case let .toggle(rId, rSection, rKey, rTitle, rText, rValue) = rhs,
               lId == rId, lSection == rSection, lKey == rKey, lTitle == rTitle, lText == rText, lValue == rValue {
                return true
            }
            return false
        }
    }

    static func <(lhs: MQGramEntry, rhs: MQGramEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let args = arguments as! MQGramArguments
        switch self {
        case let .linksHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: MQGramSection.links.rawValue)
        case .freeProxy:
            return ItemListDisclosureItem(presentationData: presentationData, icon: PresentationResourcesSettings.proxy, title: "Free Proxy", label: "", sectionId: MQGramSection.links.rawValue, style: .blocks, action: {
                args.openFreeProxy()
            })
        case .swiftgramLink:
            return ItemListDisclosureItem(presentationData: presentationData, icon: PresentationResourcesSettings.swiftgram, title: "Swiftgram", label: "", sectionId: MQGramSection.links.rawValue, style: .blocks, action: {
                args.openSwiftgram()
            })
        case let .stableHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: MQGramSection.stable.rawValue)
        case let .betaHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: MQGramSection.beta.rawValue)
        case let .footer(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: MQGramSection.footer.rawValue)
        case let .toggle(_, section, key, title, text, value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: title,
                text: text,
                value: value,
                sectionId: section.rawValue,
                style: .blocks,
                updated: { newValue in
                    args.toggleSetting(key, newValue)
                }
            )
        }
    }
}

private func mqgramEntries(settings: MQGramSettings) -> [MQGramEntry] {
    var entries: [MQGramEntry] = []

    entries.append(.linksHeader("TOOLS"))
    entries.append(.freeProxy(-99))
    entries.append(.swiftgramLink(-98))

    var id: Int32 = 1

    entries.append(.stableHeader("STABLE"))

    entries.append(.toggle(id, .stable, .antiSelfDestruct,
        "Anti-Self-Destruct",
        "Save disappearing photos/videos and remove timers.",
        settings.antiSelfDestruct))
    id += 1

    entries.append(.toggle(id, .stable, .antiRevoke,
        "Anti-Revoke",
        "Messages are never deleted for you. Deleted messages are marked with a ⏱️ icon.",
        settings.antiRevoke))
    id += 1

    entries.append(.toggle(id, .stable, .ghostMode,
        "Ghost Mode",
        "Read messages and view stories without read receipts.",
        settings.ghostMode))
    id += 1

    entries.append(.toggle(id, .stable, .customIndicators,
        "Custom Indicators",
        "Adds italic/spoiler labels to intercepted disappearing content.",
        settings.customIndicators))
    id += 1

    entries.append(.betaHeader("BETA · WORK IN PROGRESS"))
    id = 1001

    entries.append(.toggle(id, .beta, .contentProtectionBypass,
        "Content Protection Bypass",
        "Forward and save media from restricted channels and chats.",
        settings.contentProtectionBypass))
    id += 1

    entries.append(.toggle(id, .beta, .antiEdit,
        "Anti-Edit",
        "See original content of edited messages.",
        settings.antiEdit))
    id += 1

    entries.append(.toggle(id, .beta, .disableAds,
        "Disable Ads",
        "Remove sponsored messages and ads from channels.",
        settings.disableAds))
    id += 1

    entries.append(.footer("MQGram features. Restart the app to apply changes."))

    return entries
}

public func mqgramSettingsController(context: AccountContext, openSwiftgramSettings: (() -> Void)? = nil) -> ViewController {
    let updatePromise = ValuePromise<Bool>(true, ignoreRepeated: false)

    var pushControllerImpl: ((ViewController) -> Void)?

    let arguments = MQGramArguments(
        toggleSetting: { key, value in
            MQGramSettings.shared.setBool(value, for: key)
            updatePromise.set(true)
        },
        openFreeProxy: {
            let proxyController = mqgramFreeProxyController(context: context)
            pushControllerImpl?(proxyController)
        },
        openSwiftgram: {
            if let openSwiftgramSettings = openSwiftgramSettings {
                openSwiftgramSettings()
            }
        }
    )

    let signal = combineLatest(context.sharedContext.presentationData, updatePromise.get())
    |> map { presentationData, _ -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text("MQGram"),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)
        )

        let entries = mqgramEntries(settings: MQGramSettings.shared)

        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: entries,
            style: .blocks
        )

        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    pushControllerImpl = { [weak controller] c in
        controller?.push(c)
    }
    return controller
}
