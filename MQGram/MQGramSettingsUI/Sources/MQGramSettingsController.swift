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
    case disclosure(Int32, String, String?, UIImage?)
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
        case let .disclosure(id, _, _, _):
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
        case let .disclosure(lId, lTitle, lSubtitle, _):
            if case let .disclosure(rId, rTitle, rSubtitle, _) = rhs, lId == rId, lTitle == rTitle, lSubtitle == rSubtitle { return true } else { return false }
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
        case let .footer(_, text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        }
    }
}

// MARK: - Localized Text

private struct MQGramText {
    // Невидимость
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
    let alwaysOnlineTitle: String
    let alwaysOnlineText: String
    let messageSendingDelayTitle: String
    let messageSendingDelayText: String
    let onlyReadWhenReplyingTitle: String
    let onlyReadWhenReplyingText: String
    let onlyReadWhenReactingTitle: String
    let onlyReadWhenReactingText: String
    
    // Антиудаление
    let antiDeleteInfo: String
    let antiRevokeTitle: String
    let antiRevokeText: String
    let antiEditText: String
    let antiEditTitle: String
    let showEditHistoryTitle: String
    let showEditHistoryText: String
    let secretMediaSaverTitle: String
    let secretMediaSaverText: String
    let savePhotosTitle: String
    let savePhotosText: String
    let saveVideosTitle: String
    let saveVideosText: String
    
    // Без ограничений
    let noLimitsInfo: String
    let contentProtectionTitle: String
    let contentProtectionText: String
    let disableAdsTitle: String
    let disableAdsText: String
    let hideReactionsTitle: String
    let hideReactionsText: String
    let hideCommentTitle: String
    let hideCommentText: String
    let readUntilTitle: String
    let readUntilText: String
    
    // Текст
    let textInfo: String
    let antiCapsTitle: String
    let antiCapsText: String
    let autoTranslateTitle: String
    let autoTranslateText: String
    let autoFormatTitle: String
    let autoFormatText: String
    
    // Внешний вид
    let appearanceInfo: String
    let customFontTitle: String
    let customFontText: String
    let videoBackgroundTitle: String
    let videoBackgroundText: String
    let squareAvatarsTitle: String
    let squareAvatarsText: String
    let deletedTransparencyTitle: String
    let deletedTransparencyText: String
    
    // Локальные фейки
    let fakesInfo: String
    let fakePremiumTitle: String
    let fakePremiumText: String
    let fakeStarsTitle: String
    let fakeStarsText: String
    let localPremiumTitle: String
    let localPremiumText: String
    
    // Профиль
    let profileInfo: String
    let showPeerIdTitle: String
    let showPeerIdText: String
    let showRegDateTitle: String
    let showRegDateText: String
    let hidePhoneNumberTitle: String
    let hidePhoneNumberText: String
    let confirmCallsTitle: String
    let confirmCallsText: String
    
    // Локализация
    let localizationInfo: String
    let fullRussianUITitle: String
    let fullRussianUIText: String
    
    // Прочее
    let otherInfo: String
    let unlimitedAccountsTitle: String
    let unlimitedAccountsText: String
    let silentMessagesTitle: String
    let silentMessagesText: String
    let pinWalletTabTitle: String
    let pinWalletTabText: String
    let businessFeaturesTitle: String
    let businessFeaturesText: String
    let antiSelfDestructTitle: String
    let antiSelfDestructText: String
    let customIndicatorsTitle: String
    let customIndicatorsText: String
    let redDeleteIconTitle: String
    let redDeleteIconText: String
    
    // Hide UI
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
    
