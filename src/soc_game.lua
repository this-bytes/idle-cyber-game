-- SOCGame - Security Operations Center Game Controller
-- Implements the systematic refactor plan for idle SOC operations
-- Emulates real-life SOC workflows: threat detection, incident response, resource management

local SOCGame = {}
SOCGame.__index = SOCGame

-- Import SOC-focused components
local EventBus = require("src.utils.event_bus")
local SceneManager = require("src.scenes.scene_manager")

-- Import fortress core systems
local GameLoop = require("src.core.game_loop")
local ResourceManager = require("src.core.resource_manager")
local SecurityUpgrades = require("src.core.security_upgrades")
local ThreatSimulation = require("src.core.threat_simulation")
local UIManager = require("src.core.ui_manager")

-- Import save system
local SaveSystem = require("src.systems.save_system")
local SOCIdleOperations = require("src.systems.soc_idle_operations")

-- SOC Game States
local SOC_STATES = {
    LOADING = "loading",
    SPLASH = "splash", 
    OPERATIONAL = "operational", -- Main SOC operations
    PAUSED = "paused",
    CRITICAL = "critical" -- Emergency response mode
}

-- Create new SOC game instance
function SOCGame.new()
    local self = setmetatable({}, SOCGame)
    
    -- Core game state
    self.initialized = false
    self.currentState = SOC_STATES.LOADING
    
    -- Core systems
    self.eventBus = nil
    self.gameLoop = nil
    self.sceneManager = nil
    self.saveSystem = nil
    
    -- Fortress systems
    self.systems = {}
    
    -- SOC-specific state
    self.socOperations = {
        startTime = love.timer.getTime(),
        lastSaveTime = love.timer.getTime(), -- Track for offline progress
        totalThreatsHandled = 0,
        totalIncidentsResolved = 0,
        operationalLevel = "STARTING", -- STARTING, BASIC, ADVANCED, ENTERPRISE
        alertStatus = "GREEN"
    }
    
    -- Auto-save
    self.lastSaveTime = 0
    self.autoSaveInterval = 30 -- Save every 30 seconds
    
    return self
end

-- Initialize the SOC game
function SOCGame:initialize()
    print("🛡️ Initializing SOC Command Center...")
    
    -- Initialize core components
    self:initializeCore()
    
    -- Initialize fortress systems
    self:initializeFortressSystems()
    
    -- Initialize scene management
    self:initializeSceneSystem()
    
    -- Set up SOC-specific integrations
    self:setupSOCIntegrations()
    
    -- Load game data if available
    self:loadGameData()
    
    -- Set initial state
    self.currentState = SOC_STATES.SPLASH
    self.initialized = true
    
    print("✅ SOC Command Center initialization complete!")
    return true
end

-- Initialize core components
function SOCGame:initializeCore()
    print("🔧 Initializing core SOC systems...")
    
    -- Event bus for system communication
    self.eventBus = EventBus.new()
    
    -- Game loop for system orchestration
    self.gameLoop = GameLoop.new(self.eventBus)
    
    -- Save system for persistence
    self.saveSystem = SaveSystem.new()
    
    print("🔧 Core SOC systems initialized")
end

-- Initialize fortress systems with SOC focus
function SOCGame:initializeFortressSystems()
    print("🏰 Initializing SOC fortress architecture...")
    
    -- Resource manager for SOC operations
    self.systems.resourceManager = ResourceManager.new(self.eventBus)
    
    -- Security upgrades for SOC infrastructure
    self.systems.securityUpgrades = SecurityUpgrades.new(self.eventBus, self.systems.resourceManager)
    
    -- Threat simulation for realistic SOC workload
    self.systems.threatSimulation = ThreatSimulation.new(self.eventBus, self.systems.resourceManager, self.systems.securityUpgrades)
    
    -- UI manager for SOC interfaces
    self.systems.uiManager = UIManager.new(self.eventBus, self.systems.resourceManager, 
                                         self.systems.securityUpgrades, self.systems.threatSimulation, self.gameLoop)
    
    -- SOC idle operations for automation and passive gameplay
    self.systems.socIdleOperations = SOCIdleOperations.new(self.eventBus, self.systems.resourceManager,
                                                          self.systems.threatSimulation, self.systems.securityUpgrades)
    
    -- Register systems with game loop in priority order
    self.gameLoop:registerSystem("resourceManager", self.systems.resourceManager, 10)
    self.gameLoop:registerSystem("securityUpgrades", self.systems.securityUpgrades, 20)
    self.gameLoop:registerSystem("threatSimulation", self.systems.threatSimulation, 30)
    self.gameLoop:registerSystem("socIdleOperations", self.systems.socIdleOperations, 40)
    self.gameLoop:registerSystem("uiManager", self.systems.uiManager, 90)
    
    -- Initialize all systems
    self.gameLoop:initialize()
    
    print("🏰 SOC fortress architecture initialized")
