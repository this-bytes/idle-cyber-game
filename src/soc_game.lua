-- SOCGame - Security Operations Center Game Controller
-- This file now focuses on managing the core game loop and state,
-- while main.lua handles the initial setup and object creation.

-- System Dependencies
local EventBus = require("src.utils.event_bus")
local DataManager = require("src.core.data_manager")
local SceneManager = require("src.scenes.scene_manager")
local ContractSystem = require("src.systems.contract_system")
local SpecialistSystem = require("src.systems.specialist_system")
local UpgradeSystem = require("src.systems.upgrade_system")
local EventSystem = require("src.systems.event_system")
local ThreatSystem = require("src.systems.threat_system")
local SkillSystem = require("src.systems.skill_system")

-- Scene Dependencies
local MainMenu = require("src.scenes.main_menu")
local SOCView = require("src.scenes.soc_view")
local UpgradeShop = require("src.scenes.upgrade_shop")
local GameOver = require("src.scenes.game_over")
local IncidentResponse = require("src.scenes.incident_response")
local AdminMode = require("src.scenes.admin_mode")


local SOCGame = {}
SOCGame.__index = SOCGame

function SOCGame.new(eventBus)
    local self = setmetatable({}, SOCGame)
    self.eventBus = eventBus
    self.systems = {}
    self.sceneManager = nil
    self.isInitialized = false
    return self
end

function SOCGame:initialize()
    print("🛡️ Initializing SOC Game Systems...")
    -- 1. Create Core Systems & Data Manager
    self.systems.dataManager = DataManager.new(self.eventBus)
    self.systems.dataManager:loadAllData()

    -- Create other systems
    self.systems.skillSystem = SkillSystem.new(self.eventBus, self.systems.dataManager)
    self.systems.upgradeSystem = UpgradeSystem.new(self.eventBus, self.systems.dataManager)
    self.systems.specialistSystem = SpecialistSystem.new(self.eventBus, self.systems.dataManager, self.systems.skillSystem)
    self.systems.contractSystem = ContractSystem.new(self.eventBus, self.systems.dataManager, self.systems.upgradeSystem, self.systems.specialistSystem)
    self.systems.eventSystem = EventSystem.new(self.eventBus, self.systems.dataManager)
    self.systems.threatSystem = ThreatSystem.new(self.eventBus, self.systems.dataManager, self.systems.specialistSystem, self.systems.skillSystem)

    -- 2. Create Scene Manager AFTER systems are created
    self.sceneManager = SceneManager.new(self.eventBus, self.systems)

    -- 3. Initialize Systems (that need it)
    self.systems.contractSystem:initialize()
    self.systems.specialistSystem:initialize()
    self.systems.eventSystem:initialize()
    self.systems.threatSystem:initialize()
    self.sceneManager:initialize()

    -- 4. Register Scenes
    self.sceneManager:registerScene("main_menu", MainMenu.new(self.eventBus))
    self.sceneManager:registerScene("soc_view", SOCView.new(self.eventBus))
    self.sceneManager:registerScene("upgrade_shop", UpgradeShop.new(self.eventBus))
    self.sceneManager:registerScene("game_over", GameOver.new(self.eventBus))
    self.sceneManager:registerScene("incident_response", IncidentResponse.new(self.eventBus))
    self.sceneManager:registerScene("admin_mode", AdminMode.new(self.eventBus))
    
    -- 5. Start Initial Scene
    self.sceneManager:requestScene("soc_view")

    print("✅ SOC Game Systems Initialized!")
    return true
end

function SOCGame:update(dt)
    if self.sceneManager then
        self.sceneManager:update(dt)
    end

    -- Update core systems
    if self.systems.specialistSystem then
        self.systems.specialistSystem:update(dt)
    end
    if self.systems.threatSystem then
        self.systems.threatSystem:update(dt)
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
    -- Handle window resizing if needed
end

function SOCGame:shutdown()
    print("Shutting down SOC game...")
    -- Perform any cleanup here
end

return SOCGame