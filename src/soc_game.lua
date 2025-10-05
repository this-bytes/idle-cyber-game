-- SOCGame - Security Operations Center Game Controller
-- This file now focuses on managing the core game loop and state,
-- while main.lua handles the initial setup and object creation.

-- Core Dependencies
local EventBus = require("src.utils.event_bus")
local SystemRegistry = require("src.systems.system_registry")
local GameStateEngine = require("src.systems.game_state_engine")

-- Legacy systems that still need manual loading (not following *_system.lua pattern)
local SceneManager = require("src.scenes.scenery_adapter")
local InputSystem = require("src.systems.input_system")
local ParticleSystem = require("src.systems.particle_system")
local IncidentSpecialistSystem = require("src.systems.incident_specialist_system")
local EventSystem = require("src.systems.event_system")

-- Scene Dependencies
local MainMenuLuis = require("src.scenes.main_menu_luis")
local SOCViewLuis = require("src.scenes.soc_view_luis")
local UpgradeShopLuis = require("src.scenes.upgrade_shop_luis")
local SkillTreeScene = require("src.scenes.skill_tree_luis")
local ContractsBoardScene = require("src.scenes.contracts_board_luis")
local SpecialistManagementScene = require("src.scenes.specialist_management_luis")
local ModalDialog = require("src.scenes.modal_dialog_luis")
local GameOverLuis = require("src.scenes.game_over_luis")
local IncidentResponseLuis = require("src.scenes.incident_response_luis")
local AdminModeLuis = require("src.scenes.admin_mode_luis")
local AdminIncidentScene = require("src.scenes.incident_admin_luis")
local AdminModeEnhanced = require("src.scenes.admin_mode_enhanced_luis")
local IdleDebugScene = require("src.scenes.idle_debug")
local SOCJoker = require("src.scenes.soc_joker")

-- UI Components
local StatsOverlayLuis = require("src.ui.stats_overlay_luis")
local OverlayManager = require("src.ui.overlay_manager")

local SOCGame = {}
SOCGame.__index = SOCGame

function SOCGame.new(eventBus)
    local self = setmetatable({}, SOCGame)
    self.eventBus = eventBus
    self.systems = {}
    self.systemRegistry = nil
    self.sceneManager = nil
    self.luis = nil
    self.statsOverlay = nil
    self.overlayManager = nil
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
    
    -- Initialize LUIS UI framework
    local initLuis = require("luis.init")
    self.luis = initLuis("lib/luis/widgets")
    self.luis.flux = require("luis.3rdparty.flux")
    print("🎨 LUIS initialized.")
    
    -- Initialize GameStateEngine (special case - needs to be first)
    local gameStateEngine = GameStateEngine.new(self.eventBus)
    self.systems.gameStateEngine = gameStateEngine
    
    -- 🤖 AUTOMATIC SYSTEM INITIALIZATION
    -- SystemRegistry handles discovery, dependency injection, and initialization
    self.systemRegistry = SystemRegistry.new(self.eventBus)
    local autoSystems = self.systemRegistry:autoInitialize(gameStateEngine)
    
    -- Merge auto-discovered systems into self.systems table
    for name, instance in pairs(autoSystems) do
        local key = name:sub(1, 1):lower() .. name:sub(2) -- Convert to camelCase
        self.systems[key] = instance
    end
    
    -- Initialize legacy systems that don't follow naming convention
    self.systems.inputSystem = InputSystem.new(self.eventBus)
    self.systems.particleSystem = ParticleSystem.new(self.eventBus)
    self.systems.eventSystem = EventSystem.new(self.eventBus, self.systems.dataManager, self.systems.resourceManager)
    self.systems.Incident = IncidentSpecialistSystem.new(self.eventBus, self.systems.resourceManager)
    
    -- Connect incident system to other systems for SLA integration
    if self.systems.Incident and self.systems.contractSystem then
        if self.systems.Incident.setContractSystem then
            self.systems.Incident:setContractSystem(self.systems.contractSystem)
        end
        if self.systems.Incident.setSpecialistSystem then
            self.systems.Incident:setSpecialistSystem(self.systems.specialistSystem)
        end
    end
    
    -- Initialize event system
    if self.systems.eventSystem and self.systems.eventSystem.initialize then
        self.systems.eventSystem:initialize()
    end
    
    -- Initialize incident system  
    if self.systems.Incident and self.systems.Incident.initialize then
        self.systems.Incident:initialize()
    end
    
    -- Load saved game state
    if gameStateEngine:loadState() then
        print("📂 Loaded game state from previous session")
    else
        print("🎮 Starting new game (no save found)")
    end

    -- Initialize Scene Manager
    self.sceneManager = SceneManager.new(self.eventBus, self.systems)
    self.sceneManager:initialize()

    -- Subscribe to modal dialog events
    self.eventBus:subscribe("show_modal", function(data)
        self.sceneManager:pushScene("modal_dialog", data)
    end)

    -- Register all scenes
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
    self.sceneManager:registerScene("admin_mode_enhanced", AdminModeEnhanced.new(self.eventBus, self.luis, self.systems))
    self.sceneManager:registerScene("incident_admin_luis", AdminIncidentScene.new(self.eventBus, self.luis, self.systems))
    self.sceneManager:registerScene("soc_joker", SOCJoker.new(self.eventBus, self.luis, self.systems))
    
    self.sceneManager:finalizeScenes("main_menu")
    
    -- Initialize UI overlays
    self.statsOverlay = StatsOverlayLuis.new(self.eventBus, self.systems, self.luis)
    self.overlayManager = OverlayManager.new()
    self.overlayManager:push(self.statsOverlay)

    print("✅ SOC Game Systems Initialized!")
    return true
end

function SOCGame:update(dt)
    if not self.sceneManager then return end
    self.luis.flux.update(dt)
    self.luis.update(dt)
    self.sceneManager:update(dt)
    if self.overlayManager then self.overlayManager:update(dt) end
    if self.systems.gameStateEngine then self.systems.gameStateEngine:update(dt) end
    if self.systems.globalStatsSystem then self.systems.globalStatsSystem:update(dt) end
    if not self.isGameStarted then
        if self._pendingStart then
            self._pendingStart = nil
            self:startGame()
        end
        return
    end
end

function SOCGame:draw()
    if self.sceneManager then self.sceneManager:draw() end
    if self.luis then self.luis.draw() end
    if self.systems.particleSystem then self.systems.particleSystem:draw() end
    if self.overlayManager then self.overlayManager:draw() end
end

function SOCGame:startGame()
    self.isGameStarted = true
    print("🚀 SOCGame: Game started!")
    if self.systems.gameStateEngine then self.systems.gameStateEngine:calculateOfflineEarnings() end
end

function SOCGame:keypressed(key, scancode, isrepeat)
    -- F3 toggles debug overlay (highest priority - works on any scene)
    if key == 'f3' and self.statsOverlay then
        self.statsOverlay:toggle()
        return
    end
    
    -- Route to overlayManager first (modal overlays block other input)
    if self.overlayManager and self.overlayManager:keypressed(key) then return end
    
    -- Then to scene manager
    if self.sceneManager and self.sceneManager:keypressed(key, scancode, isrepeat) then return end
    
    -- Finally to LUIS
    if self.luis and self.luis.keypressed(key, scancode, isrepeat) then return end
end

function SOCGame:mousepressed(x, y, button, istouch, presses)
    if self.luis and self.luis.mousepressed(x, y, button, istouch, presses) then return end
    if self.sceneManager then self.sceneManager:mousepressed(x, y, button, istouch, presses) end
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
