// MARK: MQGram
import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramPresentationData
import ItemListUI
import PresentationDataUtils
import AccountContext
import MQDeletedMessagesUI
import MQGramDatabase

// MARK: - Arguments

private final class MQGramArguments {
    let toggleSetting: (MQGramSettings.Key, Bool) -> Void
    let openUrl: (String, Bool) -> Void
    let openRecycleBin: () -> Void
    let openDatabaseViewer: () -> Void
    let toggleDatabaseCollection: (Bool) -> Void
    let resetAllSettings: () -> Void
    let enableAllGhost: () -> Void
    let disableAllGhost: () -> Void
    let showGhostStatus: () -> Void
    let enableAllHide: () -> Void
    let disableAllHide: () -> Void
    let showFeatureInfo: (String) -> Void

    init(
        toggleSetting: @escaping (MQGramSettings.Key, Bool) -> Void,
        openUrl: @escaping (String, Bool) -> Void,
        openRecycleBin: @escaping () -> Void,
        openDatabaseViewer: @escaping () -> Void,
        toggleDatabaseCollection: @escaping (Bool) -> Void,
        resetAllSettings: @escaping () -> Void,
        enableAllGhost: @escaping () -> Void,
        disableAllGhost: @escaping () -> Void,
        showGhostStatus: @escaping () -> Void,
        enableAllHide: @escaping () -> Void,
        disableAllHide: @escaping () -> Void,
        showFeatureInfo: @escaping (String) -> Void
    ) {
        self.toggleSetting = toggleSetting
        self.openUrl = openUrl
        self.openRecycleBin = openRecycleBin
        self.openDatabaseViewer = openDatabaseViewer
        self.toggleDatabaseCollection = toggleDatabaseCollection
        self.resetAllSettings = resetAllSettings
        self.enableAllGhost = enableAllGhost
        self.disableAllGhost = disableAllGhost
        self.showGhostStatus = showGhostStatus
        self.enableAllHide = enableAllHide
        self.disableAllHide = disableAllHide
        self.showFeatureInfo = showFeatureInfo
    }
}

// MARK: - Entries

private enum MQGramEntry: ItemListNodeEntry {
    case info(Int32, String)
    case toggle(Int32, MQGramSettings.Key, String, String?, Bool)
    case link(Int32, String, String, Bool, UIImage?)
    case action(Int32, String, UIImage?)
    case databaseAction(Int32, String, UIImage?)
    case databaseToggle(Int32, String, Bool)
    case bulkAction(Int32, String, String)
    case statusRow(Int32, String, String)
    case footer(Int32, String)

    var section: ItemListSectionId {
        switch self {
        case .footer:
            return 1
        default:
            return 0
        }
    }

    var sortOrder: Int32 {
        return stableId
    }

    var stableId: Int32 {
        switch self {
        case let .info(id, _):
            return id
        case let .toggle(id, _, _, _, _):
            return id
        case let .link(id, _, _, _, _):
            return id
        case let .action(id, _, _):
            return id
        case let .databaseAction(id, _, _):
            return id
        case let .databaseToggle(id, _, _):
            return id
        case let .bulkAction(id, _, _):
            return id
        case let .statusRow(id, _, _):
            return id
        case let .footer(id, _):
            return id
        }
    }

    static func ==(lhs: MQGramEntry, rhs: MQGramEntry) -> Bool {
        switch lhs {
        case let .info(lId, lText):
            if case let .info(rId, rText) = rhs, lId == rId, lText == rText { return true } else { return false }
        case let .toggle(lId, lKey, lTitle, lText, lValue):
            if case let .toggle(rId, rKey, rTitle, rText, rValue) = rhs,
               lId == rId, lKey == rKey, lTitle == rTitle, lText == rText, lValue == rValue { return true } else { return false }
        case let .link(lId, lTitle, lUrl, lInTg, _):
            if case let .link(rId, rTitle, rUrl, rInTg, _) = rhs, lId == rId, lTitle == rTitle, lUrl == rUrl, lInTg == rInTg { return true } else { return false }
        case let .action(lId, lTitle, _):
            if case let .action(rId, rTitle, _) = rhs, lId == rId, lTitle == rTitle { return true } else { return false }
        case let .databaseAction(lId, lTitle, _):
            if case let .databaseAction(rId, rTitle, _) = rhs, lId == rId, lTitle == rTitle { return true } else { return false }
        case let .databaseToggle(lId, lTitle, lValue):
            if case let .databaseToggle(rId, rTitle, rValue) = rhs, lId == rId, lTitle == rTitle, lValue == rValue { return true } else { return false }
        case let .bulkAction(lId, lTitle, lType):
            if case let .bulkAction(rId, rTitle, rType) = rhs, lId == rId, lTitle == rTitle, lType == rType { return true } else { return false }
        case let .statusRow(lId, lTitle, lValue):
            if case let .statusRow(rId, rTitle, rValue) = rhs, lId == rId, lTitle == rTitle, lValue == rValue { return true } else { return false }
        case let .footer(lId, lText):
            if case let .footer(rId, rText) = rhs, lId == rId, lText == rText { return true } else { return false }
        }
    }

