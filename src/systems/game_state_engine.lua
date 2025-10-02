-- Game State Engine
-- ==================
-- Comprehensive state management system that handles:
-- - Resource tracking and generation
-- - Persistent save/load functionality
-- - Offline earnings calculation
-- - Automatic state synchronization across all systems
-- - Periodic auto-save
-- - State validation and error recovery

local GameStateEngine = {}
GameStateEngine.__index = GameStateEngine

local json = require("src.utils.dkjson")

-- Create new game state engine
function GameStateEngine.new(eventBus)
    local self = setmetatable({}, GameStateEngine)
    self.eventBus = eventBus
    
    -- Core state tracking
    self.state = {
        version = "1.0.0",
        lastSaveTime = os.time(),
        lastUpdateTime = love.timer.getTime(),
        totalPlayTime = 0,
        sessionStartTime = love.timer.getTime(),
        
        -- Track which systems have been initialized
        initialized = false,
        systemsReady = {}
    }
    
    -- Save configuration
    self.saveFilePath = "game_state.json"
    self.autoSaveEnabled = true
    self.autoSaveInterval = 60 -- Auto-save every 60 seconds
    self.timeSinceLastSave = 0
    
    -- System references (to be set after initialization)
    self.systems = {}
    
    -- State change tracking for optimization
    self.stateChanged = false
    self.pendingChanges = {}
    
    print("💾 GameStateEngine initialized")
    
    return self
end

-- Register a system for state management
function GameStateEngine:registerSystem(name, system)
    if not system then
        print("⚠️  Cannot register nil system: " .. name)
        return false
    end
    
    self.systems[name] = system
    self.state.systemsReady[name] = true
    
    -- Check if system supports state management
    if not system.getState or not system.loadState then
        print("⚠️  System '" .. name .. "' does not support state management (missing getState/loadState)")
    end
    
    return true
end

-- Update state engine (handles auto-save)
function GameStateEngine:update(dt)
    -- Track play time
    self.state.totalPlayTime = self.state.totalPlayTime + dt
    self.state.lastUpdateTime = love.timer.getTime()
    
    -- Handle auto-save
    if self.autoSaveEnabled then
        self.timeSinceLastSave = self.timeSinceLastSave + dt
        
        if self.timeSinceLastSave >= self.autoSaveInterval then
            self:saveState()
            self.timeSinceLastSave = 0
        end
    end
end

-- Get complete game state from all systems
function GameStateEngine:getCompleteState()
    local completeState = {
        version = self.state.version,
        timestamp = os.time(),
        lastSaveTime = self.state.lastSaveTime,
        totalPlayTime = self.state.totalPlayTime,
        systems = {}
    }
    
    -- Collect state from all registered systems
    for name, system in pairs(self.systems) do
        if system.getState then
            local success, systemState = pcall(function()
                return system:getState()
            end)
            
            if success and systemState then
                completeState.systems[name] = systemState
            else
                print("⚠️  Failed to get state from system: " .. name)
                if not success then
                    print("    Error: " .. tostring(systemState))
                end
            end
        elseif system.getSaveData then
            -- Support legacy getSaveData method
            local success, systemState = pcall(function()
                return system:getSaveData()
            end)
            
            if success and systemState then
                completeState.systems[name] = systemState
            end
        end
    end
    
    return completeState
end

-- Load state into all systems
function GameStateEngine:loadCompleteState(completeState)
    if not completeState then
        print("⚠️  No state to load")
        return false
    end
    
    -- Validate version compatibility
    if completeState.version and completeState.version ~= self.state.version then
        print("⚠️  Save file version mismatch: " .. completeState.version .. " vs " .. self.state.version)
        print("    Attempting to load anyway...")
    end
    
    -- Restore core state
    if completeState.totalPlayTime then
        self.state.totalPlayTime = completeState.totalPlayTime
    end
    if completeState.lastSaveTime then
        self.state.lastSaveTime = completeState.lastSaveTime
    end
    
    -- Load state into all systems
    if completeState.systems then
        for name, systemState in pairs(completeState.systems) do
            local system = self.systems[name]
            
            if system then
                if system.loadState then
                    local success, err = pcall(function()
                        system:loadState(systemState)
                    end)
                    
                    if success then
                        print("✅ Loaded state for: " .. name)
                    else
                        print("❌ Failed to load state for: " .. name)
                        print("   Error: " .. tostring(err))
                    end
                elseif system.loadSaveData then
                    -- Support legacy loadSaveData method
                    local success, err = pcall(function()
                        system:loadSaveData(systemState)
                    end)
                    
                    if success then
                        print("✅ Loaded data for: " .. name)
                    else
                        print("❌ Failed to load data for: " .. name)
                    end
                end
            else
                print("⚠️  System not registered: " .. name .. " (state exists but system not found)")
            end
        end
    end
    
    self.state.initialized = true
    
    -- Publish event for UI updates
    if self.eventBus then
        self.eventBus:publish("game_state_loaded", {
            totalPlayTime = self.state.totalPlayTime,
            timestamp = completeState.timestamp
        })
    end
    
    return true
end

