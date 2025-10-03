-- Scenery Adapter
-- Provides backward-compatible SceneManager API wrapping Scenery library
-- Allows gradual migration from custom SceneManager to community Scenery

local SceneryInit = require("lib.scenery.scenery")

local SceneryAdapter = {}
SceneryAdapter.__index = SceneryAdapter

--- Creates a new SceneryAdapter instance.
-- @param eventBus The event system for communication.
-- @param systems A table of global systems to inject into scenes.
function SceneryAdapter.new(eventBus, systems)
    local self = setmetatable({}, SceneryAdapter)
    
    self.eventBus = eventBus
    self.systems = systems
    self.scenes = {}
    self.currentSceneName = nil
    self.scenery = nil -- Will be initialized after scenes are registered
    
    print("🎬 Scenery Adapter: Initialized")
    
    return self
end

--- Initializes the SceneryAdapter, setting up event subscriptions.
function SceneryAdapter:initialize()
    -- Subscribe to scene request events (backward compatibility)
    if self.eventBus then
        self.eventBus:subscribe("request_scene_change", function(data)
            if data and data.scene then
                self:requestScene(data.scene, data.data)
            end
        end)
        
        -- Backwards-compatible alias
        self.eventBus:subscribe("scene_request", function(data)
            if data and data.scene then
                self:requestScene(data.scene, data.data)
            end
        end)
    end
    
    print("🎬 Scenery Adapter: Event subscriptions active")
end

--- Registers a new scene with the adapter.
-- @param name The unique name of the scene (string).
-- @param scene The scene object (must have callbacks).
function SceneryAdapter:registerScene(name, scene)
    if not name or type(name) ~= "string" or not scene or type(scene) ~= "table" then
        print("Error: Invalid scene registration. Name must be a string and scene must be a table.")
        return
    end
    
    -- Inject systems into the scene
    scene.systems = self.systems
    scene.eventBus = self.eventBus
    
    -- Add setScene helper to scene for easy navigation
    scene.setScene = function(targetScene, params)
        self:requestScene(targetScene, params)
    end
    
    -- Convert old 'enter' callback to Scenery's 'load' callback
    if scene.enter and not scene.load then
        scene.load = function(sceneInstance, params)
            -- Defensive: clear input state before entering
            if scene.uiManager and scene.uiManager.root and scene.uiManager.root.clearInputState then
                scene.uiManager.root:clearInputState()
            end
            
            scene:enter(params)
            
            -- Publish scene changed event
            if self.eventBus and self.eventBus.publish then
                self.eventBus:publish("scene_changed", {scene = name})
            end
        end
    elseif scene.load then
        -- Wrap existing load to add event publishing
        local originalLoad = scene.load
        scene.load = function(sceneInstance, params)
            originalLoad(sceneInstance, params)
            
            if self.eventBus and self.eventBus.publish then
                self.eventBus:publish("scene_changed", {scene = name})
            end
        end
    end
    
    -- Wrap exit callback to clear input state
    if scene.exit then
        local originalExit = scene.exit
        scene.exit = function(sceneInstance)
            -- Defensive: clear input state before exiting
            if scene.uiManager and scene.uiManager.root and scene.uiManager.root.clearInputState then
                scene.uiManager.root:clearInputState()
            end
            
            originalExit(sceneInstance)
        end
    end
    
    self.scenes[name] = scene
    print("Registered scene: " .. name)
end

--- Finalizes scene registration and initializes Scenery with all scenes.
-- Must be called after all scenes are registered.
-- @param defaultSceneName The name of the default scene to load.
function SceneryAdapter:finalizeScenes(defaultSceneName)
    if not defaultSceneName or not self.scenes[defaultSceneName] then
        print("Error: Invalid default scene specified: " .. tostring(defaultSceneName))
        return
    end
    
    -- Build scene table for Scenery initialization
    local sceneTable = {}
    for name, scene in pairs(self.scenes) do
        table.insert(sceneTable, {
            path = scene, -- Scenery accepts table directly
            key = name,
            default = (name == defaultSceneName)
        })
    end
    
    -- Initialize Scenery with manual loading
    self.scenery = SceneryInit(table.unpack(sceneTable))
    self.currentSceneName = defaultSceneName
    
    -- Hook Scenery into Love2D callbacks (will be called by SOCGame)
    print("🎬 Scenery Adapter: Finalized with " .. #sceneTable .. " scenes, default: " .. defaultSceneName)
end

--- Requests a transition to a new scene.
-- @param sceneName The name of the scene to switch to.
-- @param params Optional parameters to pass to the new scene's 'load' function.
function SceneryAdapter:requestScene(sceneName, params)
    if not self.scenes[sceneName] then
        print("Error: Scene '" .. sceneName .. "' not found.")
        return
    end
    
    if not self.scenery then
        print("Error: Scenery not initialized. Call finalizeScenes() first.")
        return
    end
    
    -- Use Scenery's setScene method
    -- Note: Scenery internally calls setScene on the scene table
    local scene = self.scenes[sceneName]
    if scene and scene.setScene then
        scene.setScene(sceneName, params)
    else
        print("Error: Scene '" .. sceneName .. "' does not have setScene method")
    end
    
    self.currentSceneName = sceneName
end

--- Get the current active scene name.
-- @return The name of the current scene.
function SceneryAdapter:getCurrentSceneName()
    return self.currentSceneName
end

--- Get the current active scene object.
-- @return The current scene table.
function SceneryAdapter:getCurrentScene()
    return self.scenes[self.currentSceneName]
end

-- Love2D callback delegations (called by SOCGame)

function SceneryAdapter:load()
    if self.scenery then
        self.scenery:load()
    end
end

function SceneryAdapter:update(dt)
    if self.scenery then
        self.scenery:update(dt)
    end
end

function SceneryAdapter:draw()
    if self.scenery then
        self.scenery:draw()
    end
end

function SceneryAdapter:mousepressed(x, y, button, istouch, presses)
    if self.scenery then
        self.scenery:mousepressed(x, y, button, istouch, presses)
    end
end

function SceneryAdapter:mousereleased(x, y, button, istouch, presses)
    if self.scenery then
        self.scenery:mousereleased(x, y, button, istouch, presses)
    end
end

function SceneryAdapter:mousemoved(x, y, dx, dy, istouch)
    if self.scenery then
        self.scenery:mousemoved(x, y, dx, dy, istouch)
    end
end

function SceneryAdapter:wheelmoved(x, y)
    if self.scenery then
        self.scenery:wheelmoved(x, y)
    end
end

function SceneryAdapter:keypressed(key, scancode, isrepeat)
    if self.scenery then
        self.scenery:keypressed(key, scancode, isrepeat)
    end
end

function SceneryAdapter:keyreleased(key, scancode)
    if self.scenery then
        self.scenery:keyreleased(key, scancode)
    end
end

function SceneryAdapter:textinput(text)
    if self.scenery then
        self.scenery:textinput(text)
    end
end

function SceneryAdapter:resize(w, h)
    if self.scenery then
        self.scenery:resize(w, h)
    end
end

function SceneryAdapter:focus(focused)
    if self.scenery then
        self.scenery:focus(focused)
    end
end

function SceneryAdapter:quit()
    if self.scenery then
        return self.scenery:quit()
    end
    return false
end

return SceneryAdapter
