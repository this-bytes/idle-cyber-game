-- SOCGame - Security Operations Center Game Controller
-- This file now focuses on managing the core game loop and state,
-- while main.lua handles the initial setup and object creation.

-- System Dependencies
local EventBus = require("src.utils.event_bus") -- 
local DataManager = require("src.systems.data_manager")
local ResourceManager = require("src.systems.resource_manager")
local SceneManager = require("src.scenes.scenery_adapter") -- Using Scenery adapter for scene management
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
local MainMenuLuis = require("src.scenes.main_menu_luis") -- Pure LUIS implementation
local SOCView = require("src.scenes.soc_view")
local UpgradeShop = require("src.scenes.upgrade_shop")
local GameOver = require("src.scenes.game_over")
local IncidentResponse = require("src.scenes.incident_response")
local AdminMode = require("src.modes.admin_mode")
local IdleDebugScene = require("src.scenes.idle_debug")

-- UI Components
-- LUIS (Love UI System) - loaded directly, no wrapper
local StatsOverlay = require("src.ui.stats_overlay")
local OverlayManager = require("src.ui.overlay_manager")


local SOCGame = {}
SOCGame.__index = SOCGame

function SOCGame.new(eventBus)
    local self = setmetatable({}, SOCGame)
    self.eventBus = eventBus
    self.systems = {}
    self.sceneManager = nil
    self.luis = nil -- LUIS (Love UI System) instance
    self.statsOverlay = nil
    self.overlayManager = nil
    self.isInitialized = false
    self.isGameStarted = false -- Track if player has started the game
    -- Backwards-compatible fields used by older tests
    self.initialized = false
    self.socOperations = {
        operationalLevel = "STARTING",
        totalThreatsHandled = 0,
        totalIncidentsResolved = 0,
        uptime = 0
    }
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
    
    -- 0. Initialize LUIS (Love UI System) directly - no wrapper
    local initLuis = require("luis.init")
    self.luis = initLuis("lib/luis/widgets")
    
    -- Configure LUIS defaults
    self.luis.showGrid = false
    self.luis.showLayerNames = false
    self.luis.showElementOutlines = false
    
    -- Register flux for animations
    self.luis.flux = require("luis.3rdparty.flux")
    
    print("🎨 LUIS initialized with grid size: " .. self.luis.gridSize)
    
    -- 1. Create Game State Engine (manages all state)
    self.systems.gameStateEngine = GameStateEngine.new(self.eventBus)
    
    -- 2. Create Core Systems & Data Manager
    self.systems.dataManager = DataManager.new(self.eventBus)
    self.systems.dataManager:loadAllData()
    
    -- 3. Create ResourceManager
    self.systems.resourceManager = ResourceManager.new(self.eventBus)

    -- 4. Create Input System (clickRewardSystem depends on upgrade/specialist systems so it's created later)
    self.systems.inputSystem = InputSystem.new(self.eventBus)
    self.systems.particleSystem = ParticleSystem.new(self.eventBus)

    -- 4.1 Create Incident / Specialist system (canonical incident implementation)
    -- This consolidates incident logic into a single system (see ARCHITECTURE.md)
    self.systems.Incident = IncidentSpecialistSystem.new(self.eventBus, self.systems.resourceManager)

    -- 5. Create other systems
    self.systems.skillSystem = SkillSystem.new(self.eventBus, self.systems.dataManager)
    self.systems.upgradeSystem = UpgradeSystem.new(self.eventBus, self.systems.dataManager)
    self.systems.specialistSystem = SpecialistSystem.new(self.eventBus, self.systems.dataManager, self.systems.skillSystem)
    -- Create Click Reward System after upgrade and specialist systems are available
    self.systems.clickRewardSystem = ClickRewardSystem.new(self.eventBus, self.systems.resourceManager, self.systems.upgradeSystem, self.systems.specialistSystem)
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
    self.systems.gameStateEngine:registerSystem("Incident", self.systems.Incident)
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
    -- Initialize scene manager subscriptions immediately so it handles scene
    -- change requests before other subscribers (avoids heavy work blocking the
    -- visual transition). This ensures the scene switch happens first and the
    -- new scene can render while any subsequent listeners run.
    self.sceneManager:initialize()

    -- Subscribe to game start events (after sceneManager has registered its
    -- listener). This ordering makes sure the visual transition occurs before
    -- potentially expensive startup work in startGame.
    -- Legacy event name
    self.eventBus:subscribe("scene_request", function(data)
        if data and data.scene == "soc_view" and not self.isGameStarted then
            -- Defer heavy startGame work to the next update tick to allow the
            -- scene transition to render and process any outstanding input
            -- events (prevents stuck input states in interactive flows).
            self._pendingStart = true
        end
    end)
    -- Preferred event name
    self.eventBus:subscribe("request_scene_change", function(data)
        if data and data.scene == "soc_view" and not self.isGameStarted then
            self._pendingStart = true
        end
    end)

    -- 9. Initialize Systems (that need it)
    self.systems.contractSystem:initialize()
    self.systems.specialistSystem:initialize()
    self.systems.eventSystem:initialize()
    -- Initialize canonical Incident system
    if self.systems.Incident and self.systems.Incident.initialize then
        self.systems.Incident:initialize()
    end
    -- self.systems.threatSystem:initialize() -- Disabled to prevent conflict with incident_specialist_system
    self.sceneManager:initialize()

    -- 10. Register Scenes
    -- Use LUIS-based Main Menu (pure LUIS implementation)
    self.sceneManager:registerScene("main_menu", MainMenuLuis.new(self.eventBus, self.luis))
    self.sceneManager:registerScene("soc_view", SOCView.new(self.eventBus))
    self.sceneManager:registerScene("upgrade_shop", UpgradeShop.new(self.eventBus))
    self.sceneManager:registerScene("game_over", GameOver.new(self.eventBus))
    self.sceneManager:registerScene("incident_response", IncidentResponse.new(self.eventBus))
    self.sceneManager:registerScene("admin_mode", AdminMode.new())
    -- Register developer-only debug scene only when explicitly enabled via env var
    local enableIdleDebug = false
    local envVal = os.getenv("IDLE_DEBUG_SCENE")
    if envVal and (envVal == "1" or envVal:lower() == "true") then
        enableIdleDebug = true
    end
    if enableIdleDebug then
        self.sceneManager:registerScene("idle_debug", IdleDebugScene.new(self.eventBus))
        print("🔧 Idle Debug Scene registered (developer mode)")
    else
        -- For safety, do not expose the full idle debug scene in normal builds; use overlay instead
        print("🔧 Idle Debug Scene not registered (set IDLE_DEBUG_SCENE=1 to enable)")
    end
    
    -- 10.5. Finalize scene registration with SceneryAdapter (new requirement)
    self.sceneManager:finalizeScenes("main_menu")
    
    -- 11. Start Initial Scene (Main Menu) - now handled by finalizeScenes
    -- self.sceneManager:requestScene("main_menu") -- Commented out - finalizeScenes does this
    
    -- 12. Initialize Stats Overlay (player-facing, overlays on top of any scene)
    self.statsOverlay = StatsOverlay.new(self.eventBus, self.systems)

    -- Create overlay manager and register the stats overlay so it can
    -- capture input when visible. We push the overlay but it will only be
    -- visible when toggled (StatsOverlay.visible).
    self.overlayManager = OverlayManager.new()
    self.overlayManager:push(self.statsOverlay)
    print("🔎 Stats Overlay registered with OverlayManager (Toggle with F3)")

    print("✅ SOC Game Systems Initialized!")
    return true
end

function SOCGame:update(dt)
    if not self.sceneManager then
        return
    end
    
    -- Update LUIS (handles animations via flux)
    if self.luis then
        self.luis.flux.update(dt)
        self.luis.update(dt)
    end
    
    -- Update scene manager (always active for menus)
    self.sceneManager:update(dt)
    
    -- Update overlay manager (which updates the stats overlay and any other overlays)
    if self.overlayManager then
        self.overlayManager:update(dt)
    elseif self.statsOverlay then
        -- Backwards-compatible fallback
        self.statsOverlay:update(dt)
    end
    
    -- Update GameStateEngine (handles auto-save and state tracking)
    if self.systems.gameStateEngine then
        self.systems.gameStateEngine:update(dt)
    end
    
    -- Only update game systems after game has started
    -- If a start was requested in the previous frame, run it now so that the
    -- scene transition can finish rendering and input can flush through.
    if not self.isGameStarted then
        if self._pendingStart then
            self._pendingStart = nil
            -- Defensive: clear any lingering input states on overlays
            if self.overlayManager and self.overlayManager.clearInputState then
                self.overlayManager:clearInputState()
            end
            -- Run startGame now (will set isGameStarted)
            self:startGame()
        end
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
    -- if self.systems.threatSystem then
    --     self.systems.threatSystem:update(dt)
    -- end
    if self.systems.achievementSystem then
        self.systems.achievementSystem:update(dt)
    end
    if self.systems.eventSystem then
        self.systems.eventSystem:update(dt)
    end
end

function SOCGame:draw()
    -- Draw scenes first
    if self.sceneManager then
        self.sceneManager:draw()
    end
    
    -- Draw LUIS widgets
    if self.luis then
        self.luis.draw()
    end
    
    -- Draw particle effects on top of UI
    if self.systems.particleSystem then
        self.systems.particleSystem:draw()
    end
    
    -- Draw overlays on top of everything
    if self.overlayManager then
        self.overlayManager:draw()
    elseif self.statsOverlay then
        self.statsOverlay:draw()
    end
end

-- Backwards-compatible API used by legacy tests
function SOCGame:updateOperationalLevel()
    -- Determine new operational level based on simple heuristics
    if not self.socOperations then return end

    local threats = self.socOperations.totalThreatsHandled or 0
    local incidents = self.socOperations.totalIncidentsResolved or 0
    local combined = threats + incidents

    -- Match legacy test expectations: combined == 10 should map to BASIC
    if combined > 10 then
        self.socOperations.operationalLevel = "ADVANCED"
    elseif combined >= 5 then
        self.socOperations.operationalLevel = "BASIC"
    else
        self.socOperations.operationalLevel = "STARTING"
    end
end

function SOCGame:getSOCStats()
    return {
        threatsHandled = self.socOperations.totalThreatsHandled or 0,
        incidentsResolved = self.socOperations.totalIncidentsResolved or 0,
        operationalLevel = self.socOperations.operationalLevel,
        uptime = self.socOperations.uptime or 0
    }
end

function SOCGame:saveGame()
    if not self.saveSystem then return false end
    local data = { socOperations = self.socOperations }
    return self.saveSystem:save(data)
end

function SOCGame:initializeCore()
    -- Ensure core subsystems for tests are available
    if not self.eventBus then
        self.eventBus = require("src.utils.event_bus").new()
    end
    -- Create minimal GameStateEngine and ResourceManager if missing
    if not self.systems or not self.systems.resourceManager then
        self.systems = self.systems or {}
        local ResourceManager = require("src.systems.resource_manager")
        self.systems.resourceManager = ResourceManager.new(self.eventBus)
    end
    return true
end

function SOCGame:keypressed(key, scancode, isrepeat)
    -- Handle global stats overlay toggle (F3)
    if key == "f3" then
        if self.statsOverlay then
            self.statsOverlay:toggle()
        end
        return -- Don't pass F3 to other systems
    end
    
    -- Handle input system first (for global actions)
    if self.systems.inputSystem then
        self.systems.inputSystem:keypressed(key, scancode, isrepeat)
    end

    -- If any overlay consumes the key, stop propagation to scene manager
    if self.overlayManager and self.overlayManager:keypressed(key) then
        return
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

        -- The GameStateEngine now handles applying the progress and publishing the
        -- 'offline_earnings_calculated' event for the UI to display.
        -- The print statements for debugging are also handled within the engine or can be
        -- subscribed to via the event bus for a cleaner separation of concerns.
        -- This keeps SOCGame clean and focused on orchestration.

        -- The UI (e.g., SOCView) should listen for 'offline_earnings_calculated'
        -- and display the summary to the player.
    end
end

function SOCGame:keypressed(key, scancode, isrepeat)
    -- Toggle LUIS debug view with Tab
    if key == "tab" and self.luis then
        self.luis.showGrid = not self.luis.showGrid
        self.luis.showLayerNames = not self.luis.showLayerNames
        self.luis.showElementOutlines = not self.luis.showElementOutlines
        return
    end
    
    -- LUIS input handling
    if self.luis and self.luis.keypressed(key, scancode, isrepeat) then
        return
    end

    -- Global hotkeys via input system
    if self.systems.inputSystem then
        self.systems.inputSystem:keypressed(key, scancode, isrepeat)
    end

    -- Overlays
    if self.overlayManager and self.overlayManager:keypressed(key) then
        return
    end

    if self.sceneManager then
        self.sceneManager:keypressed(key, scancode, isrepeat)
    end
end

function SOCGame:keyreleased(key)
    -- LUIS input handling
    if self.luis and self.luis.keyreleased(key) then
        return
    end

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

    -- LUIS input handling
    if self.luis and self.luis.mousepressed(x, y, button, istouch, presses) then
        return
    end

    -- Handle input system (for global click actions)
    if self.systems.inputSystem then
        self.systems.inputSystem:mousepressed(x, y, button, istouch, presses)
    end

    -- Overlays get chance to consume input
    if self.overlayManager and self.overlayManager:mousepressed(x, y, button) then
        return
    end

    -- Finally pass to scene manager
    if self.sceneManager then
        self.sceneManager:mousepressed(x, y, button, istouch, presses)
    else
        print("[UI RAW] SOCGame:mousepressed but no sceneManager present")
    end
end

function SOCGame:mousereleased(x, y, button, istouch, presses)
    -- Log at SOCGame layer to verify release events arrive from LÖVE
    print(string.format("[UI RAW] SOCGame:mousereleased x=%.1f y=%.1f button=%s", x, y, tostring(button)))

    -- LUIS input handling
    if self.luis and self.luis.mousereleased(x, y, button, istouch, presses) then
        return
    end

    if self.systems.inputSystem then
        self.systems.inputSystem:mousereleased(x, y, button, istouch, presses)
    end

    -- Overlays get chance to consume releases
    if self.overlayManager and self.overlayManager:mousereleased(x, y, button) then
        print("[UI RAW] SOCGame:mousereleased consumed by overlay")
        return
    end

    if self.sceneManager and self.sceneManager.mousereleased then
        self.sceneManager:mousereleased(x, y, button, istouch, presses)
    else
        print("[UI RAW] SOCGame:mousereleased but no sceneManager.mousereleased handler")
    end

    -- Defensive fallback: clear any lingering input states
    if self.overlayManager and self.overlayManager.clearInputState then
        self.overlayManager:clearInputState()
    end
end

function SOCGame:mousemoved(x, y, dx, dy)
    -- LUIS doesn't have mousemoved - it handles hover internally
    
    if self.overlayManager and self.overlayManager:mousemoved(x, y, dx, dy) then
        return
    end

    if self.sceneManager and self.sceneManager.mousemoved then
        self.sceneManager:mousemoved(x, y, dx, dy)
    end
end

function SOCGame:wheelmoved(x, y)
    -- LUIS input handling
    if self.luis and self.luis.wheelmoved(x, y) then
        return
    end

    if self.overlayManager and self.overlayManager:wheelmoved(x, y) then
        return
    end

    if self.sceneManager and self.sceneManager.wheelmoved then
        self.sceneManager:wheelmoved(x, y)
    end
end

function SOCGame:resize(w, h)
    -- LUIS automatically handles resize through love.graphics dimensions
    
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
end

return SOCGame