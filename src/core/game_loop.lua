-- GameLoop - Central Game Loop Manager
-- Fortress Refactor: Industry-standard game loop with proper timing and system orchestration
-- Implements clean separation between update logic and system management

local GameTick = require("src.utils.game_tick")

local GameLoop = {}
GameLoop.__index = GameLoop

-- Create new game loop manager
function GameLoop.new(eventBus)
    local self = setmetatable({}, GameLoop)
    
    -- Core dependencies
    self.eventBus = eventBus
    
    -- System management
    self.systems = {}
    self.systemOrder = {} -- Explicit system update order
    
    -- Timing and performance
    self.gameTick = GameTick
    self.isPaused = false
    self.timeScale = 0.1
    
    -- Performance monitoring
    self.performanceMetrics = {
        frameCount = 0,
        updateTime = 0,
        systemUpdateTimes = {},
        lastFPSUpdate = 0,
        fps = 0
    }
    
    -- Loop state
    self.initialized = false
    
    return self
end

-- Register a system with the game loop
function GameLoop:registerSystem(name, system, priority)
    if not name or not system then
        error("GameLoop:registerSystem requires name and system")
    end
    
    -- Store system
    self.systems[name] = system
    
    -- Insert into ordered list based on priority (lower number = higher priority)
    priority = priority or 100
    local inserted = false
    
    for i, entry in ipairs(self.systemOrder) do
        if priority < entry.priority then
            table.insert(self.systemOrder, i, {name = name, priority = priority})
            inserted = true
            break
        end
    end
    
    if not inserted then
        table.insert(self.systemOrder, {name = name, priority = priority})
    end
    
    -- Initialize performance tracking for this system
    self.performanceMetrics.systemUpdateTimes[name] = 0
    
    print("🔧 GameLoop: Registered system '" .. name .. "' with priority " .. priority)
end

-- Unregister a system
function GameLoop:unregisterSystem(name)
    self.systems[name] = nil
    self.performanceMetrics.systemUpdateTimes[name] = nil
    
    -- Remove from ordered list
    for i, entry in ipairs(self.systemOrder) do
        if entry.name == name then
            table.remove(self.systemOrder, i)
            break
        end
    end
    
    print("🔧 GameLoop: Unregistered system '" .. name .. "'")
end

-- Get a registered system
function GameLoop:getSystem(name)
    return self.systems[name]
end

-- Initialize the game loop
function GameLoop:initialize()
    if self.initialized then
        return
    end
    
    -- Reset timing
    self.gameTick:reset()
    
    -- Initialize all systems in order
    for _, entry in ipairs(self.systemOrder) do
        local system = self.systems[entry.name]
        if system and system.initialize then
            local startTime = love.timer and love.timer.getTime() or 0
            system:initialize()
            local endTime = love.timer and love.timer.getTime() or 0
            print("🚀 GameLoop: Initialized system '" .. entry.name .. "' (" .. 
                  string.format("%.2fms", (endTime - startTime) * 1000) .. ")")
        end
    end
    
    self.initialized = true
    self.eventBus:publish("game_loop_initialized", {})
    print("🎯 GameLoop: initialized")
end

-- Main update loop - called every frame
function GameLoop:update(dt)
    if not self.initialized then
        return
    end
    
    local frameStartTime = love.timer and love.timer.getTime() or 0
    
    -- Update game tick
    self.gameTick:update(dt * self.timeScale)
    
    -- Only run fixed updates when needed
    while self.gameTick:shouldUpdate() do
        self:fixedUpdate(self.gameTick.dt)
    end
    
    -- Update performance metrics
    local frameEndTime = love.timer and love.timer.getTime() or 0
    self.performanceMetrics.updateTime = frameEndTime - frameStartTime
    self.performanceMetrics.frameCount = self.performanceMetrics.frameCount + 1
    
    -- Update FPS counter
    if frameEndTime - self.performanceMetrics.lastFPSUpdate >= 1.0 then
        self.performanceMetrics.fps = self.performanceMetrics.frameCount
        self.performanceMetrics.frameCount = 0
        self.performanceMetrics.lastFPSUpdate = frameEndTime
    end
end

-- Fixed timestep update - called at consistent intervals
function GameLoop:fixedUpdate(dt)
    if self.isPaused then
        return
    end
    
    -- Update systems in priority order
    for _, entry in ipairs(self.systemOrder) do
        local system = self.systems[entry.name]
        if system and system.update then
            local startTime = love.timer and love.timer.getTime() or 0
            system:update(dt)
            local endTime = love.timer and love.timer.getTime() or 0
            
            -- Track per-system performance
            self.performanceMetrics.systemUpdateTimes[entry.name] = endTime - startTime
        end
    end
    
    -- Publish update event for loose coupling
    self.eventBus:publish("game_loop_update", {dt = dt})
end

-- Pause/unpause the game loop
function GameLoop:setPaused(paused)
    if self.isPaused ~= paused then
        self.isPaused = paused
        self.eventBus:publish("game_loop_paused", {paused = paused})
        print(paused and "⏸️  GameLoop: Paused" or "▶️  GameLoop: Resumed")
    end
end

-- Set time scale for slow motion or fast forward
function GameLoop:setTimeScale(scale)
    self.timeScale = math.max(0.1, math.min(10.0, scale or 1.0))
    self.eventBus:publish("game_loop_time_scale_changed", {timeScale = self.timeScale})
end

-- Get performance metrics
function GameLoop:getPerformanceMetrics()
    return {
        fps = self.performanceMetrics.fps,
        updateTime = self.performanceMetrics.updateTime,
        systemUpdateTimes = self.performanceMetrics.systemUpdateTimes,
        totalTime = self.gameTick:getTotalTime(),
        isPaused = self.isPaused,
        timeScale = self.timeScale
    }
end

-- Shutdown the game loop
function GameLoop:shutdown()
    if not self.initialized then
        return
    end
    
    -- Shutdown systems in reverse order
    for i = #self.systemOrder, 1, -1 do
        local entry = self.systemOrder[i]
        local system = self.systems[entry.name]
        if system and system.shutdown then
            system:shutdown()
            print("🔧 GameLoop: Shutdown system '" .. entry.name .. "'")
        end
    end
    
    self.initialized = false
    self.eventBus:publish("game_loop_shutdown", {})
    print("🎯 GameLoop: Fortress architecture shutdown complete")
end

return GameLoop