-- Save current state to file
function GameStateEngine:saveState()
    local completeState = self:getCompleteState()
    
    local success, err = pcall(function()
        local jsonString = json.encode(completeState, {indent = true})
        love.filesystem.write(self.saveFilePath, jsonString)
    end)
    
    if success then
        self.state.lastSaveTime = os.time()
        print("💾 Game state saved successfully")
        
        -- Publish save event
        if self.eventBus then
            self.eventBus:publish("game_state_saved", {
                timestamp = self.state.lastSaveTime
            })
        end
        
        return true
    else
        print("❌ Failed to save game state: " .. tostring(err))
        return false
    end
end

-- Load state from file
function GameStateEngine:loadState()
    if not love.filesystem.getInfo(self.saveFilePath) then
        print("📝 No save file found (new game)")
        return false
    end
    
    local success, result = pcall(function()
        local jsonString = love.filesystem.read(self.saveFilePath)
        return json.decode(jsonString)
    end)
    
    if not success then
        print("❌ Failed to load game state: " .. tostring(result))
        return false
    end
    
    if result then
        print("💾 Loading game state from file...")
        return self:loadCompleteState(result)
    end
    
    return false
end

-- Check if save file exists
function GameStateEngine:saveExists()
    return love.filesystem.getInfo(self.saveFilePath) ~= nil
end

-- Delete save file (for testing or new game)
function GameStateEngine:deleteSave()
    if self:saveExists() then
        local success = love.filesystem.remove(self.saveFilePath)
        if success then
            print("🗑️  Save file deleted")
            return true
        else
            print("❌ Failed to delete save file")
            return false
        end
    end
    return false
end

-- Calculate offline earnings since last save
function GameStateEngine:calculateOfflineEarnings()
    local currentTime = os.time()
    local timeSinceLastSave = currentTime - self.state.lastSaveTime
    
    -- Only calculate if player was away for more than 60 seconds
    if timeSinceLastSave < 60 then
        print("⏱️  No offline time (< 1 minute)")
        return nil
    end
    
    -- Get idle system if available
    local idleSystem = self.systems.idleSystem
    if not idleSystem or not idleSystem.calculateOfflineProgress then
        print("⚠️  IdleSystem not available for offline earnings")
        return nil
    end
    
    print(string.format("💤 Calculating offline earnings for %d seconds (%.1f minutes)...", 
        timeSinceLastSave, timeSinceLastSave / 60))
    
    -- Calculate offline progress
    local offlineProgress = idleSystem:calculateOfflineProgress(timeSinceLastSave)
    
    if offlineProgress and offlineProgress.netGain then
        -- Apply offline progress to game state
        if idleSystem.applyOfflineProgress then
            idleSystem:applyOfflineProgress(offlineProgress)
        end
        
        -- Publish offline earnings event
        if self.eventBus then
            self.eventBus:publish("offline_earnings_calculated", {
                idleTime = timeSinceLastSave,
                earnings = offlineProgress.earnings or 0,
                damage = offlineProgress.damage or 0,
                netGain = offlineProgress.netGain or 0,
                events = offlineProgress.events or {}
            })
        end
        
        return offlineProgress
    end
    
    return nil
end

-- Quick save (for manual saves or on exit)
function GameStateEngine:quickSave()
    print("💾 Quick saving game state...")
    return self:saveState()
end

-- Get state summary for debugging
function GameStateEngine:getStateSummary()
    return {
        version = self.state.version,
        totalPlayTime = self.state.totalPlayTime,
        sessionDuration = love.timer.getTime() - self.state.sessionStartTime,
        lastSaveTime = self.state.lastSaveTime,
        autoSaveEnabled = self.autoSaveEnabled,
        autoSaveInterval = self.autoSaveInterval,
        timeSinceLastSave = self.timeSinceLastSave,
        systemsRegistered = self:countKeys(self.systems),
        saveExists = self:saveExists()
    }
end

-- Helper: Count keys in table
function GameStateEngine:countKeys(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

-- Enable/disable auto-save
function GameStateEngine:setAutoSave(enabled)
    self.autoSaveEnabled = enabled
    print("💾 Auto-save " .. (enabled and "enabled" or "disabled"))
end

-- Set auto-save interval
function GameStateEngine:setAutoSaveInterval(seconds)
    if seconds < 10 then
        print("⚠️  Auto-save interval too short (minimum 10 seconds)")
        return false
    end
    
    self.autoSaveInterval = seconds
    print("💾 Auto-save interval set to " .. seconds .. " seconds")
    return true
end

-- Reset state (for new game)
function GameStateEngine:resetState()
    self.state = {
        version = "1.0.0",
        lastSaveTime = os.time(),
        lastUpdateTime = love.timer.getTime(),
        totalPlayTime = 0,
        sessionStartTime = love.timer.getTime(),
        initialized = false,
        systemsReady = {}
    }
    
    self.timeSinceLastSave = 0
    
    print("🔄 Game state reset")
    
    -- Publish reset event
    if self.eventBus then
        self.eventBus:publish("game_state_reset", {})
    end
end

-- Export state to string (for debugging or backup)
function GameStateEngine:exportState()
    local completeState = self:getCompleteState()
    return json.encode(completeState, {indent = true})
end

-- Import state from string
function GameStateEngine:importState(jsonString)
    local success, state = pcall(function()
        return json.decode(jsonString)
    end)
    
    if success and state then
        return self:loadCompleteState(state)
    else
        print("❌ Failed to import state: " .. tostring(state))
        return false
    end
end

return GameStateEngine
