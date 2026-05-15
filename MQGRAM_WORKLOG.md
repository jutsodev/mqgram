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

## Обновление: фикс сборки после дизайна
- Исправлены hero-тексты MQGram: многострочные Swift-строки заменены на обычные строки с `\n\n`, чтобы не ломать компиляцию.
- Дизайн вкладки сохранён: intro-блок и пояснения разделов остаются через стандартные ItemList markdown rows.
