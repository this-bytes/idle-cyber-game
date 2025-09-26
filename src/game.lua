-- Core Game Controller
-- Manages all game systems and state

local Game = {}

-- Import game systems
local ResourceSystem = require("src.systems.resource_system")
local UpgradeSystem = require("src.systems.upgrade_system")
local ThreatSystem = require("src.systems.threat_system")
local ZoneSystem = require("src.systems.zone_system")
local FactionSystem = require("src.systems.faction_system")
local AchievementSystem = require("src.systems.achievement_system")
local ContractSystem = require("src.systems.contract_system")  -- NEW: Core business system
local SpecialistSystem = require("src.systems.specialist_system")  -- NEW: Team management
local SaveSystem = require("src.systems.save_system")
local EventBus = require("src.utils.event_bus")

-- Import UI systems
local UIManager = require("src.ui.ui_manager")

-- Import game modes
local IdleMode = require("src.modes.idle_mode")
local AdminMode = require("src.modes.admin_mode")

-- Game state
local gameState = {
    initialized = false,
    paused = false,
    currentMode = "idle", -- "idle" or "admin"
    debugMode = false,
    
    -- Core systems
    systems = {},
    
    -- Performance tracking
    performance = {
        frameCount = 0,
        fps = 0,
        lastFPSUpdate = 0,
        updateTime = 0,
        drawTime = 0,
    }
}

-- Initialize the game
function Game.init()
    print("🚀 Initializing Cyberspace Tycoon...")
    
    -- Initialize core systems in order
    gameState.systems.eventBus = EventBus.new()
    gameState.systems.resources = ResourceSystem.new(gameState.systems.eventBus)
    gameState.systems.contracts = ContractSystem.new(gameState.systems.eventBus)  -- NEW: Contract system
    gameState.systems.specialists = SpecialistSystem.new(gameState.systems.eventBus)  -- NEW: Specialist system
    gameState.systems.upgrades = UpgradeSystem.new(gameState.systems.eventBus)
    gameState.systems.threats = ThreatSystem.new(gameState.systems.eventBus)
    gameState.systems.zones = ZoneSystem.new(gameState.systems.eventBus)
    gameState.systems.factions = FactionSystem.new(gameState.systems.eventBus)
    gameState.systems.achievements = AchievementSystem.new(gameState.systems.eventBus)
    gameState.systems.save = SaveSystem.new()
    
    -- Initialize UI
    gameState.systems.ui = UIManager.new(gameState.systems.eventBus)
    
    -- Initialize game modes
    gameState.modes = {
        idle = IdleMode.new(gameState.systems),
        admin = AdminMode.new(gameState.systems)
    }
    
    -- Try to load saved game
    local savedData = gameState.systems.save:load()
    if savedData then
        Game.loadGameState(savedData)
        print("📁 Loaded saved game")
    else
        -- Initialize with default values
        Game.initializeDefaultState()
        print("✨ Starting new game")
    end
    
    gameState.initialized = true
    
    print("=== Cyberspace Tycoon ===")
    print("🔥 Welcome to the cybersecurity empire!")
    print("⌨️  Controls:")
    print("   A - Crisis Response Mode (Real-time incident handling)")
    print("   U - Upgrades shop")
    print("   H - Achievements & Progress")
    print("   Z - Zone management")
    print("   F - Faction relations")
    print("   S - Statistics")
    print("   P - Pause game")
    print("   D - Debug mode")
    print("   ESC - Quit")
end

-- Initialize default game state for new games
function Game.initializeDefaultState()
    -- Set up initial Cyber Empire Command state
    gameState.systems.resources:setResource("money", 1000)  -- Starting budget
    gameState.systems.resources:setResource("reputation", 0)
    gameState.systems.resources:setResource("xp", 0)
    gameState.systems.resources:setResource("missionTokens", 0)
    
    -- Initialize current zone
    gameState.systems.zones:setCurrentZone("garage")
    
    -- Give player basic achievements progress
    gameState.systems.achievements:initializeProgress()
end

-- Load game state from saved data
function Game.loadGameState(data)
    gameState.systems.resources:loadState(data.resources or {})
    gameState.systems.contracts:loadState(data.contracts or {})  -- NEW: Load contract state
    gameState.systems.specialists:loadState(data.specialists or {})  -- NEW: Load specialist state
    gameState.systems.upgrades:loadState(data.upgrades or {})
    gameState.systems.threats:loadState(data.threats or {})
    gameState.systems.zones:loadState(data.zones or {})
    gameState.systems.factions:loadState(data.factions or {})
    gameState.systems.achievements:loadState(data.achievements or {})
end

