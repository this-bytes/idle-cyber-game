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
        return '"' .. obj:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n'):gsub('\r', '\\r'):gsub('\t', '\\t') .. '"'
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
        
        if isArray and maxKey > 0 then
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

-- Simple decode function
function json.decode(str)
    -- Remove whitespace
    str = str:gsub("^%s*", ""):gsub("%s*$", "")
    
    -- Parse different types
    if str == "null" then
        return nil
    elseif str == "true" then
        return true
    elseif str == "false" then
        return false
    elseif str:match("^%-?%d+%.?%d*$") then
        return tonumber(str)
    elseif str:match('^".*"$') then
        -- Simple string parsing (not complete)
        return str:sub(2, -2):gsub('\\"', '"'):gsub('\\\\', '\\')
    elseif str:match("^%[.*%]$") then
        -- Array parsing (simplified)
        local content = str:sub(2, -2)
        if content == "" then return {} end
        
        local result = {}
        local depth = 0
        local current = ""
        
        for i = 1, #content do
            local char = content:sub(i, i)
            if char == ',' and depth == 0 then
                table.insert(result, json.decode(current))
                current = ""
            else
                if char == '{' or char == '[' then
                    depth = depth + 1
                elseif char == '}' or char == ']' then
                    depth = depth - 1
                end
                current = current .. char
            end
        end
        
        if current ~= "" then
            table.insert(result, json.decode(current))
        end
        
        return result
    elseif str:match("^%{.*%}$") then
        -- Object parsing (simplified)
        local content = str:sub(2, -2)
        if content == "" then return {} end
        
        local result = {}
        local depth = 0
        local current = ""
        
        for i = 1, #content do
            local char = content:sub(i, i)
            if char == ',' and depth == 0 then
                local key, value = current:match('^([^:]+):(.+)$')
                if key and value then
                    result[json.decode(key)] = json.decode(value)
                end
                current = ""
            else
                if char == '{' or char == '[' then
                    depth = depth + 1
                elseif char == '}' or char == ']' then
                    depth = depth - 1
                end
                current = current .. char
            end
        end
        
        if current ~= "" then
            local key, value = current:match('^([^:]+):(.+)$')
            if key and value then
                result[json.decode(key)] = json.decode(value)
            end
        end
        
        return result
    else
        error("Invalid JSON: " .. str)
    end
end

return json