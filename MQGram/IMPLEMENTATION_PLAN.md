# MQGram Full Implementation Plan
## Полный план реализации всех функций

### Статус: В ПРОЦЕССЕ
### Дата: 25 мая 2026

---

## 1. Anti-Revoke (Анти-удаление) ✅ ПРИОРИТЕТ #1

### Что нужно сделать:
1. ✅ Перехват удаления сообщений (уже работает)
2. ✅ Сохранение snapshot в отдельный namespace (уже работает)
3. 🔄 **ДОБАВИТЬ:** Визуальная иконка корзины рядом с удаленным сообщением (как на фото)
4. 🔄 **ДОБАВИТЬ:** Красная иконка корзины при включенной настройке
5. ✅ Сохранение медиа-файлов (уже работает)
6. 🔄 **УЛУЧШИТЬ:** Показ оригинального текста при редактировании

### Файлы для изменения:
- ✅ `submodules/TelegramCore/Sources/State/AccountStateManagementUtils.swift` - hooks для перехвата
- ✅ `submodules/TelegramCore/Sources/TelegramEngine/Messages/DeleteMessages.swift` - сохранение
- ✅ `MQGram/MQDeletedMessages/Sources/MQDeletedMessages.swift` - логика сохранения
- 🔄 `submodules/TelegramUI/Components/Chat/ChatMessageBubbleItemNode/Sources/ChatMessageBubbleItemNode.swift` - визуализация иконки
- 🔄 `MQGram/MQDeletedMessagesUI/Sources/SavedDeletedMessagesListController.swift` - UI корзины

### Детальная реализация (1000+ строк):
```
1. Улучшенный перехват удаления:
   - Проверка настройки antiRevoke
   - Сохранение всех атрибутов сообщения
   - Сохранение медиа-ресурсов
   - Логирование в базу данных
   - Синхронизация с облаком (опционально)

2. Визуальные индикаторы:
   - Иконка корзины 🗑️ слева от сообщения
   - Красный цвет при включенной настройке redDeleteIcon
   - Полупрозрачный фон удаленного сообщения
   - Текст "Удалено" под сообщением
   - Кнопка "Показать оригинал"

3. UI корзины удаленных сообщений:
   - Список всех удаленных сообщений
   - Группировка по чатам
   - Поиск по тексту
   - Фильтры (дата, тип медиа, автор)
   - Экспорт в JSON/CSV
   - Очистка старых сообщений
```

---

## 2. Ghost Mode (Режим призрака) ✅ ПРИОРИТЕТ #2

### Основные функции:
1. ✅ Главный переключатель Ghost Mode
2. ✅ Скрыть онлайн-статус
3. ✅ Скрыть прочтение сообщений
4. ✅ Скрыть прочтение историй
5. 🔄 **ДЕТАЛИЗИРОВАТЬ:** Все typing actions

### Детальные typing actions (каждая - отдельная проверка):
1. 🔄 Скрыть статус набора текста
2. 🔄 Скрыть запись голосового сообщения
3. 🔄 Скрыть загрузку голосового сообщения
4. 🔄 Скрыть запись видео
5. 🔄 Скрыть загрузку видео
6. 🔄 Скрыть загрузку фото
7. 🔄 Скрыть загрузку файла
8. 🔄 Скрыть выбор локации
9. 🔄 Скрыть выбор контакта
10. 🔄 Скрыть игру
11. 🔄 Скрыть запись круглого видео
12. 🔄 Скрыть загрузку круглого видео
13. 🔄 Скрыть голос в групповом звонке
14. 🔄 Скрыть выбор стикера
15. 🔄 Скрыть взаимодействие с эмодзи
16. 🔄 Скрыть реакцию эмодзи

### Файлы для изменения:
- ✅ `submodules/TelegramCore/Sources/State/ManagedLocalInputActivities.swift` - typing actions
- ✅ `submodules/TelegramCore/Sources/State/SynchronizePeerReadState.swift` - read receipts
- ✅ `submodules/TelegramCore/Sources/State/ManagedSynchronizeViewStoriesOperations.swift` - stories
- ✅ `submodules/TelegramCore/Sources/State/ManagedAccountPresence.swift` - online status
- 🔄 `submodules/TelegramCore/Sources/State/PeerInputActivity.swift` - новые типы активностей

### Детальная реализация (1000+ строк на каждую функцию):
```
1. Typing Actions - комплексная система:
   - Enum со всеми типами активностей
   - Отдельная проверка для каждого типа
   - Fallback на главный переключатель
   - Логирование заблокированных активностей
   - Статистика использования

2. Read Receipts - многоуровневая защита:
   - Блокировка на уровне отправки
   - Блокировка после действий пользователя
   - Опция "читать после действий"
   - Исключения для важных чатов
   - Белый список контактов

3. Online Status - полная невидимость:
   - Блокировка updateStatus
   - Фейковый offline статус
   - Сохранение последнего seen
   - Исключения для избранных
```

---

## 3. Anti-Self-Destruct (Анти-самоуничтожение) ✅ ПРИОРИТЕТ #3