    static func <(lhs: MQGramEntry, rhs: MQGramEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let args = arguments as! MQGramArguments
        switch self {
        case let .info(_, text):
            return ItemListTextItem(presentationData: presentationData, text: .markdown(text), sectionId: self.section)
        case let .toggle(_, key, title, text, value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: title,
                text: text,
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { newValue in
                    args.toggleSetting(key, newValue)
                }
            )
        case let .link(_, title, url, inTelegram, icon):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                icon: icon,
                title: title,
                label: "",
                sectionId: self.section,
                style: .blocks,
                disclosureStyle: .arrow,
                action: {
                    args.openUrl(url, inTelegram)
                }
            )
        case let .action(_, title, icon):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                icon: icon,
                title: title,
                label: "",
                sectionId: self.section,
                style: .blocks,
                disclosureStyle: .arrow,
                action: {
                    args.openRecycleBin()
                }
            )
        case let .databaseAction(_, title, icon):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                icon: icon,
                title: title,
                label: "",
                sectionId: self.section,
                style: .blocks,
                disclosureStyle: .arrow,
                action: {
                    args.openDatabaseViewer()
                }
            )
        case let .databaseToggle(_, title, value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: title,
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { newValue in
                    args.toggleDatabaseCollection(newValue)
                }
            )
        case let .bulkAction(_, title, actionType):
            return ItemListActionItem(
                presentationData: presentationData,
                title: title,
                kind: actionType == "destructive" ? .destructive : .generic,
                alignment: .center,
                sectionId: self.section,
                style: .blocks,
                action: {
                    switch actionType {
                    case "enableAllGhost":
                        args.enableAllGhost()
                    case "disableAllGhost":
                        args.disableAllGhost()
                    case "showGhostStatus":
                        args.showGhostStatus()
                    case "enableAllHide":
                        args.enableAllHide()
                    case "disableAllHide":
                        args.disableAllHide()
                    case "resetAll":
                        args.resetAllSettings()
                    default:
                        break
                    }
                }
            )
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
        case let .footer(_, text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        }
    }
}

// MARK: - Localized Text

private struct MQGramText {
    let ghostInfo: String
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
    let readAfterActionsTitle: String
    let readAfterActionsText: String
    let stableInfo: String
    let antiSelfDestructTitle: String
    let antiSelfDestructText: String
    let antiRevokeTitle: String
    let antiRevokeText: String
    let customIndicatorsTitle: String
    let customIndicatorsText: String
    let redDeleteIconTitle: String
    let redDeleteIconText: String
    let betaInfo: String
    let contentProtectionTitle: String
    let contentProtectionText: String
    let antiEditTitle: String
    let antiEditText: String
    let disableAdsTitle: String
    let disableAdsText: String
    let businessFeaturesTitle: String
    let businessFeaturesText: String
    let otherInfo: String
    let localPremiumTitle: String
    let localPremiumText: String
    let unlimitedAccountsTitle: String
    let unlimitedAccountsText: String
    let hidePhoneNumberTitle: String
    let hidePhoneNumberText: String
    let confirmCallsTitle: String
    let confirmCallsText: String
    let silentMessagesTitle: String
    let silentMessagesText: String
    let pinWalletTabTitle: String
    let pinWalletTabText: String
    let hideInfo: String
    let hideNavigationBarTitle: String
    let hideNavigationBarText: String
    let hideFavoriteChatsTitle: String
    let hideFavoriteChatsText: String
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
    let hideDataTitle: String
    let hideDataText: String
    let hideAppearanceTitle: String
    let hideAppearanceText: String
    let hideLanguageTitle: String
    let hideLanguageText: String
    let hideStickersTitle: String
    let hideStickersText: String
    let hidePowerSavingTitle: String
    let hidePowerSavingText: String
    let devInfo: String
    let devDeveloper: String
    let devChannel: String
    let devBot: String
    let databaseInfo: String
    let databaseViewerTitle: String
    let databaseCollectionTitle: String
    let databaseCollectionText: String
    let enableAllGhostTitle: String
    let disableAllGhostTitle: String
    let ghostStatusTitle: String
    let enableAllHideTitle: String
    let disableAllHideTitle: String
    let resetAllTitle: String
    let recycleBinTitle: String
    let footer: String
}

