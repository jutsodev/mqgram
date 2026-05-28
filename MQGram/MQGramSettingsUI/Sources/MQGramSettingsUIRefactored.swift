// MARK: MQGram - Redesigned Settings UI with Categories
import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramPresentationData
import ItemListUI
import PresentationDataUtils
import AccountContext

// MARK: - Settings Categories
enum MQGramSettingsCategory: Int, CaseIterable {
    case privacy = 0          // Приватность / Privacy
    case appearance = 1       // Внешний вид / Appearance
    case content = 2          // Контент / Content
    case messages = 3         // Сообщения / Messages
    case advanced = 4         // Расширенные / Advanced
    case other = 5            // Другое / Other
    
    var title: String {
        switch self {
        case .privacy: return "🔒 Приватность"
        case .appearance: return "🎨 Внешний вид"
        case .content: return "📦 Контент"
        case .messages: return "💬 Сообщения"
        case .advanced: return "⚙️ Расширенные"
        case .other: return "📋 Другое"
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

// MARK: - Settings Item Model
struct MQGramSettingsItem {
    let key: MQGramSettings.Key
    let title: String
    let description: String
    let icon: String
    let category: MQGramSettingsCategory
}

// MARK: - Category View Controller
public func mqgramCategoryViewController(context: AccountContext, category: MQGramSettingsCategory) -> ViewController {
    var dismissImpl: (() -> Void)?
    
    let items = getMQGramItemsForCategory(category)
    var entries: [ItemListNodeEntry] = []
    var id = 0
    
    // Header
    entries.append(.info(id, "\(category.emoji) \(category.title)\n\(category.description)")); id += 1
    
    // Settings items
    for item in items {
        let currentValue = UserDefaults.standard.bool(forKey: "MQGram.\(item.key.rawValue)")
        entries.append(.toggle(id, item.key, item.title, item.description, { value in
            UserDefaults.standard.set(value, forKey: "MQGram.\(item.key.rawValue)")
            MQGramSettings.shared.setBool(value, for: item.key)
        })); id += 1
    }
    
    entries.append(.footer(id, ""))
    
    let controller = ItemListViewController(
        context: context,
        state: ItemListControllerState(
            theme: context.sharedContext.currentPresentationData.with { $0.theme },
            title: .text(category.title),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: "Назад"),
            animateChanges: false
        ),
        tabBarItem: nil,
        sections: [ItemListSection(id: 0, header: nil, footer: nil, items: [])]
    )
    
    dismissImpl = { [weak controller] in
        controller?.dismiss()
    }
    
    return controller
}

// MARK: - Get items for category
private func getMQGramItemsForCategory(_ category: MQGramSettingsCategory) -> [MQGramSettingsItem] {
    switch category {
    case .privacy:
        return [
            MQGramSettingsItem(key: .ghostMode, title: "🫥 Режим призрака", description: "Полное скрытие активности", category: .privacy),
            MQGramSettingsItem(key: .ghostReadReceipts, title: "✔️ Скрывать прочтение", description: "Не отправлять информацию о прочтении", category: .privacy),
            MQGramSettingsItem(key: .ghostOnlineStatus, title: "⏱️ Всегда оффлайн", description: "Никогда не отправлять онлайн-статус", category: .privacy),
            MQGramSettingsItem(key: .ghostTypingActions, title: "✍️ Скрывать печать", description: "Не показывать что вы пишете", category: .privacy),
            MQGramSettingsItem(key: .ghostStories, title: "📖 Скрывать просмотры историй", description: "Никто не узнает что вы видели историю", category: .privacy),
            MQGramSettingsItem(key: .alwaysOnline, title: "🟢 Вечный онлайн", description: "Всегда показывать статус онлайн", category: .privacy),
            MQGramSettingsItem(key: .alwaysOffline, title: "🔴 Всегда оффлайн", description: "Всегда отображаться как оффлайн", category: .privacy),
            MQGramSettingsItem(key: .confirmCalls, title: "☎️ Подтверждать звонки", description: "Спрашивать перед принятием звонка", category: .privacy),
        ]
    
    case .appearance:
        return [
            MQGramSettingsItem(key: .squareAvatars, title: "⬛ Квадратные аватары", description: "Аватары в виде квадратов вместо кругов", category: .appearance),
            MQGramSettingsItem(key: .videoBackground, title: "🎬 Видеофон чата", description: "Анимированный фон в чатах", category: .appearance),
            MQGramSettingsItem(key: .customFont, title: "🔤 Свой шрифт", description: "Загрузить кастомный .ttf или .otf файл", category: .appearance),
            MQGramSettingsItem(key: .deletedMessageTransparency, title: "👻 Прозрачные удалённые", description: "Удалённые сообщения с прозрачностью", category: .appearance),
        ]
    
    case .content:
        return [
            MQGramSettingsItem(key: .antiSelfDestruct, title: "💾 Сохранять самоуничтожающееся", description: "Сохранять фото/видео которые исчезают", category: .content),
            MQGramSettingsItem(key: .secretMediaSaver, title: "🔐 Сохранять из секретных чатов", description: "Сохранять медиа из секретных чатов", category: .content),
            MQGramSettingsItem(key: .antiRevoke, title: "🔄 Восстанавливать удалённые", description: "Удалённые сообщения остаются видны", category: .content),
            MQGramSettingsItem(key: .showEditHistory, title: "📝 История редактирования", description: "Смотреть историю всех редактирований", category: .content),
            MQGramSettingsItem(key: .showRegDate, title: "📅 Дата регистрации", description: "Показывать примерную дату регистрации", category: .content),
        ]
    
    case .messages:
        return [
            MQGramSettingsItem(key: .messageSendingDelay, title: "⏳ Задержка отправки", description: "Сообщения отправляются с паузой", category: .messages),
            MQGramSettingsItem(key: .antiCaps, title: "🔤 Авто-преобразование КАПСА", description: "ТЕКСТ → текст автоматически", category: .messages),
            MQGramSettingsItem(key: .autoTranslate, title: "🌐 Автоперевод", description: "Переводить сообщения перед отправкой", category: .messages),
            MQGramSettingsItem(key: .autoFormat, title: "✨ Автоформатирование", description: "Применять стиль ко всем сообщениям", category: .messages),
            MQGramSettingsItem(key: .silentMessages, title: "🔇 Беззвучные сообщения", description: "Отправлять без звука уведомления", category: .messages),
        ]
    
    case .advanced:
        return [
            MQGramSettingsItem(key: .ghostDrafts, title: "📄 Скрывать черновики", description: "Не синхронизировать черновики", category: .advanced),
            MQGramSettingsItem(key: .ghostEmojiInteractions, title: "😊 Скрывать emoji-взаимодействия", description: "Не отправлять реакции эмодзи", category: .advanced),
            MQGramSettingsItem(key: .ghostReactions, title: "👍 Скрывать реакции", description: "Скрывать отправку реакций на сообщения", category: .advanced),
            MQGramSettingsItem(key: .ghostStickerActivity, title: "🎨 Скрывать стикеры", description: "Не сохранять недавние стикеры", category: .advanced),
            MQGramSettingsItem(key: .ghostScreenshots, title: "📸 Отключить уведомления о скриншоте", description: "Не получать уведомления о скриншотах", category: .advanced),
            MQGramSettingsItem(key: .hideReactions, title: "🙈 Скрывать реакции от других", description: "Скрывать счётчик реакций в чатах", category: .advanced),
            MQGramSettingsItem(key: .hideCommentButton, title: "💬 Скрывать кнопку комментариев", description: "Убрать кнопку для ответа в комментарии", category: .advanced),
        ]
    
    case .other:
        return [
            MQGramSettingsItem(key: .fakePremium, title: "⭐ Фейк Premium", description: "Отображать как подписчик Telegram Premium", category: .other),
            MQGramSettingsItem(key: .fakeStarsBalance, title: "💫 Фейк баланс звёзд", description: "Показывать поддельный баланс звёзд", category: .other),
            MQGramSettingsItem(key: .localPremium, title: "👑 Локальный Premium", description: "Разблокировать функции как в Premium", category: .other),
            MQGramSettingsItem(key: .showPeerId, title: "🔢 Показывать ID", description: "Отображать ID пользователей и чатов", category: .other),
            MQGramSettingsItem(key: .hidePhoneNumber, title: "📱 Скрывать номер телефона", description: "Скрыть номер в профиле", category: .other),
        ]
    }
}

// MARK: - Main Settings List with Categories
public func mqgramCategoryListViewController(context: AccountContext) -> ViewController {
    var entries: [ItemListNodeEntry] = []
    var id = 0
    
    entries.append(.info(id, "MQGram Settings\n\nВыбери категорию функций")); id += 1
    
    for category in MQGramSettingsCategory.allCases {
        entries.append(.disclosure(id, category.title, category.description, { openCategoryImpl?(category) })); id += 1
    }
    
    entries.append(.footer(id, "💡 Каждая категория содержит функции по теме"))
    
    let controller = ItemListViewController(
        context: context,
        state: ItemListControllerState(
            theme: context.sharedContext.currentPresentationData.with { $0.theme },
            title: .text("Функции MQGram"),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: "Назад"),
            animateChanges: false
        ),
        tabBarItem: nil,
        sections: [ItemListSection(id: 0, header: nil, footer: nil, items: [])]
    )
    
    return controller
}

private var openCategoryImpl: ((MQGramSettingsCategory) -> Void)?
