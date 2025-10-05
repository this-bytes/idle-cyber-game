-- SOCGame - Security Operations Center Game Controller
-- This file now focuses on managing the core game loop and state,
-- while main.lua handles the initial setup and object creation.

-- System Dependencies
local EventBus = require("src.utils.event_bus")
local DataManager = require("src.systems.data_manager")
local ResourceManager = require("src.systems.resource_manager")
local SceneManager = require("src.scenes.scenery_adapter")
local ContractSystem = require("src.systems.contract_system")
local SpecialistSystem = require("src.systems.specialist_system")
local UpgradeSystem = require("src.systems.upgrade_system")
local EventSystem = require("src.systems.event_system")
local ThreatSystem = require("src.systems.threat_system")
local SkillSystem = require("src.systems.skill_system")
local IdleSystem = require("src.systems.idle_system")
local IncidentSpecialistSystem = require("src.systems.incident_specialist_system")
local InputSystem = require("src.systems.input_system")
local ClickRewardSystem = require("src.systems.click_reward_system")
local ParticleSystem = require("src.systems.particle_system")
local AchievementSystem = require("src.systems.achievement_system")
local GameStateEngine = require("src.systems.game_state_engine")

-- Scene Dependencies
local MainMenuLuis = require("src.scenes.main_menu_luis")
local SOCViewLuis = require("src.scenes.soc_view_luis")
local UpgradeShopLuis = require("src.scenes.upgrade_shop_luis")
local SkillTreeScene = require("src.scenes.skill_tree_luis")
local ContractsBoardScene = require("src.scenes.contracts_board_luis")
local SpecialistManagementScene = require("src.scenes.specialist_management_luis")
local ModalDialog = require("src.scenes.modal_dialog_luis") -- New Modal Scene
local GameOverLuis = require("src.scenes.game_over_luis")
local IncidentResponseLuis = require("src.scenes.incident_response_luis")
local AdminModeLuis = require("src.scenes.admin_mode_luis")
local AdminIncidentScene = require("src.scenes.incident_admin_luis")
local IdleDebugScene = require("src.scenes.idle_debug")

-- UI Components
local StatsOverlayLuis = require("src.ui.stats_overlay_luis")
local OverlayManager = require("src.ui.overlay_manager")
local lovelyToasts = require("lib.lovely-toasts.lovelyToasts")

local SOCGame = {}
SOCGame.__index = SOCGame

function SOCGame.new(eventBus)
    local self = setmetatable({}, SOCGame)
    self.eventBus = eventBus
    self.systems = {}
    self.sceneManager = nil
    self.luis = nil
    self.statsOverlay = nil
    self.overlayManager = nil
    self.toasts = lovelyToasts
    self.isInitialized = false
    self.isGameStarted = false
    self.socOperations = {
        operationalLevel = "STARTING",
        totalThreatsHandled = 0,
        totalIncidentsResolved = 0,
        uptime = 0
    }
    return self
end

