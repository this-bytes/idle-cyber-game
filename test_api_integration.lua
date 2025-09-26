#!/usr/bin/env lua
-- Test script for API integration
-- Run with: lua test_api_integration.lua

-- Add current directory to package path
package.path = package.path .. ";./?/init.lua;./?.lua"

-- Try to load our API module
local api = require("api")

print("🧪 Testing API Integration...")
print("=============================")

-- Test 1: Test connection (synchronous)
print("\n1. Testing connection (sync)...")
local success, result = api.testConnection(nil, false)
if success then
    print("✅ Connection test: SUCCESS")
    print("   Response: " .. tostring(result))
else
    print("❌ Connection test: FAILED")
    print("   Error: " .. tostring(result))
    print("⚠️  Make sure the Flask server is running on localhost:5000")
    os.exit(1)
end

-- Test 2: Create a test player (synchronous)
print("\n2. Testing player creation (sync)...")
local testUsername = "test_player_" .. os.time()
local success, result = api.createPlayer(testUsername, nil, false)
if success then
    print("✅ Player creation: SUCCESS")
    print("   Player data: " .. (result and type(result) == "table" and "OK" or tostring(result)))
else
    print("❌ Player creation: FAILED")
    print("   Error: " .. tostring(result))
end

-- Test 3: Load the player we just created (synchronous)
print("\n3. Testing player load (sync)...")
local success, result = api.loadPlayer(testUsername, nil, false)
if success then
    print("✅ Player load: SUCCESS")
    if result and result.player then
        print("   Username: " .. tostring(result.player.username))
        print("   Currency: " .. tostring(result.player.current_currency))
        print("   Reputation: " .. tostring(result.player.reputation))
    end
else
    print("❌ Player load: FAILED")
    print("   Error: " .. tostring(result))
end

-- Test 4: Save player data (synchronous)
print("\n4. Testing player save (sync)...")
local additionalData = {
    reputation = 50,
    xp = 100,
    mission_tokens = 5
}
local success, result = api.savePlayer(testUsername, 5000, 1, additionalData, nil, false)
if success then
    print("✅ Player save: SUCCESS")
else
    print("❌ Player save: FAILED")
    print("   Error: " .. tostring(result))
end

-- Test 5: Load updated player data (synchronous)
print("\n5. Testing updated player load (sync)...")
local success, result = api.loadPlayer(testUsername, nil, false)
if success then
    print("✅ Updated player load: SUCCESS")
    if result and result.player then
        print("   Username: " .. tostring(result.player.username))
        print("   Currency: " .. tostring(result.player.current_currency))
        print("   Reputation: " .. tostring(result.player.reputation))
        print("   XP: " .. tostring(result.player.xp))
        print("   Mission Tokens: " .. tostring(result.player.mission_tokens))
    end
else
    print("❌ Updated player load: FAILED")
    print("   Error: " .. tostring(result))
end

-- Test 6: Get global state (synchronous)
print("\n6. Testing global state retrieval (sync)...")
local success, result = api.getGlobalState(nil, false)
if success then
    print("✅ Global state: SUCCESS")
    if result and result.global_state then
        print("   Base Production Rate: " .. tostring(result.global_state.base_production_rate))
        print("   Global Multiplier: " .. tostring(result.global_state.global_multiplier))
    end
else
    print("❌ Global state: FAILED")
    print("   Error: " .. tostring(result))
end

print("\n=============================")
print("🎉 API Integration Tests Complete!")
print("ℹ️  Note: Async tests require LÖVE 2D environment")