// MARK: MQGram - Passcode Settings Controller
import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramPresentationData
import ItemListUI
import PresentationDataUtils
import AccountContext
import TelegramCore

private final class MQGramPasscodeArguments {
    let context: AccountContext
    let setPasscode: (MQGramPasscodeManager.PasscodeType) -> Void
    let changePasscode: () -> Void
    let removePasscode: () -> Void
    let openLockedChats: () -> Void
    let unlockChats: () -> Void

    init(context: AccountContext, setPasscode: @escaping (MQGramPasscodeManager.PasscodeType) -> Void, changePasscode: @escaping () -> Void, removePasscode: @escaping () -> Void, openLockedChats: @escaping () -> Void, unlockChats: @escaping () -> Void) {
        self.context = context
        self.setPasscode = setPasscode
        self.changePasscode = changePasscode
        self.removePasscode = removePasscode
        self.openLockedChats = openLockedChats
        self.unlockChats = unlockChats
    }
}

private struct MQGramPasscodeState: Equatable {
    var isPasscodeSet: Bool
    var lockedCount: Int
    var isUnlocked: Bool
    var passcodeType: MQGramPasscodeManager.PasscodeType
}

private enum MQGramPasscodeSection: Int32 {
    case passcode
    case chats
    case actions
}

private enum MQGramPasscodeEntryId: Hashable {
    case header
    case setPasscode4
    case setPasscode6
    case changePasscode
    case removePasscode
    case chatsHeader
    case lockedChats
    case actionsHeader
    case unlockChats
    case info
}

private enum MQGramPasscodeEntry: ItemListNodeEntry {
    case header(String)
    case setPasscode4(String)
    case setPasscode6(String)
    case changePasscode(String)
    case removePasscode(String)
    case chatsHeader(String)
    case lockedChats(String, Int)
    case actionsHeader(String)
    case unlockChats(String)
    case info(String)

    var section: ItemListSectionId {
        switch self {
        case .header, .setPasscode4, .setPasscode6, .changePasscode, .removePasscode:
            return MQGramPasscodeSection.passcode.rawValue
        case .chatsHeader, .lockedChats:
            return MQGramPasscodeSection.chats.rawValue
        case .actionsHeader, .unlockChats, .info:
            return MQGramPasscodeSection.actions.rawValue
        }
    }

    var stableId: MQGramPasscodeEntryId {
        switch self {
        case .header: return .header
        case .setPasscode4: return .setPasscode4
        case .setPasscode6: return .setPasscode6
        case .changePasscode: return .changePasscode
        case .removePasscode: return .removePasscode
        case .chatsHeader: return .chatsHeader
        case .lockedChats: return .lockedChats
        case .actionsHeader: return .actionsHeader
        case .unlockChats: return .unlockChats
        case .info: return .info
        }
    }

    static func ==(lhs: MQGramPasscodeEntry, rhs: MQGramPasscodeEntry) -> Bool {
        switch lhs {
        case let .header(lText):
            if case let .header(rText) = rhs, lText == rText { return true } else { return false }
        case let .setPasscode4(lText):
            if case let .setPasscode4(rText) = rhs, lText == rText { return true } else { return false }
        case let .setPasscode6(lText):
            if case let .setPasscode6(rText) = rhs, lText == rText { return true } else { return false }
        case let .changePasscode(lText):
            if case let .changePasscode(rText) = rhs, lText == rText { return true } else { return false }
        case let .removePasscode(lText):
            if case let .removePasscode(rText) = rhs, lText == rText { return true } else { return false }
        case let .chatsHeader(lText):
            if case let .chatsHeader(rText) = rhs, lText == rText { return true } else { return false }
        case let .lockedChats(lText, lCount):
            if case let .lockedChats(rText, rCount) = rhs, lText == rText, lCount == rCount { return true } else { return false }
        case let .actionsHeader(lText):
            if case let .actionsHeader(rText) = rhs, lText == rText { return true } else { return false }
        case let .unlockChats(lText):
            if case let .unlockChats(rText) = rhs, lText == rText { return true } else { return false }
        case let .info(lText):
            if case let .info(rText) = rhs, lText == rText { return true } else { return false }
        }
    }

    static func <(lhs: MQGramPasscodeEntry, rhs: MQGramPasscodeEntry) -> Bool {
        return lhs.sortIndex < rhs.sortIndex
    }

