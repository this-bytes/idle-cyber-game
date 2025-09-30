-- Scene Manager - SOC-Focused Scene System
-- Manages transitions between different SOC views and states
-- Implements clean separation between main menu, SOC view, upgrade shop, and game over states

-- NOTE:
-- Preferred scene module pattern: modules should return an instantiated scene table (i.e. call `return MyScene.new()`)
-- This keeps scene exports unambiguous and simplifies testing. SceneManager still supports class-style
-- modules that expose a `new()` constructor and will attempt to construct an instance when present.

local SceneManager = {}
SceneManager.__index = SceneManager

-- Scene types aligned with SOC workflow
local SCENES = {
    MAIN_MENU = "main_menu",
    SOC_VIEW = "soc_view",
    UPGRADE_SHOP = "upgrade_shop", 
    INCIDENT_RESPONSE = "incident_response",
    GAME_OVER = "game_over"
}

-- Create new scene manager
function SceneManager.new(eventBus)
    local self = setmetatable({}, SceneManager)
    
    -- Core dependencies
    self.eventBus = eventBus
    
    -- Scene management
    self.scenes = {}
    self.currentScene = nil
    self.previousScene = nil
    
    -- Transition state
    self.transitioning = false
    self.transitionTime = 0
    self.transitionDuration = 0.3
    
    -- Scene data persistence
    self.sceneData = {}
    
    return self
end

-- Initialize scene manager
function SceneManager:initialize()
    -- Load scene modules (support both instance modules and class-style modules)
    -- Note: Scene modules can either export an instantiated table (with methods)
    -- or a class-style table exposing a `new()` constructor. SceneManager will
    -- prefer constructing an instance when `new` is present, falling back to
    -- using the module table itself if construction fails.
    local modules = {
        [SCENES.MAIN_MENU] = require("src.scenes.main_menu"),
        [SCENES.SOC_VIEW] = require("src.scenes.soc_view"),
        [SCENES.UPGRADE_SHOP] = require("src.scenes.upgrade_shop"),
        [SCENES.INCIDENT_RESPONSE] = require("src.scenes.incident_response"),
        [SCENES.GAME_OVER] = require("src.scenes.game_over")
    }

    -- Instantiate modules that expose a constructor (.new)
    for name, mod in pairs(modules) do
        if type(mod) == "table" and type(mod.new) == "function" then
            -- Prefer instance created from constructor
            local ok, instance = pcall(mod.new)
            if ok and type(instance) == "table" then
                self.scenes[name] = instance
            else
                -- Fallback to module table if constructor fails
                self.scenes[name] = mod
            end
        else
            self.scenes[name] = mod
        end
    end

    -- Initialize all scenes
    for sceneName, scene in pairs(self.scenes) do
        if scene and scene.initialize then
            scene:initialize(self.eventBus)
        end
    end
    
    -- Set default scene
    self:switchToScene(SCENES.MAIN_MENU)
    
    print("🎬 SceneManager: Initialized SOC scene system")
end

-- Switch to a new scene
function SceneManager:switchToScene(sceneName, data)
    if not self.scenes[sceneName] then
        print("❌ SceneManager: Unknown scene '" .. sceneName .. "'")
        return false
    end
    
    -- Store previous scene for potential return
    self.previousScene = self.currentScene
    
    -- Exit current scene
    if self.currentScene and self.scenes[self.currentScene].exit then
        self.scenes[self.currentScene]:exit()
    end
    
    -- Start transition
    self.transitioning = true
    self.transitionTime = 2
    
    -- Set new scene
    self.currentScene = sceneName
    
    -- Enter new scene
    if self.scenes[self.currentScene].enter then
        self.scenes[self.currentScene]:enter(data or {})
    end
    
    -- Store scene data
    if data then
        self.sceneData[sceneName] = data
    end
    
    -- Publish scene change event
    self.eventBus:publish("scene_changed", {
        scene = sceneName,
        previous = self.previousScene,
        data = data
    })
    
    print("🎬 SceneManager: Switched to scene '" .. sceneName .. "'")
    return true
end

-- Go back to previous scene
function SceneManager:goBack()
    if self.previousScene then
        self:switchToScene(self.previousScene)
        return true
    end
    return false
end

-- Update scene manager
function SceneManager:update(dt)
    -- Update transition
    if self.transitioning then
        self.transitionTime = self.transitionTime + dt
        if self.transitionTime >= self.transitionDuration then
            self.transitioning = false
        end
    end
    
    -- Update current scene
    if self.currentScene and self.scenes[self.currentScene] then
        local scene = self.scenes[self.currentScene]
        if scene.update then
            scene:update(dt)
        end
    end
end

-- Draw scene manager
function SceneManager:draw()
    -- Draw current scene
    if self.currentScene and self.scenes[self.currentScene] then
        local scene = self.scenes[self.currentScene]
        if scene.draw then
            scene:draw()
        end
    end
    
    -- Draw transition effect if transitioning
    if self.transitioning then
        self:drawTransition()
    end
end

-- Draw transition effect
function SceneManager:drawTransition()
    local progress = self.transitionTime / self.transitionDuration
    local alpha = math.sin(progress * math.pi) * 0.3
    
    love.graphics.setColor(0, 0, 0, alpha)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.setColor(1, 1, 1, 1) -- Reset color
end

-- Handle input events
function SceneManager:keypressed(key)
    if self.currentScene and self.scenes[self.currentScene] then
        local scene = self.scenes[self.currentScene]
        if scene.keypressed then
            scene:keypressed(key)
        end
    end
end

function SceneManager:mousepressed(x, y, button)
    if self.currentScene and self.scenes[self.currentScene] then
        local scene = self.scenes[self.currentScene]
        if scene.mousepressed then
            scene:mousepressed(x, y, button)
        end
    end
end

-- Get current scene info
function SceneManager:getCurrentScene()
    return self.currentScene
end

function SceneManager:isTransitioning()
    return self.transitioning
end

-- Scene constants for external use
SceneManager.SCENES = SCENES

return SceneManager