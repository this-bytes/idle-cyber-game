-- Validator for src/data/soc_operations.lua
local Validator = {}

local function is_number(v)
    return type(v) == "number"
end

local function is_boolean(v)
    return type(v) == "boolean"
end

local function is_string(v)
    return type(v) == "string"
end

-- Validate passive operation definition (basic checks)
local function validate_passive(name, def)
    local errors = {}
    if type(def) ~= "table" then
        table.insert(errors, string.format("passiveOperations.%s must be a table", tostring(name)))
        return errors
    end
    if def.enabled == nil or not is_boolean(def.enabled) then
        table.insert(errors, string.format("passiveOperations.%s.enabled must be boolean", tostring(name)))
    end
    -- interval or baseRate should exist for time/periodic ops
    if def.interval == nil and def.baseRate == nil then
        table.insert(errors, string.format("passiveOperations.%s must include 'interval' or 'baseRate'", tostring(name)))
    end
    if def.interval ~= nil and not is_number(def.interval) then
        table.insert(errors, string.format("passiveOperations.%s.interval must be a number", tostring(name)))
    end
    if def.baseRate ~= nil and not is_number(def.baseRate) then
        table.insert(errors, string.format("passiveOperations.%s.baseRate must be a number", tostring(name)))
    end
    return errors
end

-- Validate automation level definition
local function validate_automation_level(key, lvl)
    local errors = {}
    if type(lvl) ~= "table" then
        table.insert(errors, string.format("automationLevels.%s must be a table", tostring(key)))
        return errors
    end
    if not is_string(lvl.name) then
        table.insert(errors, string.format("automationLevels.%s.name must be a string", tostring(key)))
    end
    if lvl.threatMonitoring == nil or not is_number(lvl.threatMonitoring) then
        table.insert(errors, string.format("automationLevels.%s.threatMonitoring must be a number (0-1)", tostring(key)))
    end
    if lvl.incidentResponse == nil or not is_number(lvl.incidentResponse) then
        table.insert(errors, string.format("automationLevels.%s.incidentResponse must be a number (0-1)", tostring(key)))
    end
    if lvl.resourceMultiplier == nil or not is_number(lvl.resourceMultiplier) then
        table.insert(errors, string.format("automationLevels.%s.resourceMultiplier must be a number (>0)", tostring(key)))
    end
    if not is_string(lvl.description) then
        table.insert(errors, string.format("automationLevels.%s.description must be a string", tostring(key)))
    end
    -- range checks
    if is_number(lvl.threatMonitoring) and (lvl.threatMonitoring < 0 or lvl.threatMonitoring > 1) then
        table.insert(errors, string.format("automationLevels.%s.threatMonitoring must be between 0 and 1", tostring(key)))
    end
    if is_number(lvl.incidentResponse) and (lvl.incidentResponse < 0 or lvl.incidentResponse > 1) then
        table.insert(errors, string.format("automationLevels.%s.incidentResponse must be between 0 and 1", tostring(key)))
    end
    if is_number(lvl.resourceMultiplier) and lvl.resourceMultiplier <= 0 then
        table.insert(errors, string.format("automationLevels.%s.resourceMultiplier must be > 0", tostring(key)))
    end
    return errors
end

-- Public validate function
function Validator.validate(soc_ops)
    local errors = {}
    if type(soc_ops) ~= "table" then
        return false, {"soc_operations must return a table"}
    end
    if type(soc_ops.passiveOperations) ~= "table" then
        table.insert(errors, "passiveOperations must be a table")
    else
        for name, def in pairs(soc_ops.passiveOperations) do
            local e = validate_passive(name, def)
            for _, msg in ipairs(e) do table.insert(errors, msg) end
        end
    end

    if type(soc_ops.automationLevels) ~= "table" then
        table.insert(errors, "automationLevels must be a table")
    else
        if soc_ops.automationLevels.MANUAL == nil then
            table.insert(errors, "automationLevels must include 'MANUAL' level")
        end
        for key, lvl in pairs(soc_ops.automationLevels) do
            local e = validate_automation_level(key, lvl)
            for _, msg in ipairs(e) do table.insert(errors, msg) end
        end
    end

    if #errors == 0 then
        return true, {}
    else
        return false, errors
    end
end

return Validator
