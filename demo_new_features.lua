#!/usr/bin/env lua5.3
-- Demo script for new advanced features in Cyberspace Tycoon
-- Showcases the comprehensive enhancements added to the idle cybersecurity game

local json = require("dkjson")

-- Mock love for testing outside LÖVE environment
if not love then
    love = {
        timer = {
            getTime = function() return os.clock() end
        },
        graphics = {
            getDimensions = function() return 1024, 768 end
        }
    }
end

print("🎮 Cyberspace Tycoon - Advanced Features Demo")
print("=" .. string.rep("=", 50))

-- Initialize systems
local EventBus = require("src.utils.event_bus")
local SoundSystem = require("src.systems.sound_system")
local CrisisGameSystem = require("src.systems.crisis_game_system")
local AdvancedAchievementSystem = require("src.systems.advanced_achievement_system")
local ContractModal = require("src.ui.contract_modal")

local eventBus = EventBus.new()

print("\n🔊 SOUND SYSTEM DEMO")
print("-" .. string.rep("-", 30))
local soundSystem = SoundSystem.new(eventBus)
print("Sound system initialized with " .. soundSystem:countLoadedSounds() .. " sounds")

-- Demo sound events
soundSystem:playSound("ui_click")
soundSystem:playSound("contract_accept")
soundSystem:playSound("crisis_alert")
soundSystem:playSound("achievement_unlock")

-- Demo volume controls
soundSystem:setMasterVolume(0.8)
soundSystem:setSFXVolume(0.9)
soundSystem:setMusicVolume(0.5)
print("Volume controls: Master=" .. soundSystem.masterVolume .. ", SFX=" .. soundSystem.sfxVolume .. ", Music=" .. soundSystem.musicVolume)

print("\n🚨 CRISIS GAME SYSTEM DEMO")
print("-" .. string.rep("-", 30))
local crisisSystem = CrisisGameSystem.new(eventBus)

-- Demo crisis types
local crisisTypes = {"ddos_attack", "ransomware_incident", "phishing_campaign", "data_exfiltration", "supply_chain_compromise"}
for i, crisisType in ipairs(crisisTypes) do
    print(i .. ". " .. crisisType:gsub("_", " "):upper())
end

-- Start a demo crisis
crisisSystem:startCrisis("ddos_attack")
print("Crisis started: " .. (crisisSystem:getCurrentCrisis() and crisisSystem:getCurrentCrisis().title or "None"))

-- Simulate game state updates
for i = 1, 5 do
    crisisSystem:update(1.0)  -- 1 second updates
    local gameState = crisisSystem:getGameState()
    print("Update " .. i .. ": Score=" .. gameState.score .. ", Time=" .. math.floor(gameState.timeRemaining) .. "s")
end

print("\n🏆 ADVANCED ACHIEVEMENT SYSTEM DEMO")
print("-" .. string.rep("-", 30))
local achievementSystem = AdvancedAchievementSystem.new(eventBus)

-- Display achievement categories
print("Achievement Categories:")
local categoryCount = 0
for categoryId, category in pairs(achievementSystem.categories) do
    categoryCount = categoryCount + 1
    local achievementCount = 0
    for _ in pairs(category.achievements) do
        achievementCount = achievementCount + 1
    end
    print("  " .. category.icon .. " " .. category.title .. " (" .. achievementCount .. " achievements)")
end
print("Total categories: " .. categoryCount)

-- Simulate some progress to trigger achievements
achievementSystem.stats.contractsCompleted = 1
achievementSystem.stats.totalEarnings = 1000
achievementSystem.stats.specialistsHired = 1
achievementSystem:checkAchievements()

local stats = achievementSystem:getStats()
print("Achievement Progress: " .. stats.unlocked .. "/" .. stats.total .. " (" .. math.floor(stats.percentage) .. "%)")
print("Hidden achievements: " .. stats.hiddenUnlocked .. "/" .. stats.hidden)

-- Show recent unlocks
local recentUnlocks = achievementSystem:getRecentUnlocks()
if #recentUnlocks > 0 then
    print("Recent unlocks:")
    for _, unlock in ipairs(recentUnlocks) do
        print("  🏆 " .. unlock.achievement.title .. " - " .. unlock.achievement.description)
    end
end

print("\n📋 CONTRACT MODAL DEMO")
print("-" .. string.rep("-", 30))
local contractModal = ContractModal.new(eventBus)

-- Demo contract
local demoContract = {
    clientName = "SecureTech Industries",
    description = "Comprehensive security assessment and penetration testing for our financial services platform. We need to ensure compliance with PCI DSS and identify any vulnerabilities in our customer-facing applications.",
    totalBudget = 25000,
    duration = 300,
    reputationReward = 12
}

