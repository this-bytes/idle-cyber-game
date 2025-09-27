-- Minimal ProgressionSystem - single atomic file
local json = require("dkjson")

local ProgressionSystem = {}
ProgressionSystem.__index = ProgressionSystem

local function read_json(path)
    local content
    if type(love) == "table" and love.filesystem and love.filesystem.getInfo then
        if love.filesystem.getInfo(path) then content = love.filesystem.read(path) end
    else
        local f = io.open(path, "r")
        if f then content = f:read("*a"); f:close() end
    end
    if not content then return nil end
    local ok, data = pcall(function() return json.decode(content) end)
    if ok and type(data) == "table" then return data end
    return nil
end

function ProgressionSystem.new(eventBus, resourceSystem)
    local self = setmetatable({}, ProgressionSystem)
    self.eventBus = eventBus
    self.resourceSystem = resourceSystem

    self.config = read_json("src/data/progression.json") or {}
    self.currencies = {}
    self.currentTier = "startup"
    self.completedMilestones = {}
    self.totalStats = { totalEarnings = 0, contractsCompleted = 0 }
    self.achievements = {}
    self.statistics = { rooms_visited = {}, contracts_completed = 0 }

    for _, category in pairs(self.config.currencies or {}) do
        for id, cur in pairs(category) do
            self.currencies[id] = { amount = cur.startingAmount or 0, totalEarned = 0, totalSpent = 0, config = cur }
            if self.resourceSystem and self.resourceSystem.setResource then
                self.resourceSystem:setResource(id, self.currencies[id].amount)
            end
        end
    end

    if self.eventBus and self.eventBus.subscribe then self:subscribeToEvents() end
    return self
end

function ProgressionSystem:subscribeToEvents()
    if not self.eventBus then return end
    self.eventBus:subscribe("resource_earned", function(data) self:onResourceEarned(data.resource, data.amount) end)
    self.eventBus:subscribe("resource_spent", function(data) self:onResourceSpent(data.resource, data.amount) end)
    self.eventBus:subscribe("location_changed", function(data) self:onLocationChanged(data) end)
    self.eventBus:subscribe("contract_completed", function(data) self:onContractCompleted(data) end)
end

function ProgressionSystem:onResourceEarned(resource, amount)
    if resource == "money" then self.totalStats.totalEarnings = self.totalStats.totalEarnings + amount end
    if self.currencies[resource] then self:awardCurrency(resource, amount) end
end

function ProgressionSystem:onResourceSpent(resource, amount)
    if resource == "money" then self.totalStats.totalSpent = (self.totalStats.totalSpent or 0) + amount end
end

function ProgressionSystem:onLocationChanged(data)
    local key = (data.newBuilding or "") .. "/" .. (data.newFloor or "") .. "/" .. (data.newRoom or "")
    self.statistics.rooms_visited[key] = (self.statistics.rooms_visited[key] or 0) + 1
end

function ProgressionSystem:onContractCompleted(data)
    self.statistics.contracts_completed = self.statistics.contracts_completed + 1
    self.totalStats.contractsCompleted = (self.totalStats.contractsCompleted or 0) + 1
    local baseExp = data and data.experience or 50
    local baseRep = data and data.reputation or 5
    if self.resourceSystem and self.resourceSystem.addResource then
        self.resourceSystem:addResource("xp", baseExp)
        self.resourceSystem:addResource("reputation", baseRep)
    end
end

function ProgressionSystem:getCurrency(id) return (self.currencies[id] and self.currencies[id].amount) or 0 end

function ProgressionSystem:awardCurrency(id, amount)
    if not self.currencies[id] then return false end
    local cur = self.currencies[id]
    local cfg = cur.config or {}
    if cfg.maxStorage and cfg.maxStorage > 0 then amount = math.min(amount, cfg.maxStorage - cur.amount) end
    if amount <= 0 then return false end
    cur.amount = cur.amount + amount
    cur.totalEarned = cur.totalEarned + amount
    if self.eventBus and self.eventBus.publish then self.eventBus:publish("currency_awarded", {currency = id, amount = amount, total = cur.amount}) end
    return true
end

function ProgressionSystem:spendCurrency(id, amount)
    if not self.currencies[id] then return false end
    local cur = self.currencies[id]
    if cur.config and cur.config.canSpend == false then return false end
    if cur.amount < amount then return false end
    cur.amount = cur.amount - amount
    cur.totalSpent = cur.totalSpent + amount
    if self.eventBus and self.eventBus.publish then self.eventBus:publish("currency_spent", {currency = id, amount = amount, remaining = cur.amount}) end
    return true
end