function SOCGame:initialize()
    if self.isInitialized then return false end
    self.isInitialized = true

    print("🛡️ Initializing SOC Game Systems...")
    
    local initLuis = require("luis.init")
    self.luis = initLuis("lib/luis/widgets")
    self.luis.flux = require("luis.3rdparty.flux")
    print("🎨 LUIS initialized.")
    
    self.systems.gameStateEngine = GameStateEngine.new(self.eventBus)
    self.systems.dataManager = DataManager.new(self.eventBus)
    self.systems.dataManager:loadAllData()
    self.systems.resourceManager = ResourceManager.new(self.eventBus)
    self.systems.inputSystem = InputSystem.new(self.eventBus)
    self.systems.particleSystem = ParticleSystem.new(self.eventBus)
    self.systems.Incident = IncidentSpecialistSystem.new(self.eventBus, self.systems.resourceManager)
    self.systems.skillSystem = SkillSystem.new(self.eventBus, self.systems.dataManager)
    self.systems.upgradeSystem = UpgradeSystem.new(self.eventBus, self.systems.dataManager)
    self.systems.specialistSystem = SpecialistSystem.new(self.eventBus, self.systems.dataManager, self.systems.skillSystem)
    self.systems.clickRewardSystem = ClickRewardSystem.new(self.eventBus, self.systems.resourceManager, self.systems.upgradeSystem, self.systems.specialistSystem)
    self.systems.contractSystem = ContractSystem.new(self.eventBus, self.systems.dataManager, self.systems.upgradeSystem, self.systems.specialistSystem, nil, nil, self.systems.resourceManager)
    self.systems.eventSystem = EventSystem.new(self.eventBus, self.systems.dataManager, self.systems.resourceManager)
    self.systems.threatSystem = ThreatSystem.new(self.eventBus, self.systems.dataManager, self.systems.specialistSystem, self.systems.skillSystem)
    self.systems.idleSystem = IdleSystem.new(self.eventBus, self.systems.resourceManager, self.systems.threatSystem, self.systems.upgradeSystem)
    self.systems.achievementSystem = AchievementSystem.new(self.eventBus, self.systems.dataManager, self.systems.resourceManager)

    self.systems.gameStateEngine:registerSystem("resourceManager", self.systems.resourceManager)
    self.systems.gameStateEngine:registerSystem("skillSystem", self.systems.skillSystem)
    self.systems.gameStateEngine:registerSystem("upgradeSystem", self.systems.upgradeSystem)
    self.systems.gameStateEngine:registerSystem("specialistSystem", self.systems.specialistSystem)
    self.systems.gameStateEngine:registerSystem("contractSystem", self.systems.contractSystem)
    self.systems.gameStateEngine:registerSystem("threatSystem", self.systems.threatSystem)
    self.systems.gameStateEngine:registerSystem("idleSystem", self.systems.idleSystem)
    self.systems.gameStateEngine:registerSystem("Incident", self.systems.Incident)
    self.systems.gameStateEngine:registerSystem("achievementSystem", self.systems.achievementSystem)
    
    if self.systems.gameStateEngine:loadState() then
        print("📂 Loaded game state from previous session")
    else
        print("🎮 Starting new game (no save found)")
    end

    self.sceneManager = SceneManager.new(self.eventBus, self.systems)
    self.sceneManager:initialize()

    self.eventBus:subscribe("show_modal", function(data)
        self.sceneManager:pushScene("modal_dialog", data)
    end)
    
    -- Start game when entering soc_view (main gameplay scene)
    self.eventBus:subscribe("request_scene_change", function(data)
        if data and data.scene == "soc_view" and not self.isGameStarted then
            print("🎮 Starting game systems (entering soc_view)...")
            self._pendingStart = true
        end
    end)

    self.systems.contractSystem:initialize()
    self.systems.specialistSystem:initialize()
    self.systems.eventSystem:initialize()
    if self.systems.Incident and self.systems.Incident.initialize then
        self.systems.Incident:initialize()
    end

    self.sceneManager:registerScene("main_menu", MainMenuLuis.new(self.eventBus, self.luis, self.systems))
    self.sceneManager:registerScene("soc_view", SOCViewLuis.new(self.eventBus, self.luis, self.systems))
    self.sceneManager:registerScene("upgrade_shop", UpgradeShopLuis.new(self.eventBus, self.luis, self.systems))
    self.sceneManager:registerScene("skill_tree", SkillTreeScene.new(self.eventBus, self.luis, self.systems))
    self.sceneManager:registerScene("contracts_board", ContractsBoardScene.new(self.eventBus, self.luis, self.systems))
    self.sceneManager:registerScene("specialist_management", SpecialistManagementScene.new(self.eventBus, self.luis, self.systems))
    self.sceneManager:registerScene("modal_dialog", ModalDialog.new(self.eventBus, self.luis, self.sceneManager))
    self.sceneManager:registerScene("game_over", GameOverLuis.new(self.eventBus, self.luis, self.systems))
    self.sceneManager:registerScene("incident_response", IncidentResponseLuis.new(self.eventBus, self.luis, self.systems))
    self.sceneManager:registerScene("admin_mode", AdminModeLuis.new(self.eventBus, self.luis, self.systems))
    self.sceneManager:registerScene("incident_admin_luis", AdminIncidentScene.new(self.eventBus, self.luis, self.systems))
    self.sceneManager:registerScene("IdleDebugScene", IdleDebugScene.new(self.eventBus, self.luis, self.systems))
    
    self.sceneManager:finalizeScenes("main_menu")
    
    self.statsOverlay = StatsOverlayLuis.new(self.eventBus, self.systems, self.luis)
    self.overlayManager = OverlayManager.new()
    self.overlayManager:push(self.statsOverlay)
    
    -- Configure toast notifications
    self.toasts.canvasSize = {love.graphics.getWidth(), love.graphics.getHeight()}
    
    -- Subscribe to game events for notifications
    self:setupNotifications()

    print("✅ SOC Game Systems Initialized!")
    return true
