// MARK: MQGram - Developer Contacts
import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramPresentationData
import ItemListUI
import PresentationDataUtils
import AccountContext
import TelegramCore

private struct DeveloperState: Equatable {
    var contacts: [MQGramContact]
    var isLoading: Bool
    var isAdmin: Bool

    init(userId: Int64 = 0) {
        self.contacts = []
        self.isLoading = true
        self.isAdmin = MQGramProxyAPI.isAdmin(userId: userId)
    }
}

private final class DeveloperArguments {
    let openContact: (MQGramContact) -> Void
    let editContact: (MQGramContact) -> Void
    let deleteContact: (MQGramContact) -> Void
    let addContact: () -> Void

    init(openContact: @escaping (MQGramContact) -> Void, editContact: @escaping (MQGramContact) -> Void, deleteContact: @escaping (MQGramContact) -> Void, addContact: @escaping () -> Void) {
        self.openContact = openContact
        self.editContact = editContact
        self.deleteContact = deleteContact
        self.addContact = addContact
    }
}

private enum DeveloperSection: Int32 {
    case info
    case contacts
    case admin
}

private enum DeveloperEntryId: Hashable {
    case headerInfo
    case contactsHeader
    case contact(String)
    case loading
    case empty
    case adminHeader
    case addContact
}

private enum DeveloperEntry: ItemListNodeEntry {
    case headerInfo(String)
    case contactsHeader(String)
    case contactItem(Int32, MQGramContact, Bool)
    case loading(Int32)
    case empty(Int32, String)
    case adminHeader(String)
    case addContact(Int32)

    var section: ItemListSectionId {
        switch self {
        case .headerInfo:
            return DeveloperSection.info.rawValue
        case .contactsHeader, .contactItem, .loading, .empty:
            return DeveloperSection.contacts.rawValue
        case .adminHeader, .addContact:
            return DeveloperSection.admin.rawValue
        }
    }

    var stableId: DeveloperEntryId {
        switch self {
        case .headerInfo:
            return .headerInfo
        case .contactsHeader:
            return .contactsHeader
        case let .contactItem(_, contact, _):
            return .contact(contact.id)
        case .loading:
            return .loading
        case .empty:
            return .empty
        case .adminHeader:
            return .adminHeader
        case .addContact:
            return .addContact
        }
    }

    static func ==(lhs: DeveloperEntry, rhs: DeveloperEntry) -> Bool {
        switch lhs {
        case let .headerInfo(lText):
            if case let .headerInfo(rText) = rhs, lText == rText { return true } else { return false }
        case let .contactsHeader(lText):
            if case let .contactsHeader(rText) = rhs, lText == rText { return true } else { return false }
        case let .contactItem(lIdx, lContact, lAdmin):
            if case let .contactItem(rIdx, rContact, rAdmin) = rhs, lIdx == rIdx, lContact == rContact, lAdmin == rAdmin { return true } else { return false }
        case let .loading(lIdx):
            if case let .loading(rIdx) = rhs, lIdx == rIdx { return true } else { return false }
        case let .empty(lIdx, lText):
            if case let .empty(rIdx, rText) = rhs, lIdx == rIdx, lText == rText { return true } else { return false }
        case let .adminHeader(lText):
            if case let .adminHeader(rText) = rhs, lText == rText { return true } else { return false }
        case let .addContact(lIdx):
            if case let .addContact(rIdx) = rhs, lIdx == rIdx { return true } else { return false }
        }
    }

    static func <(lhs: DeveloperEntry, rhs: DeveloperEntry) -> Bool {
        return lhs.sortIndex < rhs.sortIndex
    }

