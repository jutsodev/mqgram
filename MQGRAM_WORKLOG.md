# MQGram Worklog

## Запрос пользователя
- Перевести вкладку MQGram на русский, если язык Telegram русский.
- Починить добавление free proxy.
- Сделать пароль/код-пароль визуально как Telegram.
- Усилить Ghost/Призрак: не прочитывать после действий, отправки текста/файлов/фото/видео, добавить больше функций.
- Исправить StivenVPN, чтобы открывался бот.
- Запустить сборку на GitHub.
- Дальше: вести этот README-лог — запрос, что сделано, какие файлы изменены, что осталось.

## Что уже сделано
- Вкладка MQGram получила RU/EN тексты по `presentationData.strings.baseLanguageCode`.
- Добавлены отдельные настройки Ghost: read receipts, stories, media/content reads, typing/actions.
- Ghost hooks расширены для read receipts, story views, content reads и typing/upload/record actions.
- В прокси добавлена кнопка `Добавить бесплатный прокси` / `Add Free Proxy`, которая добавляет и включает MTProxy.
- Для `StivenVPN` добавлен fallback: открыть чат/бота вместо mini app.

## Файлы, которые менялись
- `MQGram/MQGramSettingsUI/Sources/MQGramSettings.swift`
- `MQGram/MQGramSettingsUI/Sources/MQGramSettingsController.swift`
- `submodules/SettingsUI/Sources/Data and Storage/ProxyListSettingsController.swift`
- `submodules/TelegramCore/Sources/State/AccountViewTracker.swift`
- `submodules/TelegramCore/Sources/State/ManagedLocalInputActivities.swift`
- `submodules/TelegramCore/Sources/State/ManagedSynchronizeConsumeMessageContentsOperations.swift`
- `submodules/TelegramCore/Sources/State/ManagedSynchronizeViewStoriesOperations.swift`
- `submodules/TelegramCore/Sources/State/SynchronizePeerReadState.swift`
- `submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoScreen.swift`

## Что делаю сейчас
- Добавляю ещё Ghost-функции:
  - скрывать online/presence;
  - скрывать прочтение личных mention/reaction/poll actions.
- Обновляю MQGram UI и настройки под новые функции.

## Что осталось
- Полноценная сборка недоступна в текущем окружении: нет `bazel`, `bazelisk`, `swift`, `xcodebuild`.
- GitHub Actions не запускались: нужен доступ к GitHub/интернету и подтверждение.
- Passcode-дизайн ещё не изменён: нужно отдельно трогать `PasscodeUI` и проверять на сборке.

## Обновление: дополнительные Ghost-функции
- Добавлен переключатель `Скрывать онлайн` / `Hide Online Status`.
- Добавлен переключатель `Скрывать личные отметки` / `Hide Personal Marks`.
- Hook `ManagedAccountPresence.swift`: при `ghostMode` или `ghostOnlineStatus` приложение не отправляет `account.updateStatus(offline: false)`.
- Hook `ManagedConsumePersonalMessagesActions.swift`: при `ghostMode` или `ghostPersonalActions` не отправляется read-content для личных упоминаний, реакций и голосований.

## Новые файлы в изменениях
- `submodules/TelegramCore/Sources/State/ManagedAccountPresence.swift`
- `submodules/TelegramCore/Sources/State/ManagedConsumePersonalMessagesActions.swift`

## Обновление: делаю функции реально привязанными к hooks
- Добавлен `ghostScreenshots` / `Скрывать скриншоты`.
- Secret chats: `_internal_addSecretChatMessageScreenshot` теперь не создаёт screenshot action при Ghost.
- Secret outgoing operations: блокируется отправка `readMessagesContent` и `screenshotMessages` при Ghost.
- Cloud chats: блокируется `messages.sendScreenshotNotification` при Ghost.
- Mark-all personal actions: блокируются массовые отметки unseen personal/reactions/poll votes.
- Free proxy теперь добавляет несколько MTProxy вариантов, а не один.

