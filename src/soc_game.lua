-- SOCGame - Security Operations Center Game Controller
-- This file now focuses on managing the core game loop and state,
-- while main.lua handles the initial setup and object creation.

-- System Dependencies
local EventBus = require("src.utils.event_bus")
local DataManager = require("src.core.data_manager")
local ResourceManager = require("src.systems.resource_manager")
local SceneManager = require("src.scenes.scene_manager")
local ContractSystem = require("src.systems.contract_system")
local SpecialistSystem = require("src.systems.specialist_system")
local UpgradeSystem = require("src.systems.upgrade_system")
local EventSystem = require("src.systems.event_system")
local ThreatSystem = require("src.systems.threat_system")
local SkillSystem = require("src.systems.skill_system")
local InputSystem = require("src.systems.input_system")
local ClickRewardSystem = require("src.systems.click_reward_system")
local ParticleSystem = require("src.systems.particle_system")

-- Scene Dependencies
local MainMenu = require("src.scenes.main_menu")
local SmartMainMenu = require("src.scenes.main_menu") -- Fallback to regular MainMenu
local SOCView = require("src.scenes.soc_view")
local SmartSOCView = require("src.scenes.soc_view") -- Fallback to regular SOCView
local UpgradeShop = require("src.scenes.upgrade_shop")
local GameOver = require("src.scenes.game_over")
local IncidentResponse = require("src.scenes.incident_response")
local AdminMode = require("src.modes.admin_mode")
local IdleDebugScene = require("src.scenes.idle_debug")


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
    
    -- 2. Create ResourceManager (CRITICAL for playable game!)
    self.systems.resourceManager = ResourceManager.new(self.eventBus)

    -- 3. Create Input & Click Systems (PHASE 2)
    self.systems.inputSystem = InputSystem.new(self.eventBus)
    self.systems.clickRewardSystem = ClickRewardSystem.new(self.eventBus, self.systems.resourceManager, self.systems.upgradeSystem, self.systems.specialistSystem)
    self.systems.particleSystem = ParticleSystem.new(self.eventBus)

    -- 4. Create other systems
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
    -- Use Smart Main Menu with animations and dual-mode support!
    self.sceneManager:registerScene("main_menu", SmartMainMenu.new(self.eventBus))
    self.sceneManager:registerScene("soc_view", SOCView.new(self.eventBus))
    self.sceneManager:registerScene("upgrade_shop", UpgradeShop.new(self.eventBus))
    self.sceneManager:registerScene("game_over", GameOver.new(self.eventBus))
    self.sceneManager:registerScene("incident_response", IncidentResponse.new(self.eventBus))
    self.sceneManager:registerScene("admin_mode", AdminMode.new(self.eventBus))
    self.sceneManager:registerScene("idle_debug", IdleDebugScene.new(self.eventBus))
    
    -- 5. Start Initial Scene (Main Menu)
    self.sceneManager:requestScene("main_menu")

    print("✅ SOC Game Systems Initialized!")
    return true
end

function SOCGame:update(dt)
    if self.sceneManager then
        self.sceneManager:update(dt)
    end

    -- Update core systems
    if self.systems.resourceManager then
        self.systems.resourceManager:update(dt)
    end
    if self.systems.inputSystem then
        self.systems.inputSystem:update(dt)
    end
    if self.systems.clickRewardSystem then
        self.systems.clickRewardSystem:update(dt)
    end
    if self.systems.particleSystem then
        self.systems.particleSystem:update(dt)
    end
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
    
    -- Draw particle effects on top of everything (Phase 2)
    if self.systems.particleSystem then
        self.systems.particleSystem:draw()
    end
end

function SOCGame:keypressed(key, scancode, isrepeat)
    -- Handle input system first (for global actions)
    if self.systems.inputSystem then
        self.systems.inputSystem:keypressed(key, scancode, isrepeat)
    end

    -- Then pass to scene manager
    if self.sceneManager then
        self.sceneManager:keypressed(key, scancode, isrepeat)
    end
end

function SOCGame:keyreleased(key)
    if self.systems.inputSystem then
        self.systems.inputSystem:keyreleased(key)
    end

    if self.sceneManager then
        self.sceneManager:keyreleased(key)
    end
end

function SOCGame:mousepressed(x, y, button, istouch, presses)
    -- Log at SOCGame layer to verify coordinate mapping after LÖVE dispatch
    print(string.format("[UI RAW] SOCGame:mousepressed x=%.1f y=%.1f button=%s", x, y, tostring(button)))

    -- Handle input system first (for global click actions)
    if self.systems.inputSystem then
        self.systems.inputSystem:mousepressed(x, y, button, istouch, presses)
    end

    if self.sceneManager then
        self.sceneManager:mousepressed(x, y, button, istouch, presses)
    else
        print("[UI RAW] SOCGame:mousepressed but no sceneManager present")
    end
end

function SOCGame:mousereleased(x, y, button, istouch, presses)
    if self.systems.inputSystem then
        self.systems.inputSystem:mousereleased(x, y, button, istouch, presses)
    end

    if self.sceneManager and self.sceneManager.mousereleased then
        self.sceneManager:mousereleased(x, y, button, istouch, presses)
    end
end

function SOCGame:mousemoved(x, y, dx, dy)
    if self.sceneManager and self.sceneManager.mousemoved then
        self.sceneManager:mousemoved(x, y, dx, dy)
    end
end

function SOCGame:wheelmoved(x, y)
    if self.sceneManager and self.sceneManager.wheelmoved then
        self.sceneManager:wheelmoved(x, y)
    end
end

function SOCGame:resize(w, h)
    if self.sceneManager and self.sceneManager.resize then
        self.sceneManager:resize(w, h)
    end
end

function SOCGame:shutdown()
    print("Shutting down SOC game...")
    -- Perform any cleanup here
end

return SOCGame