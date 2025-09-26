-- Configuration Loader System
-- Handles loading game configuration from JSON files with hot-reload support

local json = require("src.utils.json")

local ConfigLoader = {}
ConfigLoader.__index = ConfigLoader

-- Create new config loader
function ConfigLoader.new()
    local self = setmetatable({}, ConfigLoader)
    self.configs = {}
    self.fileWatchers = {}
    self.lastModified = {}
    return self
end

-- Load configuration from file
function ConfigLoader:loadConfig(configName, filePath)
    print("📁 Loading config: " .. configName .. " from " .. filePath)
    
    -- Check if file exists
    local info = love.filesystem.getInfo(filePath)
    if not info then
        print("❌ Config file not found: " .. filePath)
        return nil
    end
    
    -- Read and parse JSON
    local success, result = pcall(function()
        local jsonString = love.filesystem.read(filePath)
        return json.decode(jsonString)
    end)
    
    if not success then
        print("❌ Failed to load config " .. configName .. ": " .. tostring(result))
        return nil
    end
    
    -- Store config and metadata
    self.configs[configName] = result
    self.lastModified[configName] = info.modtime
    
    print("✅ Loaded config: " .. configName .. " (" .. self:getConfigItemCount(result) .. " items)")
    return result
end

-- Get config by name
function ConfigLoader:getConfig(configName)
    return self.configs[configName]
end

-- Check if config has been modified and reload if needed
function ConfigLoader:checkForUpdates(configName, filePath)
    local info = love.filesystem.getInfo(filePath)
    if not info then
        return false
    end
    
    local lastMod = self.lastModified[configName]
    if not lastMod or info.modtime > lastMod then
        print("🔄 Config file updated, reloading: " .. configName)
        return self:loadConfig(configName, filePath) ~= nil
    end
    
    return false
end

-- Save config to file (for admin panel modifications)
function ConfigLoader:saveConfig(configName, filePath)
    local config = self.configs[configName]
    if not config then
        print("❌ No config loaded: " .. configName)
        return false
    end
    
    local success, err = pcall(function()
        local jsonString = json.encode(config)
        love.filesystem.write(filePath, jsonString)
    end)
    
    if not success then
        print("❌ Failed to save config " .. configName .. ": " .. tostring(err))
        return false
    end
    
    -- Update modification time
    local info = love.filesystem.getInfo(filePath)
    if info then
        self.lastModified[configName] = info.modtime
    end
    
    print("💾 Saved config: " .. configName)
    return true
end

-- Update specific item in config
function ConfigLoader:updateConfigItem(configName, itemId, itemData)
    local config = self.configs[configName]
    if not config then
        print("❌ No config loaded: " .. configName)
        return false
    end
    
    config[itemId] = itemData
    print("🔧 Updated config item: " .. configName .. "." .. itemId)
    return true
end

-- Get config item by ID
function ConfigLoader:getConfigItem(configName, itemId)
    local config = self.configs[configName]
    if not config then
        return nil
    end
    return config[itemId]
end

-- Get count of items in config
function ConfigLoader:getConfigItemCount(config)
    local count = 0
    for _ in pairs(config) do
        count = count + 1
    end
    return count
end

-- Validate config structure (basic validation)
function ConfigLoader:validateConfig(configName, schema)
    local config = self.configs[configName]
    if not config then
        return false, "Config not loaded"
    end
    
    -- Basic validation - just check if it's a table
    if type(config) ~= "table" then
        return false, "Config must be a table"
    end
    
    -- More sophisticated validation could be added here
    return true, "Valid"
end

return ConfigLoader