-- Update game systems
function Game.update(dt)
    if not gameState.initialized or gameState.paused then
        return
    end
    
    local startTime = love.timer.getTime()
    
    -- Update current game mode
    local currentMode = gameState.modes[gameState.currentMode]
    if currentMode then
        currentMode:update(dt)
    end
    
    -- Update all systems
    for _, system in pairs(gameState.systems) do
        if system.update then
            system:update(dt)
        end
    end
    
    -- Update performance tracking
    gameState.performance.updateTime = love.timer.getTime() - startTime
    gameState.performance.frameCount = gameState.performance.frameCount + 1
    
    local currentTime = love.timer.getTime()
    if currentTime - gameState.performance.lastFPSUpdate >= 1.0 then
        gameState.performance.fps = gameState.performance.frameCount
        gameState.performance.frameCount = 0
        gameState.performance.lastFPSUpdate = currentTime
    end
end

-- Render the game
function Game.draw()
    if not gameState.initialized then
        love.graphics.print("Loading...", 10, 10)
        return
    end
    
    local startTime = love.timer.getTime()
    
    -- Draw UI background first (terminal theme)
    gameState.systems.ui:draw()
    
    -- Render current game mode
    local currentMode = gameState.modes[gameState.currentMode]
    if currentMode then
        currentMode:draw()
    end
    
    -- Debug information
    if gameState.debugMode then
        Game.drawDebugInfo()
    end
    
    gameState.performance.drawTime = love.timer.getTime() - startTime
end

-- Draw debug information
function Game.drawDebugInfo()
    love.graphics.setColor(1, 1, 1, 0.8)
    local y = 10
    local lineHeight = 15
    
    love.graphics.print("DEBUG MODE", 10, y)
    y = y + lineHeight
    love.graphics.print("FPS: " .. gameState.performance.fps, 10, y)
    y = y + lineHeight
    love.graphics.print("Update: " .. string.format("%.3fms", gameState.performance.updateTime * 1000), 10, y)
    y = y + lineHeight
    love.graphics.print("Draw: " .. string.format("%.3fms", gameState.performance.drawTime * 1000), 10, y)
    y = y + lineHeight
    love.graphics.print("Mode: " .. gameState.currentMode, 10, y)
    y = y + lineHeight
    
    -- Show current zone and resources
    local resources = gameState.systems.resources:getAllResources()
    for name, value in pairs(resources) do
        love.graphics.print(name .. ": " .. string.format("%.2f", value), 10, y)
        y = y + lineHeight
    end
end

-- Handle input
function Game.keypressed(key)
    if key == "escape" then
        love.event.quit()
    elseif key == "p" then
        gameState.paused = not gameState.paused
        print(gameState.paused and "⏸️  Game paused" or "▶️  Game resumed")
    elseif key == "d" then
        gameState.debugMode = not gameState.debugMode
    elseif key == "a" then
        -- Toggle between idle and admin modes
        gameState.currentMode = gameState.currentMode == "idle" and "admin" or "idle"
        print("🔄 Switched to " .. gameState.currentMode .. " mode")
    else
        -- Pass input to current mode
        local currentMode = gameState.modes[gameState.currentMode]
        if currentMode and currentMode.keypressed then
            currentMode:keypressed(key)
        end
        
        -- Pass input to UI system
        gameState.systems.ui:keypressed(key)
    end
end

-- Handle mouse input
function Game.mousepressed(x, y, button)
    if not gameState.initialized then
        return
    end
    
    -- Pass to UI first
    if gameState.systems.ui:mousepressed(x, y, button) then
        return
    end
    
    -- Pass to current mode
    local currentMode = gameState.modes[gameState.currentMode]
    if currentMode and currentMode.mousepressed then
        currentMode:mousepressed(x, y, button)
    end
end

-- Save game state
function Game.save()
    if not gameState.initialized then
        return
    end
    
    local saveData = {
        resources = gameState.systems.resources:getState(),
        contracts = gameState.systems.contracts:getState(),  -- NEW: Save contract state
        specialists = gameState.systems.specialists:getState(),  -- NEW: Save specialist state
        upgrades = gameState.systems.upgrades:getState(),
        threats = gameState.systems.threats:getState(),
        zones = gameState.systems.zones:getState(),
        factions = gameState.systems.factions:getState(),
        achievements = gameState.systems.achievements:getState(),
        version = "1.0.0",
        timestamp = os.time()
    }
    
    gameState.systems.save:save(saveData)
    print("💾 Game saved")
end

-- Auto-save periodically
local autoSaveTimer = 0
local AUTO_SAVE_INTERVAL = 60 -- seconds

function Game.handleAutoSave(dt)
    autoSaveTimer = autoSaveTimer + dt
    if autoSaveTimer >= AUTO_SAVE_INTERVAL then
        Game.save()
        autoSaveTimer = 0
    end
end

-- Get game state for external access
function Game.getState()
    return gameState
end

-- Handle window resize
function Game.resize(w, h)
    if gameState.systems and gameState.systems.ui then
        gameState.systems.ui:resize(w, h)
    end
end

return Game