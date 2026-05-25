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

// MARK: - Arguments

private final class MQGramArguments {
    let toggleSetting: (MQGramSettings.Key, Bool) -> Void
    let openUrl: (String, Bool) -> Void
    let openRecycleBin: () -> Void
    let openAdvancedGhost: () -> Void

    init(toggleSetting: @escaping (MQGramSettings.Key, Bool) -> Void, openUrl: @escaping (String, Bool) -> Void, openRecycleBin: @escaping () -> Void, openAdvancedGhost: @escaping () -> Void) {
        self.toggleSetting = toggleSetting
        self.openUrl = openUrl
        self.openRecycleBin = openRecycleBin
        self.openAdvancedGhost = openAdvancedGhost
    }
}

// MARK: - Entries

private enum MQGramEntry: ItemListNodeEntry {
    case info(Int32, String)
    case toggle(Int32, MQGramSettings.Key, String, String?, Bool)
    case link(Int32, String, String, Bool, UIImage?)
    case action(Int32, String, UIImage?)
    case advancedGhost(Int32, String, String)
    case footer(Int32, String)

    var section: ItemListSectionId {
        switch self {
        case .footer:
            return 1
        default:
            return 0
        }
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
        case let .advancedGhost(id, _, _):
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
        case let .advancedGhost(lId, lTitle, lText):
            if case let .advancedGhost(rId, rTitle, rText) = rhs, lId == rId, lTitle == rTitle, lText == rText { return true } else { return false }
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
        case let .advancedGhost(_, title, text):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                icon: makeAdvancedIcon(),
                title: title,
                label: text,
                sectionId: self.section,
                style: .blocks,
                disclosureStyle: .arrow,
                action: {
                    args.openAdvancedGhost()
                }
            )
        case let .footer(_, text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        }
    }
}

// MARK: - Localized Text

private struct MQGramGhostText {
    let ghostModeTitle: String
    let ghostModeText: String
    let advancedSettingsTitle: String
    let advancedSettingsText: String
    let hideOnlineStatusTitle: String
    let hideOnlineStatusText: String
    let hideTypingTitle: String
    let hideTypingText: String
    let hideVideoRecordTitle: String
    let hideVideoRecordText: String
    let hideVideoUploadTitle: String
    let hideVideoUploadText: String
    let hideVoiceRecordTitle: String
    let hideVoiceRecordText: String
    let hideVoiceUploadTitle: String
    let hideVoiceUploadText: String
    let hidePhotoUploadTitle: String
    let hidePhotoUploadText: String
    let hideFileUploadTitle: String
    let hideFileUploadText: String
    let hideLocationPickTitle: String
    let hideLocationPickText: String
    let hideContactPickTitle: String
    let hideContactPickText: String
    let hideGameTitle: String
    let hideGameText: String
    let hideRoundVideoRecordTitle: String
    let hideRoundVideoRecordText: String
    let hideRoundVideoUploadTitle: String
    let hideRoundVideoUploadText: String
    let hideGroupCallVoiceTitle: String
    let hideGroupCallVoiceText: String
    let hideStickerPickTitle: String
    let hideStickerPickText: String
    let hideEmojiInteractionTitle: String
    let hideEmojiInteractionText: String
    let hideEmojiReactionTitle: String
    let hideEmojiReactionText: String
    let readReceiptsDisableTitle: String
    let readReceiptsDisableText: String
    let storyReadDisableTitle: String
    let storyReadDisableText: String
}

private struct MQGramPrivacyText {
    let sectionTitle: String
    let disableAdsTitle: String
    let disableAdsText: String
    let contentProtectionTitle: String
    let contentProtectionText: String
    let saveDeletedTitle: String
    let saveDeletedText: String
    let saveAutoDeleteTitle: String
    let saveAutoDeleteText: String
    let screenshotNoNotifyTitle: String
    let screenshotNoNotifyText: String
    let viewDisappearingTitle: String
    let viewDisappearingText: String
    let confirmCallsTitle: String
    let confirmCallsText: String
}