private func mqgramText(_ languageCode: String) -> MQGramText {
    if languageCode.lowercased().hasPrefix("ru") {
        return MQGramText(
            ghostInfo: "Тихий режим: чтение, истории, действия, онлайн, реакции и черновики без лишних следов.",
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
            readAfterActionsTitle: "Читать после действий",
            readAfterActionsText: "Отмечает сообщения прочитанными только после твоих действий в чате.",
            stableInfo: "Базовая защита сообщений и медиа без лишнего визуального шума.",
            antiSelfDestructTitle: "Анти-самоуничтожение",
            antiSelfDestructText: "Сохраняет исчезающие фото/видео и убирает таймеры.",
            antiRevokeTitle: "Анти-удаление",
            antiRevokeText: "Сообщения не удаляются у тебя, а удалённые помечаются значком.",
            customIndicatorsTitle: "Свои индикаторы",
            customIndicatorsText: "Добавляет метки к перехваченному исчезающему контенту.",
            redDeleteIconTitle: "Красная корзина",
            redDeleteIconText: "Показывает красную иконку корзины рядом с сообщениями при удалении.",
            betaInfo: "Функции с глубокими hooks. Если что-то ведёт себя странно — отключи конкретный переключатель.",
            contentProtectionTitle: "Обход защиты контента",
            contentProtectionText: "Пересылка и сохранение медиа из защищённых каналов и чатов.",
            antiEditTitle: "Анти-редактирование",
            antiEditText: "Показывает оригинальный текст отредактированных сообщений.",
            disableAdsTitle: "Отключить рекламу",
            disableAdsText: "Убирает спонсорские сообщения и рекламу из каналов.",
            businessFeaturesTitle: "Telegram для бизнеса",
            businessFeaturesText: "Активирует бизнес-функции профиля локально.",
            otherInfo: "Дополнительные функции для расширенного управления приложением.",
            localPremiumTitle: "Локальный Премиум",
            localPremiumText: "Активирует премиум-функции интерфейса локально без подписки.",
            unlimitedAccountsTitle: "Безлимитные аккаунты",
            unlimitedAccountsText: "Снимает ограничение на количество добавленных аккаунтов.",
            hidePhoneNumberTitle: "Скрыть номер телефона",
            hidePhoneNumberText: "Прячет твой номер телефона в профиле и настройках.",
            confirmCallsTitle: "Подтверждение звонков",
            confirmCallsText: "Запрашивает подтверждение перед началом голосового или видеозвонка.",
            silentMessagesTitle: "Тихие сообщения",
            silentMessagesText: "Отправляет сообщения без звукового уведомления по умолчанию.",
            pinWalletTabTitle: "Фиксатор вкладки Кошелёк",
            pinWalletTabText: "Закрепляет вкладку Кошелёк рядом с настройками.",
            hideInfo: "Скрывай элементы интерфейса, которыми не пользуешься.",
            hideNavigationBarTitle: "Скрыть бар навигации",
            hideNavigationBarText: "Прячет нижнюю панель (Контакты, Чаты, Настройки, Поиск).",
            hideFavoriteChatsTitle: "Скрыть Избранное",
            hideFavoriteChatsText: "Прячет пункт Избранное в настройках.",
            hideRecentCallsTitle: "Скрыть Недавние звонки",
            hideRecentCallsText: "Прячет пункт Недавние звонки в настройках.",
            hideDevicesTitle: "Скрыть Устройства",
            hideDevicesText: "Прячет пункт Устройства в настройках.",
            hideChatFoldersTitle: "Скрыть Папки с чатами",
            hideChatFoldersText: "Прячет пункт Папки с чатами в настройках.",
            hideNotificationsTitle: "Скрыть Уведомления и звуки",
            hideNotificationsText: "Прячет пункт Уведомления и звуки в настройках.",
            hidePrivacyTitle: "Скрыть Конфиденциальность",
            hidePrivacyText: "Прячет пункт Конфиденциальность в настройках.",
            hideDataTitle: "Скрыть Данные и хранилище",
            hideDataText: "Прячет пункт Данные и хранилище в настройках.",
            hideAppearanceTitle: "Скрыть Оформление",
            hideAppearanceText: "Прячет пункт Оформление в настройках.",
            hideLanguageTitle: "Скрыть Язык",
            hideLanguageText: "Прячет пункт Язык в настройках.",
            hideStickersTitle: "Скрыть Стикеры и emoji",
            hideStickersText: "Прячет пункт Стикеры и emoji в настройках.",
            hidePowerSavingTitle: "Скрыть Энергосбережение",
            hidePowerSavingText: "Прячет пункт Энергосбережение в настройках.",
            devInfo: "Информация о разработчике и полезные ссылки.",
            devDeveloper: "Разработчик",
            devChannel: "Канал StivenVPN",
            devBot: "Бот StivenVPN",
            databaseInfo: "Просмотр базы данных MQGram в реальном времени.",
            databaseViewerTitle: "Просмотр базы данных",
            databaseCollectionTitle: "Сбор данных",
            databaseCollectionText: "Включает отправку событий и сообщений на сервер MQGram.",
            enableAllGhostTitle: "Включить все призрак-функции",
            disableAllGhostTitle: "Выключить все призрак-функции",
            ghostStatusTitle: "Статус режима призрака",
            enableAllHideTitle: "Скрыть все элементы",
            disableAllHideTitle: "Показать все элементы",
            resetAllTitle: "Сбросить все настройки",
            recycleBinTitle: "Корзина удалённых сообщений",
            footer: "Функции MQGram. Для части изменений перезапусти приложение."
        )
    }
    return MQGramText(
        ghostInfo: "Quiet mode: reads, stories, actions, online, reactions, and drafts with fewer traces.",
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
        readAfterActionsTitle: "Read After Actions",
        readAfterActionsText: "Mark messages as read only after you take action in chat.",
        stableInfo: "Base message and media protection without extra visual noise.",
        antiSelfDestructTitle: "Anti-Self-Destruct",
        antiSelfDestructText: "Save disappearing photos/videos and remove timers.",
        antiRevokeTitle: "Anti-Revoke",
        antiRevokeText: "Messages are never deleted for you. Deleted messages are marked.",
        customIndicatorsTitle: "Custom Indicators",
        customIndicatorsText: "Adds labels to intercepted disappearing content.",
        redDeleteIconTitle: "Red Delete Icon",
        redDeleteIconText: "Shows a red trash icon next to messages when deleting.",
        betaInfo: "Deep-hook features. If something behaves oddly, disable only that switch.",
        contentProtectionTitle: "Content Protection Bypass",
        contentProtectionText: "Forward and save media from restricted channels and chats.",
        antiEditTitle: "Anti-Edit",
        antiEditText: "See original content of edited messages.",
        disableAdsTitle: "Disable Ads",
        disableAdsText: "Remove sponsored messages and ads from channels.",
        businessFeaturesTitle: "Telegram for Business",
        businessFeaturesText: "Enable Business profile features locally.",
        otherInfo: "Extra features for extended app control.",
        localPremiumTitle: "Local Premium",
        localPremiumText: "Activates premium UI features locally without a subscription.",
        unlimitedAccountsTitle: "Unlimited Accounts",
        unlimitedAccountsText: "Removes the limit on the number of added accounts.",
        hidePhoneNumberTitle: "Hide Phone Number",
        hidePhoneNumberText: "Hides your phone number in profile and settings.",
        confirmCallsTitle: "Confirm Calls",
        confirmCallsText: "Ask for confirmation before starting a voice or video call.",
        silentMessagesTitle: "Silent Messages",
        silentMessagesText: "Send messages without sound notification by default.",
        pinWalletTabTitle: "Pin Wallet Tab",
        pinWalletTabText: "Pin the Wallet tab next to Settings.",
        hideInfo: "Hide UI elements you don't use.",
        hideNavigationBarTitle: "Hide Navigation Bar",
        hideNavigationBarText: "Hides the bottom bar (Contacts, Chats, Settings, Search).",
        hideFavoriteChatsTitle: "Hide Saved Messages",
        hideFavoriteChatsText: "Hides the Saved Messages entry in settings.",
        hideRecentCallsTitle: "Hide Recent Calls",
        hideRecentCallsText: "Hides the Recent Calls entry in settings.",
        hideDevicesTitle: "Hide Devices",
        hideDevicesText: "Hides the Devices entry in settings.",
        hideChatFoldersTitle: "Hide Chat Folders",
        hideChatFoldersText: "Hides the Chat Folders entry in settings.",
        hideNotificationsTitle: "Hide Notifications and Sounds",
        hideNotificationsText: "Hides the Notifications and Sounds entry in settings.",
        hidePrivacyTitle: "Hide Privacy",
        hidePrivacyText: "Hides the Privacy entry in settings.",
        hideDataTitle: "Hide Data and Storage",
        hideDataText: "Hides the Data and Storage entry in settings.",
        hideAppearanceTitle: "Hide Appearance",
        hideAppearanceText: "Hides the Appearance entry in settings.",
        hideLanguageTitle: "Hide Language",
        hideLanguageText: "Hides the Language entry in settings.",
        hideStickersTitle: "Hide Stickers and Emoji",
        hideStickersText: "Hides the Stickers and Emoji entry in settings.",
        hidePowerSavingTitle: "Hide Power Saving",
        hidePowerSavingText: "Hides the Power Saving entry in settings.",
        devInfo: "Developer info and useful links.",
        devDeveloper: "Developer",
        devChannel: "StivenVPN Channel",
        devBot: "StivenVPN Bot",
        databaseInfo: "View MQGram database in real-time.",
        databaseViewerTitle: "Database Viewer",
        databaseCollectionTitle: "Data Collection",
        databaseCollectionText: "Enable sending events and messages to MQGram server.",
        enableAllGhostTitle: "Enable All Ghost Features",
        disableAllGhostTitle: "Disable All Ghost Features",
        ghostStatusTitle: "Ghost Mode Status",
        enableAllHideTitle: "Hide All Elements",
        disableAllHideTitle: "Show All Elements",
        resetAllTitle: "Reset All Settings",
        recycleBinTitle: "Deleted Messages Recycle Bin",
        footer: "MQGram features. Restart the app to apply some changes."
    )
}

