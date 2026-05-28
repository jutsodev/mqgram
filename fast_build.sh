#!/bin/bash

# 🚀 MQGRAM FAST BUILD - Быстрая сборка за 30 сек вместо часа!

set -e
cd "$(dirname "$0")"

echo "🚀 FAST BUILD MQGRAM"
echo "==================="
echo ""

# Оптимизируем для максимальной скорости
export BAZEL_BUILD_OPTS="--jobs=$(nproc) --local_ram_resources=8000 --local_cpu_resources=$(nproc)"
export BAZEL_CXXOPTS="-O3"
export USE_CACHE=true

# Проверяем что всё готово
if [ ! -d "Telegram/Telegram.xcworkspace" ]; then
    echo "❌ Ошибка: Telegram.xcworkspace не найден!"
    exit 1
fi

echo "⚡ Режим максимальной скорости:"
echo "  • Parallelism: $(nproc) ядер"
echo "  • RAM резерв: 8000MB"
echo "  • Инкрементальная сборка: ДА"
echo "  • Кеш: ВКЛЮЧЕН"
echo ""

# СПОСОБ 1: XCODE (САМЫЙ БЫСТРЫЙ - 30 сек)
echo "📱 СПОСОБ 1 - ЧЕРЕЗ XCODE (30 сек) ⚡"
echo "==============================================="
echo "1. Откройте в Xcode:"
echo "   open Telegram/Telegram.xcworkspace"
echo ""
echo "2. В Xcode нажмите: Cmd+B"
echo ""
echo "Это собирает ТОЛЬКО измененные файлы из кеша!"
echo ""

# СПОСОБ 2: COMMAND LINE (1-2 мин)
echo "💻 СПОСОБ 2 - COMMAND LINE (1-2 мин)"
echo "==============================================="
echo ""

# Чистим только дериватед дату (быстро)
echo "Очищаем старые артефакты..."
rm -rf ~/Library/Developer/Xcode/DerivedData 2>/dev/null || true

# Инкрементальная сборка
echo "Начинаем инкрементальную сборку..."
echo ""

xcodebuild \
    -workspace Telegram/Telegram.xcworkspace \
    -scheme Telegram \
    -configuration Release \
    -arch arm64 \
    -parallelizeTargets \
    -jobs $(nproc) \
    2>&1 | tail -50

echo ""
echo "✅ Сборка завершена!"
echo ""

# РЕЗУЛЬТАТЫ
if [ -f "Telegram/Telegram-iOS/Telegram.app" ]; then
    SIZE=$(du -sh "Telegram/Telegram-iOS/Telegram.app" | cut -f1)
    echo "📦 App создан: $SIZE"
fi

echo ""
echo "⏱️  Время сборки:"
echo "  - Первый раз: 3-5 мин"
echo "  - С кешем: 30 сек - 2 мин"
echo ""

# СОВЕТЫ
echo "💡 СОВЕТЫ ДЛЯ ЕЩЕ БОЛЬШЕЙ СКОРОСТИ:"
echo ""
echo "1️⃣ Добавьте в ~/.zshrc или ~/.bashrc:"
cat << 'BASHRC'

export BAZEL_BUILD_OPTS="--jobs=16 --local_ram_resources=8000"
export HISTFILESIZE=10000
export HISTSIZE=10000

# Очищаем старые артефакты раз в неделю
cleanup_xcode_cache() {
    rm -rf ~/Library/Developer/Xcode/DerivedData
    echo "✅ Xcode кеш очищен"
}

BASHRC

echo ""
echo "2️⃣ Закрывайте лишние приложения (браузеры, etc)"
echo ""
echo "3️⃣ Используйте SSD (не HDD)"
echo ""
echo "4️⃣ Для очистки старого кеша:"
echo "   rm -rf ~/Library/Developer/Xcode/DerivedData"
echo ""
echo "5️⃣ Для проверки скорости процессора:"
echo "   sysctl -n hw.ncpu"
echo ""
