# Как перенести MQGram в новую версию Telegram-iOS / Swiftgram

## TL;DR

```bash
# 1) Склонируй свежий Swiftgram/Telegram-iOS
git clone --recurse-submodules https://github.com/Swiftgram/Telegram-iOS.git
cd Telegram-iOS

# 2) Скопируй папку MQGram/ из старого форка
cp -R /path/to/old/Telegram-iOS/MQGram .

# 3) Применить точечные патчи в подмодулях
python3 MQGram/Patches/apply_patches.py

# 4) Собрать
python3 build-system/Make/Make.py build ...
```

## Что MQGram трогает в репозитории

### Папки, добавленные MQGram
- `MQGram/` — целиком (модуль + ассеты + патчи + документация)
- `.github/workflows/build.yml` — обновлённый CI

### Файлы, в которые MQGram вставляет хуки

Все хуки помечены комментарием с подстрокой `MQGram` — можно найти грепом:
```bash
grep -rn "MQGram" submodules/
```

| Файл | Что меняется |
|---|---|
| `submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoScreen.swift` | `case mqgram` в `PeerInfoSettingsSection` |
| `submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoSettingsItems.swift` | `case mqgram` в `SettingsSection`; видимая кнопка MQGram в секции swiftgram; скрытые swiftgram/Pro пункты |
| `submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoScreenSettingsActions.swift` | `case .mqgram` → `mqgramSettingsController` |
| `submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/ListItems/PeerInfoScreenDisclosureItem.swift` | `longPressAction` параметр |
| `submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/ListItems/PeerInfoScreenSelectableBackgroundNode.swift` | `longPressed` callback + UILongPressGestureRecognizer |
| `submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/BUILD` | dep на `//MQGram/MQGramSettingsUI:MQGramSettingsUI` |
| `submodules/TelegramCore/Sources/TelegramEngine/Messages/AdMessages.swift` | Disable Ads — не запрашивать sponsored messages |
| `submodules/TelegramCore/Sources/TelegramEngine/Peers/AdPeers.swift` | Disable Ads — не запрашивать sponsored peers |
| `submodules/TelegramCore/Sources/State/SynchronizePeerReadState.swift` | Ghost Mode — не пушить readState |
| `submodules/TelegramCore/Sources/State/AccountViewTracker.swift` | Ghost Mode — не вызывать readMessageContents |
| `submodules/TelegramCore/Sources/State/ManagedSynchronizeViewStoriesOperations.swift` | Ghost Mode — не пушить readStories |
| `submodules/TelegramCore/Sources/State/ManagedSynchronizeConsumeMessageContentsOperations.swift` | Ghost Mode — пропускать synchronizeConsumeMessageContents |
| `submodules/TelegramCore/Sources/State/AccountStateManagementUtils.swift` | Anti-Revoke (×3) и Anti-Edit (×3) |
| `submodules/TelegramCore/Sources/Utils/PeerUtils.swift` | Content Protection Bypass — `isCopyProtectionEnabled` → false |
| `submodules/TelegramCore/Sources/Utils/MessageUtils.swift` | Content Protection Bypass — `isCopyProtected()` → false |
| `submodules/TelegramCore/Sources/ApiUtils/StoreMessage_Telegram.swift` | Anti-Self-Destruct + Custom Indicators |
| `submodules/TelegramCore/Sources/State/ManagedAutoremoveMessageOperations.swift` | Anti-Self-Destruct — блок срабатывания таймера |

### Прочие правки
- `Telegram/BUILD` — `<string>Swiftgram</string>` → `<string>MQGram</string>` (CFBundleDisplayName)
- `Telegram/Telegram-iOS/en.lproj/Localizable.strings` — `Tour.Title1` и `Application.Name` → `MQGram`
- `submodules/TelegramCallsUI/Sources/CallKitIntegration.swift` — CallKit name → `MQGram`
- `Telegram/Telegram-iOS/DefaultAppIcon.xcassets/AppIconLLC.appiconset/Swiftgram.png` — заменён на твой логотип

## Скрипт автопатча

`MQGram/Patches/apply_patches.py` (см. файл) — применяет все правки идемпотентно
к свежему Swiftgram-clone. Запуск:
```bash
python3 MQGram/Patches/apply_patches.py
```

## Сценарий обновления при выходе новой версии Swiftgram

1. Склонируй новый Swiftgram свежим репо.
2. Скопируй свою папку `MQGram/` в корень.
3. Запусти `python3 MQGram/Patches/apply_patches.py`.
4. Скрипт сообщит, какие из патчей конфликтуют (если апстрим что-то поменял) — те правки нужно дофиксить вручную.
5. Собери проект.

## Storage of feature flags

Все настройки фич — в `UserDefaults.standard` с префиксом `MQGram.`:
- `MQGram.antiSelfDestruct`
- `MQGram.antiRevoke`
- `MQGram.ghostMode`
- `MQGram.customIndicators`
- `MQGram.contentProtectionBypass`
- `MQGram.antiEdit`
- `MQGram.disableAds`

Все по умолчанию `false`. UI меняет их через `MQGramSettings.shared.setBool(...)`.
