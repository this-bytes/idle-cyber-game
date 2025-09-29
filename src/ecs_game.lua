-- ECS Game - Pure Entity-Component-System Game Controller
-- Complete replacement for IdleGame using only ECS architecture
-- No legacy systems or backward compatibility

local ECSGame = {}
ECSGame.__index = ECSGame

-- Import ECS framework
local World = require("src.ecs.world")
local EventBus = require("src.utils.event_bus")

-- Import ECS systems
local ThreatSystem = require("src.systems.threat_system")
local UpgradeSystem = require("src.systems.upgrade_system")
local ECSContractSystem = require("src.systems.ecs_contract_system")
local ECSResourceSystem = require("src.systems.ecs_resource_system")

-- Import data loaders
local Contracts = require("src.data.contracts")
local json = require("dkjson")

-- Game states
local GAME_STATES = {
    LOADING = "loading",
    SPLASH = "splash", 
    PLAYING = "playing",
    PAUSED = "paused"
}

-- Create new ECS game instance
function ECSGame.new()
    local self = setmetatable({}, ECSGame)
    
    -- Core ECS components
    self.eventBus = EventBus.new()
    self.world = World.new(self.eventBus)
    
    -- Game state
    self.initialized = false
    self.currentState = GAME_STATES.LOADING
    self.gameTime = 0
    
    -- Game entities
    self.playerEntity = nil
    self.gameStateEntity = nil
    
    -- UI state
    self.showSplash = true
    self.splashTime = 0
    self.splashDuration = 2.0
    
    return self
end

-- Initialize the ECS game
function ECSGame:initialize()
    print("🎯 Initializing Pure ECS Game...")
    
    -- Initialize ECS world
    self.world:initialize()
    
    -- Register all component types
    self:registerComponents()
    
    -- Register all systems
    self:registerSystems()
    
    -- Create game entities
    self:createGameEntities()
    
    -- Load game data
    self:loadGameData()
    
    self.initialized = true
    self.currentState = GAME_STATES.SPLASH
    
    print("✅ Pure ECS Game initialized!")
    return true
end

-- Register all component types
function ECSGame:registerComponents()
    print("🔧 Registering ECS components...")
    
    -- Player components
    self.world:registerComponent("player", {
        name = "string",
        level = "number",
        experience = "number"
    })
    
    -- Resource components  
    self.world:registerComponent("resources", {
        money = "number",
        reputation = "number", 
        experience = "number",
        energy = "number"
    })
    
    -- Game state components
    self.world:registerComponent("gameState", {
        paused = "boolean",
        timeScale = "number",
        totalPlayTime = "number"
    })
    
    -- Contract components
    self.world:registerComponent("contract", {
        id = "string",
        clientName = "string",
        description = "string", 
        budget = "number",
        duration = "number",
        reputationReward = "number",
        completed = "boolean"
    })
    
    -- Active work components
    self.world:registerComponent("activeWork", {
        started = "boolean",
        timeRemaining = "number",
        progress = "number"
    })
    
    -- Threat components (already defined in ThreatSystem)
    self.world:registerComponent("threat", {
        type = "string",
        severity = "number",
        duration = "number",
        active = "boolean"
    })
    
    -- Upgrade components (already defined in UpgradeSystem)  
    self.world:registerComponent("upgrade", {
        id = "string",
        name = "string",
        effects = "table",
        purchased = "boolean"
    })
    
    print("✅ ECS components registered")
end

