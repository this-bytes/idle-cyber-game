-- Fortress Architecture Demo
-- Demonstrates the new fortress architecture capabilities
-- Run with: lua5.3 src/fortress_demo.lua

-- Set up test environment
local testEnv = require("tests.test_environment")
testEnv.setup()

-- Import fortress game
local FortressGame = require("src.core.fortress_game")

local function runFortressDemo()
    print("🏰 FORTRESS ARCHITECTURE DEMO")
    print("=====================================")
    print("")
    
    -- Initialize fortress game
    print("🚀 Creating Fortress Game...")
    local fortress = FortressGame.new()
    local success = fortress:initialize()
    
    if not success then
        print("❌ Failed to initialize fortress")
        return
    end
    
    print("✅ Fortress Game initialized successfully!")
    print("")
    
    -- Demonstrate resource management
    print("💰 RESOURCE MANAGEMENT DEMO")
    print("----------------------------")
    local resourceManager = fortress.systems.resourceManager
    
    print("Initial resources:")
    local resources = resourceManager:getAllResources()
    for name, amount in pairs(resources) do
        print("  " .. name .. ": " .. string.format("%.0f", amount))
    end
    
    print("\nAdding resources...")
    resourceManager:addResource("money", 500)
    resourceManager:addResource("reputation", 10)
    resourceManager:addResource("xp", 25)
    
    print("Resources after addition:")
    resources = resourceManager:getAllResources()
    for name, amount in pairs(resources) do
        print("  " .. name .. ": " .. string.format("%.0f", amount))
    end
    print("")
    
    -- Demonstrate security upgrades
    print("🛡️ SECURITY UPGRADES DEMO")
    print("-------------------------")
    local securityUpgrades = fortress.systems.securityUpgrades
    
    local available = securityUpgrades:getAvailableUpgrades()
    print("Available upgrades: " .. fortress:countKeys(available))
    
    -- Purchase some upgrades
    local purchased = securityUpgrades:purchaseUpgrade("basicFirewall")
    if purchased then
        print("✅ Purchased Basic Firewall")
    end
    
    purchased = securityUpgrades:purchaseUpgrade("securityTraining")
    if purchased then
        print("✅ Purchased Security Training")
    end
    
    local threatReduction = securityUpgrades:getTotalThreatReduction()
    print("Total threat reduction: " .. string.format("%.1f%%", threatReduction * 100))
    print("")
    
    -- Demonstrate threat simulation
    print("🚨 THREAT SIMULATION DEMO")
    print("-------------------------")
    local threatSim = fortress.systems.threatSimulation
    
    -- Generate some threats
    print("Generating threats...")
    for i = 1, 3 do
        local threat = threatSim:generateThreat()
        if threat then
            print("  🚨 " .. threat.name .. " (" .. threat.severity .. ") - Damage: " .. threat.actualDamage)
        end
    end
    
    local activeThreats = threatSim:getActiveThreats()
    print("Active threats: " .. fortress:countKeys(activeThreats))
    
    local stats = threatSim:getThreatStatistics()
    print("Threat statistics:")
    print("  Total: " .. stats.totalThreats)
    print("  Active: " .. stats.activeThreats)
    print("")
    
    -- Demonstrate UI management
    print("🖥️ UI MANAGEMENT DEMO")
    print("--------------------")
    local uiManager = fortress.systems.uiManager
    
    print("Showing notifications...")
    uiManager:showNotification("🏰 Fortress Demo Running", "info")
    uiManager:showNotification("💰 Resources Updated", "success")
    uiManager:showNotification("🚨 Threat Detected", "danger")
    
    print("Notifications in queue: " .. #uiManager.notifications)
    
    -- Update UI to process notifications
    for i = 1, 5 do
        uiManager:update(0.5) -- Simulate 0.5 second updates
    end
    
    print("Notifications after processing: " .. #uiManager.notifications)
    print("")
    
    -- Demonstrate game loop performance
    print("⚡ GAME LOOP PERFORMANCE DEMO")
    print("----------------------------")
    local gameLoop = fortress.gameLoop
    
    print("Running update cycles...")
    for i = 1, 60 do -- Simulate 1 second of updates at 60 FPS
        fortress:update(1/60)
    end
    
    local metrics = gameLoop:getPerformanceMetrics()
    print("Performance metrics:")
    print("  FPS: " .. (metrics.fps or 0))
    print("  Update Time: " .. string.format("%.3fms", (metrics.updateTime or 0) * 1000))
    print("  Systems: " .. fortress:countKeys(metrics.systemUpdateTimes))
    print("  Time Scale: " .. string.format("%.1fx", metrics.timeScale))
    print("")
    
    -- Demonstrate save/load
    print("💾 SAVE/LOAD DEMO")
    print("----------------")
    print("Saving game state...")
    local saveData = fortress:save()
    print("Save data contains " .. fortress:countKeys(saveData.systems) .. " system states")
    
    -- Create new fortress and load
    print("Creating new fortress instance and loading...")
    local fortress2 = FortressGame.new()
    fortress2:initialize()
    fortress2:load(saveData)
    
    print("✅ Save/load completed successfully")
    print("")
    
    -- Demonstrate system integration
    print("🔗 SYSTEM INTEGRATION DEMO")
    print("--------------------------")
    
    -- Test event-driven communication
    print("Testing event-driven communication...")
    local eventsFired = 0
    fortress.eventBus:subscribe("demo_event", function(data)
        eventsFired = eventsFired + 1
        print("  📡 Event received: " .. (data.message or "Unknown"))
    end)
    
    fortress.eventBus:publish("demo_event", {message = "Fortress communication test"})
    fortress.eventBus:publish("demo_event", {message = "Multi-system integration"})
    
    print("Events fired and received: " .. eventsFired)
    print("")
    
    -- Performance comparison
    print("📊 ARCHITECTURE COMPARISON")
    print("-------------------------")
    print("Systems managed by GameLoop: " .. #fortress.gameLoop.systemOrder)
    print("Event subscribers active: " .. fortress:countKeys(fortress.eventBus.listeners))
    print("Memory efficiency: Centralized resource management")
    print("Update efficiency: Priority-based system updates")
    print("Maintainability: SOLID principles with dependency injection")
    print("")
    
    -- Cleanup
    print("🧹 CLEANUP")
    print("---------")
    fortress:shutdown()
    fortress2:shutdown()
    print("✅ Fortress demo completed successfully!")
    print("")
    
    print("🏆 FORTRESS ARCHITECTURE BENEFITS DEMONSTRATED:")
    print("  ✓ Centralized GameLoop with priority-based updates")
    print("  ✓ Unified ResourceManager with event-driven updates")
    print("  ✓ Specialized SecurityUpgrades with cybersecurity theme")
    print("  ✓ Realistic ThreatSimulation with defense calculations")
    print("  ✓ Modern UIManager with reactive state management")
    print("  ✓ Clean system integration with legacy compatibility")
    print("  ✓ Comprehensive performance monitoring")
    print("  ✓ Robust save/load with full state persistence")
    print("")
    print("🏰 The fortress stands strong! Architecture refactor complete.")
end

-- Run the demo
runFortressDemo()