end

function SOCGame:setupNotifications()
    -- Offline earnings display
    self.eventBus:subscribe("offline_earnings_calculated", function(data)
        local timeAway = data.idleTime or 0
        local minutes = math.floor(timeAway / 60)
        local hours = math.floor(minutes / 60)
        minutes = minutes % 60
        
        local timeStr = ""
        if hours > 0 then
            timeStr = string.format("%dh %dm", hours, minutes)
        else
            timeStr = string.format("%dm", minutes)
        end
        
        if data.netGain > 0 then
            local message = string.format("💤 Welcome back! You earned $%d while away (%s)", 
                math.floor(data.netGain), timeStr)
            self.toasts.show(message, 5.0, "middle")
        elseif data.netGain < 0 then
            local message = string.format("💤 While away (%s): $%d income, $%d losses = $%d net", 
                timeStr, 
                math.floor(data.earnings), 
                math.floor(data.damage), 
                math.floor(data.netGain))
            self.toasts.show(message, 6.0, "middle")
        end
    end)
    
    -- Threat notifications
    self.eventBus:subscribe("threat_detected", function(data)
        local threat = data.threat
        local message = string.format("🚨 Threat Detected: %s", threat.name or "Unknown Threat")
        self.toasts.show(message, 3.0, "top")
    end)
    
    self.eventBus:subscribe("threat_resolved", function(data)
        local threat = data.threat
        if data.status == "success" then
            local message = string.format("✅ Threat Resolved: %s", threat.name or "Threat")
            self.toasts.show(message, 2.5, "top")
        else
            local message = string.format("⚠️ Threat Failed: %s", threat.name or "Threat")
            self.toasts.show(message, 3.0, "top")
        end
    end)
    
    -- Contract notifications
    self.eventBus:subscribe("contract_accepted", function(data)
        local message = "📋 Contract Accepted"
        self.toasts.show(message, 2.0, "top")
    end)
    
    self.eventBus:subscribe("contract_completed", function(data)
        local message = "✅ Contract Completed!"
        self.toasts.show(message, 2.5, "top")
    end)
    
    -- Specialist notifications
    self.eventBus:subscribe("specialist_hired", function(data)
        local message = "👥 New Specialist Hired!"
        self.toasts.show(message, 2.0, "top")
    end)
    
    self.eventBus:subscribe("specialist_level_up", function(data)
        local message = string.format("⭐ %s leveled up to %d!", data.name or "Specialist", data.newLevel or 0)
        self.toasts.show(message, 3.0, "top")
    end)
    
    -- Achievement notifications
    self.eventBus:subscribe("achievement_unlocked", function(data)
        local achievement = data.achievement
        local message = string.format("🏆 Achievement: %s", achievement.name or "Unlocked!")
        self.toasts.show(message, 4.0, "top")
    end)
    
    -- Event notifications
    self.eventBus:subscribe("dynamic_event_triggered", function(data)
        local event = data.event
        if event.title then
            local message = string.format("🎲 %s", event.title)
            self.toasts.show(message, 3.0, "top")
        end
    end)
