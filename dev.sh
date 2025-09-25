#!/bin/bash
# Development script for Cyber Empire Command

echo "🔐 Cyber Empire Command - Development Tools"
echo "==========================================="

case "$1" in
    "test")
        echo "🧪 Running test suite..."
        lua5.3 tests/test_runner.lua
        ;;
    "syntax")
        echo "🔍 Checking Lua syntax..."
        find . -name "*.lua" -not -path "./tests/*" -exec echo "Checking {}" \; -exec lua5.3 -e "dofile('{}')" \;
        echo "✅ Syntax check complete"
        ;;
    "run")
        echo "🚀 Note: Use 'love .' to run the game with LÖVE 2D"
        echo "   For testing without LÖVE, run individual Lua files"
        ;;
    "clean")
        echo "🧹 Cleaning temporary files..."
        find . -name "*.log" -delete
        find . -name "*~" -delete
        echo "✅ Cleanup complete"
        ;;
    *)
        echo "Available commands:"
        echo "  ./dev.sh test    - Run test suite"
        echo "  ./dev.sh syntax  - Check Lua syntax"
        echo "  ./dev.sh run     - Instructions to run game"
        echo "  ./dev.sh clean   - Clean temporary files"
        echo ""
        echo "Current status:"
        echo "  📁 Source files: $(find src -name "*.lua" | wc -l)"
        echo "  🧪 Test files: $(find tests -name "*.lua" | wc -l)"
        echo "  📋 TODO items: $(grep -c "^- \[ \]" TODO.md 2>/dev/null || echo "0")"
        ;;
esac