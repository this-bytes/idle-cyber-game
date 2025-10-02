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
local IdleSystem = require("src.systems.idle_system")
local InputSystem = require("src.systems.input_system")
local ClickRewardSystem = require("src.systems.click_reward_system")
local ParticleSystem = require("src.systems.particle_system")
local AchievementSystem = require("src.systems.achievement_system")
local GameStateEngine = require("src.systems.game_state_engine")

-- Scene Dependencies
local MainMenu = require("src.scenes.main_menu")
local SOCView = require("src.scenes.soc_view")
local UpgradeShop = require("src.scenes.upgrade_shop")
local GameOver = require("src.scenes.game_over")
local IncidentResponse = require("src.scenes.incident_response")
local AdminMode = require("src.modes.admin_mode")
local IdleDebugScene = require("src.scenes.idle_debug")

-- UI Components
local DebugOverlay = require("src.ui.debug_overlay")


local SOCGame = {}
SOCGame.__index = SOCGame

function SOCGame.new(eventBus)
    local self = setmetatable({}, SOCGame)
    self.eventBus = eventBus
    self.systems = {}
    self.sceneManager = nil
    self.debugOverlay = nil
    self.isInitialized = false
    self.isGameStarted = false -- Track if player has started the game
    self.lastExitTime = nil -- Track when player last exited
    return self
end

function SOCGame:initialize()
    -- TODO: migrate prints to a logging system
    if self.isInitialized then
        print("⚠️ SOCGame: Already initialized!")
        return false
    end
    self.isInitialized = true

    print("🛡️ Initializing SOC Game Systems...")
    
    -- 1. Create Game State Engine FIRST (manages all state)
    self.systems.gameStateEngine = GameStateEngine.new(self.eventBus)
    
    -- 2. Create Core Systems & Data Manager
    self.systems.dataManager = DataManager.new(self.eventBus)
    self.systems.dataManager:loadAllData()
    
    -- 3. Create ResourceManager
    self.systems.resourceManager = ResourceManager.new(self.eventBus)

    -- 4. Create Input & Click Systems
    self.systems.inputSystem = InputSystem.new(self.eventBus)
    self.systems.clickRewardSystem = ClickRewardSystem.new(self.eventBus, self.systems.resourceManager, self.systems.upgradeSystem, self.systems.specialistSystem)
    self.systems.particleSystem = ParticleSystem.new(self.eventBus)

    -- 5. Create other systems
    self.systems.skillSystem = SkillSystem.new(self.eventBus, self.systems.dataManager)
    self.systems.upgradeSystem = UpgradeSystem.new(self.eventBus, self.systems.dataManager)
    self.systems.specialistSystem = SpecialistSystem.new(self.eventBus, self.systems.dataManager, self.systems.skillSystem)
    self.systems.contractSystem = ContractSystem.new(self.eventBus, self.systems.dataManager, self.systems.upgradeSystem, self.systems.specialistSystem, nil, nil, self.systems.resourceManager)
    self.systems.eventSystem = EventSystem.new(self.eventBus, self.systems.dataManager, self.systems.resourceManager)
    self.systems.threatSystem = ThreatSystem.new(self.eventBus, self.systems.dataManager, self.systems.specialistSystem, self.systems.skillSystem)
    self.systems.idleSystem = IdleSystem.new(self.eventBus, self.systems.resourceManager, self.systems.threatSystem, self.systems.upgradeSystem)
    self.systems.achievementSystem = AchievementSystem.new(self.eventBus, self.systems.dataManager, self.systems.resourceManager)

    -- 6. Register all systems with GameStateEngine for state management
    self.systems.gameStateEngine:registerSystem("resourceManager", self.systems.resourceManager)
    self.systems.gameStateEngine:registerSystem("skillSystem", self.systems.skillSystem)
    self.systems.gameStateEngine:registerSystem("upgradeSystem", self.systems.upgradeSystem)
    self.systems.gameStateEngine:registerSystem("specialistSystem", self.systems.specialistSystem)
    self.systems.gameStateEngine:registerSystem("contractSystem", self.systems.contractSystem)
    self.systems.gameStateEngine:registerSystem("threatSystem", self.systems.threatSystem)
    self.systems.gameStateEngine:registerSystem("idleSystem", self.systems.idleSystem)
    self.systems.gameStateEngine:registerSystem("achievementSystem", self.systems.achievementSystem)
    
    -- 7. Try to load saved game state
    local saveLoaded = self.systems.gameStateEngine:loadState()
    if saveLoaded then
        print("📂 Loaded game state from previous session")
    else
        print("🎮 Starting new game (no save found)")
    end

    -- 8. Create Scene Manager AFTER systems are created
    self.sceneManager = SceneManager.new(self.eventBus, self.systems)
    
    -- Subscribe to game start events
    self.eventBus:subscribe("scene_request", function(data)
        if data.scene == "soc_view" and not self.isGameStarted then
            self:startGame()
        end
    end)

    -- 9. Initialize Systems (that need it)
    self.systems.contractSystem:initialize()
    self.systems.specialistSystem:initialize()
    self.systems.eventSystem:initialize()
    self.systems.threatSystem:initialize()
    self.sceneManager:initialize()

    -- 10. Register Scenes
    -- Use Smart Main Menu with animations and dual-mode support!
    self.sceneManager:registerScene("main_menu", MainMenu.new(self.eventBus))
    self.sceneManager:registerScene("soc_view", SOCView.new(self.eventBus))
    self.sceneManager:registerScene("upgrade_shop", UpgradeShop.new(self.eventBus))
    self.sceneManager:registerScene("game_over", GameOver.new(self.eventBus))
    self.sceneManager:registerScene("incident_response", IncidentResponse.new(self.eventBus))
    self.sceneManager:registerScene("admin_mode", AdminMode.new())
    self.sceneManager:registerScene("idle_debug", IdleDebugScene.new(self.eventBus))
    
    -- 11. Start Initial Scene (Main Menu)
    self.sceneManager:requestScene("main_menu")
    
    -- 12. Initialize Debug Overlay (overlays on top of any scene)
    self.debugOverlay = DebugOverlay.new(self.eventBus, self.systems)
    print("🔍 Debug Overlay initialized (Toggle with F3)")

    print("✅ SOC Game Systems Initialized!")
    return true
