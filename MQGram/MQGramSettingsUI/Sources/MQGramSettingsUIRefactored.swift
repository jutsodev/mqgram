import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramPresentationData
import ItemListUI
import PresentationDataUtils
import AccountContext

public enum MQGramSettingsCategory: Int, CaseIterable {
    case privacy = 0
    case appearance = 1
    case content = 2
    case messages = 3
    case advanced = 4
    case other = 5

    var title: String {
        switch self {
        case .privacy: return "Приватность"
        case .appearance: return "Внешний вид"
        case .content: return "Контент"
        case .messages: return "Сообщения"
        case .advanced: return "Расширенные"
        case .other: return "Другое"
        }
    }

    var description: String {
        switch self {
        case .privacy: return "Скрытие статуса, действий, читаемости"
        case .appearance: return "Дизайн, шрифты, аватары"
        case .content: return "Сохранение медиа, логирование"
        case .messages: return "Задержка, перевод, форматирование"
        case .advanced: return "Мощные функции для опытных"
        case .other: return "Остальные функции"
        }
    }

    var emoji: String {
        switch self {
        case .privacy: return "🔒"
        case .appearance: return "🎨"
        case .content: return "📦"
        case .messages: return "💬"
        case .advanced: return "⚙️"
        case .other: return "📋"
        }
    }
}

struct MQGramSettingsItem {
    let key: MQGramSettings.Key
    let title: String
    let description: String
    let icon: String
    let category: MQGramSettingsCategory
}

private enum MQGramCategoryEntry: ItemListNodeEntry {
    case header(Int32, String)
    case info(Int32, String)
    case toggle(Int32, MQGramSettings.Key, String, String?, Bool)
    case footer(Int32, String)

    var section: ItemListSectionId {
        switch self {
        case .header:
            return 0
        case .info, .toggle:
            return 1
        case .footer:
            return 2
        }
    }

    var stableId: Int32 {
        switch self {
        case let .header(id, _):      return id
        case let .info(id, _):        return id
        case let .toggle(id, _, _, _, _): return id
        case let .footer(id, _):      return id
        }
    }

    static func ==(lhs: MQGramCategoryEntry, rhs: MQGramCategoryEntry) -> Bool {
        switch lhs {
        case let .header(lId, lText):
            if case let .header(rId, rText) = rhs, lId == rId, lText == rText { return true }
            return false
        case let .info(lId, lText):
            if case let .info(rId, rText) = rhs, lId == rId, lText == rText { return true }
            return false
        case let .toggle(lId, lKey, lTitle, lText, lValue):
            if case let .toggle(rId, rKey, rTitle, rText, rValue) = rhs, lId == rId, lKey == rKey, lTitle == rTitle, lText == rText, lValue == rValue { return true }
            return false
        case let .footer(lId, lText):
            if case let .footer(rId, rText) = rhs, lId == rId, lText == rText { return true }
            return false
        }
    }

    static func <(lhs: MQGramCategoryEntry, rhs: MQGramCategoryEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let args = arguments as! MQGramCategoryArguments
        switch self {
        case let .header(_, text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .info(_, text):
            return ItemListTextItem(presentationData: presentationData, text: .markdown(text), sectionId: self.section)
        case let .toggle(_, key, title, text, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: title, text: text, value: value, sectionId: self.section, style: .blocks, updated: { newValue in
                args.toggleSetting(key, newValue)
            })
        case let .footer(_, text):
            return ItemListTextItem(presentationData: presentationData, text: .markdown(text), sectionId: self.section)
        }
    }
}

private struct MQGramCategoryArguments {
    let toggleSetting: (MQGramSettings.Key, Bool) -> Void
}

private func getMQGramItemsForCategory(_ category: MQGramSettingsCategory) -> [MQGramSettingsItem] {
    let allItems: [MQGramSettingsItem] = [
        MQGramSettingsItem(key: .ghostMode, title: "Ghost Mode", description: "Скрыть активность", icon: "👻", category: .privacy),
    ]
    return allItems.filter { $0.category == category }
}

public func mqgramCategoryViewController(context: AccountContext, category: MQGramSettingsCategory) -> ViewController {
    let updatePromise = ValuePromise<Bool>(true, ignoreRepeated: false)

    let arguments = MQGramCategoryArguments(
        toggleSetting: { key, value in
            MQGramSettings.shared.setBool(value, for: key)
            updatePromise.set(true)
        }
    )

    let signal = combineLatest(context.sharedContext.presentationData, updatePromise.get())
    |> map { presentationData, _ -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let settings = MQGramSettings.shared
        let strings = presentationData.strings

        let items = getMQGramItemsForCategory(category)
        var entries: [MQGramCategoryEntry] = []
        var id: Int32 = 0

        entries.append(.info(id, "\(category.emoji) \(category.title)\n\(category.description)")); id += 1

        for item in items {
            let value = settings.bool(for: item.key)
            entries.append(.toggle(id, item.key, item.title, item.description, value)); id += 1
        }

        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text(category.title),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: strings.Common_Back)
        )

        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: entries,
            style: .blocks,
            animateChanges: true
        )

        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    return controller
}
