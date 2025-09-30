-- SOCGame - Security Operations Center Game Controller
-- This file now focuses on managing the core game loop and state,
-- while main.lua handles the initial setup and object creation.

local SOCGame = {}
SOCGame.__index = SOCGame

-- Import necessary components
local SceneManager = require("src.scenes.scene_manager")
local DataManager = require("src.utils.data_manager")
local ResourceManager = require("src.core.resource_manager")
local ContractSystem = require("src.systems.contract_system")
local SpecialistSystem = require("src.systems.specialist_system")
local UpgradeSystem = require("src.systems.upgrade_system")
local EventSystem = require("src.systems.event_system")

-- Scene Files
local MainMenu = require("src.scenes.main_menu")
local SOCView = require("src.scenes.soc_view")
local UpgradeShop = require("src.scenes.upgrade_shop")
local GameOver = require("src.scenes.game_over")

function SOCGame.new(eventBus)
    local self = setmetatable({}, SOCGame)
    self.eventBus = eventBus
    self.systems = {}
    self.sceneManager = nil
    return self
end

function SOCGame:initialize()
    print("🛡️ Initializing SOC Game Systems...")

    -- 1. Create Systems
    self.systems.dataManager = DataManager:new()
    self.systems.resourceManager = ResourceManager.new(self.eventBus)
    
    -- Load data BEFORE initializing systems that depend on it
    self.systems.dataManager:loadDataFromFile("contracts", "src/data/contracts.json")
    self.systems.dataManager:loadDataFromFile("specialists", "src/data/specialists.json")
    self.systems.dataManager:loadDataFromFile("upgrades", "src/data/upgrades.json")
    self.systems.dataManager:loadDataFromFile("events", "src/data/events.json")

    -- Now create systems that use the loaded data
    self.systems.upgradeSystem = UpgradeSystem.new(self.eventBus, self.systems.dataManager)
    self.systems.specialistSystem = SpecialistSystem.new(self.eventBus, self.systems.dataManager)
    self.systems.contractSystem = ContractSystem.new(self.eventBus, self.systems.dataManager, self.systems.upgradeSystem, self.systems.specialistSystem)
    self.systems.eventSystem = EventSystem.new(self.eventBus, self.systems.dataManager)
    self.sceneManager = SceneManager.new(self.eventBus)

    -- 3. Initialize Systems (that need it)
    self.systems.contractSystem:initialize()
    self.systems.specialistSystem:initialize()
    self.systems.eventSystem:initialize()
    self.sceneManager:initialize()

    -- 4. Register Scenes
    self.sceneManager:registerScene("main_menu", MainMenu:new(self.eventBus))
    self.sceneManager:registerScene("soc_view", SOCView.new(self.systems, self.eventBus))
    self.sceneManager:registerScene("upgrade_shop", UpgradeShop:new(self.eventBus))
    self.sceneManager:registerScene("game_over", GameOver:new(self.eventBus))
    
    -- 5. Start Initial Scene
    self.sceneManager:requestScene("soc_view")

    print("✅ SOC Game Systems Initialized!")
    return true
end

function SOCGame:update(dt)
    if self.systems.contractSystem then
        self.systems.contractSystem:update(dt)
    end
    if self.systems.specialistSystem then
        self.systems.specialistSystem:update(dt)
    end
    if self.systems.eventSystem then
        self.systems.eventSystem:update(dt)
    end
    if self.sceneManager then
        self.sceneManager:update(dt)
    end
end

function SOCGame:draw()
    if self.sceneManager then
        self.sceneManager:draw()
    end
end

function SOCGame:keypressed(key)
    if self.sceneManager then
        self.sceneManager:keypressed(key)
    end
end

function SOCGame:mousepressed(x, y, button)
    if self.sceneManager then
        self.sceneManager:mousepressed(x, y, button)
    end
end

function SOCGame:resize(w, h)
    if self.sceneManager then
        self.sceneManager:resize(w, h)
    end
end

function SOCGame:shutdown()
    print("Shutting down SOC game...")
end

return SOCGame