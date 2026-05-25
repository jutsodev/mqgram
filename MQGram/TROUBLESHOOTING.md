# MQGram Troubleshooting Guide / Руководство по устранению неполадок

## Проблема: Функции MQGram не работают

### Возможные причины

#### 1. Настройки не сохраняются
**Симптомы:**
- Переключатели в настройках MQGram включаются, но функции не работают
- После перезапуска приложения настройки сбрасываются

**Решение:**
- ✅ **ИСПРАВЛЕНО**: Добавлен вызов `synchronize()` в метод `setBool`
- Теперь настройки должны сохраняться немедленно

**Как проверить:**
1. Откройте настройки MQGram (долгое нажатие на "Telegram Stars")
2. Включите любую функцию (например, "Анти-удаление")
3. Закройте и снова откройте настройки MQGram
4. Проверьте, что переключатель остался включенным

#### 2. Приложение не перезапущено после изменения настроек
**Симптомы:**
- Настройки сохраняются, но функции не работают до перезапуска

**Решение:**
- Некоторые функции требуют **полного перезапуска приложения**
- Закройте приложение полностью (свайп вверх в переключателе приложений)
- Запустите приложение заново

**Функции, требующие перезапуска:**
- ❌ Скрытие элементов UI (Hide Navigation Bar, Hide Settings, etc.)
- ❌ Local Premium
- ❌ Unlimited Accounts
- ❌ Business Features

**Функции, работающие без перезапуска:**
- ✅ Ghost Mode и все его подфункции
- ✅ Anti-Revoke (Анти-удаление)
- ✅ Anti-Self-Destruct (Анти-самоуничтожение)
- ✅ Anti-Edit (Анти-редактирование)
- ✅ Content Protection Bypass
- ✅ Disable Ads

#### 3. Hooks не установлены в коде
**Симптомы:**
- Настройки сохраняются, приложение перезапущено, но функции не работают

**Проверка:**
Убедитесь, что в коде установлены все необходимые hooks. Проверьте файлы:

```bash
# Проверка Anti-Revoke hooks
grep -n "MQGram.*antiRevoke" submodules/TelegramCore/Sources/State/AccountStateManagementUtils.swift

# Проверка Ghost Mode hooks
grep -n "MQGram.*ghost" submodules/TelegramCore/Sources/State/*.swift

# Проверка всех MQGram hooks
grep -rn "MQGram\." submodules/
```

**Ожидаемые результаты:**
- `AccountStateManagementUtils.swift`: Anti-Revoke, Anti-Edit hooks
- `SynchronizePeerReadState.swift`: Ghost Mode read receipts
- `ManagedSynchronizeViewStoriesOperations.swift`: Ghost Mode stories
- `MessageReactions.swift`: Ghost Mode reactions
- `PeerUtils.swift`: Content Protection Bypass, Local Premium
- И другие...

#### 4. Конфликт с Swiftgram настройками
**Симптомы:**
- Некоторые функции работают странно или конфликтуют

**Решение:**
- MQGram **скрывает** настройки Swiftgram и Swiftgram Pro
- Убедитесь, что вы используете **только настройки MQGram**
- Не пытайтесь использовать обе системы настроек одновременно

#### 5. Проблемы с UserDefaults в sideload-сборках
**Симптомы:**
- Настройки не сохраняются при установке через Sideloadly/AltStore

**Решение:**
- MQGram использует `UserDefaults.standard` вместо App Group
- Это должно работать даже с бесплатным Apple ID
- Если проблема сохраняется, попробуйте:
  1. Удалить приложение полностью
  2. Переустановить
  3. Настроить заново

### Диагностика конкретных функций

#### Anti-Revoke (Анти-удаление)
**Как работает:**
- Перехватывает `updateDeleteMessages` и `updateDeleteChannelMessages`
- Сохраняет snapshot сообщения перед удалением
- Помечает удаленные сообщения специальным атрибутом

**Проверка:**
1. Включите "Анти-удаление" в настройках MQGram
2. Попросите кого-то отправить вам сообщение
3. Попросите его удалить это сообщение
4. Вы должны увидеть сообщение с пометкой "удалено"

**Если не работает:**
- Проверьте, что настройка `MQGram.antiRevoke` = `true` в UserDefaults
- Проверьте логи: `MQDeletedMessages.saveSnapshots` должен вызываться
- Проверьте, что модуль `MQDeletedMessages` скомпилирован

#### Ghost Mode (Режим призрака)
**Как работает:**
- Блокирует отправку read receipts, story views, typing actions, etc.
- Каждая подфункция работает независимо

**Проверка:**
1. Включите "Режим призрака" или конкретную подфункцию
2. Откройте чат и прочитайте сообщения
3. Собеседник не должен видеть "прочитано"

