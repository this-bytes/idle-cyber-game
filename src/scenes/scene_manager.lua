-- Scene Manager - SOC-Focused Scene System
-- Manages transitions between different SOC views and states

local SceneManager = {}
SceneManager.__index = SceneManager

--- Creates a new SceneManager instance.
-- @param eventBus The event system for communication.
-- @param systems A table of global systems to inject into scenes.
function SceneManager.new(eventBus, systems)
    local self = setmetatable({}, SceneManager)
    
    self.eventBus = eventBus
    self.systems = systems
    self.scenes = {}
    self.currentScene = nil
    self.currentSceneName = nil
    
    return self
end

--- Initializes the SceneManager, primarily by setting up event subscriptions.
function SceneManager:initialize()
    -- Subscribe to scene request events
    if self.eventBus then
        -- Primary event name
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
    
    print("🎬 SceneManager: Initialized with event subscriptions.")
end

--- Registers a new scene with the manager.
-- @param name The unique name of the scene (string).
-- @param scene The scene object (must have an 'enter' and 'exit' function, 
--              and optionally 'update', 'draw', etc.).
function SceneManager:registerScene(name, scene)
    if not name or type(name) ~= "string" or not scene or type(scene) ~= "table" then
        print("Error: Invalid scene registration. Name must be a string and scene must be a table.")
        return
    end
    
    self.scenes[name] = scene
    print("Registered scene: " .. name)
end

--- Requests a transition to a new scene.
-- @param sceneName The name of the scene to switch to.
-- @param params Optional parameters to pass to the new scene's 'enter' function.
function SceneManager:requestScene(sceneName, params)
    if not self.scenes[sceneName] then
        print("Error: Scene '" .. sceneName .. "' not found.")
        return
    end
    
    -- 1. Exit current scene
    -- Defensive: clear input state on outgoing scene root to avoid carrying
    -- pressed/hovered states across scenes (helps interactive flows where
    -- heavy work during transition can prevent release events). Do this
    -- before calling exit so components have a chance to reset.
    if self.currentScene and self.currentScene.uiManager and self.currentScene.uiManager.root and self.currentScene.uiManager.root.clearInputState then
        self.currentScene.uiManager.root:clearInputState()
        print("[UI DEBUG] Cleared input state on outgoing scene root before exit")
    end

    if self.currentScene and self.currentScene.exit then
        self.currentScene:exit()
    end
    
    -- 2. Set new current scene
    self.currentSceneName = sceneName
    self.currentScene = self.scenes[sceneName]
    
    -- Inject the systems table into the scene for easy access
    self.currentScene.systems = self.systems
    
    -- 3. Enter new scene
    if self.currentScene.enter then
        self.currentScene:enter(params)
    end

    -- Notify other systems that the scene has changed (post-transition).
    if self.eventBus and self.eventBus.publish then
        self.eventBus:publish("scene_changed", { scene = sceneName })
    end

    -- Defensive: clear any lingering input state in new scene's UI root (if present)
    if self.currentScene and self.currentScene.uiManager and self.currentScene.uiManager.root and self.currentScene.uiManager.root.clearInputState then
        self.currentScene.uiManager.root:clearInputState()
        print("[UI DEBUG] Cleared input state on new scene root to avoid stuck presses")
    end

    print("Transitioned to scene: " .. sceneName)
end

--- Gets a registered scene object.
-- @param name The name of the scene.
-- @return The scene object, or nil if not found.
function SceneManager:getScene(name)
    return self.scenes[name]
end

--- Calls the current scene's 'update' function.
-- @param dt Delta time.
function SceneManager:update(dt)
    if self.currentScene and self.currentScene.update then
        self.currentScene:update(dt)
    end
end

--- Calls the current scene's 'draw' function.
function SceneManager:draw()
    if self.currentScene and self.currentScene.draw then
        self.currentScene:draw()
    end
end

--- Passes a key press event to the current scene.
-- @param key The key that was pressed.
function SceneManager:keypressed(key)
    if self.currentScene and self.currentScene.keypressed then
        self.currentScene:keypressed(key)
    end
end

--- Passes a mouse press event to the current scene.
-- @param x Mouse x-coordinate.
-- @param y Mouse y-coordinate.
-- @param button Mouse button index.
function SceneManager:mousepressed(x, y, button)
    -- Debug: report mousepressed entering SceneManager
    print(string.format("[UI DEBUG] SceneManager:mousepressed x=%.1f y=%.1f button=%s currentScene=%s", x, y, tostring(button), tostring(self.currentSceneName)))
    if self.currentScene and self.currentScene.mousepressed then
        self.currentScene:mousepressed(x, y, button)
    end
end

--- Passes a mouse release event to the current scene.
-- @param x Mouse x-coordinate.
-- @param y Mouse y-coordinate.
-- @param button Mouse button index.
function SceneManager:mousereleased(x, y, button)
    -- Debug: report mousereleased entering SceneManager
    print(string.format("[UI DEBUG] SceneManager:mousereleased x=%.1f y=%.1f button=%s currentScene=%s", x, y, tostring(button), tostring(self.currentSceneName)))
    if self.currentScene and self.currentScene.mousereleased then
        self.currentScene:mousereleased(x, y, button)
    end
end

--- Passes a mouse move event to the current scene.
-- @param x Mouse x-coordinate.
-- @param y Mouse y-coordinate.
-- @param dx Delta x.
-- @param dy Delta y.
function SceneManager:mousemoved(x, y, dx, dy)
    if self.currentScene and self.currentScene.mousemoved then
        self.currentScene:mousemoved(x, y, dx, dy)
    end
end

--- Passes a mouse wheel event to the current scene.
-- @param x Horizontal scroll amount.
-- @param y Vertical scroll amount.
function SceneManager:wheelmoved(x, y)
    if self.currentScene and self.currentScene.wheelmoved then
        self.currentScene:wheelmoved(x, y)
    end
end

--- Passes a resize event to the current scene.
-- @param w New window width.
-- @param h New window height.
function SceneManager:resize(w, h)
    if self.currentScene and self.currentScene.resize then
        self.currentScene:resize(w, h)
    end
end

return SceneManager