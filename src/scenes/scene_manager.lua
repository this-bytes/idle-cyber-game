-- Scene Manager - SOC-Focused Scene System
-- Manages transitions between different SOC views and states

local SceneManager = {}
SceneManager.__index = SceneManager

function SceneManager.new(eventBus, systems)
    local self = setmetatable({}, SceneManager)
    self.eventBus = eventBus
    self.systems = systems
    self.scenes = {}
    self.currentScene = nil
    self.currentSceneName = nil
    return self
end

function SceneManager:initialize()
    -- Subscribe to scene request events
    if self.eventBus then
        self.eventBus:subscribe("scene_request", function(data)
            if data.scene then
                self:requestScene(data.scene, data.data)
            end
        end)
    end
    
    print("🎬 SceneManager: Initialized with event subscriptions.")
end

function SceneManager:registerScene(name, scene)
    if not name or not scene then
        print("Error: Invalid scene registration.")
        return
    end
    self.scenes[name] = scene
    print("Registered scene: " .. name)
end

function SceneManager:requestScene(sceneName, params)
    if not self.scenes[sceneName] then
        print("Error: Scene '" .. sceneName .. "' not found.")
        return
    end

    if self.currentScene and self.currentScene.exit then
        self.currentScene:exit()
    end

    self.currentSceneName = sceneName
    self.currentScene = self.scenes[sceneName]
    
    -- Inject the systems table into the scene
    self.currentScene.systems = self.systems

    if self.currentScene.enter then
        self.currentScene:enter(params)
    end
end

function SceneManager:getScene(name)
    return self.scenes[name]
end

function SceneManager:update(dt)
    if self.currentScene and self.currentScene.update then
        self.currentScene:update(dt)
    end
end

function SceneManager:draw()
    if self.currentScene and self.currentScene.draw then
        self.currentScene:draw()
    end
end

function SceneManager:keypressed(key)
    if self.currentScene and self.currentScene.keypressed then
        self.currentScene:keypressed(key)
    end
end

function SceneManager:mousepressed(x, y, button)
    if self.currentScene and self.currentScene.mousepressed then
        self.currentScene:mousepressed(x, y, button)
    end
end

function SceneManager:resize(w, h)
    if self.currentScene and self.currentScene.resize then
        self.currentScene:resize(w, h)
    end
end

return SceneManager