**Если не работает:**
- Проверьте, что включена **главная** функция "Режим призрака" ИЛИ конкретная подфункция
- Некоторые подфункции работают независимо от главного переключателя
- Проверьте hooks в файлах:
  - `SynchronizePeerReadState.swift` (read receipts)
  - `ManagedSynchronizeViewStoriesOperations.swift` (stories)
  - `ManagedLocalInputActivities.swift` (typing actions)

#### Anti-Self-Destruct (Анти-самоуничтожение)
**Как работает:**
- Перехватывает disappearing photos/videos
- Убирает таймер автоудаления
- Опционально оставляет визуальный индикатор (Custom Indicators)

**Проверка:**
1. Включите "Анти-самоуничтожение"
2. Попросите кого-то отправить вам "view once" фото
3. Фото должно остаться после просмотра

**Если не работает:**
- Проверьте hook в `StoreMessage_Telegram.swift`
- Проверьте hook в `ManagedAutoremoveMessageOperations.swift`

#### Content Protection Bypass (Обход защиты контента)
**Как работает:**
- Возвращает `false` из `Peer.isCopyProtectionEnabled`
- Возвращает `false` из `Message.isCopyProtected()`

**Проверка:**
1. Включите "Обход защиты контента"
2. Откройте защищенный канал
3. Попробуйте переслать или сохранить медиа

**Если не работает:**
- Проверьте hooks в `PeerUtils.swift` и `MessageUtils.swift`
- Убедитесь, что проверка `UserDefaults.standard.bool(forKey: "MQGram.contentProtectionBypass")` возвращает `true`

#### Disable Ads (Отключить рекламу)
**Как работает:**
- Возвращает пустой результат из `getSponsoredMessages`
- Возвращает пустой результат из `getSponsoredPeers`

**Проверка:**
1. Включите "Отключить рекламу"
2. Откройте каналы, где обычно показывается реклама
3. Реклама не должна отображаться

**Если не работает:**
- Проверьте hooks в `AdMessages.swift` и `AdPeers.swift`

### Логирование и отладка

#### Включение debug-логов
Добавьте в начало `MQGramSettings.swift`:

```swift
private static let debugLogging = true

public func setBool(_ value: Bool, for key: Key) {
    let keyString = "MQGram.\(key.rawValue)"
    self.defaults.set(value, forKey: keyString)
    self.defaults.synchronize()
    
    if Self.debugLogging {
        print("🔧 MQGram: Set \(keyString) = \(value)")
        print("🔧 MQGram: Verify \(keyString) = \(self.defaults.bool(forKey: keyString))")
    }
}
```

#### Проверка сохраненных настроек
Добавьте в `MQGramSettingsController.swift` кнопку для вывода всех настроек:

```swift
public func dumpAllSettings() {
    print("=== MQGram Settings Dump ===")
    for key in MQGramSettings.Key.allCases {
        let value = MQGramSettings.shared.bool(for: key)
        print("\(key.rawValue): \(value)")
    }
    print("============================")
}
```

### Известные ограничения

1. **Серверные ограничения:**
   - MQGram — это **клиентская модификация**
   - Некоторые функции могут не работать, если сервер Telegram изменит протокол
   - Ghost Mode не делает вас полностью невидимым для сервера

2. **Функции, требующие root/jailbreak:**
   - Нет таких функций! MQGram работает без jailbreak

3. **Функции, которые не могут быть реализованы:**
   - Чтение удаленных сообщений, отправленных **до** установки MQGram
   - Восстановление медиа из удаленных сообщений, если медиа уже удалено с сервера
   - Полная анонимность (сервер всегда знает ваш IP и device ID)

### Контрольный список диагностики

- [ ] Настройки сохраняются (переключатели остаются включенными после перезапуска настроек)
- [ ] Приложение полностью перезапущено после изменения настроек
- [ ] Проверены hooks в исходном коде (grep показывает наличие MQGram комментариев)
- [ ] Проверена версия приложения (MQGram должен быть в названии)
- [ ] Проверено, что используются настройки MQGram, а не Swiftgram
- [ ] Проверены логи (если включено debug-логирование)
- [ ] Проверена конкретная функция по инструкции выше

### Получение помощи

Если проблема не решена:

1. **Соберите информацию:**
   - Какая функция не работает?
   - Настройка сохраняется?
   - Приложение перезапущено?
   - Версия iOS?
   - Способ установки (App Store / Sideload / TestFlight)?

2. **Проверьте логи:**
   - Включите debug-логирование
   - Воспроизведите проблему
   - Сохраните логи

3. **Сообщите о проблеме:**
   - GitHub Issues: https://github.com/jutsodev (если репозиторий публичный)
   - Telegram: @jutsodev
   - Канал: @Stivenvpn

### Changelog исправлений

#### v1.0.1 (текущая версия)
- ✅ Добавлен `synchronize()` в `setBool` для немедленного сохранения настроек
- ✅ Создано руководство по устранению неполадок

#### v1.0.0 (начальная версия)
- Все основные функции реализованы
- Известная проблема: настройки могут не сохраняться немедленно