end

function SOCGame:update(dt)
    if not self.sceneManager then
        return
    end
    
    -- Update scene manager (always active for menus)
    self.sceneManager:update(dt)
    
    -- Update debug overlay (always active when visible)
    if self.debugOverlay then
        self.debugOverlay:update(dt)
    end
    
    -- Update GameStateEngine (handles auto-save and state tracking)
    if self.systems.gameStateEngine then
        self.systems.gameStateEngine:update(dt)
    end
    
    -- Only update game systems after game has started
    if not self.isGameStarted then
        return
    end
    
    -- Update contracts
    if self.systems.contractSystem then
        self.systems.contractSystem:update(dt)
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
    if self.systems.achievementSystem then
        self.systems.achievementSystem:update(dt)
    end
    if self.systems.eventSystem then
        self.systems.eventSystem:update(dt)
    end
end

function SOCGame:draw()
    if self.sceneManager then
        self.sceneManager:draw()
    end
    
    -- Draw particle effects on top of everything
    if self.systems.particleSystem then
        self.systems.particleSystem:draw()
    end
    
    -- Draw debug overlay on top of everything (if visible)
    if self.debugOverlay then
        self.debugOverlay:draw()
    end
end

function SOCGame:keypressed(key, scancode, isrepeat)
    -- Handle global debug overlay toggle (F3)
    if key == "f3" then
        if self.debugOverlay then
            self.debugOverlay:toggle()
        end
        return -- Don't pass F3 to other systems
    end
    
    -- Handle input system first (for global actions)
    if self.systems.inputSystem then
        self.systems.inputSystem:keypressed(key, scancode, isrepeat)
    end

    -- Then pass to scene manager
    if self.sceneManager then
        self.sceneManager:keypressed(key, scancode, isrepeat)
    end
end

-- Start the game and calculate offline earnings
function SOCGame:startGame()
    self.isGameStarted = true
    print("🚀 SOCGame: Game started!")
    
    -- Calculate offline earnings using GameStateEngine
    if self.systems.gameStateEngine then
        local offlineProgress = self.systems.gameStateEngine:calculateOfflineEarnings()
        
        if offlineProgress then
            -- Show offline earnings notification
            local timeAwayMinutes = math.floor(offlineProgress.idleTime / 60)
            local timeAwayHours = math.floor(timeAwayMinutes / 60)
            local timeAwayDisplay = timeAwayHours > 0 
                and string.format("%dh %dm", timeAwayHours, timeAwayMinutes % 60)
                or string.format("%dm", timeAwayMinutes)
            
            print(string.format("💰 Offline Earnings: You were away for %s", timeAwayDisplay))
            print(string.format("   Earned: $%d | Damage: $%d | Net: $%d", 
                offlineProgress.earnings or 0,
                offlineProgress.damage or 0,
                offlineProgress.netGain or 0))
            
            -- Event already published by GameStateEngine
        end
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
    print("🛡️ Shutting down SOC game...")
    
    -- Save game state using GameStateEngine
    if self.systems.gameStateEngine then
        self.systems.gameStateEngine:quickSave()
    end
    
    -- Legacy: Also save exit time separately for compatibility
    self:saveExitTime()
    
    print("👋 Shutdown complete")
end

-- Save the current time as exit time
function SOCGame:saveExitTime()
    local exitTime = os.time()
    local saveData = string.format("%d", exitTime)
    local success = love.filesystem.write("last_exit.dat", saveData)
    if success then
        print(string.format("💾 Saved exit time: %d", exitTime))
    else
        print("❌ Failed to save exit time")
    end
end

-- Load the last exit time
function SOCGame:loadExitTime()
    if love.filesystem.getInfo("last_exit.dat") then
        local data, err = love.filesystem.read("last_exit.dat")
        if data then
            self.lastExitTime = tonumber(data)
            if self.lastExitTime then
                print(string.format("📂 Loaded last exit time: %d", self.lastExitTime))
            else
                print("⚠️  Invalid exit time data")
            end
        else
            print("⚠️  Could not read exit time: " .. tostring(err))
        end
    else
        print("📝 No previous exit time found (first run)")
    end
end

return SOCGame