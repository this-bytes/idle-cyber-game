-- Scenery Adapter
-- Provides backward-compatible SceneManager API wrapping Scenery library
-- This version has been upgraded to support a scene stack for overlays and modals.

local SceneryAdapter = {}
SceneryAdapter.__index = SceneryAdapter

function SceneryAdapter.new(eventBus, systems)
    local self = setmetatable({}, SceneryAdapter)
    
    self.eventBus = eventBus
    self.systems = systems
    self.scenes = {}
    self.sceneStack = {} -- The stack of active scenes.
    
    print("🎬 Scenery Adapter: Initialized with Scene Stack support.")
    return self
end

function SceneryAdapter:initialize()
    if self.eventBus then
        self.eventBus:subscribe("request_scene_change", function(data)
            self:switchScene(data.scene, data.data)
        end)
        self.eventBus:subscribe("push_scene", function(data)
            self:pushScene(data.scene, data.data)
        end)
        self.eventBus:subscribe("pop_scene", function()
            self:popScene()
        end)
    end
    print("🎬 Scenery Adapter: Event subscriptions active.")
end

function SceneryAdapter:registerScene(name, scene)
    scene.systems = self.systems
    scene.eventBus = self.eventBus
    scene.sceneManager = self -- Give scenes a reference to the manager to call push/pop
    self.scenes[name] = scene
end

function SceneryAdapter:finalizeScenes(defaultSceneName)
    self:switchScene(defaultSceneName)
    print("🎬 Scenery Adapter: Finalized with default scene: " .. defaultSceneName)
end

function SceneryAdapter:getCurrentScene()
    return self.sceneStack[#self.sceneStack]
end

-- Switches to a new scene, clearing the entire stack.
function SceneryAdapter:switchScene(sceneName, params)
    if not self.scenes[sceneName] then
        print("Error: Scene '" .. sceneName .. "' not found.")
        return
    end

    -- Exit all scenes on the stack
    while #self.sceneStack > 0 do
        self:popScene(true) -- pop without loading the underlying scene
    end

    -- Push the new scene
    table.insert(self.sceneStack, self.scenes[sceneName])
    local newScene = self:getCurrentScene()
    if newScene and newScene.load then
        newScene:load(params)
    end
end

-- Pushes a new scene onto the stack (for overlays/modals).
function SceneryAdapter:pushScene(sceneName, params)
    if not self.scenes[sceneName] then
        print("Error: Scene '" .. sceneName .. "' not found.")
        return
    end

    -- Don't exit the current scene, just push the new one on top.
    table.insert(self.sceneStack, self.scenes[sceneName])
    local newScene = self:getCurrentScene()
    if newScene and newScene.load then
        newScene:load(params)
    end
end

-- Pops the top scene from the stack.
function SceneryAdapter:popScene(isSwitching)
    if #self.sceneStack == 0 then return end

    -- Exit and remove the current top scene
    local currentScene = self:getCurrentScene()
    if currentScene and currentScene.exit then
        currentScene:exit()
    end
    table.remove(self.sceneStack)

    -- If we are not in the middle of a full switch, resume the new top scene
    if not isSwitching then
        local newTopScene = self:getCurrentScene()
        if newTopScene then
            if newTopScene.onResume then
                -- Prefer efficient state restoration
                newTopScene:onResume()
            elseif newTopScene.load then
                -- Fallback to full reload if no onResume is provided
                newTopScene:load()
            end
        end
    end
end


-- Love2D callback delegations

function SceneryAdapter:update(dt)
    local scene = self:getCurrentScene()
    if scene and scene.update then
        scene:update(dt)
    end
end

function SceneryAdapter:draw()
    -- Draw all scenes in the stack, from bottom to top.
    for i, scene in ipairs(self.sceneStack) do
        if scene and scene.draw then
            scene:draw()
        end
    end
end

function SceneryAdapter:keypressed(key, scancode, isrepeat)
    -- Input is only ever sent to the top-most scene.
    local scene = self:getCurrentScene()
    if scene and scene.keypressed then
        return scene:keypressed(key, scancode, isrepeat)
    end
end

-- Pass through all other love callbacks to the top scene
function SceneryAdapter:mousepressed(x, y, button, istouch, presses)
    local scene = self:getCurrentScene()
    if scene and scene.mousepressed then
        return scene:mousepressed(x, y, button, istouch, presses)
    end
end

function SceneryAdapter:mousereleased(x, y, button, istouch, presses)
    local scene = self:getCurrentScene()
    if scene and scene.mousereleased then
        return scene:mousereleased(x, y, button, istouch, presses)
    end
end

function SceneryAdapter:wheelmoved(x, y)
    local scene = self:getCurrentScene()
    if scene and scene.wheelmoved then
        return scene:wheelmoved(x, y)
    end
end

return SceneryAdapter