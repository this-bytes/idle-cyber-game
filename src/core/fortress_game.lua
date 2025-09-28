-- FortressGame - Integrated Game Controller with Fortress Architecture
-- Fortress Refactor Phase 2: Seamless integration of fortress components with legacy systems
-- Replaces the monolithic game.lua with clean, modular fortress architecture

local FortressGame = {}
FortressGame.__index = FortressGame

-- Import fortress core components
local GameLoop = require("src.core.game_loop")
local ResourceManager = require("src.core.resource_manager")
local SecurityUpgrades = require("src.core.security_upgrades")
local ThreatSimulation = require("src.core.threat_simulation")
local UIManager = require("src.core.ui_manager")
local SOCStats = require("src.core.soc_stats")  -- SOC REFACTOR: Statistical backbone
local EventBus = require("src.utils.event_bus")

-- Import legacy systems for integration
local SkillSystem = require("src.systems.skill_system")
local ProgressionSystem = require("src.systems.progression_system")
local LocationSystem = require("src.systems.location_system")
local ContractSystem = require("src.systems.contract_system")
local SpecialistSystem = require("src.systems.specialist_system")
local IdleSystem = require("src.systems.idle_system")
local FactionSystem = require("src.systems.faction_system")
local AchievementSystem = require("src.systems.achievement_system")

-- Import game modes
local IdleMode = require("src.modes.idle_mode")
local AdminMode = require("src.modes.admin_mode")

-- Create fortress game controller
function FortressGame.new()
    local self = setmetatable({}, FortressGame)
    
    -- Fortress state
    self.initialized = false
    self.currentMode = "idle"
    self.flowState = "splash" -- "splash" -> "game"
    self.debugMode = false
    
    -- Core fortress components
    self.eventBus = EventBus.new()
    self.gameLoop = GameLoop.new(self.eventBus)
    
    -- System storage
    self.systems = {}
    self.modes = {}
    
    -- Performance and state
    self.lastSaveTime = 0
    self.autoSaveInterval = 30 -- seconds
    
    return self
end

-- Initialize the fortress game
function FortressGame:initialize()
    if self.initialized then
        return
    end
    
    print("🏰 Initializing Fortress Game Architecture...")
    
    -- Initialize fortress core systems first
    self:initializeFortressSystems()
    
    -- Initialize legacy systems with fortress integration
    self:initializeLegacySystems()
    
    -- Initialize game modes
    self:initializeGameModes()
    
    -- Set up inter-system dependencies and integrations
    self:setupSystemIntegrations()
    
    -- Initialize the game loop (this will initialize all registered systems)
    self.gameLoop:initialize()
    
    -- Set UI state
    self.systems.uiManager:setState("SPLASH")
    
    self.initialized = true
    print("🏰 Fortress Game Architecture initialized successfully!")
    
    return true
end

-- Initialize fortress core systems
function FortressGame:initializeFortressSystems()
    print("🔧 Initializing Fortress Core Systems...")
    
    -- Create fortress systems
    self.systems.resourceManager = ResourceManager.new(self.eventBus)
    self.systems.securityUpgrades = SecurityUpgrades.new(self.eventBus, self.systems.resourceManager)
    self.systems.threatSimulation = ThreatSimulation.new(self.eventBus, self.systems.resourceManager, self.systems.securityUpgrades)
    
    -- SOC REFACTOR: Initialize statistical backbone
    self.systems.socStats = SOCStats.new(self.eventBus, self.systems.resourceManager, 
                                        self.systems.securityUpgrades, self.systems.threatSimulation)
    
    -- Update UI manager to include SOC stats
    self.systems.uiManager = UIManager.new(self.eventBus, self.systems.resourceManager, 
                                         self.systems.securityUpgrades, self.systems.threatSimulation, self.gameLoop)
    
    -- Register with game loop in priority order
    self.gameLoop:registerSystem("resourceManager", self.systems.resourceManager, 10)
    self.gameLoop:registerSystem("securityUpgrades", self.systems.securityUpgrades, 20)
    self.gameLoop:registerSystem("threatSimulation", self.systems.threatSimulation, 30)
    self.gameLoop:registerSystem("socStats", self.systems.socStats, 35)  -- SOC REFACTOR: Stats system
    self.gameLoop:registerSystem("uiManager", self.systems.uiManager, 90)
    
    print("🔧 Fortress Core Systems registered with GameLoop")
end