    var sortIndex: Int32 {
        switch self {
        case .headerInfo: return 0
        case .contactsHeader: return 1
        case let .contactItem(idx, _, _): return 10 + idx
        case .loading: return 5
        case .empty: return 5
        case .adminHeader: return 1000
        case .addContact: return 1001
        }
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let args = arguments as! DeveloperArguments
        switch self {
        case let .headerInfo(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .contactsHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .contactItem(_, contact, _):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                title: contact.name,
                label: "",
                sectionId: self.section,
                style: .blocks,
                disclosureStyle: .arrow,
                action: {
                    args.openContact(contact)
                }
            )
        case .loading:
            return ItemListTextItem(presentationData: presentationData, text: .plain("Загрузка..."), sectionId: self.section)
        case let .empty(_, text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .adminHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case .addContact:
            return ItemListDisclosureItem(
                presentationData: presentationData,
                title: "Добавить контакт",
                titleColor: .accent,
                label: "",
                sectionId: self.section,
                style: .blocks,
                disclosureStyle: .arrow,
                action: {
                    args.addContact()
                }
            )
        }
    }
}

private func developerEntries(state: DeveloperState) -> [DeveloperEntry] {
    var entries: [DeveloperEntry] = []

    entries.append(.headerInfo("Контакты разработчика MQGram. Нажмите для перехода."))
    entries.append(.contactsHeader("КОНТАКТЫ"))

    if state.isLoading {
        entries.append(.loading(0))
    } else if state.contacts.isEmpty {
        entries.append(.empty(0, "Нет контактов."))
    } else {
        for (index, contact) in state.contacts.enumerated() {
            entries.append(.contactItem(Int32(index), contact, state.isAdmin))
        }
    }

    if state.isAdmin {
        entries.append(.adminHeader("АДМИНИСТРАТОР"))
        entries.append(.addContact(0))
    }

    return entries
}

public func mqgramDeveloperController(context: AccountContext) -> ViewController {
    let userId = context.account.peerId.id._internalGetInt64Value()
    let statePromise = ValuePromise<DeveloperState>(DeveloperState(userId: userId), ignoreRepeated: true)
    var state = DeveloperState(userId: userId)

    func updateState(_ f: (inout DeveloperState) -> Void) {
        f(&state)
        statePromise.set(state)
    }

    func loadContacts() {
        updateState { $0.isLoading = true }
        MQGramProxyAPI.shared.fetchContacts { contacts in
            updateState {
                $0.contacts = contacts
                $0.isLoading = false
            }
        }
    }

    var pushControllerImpl: ((ViewController) -> Void)?

    let arguments = DeveloperArguments(
        openContact: { contact in
            context.sharedContext.openExternalUrl(
                context: context,
                urlContext: .generic,
                url: contact.url,
                forceExternal: false,
                presentationData: context.sharedContext.currentPresentationData.with { $0 },
                navigationController: context.sharedContext.mainWindow?.viewController as? NavigationController,
                dismissInput: {}
            )
        },
        editContact: { contact in
            let presentationData = context.sharedContext.currentPresentationData.with { $0 }
            let controller = mqgramEditContactController(context: context, presentationData: presentationData, contact: contact) {
                loadContacts()
            }
            pushControllerImpl?(controller)
        },
        deleteContact: { contact in
            MQGramProxyAPI.shared.deleteContact(id: contact.id) { success in
                if success {
                    loadContacts()
                }
            }
        },
        addContact: {
            let presentationData = context.sharedContext.currentPresentationData.with { $0 }
            let controller = mqgramAddContactController(context: context, presentationData: presentationData) {
                loadContacts()
            }
            pushControllerImpl?(controller)
        }
    )

    let signal = combineLatest(context.sharedContext.presentationData, statePromise.get())
    |> map { presentationData, devState -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text("Разработчики"),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)
        )

        let entries = developerEntries(state: devState)

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

    loadContacts()

    return controller
}

// MARK: - Add Contact Controller

private struct AddContactFormState: Equatable {
    var name: String = ""
    var url: String = ""
    var icon: String = "link"
}

private enum AddContactSection: Int32 {
    case fields
}

private enum AddContactEntryId: Hashable {
    case nameField
    case urlField
    case iconField
}

private enum AddContactEntry: ItemListNodeEntry {
    case nameField(String, String)
    case urlField(String, String)
    case iconField(String, String)

    var section: ItemListSectionId {
        return AddContactSection.fields.rawValue
    }

    var stableId: AddContactEntryId {
        switch self {
        case .nameField: return .nameField
        case .urlField: return .urlField
        case .iconField: return .iconField
        }
    }

    static func ==(lhs: AddContactEntry, rhs: AddContactEntry) -> Bool {
        switch lhs {
        case let .nameField(lTitle, lValue):
            if case let .nameField(rTitle, rValue) = rhs, lTitle == rTitle, lValue == rValue { return true } else { return false }
        case let .urlField(lTitle, lValue):
            if case let .urlField(rTitle, rValue) = rhs, lTitle == rTitle, lValue == rValue { return true } else { return false }
        case let .iconField(lTitle, lValue):
            if case let .iconField(rTitle, rValue) = rhs, lTitle == rTitle, lValue == rValue { return true } else { return false }
        }
    }