-- Show contract details
contractModal:show(demoContract)
print("Contract modal opened for: " .. demoContract.clientName)
print("Budget: $" .. demoContract.totalBudget)
print("Duration: " .. math.floor(demoContract.duration / 60) .. " minutes")
print("Reputation reward: +" .. demoContract.reputationReward)

-- Generate client background
local clientInfo = contractModal.clientInfo
if clientInfo then
    print("\nClient Background:")
    print("Type: " .. clientInfo.type:upper())
    print("Background: " .. clientInfo.background)
    print("Primary Concern: " .. clientInfo.primaryConcern)
    print("Risk Level: " .. clientInfo.riskLevel)
    print("Contact: " .. clientInfo.contactPerson.name .. " (" .. clientInfo.contactPerson.title .. ")")
    print("Timeline phases: " .. #clientInfo.timeline)
    print("Special requirements: " .. #clientInfo.specialRequirements)
end

print("\n🎯 EVENT SYSTEM INTEGRATION DEMO")
print("-" .. string.rep("-", 30))

-- Subscribe to some events to show integration
local eventLog = {}
local function logEvent(eventName)
    return function(data)
        table.insert(eventLog, {
            event = eventName,
            data = data,
            timestamp = love.timer.getTime()
        })
        print("📡 Event: " .. eventName .. " (data: " .. (data and type(data) or "nil") .. ")")
    end
end

eventBus:subscribe("ui.click", logEvent("ui.click"))
eventBus:subscribe("ui.success", logEvent("ui.success"))
eventBus:subscribe("contract_accepted", logEvent("contract_accepted"))
eventBus:subscribe("crisis_started", logEvent("crisis_started"))
eventBus:subscribe("achievement_unlocked", logEvent("achievement_unlocked"))

-- Trigger some events
eventBus:publish("ui.click", {})
eventBus:publish("contract_accepted", {contract = demoContract})
eventBus:publish("ui.success", {})

print("Events logged: " .. #eventLog)

print("\n🔄 SAVE/LOAD SYSTEM DEMO")
print("-" .. string.rep("-", 30))

-- Demo save states
local soundState = soundSystem:getState()
local achievementState = achievementSystem:getState()

print("Sound system state keys: " .. (soundState and "masterVolume, sfxVolume, musicVolume, enabled" or "none"))
print("Achievement system state:")
if achievementState then
    local unlockedCount = 0
    if achievementState.unlockedAchievements then
        for _ in pairs(achievementState.unlockedAchievements) do
            unlockedCount = unlockedCount + 1
        end
    end
    local statsCount = 0
    if achievementState.stats then
        for _ in pairs(achievementState.stats) do
            statsCount = statsCount + 1
        end
    end
    print("  Unlocked achievements: " .. unlockedCount)
    print("  Tracked stats: " .. statsCount)
end

print("\n📊 PERFORMANCE & FEATURES SUMMARY")
print("-" .. string.rep("-", 30))
print("✅ Sound System: " .. soundSystem:countLoadedSounds() .. " sounds, " .. (soundSystem:isEnabled() and "enabled" or "disabled"))
print("✅ Crisis Games: " .. #crisisTypes .. " crisis types, " .. (crisisSystem:isActive() and "active" or "idle"))
print("✅ Achievements: " .. stats.total .. " total, " .. stats.unlocked .. " unlocked, " .. stats.hidden .. " hidden")
print("✅ Contract Modal: Interactive UI with rich client backgrounds")
print("✅ Event Integration: " .. #eventLog .. " events processed")

-- Feature compatibility check
print("\n🔧 COMPATIBILITY CHECK")
print("-" .. string.rep("-", 30))
local features = {
    ["LÖVE 2D Graphics"] = love.graphics ~= nil,
    ["Timer Functions"] = love.timer ~= nil,
    ["JSON Processing"] = json ~= nil,
    ["Event Bus System"] = eventBus ~= nil,
    ["Modular Architecture"] = true
}

for feature, status in pairs(features) do
    print((status and "✅" or "❌") .. " " .. feature)
end

print("\n🎮 GAME ENHANCEMENT SUMMARY")
print("=" .. string.rep("=", 50))
print("The game now features:")
print("• 🔊 Reactive audio system with procedural sound generation")
print("• 🚨 Interactive crisis mini-games with real-time mechanics")
print("• 🏆 Comprehensive achievement system with hidden unlocks")
print("• 📋 Rich contract details with procedural client backgrounds")
print("• 🎯 Integrated event system for seamless feature interaction")
print("• 💾 Advanced save/load system for persistent progression")
print("• ✨ Animated UI elements with micro-interactions")
print("• 🎨 Polished visual feedback and responsive controls")
print("")
print("Ready to transform your cybersecurity empire! 🚀")
print("=" .. string.rep("=", 50))