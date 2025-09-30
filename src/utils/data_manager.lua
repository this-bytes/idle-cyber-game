-- src/utils/data_manager.lua

local dkjson = require("dkjson")

local DataManager = {}

function DataManager:new()
    local instance = {
        data = {}
    }
    setmetatable(instance, { __index = self })
    return instance
end

function DataManager:loadDataFromFile(key, filePath)
    local file, err = love.filesystem.newFile(filePath)
    if not file then
        print("Error opening file: " .. filePath .. " (" .. tostring(err) .. ")")
        return false
    end

    local content, read_err = file:read()
    if not content then
        print("Error reading file: " .. filePath .. " (" .. tostring(read_err) .. ")")
        return false
    end

    local success, result = pcall(dkjson.decode, content)
    if success then
        self.data[key] = result
        print("Successfully loaded data for: " .. key)
        return true
    else
        print("Error decoding JSON from " .. filePath .. ": " .. tostring(result))
        return false
    end
end

function DataManager:getData(key)
    return self.data[key]
end

function DataManager:getItem(key, itemId)
    if self.data[key] then
        if self.data[key][itemId] then
            return self.data[key][itemId]
        else
            -- Support for arrays of objects with an 'id' field
            for _, item in ipairs(self.data[key]) do
                if item.id == itemId then
                    return item
                end
            end
        end
    end
    return nil
end

return DataManager
