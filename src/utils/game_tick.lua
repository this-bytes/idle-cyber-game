-- Game tick utility
local GameTick = {}
GameTick.__index = GameTick
GameTick.FPS = 60
GameTick.dt = 1 / GameTick.FPS
GameTick.accumulator = 0
GameTick.maxFrameTime = 0.25 -- Cap to avoid spiral of death
GameTick.totalTime = 0
GameTick.frameCount = 0
GameTick.fps = 0
GameTick.fpsTimer = 0
GameTick.fpsInterval = 1 -- Update FPS every second

-- Update game tick
function GameTick:update(dt)
    -- Cap dt to avoid spiral of death
    if dt > self.maxFrameTime then
        dt = self.maxFrameTime
    end 
    self.accumulator = self.accumulator + dt
    self.totalTime = self.totalTime + dt
    self.fpsTimer = self.fpsTimer + dt
    self.frameCount = self.frameCount + 1
    if self.fpsTimer >= self.fpsInterval then
        self.fps = self.frameCount / self.fpsTimer
        self.frameCount = 0
        self.fpsTimer = self.fpsTimer - self.fpsInterval
    end
end     
-- Check if we should run a fixed update
function GameTick:shouldUpdate()
    if self.accumulator >= self.dt then
        self.accumulator = self.accumulator - self.dt
        return true
    end
    return false
end     
-- Get current FPS
function GameTick:getFPS()
    return self.fps
end
-- Get total elapsed time
function GameTick:getTotalTime()
    return self.totalTime
end
-- Reset the game tick (for new game or load)
function GameTick:reset()
    self.accumulator = 0
    self.totalTime = 0
    self.frameCount = 0
    self.fps = 0
    self.fpsTimer = 0
end 

return GameTick