end

-- Initialize scene system for SOC workflow
function SOCGame:initializeSceneSystem()
    print("🎬 Initializing SOC scene management...")
    
    -- Create scene manager
    self.sceneManager = SceneManager.new(self.eventBus)
    self.sceneManager:initialize()
    
    -- Register with game loop
    self.gameLoop:registerSystem("sceneManager", self.sceneManager, 95)
    
    print("🎬 SOC scene management initialized")
end

-- Set up SOC-specific integrations
function SOCGame:setupSOCIntegrations()
    print("🔄 Setting up SOC integrations...")
    
    -- Scene transition requests
    self.eventBus:subscribe("scene_request", function(data)
        if data.scene then
            local sceneData = {systems = self.systems}
            self.sceneManager:switchToScene(data.scene, sceneData)
        end
    end)
    
    -- Save/load requests
    self.eventBus:subscribe("save_game_request", function(data)
        self:saveGame()
    end)
    
    self.eventBus:subscribe("load_game_request", function(data)
        self:loadGame()
    end)
    
    self.eventBus:subscribe("restart_game_request", function(data)
        self:restartGame()
    end)
    
    -- SOC operational events
    self.eventBus:subscribe("threat_detected", function(data)
        self.socOperations.totalThreatsHandled = self.socOperations.totalThreatsHandled + 1
        self:updateOperationalLevel()
    end)
    
    self.eventBus:subscribe("incident_resolved", function(data)
        self.socOperations.totalIncidentsResolved = self.socOperations.totalIncidentsResolved + 1
        self:updateOperationalLevel()
    end)
    
    print("🔄 SOC integrations complete")
end

-- Load game data
function SOCGame:loadGameData()
    print("📊 Loading SOC operational data...")
    
    -- Try to load existing save
    if self.saveSystem:saveExists() then
        print("📁 Found existing SOC save data")
        self:loadGame()
        
        -- Calculate offline progress if there was a gap
        self:calculateOfflineProgress()
    else
        print("🆕 Starting new SOC operations")
        self:initializeStartingResources()
    end
    
    print("📊 SOC operational data loaded")
end

-- Initialize starting resources for new SOC
function SOCGame:initializeStartingResources()
    -- Starting SOC resources (garage-level operations)
    local startingResources = {
        money = 5000,      -- Small startup budget
        reputation = 5,    -- Minimal reputation to start
        xp = 0,           -- No experience yet
        missionTokens = 0  -- No government contracts yet
    }
    
    for resource, amount in pairs(startingResources) do
        self.systems.resourceManager:setResource(resource, amount)
    end
    
    print("💰 Starting SOC resources initialized (Budget: $5000, Rep: 5)")
end

-- Calculate offline progress when player returns to the game
function SOCGame:calculateOfflineProgress()
    if not self.systems.socIdleOperations then
        return
    end
    
    local lastSaveTime = self.socOperations.lastSaveTime or love.timer.getTime()
    local currentTime = love.timer.getTime()
    local offlineTime = currentTime - lastSaveTime
    
    -- Only show offline progress if away for more than 2 minutes
    if offlineTime > 120 then
        local progress = self.systems.socIdleOperations:calculateOfflineProgress(offlineTime)
        
        if progress.income > 0 then
            -- Apply offline progress
            self.resourceManager:addResource("money", progress.income)
            self.resourceManager:addResource("xp", progress.xpGained)
            self.resourceManager:addResource("reputation", progress.reputationGained)
            
            -- Update SOC statistics
            self.socOperations.totalThreatsHandled = self.socOperations.totalThreatsHandled + progress.threatsHandled
            self.socOperations.totalIncidentsResolved = self.socOperations.totalIncidentsResolved + progress.incidentsResolved
            
            -- Show offline progress summary
            print("📈 SOC Offline Progress Report:")
            print(progress.summary)
            
            -- Publish event for UI to show offline modal
            self.eventBus:publish("offline_progress_calculated", progress)
        end
    end
    
    -- Update last save time
    self.socOperations.lastSaveTime = currentTime