end

function SOCGame:update(dt)
    if not self.sceneManager then return end
    self.luis.flux.update(dt)
    self.luis.update(dt)
    self.sceneManager:update(dt)
    if self.overlayManager then self.overlayManager:update(dt) end
    if self.toasts then self.toasts.update(dt) end
    
    -- Update game state engine (for auto-save)
    if self.systems.gameStateEngine then self.systems.gameStateEngine:update(dt) end
    
    -- Update individual gameplay systems
    if not self.isGameStarted then
        if self._pendingStart then
            self._pendingStart = nil
            self:startGame()
        end
        return
    end
    
    -- Update all core gameplay systems
    if self.systems.contractSystem then self.systems.contractSystem:update(dt) end
    if self.systems.threatSystem then self.systems.threatSystem:update(dt) end
    if self.systems.eventSystem then self.systems.eventSystem:update(dt) end
    if self.systems.specialistSystem then self.systems.specialistSystem:update(dt) end
    if self.systems.achievementSystem then self.systems.achievementSystem:update(dt) end
    if self.systems.Incident then self.systems.Incident:update(dt) end
end

function SOCGame:draw()
    if self.sceneManager then self.sceneManager:draw() end
    if self.luis then self.luis.draw() end
    if self.systems.particleSystem then self.systems.particleSystem:draw() end
    if self.overlayManager then self.overlayManager:draw() end
    if self.toasts then self.toasts.draw() end
end

function SOCGame:startGame()
    self.isGameStarted = true
    print("🚀 SOCGame: Game started!")
    
    -- Calculate offline earnings
    if self.systems.gameStateEngine then 
        self.systems.gameStateEngine:calculateOfflineEarnings() 
    end
    
    -- Show welcome message for new players
    if self.toasts and self.systems.gameStateEngine then
        local hasExistingSave = self.systems.gameStateEngine:saveExists()
        if not hasExistingSave then
            -- New game - show welcome tutorial
            self.toasts.show("🛡️ Welcome to SOC Command Center!", 4.0, "middle")
            -- Schedule subsequent hints
            self.eventBus:publish("show_tutorial_hint", {step = 1})
        else
            -- Returning player
            self.toasts.show("🛡️ Welcome back, Commander!", 2.5, "top")
        end
    end
end

function SOCGame:keypressed(key, scancode, isrepeat)
    if key == "f1" then
        self.eventBus:publish("show_tutorial_hint", {step = 0})
        return
    end
    -- Need to switch to the debug overlay scene when F3 is pressed
    if key == "f3" then
        self.eventBus:publish("request_scene_change", "idle_debug")
        return
    end
    if self.sceneManager then
        local handled = self.sceneManager:keypressed(key, scancode, isrepeat)
        if handled then
            return
        end
    end
    if self.luis then
        local handled = self.luis.keypressed(key, scancode, isrepeat)
        if handled then
            return
        end
    end
end

function SOCGame:mousepressed(x, y, button, istouch, presses)
    if self.luis then
        local handled = self.luis.mousepressed(x, y, button, istouch, presses)
        if handled then
            return
        end
    end
    if self.sceneManager then
        self.sceneManager:mousepressed(x, y, button, istouch, presses)
    end
end

-- Stripped down input handlers for brevity
function SOCGame:keyreleased(key) end
function SOCGame:mousereleased(x, y, button, istouch, presses) end
function SOCGame:mousemoved(x, y, dx, dy) end
function SOCGame:wheelmoved(x, y) end
function SOCGame:resize(w, h) end
function SOCGame:shutdown()
    print("🛡️ Shutting down SOC game...")
    if self.systems.gameStateEngine then self.systems.gameStateEngine:quickSave() end
end

return SOCGame