function ProgressionSystem:canAfford(costs)
    for k,v in pairs(costs or {}) do if self:getCurrency(k) < v then return false end end
    return true
end

function ProgressionSystem:spendMultiple(costs)
    if not self:canAfford(costs) then return false end
    for k,v in pairs(costs) do self:spendCurrency(k, v) end
    return true
end

function ProgressionSystem:checkMilestones()
    for id, milestone in pairs(self.config.milestones or {}) do
        if not self.completedMilestones[id] and self:isMilestoneComplete(milestone) then
            self:completeMilestone(id, milestone)
        end
    end
end

function ProgressionSystem:isMilestoneComplete(milestone)
    for req, val in pairs(milestone.requirements or {}) do
        local cur = 0
        if req == "totalEarnings" then cur = self.totalStats.totalEarnings
        elseif req == "contractsCompleted" then cur = self.totalStats.contractsCompleted
        elseif self.currencies[req] then cur = self.currencies[req].amount
        end
        if cur < val then return false end
    end
    return true
end

function ProgressionSystem:completeMilestone(id, milestone)
    self.completedMilestones[id] = true
    if milestone.rewards then for k,v in pairs(milestone.rewards) do self:awardCurrency(k, v) end end
    if self.eventBus and self.eventBus.publish then self.eventBus:publish("milestone_completed", {id = id, milestone = milestone}) end
end

function ProgressionSystem:getState()
    return { currencies = self.currencies, currentTier = self.currentTier, prestigeLevel = self.prestigeLevel, prestigePoints = self.prestigePoints, completedMilestones = self.completedMilestones, totalStats = self.totalStats, dailyConversions = self.dailyConversions, achievements = self.achievements, statistics = self.statistics }
end

function ProgressionSystem:setState(state)
    if not state then return end
    if state.currencies then for id,data in pairs(state.currencies) do if self.currencies[id] then self.currencies[id].amount = data.amount or self.currencies[id].amount; self.currencies[id].totalEarned = data.totalEarned or self.currencies[id].totalEarned; self.currencies[id].totalSpent = data.totalSpent or self.currencies[id].totalSpent end end end
    self.currentTier = state.currentTier or self.currentTier
    self.prestigeLevel = state.prestigeLevel or self.prestigeLevel
    self.prestigePoints = state.prestigePoints or self.prestigePoints
    self.completedMilestones = state.completedMilestones or self.completedMilestones
    self.totalStats = state.totalStats or self.totalStats
    self.dailyConversions = state.dailyConversions or self.dailyConversions
    self.achievements = state.achievements or self.achievements
    self.statistics = state.statistics or self.statistics
end

function ProgressionSystem:update(dt) self:checkMilestones() end

function ProgressionSystem:getAchievements() return self.achievements end
function ProgressionSystem:getStatistics() return self.statistics end
function ProgressionSystem:getCurrencyCount() local c=0 for _ in pairs(self.currencies) do c=c+1 end return c end
function ProgressionSystem:getTierCount() local c=0 for _ in pairs(self.config.progressionTiers or {}) do c=c+1 end return c end
function ProgressionSystem:getCurrentTier() return self.config.progressionTiers and (self.config.progressionTiers[self.currentTier] or {}) or {} end

-- Compatibility shims used by game/tests
function ProgressionSystem:loadState(state)
    return self:setState(state)
end

function ProgressionSystem:unlockAchievement(id)
    if not id then return end
    self.achievements[id] = true
    if self.eventBus and self.eventBus.publish then
        self.eventBus:publish("achievement_unlocked", { id = id })
    end
end

function ProgressionSystem:getAllCurrencies()
    return self.currencies
end

function ProgressionSystem:getCurrentTierLevel()
    if not (self.config and self.config.progressionTiers and self.currentTier) then return 1 end
    local tier = self.config.progressionTiers[self.currentTier]
    return (tier and tier.level) or 1
end

function ProgressionSystem:canPrestige()
    -- Simple default: disabled unless config enables it
    if not self.config or not self.config.prestigeSystem then return false end
    return self.config.prestigeSystem.enabled == true
end

function ProgressionSystem:calculatePrestigePoints()
    -- Basic placeholder calculation based on total earnings
    return math.floor((self.totalStats.totalEarnings or 0) / 10000)
end

function ProgressionSystem:performPrestige()
    if not self:canPrestige() then return false end
    local pts = self:calculatePrestigePoints()
    self.prestigeLevel = (self.prestigeLevel or 0) + 1
    self.prestigePoints = (self.prestigePoints or 0) + pts
    return true
end

function ProgressionSystem:convertCurrency(convId)
    -- Placeholder: no conversions supported in minimal implementation
    return false
end

return ProgressionSystem