    // Dev
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

private func mqgramText(_ languageCode: String) -> MQGramText {
    if languageCode.lowercased().hasPrefix("ru") {
        return MQGramText(
            // Невидимость
            ghostInfo: "Режим призрака — не отправляет «прочитано», «печатает», «онлайн», просмотры историй. Все функции скрытного присутствия.",
            ghostModeTitle: "Режим призрака",
            ghostModeText: "Главный переключатель: блокирует все следы активности.",
            ghostReadReceiptsTitle: "Не отправлять прочитано",
            ghostReadReceiptsText: "Блокирует отправку отметки прочтения даже после отправки текста, фото, видео или файла.",
            ghostStoriesTitle: "Скрытый просмотр историй",
            ghostStoriesText: "Не отправляет отметку просмотра историй.",
            ghostContentReadsTitle: "Не читать медиа",
            ghostContentReadsText: "Не отправляет отметки для голосовых, видео, файлов и другого контента.",
            ghostPersonalActionsTitle: "Скрывать личные отметки",
            ghostPersonalActionsText: "Не отправляет прочтение личных упоминаний, реакций и голосований.",
            ghostScreenshotsTitle: "Скрывать скриншоты",
            ghostScreenshotsText: "Не отправляет уведомления о скриншотах в секретных чатах.",
            ghostDraftsTitle: "Скрывать черновики",
            ghostDraftsText: "Не синхронизирует набранный текст как облачный черновик.",
            ghostEmojiInteractionsTitle: "Скрывать emoji-действия",
            ghostEmojiInteractionsText: "Не отправляет emoji interaction и seen interaction.",
            ghostReactionsTitle: "Скрывать реакции (отправку)",
            ghostReactionsText: "Не отправляет реакции на сообщения и истории на сервер.",
            ghostStickerActivityTitle: "Скрывать стикеры",
            ghostStickerActivityText: "Не сохраняет недавние стикеры и просмотр новых наборов.",
            ghostOnlineStatusTitle: "Всегда оффлайн",
            ghostOnlineStatusText: "Отображайся оффлайн, даже когда сидишь в чатах.",
            ghostTypingActionsTitle: "Скрывать «печатает»",
            ghostTypingActionsText: "Скрывает набор текста, запись голоса, загрузку фото/видео.",
            alwaysOnlineTitle: "Вечный онлайн",
            alwaysOnlineText: "Всегда отображайся в сети, даже когда не в приложении.",
            messageSendingDelayTitle: "Задержка отправки",
            messageSendingDelayText: "Сообщения уходят с паузой, чтобы имитировать ручной ввод.",
            onlyReadWhenReplyingTitle: "Прочитать при ответе",
            onlyReadWhenReplyingText: "Отметка прочтения только когда сам отвечаешь.",
            onlyReadWhenReactingTitle: "Прочитать при реакции",
            onlyReadWhenReactingText: "Отметка прочтения только когда ставишь реакцию.",
            
            // Антиудаление
            antiDeleteInfo: "Удалённые сообщения остаются в чате. История редактирований по правому клику. Одноразовые медиа сохраняются.",
            antiRevokeTitle: "Анти-удаление",
            antiRevokeText: "Удалённые сообщения остаются в чате и помечаются значком.",
            antiEditTitle: "Анти-редактирование",
            antiEditText: "Показывает оригинальный текст отредактированных сообщений.",
            showEditHistoryTitle: "История редактирований",
            showEditHistoryText: "Правый клик на сообщении — показать все версии текста.",
            secretMediaSaverTitle: "Сохранение одноразовых",
            secretMediaSaverText: "Автоматически сохраняет исчезающие фото и видео.",
            savePhotosTitle: "Сохранять фото",
            savePhotosText: "Сохранять исчезающие фото при самоуничтожении.",
            saveVideosTitle: "Сохранять видео",
            saveVideosText: "Сохранять исчезающие видео при самоуничтожении.",
            
            // Без ограничений
            noLimitsInfo: "Обход защиты, блокировка рекламы, скрытие реакций и комментариев.",
            contentProtectionTitle: "Обход защиты контента",
            contentProtectionText: "Пересылка и сохранение медиа из защищённых каналов и чатов.",
            disableAdsTitle: "Блокировка рекламы",
            disableAdsText: "Убирает спонсорские сообщения и рекламу из каналов.",
            hideReactionsTitle: "Скрыть реакции",
            hideReactionsText: "Скрывает отображение реакций на сообщениях.",
            hideCommentTitle: "Скрыть комментарии",
            hideCommentText: "Скрывает кнопку комментариев под постами в каналах.",
            readUntilTitle: "Прочитать до сообщения",
            readUntilText: "Правый клик по сообщению — отметить всё прочитанным до него.",
            
            // Текст
            textInfo: "Автоматическая обработка текста перед отправкой.",
            antiCapsTitle: "Анти-капс",
            antiCapsText: "Автоматически переводит КАПС в нижний регистр.",
            autoTranslateTitle: "Авто-перевод",
            autoTranslateText: "Переводит текст перед отправкой через Google Translate.",
            autoFormatTitle: "Авто-формат",
            autoFormatText: "Каждое сообщение автоматически форматируется в выбранном стиле.",
            
            // Внешний вид
            appearanceInfo: "Кастомизация визуального оформления клиента.",
            customFontTitle: "Свой шрифт",
            customFontText: "Загрузить TTF или OTF шрифт для всех сообщений.",
            videoBackgroundTitle: "Видео/GIF фон чата",
            videoBackgroundText: "Установить видео или GIF как фон чата.",
            squareAvatarsTitle: "Квадратные аватары",
            squareAvatarsText: "Отображает аватары как квадраты вместо кругов.",
            deletedTransparencyTitle: "Прозрачность удалённых",
            deletedTransparencyText: "Удалённые сообщения отображаются полупрозрачными.",
            
            // Локальные фейки
            fakesInfo: "Локальные подделки — работают только на вашем устройстве.",
            fakePremiumTitle: "Фейковый Premium",
            fakePremiumText: "Разблокирует клиентские премиум-фичи без подписки.",
            fakeStarsTitle: "Фейковый баланс звёзд",
            fakeStarsText: "Показывает поддельный баланс звёзд в профиле.",
            localPremiumTitle: "Локальный Премиум",
            localPremiumText: "Активирует премиум-функции интерфейса локально без подписки.",
            
            // Профиль
            profileInfo: "Расширенная информация о профиле и управления звонками.",
            showPeerIdTitle: "ID любого юзера",
            showPeerIdText: "Показывает ID пользователя, чата, канала с копированием.",
            showRegDateTitle: "Дата регистрации",
            showRegDateText: "Примерная дата регистрации аккаунта в профиле.",
            hidePhoneNumberTitle: "Скрыть номер телефона",
            hidePhoneNumberText: "Прячет твой номер телефона в профиле и настройках.",
            confirmCallsTitle: "Подтверждение звонков",
            confirmCallsText: "Запрашивает подтверждение перед началом звонка.",
            
            // Локализация
            localizationInfo: "Язык интерфейса автоматически следует настройкам Telegram.",
            fullRussianUITitle: "Полный русский интерфейс",
            fullRussianUIText: "Переключается автоматически с языком Telegram.",
            
            // Прочее
            otherInfo: "Дополнительные функции для расширенного управления.",
            unlimitedAccountsTitle: "Безлимитные аккаунты",
            unlimitedAccountsText: "Снимает ограничение на количество добавленных аккаунтов.",
            silentMessagesTitle: "Тихие сообщения",
            silentMessagesText: "Отправляет сообщения без звукового уведомления по умолчанию.",
            pinWalletTabTitle: "Фиксатор вкладки Кошелёк",
            pinWalletTabText: "Закрепляет вкладку Кошелёк рядом с настройками.",
            businessFeaturesTitle: "Telegram для бизнеса",
            businessFeaturesText: "Активирует бизнес-функции профиля локально.",
            antiSelfDestructTitle: "Анти-самоуничтожение",
            antiSelfDestructText: "Сохраняет исчезающие фото/видео и убирает таймеры.",
            customIndicatorsTitle: "Свои индикаторы",
            customIndicatorsText: "Добавляет метки к перехваченному исчезающему контенту.",
            redDeleteIconTitle: "Красная корзина",
            redDeleteIconText: "Показывает красную иконку корзины при удалении сообщений.",
            
            // Hide UI
            hideInfo: "Скрывай элементы интерфейса, которыми не пользуешься.",
            hideNavigationBarTitle: "Скрыть бар навигации",
            hideNavigationBarText: "Прячет нижнюю панель навигации.",
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
            
            // Dev
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
            
            footer: "Функции MQGram. Для части изменений нужен перезапуск приложения."
        )
    }
    return MQGramText(
        // Invisibility
        ghostInfo: "Ghost Mode — no read receipts, typing indicators, online status, or story views. All stealth features.",
        ghostModeTitle: "Ghost Mode",
        ghostModeText: "Master switch: blocks all activity traces.",
        ghostReadReceiptsTitle: "Hide Read Receipts",
        ghostReadReceiptsText: "Blocks sending read receipts even after sending text, photos, videos, or files.",
        ghostStoriesTitle: "Hidden Story Views",
        ghostStoriesText: "Do not send story view receipts.",
        ghostContentReadsTitle: "Hide Media Reads",
        ghostContentReadsText: "Do not send consumed-content receipts for voice, video, files, and media.",
        ghostPersonalActionsTitle: "Hide Personal Marks",
        ghostPersonalActionsText: "Do not send seen marks for personal mentions, reactions, and poll votes.",
        ghostScreenshotsTitle: "Hide Screenshots",
        ghostScreenshotsText: "Do not send screenshot notifications in secret chats.",
        ghostDraftsTitle: "Hide Drafts",
        ghostDraftsText: "Do not sync typed text as a cloud draft.",
        ghostEmojiInteractionsTitle: "Hide Emoji Interactions",
        ghostEmojiInteractionsText: "Do not send emoji interaction and seen interaction actions.",
        ghostReactionsTitle: "Hide Reactions (sending)",
        ghostReactionsText: "Do not send reactions to messages and stories to server.",
        ghostStickerActivityTitle: "Hide Sticker Activity",
        ghostStickerActivityText: "Do not save recent stickers or seen featured packs.",
        ghostOnlineStatusTitle: "Always Offline",
        ghostOnlineStatusText: "Appear offline even when you are active in chats.",
        ghostTypingActionsTitle: "Hide Typing",
        ghostTypingActionsText: "Hides typing, voice recording, photo/video uploads.",
        alwaysOnlineTitle: "Always Online",
        alwaysOnlineText: "Always appear online, even when not in the app.",
        messageSendingDelayTitle: "Message Delay",
        messageSendingDelayText: "Messages are sent with a pause to simulate manual typing.",
        onlyReadWhenReplyingTitle: "Read on Reply",
        onlyReadWhenReplyingText: "Mark as read only when you reply.",
        onlyReadWhenReactingTitle: "Read on React",
        onlyReadWhenReactingText: "Mark as read only when you react.",
        
        // Anti-delete
        antiDeleteInfo: "Deleted messages stay in chat. Edit history via right-click. Self-destruct media is saved.",
        antiRevokeTitle: "Anti-Delete",
        antiRevokeText: "Deleted messages stay in chat and are marked with an icon.",
        antiEditTitle: "Anti-Edit",
        antiEditText: "Shows original text of edited messages.",
        showEditHistoryTitle: "Edit History",
        showEditHistoryText: "Right-click message to show all text versions.",
        secretMediaSaverTitle: "Save Self-Destruct Media",
        secretMediaSaverText: "Auto-save disappearing photos and videos.",
        savePhotosTitle: "Save Photos",
        savePhotosText: "Save self-destructing photos.",
        saveVideosTitle: "Save Videos",
        saveVideosText: "Save self-destructing videos.",
        
        // No Restrictions
        noLimitsInfo: "Bypass protection, block ads, hide reactions and comments.",
        contentProtectionTitle: "Forward Protection Bypass",
        contentProtectionText: "Forward and save media from restricted channels and chats.",
        disableAdsTitle: "Block Ads",
        disableAdsText: "Remove sponsored messages and ads from channels.",
        hideReactionsTitle: "Hide Reactions",
        hideReactionsText: "Hide reactions display on messages.",
        hideCommentTitle: "Hide Comments",
        hideCommentText: "Hide the comment button under channel posts.",
        readUntilTitle: "Read Until Message",
        readUntilText: "Right-click message to mark all read up to it.",
        
        // Text
        textInfo: "Automatic text processing before sending.",
        antiCapsTitle: "Anti-Caps",
        antiCapsText: "Automatically converts CAPS to lowercase.",
        autoTranslateTitle: "Auto-Translate",
        autoTranslateText: "Translate text before sending via Google Translate.",
        autoFormatTitle: "Auto-Format",
        autoFormatText: "Each message is automatically formatted in the selected style.",
        
        // Appearance
        appearanceInfo: "Visual customization of the client.",
        customFontTitle: "Custom Font",
        customFontText: "Load a TTF or OTF font for all messages.",
        videoBackgroundTitle: "Video/GIF Chat Background",
        videoBackgroundText: "Set a video or GIF as chat background.",
        squareAvatarsTitle: "Square Avatars",
        squareAvatarsText: "Display avatars as squares instead of circles.",
        deletedTransparencyTitle: "Deleted Transparency",
        deletedTransparencyText: "Deleted messages appear semi-transparent.",
        
        // Local Fakes
        fakesInfo: "Local fakes — only work on your device.",
        fakePremiumTitle: "Fake Premium",
        fakePremiumText: "Unlocks client-side premium features without subscription.",
        fakeStarsTitle: "Fake Stars Balance",
        fakeStarsText: "Shows a fake stars balance in profile.",
        localPremiumTitle: "Local Premium",
        localPremiumText: "Activates premium UI features locally without a subscription.",
        
        // Profile
        profileInfo: "Extended profile info and call management.",
        showPeerIdTitle: "User/Chat/Channel ID",
        showPeerIdText: "Show ID of any user, chat, or channel with copy.",
        showRegDateTitle: "Registration Date",
        showRegDateText: "Approximate account registration date in profile.",
        hidePhoneNumberTitle: "Hide Phone Number",
        hidePhoneNumberText: "Hides your phone number in profile and settings.",
        confirmCallsTitle: "Confirm Calls",
        confirmCallsText: "Ask for confirmation before starting a call.",
        
        // Localization
        localizationInfo: "Interface language follows Telegram settings automatically.",
        fullRussianUITitle: "Full Russian Interface",
        fullRussianUIText: "Switches automatically with Telegram language.",
        
        // Other
        otherInfo: "Extra features for extended app control.",
        unlimitedAccountsTitle: "Unlimited Accounts",
        unlimitedAccountsText: "Removes the limit on the number of added accounts.",
        silentMessagesTitle: "Silent Messages",
        silentMessagesText: "Send messages without sound notification by default.",
        pinWalletTabTitle: "Pin Wallet Tab",
        pinWalletTabText: "Pin the Wallet tab next to Settings.",
        businessFeaturesTitle: "Telegram for Business",
        businessFeaturesText: "Enable Business profile features locally.",
        antiSelfDestructTitle: "Anti-Self-Destruct",
        antiSelfDestructText: "Save disappearing photos/videos and remove timers.",
        customIndicatorsTitle: "Custom Indicators",
        customIndicatorsText: "Adds labels to intercepted disappearing content.",
        redDeleteIconTitle: "Red Delete Icon",
        redDeleteIconText: "Shows a red trash icon next to messages when deleting.",
        
        // Hide UI
        hideInfo: "Hide UI elements you don't use.",
        hideNavigationBarTitle: "Hide Navigation Bar",
        hideNavigationBarText: "Hides the bottom navigation bar.",
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
        
        // Dev
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
    case 0: // Невидимость / Invisibility
        entries.append(.info(1, text.ghostInfo))
        entries.append(.toggle(id, .ghostMode, text.ghostModeTitle, text.ghostModeText, settings.ghostMode)); id += 1
        entries.append(.toggle(id, .ghostReadReceipts, text.ghostReadReceiptsTitle, text.ghostReadReceiptsText, settings.ghostReadReceipts)); id += 1
        entries.append(.toggle(id, .ghostOnlineStatus, text.ghostOnlineStatusTitle, text.ghostOnlineStatusText, settings.ghostOnlineStatus)); id += 1
        entries.append(.toggle(id, .alwaysOnline, text.alwaysOnlineTitle, text.alwaysOnlineText, settings.alwaysOnline)); id += 1
        entries.append(.toggle(id, .ghostStories, text.ghostStoriesTitle, text.ghostStoriesText, settings.ghostStories)); id += 1
        entries.append(.toggle(id, .ghostTypingActions, text.ghostTypingActionsTitle, text.ghostTypingActionsText, settings.ghostTypingActions)); id += 1
        entries.append(.toggle(id, .ghostContentReads, text.ghostContentReadsTitle, text.ghostContentReadsText, settings.ghostContentReads)); id += 1
        entries.append(.toggle(id, .ghostPersonalActions, text.ghostPersonalActionsTitle, text.ghostPersonalActionsText, settings.ghostPersonalActions)); id += 1
        entries.append(.toggle(id, .ghostScreenshots, text.ghostScreenshotsTitle, text.ghostScreenshotsText, settings.ghostScreenshots)); id += 1
        entries.append(.toggle(id, .ghostDrafts, text.ghostDraftsTitle, text.ghostDraftsText, settings.ghostDrafts)); id += 1
        entries.append(.toggle(id, .ghostEmojiInteractions, text.ghostEmojiInteractionsTitle, text.ghostEmojiInteractionsText, settings.ghostEmojiInteractions)); id += 1
        entries.append(.toggle(id, .ghostReactions, text.ghostReactionsTitle, text.ghostReactionsText, settings.ghostReactions)); id += 1
        entries.append(.toggle(id, .ghostStickerActivity, text.ghostStickerActivityTitle, text.ghostStickerActivityText, settings.ghostStickerActivity)); id += 1
        entries.append(.toggle(id, .messageSendingDelay, text.messageSendingDelayTitle, text.messageSendingDelayText, settings.messageSendingDelay)); id += 1
        entries.append(.toggle(id, .onlyReadWhenReplying, text.onlyReadWhenReplyingTitle, text.onlyReadWhenReplyingText, settings.onlyReadWhenReplying)); id += 1
        entries.append(.toggle(id, .onlyReadWhenReacting, text.onlyReadWhenReactingTitle, text.onlyReadWhenReactingText, settings.onlyReadWhenReacting))

    case 1: // Антиудаление / Anti-delete
        entries.append(.info(1, text.antiDeleteInfo))
        entries.append(.toggle(id, .antiRevoke, text.antiRevokeTitle, text.antiRevokeText, settings.antiRevoke)); id += 1
        entries.append(.toggle(id, .antiEdit, text.antiEditTitle, text.antiEditText, settings.antiEdit)); id += 1
        entries.append(.toggle(id, .showEditHistory, text.showEditHistoryTitle, text.showEditHistoryText, settings.showEditHistory)); id += 1
        entries.append(.toggle(id, .secretMediaSaver, text.secretMediaSaverTitle, text.secretMediaSaverText, settings.secretMediaSaver)); id += 1
        entries.append(.toggle(id, .antiSelfDestructSavePhotos, text.savePhotosTitle, text.savePhotosText, settings.antiSelfDestructSavePhotos)); id += 1
        entries.append(.toggle(id, .antiSelfDestructSaveVideos, text.saveVideosTitle, text.saveVideosText, settings.antiSelfDestructSaveVideos)); id += 1
        entries.append(.toggle(id, .antiSelfDestruct, text.antiSelfDestructTitle, text.antiSelfDestructText, settings.antiSelfDestruct)); id += 1
        entries.append(.toggle(id, .customIndicators, text.customIndicatorsTitle, text.customIndicatorsText, settings.customIndicators)); id += 1
        let recycleBinTitle = strings.baseLanguageCode.lowercased().hasPrefix("ru") ? "Корзина удалённых" : "Recycle Bin"
        entries.append(.action(id, recycleBinTitle, makeRecycleBinIcon()))

    case 2: // Без ограничений / No Restrictions
        entries.append(.info(1, text.noLimitsInfo))
        entries.append(.toggle(id, .contentProtectionBypass, text.contentProtectionTitle, text.contentProtectionText, settings.contentProtectionBypass)); id += 1
        entries.append(.toggle(id, .disableAds, text.disableAdsTitle, text.disableAdsText, settings.disableAds)); id += 1
        entries.append(.toggle(id, .hideReactions, text.hideReactionsTitle, text.hideReactionsText, settings.hideReactions)); id += 1
        entries.append(.toggle(id, .hideCommentButton, text.hideCommentTitle, text.hideCommentText, settings.hideCommentButton)); id += 1
        entries.append(.toggle(id, .readUntilMessage, text.readUntilTitle, text.readUntilText, settings.readUntilMessage))

    case 3: // Текст / Text
        entries.append(.info(1, text.textInfo))
        entries.append(.toggle(id, .antiCaps, text.antiCapsTitle, text.antiCapsText, settings.antiCaps)); id += 1
        entries.append(.toggle(id, .autoTranslate, text.autoTranslateTitle, text.autoTranslateText, settings.autoTranslate)); id += 1
        entries.append(.toggle(id, .autoFormat, text.autoFormatTitle, text.autoFormatText, settings.autoFormat))

    case 4: // Внешний вид / Appearance
        entries.append(.info(1, text.appearanceInfo))
        entries.append(.toggle(id, .customFont, text.customFontTitle, text.customFontText, settings.customFont)); id += 1
        entries.append(.toggle(id, .videoBackground, text.videoBackgroundTitle, text.videoBackgroundText, settings.videoBackground)); id += 1
        entries.append(.toggle(id, .squareAvatars, text.squareAvatarsTitle, text.squareAvatarsText, settings.squareAvatars)); id += 1
        entries.append(.toggle(id, .deletedMessageTransparency, text.deletedTransparencyTitle, text.deletedTransparencyText, settings.deletedMessageTransparency)); id += 1
        entries.append(.toggle(id, .redDeleteIcon, text.redDeleteIconTitle, text.redDeleteIconText, settings.redDeleteIcon))

    case 5: // Локальные фейки / Local Fakes
        entries.append(.info(1, text.fakesInfo))
        entries.append(.toggle(id, .fakePremium, text.fakePremiumTitle, text.fakePremiumText, settings.fakePremium)); id += 1
        entries.append(.toggle(id, .fakeStarsBalance, text.fakeStarsTitle, text.fakeStarsText, settings.fakeStarsBalance)); id += 1
        entries.append(.toggle(id, .localPremium, text.localPremiumTitle, text.localPremiumText, settings.localPremium))

    case 6: // Профиль / Profile
        entries.append(.info(1, text.profileInfo))
        entries.append(.toggle(id, .showPeerId, text.showPeerIdTitle, text.showPeerIdText, settings.showPeerId)); id += 1
        entries.append(.toggle(id, .showRegDate, text.showRegDateTitle, text.showRegDateText, settings.showRegDate)); id += 1
        entries.append(.toggle(id, .hidePhoneNumber, text.hidePhoneNumberTitle, text.hidePhoneNumberText, settings.hidePhoneNumber)); id += 1
        entries.append(.toggle(id, .confirmCalls, text.confirmCallsTitle, text.confirmCallsText, settings.confirmCalls))

    case 7: // Локализация / Localization
        entries.append(.info(1, text.localizationInfo))
        entries.append(.toggle(id, .fullRussianUI, text.fullRussianUITitle, text.fullRussianUIText, settings.fullRussianUI)); id += 1
        entries.append(.link(id, text.languageTitle, "tg://settings/language", true, nil))

    case 8: // Прочее / Other
        entries.append(.info(1, text.otherInfo))
        entries.append(.toggle(id, .unlimitedAccounts, text.unlimitedAccountsTitle, text.unlimitedAccountsText, settings.unlimitedAccounts)); id += 1
        entries.append(.toggle(id, .silentMessages, text.silentMessagesTitle, text.silentMessagesText, settings.silentMessages)); id += 1
        entries.append(.toggle(id, .pinWalletTab, text.pinWalletTabTitle, text.pinWalletTabText, settings.pinWalletTab)); id += 1
        entries.append(.toggle(id, .businessFeatures, text.businessFeaturesTitle, text.businessFeaturesText, settings.businessFeatures))

    case 9: // Скрыть / Hide UI
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

    case 10: // Dev
        entries.append(.info(1, text.devInfo))
        entries.append(.link(id, "GitHub", "https://github.com/jutsodev", false, makeGitHubIcon())); id += 1
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

// MARK: - Controller

public func mqgramSettingsController(context: AccountContext) -> ViewController {
    let updatePromise = ValuePromise<Bool>(true, ignoreRepeated: false)
    let tabIndexPromise = ValuePromise<Int>(0, ignoreRepeated: false)
    let previousTabIndex = Atomic<Int?>(value: nil)

    var openUrlImpl: ((String, Bool) -> Void)?
    var openRecycleBinImpl: (() -> Void)?

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
        }
    )

    let tabNamesRu: [String] = ["Невидимость", "Антиудаление", "Без ограничений", "Текст", "Внешний вид", "Фейки", "Профиль", "Локализация", "Прочее", "Скрыть", "Dev"]
    let tabNamesEn: [String] = ["Invisible", "Anti-Delete", "No Limits", "Text", "Appearance", "Fakes", "Profile", "i18n", "Other", "Hide", "Dev"]

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

    return controller
}