private struct MQGramFullText {
    let ghost: MQGramGhostText
    let privacy: MQGramPrivacyText
    let ghostInfo: String
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
    let ghostReactionsTitle: String
    let ghostReactionsText: String
    let ghostStickerActivityTitle: String
    let ghostStickerActivityText: String
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
    let antiEditTitle: String
    let antiEditText: String
    let businessFeaturesTitle: String
    let businessFeaturesText: String
    let otherInfo: String
    let localPremiumTitle: String
    let localPremiumText: String
    let unlimitedAccountsTitle: String
    let unlimitedAccountsText: String
    let hidePhoneNumberTitle: String
    let hidePhoneNumberText: String
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
    let languageInfo: String
    let languageTitle: String
    let languageText: String
    let disclaimerTitle: String
    let disclaimerText: String
    let thanksTitle: String
    let thanksText: String
    let devDeveloper: String
    let devChannel: String
    let devBot: String
    let footer: String
}

private func mqgramText(_ languageCode: String) -> MQGramFullText {
    let isRu = languageCode.lowercased().hasPrefix("ru")

    let ghost = isRu ? MQGramGhostText(
        ghostModeTitle: "Ghost Mode",
        ghostModeText: "Главный переключатель для всех ghost-функций.",
        advancedSettingsTitle: "Advanced Settings",
        advancedSettingsText: "Hide detail settings",
        hideOnlineStatusTitle: "Скрыть онлайн-статус",
        hideOnlineStatusText: "Не показывать другим, что вы в сети.",
        hideTypingTitle: "Скрыть статус набора",
        hideTypingText: "Не показывать, что вы печатаете сообщение.",
        hideVideoRecordTitle: "Скрыть статус записи видео",
        hideVideoRecordText: "Не показывать, что вы записываете видео.",
        hideVideoUploadTitle: "Скрыть статус загрузки видео",
        hideVideoUploadText: "Скрывать при загрузке видео.",
        hideVoiceRecordTitle: "Скрыть запись голосового сообщения",
        hideVoiceRecordText: "Не показывать, что вы записываете голосовое сообщение.",
        hideVoiceUploadTitle: "Скрыть загрузку голосового сообщения",
        hideVoiceUploadText: "Не показывать, что вы загружаете голосовое сообщение.",
        hidePhotoUploadTitle: "Скрыть статус загрузки фото",
        hidePhotoUploadText: "Скрывать при загрузке фото.",
        hideFileUploadTitle: "Скрыть статус загрузки файла",
        hideFileUploadText: "Не показывать, что вы загружаете файл.",
        hideLocationPickTitle: "Скрыть выбор локации",
        hideLocationPickText: "Не показывать, что вы выбираете местоположение.",
        hideContactPickTitle: "Скрыть выбор контакта",
        hideContactPickText: "Не показывать, что вы выбираете контакт.",
        hideGameTitle: "Скрыть игру",
        hideGameText: "Не показывать, что вы играете в игру.",
        hideRoundVideoRecordTitle: "Скрыть запись круглого видео",
        hideRoundVideoRecordText: "Не показывать, что вы записываете круглое видео.",
        hideRoundVideoUploadTitle: "Скрыть загрузку круглого видео",
        hideRoundVideoUploadText: "Скрыть загрузку круглого видео.",
        hideGroupCallVoiceTitle: "Скрыть голос в групповом звонке",
        hideGroupCallVoiceText: "Не показывать, что вы говорите в групповом звонке.",
        hideStickerPickTitle: "Скрыть выбор стикера",
        hideStickerPickText: "Не показывать, что вы выбираете стикер.",
        hideEmojiInteractionTitle: "Скрыть взаимодействие с эмодзи",
        hideEmojiInteractionText: "Не показывать, что вы взаимодействуете с эмодзи.",
        hideEmojiReactionTitle: "Скрыть реакцию эмодзи",
        hideEmojiReactionText: "Не показывать, что вы реагируете на сообщение эмодзи.",
        readReceiptsDisableTitle: "Отключить отчёты о прочтении сообщений",
        readReceiptsDisableText: "Не сообщать, что вы прочитали сообщение.",
        storyReadDisableTitle: "Отключить отчёты о прочтении историй",
        storyReadDisableText: "Не сообщать, что вы просмотрели историю."
    ) : MQGramGhostText(
        ghostModeTitle: "Ghost Mode",
        ghostModeText: "Main toggle for all ghost features.",
        advancedSettingsTitle: "Advanced Settings",
        advancedSettingsText: "Hide detail settings",
        hideOnlineStatusTitle: "Hide Online Status",
        hideOnlineStatusText: "Don't show others that you are online.",
        hideTypingTitle: "Hide Typing Status",
        hideTypingText: "Don't show that you are typing a message.",
        hideVideoRecordTitle: "Hide Video Recording Status",
        hideVideoRecordText: "Don't show that you are recording video.",
        hideVideoUploadTitle: "Hide Video Upload Status",
        hideVideoUploadText: "Hide when uploading video.",
        hideVoiceRecordTitle: "Hide Voice Message Recording",
        hideVoiceRecordText: "Don't show that you are recording a voice message.",
        hideVoiceUploadTitle: "Hide Voice Message Upload",
        hideVoiceUploadText: "Don't show that you are uploading a voice message.",
        hidePhotoUploadTitle: "Hide Photo Upload Status",
        hidePhotoUploadText: "Hide when uploading photo.",
        hideFileUploadTitle: "Hide File Upload Status",
        hideFileUploadText: "Don't show that you are uploading a file.",
        hideLocationPickTitle: "Hide Location Pick",
        hideLocationPickText: "Don't show that you are choosing a location.",
        hideContactPickTitle: "Hide Contact Pick",
        hideContactPickText: "Don't show that you are choosing a contact.",
        hideGameTitle: "Hide Game",
        hideGameText: "Don't show that you are playing a game.",
        hideRoundVideoRecordTitle: "Hide Round Video Recording",
        hideRoundVideoRecordText: "Don't show that you are recording a round video.",
        hideRoundVideoUploadTitle: "Hide Round Video Upload",
        hideRoundVideoUploadText: "Hide round video upload.",
        hideGroupCallVoiceTitle: "Hide Voice in Group Call",
        hideGroupCallVoiceText: "Don't show that you are speaking in a group call.",
        hideStickerPickTitle: "Hide Sticker Pick",
        hideStickerPickText: "Don't show that you are choosing a sticker.",
        hideEmojiInteractionTitle: "Hide Emoji Interaction",
        hideEmojiInteractionText: "Don't show that you are interacting with emoji.",
        hideEmojiReactionTitle: "Hide Emoji Reaction",
        hideEmojiReactionText: "Don't show that you are reacting to a message with emoji.",
        readReceiptsDisableTitle: "Disable Read Receipts",
        readReceiptsDisableText: "Don't report that you have read a message.",
        storyReadDisableTitle: "Disable Story Read Receipts",
        storyReadDisableText: "Don't report that you have viewed a story."
    )

    let privacy = isRu ? MQGramPrivacyText(
        sectionTitle: "Приватность и функции",
        disableAdsTitle: "Отключить всю рекламу",
        disableAdsText: "Убирает спонсорские сообщения и рекламный контент из приложения.",
        contentProtectionTitle: "Сохранение медиа из закрытых чатов",
        contentProtectionText: "Обходит запрет пересылки — сохраняй и пересылай медиа из защищённых каналов и чатов.",
        saveDeletedTitle: "Сохранять удалённые сообщения",
        saveDeletedText: "Сообщения остаются у вас в чате даже после того, как отправитель их удалил.",
        saveAutoDeleteTitle: "Сохранять авто-удаляемые сообщения",
        saveAutoDeleteText: "Предотвращает удаление сообщений в чатах с авто-удалением (1 день, 7 дней и т.д.). Сообщения остаются видимыми даже после истечения таймера.",
        screenshotNoNotifyTitle: "Скриншоты без уведомлений",
        screenshotNoNotifyText: "Делайте скриншоты в секретных чатах и защищённых каналах — без уведомления собеседника.",
        viewDisappearingTitle: "Просмотр исчезающих медиафайлов",
        viewDisappearingText: "Открывайте одноразовые и исчезающие фото/видео без запуска таймера самоуничтожения. Медиа-файл остаётся доступным локально.",
        confirmCallsTitle: "Confirm Calls",
        confirmCallsText: "Show a confirmation dialog before answering incoming calls."
    ) : MQGramPrivacyText(
        sectionTitle: "Privacy & Functions",
        disableAdsTitle: "Disable All Ads",
        disableAdsText: "Removes sponsored messages and ad content from the app.",
        contentProtectionTitle: "Save Media from Restricted Chats",
        contentProtectionText: "Bypasses forwarding restrictions — save and forward media from protected channels and chats.",
        saveDeletedTitle: "Save Deleted Messages",
        saveDeletedText: "Messages stay in your chat even after the sender deleted them.",
        saveAutoDeleteTitle: "Save Auto-Delete Messages",
        saveAutoDeleteText: "Prevents deletion in chats with auto-delete (1 day, 7 days, etc.). Messages remain visible even after the timer expires.",
        screenshotNoNotifyTitle: "Screenshots Without Notifications",
        screenshotNoNotifyText: "Take screenshots in secret chats and protected channels — without notifying the other party.",
        viewDisappearingTitle: "View Disappearing Media",
        viewDisappearingText: "Open one-time and disappearing photos/videos without triggering the self-destruct timer. Media remains available locally.",
        confirmCallsTitle: "Confirm Calls",
        confirmCallsText: "Show a confirmation dialog before answering incoming calls."
    )

    if isRu {
        return MQGramFullText(
            ghost: ghost,
            privacy: privacy,
            ghostInfo: "Тихий режим: чтение, истории, действия, онлайн, реакции и черновики без лишних следов.",
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
            ghostReactionsTitle: "Скрывать реакции",
            ghostReactionsText: "Не отправляет реакции на сообщения и истории.",
            ghostStickerActivityTitle: "Скрывать стикеры",
            ghostStickerActivityText: "Не сохраняет недавние стикеры и просмотр новых наборов.",
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
            antiEditTitle: "Анти-редактирование",
            antiEditText: "Показывает оригинальный текст отредактированных сообщений.",
            businessFeaturesTitle: "Telegram для бизнеса",
            businessFeaturesText: "Активирует бизнес-функции профиля локально.",
            otherInfo: "Дополнительные функции для расширенного управления приложением.",
            localPremiumTitle: "Локальный Премиум",
            localPremiumText: "Активирует премиум-функции интерфейса локально без подписки.",
            unlimitedAccountsTitle: "Безлимитные аккаунты",
            unlimitedAccountsText: "Снимает ограничение на количество добавленных аккаунтов.",
            hidePhoneNumberTitle: "Скрыть номер телефона",
            hidePhoneNumberText: "Прячет твой номер телефона в профиле и настройках.",
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
            languageInfo: "Язык меняется в стандартных настройках Telegram. MQGram следует системной локализации приложения.",
            languageTitle: "Сменить язык",
            languageText: "Открывает настройки языка Telegram.",
            disclaimerTitle: "Отказ от ответственности",
            disclaimerText: "MQGram — локальная клиентская модификация. Ghost Mode и приватные функции хранятся локально и не являются серверной настройкой Telegram.",
            thanksTitle: "Благодарность",
            thanksText: "Спасибо пользователям MQGram, open-source сообществу Telegram-iOS/Swiftgram и MQ Team / jutsodev.",
            devDeveloper: "MQ Team / jutsodev",
            devChannel: "Канал StivenVPN",
            devBot: "Бот StivenVPN",
            footer: "Функции MQGram. Для части изменений перезапусти приложение."
        )
    }
    return MQGramFullText(
        ghost: ghost,
        privacy: privacy,
        ghostInfo: "Quiet mode: reads, stories, actions, online, reactions, and drafts with fewer traces.",
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
        ghostReactionsTitle: "Hide Reactions",
        ghostReactionsText: "Do not send reactions to messages and stories.",
        ghostStickerActivityTitle: "Hide Sticker Activity",
        ghostStickerActivityText: "Do not save recent stickers or seen featured packs.",
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
        antiEditTitle: "Anti-Edit",
        antiEditText: "See original content of edited messages.",
        businessFeaturesTitle: "Telegram for Business",
        businessFeaturesText: "Enable Business profile features locally.",
        otherInfo: "Extra features for extended app control.",
        localPremiumTitle: "Local Premium",
        localPremiumText: "Activates premium UI features locally without a subscription.",
        unlimitedAccountsTitle: "Unlimited Accounts",
        unlimitedAccountsText: "Removes the limit on the number of added accounts.",
        hidePhoneNumberTitle: "Hide Phone Number",
        hidePhoneNumberText: "Hides your phone number in profile and settings.",
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
        languageInfo: "Language is changed in Telegram language settings. MQGram follows the app localization.",
        languageTitle: "Change Language",
        languageText: "Opens Telegram language settings.",
        disclaimerTitle: "Disclaimer",
        disclaimerText: "MQGram is a local client modification. Ghost Mode and privacy features are stored locally and are not Telegram server settings.",
        thanksTitle: "Thanks",
        thanksText: "Thanks to MQGram users, the Telegram-iOS/Swiftgram open-source community, and MQ Team / jutsodev.",
        devDeveloper: "MQ Team / jutsodev",
        devChannel: "StivenVPN Channel",
        devBot: "StivenVPN Bot",
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

private func makeGhostIcon() -> UIImage {
    return makeRoundedIcon(backgroundColor: UIColor(red: 0.3, green: 0.3, blue: 0.35, alpha: 1.0)) { _, rect in
        let cx = rect.midX
        let cy = rect.midY
        UIColor.white.setFill()
        let body = UIBezierPath(ovalIn: CGRect(x: cx - 7, y: cy - 8, width: 14, height: 12))
        body.fill()
        let bottom = UIBezierPath(rect: CGRect(x: cx - 7, y: cy, width: 14, height: 6))
        bottom.fill()
        UIColor(red: 0.3, green: 0.3, blue: 0.35, alpha: 1.0).setFill()
        UIBezierPath(ovalIn: CGRect(x: cx - 4, y: cy - 4, width: 3, height: 3)).fill()
        UIBezierPath(ovalIn: CGRect(x: cx + 1, y: cy - 4, width: 3, height: 3)).fill()
    }
}

private func makeAdvancedIcon() -> UIImage {
    return makeRoundedIcon(backgroundColor: UIColor(red: 0.4, green: 0.4, blue: 0.45, alpha: 1.0)) { _, rect in
        let cx = rect.midX
        let cy = rect.midY
        UIColor.white.setStroke()
        UIColor.white.setFill()
        for yOff: CGFloat in [-5, 0, 5] {
            let line = UIBezierPath()
            line.lineWidth = 1.5
            line.move(to: CGPoint(x: cx - 7, y: cy + yOff))
            line.addLine(to: CGPoint(x: cx + 7, y: cy + yOff))
            line.stroke()
            UIBezierPath(ovalIn: CGRect(x: cx + (yOff == 0 ? -3 : 1), y: cy + yOff - 2, width: 4, height: 4)).fill()
        }
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

private func mqgramEntries(settings: MQGramSettings, strings: PresentationStrings, tab: Int) -> [MQGramEntry] {
    let text = mqgramText(strings.baseLanguageCode)
    var entries: [MQGramEntry] = []
    var id: Int32 = 10

    switch tab {
    case 0: // Ghost Mode (main page)
        entries.append(.info(1, text.ghostInfo))
        entries.append(.toggle(id, .ghostMode, text.ghost.ghostModeTitle, text.ghost.ghostModeText, settings.ghostMode)); id += 1
        entries.append(.advancedGhost(id, text.ghost.advancedSettingsTitle, text.ghost.advancedSettingsText)); id += 1
        entries.append(.toggle(id, .ghostOnlineStatus, text.ghost.hideOnlineStatusTitle, text.ghost.hideOnlineStatusText, settings.ghostOnlineStatus)); id += 1
        entries.append(.toggle(id, .ghostTypingActions, text.ghost.hideTypingTitle, text.ghost.hideTypingText, settings.ghostTypingActions)); id += 1
        entries.append(.toggle(id, .ghostVideoRecording, text.ghost.hideVideoRecordTitle, text.ghost.hideVideoRecordText, settings.ghostVideoRecording)); id += 1
        entries.append(.toggle(id, .ghostVideoUpload, text.ghost.hideVideoUploadTitle, text.ghost.hideVideoUploadText, settings.ghostVideoUpload)); id += 1
        entries.append(.toggle(id, .ghostVoiceRecording, text.ghost.hideVoiceRecordTitle, text.ghost.hideVoiceRecordText, settings.ghostVoiceRecording)); id += 1
        entries.append(.toggle(id, .ghostVoiceUpload, text.ghost.hideVoiceUploadTitle, text.ghost.hideVoiceUploadText, settings.ghostVoiceUpload)); id += 1
        entries.append(.toggle(id, .ghostPhotoUpload, text.ghost.hidePhotoUploadTitle, text.ghost.hidePhotoUploadText, settings.ghostPhotoUpload)); id += 1
        entries.append(.toggle(id, .ghostFileUpload, text.ghost.hideFileUploadTitle, text.ghost.hideFileUploadText, settings.ghostFileUpload)); id += 1
        entries.append(.toggle(id, .ghostLocationPick, text.ghost.hideLocationPickTitle, text.ghost.hideLocationPickText, settings.ghostLocationPick)); id += 1
        entries.append(.toggle(id, .ghostContactPick, text.ghost.hideContactPickTitle, text.ghost.hideContactPickText, settings.ghostContactPick)); id += 1
        entries.append(.toggle(id, .ghostGamePlaying, text.ghost.hideGameTitle, text.ghost.hideGameText, settings.ghostGamePlaying)); id += 1
        entries.append(.toggle(id, .ghostRoundVideoRecording, text.ghost.hideRoundVideoRecordTitle, text.ghost.hideRoundVideoRecordText, settings.ghostRoundVideoRecording)); id += 1
        entries.append(.toggle(id, .ghostRoundVideoUpload, text.ghost.hideRoundVideoUploadTitle, text.ghost.hideRoundVideoUploadText, settings.ghostRoundVideoUpload)); id += 1
        entries.append(.toggle(id, .ghostGroupCallVoice, text.ghost.hideGroupCallVoiceTitle, text.ghost.hideGroupCallVoiceText, settings.ghostGroupCallVoice)); id += 1
        entries.append(.toggle(id, .ghostStickerPick, text.ghost.hideStickerPickTitle, text.ghost.hideStickerPickText, settings.ghostStickerPick)); id += 1
        entries.append(.toggle(id, .ghostEmojiInteractions, text.ghost.hideEmojiInteractionTitle, text.ghost.hideEmojiInteractionText, settings.ghostEmojiInteractions)); id += 1
        entries.append(.toggle(id, .ghostEmojiReaction, text.ghost.hideEmojiReactionTitle, text.ghost.hideEmojiReactionText, settings.ghostEmojiReaction)); id += 1
        entries.append(.toggle(id, .ghostReadReceiptsDisable, text.ghost.readReceiptsDisableTitle, text.ghost.readReceiptsDisableText, settings.ghostReadReceiptsDisable)); id += 1
        entries.append(.toggle(id, .ghostStoryReadDisable, text.ghost.storyReadDisableTitle, text.ghost.storyReadDisableText, settings.ghostStoryReadDisable))

    case 1: // Privacy & Functions
        entries.append(.info(1, "**\(text.privacy.sectionTitle)**"))
        entries.append(.toggle(id, .disableAds, text.privacy.disableAdsTitle, text.privacy.disableAdsText, settings.disableAds)); id += 1
        entries.append(.toggle(id, .contentProtectionBypass, text.privacy.contentProtectionTitle, text.privacy.contentProtectionText, settings.contentProtectionBypass)); id += 1
        entries.append(.toggle(id, .antiRevoke, text.privacy.saveDeletedTitle, text.privacy.saveDeletedText, settings.antiRevoke)); id += 1
        entries.append(.toggle(id, .saveAutoDeleteMessages, text.privacy.saveAutoDeleteTitle, text.privacy.saveAutoDeleteText, settings.saveAutoDeleteMessages)); id += 1
        entries.append(.toggle(id, .screenshotNoNotify, text.privacy.screenshotNoNotifyTitle, text.privacy.screenshotNoNotifyText, settings.screenshotNoNotify)); id += 1
        entries.append(.toggle(id, .viewDisappearingMedia, text.privacy.viewDisappearingTitle, text.privacy.viewDisappearingText, settings.viewDisappearingMedia)); id += 1
        entries.append(.toggle(id, .confirmCalls, text.privacy.confirmCallsTitle, text.privacy.confirmCallsText, settings.confirmCalls))

    case 2: // Core
        entries.append(.info(1, text.stableInfo))
        entries.append(.toggle(id, .antiSelfDestruct, text.antiSelfDestructTitle, text.antiSelfDestructText, settings.antiSelfDestruct)); id += 1
        entries.append(.toggle(id, .antiRevoke, text.antiRevokeTitle, text.antiRevokeText, settings.antiRevoke)); id += 1
        entries.append(.toggle(id, .customIndicators, text.customIndicatorsTitle, text.customIndicatorsText, settings.customIndicators)); id += 1
        entries.append(.toggle(id, .redDeleteIcon, text.redDeleteIconTitle, text.redDeleteIconText, settings.redDeleteIcon)); id += 1
        let recycleBinTitle = strings.baseLanguageCode.lowercased().hasPrefix("ru") ? "Корзина удалённых" : "Recycle Bin"
        entries.append(.action(id, recycleBinTitle, makeRecycleBinIcon()))

    case 3: // Beta
        entries.append(.info(1, text.betaInfo))
        entries.append(.toggle(id, .contentProtectionBypass, text.privacy.contentProtectionTitle, text.privacy.contentProtectionText, settings.contentProtectionBypass)); id += 1
        entries.append(.toggle(id, .antiEdit, text.antiEditTitle, text.antiEditText, settings.antiEdit)); id += 1
        entries.append(.toggle(id, .disableAds, text.privacy.disableAdsTitle, text.privacy.disableAdsText, settings.disableAds)); id += 1
        entries.append(.toggle(id, .businessFeatures, text.businessFeaturesTitle, text.businessFeaturesText, settings.businessFeatures))

    case 4: // Other
        entries.append(.info(1, text.otherInfo))
        entries.append(.toggle(id, .localPremium, text.localPremiumTitle, text.localPremiumText, settings.localPremium)); id += 1
        entries.append(.toggle(id, .unlimitedAccounts, text.unlimitedAccountsTitle, text.unlimitedAccountsText, settings.unlimitedAccounts)); id += 1
        entries.append(.toggle(id, .hidePhoneNumber, text.hidePhoneNumberTitle, text.hidePhoneNumberText, settings.hidePhoneNumber)); id += 1
        entries.append(.toggle(id, .confirmCalls, text.privacy.confirmCallsTitle, text.privacy.confirmCallsText, settings.confirmCalls)); id += 1
        entries.append(.toggle(id, .silentMessages, text.silentMessagesTitle, text.silentMessagesText, settings.silentMessages)); id += 1
        entries.append(.toggle(id, .pinWalletTab, text.pinWalletTabTitle, text.pinWalletTabText, settings.pinWalletTab))

    case 5: // Hide
        entries.append(.info(1, text.hideInfo))
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
        entries.append(.toggle(id, .hidePowerSaving, text.hidePowerSavingTitle, text.hidePowerSavingText, settings.hidePowerSaving))

    case 6: // Developer
        entries.append(.info(1, text.devInfo))
        entries.append(.link(id, "GitHub", "https://github.com/jutsodev", false, makeGitHubIcon())); id += 1
        entries.append(.info(id, text.languageInfo)); id += 1
        entries.append(.link(id, text.languageTitle, "tg://settings/language", true, nil)); id += 1
        entries.append(.info(id, "**\(text.disclaimerTitle)**\n\(text.disclaimerText)")); id += 1
        entries.append(.info(id, "**\(text.thanksTitle)**\n\(text.thanksText)")); id += 1
        entries.append(.link(id, text.devDeveloper, "https://t.me/jutsodev", true, makeTelegramIcon())); id += 1
        entries.append(.link(id, text.devChannel, "https://t.me/Stivenvpn", true, makeChannelIcon())); id += 1
        entries.append(.link(id, text.devBot, "https://t.me/Stivenvpnbot", true, makeBotIcon()))

    default:
        break
    }

    entries.append(.footer(9999, text.footer))
    return entries
}

// MARK: - Advanced Ghost Entries

private func mqgramAdvancedGhostEntries(settings: MQGramSettings, strings: PresentationStrings) -> [MQGramEntry] {
    let text = mqgramText(strings.baseLanguageCode)
    var entries: [MQGramEntry] = []
    var id: Int32 = 10

    entries.append(.toggle(id, .ghostReadReceipts, text.ghostReadReceiptsTitle, text.ghostReadReceiptsText, settings.ghostReadReceipts)); id += 1
    entries.append(.toggle(id, .readAfterActions, text.readAfterActionsTitle, text.readAfterActionsText, settings.readAfterActions)); id += 1
    entries.append(.toggle(id, .ghostStories, text.ghostStoriesTitle, text.ghostStoriesText, settings.ghostStories)); id += 1
    entries.append(.toggle(id, .ghostContentReads, text.ghostContentReadsTitle, text.ghostContentReadsText, settings.ghostContentReads)); id += 1
    entries.append(.toggle(id, .ghostPersonalActions, text.ghostPersonalActionsTitle, text.ghostPersonalActionsText, settings.ghostPersonalActions)); id += 1
    entries.append(.toggle(id, .ghostScreenshots, text.ghostScreenshotsTitle, text.ghostScreenshotsText, settings.ghostScreenshots)); id += 1
    entries.append(.toggle(id, .ghostDrafts, text.ghostDraftsTitle, text.ghostDraftsText, settings.ghostDrafts)); id += 1
    entries.append(.toggle(id, .ghostReactions, text.ghostReactionsTitle, text.ghostReactionsText, settings.ghostReactions)); id += 1
    entries.append(.toggle(id, .ghostStickerActivity, text.ghostStickerActivityTitle, text.ghostStickerActivityText, settings.ghostStickerActivity))

    entries.append(.footer(9999, text.footer))
    return entries
}

// MARK: - Controller

public func mqgramSettingsController(context: AccountContext) -> ViewController {
    let updatePromise = ValuePromise<Bool>(true, ignoreRepeated: false)
    let tabIndexPromise = ValuePromise<Int>(0, ignoreRepeated: false)
    let previousTabIndex = Atomic<Int?>(value: nil)

    var openUrlImpl: ((String, Bool) -> Void)?
    var openRecycleBinImpl: (() -> Void)?
    var openAdvancedGhostImpl: (() -> Void)?

    let arguments = MQGramArguments(
        toggleSetting: { key, value in
            MQGramSettings.shared.setBool(value, for: key)
            updatePromise.set(true)
        },
        openUrl: { url, inTelegram in
            openUrlImpl?(url, inTelegram)
        },
        openRecycleBin: {
            openRecycleBinImpl?()
        },
        openAdvancedGhost: {
            openAdvancedGhostImpl?()
        }
    )

    let isRuSignal = context.sharedContext.presentationData
    |> map { $0.strings.baseLanguageCode.lowercased().hasPrefix("ru") }
    |> distinctUntilChanged

    let tabNamesRu: [String] = ["Призрак", "Приватность", "Основные", "Бета", "Прочее", "Скрыть", "Dev"]
    let tabNamesEn: [String] = ["Ghost", "Privacy", "Core", "Beta", "Other", "Hide", "Dev"]

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
        let previousIndex = previousTabIndex.swap(tabIndex)
        let tabChanged = previousIndex != nil && previousIndex != tabIndex

        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: entries,
            style: .blocks,
            crossfadeState: tabChanged,
            animateChanges: !tabChanged
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

    openAdvancedGhostImpl = { [weak controller] in
        let advancedController = mqgramAdvancedGhostController(context: context)
        controller?.navigationController?.pushViewController(advancedController, animated: true)
    }

    return controller
}

// MARK: - Advanced Ghost Controller

private func mqgramAdvancedGhostController(context: AccountContext) -> ViewController {
    let updatePromise = ValuePromise<Bool>(true, ignoreRepeated: false)

    let arguments = MQGramArguments(
        toggleSetting: { key, value in
            MQGramSettings.shared.setBool(value, for: key)
            updatePromise.set(true)
        },
        openUrl: { _, _ in },
        openRecycleBin: {},
        openAdvancedGhost: {}
    )

    let signal = combineLatest(context.sharedContext.presentationData, updatePromise.get())
    |> map { presentationData, _ -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let isRu = presentationData.strings.baseLanguageCode.lowercased().hasPrefix("ru")
        let title = isRu ? "Расширенные настройки призрака" : "Advanced Ghost Settings"

        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text(title),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)
        )

        let entries = mqgramAdvancedGhostEntries(settings: MQGramSettings.shared, strings: presentationData.strings)

        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: entries,
            style: .blocks,
            animateChanges: false
        )

        return (controllerState, (listState, arguments))
    }

    return ItemListController(context: context, state: signal)
}
