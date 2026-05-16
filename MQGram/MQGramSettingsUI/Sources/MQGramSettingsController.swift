// MARK: MQGram
import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramPresentationData
import ItemListUI
import PresentationDataUtils
import AccountContext

private final class MQGramArguments {
    let toggleSetting: (MQGramSettings.Key, Bool) -> Void

    init(toggleSetting: @escaping (MQGramSettings.Key, Bool) -> Void) {
        self.toggleSetting = toggleSetting
    }
}

private enum MQGramSection: Int32 {
    case intro
    case stable
    case ghost
    case beta
    case hideButtons
    case footer
}

private enum MQGramEntry: ItemListNodeEntry {
    case header(Int32, String)
    case info(Int32, Int32, String)
    case toggle(Int32, MQGramSection, MQGramSettings.Key, String, String?, Bool)
    case footer(String)

    var section: ItemListSectionId {
        switch self {
        case let .header(section, _):
            return section
        case let .info(section, _, _):
            return section
        case .footer:
            return MQGramSection.footer.rawValue
        case let .toggle(_, section, _, _, _, _):
            return section.rawValue
        }
    }

    var stableId: Int32 {
        switch self {
        case let .header(section, _):
            return section * 1000
        case let .info(section, id, _):
            return section * 1000 + id
        case let .toggle(id, section, _, _, _, _):
            return section.rawValue * 1000 + 100 + id
        case .footer:
            return 9999
        }
    }

