-- Core Game Controller - SOC REFACTOR: Pure Fortress Architecture
-- Manages all game systems and state using fortress components
-- Legacy systems removed - vulnerabilities eradicated

local Game = {}

-- SOC REFACTOR: Import only fortress core components and essential systems
local GameLoop = require("src.core.game_loop")
local ResourceManager = require("src.core.resource_manager") 
local SecurityUpgrades = require("src.core.security_upgrades")
local ThreatSimulation = require("src.core.threat_simulation")
local UIManager = require("src.core.ui_manager")  -- Fortress UI Manager
local SOCStats = require("src.core.soc_stats")  -- SOC Statistical backbone
local EventBus = require("src.utils.event_bus")

-- Essential legacy systems (not duplicated in fortress)
local SkillSystem = require("src.systems.skill_system") 
local ProgressionSystem = require("src.systems.progression_system")
local ZoneSystem = require("src.systems.zone_system")
local LocationSystem = require("src.systems.location_system")
local RoomSystem = require("src.systems.room_system")
local RoomEventSystem = require("src.systems.room_event_system")
local FactionSystem = require("src.systems.faction_system")
local AchievementSystem = require("src.systems.achievement_system")
local ContractSystem = require("src.systems.contract_system")
local SpecialistSystem = require("src.systems.specialist_system")
local NetworkSaveSystem = require("src.systems.network_save_system")
local IdleSystem = require("src.systems.idle_system")
local SoundSystem = require("src.systems.sound_system")
local CrisisGameSystem = require("src.systems.crisis_game_system")
local AdvancedAchievementSystem = require("src.systems.advanced_achievement_system")
local ParticleSystem = require("src.systems.particle_system")
local BuffSystem = require("src.systems.buff_system")

-- Fortress UI components
local FortressUIAdapter = require("src.utils.fortress_ui_adapter")  -- SOC compatibility bridge
local ContractModal = require("src.ui.contract_modal")
local BuffDisplay = require("src.ui.buff_display")

