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
    -- Scenery's manualLoad expects: {path = scene_table, key = "name", default = bool}
    local sceneTable = {}
    for name, scene in pairs(self.scenes) do
        table.insert(sceneTable, {
            path = scene, -- Scenery's manualLoad calls require() but we pass table directly
            key = name,
            default = (name == defaultSceneName)
        })
    end
    
    -- CRITICAL FIX: Scenery expects path to be requireable string OR the actual table
    -- Since we're passing tables, we need to modify approach
    -- Instead, we'll use Scenery directly but inject setScene into each scene
    
    -- Store scenes and current scene
    self.currentSceneName = defaultSceneName
    
    -- Create setScene function for all scenes
    local setSceneFunc = function(key, data)
        if not self.scenes[key] then
            error("No such scene '" .. key .. "'")
        end
        
        -- Exit current scene
        local current = self.scenes[self.currentSceneName]
        if current and current.exit then
            current:exit()
        end
        
        -- Change scene
        self.currentSceneName = key
        local newScene = self.scenes[key]
        
        -- Enter/Load new scene
        if newScene and newScene.load then
            newScene:load(data)
        elseif newScene and newScene.enter then
            newScene:enter(data)
        end
        
        -- Publish scene change event
        if self.eventBus and self.eventBus.publish then
            self.eventBus:publish("scene_changed", {scene = key})
        end
    end
    
    -- Inject setScene into all scenes
    for name, scene in pairs(self.scenes) do
        scene.setScene = setSceneFunc
    end
    
    -- Load the default scene
    local defaultScene = self.scenes[defaultSceneName]
    print(string.format("🎬 Scenery: Loading default scene '%s'... (scene = %s, has load = %s, has enter = %s)", 
        defaultSceneName, tostring(defaultScene), tostring(defaultScene and defaultScene.load ~= nil), tostring(defaultScene and defaultScene.enter ~= nil)))
    
    if defaultScene and defaultScene.load then
        print("🎬 Scenery: Calling load() on " .. defaultSceneName)
        local success, err = pcall(function() defaultScene:load() end)
        if not success then
            print("🎬 Scenery: ERROR calling load(): " .. tostring(err))
        end
    elseif defaultScene and defaultScene.enter then
        print("🎬 Scenery: Calling enter() on " .. defaultSceneName)
        defaultScene:enter()
    else
        print("🎬 Scenery: WARNING - No load() or enter() method found for " .. defaultSceneName)
    end
    
    print("🎬 Scenery Adapter: Finalized with " .. self:getSceneCount() .. " scenes, default: " .. defaultSceneName)
end

--- Requests a transition to a new scene.
-- @param sceneName The name of the scene to switch to.
-- @param params Optional parameters to pass to the new scene's 'load' function.
function SceneryAdapter:requestScene(sceneName, params)
    if not self.scenes[sceneName] then
        print("Error: Scene '" .. sceneName .. "' not found.")
        return
    end
    
    -- Use the injected setScene function
    if self.scenes[self.currentSceneName] and self.scenes[self.currentSceneName].setScene then
        self.scenes[self.currentSceneName].setScene(sceneName, params)
    else
        print("Error: Cannot change scene - setScene not initialized. Call finalizeScenes() first.")
    end
end

--- Get the number of registered scenes
-- @return Number of scenes
function SceneryAdapter:getSceneCount()
    local count = 0
    for _ in pairs(self.scenes) do
        count = count + 1
    end
    return count
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
    -- Initial load already handled in finalizeScenes
end

function SceneryAdapter:update(dt)
    local scene = self.scenes[self.currentSceneName]
    if scene and scene.update then
        scene:update(dt)
    end
end

function SceneryAdapter:draw()
    local scene = self.scenes[self.currentSceneName]
    if scene and scene.draw then
        scene:draw()
    end
end

function SceneryAdapter:mousepressed(x, y, button, istouch, presses)
    local scene = self.scenes[self.currentSceneName]
    if scene and scene.mousepressed then
        return scene:mousepressed(x, y, button, istouch, presses)
    end
end

function SceneryAdapter:mousereleased(x, y, button, istouch, presses)
    local scene = self.scenes[self.currentSceneName]
    if scene and scene.mousereleased then
        return scene:mousereleased(x, y, button, istouch, presses)
    end
end

function SceneryAdapter:mousemoved(x, y, dx, dy, istouch)
    local scene = self.scenes[self.currentSceneName]
    if scene and scene.mousemoved then
        return scene:mousemoved(x, y, dx, dy, istouch)
    end
end

function SceneryAdapter:wheelmoved(x, y)
    local scene = self.scenes[self.currentSceneName]
    if scene and scene.wheelmoved then
        return scene:wheelmoved(x, y)
    end
end

function SceneryAdapter:keypressed(key, scancode, isrepeat)
    local scene = self.scenes[self.currentSceneName]
    if scene and scene.keypressed then
        return scene:keypressed(key, scancode, isrepeat)
    end
end

function SceneryAdapter:keyreleased(key, scancode)
    local scene = self.scenes[self.currentSceneName]
    if scene and scene.keyreleased then
        return scene:keyreleased(key, scancode)
    end
end

function SceneryAdapter:textinput(text)
    local scene = self.scenes[self.currentSceneName]
    if scene and scene.textinput then
        return scene:textinput(text)
    end
end

function SceneryAdapter:resize(w, h)
    local scene = self.scenes[self.currentSceneName]
    if scene and scene.resize then
        return scene:resize(w, h)
    end
end

function SceneryAdapter:focus(focused)
    local scene = self.scenes[self.currentSceneName]
    if scene and scene.focus then
        return scene:focus(focused)
    end
end

function SceneryAdapter:quit()
    local scene = self.scenes[self.currentSceneName]
    if scene and scene.quit then
        return scene:quit()
    end
    return false
end

return SceneryAdapter
