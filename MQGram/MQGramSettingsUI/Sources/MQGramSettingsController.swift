// MARK: MQGram
import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramPresentationData
import ItemListUI
import PresentationDataUtils
import AccountContext

// MARK: - Localization

private func mqLoc(_ key: String, _ lang: String) -> String {
    let isRu = lang.hasPrefix("ru")
    let strings: [String: [Bool: String]] = [
        "MQGram.Header":             [true: "ФУНКЦИИ", false: "FEATURES"],
        "MQGram.AntiSelfDestruct":   [true: "Анти-удаление", false: "Anti-Self-Destruct"],
        "MQGram.AntiSelfDestruct.Desc": [true: "Сохраняет исчезающие фото/видео и убирает таймеры.", false: "Save disappearing photos/videos and remove timers."],
        "MQGram.AntiRevoke":         [true: "Анти-отзыв", false: "Anti-Revoke"],
        "MQGram.AntiRevoke.Desc":    [true: "Удалённые сообщения остаются у вас. Помечаются иконкой 🗑️.", false: "Deleted messages stay for you. Marked with 🗑️ icon."],
        "MQGram.GhostMode":         [true: "Невидимка", false: "Ghost Mode"],
        "MQGram.GhostMode.Desc":    [true: "Читайте сообщения и смотрите сторис без отметки о прочтении.", false: "Read messages and view stories without read receipts."],
        "MQGram.CustomIndicators":   [true: "Индикаторы", false: "Custom Indicators"],
        "MQGram.CustomIndicators.Desc": [true: "Добавляет метки к перехваченному исчезающему контенту.", false: "Adds labels to intercepted disappearing content."],
        "MQGram.ContentProtection":  [true: "Обход защиты контента", false: "Content Protection Bypass"],
        "MQGram.ContentProtection.Desc": [true: "Пересылка и сохранение медиа из закрытых каналов и чатов.", false: "Forward and save media from restricted channels and chats."],
        "MQGram.AntiEdit":           [true: "Анти-редактирование", false: "Anti-Edit"],
        "MQGram.AntiEdit.Desc":      [true: "Видите оригинал отредактированных сообщений.", false: "See original content of edited messages."],
        "MQGram.DisableAds":         [true: "Отключить рекламу", false: "Disable Ads"],
        "MQGram.DisableAds.Desc":    [true: "Убирает спонсорские сообщения и рекламу в каналах.", false: "Remove sponsored messages and ads from channels."],
        "MQGram.ReadAfterAction":    [true: "Прочитать после действия", false: "Read After Action"],
        "MQGram.ReadAfterAction.Desc": [true: "Когда вы отправляете сообщение, все сообщения собеседника автоматически прочитываются.", false: "When you send a message, all messages in the chat are automatically marked as read."],
        "MQGram.Footer":            [true: "Функции MQGram. Перезапустите приложение для применения.", false: "MQGram features. Restart the app to apply changes."],
    ]
    return strings[key]?[isRu] ?? strings[key]?[false] ?? key
}

// MARK: - Controller

private final class MQGramArguments {
    let toggleSetting: (MQGramSettings.Key, Bool) -> Void

    init(toggleSetting: @escaping (MQGramSettings.Key, Bool) -> Void) {
        self.toggleSetting = toggleSetting
    }
}

private enum MQGramSection: Int32 {
    case features
    case footer
}

private enum MQGramEntry: ItemListNodeEntry {
    case header(String)
    case toggle(Int32, MQGramSettings.Key, String, String?, Bool)
    case footer(String)

    var section: ItemListSectionId {
        switch self {
        case .header, .toggle:
            return MQGramSection.features.rawValue
        case .footer:
            return MQGramSection.footer.rawValue
        }
    }

    var stableId: Int32 {
        switch self {
        case .header:
            return 0
        case let .toggle(id, _, _, _, _):
            return id
        case .footer:
            return 9999
        }
    }

    static func ==(lhs: MQGramEntry, rhs: MQGramEntry) -> Bool {
        switch lhs {
        case let .header(lText):
            if case let .header(rText) = rhs, lText == rText { return true } else { return false }
        case let .footer(lText):
            if case let .footer(rText) = rhs, lText == rText { return true } else { return false }
        case let .toggle(lId, lKey, lTitle, lText, lValue):
            if case let .toggle(rId, rKey, rTitle, rText, rValue) = rhs,
               lId == rId, lKey == rKey, lTitle == rTitle, lText == rText, lValue == rValue {
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
        case let .header(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: MQGramSection.features.rawValue)
        case let .footer(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: MQGramSection.footer.rawValue)
        case let .toggle(_, key, title, text, value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: title,
                text: text,
                value: value,
                sectionId: MQGramSection.features.rawValue,
                style: .blocks,
                updated: { newValue in
                    args.toggleSetting(key, newValue)
                }
            )
        }
    }
}

private func mqgramEntries(settings: MQGramSettings, lang: String) -> [MQGramEntry] {
    var entries: [MQGramEntry] = []
    var id: Int32 = 1

    entries.append(.header(mqLoc("MQGram.Header", lang)))

    entries.append(.toggle(id, .antiSelfDestruct,
        mqLoc("MQGram.AntiSelfDestruct", lang),
        mqLoc("MQGram.AntiSelfDestruct.Desc", lang),
        settings.antiSelfDestruct))
    id += 1

    entries.append(.toggle(id, .antiRevoke,
        mqLoc("MQGram.AntiRevoke", lang),
        mqLoc("MQGram.AntiRevoke.Desc", lang),
        settings.antiRevoke))
    id += 1

    entries.append(.toggle(id, .ghostMode,
        mqLoc("MQGram.GhostMode", lang),
        mqLoc("MQGram.GhostMode.Desc", lang),
        settings.ghostMode))
    id += 1

    entries.append(.toggle(id, .customIndicators,
        mqLoc("MQGram.CustomIndicators", lang),
        mqLoc("MQGram.CustomIndicators.Desc", lang),
        settings.customIndicators))
    id += 1

    entries.append(.toggle(id, .contentProtectionBypass,
        mqLoc("MQGram.ContentProtection", lang),
        mqLoc("MQGram.ContentProtection.Desc", lang),
        settings.contentProtectionBypass))
    id += 1

    entries.append(.toggle(id, .antiEdit,
        mqLoc("MQGram.AntiEdit", lang),
        mqLoc("MQGram.AntiEdit.Desc", lang),
        settings.antiEdit))
    id += 1

    entries.append(.toggle(id, .disableAds,
        mqLoc("MQGram.DisableAds", lang),
        mqLoc("MQGram.DisableAds.Desc", lang),
        settings.disableAds))
    id += 1

    entries.append(.toggle(id, .readAfterAction,
        mqLoc("MQGram.ReadAfterAction", lang),
        mqLoc("MQGram.ReadAfterAction.Desc", lang),
        settings.readAfterAction))
    id += 1

    entries.append(.footer(mqLoc("MQGram.Footer", lang)))

    return entries
}

public func mqgramSettingsController(context: AccountContext) -> ViewController {
    let updatePromise = ValuePromise<Bool>(true, ignoreRepeated: false)

    let arguments = MQGramArguments(toggleSetting: { key, value in
        MQGramSettings.shared.setBool(value, for: key)
        updatePromise.set(true)
    })

    let signal = combineLatest(context.sharedContext.presentationData, updatePromise.get())
    |> map { presentationData, _ -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let lang = presentationData.strings.baseLanguageCode
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text("MQGram"),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)
        )

        let entries = mqgramEntries(settings: MQGramSettings.shared, lang: lang)

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
