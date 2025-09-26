-- Network Save System
-- Enhanced save system that integrates with the Flask backend
-- Falls back to local saves when offline

local NetworkSaveSystem = {}
NetworkSaveSystem.__index = NetworkSaveSystem

local api = require("api")
local SaveSystem = require("src.systems.save_system")

-- Create new network save system
function NetworkSaveSystem.new()
    local self = setmetatable({}, NetworkSaveSystem)
    
    -- Local save system for fallback
    self.localSave = SaveSystem.new()
    
    -- Network state
    self.isOnline = false
    self.lastConnectionTest = 0
    self.connectionTestInterval = 30 -- Test connection every 30 seconds
    self.username = "default_player"
    self.saveMode = "hybrid" -- "local", "server", "hybrid"
    
    -- Pending operations
    self.pendingSave = nil
    self.loadCallback = nil
    
    -- Settings
    self.autoSyncEnabled = true
    self.offlineMode = false
    
    return self
end

-- Set player username for server saves
function NetworkSaveSystem:setUsername(username)
    self.username = username or "default_player"
    print("🌐 Player username set to: " .. self.username)
end

-- Set save mode: "local", "server", or "hybrid"
function NetworkSaveSystem:setSaveMode(mode)
    local validModes = {local = true, server = true, hybrid = true}
    if validModes[mode] then
        self.saveMode = mode
        print("💾 Save mode set to: " .. mode)
    else
        print("❌ Invalid save mode: " .. mode)
    end
end

-- Test connection to server
function NetworkSaveSystem:testConnection(callback)
    api.testConnection(function(success, result)
        self.isOnline = success
        if success then
            print("🌐 Server connection: OK")
        else
            print("❌ Server connection: FAILED - " .. tostring(result))
        end
        if callback then callback(success, result) end
    end)
end

-- Update function to handle async operations and connection testing
function NetworkSaveSystem:update(dt)
    -- Update API for async requests
    api.update()
    
    -- Test connection periodically
    self.lastConnectionTest = self.lastConnectionTest + dt
    if self.lastConnectionTest >= self.connectionTestInterval then
        self.lastConnectionTest = 0
        if not self.offlineMode then
            self:testConnection()
        end
    end
end

-- Save game data with hybrid approach
function NetworkSaveSystem:save(gameData, callback)
    callback = callback or function() end
    
    -- Always save locally first (immediate backup)
    if self.saveMode ~= "server" then
        local localSuccess = self.localSave:save(gameData)
        if localSuccess then
            print("💾 Local save: SUCCESS")
        else
            print("❌ Local save: FAILED")
        end
    end
    
    -- Try server save if online and not in local-only mode
    if self.saveMode ~= "local" and not self.offlineMode then
        self:saveToServer(gameData, function(success, result)
            if success then
                print("🌐 Server save: SUCCESS")
                callback(true, "saved to server")
            else
                print("❌ Server save: FAILED - " .. tostring(result))
                if self.saveMode == "server" then
                    -- If server-only mode failed, try local save as emergency backup
                    local emergencySuccess = self.localSave:save(gameData)
                    if emergencySuccess then
                        print("💾 Emergency local save: SUCCESS")
                        callback(true, "saved locally (emergency)")
                    else
                        callback(false, "both server and local saves failed")
                    end
                else
                    callback(true, "saved locally")
                end
            end
        end)
    else
        callback(true, "saved locally")
    end
end

-- Save specifically to server
function NetworkSaveSystem:saveToServer(gameData, callback)
    if not gameData or not gameData.resources then
        if callback then callback(false, "invalid game data") end
        return
    end
    
    local resources = gameData.resources
    
    -- Prepare additional data
    local additionalData = {
        reputation = resources.reputation or 0,
        xp = resources.xp or 0,
        mission_tokens = resources.missionTokens or 0
    }
    
    -- Add other systems data if available
    if gameData.contracts then
        additionalData.contracts_data = gameData.contracts
    end
    if gameData.specialists then
        additionalData.specialists_data = gameData.specialists
    end
    if gameData.upgrades then
        additionalData.upgrades_data = gameData.upgrades
    end
    
    api.savePlayer(
        self.username,
        math.floor(resources.money or 0),
        math.floor(resources.prestige or 0),
        additionalData,
        callback
    )
end