    static func <(lhs: AddContactEntry, rhs: AddContactEntry) -> Bool {
        return lhs.sortIndex < rhs.sortIndex
    }

    var sortIndex: Int32 {
        switch self {
        case .nameField: return 0
        case .urlField: return 1
        case .iconField: return 2
        }
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let args = arguments as! AddContactArguments
        switch self {
        case let .nameField(title, value):
            return ItemListSingleLineInputItem(presentationData: presentationData, title: NSAttributedString(string: title), text: value, placeholder: "GitHub", sectionId: self.section, textUpdated: { text in args.updateName(text) }, action: {})
        case let .urlField(title, value):
            return ItemListSingleLineInputItem(presentationData: presentationData, title: NSAttributedString(string: title), text: value, placeholder: "https://github.com/...", sectionId: self.section, textUpdated: { text in args.updateURL(text) }, action: {})
        case let .iconField(title, value):
            return ItemListSingleLineInputItem(presentationData: presentationData, title: NSAttributedString(string: title), text: value, placeholder: "link, github, telegram, bot", sectionId: self.section, textUpdated: { text in args.updateIcon(text) }, action: {})
        }
    }
}

private final class AddContactArguments {
    let updateName: (String) -> Void
    let updateURL: (String) -> Void
    let updateIcon: (String) -> Void

    init(updateName: @escaping (String) -> Void, updateURL: @escaping (String) -> Void, updateIcon: @escaping (String) -> Void) {
        self.updateName = updateName
        self.updateURL = updateURL
        self.updateIcon = updateIcon
    }
}

func mqgramAddContactController(context: AccountContext, presentationData: PresentationData, completion: @escaping () -> Void) -> ViewController {
    let formState = ValuePromise<AddContactFormState>(AddContactFormState(), ignoreRepeated: true)
    var currentFormState = AddContactFormState()

    func updateForm(_ f: (inout AddContactFormState) -> Void) {
        f(&currentFormState)
        formState.set(currentFormState)
    }

    let arguments = AddContactArguments(
        updateName: { text in updateForm { $0.name = text } },
        updateURL: { text in updateForm { $0.url = text } },
        updateIcon: { text in updateForm { $0.icon = text } }
    )

    var dismissImpl: (() -> Void)?

    let signal = combineLatest(context.sharedContext.presentationData, formState.get())
    |> map { presentationData, form -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let rightButton = ItemListNavigationButton(content: .text("Сохранить"), style: .bold, enabled: !form.name.isEmpty && !form.url.isEmpty, action: {
            MQGramProxyAPI.shared.addContact(name: currentFormState.name, url: currentFormState.url, icon: currentFormState.icon.isEmpty ? "link" : currentFormState.icon) { contact in
                if contact != nil {
                    completion()
                    dismissImpl?()
                }
            }
        })

        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text("Добавить контакт"),
            leftNavigationButton: nil,
            rightNavigationButton: rightButton,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)
        )

        let entries: [AddContactEntry] = [
            .nameField("Имя: ", form.name),
            .urlField("Ссылка: ", form.url),
            .iconField("Иконка: ", form.icon),
        ]

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

// MARK: - Edit Contact Controller

private struct EditContactFormState: Equatable {
    var name: String
    var url: String
    var icon: String

    init(contact: MQGramContact) {
        self.name = contact.name
        self.url = contact.url
        self.icon = contact.icon
    }
}

private enum EditContactSection: Int32 {
    case fields
    case actions
}

private enum EditContactEntryId: Hashable {
    case nameField
    case urlField
    case iconField
    case deleteButton
}

private enum EditContactEntry: ItemListNodeEntry {
    case nameField(String, String)
    case urlField(String, String)
    case iconField(String, String)
    case deleteButton(Int32)

    var section: ItemListSectionId {
        switch self {
        case .nameField, .urlField, .iconField:
            return EditContactSection.fields.rawValue
        case .deleteButton:
            return EditContactSection.actions.rawValue
        }
    }

    var stableId: EditContactEntryId {
        switch self {
        case .nameField: return .nameField
        case .urlField: return .urlField
        case .iconField: return .iconField
        case .deleteButton: return .deleteButton
        }
    }