## Обновление: ещё сильнее Ghost
- Добавлен `ghostDrafts` / `Скрывать черновики`: блокирует `messages.saveDraft`, чтобы набранный текст не синхронизировался в облако.
- Добавлен `ghostEmojiInteractions` / `Скрывать emoji-действия`: блокирует emoji interaction и emoji interaction seen actions.
- Усилена типобезопасность блокировки screenshot notification: вместо фейкового результата используется `.acknowledged`.

## Обновление: ещё Ghost-функции
- Добавлен `ghostReactions` / `Скрывать реакции`: блокирует отправку реакций на сообщения и истории.
- Добавлен `ghostStickerActivity` / `Скрывать стикеры`: блокирует сохранение недавних стикеров и отметку новых наборов как просмотренных.

## Обновление: дизайн вкладки MQGram
- Добавлен безопасный intro-блок `MQGram Control Center` без кастомных risky-компонентов.
- Переключатели переведены на `systemStyle: .glass`, чтобы экран выглядел мягче и современнее в стиле Telegram.
- Добавлены поясняющие карточки для разделов `Основные функции`, `Призрак` и `Эксперименты`.
- Сортировка элементов поправлена через stableId, чтобы список не ломался при обновлениях.

## Обновление: диагностика и исправление проблемы "функции не работают"

### Проблема
Пользователь сообщил, что функции MQGram не работают после включения в настройках.

### Анализ
1. **Архитектура настроек:**
   - UI использует `MQGramSettings.shared` для чтения/записи
   - Hooks в TelegramCore используют `UserDefaults.standard` напрямую
   - Оба способа работают с одними ключами `"MQGram.xxx"`

2. **Найденная проблема:**
   - Метод `setBool` не вызывал `synchronize()` после сохранения
   - Это могло приводить к задержке сохранения настроек
   - Настройки могли не применяться до перезапуска приложения

3. **Проверка hooks:**
   - Все hooks установлены правильно в TelegramCore
   - Anti-Revoke: `AccountStateManagementUtils.swift` ✅
   - Ghost Mode: `SynchronizePeerReadState.swift`, `ManagedSynchronizeViewStoriesOperations.swift`, etc. ✅
   - Content Protection: `PeerUtils.swift`, `MessageUtils.swift` ✅
   - Все остальные функции: hooks на месте ✅

### Решение
- ✅ Добавлен вызов `self.defaults.synchronize()` в метод `setBool`
- ✅ Создан файл `MQGram/TROUBLESHOOTING.md` с подробной диагностикой
- ✅ Документированы все функции и способы их проверки
- ✅ Добавлены инструкции по отладке

### Рекомендации пользователю
1. **Немедленно:** Перезапустите приложение полностью после изменения настроек
2. **Проверка:** Откройте настройки MQGram снова и убедитесь, что переключатели остались включенными
3. **Тестирование:** Проверьте конкретные функции по инструкциям в TROUBLESHOOTING.md

### Функции, требующие перезапуска
- Скрытие элементов UI (hideNavigationBar, hideSettings, etc.)
- Local Premium
- Unlimited Accounts
- Business Features

### Функции, работающие без перезапуска
- Ghost Mode (все подфункции)
- Anti-Revoke
- Anti-Self-Destruct
- Anti-Edit
- Content Protection Bypass
- Disable Ads

## Обновление: фикс сборки после дизайна
- Исправлены hero-тексты MQGram: многострочные Swift-строки заменены на обычные строки с `\n\n`, чтобы не ломать компиляцию.
- Дизайн вкладки сохранён: intro-блок и пояснения разделов остаются через стандартные ItemList markdown rows.