    var sortIndex: Int32 {
        switch self {
        case .header: return 0
        case .setPasscode4: return 1
        case .setPasscode6: return 2
        case .changePasscode: return 3
        case .removePasscode: return 4
        case .chatsHeader: return 10
        case .lockedChats: return 11
        case .actionsHeader: return 20
        case .unlockChats: return 21
        case .info: return 30
        }
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let args = arguments as! MQGramPasscodeArguments
        switch self {
        case let .header(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .setPasscode4(text):
            return ItemListDisclosureItem(presentationData: presentationData, title: text, label: "", sectionId: self.section, style: .blocks, action: {
                args.setPasscode(.fourDigit)
            })
        case let .setPasscode6(text):
            return ItemListDisclosureItem(presentationData: presentationData, title: text, label: "", sectionId: self.section, style: .blocks, action: {
                args.setPasscode(.sixDigit)
            })
        case let .changePasscode(text):
            return ItemListDisclosureItem(presentationData: presentationData, title: text, label: "", sectionId: self.section, style: .blocks, action: {
                args.changePasscode()
            })
        case let .removePasscode(text):
            return ItemListActionItem(presentationData: presentationData, title: text, kind: .destructive, alignment: .natural, sectionId: self.section, style: .blocks, action: {
                args.removePasscode()
            })
        case let .chatsHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .lockedChats(text, count):
            return ItemListDisclosureItem(presentationData: presentationData, title: text, label: "\(count)", sectionId: self.section, style: .blocks, action: {
                args.openLockedChats()
            })
        case let .actionsHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .unlockChats(text):
            return ItemListActionItem(presentationData: presentationData, title: text, kind: .generic, alignment: .natural, sectionId: self.section, style: .blocks, action: {
                args.unlockChats()
            })
        case let .info(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        }
    }
}

private func mqgramPasscodeEntries(state: MQGramPasscodeState) -> [MQGramPasscodeEntry] {
    var entries: [MQGramPasscodeEntry] = []

    entries.append(.header("КОД-ПАРОЛЬ"))

    if state.isPasscodeSet {
        entries.append(.changePasscode("Изменить код-пароль"))
        entries.append(.removePasscode("Убрать код-пароль"))

        entries.append(.chatsHeader("ЗАЩИЩЁННЫЕ ЧАТЫ"))
        entries.append(.lockedChats("Заблокированные чаты", state.lockedCount))

        if state.lockedCount > 0 {
            entries.append(.actionsHeader("ДЕЙСТВИЯ"))
            if state.isUnlocked {
                entries.append(.info("Скрытые чаты сейчас видны. Они будут скрыты при перезапуске приложения."))
            } else {
                entries.append(.unlockChats("Показать скрытые чаты"))
            }
        }
    } else {
        entries.append(.setPasscode4("4-значный код"))
        entries.append(.setPasscode6("6-значный код"))
    }

    return entries
}

public func mqgramPasscodeController(context: AccountContext) -> ViewController {
    let statePromise = ValuePromise<MQGramPasscodeState>(ignoreRepeated: true)

    func refreshState() {
        let manager = MQGramPasscodeManager.shared
        statePromise.set(MQGramPasscodeState(
            isPasscodeSet: manager.isPasscodeSet,
            lockedCount: manager.lockedPeerIds.count,
            isUnlocked: manager.isUnlocked,
            passcodeType: manager.passcodeType
        ))
    }

    refreshState()

    var pushControllerImpl: ((ViewController) -> Void)?
    var presentControllerImpl: ((ViewController) -> Void)?

    let arguments = MQGramPasscodeArguments(
        context: context,
        setPasscode: { type in
            let entryController = MQGramPasscodeEntryController(context: context, mode: .set, passcodeType: type) { success in
                if success {
                    refreshState()
                }
            }
            pushControllerImpl?(entryController)
        },
        changePasscode: {
            let type = MQGramPasscodeManager.shared.passcodeType
            let verifyController = MQGramPasscodeEntryController(context: context, mode: .verify, passcodeType: type) { success in
                if success {
                    let changeController = MQGramPasscodeEntryController(context: context, mode: .change, passcodeType: type) { changeSuccess in
                        if changeSuccess {
                            refreshState()
                        }
                    }
                    pushControllerImpl?(changeController)
                }
            }
            pushControllerImpl?(verifyController)
        },
        removePasscode: {
            let type = MQGramPasscodeManager.shared.passcodeType
            let verifyController = MQGramPasscodeEntryController(context: context, mode: .verify, passcodeType: type) { success in
                if success {
                    MQGramPasscodeManager.shared.removePasscode()
                    refreshState()
                }
            }
            pushControllerImpl?(verifyController)
        },
        openLockedChats: {
            let chatPickerController = mqgramChatPickerController(context: context) {
                refreshState()
            }
            pushControllerImpl?(chatPickerController)
        },
        unlockChats: {
            let type = MQGramPasscodeManager.shared.passcodeType
            let verifyController = MQGramPasscodeEntryController(context: context, mode: .verify, passcodeType: type) { success in
                if success {
                    MQGramPasscodeManager.shared.unlock()
                    refreshState()
                }
            }
            pushControllerImpl?(verifyController)
        }
    )

    let signal = combineLatest(context.sharedContext.presentationData, statePromise.get())
    |> map { presentationData, passcodeState -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text("Код-пароль"),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)
        )

        let entries = mqgramPasscodeEntries(state: passcodeState)

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
    presentControllerImpl = { [weak controller] c in
        controller?.present(c, in: .window(.root))
    }
    let _ = presentControllerImpl
    return controller
}