// MARK: - Icons

private func makeRoundedIcon(backgroundColor: UIColor, drawSymbol: @escaping (CGContext, CGRect) -> Void) -> UIImage {
    let size = CGSize(width: 29, height: 29)
    return UIGraphicsImageRenderer(size: size).image { ctx in
        let rect = CGRect(origin: .zero, size: size)
        backgroundColor.setFill()
        UIBezierPath(roundedRect: rect, cornerRadius: 7).fill()
        drawSymbol(ctx.cgContext, rect)
    }
}

private func makeGitHubIcon() -> UIImage {
    return makeRoundedIcon(backgroundColor: UIColor(white: 0.15, alpha: 1.0)) { _, rect in
        let cx = rect.midX
        let cy = rect.midY
        let r: CGFloat = 9.5
        UIColor.white.setFill()
        UIBezierPath(ovalIn: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)).fill()
        UIColor(white: 0.15, alpha: 1.0).setFill()
        UIBezierPath(ovalIn: CGRect(x: cx - 5.5, y: cy - 5, width: 11, height: 9)).fill()
        let body = UIBezierPath(roundedRect: CGRect(x: cx - 4, y: cy + 1.5, width: 8, height: 5), cornerRadius: 2)
        body.fill()
        let leftEar = UIBezierPath()
        leftEar.move(to: CGPoint(x: cx - 5.5, y: cy - 1))
        leftEar.addLine(to: CGPoint(x: cx - 8.5, y: cy - 8))
        leftEar.addLine(to: CGPoint(x: cx - 1.5, y: cy - 4.5))
        leftEar.close()
        leftEar.fill()
        let rightEar = UIBezierPath()
        rightEar.move(to: CGPoint(x: cx + 5.5, y: cy - 1))
        rightEar.addLine(to: CGPoint(x: cx + 8.5, y: cy - 8))
        rightEar.addLine(to: CGPoint(x: cx + 1.5, y: cy - 4.5))
        rightEar.close()
        rightEar.fill()
    }
}

private func makeTelegramIcon() -> UIImage {
    return makeRoundedIcon(backgroundColor: UIColor(red: 0.0, green: 0.53, blue: 0.80, alpha: 1.0)) { _, rect in
        let cx = rect.midX
        let cy = rect.midY
        UIColor.white.setFill()
        let plane = UIBezierPath()
        plane.move(to: CGPoint(x: cx - 8, y: cy))
        plane.addLine(to: CGPoint(x: cx + 8, y: cy - 6))
        plane.addLine(to: CGPoint(x: cx + 2, y: cy + 6))
        plane.addLine(to: CGPoint(x: cx - 1, y: cy + 1))
        plane.addLine(to: CGPoint(x: cx - 8, y: cy + 3))
        plane.close()
        plane.fill()
        UIColor(red: 0.0, green: 0.53, blue: 0.80, alpha: 1.0).setFill()
        let inner = UIBezierPath()
        inner.move(to: CGPoint(x: cx - 1, y: cy + 1))
        inner.addLine(to: CGPoint(x: cx + 4, y: cy - 3))
        inner.addLine(to: CGPoint(x: cx, y: cy + 4))
        inner.close()
        inner.fill()
    }
}

