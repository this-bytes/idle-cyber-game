-- ID Generator Utility
-- Centralized unique ID generation for all game entities
-- Provides both sequential IDs and UUIDs for different use cases

local IDGenerator = {}

-- Generate a UUID v4 (universally unique identifier)
-- Use for entities that need to be globally unique across sessions
function IDGenerator.generateUUID()
    local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
    return string.gsub(template, "[xy]", function(c)
        local v = (c == "x") and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format("%x", v)
    end)
end

-- Generate a unique ID with timestamp and random component
-- Use for entities that need human-readable but unique IDs
function IDGenerator.generateTimestampID(prefix)
    prefix = prefix or "id"
    local timestamp = os.time()
    local random = math.random(1000, 9999)
    return string.format("%s_%d_%d", prefix, timestamp, random)
end

-- Generate a sequential ID (requires counter to be passed in)
-- Use for entities that need predictable, sequential IDs within a system
-- Systems must persist and manage their own counters
function IDGenerator.generateSequentialID(counter, prefix)
    if prefix then
        return string.format("%s_%d", prefix, counter)
    else
        return counter
    end
end

-- Validate that an ID is unique within a collection
function IDGenerator.isUniqueInCollection(id, collection)
    if not collection then return true end
    
    if type(collection) == "table" then
        -- Check if ID exists as key
        if collection[id] ~= nil then
            return false
        end
        
        -- Check if ID exists in array
        for _, item in pairs(collection) do
            if type(item) == "table" and item.id == id then
                return false
            end
        end
    end
    
    return true
end

-- Find the highest ID in a collection (for initializing counters)
function IDGenerator.findMaxID(collection, keyField)
    keyField = keyField or "id"
    local maxId = 0
    
    if not collection then return maxId end
    
    for key, item in pairs(collection) do
        local id = nil
        
        -- Try to get ID from the key itself
        if type(key) == "number" then
            id = key
        elseif type(key) == "string" then
            id = tonumber(key)
        end
        
        -- Try to get ID from the item's field
        if type(item) == "table" and item[keyField] then
            local itemId = tonumber(item[keyField])
            if itemId and itemId > (id or 0) then
                id = itemId
            end
        end
        
        if id and id > maxId then
            maxId = id
        end
    end
    
    return maxId
end

-- Generate a short unique ID (8 characters)
-- Use for temporary IDs or session-specific entities
function IDGenerator.generateShortID()
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local id = ""
    for i = 1, 8 do
        local idx = math.random(1, #chars)
        id = id .. chars:sub(idx, idx)
    end
    return id
end

-- Sanitize an ID to ensure it's valid
function IDGenerator.sanitizeID(id)
    if id == nil then return nil end
    
    -- Convert to string
    local str = tostring(id)
    
    -- Remove invalid characters (keep alphanumeric, underscore, hyphen)
    str = string.gsub(str, "[^%w_%-]", "_")
    
    -- Ensure it doesn't start with a number (for systems that require this)
    if string.match(str, "^%d") then
        str = "id_" .. str
    end
    
    return str
end

return IDGenerator
