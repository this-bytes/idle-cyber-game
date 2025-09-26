-- Core definitions and enums for the game (centralized)
local json = require("dkjson")

local defs = {}
local dataPath = "src/data/defs.json"

local function loadFromJSON()
    if love and love.filesystem and love.filesystem.getInfo then
        if love.filesystem.getInfo(dataPath) then
            local s = love.filesystem.read(dataPath)
            local ok, t = pcall(function() return json.decode(s) end)
            if ok and type(t) == "table" then
                defs = t
                return true
            end
        end
    else
        local f = io.open(dataPath, "r")
        if f then
            local s = f:read("*a")
            f:close()
            local ok, t = pcall(function() return json.decode(s) end)
            if ok and type(t) == "table" then
                defs = t
                return true
            end
        end
    end
    return false
end

local function populateDefaults()
    defs = {}
    defs.Resources = {
        MONEY = "money",
        REPUTATION = "reputation",
        XP = "xp",
        MISSION_TOKENS = "missionTokens"
    }
    defs.Departments = {
        { id = "desk", name = "My Desk", x = 160, y = 120, radius = 18 },
        { id = "contracts", name = "Contracts", x = 80, y = 60, radius = 28 },
        { id = "research", name = "Research", x = 300, y = 60, radius = 28 },
        { id = "ops", name = "Operations", x = 520, y = 60, radius = 28 },
        { id = "hr", name = "HR", x = 80, y = 260, radius = 28 },
        { id = "training", name = "Training", x = 300, y = 260, radius = 28 },
        { id = "security", name = "Security", x = 520, y = 260, radius = 28 },
    }
    defs.GameModes = {
        IDLE = "idle",
        ADMIN = "admin",
    }
end

local ok = pcall(loadFromJSON)
if not ok or not next(defs) then
    populateDefaults()
end

-- Save current defs back to JSON
function defs.saveToJSON()
    local s = json.encode(defs)
    if love and love.filesystem and love.filesystem.write then
        love.filesystem.write(dataPath, s)
        return true
    else
        local f, err = io.open(dataPath, "w")
        if not f then return false, err end
        f:write(s)
        f:close()
        return true
    end
end

-- Expose reload function
function defs.reloadFromJSON()
    local ok, err = pcall(loadFromJSON)
    if not ok then
        return false, err
    end
    return true
end

return defs