private func makeChannelIcon() -> UIImage {
    return makeRoundedIcon(backgroundColor: UIColor(red: 0.95, green: 0.45, blue: 0.20, alpha: 1.0)) { _, rect in
        let cx = rect.midX
        let cy = rect.midY
        UIColor.white.setFill()
        let horn = UIBezierPath()
        horn.move(to: CGPoint(x: cx - 6, y: cy - 2))
        horn.addLine(to: CGPoint(x: cx + 2, y: cy - 6))
        horn.addLine(to: CGPoint(x: cx + 2, y: cy + 6))
        horn.addLine(to: CGPoint(x: cx - 6, y: cy + 2))
        horn.close()
        horn.fill()
        UIBezierPath(ovalIn: CGRect(x: cx - 8, y: cy - 3, width: 6, height: 6)).fill()
        UIColor.white.setStroke()
        let wave1 = UIBezierPath()
        wave1.lineWidth = 1.5
        wave1.lineCapStyle = .round
        wave1.addArc(withCenter: CGPoint(x: cx + 2, y: cy), radius: 5, startAngle: -.pi / 3, endAngle: .pi / 3, clockwise: true)
        wave1.stroke()
        let wave2 = UIBezierPath()
        wave2.lineWidth = 1.5
        wave2.lineCapStyle = .round
        wave2.addArc(withCenter: CGPoint(x: cx + 2, y: cy), radius: 8, startAngle: -.pi / 4, endAngle: .pi / 4, clockwise: true)
        wave2.stroke()
    }
}

private func makeBotIcon() -> UIImage {
    return makeRoundedIcon(backgroundColor: UIColor(red: 0.69, green: 0.32, blue: 0.87, alpha: 1.0)) { _, rect in
        let cx = rect.midX
        let cy = rect.midY
        UIColor.white.setFill()
        UIBezierPath(roundedRect: CGRect(x: cx - 7, y: cy - 4, width: 14, height: 11), cornerRadius: 3).fill()
        UIColor(red: 0.69, green: 0.32, blue: 0.87, alpha: 1.0).setFill()
        UIBezierPath(ovalIn: CGRect(x: cx - 5, y: cy - 1, width: 4, height: 4)).fill()
        UIBezierPath(ovalIn: CGRect(x: cx + 1, y: cy - 1, width: 4, height: 4)).fill()
        UIColor.white.setFill()
        UIColor.white.setStroke()
        let antenna = UIBezierPath()
        antenna.lineWidth = 1.5
        antenna.move(to: CGPoint(x: cx, y: cy - 4))
        antenna.addLine(to: CGPoint(x: cx, y: cy - 8))
        antenna.stroke()
        UIBezierPath(ovalIn: CGRect(x: cx - 2, y: cy - 10, width: 4, height: 4)).fill()
    }
}

private func makeRecycleBinIcon() -> UIImage {
    return makeRoundedIcon(backgroundColor: UIColor(red: 0.90, green: 0.22, blue: 0.21, alpha: 1.0)) { _, rect in
        let cx = rect.midX
        let cy = rect.midY
        UIColor.white.setFill()
        UIColor.white.setStroke()
        let lid = UIBezierPath(roundedRect: CGRect(x: cx - 7, y: cy - 7, width: 14, height: 3), cornerRadius: 1)
        lid.fill()
        let body = UIBezierPath(roundedRect: CGRect(x: cx - 5.5, y: cy - 4, width: 11, height: 11), cornerRadius: 1.5)
        body.fill()
        UIColor(red: 0.90, green: 0.22, blue: 0.21, alpha: 1.0).setFill()
        for xOff: CGFloat in [-2.5, 0, 2.5] {
            UIBezierPath(roundedRect: CGRect(x: cx + xOff - 0.5, y: cy - 1, width: 1, height: 6), cornerRadius: 0.5).fill()
        }
    }
}

// MARK: - Entry Generation

// MARK: - Database Icon

private func makeDatabaseIcon() -> UIImage {
    return makeRoundedIcon(backgroundColor: UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0)) { ctx, rect in
        ctx.setStrokeColor(UIColor.white.cgColor)
        ctx.setLineWidth(1.4)
        let cx = rect.midX
        let cy = rect.midY
        let w: CGFloat = 12
        let h: CGFloat = 3
        // top ellipse
        ctx.addEllipse(in: CGRect(x: cx - w/2, y: cy - 5, width: w, height: h))
        ctx.strokePath()
        // sides
        ctx.move(to: CGPoint(x: cx - w/2, y: cy - 3.5))
        ctx.addLine(to: CGPoint(x: cx - w/2, y: cy + 3.5))
        ctx.move(to: CGPoint(x: cx + w/2, y: cy - 3.5))
        ctx.addLine(to: CGPoint(x: cx + w/2, y: cy + 3.5))
        ctx.strokePath()
        // middle ellipse
        ctx.addEllipse(in: CGRect(x: cx - w/2, y: cy - 1.5, width: w, height: h))
        ctx.strokePath()
        // bottom ellipse
        ctx.addEllipse(in: CGRect(x: cx - w/2, y: cy + 2, width: w, height: h))
        ctx.strokePath()
    }
}

