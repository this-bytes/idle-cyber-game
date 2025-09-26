-- Contract templates registry
-- Central place to define contract templates and helpers to instantiate them

local Contracts = {}

-- Internal templates table (populated from JSON or defaults)
local templates = {}

local json = require("dkjson")

local dataPath = "src/data/contracts.json"

-- Helper: try to load templates from JSON file in project
local function loadTemplatesFromJSON()
    if love and love.filesystem and love.filesystem.getInfo then
        -- In LÖVE runtime, prefer love.filesystem
        if love.filesystem.getInfo(dataPath) then
            local s = love.filesystem.read(dataPath)
            local ok, t = pcall(function() return json.decode(s) end)
            if ok and type(t) == "table" then
                templates = {}
                for _, entry in ipairs(t) do
                    if entry.id then templates[entry.id] = entry end
                end
                return true
            end
        end
    else
        -- Fallback to standard io
        local f = io.open(dataPath, "r")
        if f then
            local s = f:read("*a")
            f:close()
            local ok, t = pcall(function() return json.decode(s) end)
            if ok and type(t) == "table" then
                templates = {}
                for _, entry in ipairs(t) do
                    if entry.id then templates[entry.id] = entry end
                end
                return true
            end
        end
    end
    return false
end

-- If JSON not available, populate defaults (compat)
local function populateDefaultTemplates()
    templates = {
        basic_small_business = {
            id = "basic_small_business",
            clientName = "Small Business",
            description = "Provide basic security audit and recommendations.",
            baseBudget = 100,
            baseDuration = 30,
            reputationReward = 1,
            riskLevel = "LOW",
            requiredResources = {},
        },
        tech_startup = {
            id = "tech_startup",
            clientName = "Tech Startup",
            description = "Implement a lightweight WAF and incident response plan.",
            baseBudget = 400,
            baseDuration = 60,
            reputationReward = 2,
            riskLevel = "MEDIUM",
            requiredResources = {},
        },
        enterprise_contract = {
            id = "enterprise_contract",
            clientName = "Enterprise Corp",
            description = "Enterprise security overhaul with training and long-term monitoring.",
            baseBudget = 5000,
            baseDuration = 300,
            reputationReward = 20,
            riskLevel = "HIGH",
            requiredResources = {},
        }
    }
end

-- Attempt to load JSON; otherwise set defaults
local loaded = pcall(loadTemplatesFromJSON)
if not loaded or not next(templates) then
    populateDefaultTemplates()
end

-- Expose a reload function to re-read JSON at runtime
function Contracts.reloadFromJSON()
    local ok, err = pcall(loadTemplatesFromJSON)
    if not ok then
        return false, err
    end
    return true
end

-- Return list of all templates
function Contracts.getTemplates()
    local list = {}
    for k, t in pairs(templates) do table.insert(list, t) end
    return list
end

-- Get a single template by id
function Contracts.getTemplate(id)
    return templates[id]
end

-- Instantiate a contract from template with optional scaling parameters
-- scale: number (multiplier for budget/duration), overrides: table for any fields
function Contracts.instantiate(id, scale, overrides)
    local t = templates[id]
    if not t then return nil, "Unknown template id: " .. tostring(id) end
    scale = scale or 1.0
    overrides = overrides or {}

    local contract = {
        id = overrides.id or (t.id .. "_" .. tostring(math.floor(love.timer.getTime()))) ,
        templateId = t.id,
        clientName = overrides.clientName or t.clientName,
        description = overrides.description or t.description,
        totalBudget = overrides.totalBudget or math.floor(t.baseBudget * scale),
        originalDuration = overrides.originalDuration or math.floor(t.baseDuration * scale),
        remainingTime = overrides.remainingTime or math.floor(t.baseDuration * scale),
        reputationReward = overrides.reputationReward or t.reputationReward,
        riskLevel = overrides.riskLevel or t.riskLevel,
        requirement = overrides.requirement or t.requiredResources or {},
        started = false,
    }
    return contract
end

-- Register a new template at runtime (useful for mods / config)
function Contracts.registerTemplate(template)
    if not template or not template.id then return false, "Template must include an id" end
    templates[template.id] = template
    return true
end

-- Save current templates back to JSON (useful for editor/backend)
function Contracts.saveToJSON()
    local arr = {}
    for id, t in pairs(templates) do
        table.insert(arr, t)
    end
    local s = json.encode(arr, { indent = true })

    -- Try love.filesystem first
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

return Contracts
