#!/bin/bash

# 🚀 MQGram Build Script - Запуск сборки
# Run this on your Mac with Xcode installed

echo "🚀 MQGRAM BUILD SCRIPT"
echo "======================"
echo ""
echo "This script will build MQGram on your Mac"
echo ""

# Check if running on macOS
if [[ ! "$OSTYPE" == "darwin"* ]]; then
    echo "❌ This script must be run on macOS!"
    echo "Run this on your Mac:"
    echo "  cd /path/to/mqgram"
    echo "  bash BUILD_SCRIPT.sh"
    exit 1
fi

# Check Xcode
if ! command -v xcode-select &> /dev/null; then
    echo "❌ Xcode Command Line Tools not found"
    echo "Install with: xcode-select --install"
    exit 1
fi

XCODE_PATH=$(xcode-select -p)
echo "✅ Xcode found at: $XCODE_PATH"
echo ""

# Detect processor
ARCH=$(uname -m)
if [[ "$ARCH" == "arm64" ]]; then
    echo "✅ Apple Silicon Mac detected (M1/M2/M3)"
else
    echo "⚠️  Intel Mac detected"
fi
echo ""

# Option to choose build method
echo "Select build method:"
echo "1) Xcode (Recommended - Fast with cache)"
echo "2) Command Line (bazel)"
echo "3) Fast Build (./fast_build.sh)"
echo ""
read -p "Enter choice (1-3): " choice

case $choice in
    1)
        echo ""
        echo "🔨 Building with Xcode..."
        echo ""
        cd "$(dirname "$0")"
        
        # Open Xcode workspace
        if [ -d "Telegram/Telegram.xcworkspace" ]; then
            echo "Opening Telegram.xcworkspace..."
            open Telegram/Telegram.xcworkspace
            echo ""
            echo "✅ Xcode opened!"
            echo ""
            echo "Next steps in Xcode:"
            echo "1. Select Scheme: 'Telegram'"
            echo "2. Select Device: 'Any iOS Device (arm64)' or your device"
            echo "3. Press Cmd+B to build"
            echo ""
            echo "Build time:"
            echo "  First time: 3-5 minutes"
            echo "  With cache: 30 seconds - 2 minutes"
        else
            echo "❌ Telegram.xcworkspace not found!"
            exit 1
        fi
        ;;
    2)
        echo ""
        echo "🔨 Building with Bazel..."
        echo ""
        cd "$(dirname "$0")"
        
        # Clean and build
        echo "Cleaning previous build..."
        bazel clean --expunge 2>/dev/null || true
        
        echo "Starting build..."
        echo "This will take 3-5 minutes..."
        echo ""
        
        bazel build \
            --jobs=$(sysctl -n hw.ncpu) \
            --local_ram_resources=8000 \
            --local_cpu_resources=$(sysctl -n hw.ncpu) \
            --apple_enable_clang_static_analyzer=false \
            --announce_rc \
            //Telegram/Telegram-iOS:Telegram
        
        if [ $? -eq 0 ]; then
            echo ""
            echo "✅ BUILD SUCCESSFUL!"
            echo ""
            echo "Next: Archive and sign the app for deployment"
        else
            echo ""
            echo "❌ BUILD FAILED!"
            echo "Check the error messages above"
            exit 1
        fi
        ;;
    3)
        echo ""
        echo "🚀 Running fast_build.sh..."
        echo ""
        cd "$(dirname "$0")"
        bash ./fast_build.sh
        ;;
    *)
        echo "❌ Invalid choice!"
        exit 1
        ;;
esac

echo ""
echo "═════════════════════════════════════════"
echo "✅ Build script completed!"
echo "═════════════════════════════════════════"