-- Initialize legacy systems with fortress integration
function FortressGame:initializeLegacySystems()
    print("🔗 Integrating Legacy Systems with Fortress Architecture...")
    
    -- Initialize legacy systems
    self.systems.skills = SkillSystem.new(self.eventBus)
    self.systems.progression = ProgressionSystem.new(self.eventBus)
    self.systems.locations = LocationSystem.new(self.eventBus)
    self.systems.contracts = ContractSystem.new(self.eventBus, self.systems.resourceManager) -- Use fortress ResourceManager
    self.systems.specialists = SpecialistSystem.new(self.eventBus, self.systems.resourceManager) -- Use fortress ResourceManager
    self.systems.factions = FactionSystem.new(self.eventBus)
    self.systems.achievements = AchievementSystem.new(self.eventBus)
    
    -- Initialize idle system with fortress dependencies
    self.systems.idle = IdleSystem.new(self.eventBus, self.systems.resourceManager, self.systems.threatSimulation, self.systems.securityUpgrades)
    
    -- Register legacy systems with game loop
    self.gameLoop:registerSystem("skills", self.systems.skills, 40)
    self.gameLoop:registerSystem("progression", self.systems.progression, 45)
    self.gameLoop:registerSystem("locations", self.systems.locations, 50)
    self.gameLoop:registerSystem("contracts", self.systems.contracts, 55)
    self.gameLoop:registerSystem("specialists", self.systems.specialists, 60)
    self.gameLoop:registerSystem("idle", self.systems.idle, 65)
    self.gameLoop:registerSystem("factions", self.systems.factions, 70)
    self.gameLoop:registerSystem("achievements", self.systems.achievements, 75)
    
    print("🔗 Legacy Systems integrated with Fortress Architecture")
end

-- Initialize game modes
function FortressGame:initializeGameModes()
    -- Create modified systems table that includes eventBus for legacy compatibility
    local systemsWithEventBus = {}
    for name, system in pairs(self.systems) do
        systemsWithEventBus[name] = system
    end
    systemsWithEventBus.eventBus = self.eventBus -- Add eventBus for legacy mode compatibility
    
    -- Create game modes with fortress system references
    self.modes.idle = IdleMode.new(systemsWithEventBus)
    self.modes.admin = AdminMode.new(systemsWithEventBus)
    
    print("🎮 Game Modes initialized with fortress compatibility")
end

-- Set up inter-system integrations and event bindings
function FortressGame:setupSystemIntegrations()
    print("🔄 Setting up system integrations...")
    
    -- Contract system integration with fortress ResourceManager
    self.eventBus:subscribe("contract_completed", function(data)
        -- This will be handled by ResourceManager automatically via the event
        print("💼 Contract completed through fortress integration")
    end)
    
    -- Specialist system integration
    self.eventBus:subscribe("specialist_hired", function(data)
        print("👨‍💻 Specialist hired through fortress integration")
    end)
    
    -- Idle system integration with fortress threat simulation
    self.eventBus:subscribe("idle_progress_calculated", function(data)
        print("⏰ Idle progress calculated through fortress integration")
    end)
    
    -- Achievement integration
    self.eventBus:subscribe("achievement_unlocked", function(data)
        self.systems.uiManager:showNotification("🏆 Achievement: " .. (data.name or "Unknown"), "success")
    end)
    
    print("🔄 System integrations complete")
end

-- Update the fortress game
function FortressGame:update(dt)
    if not self.initialized then
        return
    end
    
    -- Update game loop (this handles all system updates)
    self.gameLoop:update(dt)
    
    -- Update current game mode
    local currentMode = self.modes[self.currentMode]
    if currentMode and currentMode.update then
        currentMode:update(dt)
    end
    
    -- Handle auto-save
    self:handleAutoSave(dt)
end

-- Draw the fortress game
function FortressGame:draw()
    if not self.initialized then
        love.graphics.print("Loading Fortress Architecture...", 10, 10)
        return
    end
    
    -- Handle splash screen
    if self.flowState == "splash" then
        self.systems.uiManager:draw()
        return
    end
    
    -- Draw current game mode
    local currentMode = self.modes[self.currentMode]
    if currentMode and currentMode.draw then
        currentMode:draw()
    end
    
    -- Draw UI overlay (fortress UI manager handles everything)
    self.systems.uiManager:draw()
    
    -- Debug info
    if self.debugMode then
        self:drawDebugInfo()
    end
end

