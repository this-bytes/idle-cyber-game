-- Simple JSON encoder/decoder
-- Minimal implementation for save/load functionality

local json = {}

-- Encode table to JSON string
function json.encode(obj)
    local objType = type(obj)
    
    if objType == "nil" then
        return "null"
    elseif objType == "boolean" then
        return obj and "true" or "false"
    elseif objType == "number" then
        return tostring(obj)
    elseif objType == "string" then
        return '"' .. obj:gsub('\\', '\\\\'):gsub('"', '\\"') .. '"'
    elseif objType == "table" then
        local result = {}
        local isArray = true
        local maxKey = 0
        
        -- Check if it's an array
        for k, v in pairs(obj) do
            if type(k) ~= "number" or k <= 0 or k ~= math.floor(k) then
                isArray = false
                break
            end
            maxKey = math.max(maxKey, k)
        end
        
        if isArray then
            -- Array format
            for i = 1, maxKey do
                table.insert(result, json.encode(obj[i]))
            end
            return "[" .. table.concat(result, ",") .. "]"
        else
            -- Object format
            for k, v in pairs(obj) do
                table.insert(result, json.encode(tostring(k)) .. ":" .. json.encode(v))
            end
            return "{" .. table.concat(result, ",") .. "}"
        end
    else
        error("Cannot encode " .. objType)
    end
end

-- Simple decode - just use loadstring for now (not production ready)
function json.decode(str)
    -- This is a very basic implementation
    -- In a real game, you'd want a proper JSON parser
    local jsonStr = str:gsub("null", "nil"):gsub("true", "true"):gsub("false", "false")
    local func = load("return " .. jsonStr)
    if func then
        return func()
    else
        error("Invalid JSON")
    end
end

return json