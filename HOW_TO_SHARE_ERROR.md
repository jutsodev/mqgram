# 📋 Как поделиться ошибкой сборки

## Вариант 1: Через GitHub Actions UI (самый просто)

1. Открой: https://github.com/jutsodev/mqgram/actions
2. Нажми на последний (красный) workflow run
3. Нажми на job "build"
4. Скопируй текст ошибки (красные строки)
5. Скинь мне в chat

## Вариант 2: Screenshot

1. Открой Actions
2. Скопируй скриншот экрана с ошибкой
3. Скинь мне

## Вариант 3: Build Log

1. В Actions нажми на job "build"
2. Скролл вниз к "Artifacts"
3. Скачай "build-log"
4. Открой файл и скопируй ошибки

## Что ищу в ошибке:

```
error: [что-то тут]
     | error message
```

Нужна ВСЯ красная ошибка, включая:
- Имя файла
- Номер строки
- Текст ошибки
- Контекст (строки вокруг ошибки)

## Пример того как скинуть:

```
Error in: submodules/TelegramUI/Sources/ChatController.swift
Line 1234: error: cannot find type 'SomeType'
```

---

Любой из вариантов поможет мне понять что не так и быстро исправить!