-- Load game data with hybrid approach
function NetworkSaveSystem:load(callback)
    callback = callback or function() end
    
    -- Try server load first if online and not in local-only mode
    if self.saveMode ~= "local" and not self.offlineMode then
        self:loadFromServer(function(success, serverData)
            if success and serverData then
                print("🌐 Server load: SUCCESS")
                -- Also load local data for comparison/merging if in hybrid mode
                if self.saveMode == "hybrid" then
                    local localData = self.localSave:load()
                    if localData then
                        -- TODO: Implement data merging logic
                        -- For now, prioritize server data
                        print("📊 Hybrid mode: Using server data")
                    end
                end
                callback(success, self:convertServerDataToGameData(serverData))
            else
                print("❌ Server load: FAILED - " .. tostring(serverData))
                -- Fall back to local save
                local localData = self.localSave:load()
                if localData then
                    print("💾 Local load: SUCCESS (fallback)")
                    callback(true, localData)
                else
                    print("❌ Local load: FAILED")
                    callback(false, "no save data available")
                end
            end
        end)
    else
        -- Local-only mode
        local localData = self.localSave:load()
        if localData then
            print("💾 Local load: SUCCESS")
            callback(true, localData)
        else
            print("❌ Local load: FAILED")
            callback(false, "no local save data")
        end
    end
end

-- Load specifically from server
function NetworkSaveSystem:loadFromServer(callback)
    api.loadPlayer(self.username, function(success, result)
        if success and result and result.player then
            callback(true, result.player)
        else
            -- Try creating new player if not found
            if result and type(result) == "string" and result:find("not found") then
                print("🆕 Player not found, creating new player...")
                api.createPlayer(self.username, function(createSuccess, createResult)
                    if createSuccess and createResult then
                        callback(true, createResult)
                    else
                        callback(false, createResult or "failed to create player")
                    end
                end)
            else
                callback(false, result or "unknown error")
            end
        end
    end)
end

-- Convert server data format to game data format
function NetworkSaveSystem:convertServerDataToGameData(serverData)
    local gameData = {
        resources = {
            money = serverData.current_currency or 0,
            reputation = serverData.reputation or 0,
            xp = serverData.xp or 0,
            missionTokens = serverData.mission_tokens or 0,
            prestige = serverData.prestige_level or 0
        },
        version = "1.0.0",
        timestamp = os.time()
    }
    
    -- Add idle time for offline earnings calculation
    if serverData.idle_time_seconds then
        gameData.idleTimeSeconds = serverData.idle_time_seconds
        print("⏰ Offline time: " .. math.floor(serverData.idle_time_seconds) .. " seconds")
    end
    
    -- Restore complex system data if available
    if serverData.contracts_data then
        gameData.contracts = serverData.contracts_data
    end
    if serverData.specialists_data then
        gameData.specialists = serverData.specialists_data
    end
    if serverData.upgrades_data then
        gameData.upgrades = serverData.upgrades_data
    end
    
    return gameData
end

-- Apply offline earnings based on idle time
function NetworkSaveSystem:applyOfflineEarnings(gameData, idleTimeSeconds)
    if not idleTimeSeconds or idleTimeSeconds <= 0 then
        return gameData
    end
    
    -- Calculate offline earnings (basic implementation)
    local baseRate = 10 -- Base money per second when offline
    local offlineEarnings = math.floor(baseRate * idleTimeSeconds)
    
    -- Cap offline earnings to prevent exploitation
    local maxOfflineHours = 24
    local maxOfflineEarnings = baseRate * 60 * 60 * maxOfflineHours
    offlineEarnings = math.min(offlineEarnings, maxOfflineEarnings)
    
    if offlineEarnings > 0 then
        gameData.resources.money = (gameData.resources.money or 0) + offlineEarnings
        print("💰 Offline earnings: $" .. offlineEarnings .. " (" .. math.floor(idleTimeSeconds/60) .. " minutes)")
    end
    
    return gameData
end

-- Check if save file exists (local)
function NetworkSaveSystem:saveExists()
    return self.localSave:saveExists()
end

-- Delete save files
function NetworkSaveSystem:deleteSave()
    local localDeleted = self.localSave:deleteSave()
    print("🗑️  Local save deleted: " .. (localDeleted and "SUCCESS" or "FAILED"))
    
    -- TODO: Implement server save deletion if needed
    -- This would require a new API endpoint
    
    return localDeleted
end

-- Get connection status
function NetworkSaveSystem:getConnectionStatus()
    return {
        isOnline = self.isOnline,
        saveMode = self.saveMode,
        username = self.username,
        offlineMode = self.offlineMode
    }
end

-- Enable/disable offline mode
function NetworkSaveSystem:setOfflineMode(enabled)
    self.offlineMode = enabled
    print("📡 Offline mode: " .. (enabled and "ENABLED" or "DISABLED"))
end

-- Sync local and server saves (for hybrid mode)
function NetworkSaveSystem:syncSaves(callback)
    if self.saveMode ~= "hybrid" then
        if callback then callback(false, "not in hybrid mode") end
        return
    end
    
    -- TODO: Implement comprehensive sync logic
    -- For now, just test the connection
    self:testConnection(callback)
end

return NetworkSaveSystem