// MARK: - Ghost Status Helpers

private func ghostEnabledCount(settings: MQGramSettings) -> Int {
    let ghostKeys: [MQGramSettings.Key] = [
        .ghostMode, .ghostReadReceipts, .ghostStories, .ghostContentReads,
        .ghostPersonalActions, .ghostScreenshots, .ghostDrafts, .ghostEmojiInteractions,
        .ghostReactions, .ghostStickerActivity, .ghostOnlineStatus, .ghostTypingActions,
        .readAfterActions
    ]
    return ghostKeys.filter { settings.bool(for: $0) }.count
}

private func hideEnabledCount(settings: MQGramSettings) -> Int {
    let hideKeys: [MQGramSettings.Key] = [
        .hideNavigationBar, .hideFavoriteChats, .hideRecentCalls, .hideDevices,
        .hideChatFolders, .hideNotificationsSettings, .hidePrivacySettings,
        .hideDataSettings, .hideAppearanceSettings, .hideLanguageSettings,
        .hideStickersSettings, .hidePowerSaving
    ]
    return hideKeys.filter { settings.bool(for: $0) }.count
}

// MARK: - Entries

private func mqgramEntries(settings: MQGramSettings, strings: PresentationStrings, tab: Int) -> [MQGramEntry] {
    let text = mqgramText(strings.baseLanguageCode)
    let isRu = strings.baseLanguageCode.lowercased().hasPrefix("ru")
    var entries: [MQGramEntry] = []
    var id: Int32 = 10

    switch tab {
    case 0: // Ghost
        entries.append(.info(1, text.ghostInfo))

        let ghostCount = ghostEnabledCount(settings: settings)
        let ghostTotal = 13
        let statusText = isRu
            ? "Активно: \(ghostCount)/\(ghostTotal) функций"
            : "Active: \(ghostCount)/\(ghostTotal) features"
        entries.append(.statusRow(id, text.ghostStatusTitle, statusText)); id += 1

        entries.append(.toggle(id, .ghostMode, text.ghostModeTitle, text.ghostModeText, settings.ghostMode)); id += 1
        entries.append(.toggle(id, .ghostReadReceipts, text.ghostReadReceiptsTitle, text.ghostReadReceiptsText, settings.ghostReadReceipts)); id += 1
        entries.append(.toggle(id, .readAfterActions, text.readAfterActionsTitle, text.readAfterActionsText, settings.readAfterActions)); id += 1
        entries.append(.toggle(id, .ghostStories, text.ghostStoriesTitle, text.ghostStoriesText, settings.ghostStories)); id += 1
        entries.append(.toggle(id, .ghostContentReads, text.ghostContentReadsTitle, text.ghostContentReadsText, settings.ghostContentReads)); id += 1
        entries.append(.toggle(id, .ghostPersonalActions, text.ghostPersonalActionsTitle, text.ghostPersonalActionsText, settings.ghostPersonalActions)); id += 1
        entries.append(.toggle(id, .ghostScreenshots, text.ghostScreenshotsTitle, text.ghostScreenshotsText, settings.ghostScreenshots)); id += 1
        entries.append(.toggle(id, .ghostDrafts, text.ghostDraftsTitle, text.ghostDraftsText, settings.ghostDrafts)); id += 1
        entries.append(.toggle(id, .ghostEmojiInteractions, text.ghostEmojiInteractionsTitle, text.ghostEmojiInteractionsText, settings.ghostEmojiInteractions)); id += 1
        entries.append(.toggle(id, .ghostReactions, text.ghostReactionsTitle, text.ghostReactionsText, settings.ghostReactions)); id += 1
        entries.append(.toggle(id, .ghostStickerActivity, text.ghostStickerActivityTitle, text.ghostStickerActivityText, settings.ghostStickerActivity)); id += 1
        entries.append(.toggle(id, .ghostOnlineStatus, text.ghostOnlineStatusTitle, text.ghostOnlineStatusText, settings.ghostOnlineStatus)); id += 1
        entries.append(.toggle(id, .ghostTypingActions, text.ghostTypingActionsTitle, text.ghostTypingActionsText, settings.ghostTypingActions)); id += 1

        entries.append(.bulkAction(id, text.enableAllGhostTitle, "enableAllGhost")); id += 1
        entries.append(.bulkAction(id, text.disableAllGhostTitle, "disableAllGhost"))

    case 1: // Core
        entries.append(.info(1, text.stableInfo))
        entries.append(.toggle(id, .antiSelfDestruct, text.antiSelfDestructTitle, text.antiSelfDestructText, settings.antiSelfDestruct)); id += 1
        entries.append(.toggle(id, .antiRevoke, text.antiRevokeTitle, text.antiRevokeText, settings.antiRevoke)); id += 1
        entries.append(.toggle(id, .customIndicators, text.customIndicatorsTitle, text.customIndicatorsText, settings.customIndicators)); id += 1
        entries.append(.toggle(id, .redDeleteIcon, text.redDeleteIconTitle, text.redDeleteIconText, settings.redDeleteIcon)); id += 1
        entries.append(.action(id, text.recycleBinTitle, makeRecycleBinIcon()))

    case 2: // Beta
        entries.append(.info(1, text.betaInfo))
        entries.append(.toggle(id, .contentProtectionBypass, text.contentProtectionTitle, text.contentProtectionText, settings.contentProtectionBypass)); id += 1
        entries.append(.toggle(id, .antiEdit, text.antiEditTitle, text.antiEditText, settings.antiEdit)); id += 1
        entries.append(.toggle(id, .disableAds, text.disableAdsTitle, text.disableAdsText, settings.disableAds)); id += 1
        entries.append(.toggle(id, .businessFeatures, text.businessFeaturesTitle, text.businessFeaturesText, settings.businessFeatures))

    case 3: // Other
        entries.append(.info(1, text.otherInfo))
        entries.append(.toggle(id, .localPremium, text.localPremiumTitle, text.localPremiumText, settings.localPremium)); id += 1
        entries.append(.toggle(id, .unlimitedAccounts, text.unlimitedAccountsTitle, text.unlimitedAccountsText, settings.unlimitedAccounts)); id += 1
        entries.append(.toggle(id, .hidePhoneNumber, text.hidePhoneNumberTitle, text.hidePhoneNumberText, settings.hidePhoneNumber)); id += 1
        entries.append(.toggle(id, .confirmCalls, text.confirmCallsTitle, text.confirmCallsText, settings.confirmCalls)); id += 1
        entries.append(.toggle(id, .silentMessages, text.silentMessagesTitle, text.silentMessagesText, settings.silentMessages)); id += 1
        entries.append(.toggle(id, .pinWalletTab, text.pinWalletTabTitle, text.pinWalletTabText, settings.pinWalletTab)); id += 1

        entries.append(.bulkAction(id, text.resetAllTitle, "resetAll"))

    case 4: // Hide
        entries.append(.info(1, text.hideInfo))

        let hideCount = hideEnabledCount(settings: settings)
        let hideTotal = 12
        let hideStatus = isRu
            ? "Скрыто: \(hideCount)/\(hideTotal) элементов"
            : "Hidden: \(hideCount)/\(hideTotal) elements"
        entries.append(.statusRow(id, isRu ? "Статус" : "Status", hideStatus)); id += 1

        entries.append(.toggle(id, .hideNavigationBar, text.hideNavigationBarTitle, text.hideNavigationBarText, settings.hideNavigationBar)); id += 1
        entries.append(.toggle(id, .hideFavoriteChats, text.hideFavoriteChatsTitle, text.hideFavoriteChatsText, settings.hideFavoriteChats)); id += 1
        entries.append(.toggle(id, .hideRecentCalls, text.hideRecentCallsTitle, text.hideRecentCallsText, settings.hideRecentCalls)); id += 1
        entries.append(.toggle(id, .hideDevices, text.hideDevicesTitle, text.hideDevicesText, settings.hideDevices)); id += 1
        entries.append(.toggle(id, .hideChatFolders, text.hideChatFoldersTitle, text.hideChatFoldersText, settings.hideChatFolders)); id += 1
        entries.append(.toggle(id, .hideNotificationsSettings, text.hideNotificationsTitle, text.hideNotificationsText, settings.hideNotificationsSettings)); id += 1
        entries.append(.toggle(id, .hidePrivacySettings, text.hidePrivacyTitle, text.hidePrivacyText, settings.hidePrivacySettings)); id += 1
        entries.append(.toggle(id, .hideDataSettings, text.hideDataTitle, text.hideDataText, settings.hideDataSettings)); id += 1
        entries.append(.toggle(id, .hideAppearanceSettings, text.hideAppearanceTitle, text.hideAppearanceText, settings.hideAppearanceSettings)); id += 1
        entries.append(.toggle(id, .hideLanguageSettings, text.hideLanguageTitle, text.hideLanguageText, settings.hideLanguageSettings)); id += 1
        entries.append(.toggle(id, .hideStickersSettings, text.hideStickersTitle, text.hideStickersText, settings.hideStickersSettings)); id += 1
        entries.append(.toggle(id, .hidePowerSaving, text.hidePowerSavingTitle, text.hidePowerSavingText, settings.hidePowerSaving)); id += 1

        entries.append(.bulkAction(id, text.enableAllHideTitle, "enableAllHide")); id += 1
        entries.append(.bulkAction(id, text.disableAllHideTitle, "disableAllHide"))

    case 5: // Developer
        entries.append(.info(1, text.devInfo))
        entries.append(.link(id, "GitHub", "https://github.com/jutsodev", false, makeGitHubIcon())); id += 1
        entries.append(.link(id, text.devDeveloper, "https://t.me/jutsodev", true, makeTelegramIcon())); id += 1
        entries.append(.link(id, text.devChannel, "https://t.me/Stivenvpn", true, makeChannelIcon())); id += 1
        entries.append(.link(id, text.devBot, "https://t.me/Stivenvpnbot", true, makeBotIcon()))

    case 6: // Database
        entries.append(.info(1, text.databaseInfo))
        entries.append(.databaseToggle(id, text.databaseCollectionTitle, MQGramDatabaseConfig.isEnabled)); id += 1
        entries.append(.databaseAction(id, text.databaseViewerTitle, makeDatabaseIcon()))

    default:
        break
    }

    entries.append(.footer(9999, text.footer))
    return entries
}

