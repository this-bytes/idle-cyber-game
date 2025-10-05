-- src/systems/data_manager.lua
-- Thin wrapper copied from src/core/data_manager.lua to provide canonical systems path
local DataManager = {}
DataManager.__index = DataManager

-- System metadata for automatic registration
DataManager.metadata = {
    priority = 1,  -- Load very early - other systems depend on data
    dependencies = {},
    systemName = "DataManager"
}

local dkjson = require("dkjson")

function DataManager.new(eventBus)
    local self = setmetatable({}, DataManager)
    self.eventBus = eventBus
    self.gameData = {}
    self.dataDirectory = "src/data"
    return self
end

function DataManager:loadDataFile(fileName)
    local path = self.dataDirectory .. "/" .. fileName
    local content, err = love.filesystem.read(path)
    if not content then
        print("❌ DataManager: Failed to read data file: " .. path .. " - " .. tostring(err))
        return false
    end

    local success, data = pcall(dkjson.decode, content)
    if not success then
        print("❌ DataManager: Failed to parse JSON from " .. path .. ": " .. tostring(data))
        return false
    end

    local dataKey = fileName:match("(.+)%.json$")
    if dataKey then
        self.gameData[dataKey] = data
        print("Successfully loaded data for: " .. dataKey)
        return true
    end
    return false
end

function DataManager:loadAllData()
    local files, err = love.filesystem.getDirectoryItems(self.dataDirectory)
    if err then
        print("❌ DataManager: Could not read data directory: " .. tostring(err))
        return
    end

    for _, file in ipairs(files) do
        if file:match("%.json$") then
            self:loadDataFile(file)
        end
    end
end

function DataManager:getData(key)
    return self.gameData[key]
end

return DataManager
