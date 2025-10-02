-- Loading Screen to be used to switch scenes
local LoadingScreen = {}
LoadingScreen.__index = LoadingScreen

function LoadingScreen.new()
  local self = setmetatable({}, LoadingScreen)
  return self
end
function LoadingScreen:enter(params)
  self.nextScene = params.nextScene
  self.nextSceneParams = params.nextSceneParams or {}
  self.loadingTime = params.loadingTime or 1.0 -- seconds
  self.elapsedTime = 0
  self.font = love.graphics.newFont(24)
end 
function LoadingScreen:update(dt)
  self.elapsedTime = self.elapsedTime + dt
  if self.elapsedTime >= self.loadingTime then
    -- Transition to the next scene
    if self.nextScene and self.sceneManager then
      self.sceneManager:changeScene(self.nextScene, self.nextSceneParams)
    else
      print("⚠️ WARNING: No next scene specified or sceneManager not set.")
    end
  end
end
function LoadingScreen:draw()
  love.graphics.setFont(self.font)
  love.graphics.printf("Loading...", 0, love.graphics.getHeight() / 2 - 12, love.graphics.getWidth(), "center")
end
return LoadingScreen    