local SynergyDetector = {}
SynergyDetector.__index = SynergyDetector

function SynergyDetector.new(eventBus, itemRegistry)
    local self = setmetatable({}, SynergyDetector)
    self.eventBus = eventBus
    self.itemRegistry = itemRegistry
    self.previouslyActive = {}
    self.allSynergies = {}
    return self
end

function SynergyDetector:initialize()
    self.allSynergies = self.itemRegistry:getItemsByType("synergy")
end

function SynergyDetector:detectActiveSynergies(gameState)
    local active = {}
    for _, synergy in ipairs(self.allSynergies) do
        if self:checkConditions(synergy.conditions or {}, gameState) then
            table.insert(active, synergy)
            if not self.previouslyActive[synergy.id] then
                self.eventBus:publish("synergy_activated", { synergy = synergy, message = "🎭 SYNERGY: " .. (synergy.description or synergy.id) })
            end
        elseif self.previouslyActive[synergy.id] then
            self.eventBus:publish("synergy_deactivated", { synergy = synergy, message = "🎭 Synergy lost: " .. (synergy.description or synergy.id) })
        end
    end
    self.previouslyActive = {}
    for _, s in ipairs(active) do self.previouslyActive[s.id] = true end
    return active
end

function SynergyDetector:checkConditions(conditions, gameState)
    if not conditions then return true end
    if conditions.requires_all then for _, cond in ipairs(conditions.requires_all) do if not self:checkSingleCondition(cond, gameState) then return false end end end
    if conditions.requires_any then local any = false; for _, cond in ipairs(conditions.requires_any) do if self:checkSingleCondition(cond, gameState) then any = true; break end end; if not any then return false end end
    return true
end

function SynergyDetector:checkSingleCondition(condition, gameState)
    if condition.item_tag then
        local count = self:countItemsWithTag(condition.item_tag, condition.item_type, condition.state, gameState)
        local minCount = condition.min_count or 1
        if count < minCount then return false end
    end
    if condition.resource then
        local amount = gameState.resources and gameState.resources[condition.resource] or 0
        local required = condition.min_amount or 0
        if amount < required then return false end
    end
    if condition.stat then
        local value = gameState.stats and gameState.stats[condition.stat] or 0
        local required = condition.min_value or 0
        if value < required then return false end
    end
    if condition.achievement then
        local unlocked = gameState.achievements and gameState.achievements[condition.achievement] or false
        if not unlocked then return false end
    end
    return true
end

function SynergyDetector:countItemsWithTag(tag, itemType, state, gameState)
    local count = 0
    if (not itemType or itemType == "contract") and gameState.activeContracts then
        for _, contract in pairs(gameState.activeContracts) do
            local item = self.itemRegistry:getItem(contract.itemId or contract.id)
            if item and self:hasTag(item, tag) then count = count + 1 end
        end
    end
    if (not itemType or itemType == "specialist") and gameState.specialists then
        for _, specialist in pairs(gameState.specialists) do
            local item = self.itemRegistry:getItem(specialist.itemId or specialist.id)
            if item and self:hasTag(item, tag) then count = count + 1 end
        end
    end
    if (not itemType or itemType == "upgrade") and gameState.upgrades then
        for _, upgrade in pairs(gameState.upgrades) do
            local item = self.itemRegistry:getItem(upgrade.itemId or upgrade.id)
            if item and self:hasTag(item, tag) then count = count + 1 end
        end
    end
    return count
end

function SynergyDetector:hasTag(item, tag)
    if not item.tags then return false end
    for _, t in ipairs(item.tags) do if t == tag then return true end end
    return false
end

function SynergyDetector:getActiveSynergiesAsEffectItems(gameState)
    local active = self:detectActiveSynergies(gameState)
    local items = {}
    for _, s in ipairs(active) do table.insert(items, s) end
    return items
end

return SynergyDetector