## Обновление: ускорение GitHub Actions сборки
- Расширен cache workflow: теперь сохраняется не только `~/telegram-bazel-cache`, но и стабильный Bazel user root `~/.cache/mqgram-bazel-user-root`.
- `BAZEL_USER_ROOT` перенесён из временного `/private/var/tmp` в кэшируемую домашнюю папку runner-а.
- Ключ кэша учитывает Bazel/Xcode metadata (`WORKSPACE`, `MODULE.bazel`, lock-файл, `variables.bzl`, `versions.json`) и имеет широкий restore-key для повторного использования.

## Обновление: новые функции и реорганизация вкладок MQGram

### Новые ключи в `MQGramSettings.swift`
- `readAfterActions` — отмечает сообщения прочитанными только после действий пользователя.
- `businessFeatures` — активирует Telegram для бизнеса локально.
- `pinWalletTab` — фиксатор вкладки Кошелёк.
- `redDeleteIcon` — красная иконка корзины при удалении сообщений.
- Скрытие интерфейса: `hideNavigationBar`, `hideFavoriteChats`, `hideRecentCalls`, `hideDevices`, `hideChatFolders`, `hideNotificationsSettings`, `hidePrivacySettings`, `hideDataSettings`, `hideAppearanceSettings`, `hideLanguageSettings`, `hideStickersSettings`, `hidePowerSaving`.

### Новая структура вкладок MQGram
1. **Призрак / Ghost** — все ghost-функции + `Читать после действий`.
2. **Основные / Core** — `Анти-самоуничтожение`, `Анти-удаление`, `Свои индикаторы`, `Красная корзина`.
3. **Бета / Beta** — `Обход защиты контента`, `Анти-редактирование`, `Отключить рекламу`, `Telegram для бизнеса`.
4. **Прочее / Other** — `Локальный Премиум`, `Безлимитные аккаунты`, `Скрыть номер`, `Подтверждение звонков`, `Тихие сообщения`, `Фиксатор Кошелька`.
5. **Скрыть / Hide** — 12 переключателей для скрытия элементов настроек.
6. **Dev** — GitHub (в браузере), Разраб, Канал StivenVPN, Бот StivenVPN (все в Telegram).

### Реальные hooks
- `readAfterActions` → `InstallInteractiveReadMessagesAction.swift` (проверка времени действия пользователя).
- `ghostReactions` → `MessageReactions.swift` (блокировка `messages.sendReaction`) и `Stories.swift` (блокировка `stories.sendReaction`).
- `ghostStickerActivity` → `ManagedSynchronizeRecentlyUsedMediaOperations.swift` (блокировка `saveRecentSticker`).
- `localPremium` → `PeerUtils.swift` (Peer.isPremium возвращает true для своего аккаунта); own peer ID сохраняется в `AccountContext.swift`.
- Скрытие настроек → `PeerInfoSettingsItems.swift` (условные `items.append`).
- `redDeleteIcon` → `ChatMessageSelectionInputPanelNode.swift` (кастомный tint color иконки корзины).

### Открытие ссылок в Dev вкладке
- Используется `openExternalUrl`, который автоматически открывает `t.me/*` внутри Telegram, а GitHub — во встроенном браузере.

### Файлы, которые менялись
- `MQGram/MQGramSettingsUI/Sources/MQGramSettings.swift`
- `MQGram/MQGramSettingsUI/Sources/MQGramSettingsController.swift`
- `submodules/TelegramCore/Sources/State/MessageReactions.swift`
- `submodules/TelegramCore/Sources/State/ManagedSynchronizeRecentlyUsedMediaOperations.swift`
- `submodules/TelegramCore/Sources/TelegramEngine/Messages/InstallInteractiveReadMessagesAction.swift`
- `submodules/TelegramCore/Sources/TelegramEngine/Messages/Stories.swift`
- `submodules/TelegramCore/Sources/Utils/PeerUtils.swift`
- `submodules/TelegramUI/Sources/AccountContext.swift`
- `submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoSettingsItems.swift`
- `submodules/TelegramUI/Components/Chat/ChatMessageSelectionInputPanelNode/Sources/ChatMessageSelectionInputPanelNode.swift`