    static func ==(lhs: EditContactEntry, rhs: EditContactEntry) -> Bool {
        switch lhs {
        case let .nameField(lTitle, lValue):
            if case let .nameField(rTitle, rValue) = rhs, lTitle == rTitle, lValue == rValue { return true } else { return false }
        case let .urlField(lTitle, lValue):
            if case let .urlField(rTitle, rValue) = rhs, lTitle == rTitle, lValue == rValue { return true } else { return false }
        case let .iconField(lTitle, lValue):
            if case let .iconField(rTitle, rValue) = rhs, lTitle == rTitle, lValue == rValue { return true } else { return false }
        case let .deleteButton(lIdx):
            if case let .deleteButton(rIdx) = rhs, lIdx == rIdx { return true } else { return false }
        }
    }

    static func <(lhs: EditContactEntry, rhs: EditContactEntry) -> Bool {
        return lhs.sortIndex < rhs.sortIndex
    }

    var sortIndex: Int32 {
        switch self {
        case .nameField: return 0
        case .urlField: return 1
        case .iconField: return 2
        case .deleteButton: return 100
        }
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let args = arguments as! EditContactArguments
        switch self {
        case let .nameField(title, value):
            return ItemListSingleLineInputItem(presentationData: presentationData, title: NSAttributedString(string: title), text: value, placeholder: "Название", sectionId: self.section, textUpdated: { text in args.updateName(text) }, action: {})
        case let .urlField(title, value):
            return ItemListSingleLineInputItem(presentationData: presentationData, title: NSAttributedString(string: title), text: value, placeholder: "https://...", sectionId: self.section, textUpdated: { text in args.updateURL(text) }, action: {})
        case let .iconField(title, value):
            return ItemListSingleLineInputItem(presentationData: presentationData, title: NSAttributedString(string: title), text: value, placeholder: "link, github, telegram, bot", sectionId: self.section, textUpdated: { text in args.updateIcon(text) }, action: {})
        case .deleteButton:
            return ItemListActionItem(presentationData: presentationData, title: "Удалить контакт", kind: .destructive, alignment: .center, sectionId: self.section, style: .blocks, action: {
                args.deleteContact()
            })
        }
    }
}

private final class EditContactArguments {
    let updateName: (String) -> Void
    let updateURL: (String) -> Void
    let updateIcon: (String) -> Void
    let deleteContact: () -> Void

    init(updateName: @escaping (String) -> Void, updateURL: @escaping (String) -> Void, updateIcon: @escaping (String) -> Void, deleteContact: @escaping () -> Void) {
        self.updateName = updateName
        self.updateURL = updateURL
        self.updateIcon = updateIcon
        self.deleteContact = deleteContact
    }
}

func mqgramEditContactController(context: AccountContext, presentationData: PresentationData, contact: MQGramContact, completion: @escaping () -> Void) -> ViewController {
    let formState = ValuePromise<EditContactFormState>(EditContactFormState(contact: contact), ignoreRepeated: true)
    var currentFormState = EditContactFormState(contact: contact)

    func updateForm(_ f: (inout EditContactFormState) -> Void) {
        f(&currentFormState)
        formState.set(currentFormState)
    }

    var dismissImpl: (() -> Void)?

    let deleteAction = {
        MQGramProxyAPI.shared.deleteContact(id: contact.id) { success in
            if success {
                completion()
                dismissImpl?()
            }
        }
    }

    let editArguments = EditContactArguments(
        updateName: { text in updateForm { $0.name = text } },
        updateURL: { text in updateForm { $0.url = text } },
        updateIcon: { text in updateForm { $0.icon = text } },
        deleteContact: deleteAction
    )

    let signal = combineLatest(context.sharedContext.presentationData, formState.get())
    |> map { presentationData, form -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let rightButton = ItemListNavigationButton(content: .text("Сохранить"), style: .bold, enabled: !form.name.isEmpty && !form.url.isEmpty, action: {
            MQGramProxyAPI.shared.updateContact(
                id: contact.id,
                name: currentFormState.name,
                url: currentFormState.url,
                icon: currentFormState.icon.isEmpty ? nil : currentFormState.icon
            ) { updated in
                if updated != nil {
                    completion()
                    dismissImpl?()
                }
            }
        })

        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text("Редактировать"),
            leftNavigationButton: nil,
            rightNavigationButton: rightButton,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)
        )

        let entries: [EditContactEntry] = [
            .nameField("Имя: ", form.name),
            .urlField("Ссылка: ", form.url),
            .iconField("Иконка: ", form.icon),
            .deleteButton(0),
        ]

        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: entries,
            style: .blocks
        )

        return (controllerState, (listState, editArguments))
    }

    let controller = ItemListController(context: context, state: signal)
    dismissImpl = { [weak controller] in
        controller?.navigationController?.popViewController(animated: true)
    }
    return controller
}