end

-- Update SOC operational level based on performance
function SOCGame:updateOperationalLevel()
    local totalOperations = self.socOperations.totalThreatsHandled + self.socOperations.totalIncidentsResolved
    local reputation = self.systems.resourceManager:getResource("reputation") or 0
    
    local newLevel = "STARTING"
    if totalOperations >= 100 and reputation >= 50 then
        newLevel = "ENTERPRISE"
    elseif totalOperations >= 50 and reputation >= 25 then
        newLevel = "ADVANCED"
    elseif totalOperations >= 10 and reputation >= 10 then
        newLevel = "BASIC"
    end
    
    if newLevel ~= self.socOperations.operationalLevel then
        self.socOperations.operationalLevel = newLevel
        print("📈 SOC operational level upgraded to: " .. newLevel)
        if self.eventBus then
            self.eventBus:publish("soc_level_upgraded", {level = newLevel})
        end
    end
end

-- Main game loop functions
function SOCGame:update(dt)
    if not self.initialized then
        return
    end
    
    -- Handle different game states
    if self.currentState == SOC_STATES.SPLASH then
        self:updateSplash(dt)
    elseif self.currentState == SOC_STATES.OPERATIONAL then
        self:updateOperational(dt)
    elseif self.currentState == SOC_STATES.CRITICAL then
        self:updateCritical(dt)
    end
    
    -- Update game loop (fortress systems + scene manager)
    self.gameLoop:update(dt)
    
    -- Auto-save
    self:updateAutoSave(dt)
end

function SOCGame:updateSplash(dt)
    -- Quick splash transition to main menu
    self.currentState = SOC_STATES.OPERATIONAL
    -- Scene manager will handle the actual scene display
end

function SOCGame:updateOperational(dt)
    -- SOC is running normally
    -- All operations handled by fortress systems and scene manager
end

function SOCGame:updateCritical(dt)
    -- Emergency response mode
    -- Could auto-switch to incident response scene
end

function SOCGame:updateAutoSave(dt)
    self.lastSaveTime = self.lastSaveTime + dt
    if self.lastSaveTime >= self.autoSaveInterval then
        self:saveGame()
        self.lastSaveTime = 0
    end
end

function SOCGame:draw()
    if not self.initialized then
        love.graphics.print("Initializing SOC Command Center...", 10, 10)
        return
    end
    
    -- Scene manager handles all drawing
    if self.sceneManager then
        self.sceneManager:draw()
    end
    
    -- Debug info if needed
    if love.keyboard.isDown("f1") then
        self:drawDebugInfo()
    end
end

function SOCGame:drawDebugInfo()
    local debugY = 10
    love.graphics.setColor(1, 1, 0, 0.8)
    love.graphics.print("SOC Debug Info:", 10, debugY)
    debugY = debugY + 20
    
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.print("State: " .. self.currentState, 10, debugY)
    debugY = debugY + 15
    love.graphics.print("Scene: " .. (self.sceneManager:getCurrentScene() or "none"), 10, debugY)
    debugY = debugY + 15
    love.graphics.print("Op Level: " .. self.socOperations.operationalLevel, 10, debugY)
    debugY = debugY + 15
    love.graphics.print("Threats: " .. self.socOperations.totalThreatsHandled, 10, debugY)
    debugY = debugY + 15
    love.graphics.print("Incidents: " .. self.socOperations.totalIncidentsResolved, 10, debugY)
    
    love.graphics.setColor(1, 1, 1, 1) -- Reset color
end