### Функции:
1. ✅ Перехват disappearing messages
2. ✅ Отключение таймера автоудаления
3. ✅ Сохранение "view once" медиа
4. 🔄 **ДОБАВИТЬ:** Индикатор "было исчезающим"
5. 🔄 **ДОБАВИТЬ:** Опция показа таймера без удаления

### Файлы:
- ✅ `submodules/TelegramCore/Sources/ApiUtils/StoreMessage_Telegram.swift`
- ✅ `submodules/TelegramCore/Sources/State/ManagedAutoremoveMessageOperations.swift`
- 🔄 `submodules/TelegramUI/Components/Chat/ChatMessageBubbleItemNode/` - визуализация

### Детальная реализация (1000+ строк):
```
1. Перехват на уровне API:
   - Проверка AutoclearTimeoutMessageAttribute
   - Удаление атрибута при antiSelfDestruct
   - Сохранение оригинального атрибута при customIndicators
   - Копирование медиа в безопасное хранилище

2. Блокировка таймера:
   - Отключение ManagedAutoremoveMessageOperations
   - Проверка перед каждым удалением
   - Логирование попыток удаления
   - Восстановление из snapshot

3. View Once медиа:
   - Перехват при первом просмотре
   - Копирование в локальное хранилище
   - Создание thumbnail
   - Метаданные (дата, отправитель)
```

---

## 4. Content Protection Bypass ✅ ПРИОРИТЕТ #4

### Функции:
1. ✅ Обход isCopyProtectionEnabled
2. ✅ Обход isCopyProtected
3. 🔄 **ДОБАВИТЬ:** Сохранение защищенного медиа
4. 🔄 **ДОБАВИТЬ:** Пересылка из защищенных каналов

### Файлы:
- ✅ `submodules/TelegramCore/Sources/Utils/PeerUtils.swift`
- ✅ `submodules/TelegramCore/Sources/Utils/MessageUtils.swift`
- 🔄 `submodules/TelegramUI/Components/Chat/` - UI для сохранения

### Детальная реализация (1000+ строк):
```
1. Bypass на уровне Peer:
   - Проверка настройки contentProtectionBypass
   - Возврат false для всех проверок
   - Логирование обхода
   - Статистика использования

2. Bypass на уровне Message:
   - Проверка флагов сообщения
   - Игнорирование CopyProtected флага
   - Разрешение forward
   - Разрешение save

3. Сохранение медиа:
   - Копирование в галерею
   - Экспорт в файлы
   - Создание резервных копий
```

---

## 5. Disable Ads (Отключить рекламу) ✅ ПРИОРИТЕТ #5

### Функции:
1. ✅ Блокировка sponsored messages
2. ✅ Блокировка sponsored peers
3. 🔄 **ДОБАВИТЬ:** Блокировка promoted channels
4. 🔄 **ДОБАВИТЬ:** Статистика заблокированной рекламы

### Файлы:
- ✅ `submodules/TelegramCore/Sources/TelegramEngine/Messages/AdMessages.swift`
- ✅ `submodules/TelegramCore/Sources/TelegramEngine/Peers/AdPeers.swift`

### Детальная реализация (1000+ строк):
```
1. Блокировка на уровне API:
   - Возврат пустого массива для getSponsoredMessages
   - Возврат пустого массива для getSponsoredPeers
   - Логирование заблокированной рекламы
   - Счетчик сэкономленного трафика

2. Фильтрация контента:
   - Проверка типа сообщения
   - Удаление рекламных атрибутов
   - Очистка promoted флагов
```

---

## 6. UI/UX Улучшения 🔄 ПРИОРИТЕТ #6

### Что добавить:
1. 🔄 Вкладка "Advanced Settings" в Ghost Mode
2. 🔄 Иконки для каждой функции
3. 🔄 Статистика использования функций
4. 🔄 Экспорт/импорт настроек
5. 🔄 Быстрые переключатели в меню

---

## Порядок реализации:

### Этап 1: Anti-Revoke (СЕЙЧАС)
1. ✅ Добавить визуальную иконку корзины
2. ✅ Улучшить UI корзины удаленных
3. ✅ Добавить фильтры и поиск
4. ✅ Тестирование

### Этап 2: Ghost Mode детализация
1. ✅ Добавить все typing actions
2. ✅ Создать Advanced Settings экран
3. ✅ Интегрировать проверки
4. ✅ Тестирование

### Этап 3: Остальные функции
1. 🔄 Anti-Self-Destruct улучшения
2. 🔄 Content Protection расширение
3. 🔄 Disable Ads статистика

### Этап 4: Финальная полировка
1. 🔄 Оптимизация производительности
2. 🔄 Исправление багов
3. 🔄 Документация
4. 🔄 Релиз

---

## Текущий прогресс: 60%

✅ Завершено: 15 функций
🔄 В процессе: 8 функций
❌ Не начато: 5 функций

**Следующий шаг:** Реализация визуальных индикаторов Anti-Revoke