-- Register all systems
function ECSGame:registerSystems()  
    print("🔧 Registering ECS systems...")
    
    -- Core game systems
    local resourceSystem = ECSResourceSystem.new(self.world, self.eventBus)
    local contractSystem = ECSContractSystem.new(self.world, self.eventBus)
    local skillSystem = require("src.systems.skill_system").new(self.eventBus)
    local specialistSystem = require("src.systems.specialist_system").new(self.eventBus)
    local threatSystem = ThreatSystem.new(self.eventBus)
    local upgradeSystem = UpgradeSystem.new(self.eventBus)
    
    -- Register systems with priorities (lower number = higher priority)
    -- Register resource and specialist systems early so others can query them
    self.world:registerSystem(resourceSystem, 1)  -- Resources first
    -- Skill system should be registered before specialist so specialists can init skills
    self.world:registerSystem(skillSystem, 2)
    self.world:registerSystem(specialistSystem, 3) -- Specialists now third (provide bonuses)
    -- Ensure specialist has reference to skill system
    if specialistSystem.setSkillSystem then
        specialistSystem:setSkillSystem(skillSystem)
    end
    -- Wire contract system with its dependencies
    contractSystem:setResourceSystem(resourceSystem)
    contractSystem:setSpecialistSystem(specialistSystem)
    contractSystem:setUpgradeSystem(upgradeSystem)
    self.world:registerSystem(contractSystem, 3)  -- Contracts third
    self.world:registerSystem(threatSystem, 4)    -- Threats fourth
    self.world:registerSystem(upgradeSystem, 5)   -- Upgrades last
    
    print("✅ ECS systems registered")
end

-- Create initial game entities
function ECSGame:createGameEntities()
    print("🏭 Creating game entities...")
    
    -- Create player entity
    self.playerEntity = self.world:createEntity()
    self.world:addComponent(self.playerEntity, "player", {
        name = "Cyber Security Expert",
        level = 1,
        experience = 0
    })
    
    self.world:addComponent(self.playerEntity, "resources", {
        money = 1000,
        reputation = 0,
        experience = 0, 
        energy = 100
    })
    
    -- Create game state entity
    self.gameStateEntity = self.world:createEntity()
    self.world:addComponent(self.gameStateEntity, "gameState", {
        paused = false,
        timeScale = 1.0,
        totalPlayTime = 0
    })
    
    print("✅ Game entities created")
end

-- Load game data from JSON
function ECSGame:loadGameData()
    print("📊 Loading game data...")
    
    -- Load contracts and create entities
    local contractTemplates = Contracts.getTemplates()
    for i, template in ipairs(contractTemplates) do
        if i <= 3 then  -- Create first 3 contracts as available
            local contractEntity = self.world:createEntity()
            
            self.world:addComponent(contractEntity, "contract", {
                id = template.id,
                clientName = template.clientName,
                description = template.description,
                budget = template.baseBudget,
                duration = template.baseDuration,
                reputationReward = template.reputationReward,
                completed = false
            })
            
            self.world:addComponent(contractEntity, "activeWork", {
                started = false,
                timeRemaining = template.baseDuration,
                progress = 0
            })
        end
    end
    
    print("✅ Game data loaded")
end

-- Main update loop
function ECSGame:update(dt)
    if not self.initialized then
        return
    end
    
    self.gameTime = self.gameTime + dt
    
    -- Handle splash screen
    if self.currentState == GAME_STATES.SPLASH then
        self.splashTime = self.splashTime + dt
        if self.splashTime >= self.splashDuration then
            self.currentState = GAME_STATES.PLAYING
            self.showSplash = false
        end
        return
    end
    
    -- Update game state entity
    if self.gameStateEntity then
        local gameState = self.world:getComponent(self.gameStateEntity, "gameState")
        if gameState then
            gameState.totalPlayTime = gameState.totalPlayTime + dt
        end
    end
    
    -- Update ECS world
    if self.currentState == GAME_STATES.PLAYING then
        self.world:update(dt)
    end
end

-- Main draw loop
function ECSGame:draw()
    if not self.initialized then
        love.graphics.print("Initializing ECS Game...", 10, 10)
        return 
    end
    
    -- Draw splash screen
    if self.showSplash then
        self:drawSplash()
        return
    end
    
    -- Draw main game
    self:drawGame()
end

-- Draw splash screen
function ECSGame:drawSplash()
    local w, h = love.graphics.getDimensions()
    
    love.graphics.setColor(0.1, 0.1, 0.2, 1)
    love.graphics.rectangle("fill", 0, 0, w, h)
    
    love.graphics.setColor(0, 1, 1, 1)
    love.graphics.printf("🎯 CYBER EMPIRE COMMAND", 0, h/2 - 50, w, "center")
    love.graphics.printf("Pure ECS Architecture", 0, h/2 - 20, w, "center")
    
    love.graphics.setColor(1, 1, 1, 0.7)
    love.graphics.printf("Loading...", 0, h/2 + 20, w, "center")
    
    love.graphics.setColor(1, 1, 1, 1)
