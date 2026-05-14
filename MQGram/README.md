# MQGram

MQGram — кастомизация Swiftgram (форка Telegram-iOS) с дополнительными приватными
функциями, портированными из tweaks/Lead.

## Структура папки

```
MQGram/
├── README.md              # этот файл
├── INTEGRATION.md         # как перенести MQGram в новую версию TG
├── Assets/                # бренд-ресурсы (логотип и т.п.)
├── MQGramSettingsUI/      # Bazel-модуль с UI вкладки настроек
└── Patches/               # точечные изменения в TelegramCore/UI
                           # (документация для портирования)
```

## Что сделано

### Вкладка настроек MQGram
- Появляется по **долгому нажатию на строку «Telegram Stars»** в настройках профиля
- Свои disclosure-пункты Swiftgram и Swiftgram Pro **скрыты**
- 7 переключателей фич, разделённых на STABLE и BETA секции

### Реализованные фичи (тумблеры)

| Фича | Что делает |
|---|---|
| **Anti-Self-Destruct** | Не запускает таймеры на disappearing photos/videos; (опц.) сохраняет timer-индикатор как «Custom Indicator» |
| **Anti-Revoke** | Игнорирует входящие `updateDeleteMessages` и `updateDeleteChannelMessages` |
| **Ghost Mode** | Не отправляет read-receipts (history, stories, voice/round playback) |
| **Custom Indicators** | В паре с Anti-Self-Destruct оставляет AutoclearTimeoutMessageAttribute, чтобы UI рисовал timer-иконку, но фактическое удаление не происходит |
| **Content Protection Bypass** | Возвращает `false` из `Peer.isCopyProtectionEnabled` и `Message.isCopyProtected()` |
| **Anti-Edit** | Игнорирует входящие `updateEditMessage` и `updateEditChannelMessage` |
| **Disable Ads** | Возвращает пусто из `getSponsoredMessages` и `getSponsoredPeers` |

Все фичи читают `UserDefaults.standard` под ключами `MQGram.<feature>`.

## Как собрать

### macOS (локально)
```bash
git clone --recurse-submodules https://github.com/<your-fork>/Telegram-iOS.git
cd Telegram-iOS
# Установи Bazel и Xcode в версии из versions.json
python3 build-system/Make/Make.py build \
    --configurationPath=build-system/appstore-configuration.json \
    --codesigningInformationPath=build-system/fake-codesigning \
    --configuration=release_arm64
```

### GitHub Actions
Workflow `.github/workflows/build.yml` запускается:
- автоматически на push в `master`/`main`
- вручную через "Run workflow" (создаёт также Release с IPA)

⚠️ **Внимание:** Telegram-iOS — очень крупный проект. Бесплатные macOS-раннеры
GitHub Actions имеют лимит 6 часов и ~14 ГБ диска; полный билд может не уместиться.
В этом случае нужно использовать self-hosted раннер на Mac, либо платный плановый
плагин с большими ресурсами.

## Бренд-ассеты

Положи свой PNG-логотип:
- `MQGram/Assets/logo.png` — основной бренд-логотип (1024×1024)
- `MQGram/Assets/appicon.png` — иконка приложения (1024×1024)

И запусти:
```bash
python3 MQGram/Patches/apply_assets.py
```

Скрипт скопирует файлы в нужные места:
- `Telegram/Telegram-iOS/DefaultAppIcon.xcassets/AppIconLLC.appiconset/Swiftgram.png` (иконка приложения)
- `Swiftgram/SGSettingsUI/Images.xcassets/SwiftgramSettings.imageset/Swiftgram.pdf` (иконка вкладки в настройках) — нужен PDF, конвертируется автоматически

## Лицензия

Telegram-iOS — GPLv2 (см. LICENSE в корне проекта).
MQGram-патчи — GPLv2.
