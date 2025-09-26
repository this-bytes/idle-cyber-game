-- Core Game Controller
-- Manages all game systems and state

local Game = {}

-- Import game systems
local ResourceSystem = require("src.systems.resource_system")
local ProgressionSystem = require("src.systems.progression_system")  -- NEW: Comprehensive progression
local UpgradeSystem = require("src.systems.upgrade_system")
local ThreatSystem = require("src.systems.threat_system")
local ZoneSystem = require("src.systems.zone_system")
local FactionSystem = require("src.systems.faction_system")
local AchievementSystem = require("src.systems.achievement_system")
local ContractSystem = require("src.systems.contract_system")  -- NEW: Core business system
local SpecialistSystem = require("src.systems.specialist_system")  -- NEW: Team management
local NetworkSaveSystem = require("src.systems.network_save_system")  -- NEW: Network-aware save system
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
    flowState = "splash", -- "splash" -> show splash screen, then switch to idle
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
    -- Ensure placeholder assets exist so OfficeMap can load them
    local ok, placeholderWriter = pcall(require, "tools.write_placeholder_assets")
    if ok and placeholderWriter and love and love.filesystem then
        placeholderWriter.ensure()
    end

    -- Diagnostic: print whether common asset files are visible to love.filesystem
    if love and love.filesystem and love.filesystem.getInfo then
        local assets_to_check = { "assets/player.png", "assets/department.png", "assets/splash.jpeg", "assets/splash.png", "assets/office.png" }
        print("🔎 Asset visibility check:")
        for _, p in ipairs(assets_to_check) do
            local info = love.filesystem.getInfo(p)
            print("   ", p, "->", info ~= nil and "FOUND" or "MISSING")
        end
    end
    
    -- Initialize core systems in order
    gameState.systems.eventBus = EventBus.new()
    -- Make gameState accessible to systems/modes for cross-cutting data (e.g., loaded player state)
    gameState.systems.gameState = gameState
    gameState.systems.resources = ResourceSystem.new(gameState.systems.eventBus)
    gameState.systems.progression = ProgressionSystem.new(gameState.systems.eventBus)  -- NEW: Progression system
    gameState.systems.contracts = ContractSystem.new(gameState.systems.eventBus)  -- NEW: Contract system
    gameState.systems.contracts:setResourceSystem(gameState.systems.resources)  -- NEW: Connect systems
    gameState.systems.specialists = SpecialistSystem.new(gameState.systems.eventBus)  -- NEW: Specialist system
    gameState.systems.upgrades = UpgradeSystem.new(gameState.systems.eventBus)
    gameState.systems.threats = ThreatSystem.new(gameState.systems.eventBus)
    gameState.systems.zones = ZoneSystem.new(gameState.systems.eventBus)
    gameState.systems.factions = FactionSystem.new(gameState.systems.eventBus)
    gameState.systems.achievements = AchievementSystem.new(gameState.systems.eventBus)
    gameState.systems.save = NetworkSaveSystem.new()
    
    -- Configure network save system
    gameState.systems.save:setUsername("player_" .. love.system.getOS() .. "_" .. os.time())
    gameState.systems.save:setSaveMode("local") -- Default to hybrid mode
    
    -- Initialize UI (pass systems so UI can trigger saves / inspect game flags)
    gameState.systems.ui = UIManager.new(gameState.systems)
    
    -- Initialize game modes
    gameState.modes = {
        idle = IdleMode.new(gameState.systems),
        admin = AdminMode.new(gameState.systems)
    }

    -- Start with splash screen state; idle mode will initialize player when entered
    gameState.flowState = "splash"
    
    -- Try to load saved game
    gameState.systems.save:load(function(success, savedData)
        if success and savedData then
            Game.loadGameState(savedData)
            
            -- Apply offline earnings if available
            if savedData.idleTimeSeconds and savedData.idleTimeSeconds > 0 then
                savedData = gameState.systems.save:applyOfflineEarnings(savedData, savedData.idleTimeSeconds)
                Game.loadGameState(savedData) -- Reload with offline earnings applied
            end
            
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
        print("   Z - Debug mode")
        print("   N - Network status")
        print("   ESC - Quit")
    end)
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
    -- Tutorial flag for first-run onboarding
    gameState.tutorialSeen = false
end