end

-- Draw main game interface
function ECSGame:drawGame()
    local w, h = love.graphics.getDimensions()
    
    -- Clear background
    love.graphics.setColor(0.05, 0.05, 0.1, 1)
    love.graphics.rectangle("fill", 0, 0, w, h)
    
    -- Draw title
    love.graphics.setColor(0, 1, 1, 1)
    love.graphics.print("🎯 Cyber Empire Command - Pure ECS", 10, 10)
    
    -- Draw player resources
    if self.playerEntity then
        local resources = self.world:getComponent(self.playerEntity, "resources")
        if resources then
            love.graphics.setColor(0, 1, 0, 1)
            love.graphics.print(string.format("💰 Money: $%d", resources.money), 10, 40)
            love.graphics.print(string.format("⭐ Reputation: %d", resources.reputation), 10, 60)
            love.graphics.print(string.format("📚 Experience: %d", resources.experience), 10, 80)
            love.graphics.print(string.format("⚡ Energy: %d", resources.energy), 10, 100)
        end
    end
    
    -- Draw game state
    if self.gameStateEntity then
        local gameState = self.world:getComponent(self.gameStateEntity, "gameState")
        if gameState then
            love.graphics.setColor(1, 1, 1, 0.7)
            love.graphics.print(string.format("⏱️ Play Time: %.1fs", gameState.totalPlayTime), 10, 130)
        end
    end
    
    -- Draw available contracts
    local contractEntities = self.world:query({"contract", "activeWork"})
    love.graphics.setColor(1, 1, 0, 1)
    love.graphics.print("📋 Available Contracts:", 10, 170)
    
    local y = 190
    for i, entityId in ipairs(contractEntities) do
        local contract = self.world:getComponent(entityId, "contract")
        local work = self.world:getComponent(entityId, "activeWork")
        
        if contract and work then
            local status = work.started and "IN PROGRESS" or "AVAILABLE"
            love.graphics.setColor(work.started and {1, 0.5, 0} or {1, 1, 1})
            love.graphics.print(string.format("  %d. %s - $%d (%s)", 
                              i, contract.clientName, contract.budget, status), 10, y)
            y = y + 20
        end
    end
    
    -- Draw ECS stats
    local stats = self.world:getStats()
    love.graphics.setColor(0.5, 0.5, 1, 1)
    love.graphics.print(string.format("🔧 ECS: %d entities, %d systems", 
                       stats.entityCount, stats.systemCount), 10, h - 40)
    
    -- Draw instructions
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.print("Press 1-3 to start contracts, ESC to quit", 10, h - 20)
    
    love.graphics.setColor(1, 1, 1, 1)
end

-- Handle key presses
function ECSGame:keypressed(key)
    if not self.initialized or self.showSplash then
        return
    end
    
    -- Handle contract selection
    if key >= "1" and key <= "3" then
        local contractIndex = tonumber(key)
        local contractEntities = self.world:query({"contract", "activeWork"})
        
        if contractEntities[contractIndex] then
            local entityId = contractEntities[contractIndex]
            local work = self.world:getComponent(entityId, "activeWork")
            local contract = self.world:getComponent(entityId, "contract")
            
            if work and contract and not work.started then
                work.started = true
                print("🚀 Started contract: " .. contract.clientName)
            end
        end
    end
    
    -- Handle pause
    if key == "space" then
        if self.gameStateEntity then
            local gameState = self.world:getComponent(self.gameStateEntity, "gameState")
            if gameState then
                gameState.paused = not gameState.paused
                self.currentState = gameState.paused and GAME_STATES.PAUSED or GAME_STATES.PLAYING
            end
        end
    end
end

-- Clean shutdown
function ECSGame:shutdown()
    if self.world then
        self.world:teardown()
    end
end

return ECSGame