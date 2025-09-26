-- Core Game Controller - Cyber Empire Command
-- Bootstrap architecture following instruction files
-- Manages all game systems and state with data-driven approach

local Game = {}

-- Import configuration
local GameConfig = require("src.config.game_config")

-- Import core systems
local ResourceSystem = require("src.systems.resource_system")
local ContractSystem = require("src.systems.contract_system")
local SpecialistSystem = require("src.systems.specialist_system")
local SaveSystem = require("src.systems.save_system")
local EventBus = require("src.utils.event_bus")

-- Import UI systems
local UIManager = require("src.ui.ui_manager")

-- Import game modes
local IdleMode = require("src.modes.idle_mode")
local AdminMode = require("src.modes.admin_mode")

-- Optional legacy systems (will be phased out)
local UpgradeSystem = require("src.systems.upgrade_system")
local ThreatSystem = require("src.systems.threat_system")
local ZoneSystem = require("src.systems.zone_system")
local FactionSystem = require("src.systems.faction_system")
local AchievementSystem = require("src.systems.achievement_system")

-- Game state - Clean bootstrap architecture
local gameState = {
    initialized = false,
    paused = false,
    currentMode = "idle", -- "idle" or "admin"
    debugMode = false,
    
    -- Core systems (prioritized)
    systems = {},
    
    -- Performance and state tracking
    performance = {
        frameCount = 0,
        fps = 0,
        lastFPSUpdate = 0,
        updateTime = 0,
        drawTime = 0,
    },
    
    -- Save/load state
    lastSaveTime = 0,
}

-- Initialize the game - Bootstrap architecture
function Game.init()
    print("🚀 Initializing " .. GameConfig.GAME_TITLE .. "...")
    print("📋 Version: " .. GameConfig.VERSION)
    
    -- Initialize core systems in dependency order
    gameState.systems.eventBus = EventBus.new()
    
    -- Core business systems (priority)
    gameState.systems.resources = ResourceSystem.new(gameState.systems.eventBus)
    gameState.systems.contracts = ContractSystem.new(gameState.systems.eventBus)
    gameState.systems.specialists = SpecialistSystem.new(gameState.systems.eventBus)
    gameState.systems.save = SaveSystem.new()
    
    -- UI and interaction systems
    gameState.systems.ui = UIManager.new(gameState.systems.eventBus)
    
    -- Game modes
    gameState.modes = {
        idle = IdleMode.new(gameState.systems),
        admin = AdminMode.new(gameState.systems)
    }
    
    -- Legacy systems (will be gradually removed)
    gameState.systems.upgrades = UpgradeSystem.new(gameState.systems.eventBus)
    gameState.systems.threats = ThreatSystem.new(gameState.systems.eventBus)
    gameState.systems.zones = ZoneSystem.new(gameState.systems.eventBus)
    gameState.systems.factions = FactionSystem.new(gameState.systems.eventBus)
    gameState.systems.achievements = AchievementSystem.new(gameState.systems.eventBus)
    
    -- Try to load saved game
    local savedData = gameState.systems.save:load()
    if savedData then
        Game.loadGameState(savedData)
        print("📁 Loaded saved game")
    else
        -- Initialize with default values from config
        Game.initializeDefaultState()
        print("✨ Starting new " .. GameConfig.GAME_TITLE)
    end
    
    gameState.initialized = true
    
    print("=== " .. GameConfig.GAME_TITLE .. " ===")
    print("🔥 Welcome to your cybersecurity consultancy!")
    Game.printControls()
end

-- Print game controls
function Game.printControls()
    print("⌨️  Controls:")
    print("   A - The Admin's Watch (Crisis response mode)")
    print("   U - Upgrades & Equipment")
    print("   C - Contracts & Clients") 
    print("   T - Team & Specialists")
    print("   S - Statistics & Analytics")
    print("   P - Pause game")
    print("   D - Debug mode")
    print("   ESC - Quit")
end

-- Initialize default game state for new games
function Game.initializeDefaultState()
    -- Set up initial resources from config
    for resourceName, resourceConfig in pairs(GameConfig.RESOURCES) do
        gameState.systems.resources:setResource(resourceName, resourceConfig.startingAmount)
    end
    
    -- Legacy initialization (TODO: Remove after full refactor)
    if gameState.systems.zones then
        gameState.systems.zones:setCurrentZone("garage")
    end
    
    print("💼 Started with $" .. GameConfig.RESOURCES.money.startingAmount .. " initial capital")
    print("🎯 Ready to build your cybersecurity empire!")
end
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
    
    -- Render current game mode
    local currentMode = gameState.modes[gameState.currentMode]
    if currentMode then
        currentMode:draw()
    end
    
    -- Render UI
    gameState.systems.ui:draw()
    
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

-- Auto-save periodically using config interval
local autoSaveTimer = 0

function Game.handleAutoSave(dt)
    if not gameState.initialized then return end
    
    autoSaveTimer = autoSaveTimer + dt
    if autoSaveTimer >= GameConfig.BALANCE.autoSaveInterval then
        Game.save()
        autoSaveTimer = 0
        gameState.lastSaveTime = love.timer.getTime()
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