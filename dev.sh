#!/bin/bash
# Development script for Idle Sec Ops

echo "🔐 Idle Sec Ops - Development Tools"
echo "==========================================="

case "$1" in
    "test")
        echo "🧪 Running unit tests..."
        lua tests/test_runner.lua
        ;;
    "behavior")
        echo "� Running behavior tests..."
        lua tests/test_behavior.lua
        ;;
    "test-all")
        echo "🚀 Running all tests..."
        echo ""
        echo "📦 Unit Tests:"
        lua tests/test_runner.lua
        echo ""
        echo "� Behavior Tests:"
        lua tests/test_behavior.lua
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
        echo "  ./dev.sh test        - Run unit tests"
        echo "  ./dev.sh behavior    - Run behavior/logic tests"
        echo "  ./dev.sh test-all    - Run all tests"
        echo "  ./dev.sh syntax      - Check Lua syntax"
        echo "  ./dev.sh run         - Instructions to run game"
        echo "  ./dev.sh clean       - Clean temporary files"
        echo ""
        echo "Current status:"
        echo "  📁 Source files: $(find src -name "*.lua" | wc -l)"
        echo "  🧪 Test files: $(find tests -name "*.lua" | wc -l)"
        echo "  📋 TODO items: $(grep -c "^- \[ \]" TODO.md 2>/dev/null || echo "0")"
        ;;
esac