-- Input handling
function SOCGame:keypressed(key)
    if self.sceneManager then
        self.sceneManager:keypressed(key)
    end
    
    -- Global hotkeys
    if key == "f5" then
        self:saveGame()
    elseif key == "f9" then
        self:loadGame()
    end
end

function SOCGame:mousepressed(x, y, button)
    if self.sceneManager then
        self.sceneManager:mousepressed(x, y, button)
    end
end

function SOCGame:resize(w, h)
    -- Handle window resize if needed
end

-- Save/Load functionality
function SOCGame:saveGame()
    -- Update last save time before saving
    self.socOperations.lastSaveTime = love.timer.getTime()
    
    local gameData = {
        socOperations = self.socOperations,
        resources = {},
        upgrades = {},
        systems = {}
    }
    
    -- Save resource state
    if self.systems.resourceManager then
        gameData.resources = self.systems.resourceManager:getState()
    end
    
    -- Save upgrade state
    if self.systems.securityUpgrades then
        gameData.upgrades = self.systems.securityUpgrades:getState()
    end
    
    -- Save threat simulation state
    if self.systems.threatSimulation then
        gameData.systems.threatSimulation = self.systems.threatSimulation:getState()
    end
    
    -- Save SOC idle operations state
    if self.systems.socIdleOperations then
        gameData.systems.socIdleOperations = self.systems.socIdleOperations:getState()
    end
    
    local success = self.saveSystem:save(gameData)
    if success then
        print("💾 SOC operations saved successfully")
    else
        print("❌ Failed to save SOC operations")
    end
    
    return success
end

function SOCGame:loadGame()
    local gameData = self.saveSystem:load()
    if not gameData then
        print("❌ No SOC save data found")
        return false
    end
    
    -- Load SOC operations state
    if gameData.socOperations then
        self.socOperations = gameData.socOperations
    end
    
    -- Load resource state
    if gameData.resources and self.systems.resourceManager then
        self.systems.resourceManager:loadState(gameData.resources)
    end
    
    -- Load upgrade state
    if gameData.upgrades and self.systems.securityUpgrades then
        self.systems.securityUpgrades:loadState(gameData.upgrades)
    end
    
    -- Load threat simulation state
    if gameData.systems and gameData.systems.threatSimulation and self.systems.threatSimulation then
        self.systems.threatSimulation:loadState(gameData.systems.threatSimulation)
    end
    
    -- Load SOC idle operations state
    if gameData.systems and gameData.systems.socIdleOperations and self.systems.socIdleOperations then
        self.systems.socIdleOperations:loadState(gameData.systems.socIdleOperations)
    end
    
    print("📁 SOC operations loaded successfully")
    return true
end

function SOCGame:restartGame()
    print("🔄 Restarting SOC operations...")
    
    -- Delete save data
    self.saveSystem:deleteSave()
    
    -- Reset SOC operations
    self.socOperations = {
        startTime = love.timer.getTime(),
        lastSaveTime = love.timer.getTime(),
        totalThreatsHandled = 0,
        totalIncidentsResolved = 0,
        operationalLevel = "STARTING",
        alertStatus = "GREEN"
    }
    
    -- Reset systems
    if self.systems.resourceManager then
        self.systems.resourceManager:initialize()
    end
    if self.systems.securityUpgrades then
        self.systems.securityUpgrades:initialize()
    end
    if self.systems.threatSimulation then
        self.systems.threatSimulation:initialize()
    end
    
    -- Initialize starting resources
    self:initializeStartingResources()
    
    -- Switch to main menu
    self.sceneManager:switchToScene("main_menu")
    
    print("🔄 SOC operations restarted")
end

function SOCGame:shutdown()
    print("🛡️ Shutting down SOC Command Center...")
    
    -- Save before shutdown
    self:saveGame()
    
    print("🛡️ SOC Command Center shutdown complete")
end

-- Get SOC operational statistics
function SOCGame:getSOCStats()
    return {
        operationalLevel = self.socOperations.operationalLevel,
        threatsHandled = self.socOperations.totalThreatsHandled,
        incidentsResolved = self.socOperations.totalIncidentsResolved,
        uptime = love.timer.getTime() - self.socOperations.startTime,
        alertStatus = self.socOperations.alertStatus
    }
end

return SOCGame