-- Load game state from saved data
function Game.loadGameState(data)
    gameState.systems.resources:loadState(data.resources or {})
    gameState.systems.progression:loadState(data.progression or {})  -- NEW: Load progression state
    gameState.systems.contracts:loadState(data.contracts or {})  -- NEW: Load contract state
    gameState.systems.specialists:loadState(data.specialists or {})  -- NEW: Load specialist state
    gameState.systems.upgrades:loadState(data.upgrades or {})
    gameState.systems.threats:loadState(data.threats or {})
    gameState.systems.zones:loadState(data.zones or {})
    gameState.systems.factions:loadState(data.factions or {})
    gameState.systems.achievements:loadState(data.achievements or {})
    -- Store loaded player state for the IdleMode to apply when it initializes
    if data.playerState then
        gameState.loadedPlayerState = data.playerState
    end
    -- Restore tutorial seen flag
    gameState.tutorialSeen = data.tutorialSeen or false
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
    -- Render current game mode first (so UI overlays like HUD/modals are on top)
    if gameState.flowState == "splash" then
        love.graphics.push()
        love.graphics.origin()
        local w, h = love.graphics.getDimensions()
        -- load splash image if available (accept .jpeg or .png)
        -- TODO: load splash image asynchronously during init to avoid hitches
        local splashImage = nil
        local splashPath = nil
        if love.filesystem.getInfo("assets/splash.jpeg") then
            splashPath = "assets/splash.jpeg"
        elseif love.filesystem.getInfo("assets/splash.png") then
            splashPath = "assets/splash.png"
        end
        if splashPath then
            local ok, img = pcall(function() return love.graphics.newImage(splashPath) end)
            if ok and img then splashImage = img end
        end
        if splashImage then
            local imgW, imgH = splashImage:getDimensions()
            local scale = math.min(w / imgW, h / imgH) * 0.8
            love.graphics.draw(splashImage, (w - imgW * scale) / 2, (h - imgH * scale) / 2, 0, scale, scale)
        else
            love.graphics.setColor(0.2, 0.2, 0.2, 1)
            love.graphics.rectangle("fill", 0, 0, w, h)
            love.graphics.setColor(0, 0, 0, 0.9)
            love.graphics.rectangle("fill", 0, 0, w, h)
            love.graphics.setColor(0.1, 0.9, 0.9, 1)
            love.graphics.printf("CYBER EMPIRE COMMAND", 0, h * 0.35, w, "center")
            love.graphics.setColor(1, 1, 1, 0.9)

        end
        love.graphics.printf("Press any key to continue...", 0, h * 0.6, w, "center")
        love.graphics.pop()
    else
        -- Render current game mode
        local currentMode = gameState.modes[gameState.currentMode]
        if currentMode then
            currentMode:draw()
        end
    end

    -- Draw UI overlay (HUD, modals) on top of the mode
    if gameState.systems and gameState.systems.ui then
        gameState.systems.ui:draw()
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
    -- If in splash, any key advances to idle
    if gameState.flowState == "splash" then
        gameState.flowState = "idle"
        -- Ensure idle mode is initialized and player positioned
        gameState.currentMode = "idle"
        if gameState.modes and gameState.modes.idle and gameState.modes.idle.enter then
            gameState.modes.idle:enter()
        end
        print("🎬 Entering game: My Desk")
        return
    end

    if key == "escape" then
        love.event.quit()
    elseif key == "p" then
        gameState.paused = not gameState.paused
        print(gameState.paused and "⏸️  Game paused" or "▶️  Game resumed")
    elseif key == "d" then
        gameState.debugMode = not gameState.debugMode
    elseif key == "r" then
        -- Reload data JSON files at runtime (useful for tuning from backend)
        local defs = pcall(function() return require("src.data.defs") end)
        local contracts = pcall(function() return require("src.data.contracts") end)
        local ok1, r1 = false, nil
        local ok2, r2 = false, nil
        if defs then
            local mod = require("src.data.defs")
            ok1, r1 = pcall(function() return mod.reloadFromJSON() end)
        end
        if contracts then
            local modc = require("src.data.contracts")
            ok2, r2 = pcall(function() return modc.reloadFromJSON() end)
        end
        print("🔁 Data reload: defs=" .. tostring(ok1) .. ", contracts=" .. tostring(ok2))
    elseif key == "n" then
        -- Show network status
        local status = gameState.systems.save:getConnectionStatus()
        print("🌐 Network Status:")
        print("   Online: " .. (status.isOnline and "YES" or "NO"))
        print("   Save Mode: " .. status.saveMode)
        print("   Username: " .. status.username)
        print("   Offline Mode: " .. (status.offlineMode and "YES" or "NO"))
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

-- Handle key releases (forward to mode and UI so input state is consistent)
function Game.keyreleased(key)
    -- Pass to current mode
    local currentMode = gameState.modes[gameState.currentMode]
    if currentMode and currentMode.keyreleased then
        currentMode:keyreleased(key)
    end

    -- Pass to UI if it wants releases
    if gameState.systems and gameState.systems.ui and gameState.systems.ui.keyreleased then
        gameState.systems.ui:keyreleased(key)
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
        progression = gameState.systems.progression:getState(),  -- NEW: Save progression state
        contracts = gameState.systems.contracts:getState(),  -- NEW: Save contract state
        specialists = gameState.systems.specialists:getState(),  -- NEW: Save specialist state
        upgrades = gameState.systems.upgrades:getState(),
        threats = gameState.systems.threats:getState(),
        zones = gameState.systems.zones:getState(),
        factions = gameState.systems.factions:getState(),
        achievements = gameState.systems.achievements:getState(),
        -- Include player state if initialized
        playerState = (gameState.modes and gameState.modes.idle and gameState.modes.idle.player) and gameState.modes.idle.player:getState() or nil,
        -- Tutorial state
        tutorialSeen = gameState.tutorialSeen or false,
        version = "1.0.0",
        timestamp = os.time()
    }
    
    gameState.systems.save:save(saveData, function(success, result)
        if success then
            print("💾 Game saved: " .. result)
        else
            print("❌ Save failed: " .. result)
        end
    end)
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