    static func ==(lhs: MQGramEntry, rhs: MQGramEntry) -> Bool {
        switch lhs {
        case let .header(lSection, lText):
            if case let .header(rSection, rText) = rhs, lSection == rSection, lText == rText { return true } else { return false }
        case let .info(lSection, lId, lText):
            if case let .info(rSection, rId, rText) = rhs, lSection == rSection, lId == rId, lText == rText { return true } else { return false }
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
        case let .header(section, text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: section)
        case let .info(section, _, text):
            return ItemListTextItem(presentationData: presentationData, text: .markdown(text), sectionId: section)
        case let .footer(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: MQGramSection.footer.rawValue)
        case let .toggle(_, section, key, title, text, value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                systemStyle: .glass,
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

private struct MQGramText {
    let hero: String
    let stable: String
    let stableInfo: String
    let ghost: String
    let ghostInfo: String
    let beta: String
    let betaInfo: String
    let antiSelfDestructTitle: String
    let antiSelfDestructText: String
    let antiRevokeTitle: String
    let antiRevokeText: String
    let ghostModeTitle: String
    let ghostModeText: String
    let ghostReadReceiptsTitle: String
    let ghostReadReceiptsText: String
    let ghostStoriesTitle: String
    let ghostStoriesText: String
    let ghostContentReadsTitle: String
    let ghostContentReadsText: String
    let ghostPersonalActionsTitle: String
    let ghostPersonalActionsText: String
    let ghostScreenshotsTitle: String
    let ghostScreenshotsText: String
    let ghostDraftsTitle: String
    let ghostDraftsText: String
    let ghostEmojiInteractionsTitle: String
    let ghostEmojiInteractionsText: String
    let ghostReactionsTitle: String
    let ghostReactionsText: String
    let ghostStickerActivityTitle: String
    let ghostStickerActivityText: String
    let ghostOnlineStatusTitle: String
    let ghostOnlineStatusText: String
    let ghostTypingActionsTitle: String
    let ghostTypingActionsText: String
    let customIndicatorsTitle: String
    let customIndicatorsText: String
    let contentProtectionTitle: String
    let contentProtectionText: String
    let antiEditTitle: String
    let antiEditText: String
    let disableAdsTitle: String
    let disableAdsText: String
    let readAfterActionTitle: String
    let readAfterActionText: String
    let localPremiumTitle: String
    let localPremiumText: String
    let hideButtonsSection: String
    let hideButtonsInfo: String
    let hideContactsTitle: String
    let hideContactsText: String
    let hideCallsTitle: String
    let hideCallsText: String
    let hideSavedMessagesTitle: String
    let hideSavedMessagesText: String
    let hideRecentCallsTitle: String
    let hideRecentCallsText: String
    let hideDevicesTitle: String
    let hideDevicesText: String
    let hideChatFoldersTitle: String
    let hideChatFoldersText: String
    let hideNotificationsTitle: String
    let hideNotificationsText: String
    let hidePrivacyTitle: String
    let hidePrivacyText: String
    let hideDataStorageTitle: String
    let hideDataStorageText: String
    let hideAppearanceTitle: String
    let hideAppearanceText: String
    let hideLanguageTitle: String
    let hideLanguageText: String
    let hidePowerSavingTitle: String
    let hidePowerSavingText: String
    let footer: String
}

private func mqgramText(_ languageCode: String) -> MQGramText {
    if languageCode.lowercased().hasPrefix("ru") {
        return MQGramText(
            hero: "**MQGram Control Center**\n\nПлавные переключатели, разделы и защитные функции собраны в одном месте. Включай только то, что нужно — всё применяется через безопасные системные настройки Telegram.",
            stable: "ОСНОВНЫЕ ФУНКЦИИ",
            stableInfo: "Базовая защита сообщений и медиа без лишнего визуального шума.",
            ghost: "ПРИЗРАК · НЕВИДИМОСТЬ",
            ghostInfo: "Тихий режим: чтение, истории, действия, онлайн, реакции и черновики без лишних следов.",
            beta: "ЭКСПЕРИМЕНТЫ",
            betaInfo: "Функции с глубокими hooks. Если что-то ведёт себя странно — отключи конкретный переключатель.",
            antiSelfDestructTitle: "Анти-самоуничтожение",
            antiSelfDestructText: "Сохраняет исчезающие фото/видео и убирает таймеры.",
            antiRevokeTitle: "Анти-удаление",
            antiRevokeText: "Сообщения не удаляются у тебя, а удалённые помечаются значком.",
            ghostModeTitle: "Режим призрака",
            ghostModeText: "Главный переключатель для скрытого чтения.",
            ghostReadReceiptsTitle: "Не отправлять прочитано",
            ghostReadReceiptsText: "Блокирует прочтение даже после отправки текста, фото, видео или файла.",
            ghostStoriesTitle: "Скрытый просмотр историй",
            ghostStoriesText: "Не отправляет отметку просмотра историй.",
            ghostContentReadsTitle: "Не читать медиа",
            ghostContentReadsText: "Не отправляет отметки для голосовых, видео, файлов и другого контента.",
            ghostPersonalActionsTitle: "Скрывать личные отметки",
            ghostPersonalActionsText: "Не отправляет прочтение личных упоминаний, реакций и голосований.",
            ghostScreenshotsTitle: "Скрывать скриншоты",
            ghostScreenshotsText: "Не отправляет уведомления о скриншотах в чатах.",
            ghostDraftsTitle: "Скрывать черновики",
            ghostDraftsText: "Не синхронизирует набранный текст как облачный черновик.",
            ghostEmojiInteractionsTitle: "Скрывать emoji-действия",
            ghostEmojiInteractionsText: "Не отправляет emoji interaction и seen interaction.",
            ghostReactionsTitle: "Скрывать реакции",
            ghostReactionsText: "Не отправляет реакции на сообщения и истории.",
            ghostStickerActivityTitle: "Скрывать стикеры",
            ghostStickerActivityText: "Не сохраняет недавние стикеры и просмотр новых наборов.",
            ghostOnlineStatusTitle: "Скрывать онлайн",
            ghostOnlineStatusText: "Не отправляет статус онлайн, пока включён призрак.",
            ghostTypingActionsTitle: "Скрывать действия",
            ghostTypingActionsText: "Скрывает набор текста, запись голоса, загрузку фото/видео.",
            customIndicatorsTitle: "Свои индикаторы",
            customIndicatorsText: "Добавляет метки к перехваченному исчезающему контенту.",
            contentProtectionTitle: "Обход защиты контента",
            contentProtectionText: "Пересылка и сохранение медиа из защищённых каналов и чатов.",
            antiEditTitle: "Анти-редактирование",
            antiEditText: "Показывает оригинальный текст отредактированных сообщений.",
            disableAdsTitle: "Отключить рекламу",
            disableAdsText: "Убирает спонсорские сообщения и рекламу из каналов.",
            readAfterActionTitle: "Прочитать после действий",
            readAfterActionText: "Не отправляет прочитано (2 галочки) на сервер, пока ты не ответишь в чате.",
            localPremiumTitle: "Локальный премиум",
            localPremiumText: "Показывает премиум-статус локально без покупки подписки.",
            hideButtonsSection: "СКРЫТЬ КНОПКИ",
            hideButtonsInfo: "Скрывай ненужные вкладки и пункты в настройках.",
            hideContactsTitle: "Скрыть контакты",
            hideContactsText: "Убирает вкладку контактов из панели навигации.",
            hideCallsTitle: "Скрыть звонки (вкладка)",
            hideCallsText: "Убирает вкладку звонков из панели навигации.",
            hideSavedMessagesTitle: "Скрыть избранное",
            hideSavedMessagesText: "Убирает пункт Избранное из настроек.",
            hideRecentCallsTitle: "Скрыть недавние звонки",
            hideRecentCallsText: "Убирает пункт Недавние звонки из настроек.",
            hideDevicesTitle: "Скрыть устройства",
            hideDevicesText: "Убирает пункт Устройства из настроек.",
            hideChatFoldersTitle: "Скрыть папки с чатами",
            hideChatFoldersText: "Убирает пункт Папки с чатами из настроек.",
            hideNotificationsTitle: "Скрыть уведомления и звуки",
            hideNotificationsText: "Убирает пункт Уведомления и звуки из настроек.",
            hidePrivacyTitle: "Скрыть конфиденциальность",
            hidePrivacyText: "Убирает пункт Конфиденциальность из настроек.",
            hideDataStorageTitle: "Скрыть данные и память",
            hideDataStorageText: "Убирает пункт Данные и память из настроек.",
            hideAppearanceTitle: "Скрыть оформление",
            hideAppearanceText: "Убирает пункт Оформление из настроек.",
            hideLanguageTitle: "Скрыть язык",
            hideLanguageText: "Убирает пункт Язык из настроек.",
            hidePowerSavingTitle: "Скрыть энергосбережение",
            hidePowerSavingText: "Убирает пункт Энергосбережение из настроек.",
            footer: "Функции MQGram. Для части изменений перезапусти приложение."
        )
    }
    return MQGramText(
        hero: "**MQGram Control Center**\n\nSmooth switches, clear sections, and privacy controls in one place. Enable only what you need — everything is stored via Telegram-safe settings.",
        stable: "CORE FEATURES",
        stableInfo: "Base message and media protection without extra visual noise.",
        ghost: "GHOST · INVISIBILITY",
        ghostInfo: "Quiet mode: reads, stories, actions, online, reactions, and drafts with fewer traces.",
        beta: "EXPERIMENTS",
        betaInfo: "Deep-hook features. If something behaves oddly, disable only that switch.",
        antiSelfDestructTitle: "Anti-Self-Destruct",
        antiSelfDestructText: "Save disappearing photos/videos and remove timers.",
        antiRevokeTitle: "Anti-Revoke",
        antiRevokeText: "Messages are never deleted for you. Deleted messages are marked.",
        ghostModeTitle: "Ghost Mode",
        ghostModeText: "Master switch for hidden reading.",
        ghostReadReceiptsTitle: "Hide Read Receipts",
        ghostReadReceiptsText: "Blocks read receipts even after sending text, photos, videos, or files.",
        ghostStoriesTitle: "Hidden Story Views",
        ghostStoriesText: "Do not send story view receipts.",
        ghostContentReadsTitle: "Hide Media Reads",
        ghostContentReadsText: "Do not send consumed-content receipts for voice, video, files, and media.",
        ghostPersonalActionsTitle: "Hide Personal Marks",
        ghostPersonalActionsText: "Do not send seen marks for personal mentions, reactions, and poll votes.",
        ghostScreenshotsTitle: "Hide Screenshots",
        ghostScreenshotsText: "Do not send screenshot notifications in chats.",
        ghostDraftsTitle: "Hide Drafts",
        ghostDraftsText: "Do not sync typed text as a cloud draft.",
        ghostEmojiInteractionsTitle: "Hide Emoji Interactions",
        ghostEmojiInteractionsText: "Do not send emoji interaction and seen interaction actions.",
        ghostReactionsTitle: "Hide Reactions",
        ghostReactionsText: "Do not send reactions to messages and stories.",
        ghostStickerActivityTitle: "Hide Sticker Activity",
        ghostStickerActivityText: "Do not save recent stickers or seen featured packs.",
        ghostOnlineStatusTitle: "Hide Online Status",
        ghostOnlineStatusText: "Do not send online presence while ghost is enabled.",
        ghostTypingActionsTitle: "Hide Typing Actions",
        ghostTypingActionsText: "Hides typing, voice recording, photo/video uploads.",
        customIndicatorsTitle: "Custom Indicators",
        customIndicatorsText: "Adds labels to intercepted disappearing content.",
        contentProtectionTitle: "Content Protection Bypass",
        contentProtectionText: "Forward and save media from restricted channels and chats.",
        antiEditTitle: "Anti-Edit",
        antiEditText: "See original content of edited messages.",
        disableAdsTitle: "Disable Ads",
        disableAdsText: "Remove sponsored messages and ads from channels.",
        readAfterActionTitle: "Read After Actions",
        readAfterActionText: "Do not send read receipts (2 checkmarks) to server until you reply in the chat.",
        localPremiumTitle: "Local Premium",
        localPremiumText: "Shows premium status locally without purchasing a subscription.",
        hideButtonsSection: "HIDE BUTTONS",
        hideButtonsInfo: "Hide unwanted tabs and settings menu items.",
        hideContactsTitle: "Hide Contacts",
        hideContactsText: "Removes the Contacts tab from the navigation bar.",
        hideCallsTitle: "Hide Calls (tab)",
        hideCallsText: "Removes the Calls tab from the navigation bar.",
        hideSavedMessagesTitle: "Hide Saved Messages",
        hideSavedMessagesText: "Removes Saved Messages from settings.",
        hideRecentCallsTitle: "Hide Recent Calls",
        hideRecentCallsText: "Removes Recent Calls from settings.",
        hideDevicesTitle: "Hide Devices",
        hideDevicesText: "Removes Devices from settings.",
        hideChatFoldersTitle: "Hide Chat Folders",
        hideChatFoldersText: "Removes Chat Folders from settings.",
        hideNotificationsTitle: "Hide Notifications & Sounds",
        hideNotificationsText: "Removes Notifications & Sounds from settings.",
        hidePrivacyTitle: "Hide Privacy",
        hidePrivacyText: "Removes Privacy & Security from settings.",
        hideDataStorageTitle: "Hide Data & Storage",
        hideDataStorageText: "Removes Data & Storage from settings.",
        hideAppearanceTitle: "Hide Appearance",
        hideAppearanceText: "Removes Appearance from settings.",
        hideLanguageTitle: "Hide Language",
        hideLanguageText: "Removes Language from settings.",
        hidePowerSavingTitle: "Hide Power Saving",
        hidePowerSavingText: "Removes Power Saving from settings.",
        footer: "MQGram features. Restart the app to apply some changes."
    )
}

private func mqgramEntries(settings: MQGramSettings, strings: PresentationStrings) -> [MQGramEntry] {
    let text = mqgramText(strings.baseLanguageCode)
    var entries: [MQGramEntry] = []
    var id: Int32 = 1

    entries.append(.info(MQGramSection.intro.rawValue, 1, text.hero))

    entries.append(.header(MQGramSection.stable.rawValue, text.stable))
    entries.append(.info(MQGramSection.stable.rawValue, 1, text.stableInfo))
    entries.append(.toggle(id, .stable, .antiSelfDestruct, text.antiSelfDestructTitle, text.antiSelfDestructText, settings.antiSelfDestruct))
    id += 1
    entries.append(.toggle(id, .stable, .antiRevoke, text.antiRevokeTitle, text.antiRevokeText, settings.antiRevoke))
    id += 1
    entries.append(.toggle(id, .stable, .customIndicators, text.customIndicatorsTitle, text.customIndicatorsText, settings.customIndicators))

    entries.append(.header(MQGramSection.ghost.rawValue, text.ghost))
    entries.append(.info(MQGramSection.ghost.rawValue, 1, text.ghostInfo))
    id = 101
    entries.append(.toggle(id, .ghost, .ghostMode, text.ghostModeTitle, text.ghostModeText, settings.ghostMode))
    id += 1
    entries.append(.toggle(id, .ghost, .ghostReadReceipts, text.ghostReadReceiptsTitle, text.ghostReadReceiptsText, settings.ghostReadReceipts))
    id += 1
    entries.append(.toggle(id, .ghost, .ghostStories, text.ghostStoriesTitle, text.ghostStoriesText, settings.ghostStories))
    id += 1
    entries.append(.toggle(id, .ghost, .ghostContentReads, text.ghostContentReadsTitle, text.ghostContentReadsText, settings.ghostContentReads))
    id += 1
    entries.append(.toggle(id, .ghost, .ghostPersonalActions, text.ghostPersonalActionsTitle, text.ghostPersonalActionsText, settings.ghostPersonalActions))
    id += 1
    entries.append(.toggle(id, .ghost, .ghostScreenshots, text.ghostScreenshotsTitle, text.ghostScreenshotsText, settings.ghostScreenshots))
    id += 1
    entries.append(.toggle(id, .ghost, .ghostDrafts, text.ghostDraftsTitle, text.ghostDraftsText, settings.ghostDrafts))
    id += 1
    entries.append(.toggle(id, .ghost, .ghostEmojiInteractions, text.ghostEmojiInteractionsTitle, text.ghostEmojiInteractionsText, settings.ghostEmojiInteractions))
    id += 1
    entries.append(.toggle(id, .ghost, .ghostReactions, text.ghostReactionsTitle, text.ghostReactionsText, settings.ghostReactions))
    id += 1
    entries.append(.toggle(id, .ghost, .ghostStickerActivity, text.ghostStickerActivityTitle, text.ghostStickerActivityText, settings.ghostStickerActivity))
    id += 1
    entries.append(.toggle(id, .ghost, .ghostOnlineStatus, text.ghostOnlineStatusTitle, text.ghostOnlineStatusText, settings.ghostOnlineStatus))
    id += 1
    entries.append(.toggle(id, .ghost, .ghostTypingActions, text.ghostTypingActionsTitle, text.ghostTypingActionsText, settings.ghostTypingActions))

    entries.append(.header(MQGramSection.beta.rawValue, text.beta))
    entries.append(.info(MQGramSection.beta.rawValue, 1, text.betaInfo))
    id = 1001
    entries.append(.toggle(id, .beta, .contentProtectionBypass, text.contentProtectionTitle, text.contentProtectionText, settings.contentProtectionBypass))
    id += 1
    entries.append(.toggle(id, .beta, .antiEdit, text.antiEditTitle, text.antiEditText, settings.antiEdit))
    id += 1
    entries.append(.toggle(id, .beta, .disableAds, text.disableAdsTitle, text.disableAdsText, settings.disableAds))
    id += 1
    entries.append(.toggle(id, .beta, .readAfterAction, text.readAfterActionTitle, text.readAfterActionText, settings.readAfterAction))
    id += 1
    entries.append(.toggle(id, .beta, .localPremium, text.localPremiumTitle, text.localPremiumText, settings.localPremium))

    entries.append(.header(MQGramSection.hideButtons.rawValue, text.hideButtonsSection))
    entries.append(.info(MQGramSection.hideButtons.rawValue, 1, text.hideButtonsInfo))
    id = 2001
    entries.append(.toggle(id, .hideButtons, .hideContacts, text.hideContactsTitle, text.hideContactsText, settings.hideContacts))
    id += 1
    entries.append(.toggle(id, .hideButtons, .hideCalls, text.hideCallsTitle, text.hideCallsText, settings.hideCalls))
    id += 1
    entries.append(.toggle(id, .hideButtons, .hideSavedMessages, text.hideSavedMessagesTitle, text.hideSavedMessagesText, settings.hideSavedMessages))
    id += 1
    entries.append(.toggle(id, .hideButtons, .hideRecentCalls, text.hideRecentCallsTitle, text.hideRecentCallsText, settings.hideRecentCalls))
    id += 1
    entries.append(.toggle(id, .hideButtons, .hideDevices, text.hideDevicesTitle, text.hideDevicesText, settings.hideDevices))
    id += 1
    entries.append(.toggle(id, .hideButtons, .hideChatFolders, text.hideChatFoldersTitle, text.hideChatFoldersText, settings.hideChatFolders))
    id += 1
    entries.append(.toggle(id, .hideButtons, .hideNotifications, text.hideNotificationsTitle, text.hideNotificationsText, settings.hideNotifications))
    id += 1
    entries.append(.toggle(id, .hideButtons, .hidePrivacy, text.hidePrivacyTitle, text.hidePrivacyText, settings.hidePrivacy))
    id += 1
    entries.append(.toggle(id, .hideButtons, .hideDataStorage, text.hideDataStorageTitle, text.hideDataStorageText, settings.hideDataStorage))
    id += 1
    entries.append(.toggle(id, .hideButtons, .hideAppearance, text.hideAppearanceTitle, text.hideAppearanceText, settings.hideAppearance))
    id += 1
    entries.append(.toggle(id, .hideButtons, .hideLanguage, text.hideLanguageTitle, text.hideLanguageText, settings.hideLanguage))
    id += 1
    entries.append(.toggle(id, .hideButtons, .hidePowerSaving, text.hidePowerSavingTitle, text.hidePowerSavingText, settings.hidePowerSaving))

    entries.append(.footer(text.footer))
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
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text("MQGram"),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)
        )

        let entries = mqgramEntries(settings: MQGramSettings.shared, strings: presentationData.strings)

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