-- Handle key press events
function FortressGame:keypressed(key)
    -- Handle splash screen advancement
    if self.flowState == "splash" then
        self.flowState = "game"
        self.systems.uiManager:setState("GAME")
        
        -- Initialize idle mode
        if self.modes.idle and self.modes.idle.enter then
            self.modes.idle:enter()
        end
        print("🎬 Entering fortress game")
        return
    end
    
    -- Global key handlers
    if key == "escape" then
        -- Toggle pause or navigation
        if self.systems.uiManager then
            self.systems.uiManager:togglePanel("navigation")
        end
    elseif key == "q" and (love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")) then
        -- Ctrl+Q to quit
        love.event.quit()
    elseif key == "p" then
        -- Toggle pause
        local isPaused = self.gameLoop.isPaused
        self.gameLoop:setPaused(not isPaused)
    elseif key == "d" then
        -- Toggle debug mode
        self.debugMode = not self.debugMode
    elseif key == "s" and (love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")) then
        -- Ctrl+S to save
        self:save()
        self.systems.uiManager:showNotification("💾 Game Saved", "success")
    elseif key == "r" then
        -- Reset/reload (for development)
        print("🔄 Reloading fortress game...")
        self:initialize()
    end
    
    -- Mode-specific key handling
    local currentMode = self.modes[self.currentMode]
    if currentMode and currentMode.keypressed then
        currentMode:keypressed(key)
    end
end

-- Handle mouse press events
function FortressGame:mousepressed(x, y, button)
    local currentMode = self.modes[self.currentMode]
    if currentMode and currentMode.mousepressed then
        currentMode:mousepressed(x, y, button)
    end
end

-- Handle window resize
function FortressGame:resize(w, h)
    if self.systems.uiManager then
        self.systems.uiManager:resize(w, h)
    end
    
    local currentMode = self.modes[self.currentMode]
    if currentMode and currentMode.resize then
        currentMode:resize(w, h)
    end
end

-- Auto-save handling
function FortressGame:handleAutoSave(dt)
    local currentTime = love.timer.getTime()
    
    if self.lastSaveTime == 0 then
        self.lastSaveTime = currentTime
        return
    end
    
    if currentTime - self.lastSaveTime >= self.autoSaveInterval then
        self:save()
        self.lastSaveTime = currentTime
        print("💾 Fortress Auto-save completed")
    end
end

-- Save game state
function FortressGame:save()
    local saveData = {
        fortress = {
            currentMode = self.currentMode,
            flowState = self.flowState,
            debugMode = self.debugMode
        },
        systems = {}
    }
    
    -- Save all system states
    for name, system in pairs(self.systems) do
        if system.getState then
            saveData.systems[name] = system:getState()
        end
    end
    
    -- Save mode states
    saveData.modes = {}
    for name, mode in pairs(self.modes) do
        if mode.getState then
            saveData.modes[name] = mode:getState()
        end
    end
    
    -- Write save data (placeholder - would use proper save system)
    print("💾 Fortress save data prepared (" .. self:countKeys(saveData.systems) .. " systems)")
    
    -- Publish save event
    self.eventBus:publish("game_saved", saveData)
    
    return saveData
end

-- Load game state
function FortressGame:load(saveData)
    if not saveData then
        print("💾 No fortress save data to load")
        return
    end
    
    print("💾 Loading fortress save data...")
    
    -- Load fortress state
    if saveData.fortress then
        self.currentMode = saveData.fortress.currentMode or "idle"
        self.flowState = saveData.fortress.flowState or "splash"
        self.debugMode = saveData.fortress.debugMode or false
    end
    
    -- Load system states
    if saveData.systems then
        for name, systemData in pairs(saveData.systems) do
            local system = self.systems[name]
            if system and system.loadState then
                system:loadState(systemData)
            end
        end
    end
    
    -- Load mode states
    if saveData.modes then
        for name, modeData in pairs(saveData.modes) do
            local mode = self.modes[name]
            if mode and mode.loadState then
                mode:loadState(modeData)
            end
        end
    end
    
    -- Publish load event
    self.eventBus:publish("game_loaded", saveData)
    
    print("💾 Fortress save data loaded successfully")
end

-- Draw debug information
function FortressGame:drawDebugInfo()
    local y = 10
    local lineHeight = 20
    
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.rectangle("fill", 5, 5, 400, 200)
    love.graphics.setColor(0, 0, 0, 1)
    
    love.graphics.print("🏰 FORTRESS DEBUG", 10, y)
    y = y + lineHeight
    
    -- Performance metrics
    local metrics = self.gameLoop:getPerformanceMetrics()
    love.graphics.print("FPS: " .. (metrics.fps or 0), 10, y)
    y = y + lineHeight
    love.graphics.print("Update: " .. string.format("%.3fms", (metrics.updateTime or 0) * 1000), 10, y)
    y = y + lineHeight
    love.graphics.print("Time Scale: " .. string.format("%.1fx", metrics.timeScale or 1.0), 10, y)
    y = y + lineHeight
    
    -- System count
    love.graphics.print("Systems: " .. self:countKeys(self.systems), 10, y)
    y = y + lineHeight
    
    -- Resources
    if self.systems.resourceManager then
        local resources = self.systems.resourceManager:getAllResources()
        for name, value in pairs(resources) do
            love.graphics.print(name .. ": " .. string.format("%.0f", value), 10, y)
            y = y + lineHeight
            if y > 180 then break end
        end
    end
end

-- Utility function to count table keys
function FortressGame:countKeys(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

-- Shutdown the fortress game
function FortressGame:shutdown()
    if not self.initialized then
        return
    end
    
    print("🏰 Shutting down Fortress Game Architecture...")
    
    -- Save before shutdown
    self:save()
    
    -- Shutdown game loop (this handles all system shutdowns)
    self.gameLoop:shutdown()
    
    self.initialized = false
    print("🏰 Fortress Game Architecture shutdown complete")
end

return FortressGame