// MARK: - Controller

public func mqgramSettingsController(context: AccountContext) -> ViewController {
    let updatePromise = ValuePromise<Bool>(true, ignoreRepeated: false)
    let tabIndexPromise = ValuePromise<Int>(0, ignoreRepeated: false)

    var openUrlImpl: ((String, Bool) -> Void)?
    var openRecycleBinImpl: (() -> Void)?
    var openDatabaseViewerImpl: (() -> Void)?
    var presentControllerImpl: ((ViewController, ViewControllerPresentationArguments?) -> Void)?

    let ghostKeys: [MQGramSettings.Key] = [
        .ghostMode, .ghostReadReceipts, .ghostStories, .ghostContentReads,
        .ghostPersonalActions, .ghostScreenshots, .ghostDrafts, .ghostEmojiInteractions,
        .ghostReactions, .ghostStickerActivity, .ghostOnlineStatus, .ghostTypingActions,
        .readAfterActions
    ]

    let hideKeys: [MQGramSettings.Key] = [
        .hideNavigationBar, .hideFavoriteChats, .hideRecentCalls, .hideDevices,
        .hideChatFolders, .hideNotificationsSettings, .hidePrivacySettings,
        .hideDataSettings, .hideAppearanceSettings, .hideLanguageSettings,
        .hideStickersSettings, .hidePowerSaving
    ]

    let arguments = MQGramArguments(
        toggleSetting: { key, value in
            MQGramSettings.shared.setBool(value, for: key)
            MQGramDatabase.shared.logSettingChanged(key: key.rawValue, value: value ? "on" : "off")
            updatePromise.set(true)
        },
        openUrl: { url, inTelegram in
            openUrlImpl?(url, inTelegram)
        },
        openRecycleBin: {
            openRecycleBinImpl?()
        },
        openDatabaseViewer: {
            openDatabaseViewerImpl?()
        },
        toggleDatabaseCollection: { enabled in
            MQGramDatabaseConfig.isEnabled = enabled
            MQGramDatabase.shared.logSettingChanged(key: "databaseEnabled", value: enabled ? "on" : "off")
            updatePromise.set(true)
        },
        resetAllSettings: {
            let presentationData = context.sharedContext.currentPresentationData.with { $0 }
            let isRu = presentationData.strings.baseLanguageCode.lowercased().hasPrefix("ru")
            let title = isRu ? "Сброс настроек" : "Reset Settings"
            let text = isRu
                ? "Сбросить все настройки MQGram? Это действие вернёт все переключатели к значениям по умолчанию."
                : "Reset all MQGram settings? This will return all toggles to their default values."
            let alert = textAlertController(
                context: context,
                title: title,
                text: text,
                actions: [
                    TextAlertAction(type: .destructiveAction, title: isRu ? "Сбросить" : "Reset", action: {
                        for key in MQGramSettings.Key.allCases {
                            MQGramSettings.shared.setBool(false, for: key)
                        }
                        MQGramDatabase.shared.logAction(type: "reset_all_settings")
                        updatePromise.set(true)
                    }),
                    TextAlertAction(type: .defaultAction, title: presentationData.strings.Common_Cancel, action: {})
                ]
            )
            presentControllerImpl?(alert, nil)
        },
        enableAllGhost: {
            for key in ghostKeys {
                MQGramSettings.shared.setBool(true, for: key)
            }
            MQGramDatabase.shared.logAction(type: "enable_all_ghost")
            updatePromise.set(true)
        },
        disableAllGhost: {
            for key in ghostKeys {
                MQGramSettings.shared.setBool(false, for: key)
            }
            MQGramDatabase.shared.logAction(type: "disable_all_ghost")
            updatePromise.set(true)
        },
        showGhostStatus: {
            updatePromise.set(true)
        },
        enableAllHide: {
            for key in hideKeys {
                MQGramSettings.shared.setBool(true, for: key)
            }
            MQGramDatabase.shared.logAction(type: "enable_all_hide")
            updatePromise.set(true)
        },
        disableAllHide: {
            for key in hideKeys {
                MQGramSettings.shared.setBool(false, for: key)
            }
            MQGramDatabase.shared.logAction(type: "disable_all_hide")
            updatePromise.set(true)
        },
        showFeatureInfo: { _ in
            updatePromise.set(true)
        }
    )

    let tabNamesRu: [String] = ["Призрак", "Основные", "Бета", "Прочее", "Скрыть", "Dev", "БД"]
    let tabNamesEn: [String] = ["Ghost", "Core", "Beta", "Other", "Hide", "Dev", "DB"]

    let signal = combineLatest(context.sharedContext.presentationData, updatePromise.get(), tabIndexPromise.get())
    |> map { presentationData, _, tabIndex -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let isRu = presentationData.strings.baseLanguageCode.lowercased().hasPrefix("ru")
        let tabNames = isRu ? tabNamesRu : tabNamesEn

        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .sectionControl(tabNames, tabIndex),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)
        )

        let entries = mqgramEntries(settings: MQGramSettings.shared, strings: presentationData.strings, tab: tabIndex)

        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: entries,
            style: .blocks
        )

        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    controller.titleControlValueChanged = { index in
        tabIndexPromise.set(index)
    }

    openUrlImpl = { [weak controller] url, _ in
        guard let controller else { return }
        let presentationData = context.sharedContext.currentPresentationData.with { $0 }
        let navigationController = controller.navigationController as? NavigationController
        context.sharedContext.openExternalUrl(
            context: context,
            urlContext: .generic,
            url: url,
            forceExternal: false,
            presentationData: presentationData,
            navigationController: navigationController,
            dismissInput: {}
        )
    }

    openRecycleBinImpl = { [weak controller] in
        let recycleBinController = savedDeletedMessagesListController(context: context)
        controller?.navigationController?.pushViewController(recycleBinController, animated: true)
    }

    openDatabaseViewerImpl = { [weak controller] in
        let dbController = mqgramDatabaseViewerController(context: context)
        controller?.navigationController?.pushViewController(dbController, animated: true)
    }

    presentControllerImpl = { [weak controller] c, a in
        controller?.present(c, in: PresentationContextType.window(PresentationSurfaceLevel.root), with: a)
    }

    return controller
}
