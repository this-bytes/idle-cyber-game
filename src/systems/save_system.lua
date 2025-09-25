-- Save System
-- Handles game persistence and loading

local SaveSystem = {}
SaveSystem.__index = SaveSystem

local json = require("src.utils.json") -- We'll need a JSON library

-- Create new save system
function SaveSystem.new()
    local self = setmetatable({}, SaveSystem)
    self.saveFilePath = "cyberspace_tycoon_save.json"
    return self
end

-- Save game data
function SaveSystem:save(gameData)
    local success, err = pcall(function()
        local saveData = {
            version = "1.0.0",
            timestamp = os.time(),
            data = gameData
        }
        
        local jsonString = json.encode(saveData)
        love.filesystem.write(self.saveFilePath, jsonString)
    end)
    
    if not success then
        print("❌ Save failed: " .. tostring(err))
        return false
    end
    
    return true
end

-- Load game data
function SaveSystem:load()
    if not love.filesystem.getInfo(self.saveFilePath) then
        return nil -- No save file exists
    end
    
    local success, result = pcall(function()
        local jsonString = love.filesystem.read(self.saveFilePath)
        local saveData = json.decode(jsonString)
        return saveData.data
    end)
    
    if not success then
        print("❌ Load failed: " .. tostring(result))
        return nil
    end
    
    return result
end

-- Check if save file exists
function SaveSystem:saveExists()
    return love.filesystem.getInfo(self.saveFilePath) ~= nil
end

-- Delete save file
function SaveSystem:deleteSave()
    if self:saveExists() then
        love.filesystem.remove(self.saveFilePath)
        return true
    end
    return false
end

return SaveSystem