-- Import game modes
local IdleMode = require("src.modes.idle_mode")
local AdminMode = require("src.modes.admin_mode")
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
    
    -- SOC REFACTOR: Initialize fortress core systems first for unified resource management
    print("🏰 Initializing SOC Fortress Core...")
    gameState.systems.resourceManager = ResourceManager.new(gameState.systems.eventBus)
    gameState.systems.securityUpgrades = SecurityUpgrades.new(gameState.systems.eventBus, gameState.systems.resourceManager)  
    gameState.systems.threatSimulation = ThreatSimulation.new(gameState.systems.eventBus, gameState.systems.resourceManager, gameState.systems.securityUpgrades)
    
    -- SOC REFACTOR: Initialize statistical backbone
    gameState.systems.socStats = SOCStats.new(gameState.systems.eventBus, gameState.systems.resourceManager,
                                            gameState.systems.securityUpgrades, gameState.systems.threatSimulation)
    
    -- Initialize fortress core systems
    gameState.systems.resourceManager:initialize()
    gameState.systems.securityUpgrades:initialize()  
    gameState.systems.threatSimulation:initialize()
    gameState.systems.socStats:initialize()  -- SOC REFACTOR: Initialize stats system
    
    -- Essential systems (use fortress resource management where possible)
    gameState.systems.skills = SkillSystem.new(gameState.systems.eventBus)
    gameState.systems.progression = ProgressionSystem.new(gameState.systems.eventBus)
    gameState.systems.contracts = ContractSystem.new(gameState.systems.eventBus, gameState.systems.resourceManager) -- Use fortress resources
    gameState.systems.specialists = SpecialistSystem.new(gameState.systems.eventBus, gameState.systems.resourceManager) -- Use fortress resources
    
    -- Advanced systems  
    gameState.systems.sound = SoundSystem.new(gameState.systems.eventBus)
    gameState.systems.crisisGame = CrisisGameSystem.new(gameState.systems.eventBus)
    gameState.systems.advancedAchievements = AdvancedAchievementSystem.new(gameState.systems.eventBus)
    gameState.systems.particles = ParticleSystem.new(gameState.systems.eventBus)
    gameState.systems.buffs = BuffSystem.new(gameState.systems.eventBus, gameState.systems.resourceManager) -- NEW: Buff system
    gameState.systems.specialists:setSkillSystem(gameState.systems.skills)
    gameState.systems.zones = ZoneSystem.new(gameState.systems.eventBus)
    gameState.systems.locations = LocationSystem.new(gameState.systems.eventBus)
    
    -- Initialize idle system with fortress dependencies
    gameState.systems.idle = IdleSystem.new(gameState.systems.eventBus, gameState.systems.resourceManager, 
                                          gameState.systems.threatSimulation, gameState.systems.securityUpgrades)
    
    -- Room systems (if available)
    local roomSystemExists = pcall(require, "src.systems.room_system")
    if roomSystemExists then
        gameState.systems.rooms = RoomSystem.new(gameState.systems.eventBus)
        gameState.systems.rooms:connectResourceSystem(gameState.systems.resourceManager) -- Use fortress resources
        gameState.systems.roomEvents = RoomEventSystem.new(gameState.systems.eventBus, gameState.systems.rooms)
    end
    
    gameState.systems.factions = FactionSystem.new(gameState.systems.eventBus)
    gameState.systems.achievements = AchievementSystem.new(gameState.systems.eventBus)
    gameState.systems.save = NetworkSaveSystem.new()
    
    -- Configure network save system
    gameState.systems.save:setUsername("player_" .. love.system.getOS() .. "_" .. os.time())
    gameState.systems.save:setSaveMode("local") -- Default to hybrid mode
    
    -- SOC REFACTOR: UI system will be handled by fortress architecture
    -- Create fortress UI manager and compatibility adapter
    local fortressUIManager = UIManager.new(gameState.systems.eventBus, gameState.systems.resourceManager, 
                                          gameState.systems.securityUpgrades, gameState.systems.threatSimulation, nil)
    fortressUIManager:initialize()
    
    -- Create compatibility adapter for legacy UI calls
    gameState.systems.ui = FortressUIAdapter.new(fortressUIManager)
    gameState.systems.uiManager = fortressUIManager  -- Direct fortress access
    gameState.systems.socStats = gameState.systems.socStats  -- Ensure SOC stats available
    
    print("🏰 SOC Fortress UI System initialized")
    
    -- NEW: Initialize advanced UI components
    gameState.systems.contractModal = ContractModal.new(gameState.systems.eventBus)  -- Contract detail modal
    gameState.systems.buffDisplay = BuffDisplay.new(gameState.systems.buffs)  -- NEW: Buff display UI
    
    -- Subscribe to offline progress events
    gameState.systems.eventBus:subscribe("offline_progress_calculated", function(progress)
        -- SOC REFACTOR: Offline progress will be handled by fortress UI system
        -- When fortress UI is available, it will display offline progress
        print("📊 Offline progress: " .. (progress.netGain or 0) .. " money, " .. (progress.totalTime or 0) .. "s")
    end)
    
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
            
            -- Apply offline progress if available
            if savedData.idleTimeSeconds and savedData.idleTimeSeconds > 0 then
                local offlineProgress = gameState.systems.idle:calculateOfflineProgress(savedData.idleTimeSeconds)
                gameState.systems.idle:applyOfflineProgress(offlineProgress)
                if gameState.systems.ui then
                    gameState.systems.ui:logDebug("Processed " .. math.floor(savedData.idleTimeSeconds/60) .. " minutes of offline time")
                end
            end
            
            if gameState.systems.ui then
                gameState.systems.ui:logDebug("Loaded saved game")
            end
        else
            -- Initialize with default values
            Game.initializeDefaultState()
            if gameState.systems.ui then
                gameState.systems.ui:logDebug("Starting new game")
            end
        end
        
        gameState.initialized = true
        
        -- Show welcome message in UI instead of console
        if gameState.systems.ui then
            gameState.systems.ui:showNotification("🔥 Welcome to Cyberspace Tycoon!", 4.0)
            gameState.systems.ui:showNotification("💡 Press ESC for controls and menu", 6.0)
        end
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
    -- Helper to load state on systems that may expose either loadState or setState
    local function tryLoad(systemName, systemObj, stateData)
        if not systemObj then return end
        if not stateData then return end
        if type(systemObj.loadState) == "function" then
            systemObj:loadState(stateData)
        elseif type(systemObj.setState) == "function" then
            systemObj:setState(stateData)
        else
            -- Log verbose warning in debug mode
            if gameState.systems and gameState.systems.ui and gameState.systems.ui.logDebug then
                gameState.systems.ui:logDebug("⚠️  System '" .. systemName .. "' has no loadState/setState method to restore state")
            else
                print("⚠️  System '" .. systemName .. "' has no loadState/setState method to restore state")
            end
        end
    end

    tryLoad("resources", gameState.systems.resources, data.resources or {})
    tryLoad("skills", gameState.systems.skills, data.skills or {})  -- NEW: Load skill state
    tryLoad("progression", gameState.systems.progression, data.progression or {})  -- NEW: Load progression state
    tryLoad("contracts", gameState.systems.contracts, data.contracts or {})  -- NEW: Load contract state
    tryLoad("specialists", gameState.systems.specialists, data.specialists or {})  -- NEW: Load specialist state
    tryLoad("upgrades", gameState.systems.upgrades, data.upgrades or {})
    tryLoad("threats", gameState.systems.threats, data.threats or {})
    tryLoad("idle", gameState.systems.idle, data.idle or {})  -- NEW: Load idle system state
    tryLoad("zones", gameState.systems.zones, data.zones or {})
    tryLoad("locations", gameState.systems.locations, data.locations or {})  -- NEW: Load location state
    tryLoad("factions", gameState.systems.factions, data.factions or {})
    tryLoad("achievements", gameState.systems.achievements, data.achievements or {})
    
    -- NEW: Load room system states (safe)
    tryLoad("rooms", gameState.systems.rooms, data.rooms or {})
    tryLoad("roomEvents", gameState.systems.roomEvents, data.roomEvents or {})

    -- NEW: Load advanced system states (safe)
    tryLoad("sound", gameState.systems.sound, data.sound or {})
    tryLoad("advancedAchievements", gameState.systems.advancedAchievements, data.advancedAchievements or {})
    tryLoad("buffs", gameState.systems.buffs, data.buffs or {})  -- NEW: Load buff system state
    
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
    
    -- Handle autosave
    Game.handleAutoSave(dt)
    
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
    
    -- Draw contract modal (on top of everything)
    if gameState.systems and gameState.systems.contractModal then
        gameState.systems.contractModal:draw()
    end
    
    -- Draw crisis game overlay if active
    if gameState.systems and gameState.systems.crisisGame and gameState.systems.crisisGame:isActive() then
        Game.drawCrisisGameOverlay()
    end
    
    -- Draw particle effects (on top of everything else)
    if gameState.systems and gameState.systems.particles then
        gameState.systems.particles:draw()
    end
    
    -- Draw buff display (on top of everything else)
    if gameState.systems and gameState.systems.buffDisplay then
        gameState.systems.buffDisplay:draw()
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
        -- Toggle navigation modal instead of quitting
        if gameState.systems and gameState.systems.ui then
            gameState.systems.ui:toggleNavigationModal()
        end
    elseif key == "q" and (love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")) then
        -- Ctrl+Q to quit
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
        -- Handle new system shortcuts first
        if key == "c" and gameState.systems.contractModal then
            -- Toggle contract modal with a sample contract (for testing)
            if not gameState.systems.contractModal:isVisible() then
                local sampleContract = {
                    clientName = "TechCorp Industries",
                    description = "Comprehensive security audit and penetration testing for our e-commerce platform",
                    totalBudget = 15000,
                    duration = 240,
                    reputationReward = 8
                }
                gameState.systems.contractModal:show(sampleContract)
                return
            end
        elseif key == "x" and gameState.systems.crisisGame then
            -- Start a random crisis game (for testing)
            if not gameState.systems.crisisGame:isActive() then
                gameState.systems.crisisGame:startCrisis("ddos_attack")
                return
            end
        elseif key == "m" and gameState.systems.sound then
            -- Toggle sound system
            local soundEnabled = gameState.systems.sound:toggle()
            if gameState.systems.eventBus then
                gameState.systems.eventBus:publish("ui.log", {
                    text = "Sound " .. (soundEnabled and "enabled" or "disabled"),
                    severity = "info"
                })
            end
            return
        elseif key == "v" and gameState.systems.particles then
            -- Trigger particle effect demo
            local w, h = love.graphics.getDimensions()
            gameState.systems.particles:emitBurst("achievement", w / 2, h / 2, 15)
            gameState.systems.particles:emitMoneyRain(w / 2, h / 2 + 100, 5000)
            if gameState.systems.eventBus then
                gameState.systems.eventBus:publish("ui.log", {
                    text = "Particle effects demo triggered!",
                    severity = "success"
                })
            end
            return
        end
        
        -- Check if contract modal handles the input
        if gameState.systems.contractModal and gameState.systems.contractModal:keypressed(key) then
            return -- Input was consumed by modal
        end
        
        -- Check if buff display handles the input
        if gameState.systems.buffDisplay and gameState.systems.buffDisplay:keypressed(key) then
            return -- Input was consumed by buff display
        end
        
        -- Check if crisis game handles the input
        if gameState.systems.crisisGame and gameState.systems.crisisGame:keypressed(key) then
            return -- Input was consumed by crisis game
        end
        
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
    
    -- Check new system modals first (highest priority)
    if gameState.systems.contractModal and gameState.systems.contractModal:mousepressed(x, y, button) then
        return -- Input consumed by contract modal
    end
    
    -- Check if buff display handles the input
    if gameState.systems.buffDisplay and gameState.systems.buffDisplay:mousepressed(x, y, button) then
        return -- Input consumed by buff display
    end
    
    if gameState.systems.crisisGame and gameState.systems.crisisGame:mousepressed(x, y, button) then
        return -- Input consumed by crisis game
    end
    
    -- Pass to UI system
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
    -- Helper to safely get state from a system (handles nil/missing getState)
    local function safeState(system)
        if not system or type(system.getState) ~= "function" then return nil end
        local ok, res = pcall(function() return system:getState() end)
        if ok then return res end
        return nil
    end

    local function safePlayerState()
        if not (gameState.modes and gameState.modes.idle and gameState.modes.idle.player) then return nil end
        local p = gameState.modes.idle.player
        if type(p.getState) ~= "function" then return nil end
        local ok, res = pcall(function() return p:getState() end)
        if ok then return res end
        return nil
    end

    local saveData = {
        resources = safeState(gameState.systems and gameState.systems.resources),
        skills = safeState(gameState.systems and gameState.systems.skills),
        progression = safeState(gameState.systems and gameState.systems.progression),
        contracts = safeState(gameState.systems and gameState.systems.contracts),
        specialists = safeState(gameState.systems and gameState.systems.specialists),
        upgrades = safeState(gameState.systems and gameState.systems.upgrades),
        threats = safeState(gameState.systems and gameState.systems.threats),
        idle = safeState(gameState.systems and gameState.systems.idle),
        zones = safeState(gameState.systems and gameState.systems.zones),
        locations = safeState(gameState.systems and gameState.systems.locations),
        rooms = safeState(gameState.systems and gameState.systems.rooms),
        roomEvents = safeState(gameState.systems and gameState.systems.roomEvents),
        factions = safeState(gameState.systems and gameState.systems.factions),
        achievements = safeState(gameState.systems and gameState.systems.achievements),
        sound = safeState(gameState.systems and gameState.systems.sound),
        advancedAchievements = safeState(gameState.systems and gameState.systems.advancedAchievements),
        buffs = safeState(gameState.systems and gameState.systems.buffs),  -- NEW: Save buff system state
        -- Include player state if initialized
        playerState = (gameState.modes and gameState.modes.idle and gameState.modes.idle.player) and gameState.modes.idle.player:getState() or nil,
        -- Tutorial state
        tutorialSeen = gameState.tutorialSeen or false,
        version = "1.0.0",
        timestamp = os.time()
    }

    if not (gameState.systems and gameState.systems.save and type(gameState.systems.save.save) == "function") then
        -- No save system available; log and return
        if gameState.systems and gameState.systems.eventBus then
            gameState.systems.eventBus:publish("ui.log", { text = "❌ Save system unavailable", severity = "error" })
        else
            print("❌ Save system unavailable")
        end
        return
    end

    gameState.systems.save:save(saveData, function(success, result)
        if success then
            if gameState.systems and gameState.systems.idle and type(gameState.systems.idle.updateSaveTime) == "function" then
                pcall(function() gameState.systems.idle:updateSaveTime() end)
            end
            if gameState.systems and gameState.systems.eventBus then
                gameState.systems.eventBus:publish("ui.log", { text = "💾 Game saved: " .. tostring(result), severity = "success" })
                gameState.systems.eventBus:publish("ui.toast", { text = "Game saved", type = "success", duration = 2.5 })
            else
                print("💾 Game saved: " .. tostring(result))
            end
        else
            if gameState.systems and gameState.systems.eventBus then
                gameState.systems.eventBus:publish("ui.log", { text = "❌ Save failed: " .. tostring(result), severity = "error" })
                gameState.systems.eventBus:publish("ui.toast", { text = "Save failed", type = "error", duration = 3.0 })
            else
                print("❌ Save failed: " .. tostring(result))
            end
        end
    end)
end

-- Auto-save periodically
local autoSaveTimer = 0
local AUTO_SAVE_INTERVAL = 15-- seconds

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

-- Draw crisis game overlay
function Game.drawCrisisGameOverlay()
    if not gameState.systems.crisisGame:isActive() then return end
    
    local crisis = gameState.systems.crisisGame:getCurrentCrisis()
    local gameStateInfo = gameState.systems.crisisGame:getGameState()
    
    if not crisis or not gameStateInfo then return end
    
    local w, h = love.graphics.getDimensions()
    
    -- Crisis overlay background
    love.graphics.setColor(0.1, 0.05, 0.05, 0.9)
    love.graphics.rectangle("fill", 0, 0, w, h)
    
    -- Crisis title and info
    love.graphics.setColor(1, 0.2, 0.2, 1)
    love.graphics.printf(crisis.title, 20, 20, w - 40, "center")
    
    love.graphics.setColor(0.9, 0.9, 0.9, 1)
    love.graphics.printf(crisis.description, 20, 60, w - 40, "center")
    
    -- Time remaining
    local timeText = "Time Remaining: " .. math.ceil(gameStateInfo.timeRemaining) .. "s"
    love.graphics.printf(timeText, 20, 100, w - 40, "center")
    
    -- Score
    local scoreText = "Score: " .. gameStateInfo.score
    love.graphics.printf(scoreText, 20, 130, w - 40, "center")
    
    -- Game mode specific rendering
    if gameStateInfo.mode == "packet_filter" then
        Game.drawPacketFilterGame(gameStateInfo)
    elseif gameStateInfo.mode == "malware_hunt" then
        Game.drawMalwareHuntGame(gameStateInfo)
    elseif gameStateInfo.mode == "social_eng_defense" then
        Game.drawSocialEngDefenseGame(gameStateInfo)
    elseif gameStateInfo.mode == "incident_response" then
        Game.drawIncidentResponseGame(gameStateInfo)
    end
    
    -- Instructions
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.printf("ESC to abort crisis", 20, h - 40, w - 40, "center")
end

-- Draw packet filter mini-game
function Game.drawPacketFilterGame(gameStateInfo)
    if not gameStateInfo.state or not gameStateInfo.state.packets then return end
    
    local w, h = love.graphics.getDimensions()
    local gameY = 200
    local gameH = h - 300
    
    -- Draw game area
    love.graphics.setColor(0.1, 0.1, 0.2, 0.8)
    love.graphics.rectangle("fill", 50, gameY, w - 100, gameH)
    
    -- Draw packets
    for _, packet in ipairs(gameStateInfo.state.packets) do
        local color = packet.malicious and {1, 0.3, 0.3} or {0.3, 1, 0.3}
        love.graphics.setColor(color[1], color[2], color[3], 0.8)
        love.graphics.rectangle("fill", packet.x, packet.y, 40, 30, 3, 3)
        
        -- Draw packet info
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.print(packet.packetType or "PKT", packet.x + 2, packet.y + 2)
    end
    
    -- Draw stats
    local stats = gameStateInfo.state
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Blocked: " .. (stats.blockedCount or 0), 60, gameY + gameH + 20)
    love.graphics.print("Wrong: " .. (stats.wrongBlocks or 0), 200, gameY + gameH + 20)
    love.graphics.print("SPACE or CLICK to block malicious packets", 60, gameY + gameH + 40)
end

-- Placeholder drawing methods for other mini-games
function Game.drawMalwareHuntGame(gameStateInfo)
    local w, h = love.graphics.getDimensions()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("MALWARE HUNT - Scan Progress: " .. math.floor((gameStateInfo.state.scanProgress or 0)) .. "%", 20, 200, w - 40, "center")
    love.graphics.printf("Threats Found: " .. (gameStateInfo.state.threatsFound or 0), 20, 230, w - 40, "center")
end

function Game.drawSocialEngDefenseGame(gameStateInfo)
    local w, h = love.graphics.getDimensions()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("SOCIAL ENGINEERING DEFENSE", 20, 200, w - 40, "center")
    love.graphics.printf("Correct: " .. (gameStateInfo.state.correctIdentifications or 0) .. " | False Alarms: " .. (gameStateInfo.state.falseAlarms or 0), 20, 230, w - 40, "center")
    love.graphics.printf("Y = Phishing | N = Legitimate", 20, 260, w - 40, "center")
end

function Game.drawIncidentResponseGame(gameStateInfo)
    local w, h = love.graphics.getDimensions()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("INCIDENT RESPONSE COORDINATION", 20, 200, w - 40, "center")
    if gameStateInfo.state.containmentProgress then
        love.graphics.printf("Containment: " .. math.floor(gameStateInfo.state.containmentProgress) .. "%", 20, 230, w - 40, "center")
    end
    if gameStateInfo.state.stakeholderSatisfaction then
        love.graphics.printf("Stakeholder Satisfaction: " .. math.floor(gameStateInfo.state.stakeholderSatisfaction) .. "%", 20, 260, w - 40, "center")
    end
end

return Game