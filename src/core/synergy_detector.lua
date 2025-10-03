-- SynergyDetector - Detects and activates synergies between game items
-- Creates emergent gameplay through item combinations
-- Part of the AWESOME Backend Architecture

local SynergyDetector = {}
SynergyDetector.__index = SynergyDetector

function SynergyDetector.new(eventBus, itemRegistry)
    local self = setmetatable({}, SynergyDetector)
    self.eventBus = eventBus
    self.itemRegistry = itemRegistry
    
    -- Track previously active synergies
    self.previouslyActive = {}
    
    -- All synergy definitions
    self.allSynergies = {}
    
    return self
end

function SynergyDetector:initialize()
    print("🎭 Initializing Synergy Detector...")
    
    -- Load synergy definitions from registry
    self.allSynergies = self.itemRegistry:getItemsByType("synergy")
    
    print("✅ Synergy Detector initialized with " .. #self.allSynergies .. " synergies")
end

function SynergyDetector:detectActiveSynergies(gameState)
    local active = {}
    
    for _, synergy in ipairs(self.allSynergies) do
        if self:checkConditions(synergy.conditions or {}, gameState) then
            table.insert(active, synergy)
            
            -- Publish event for newly activated synergies
            if not self.previouslyActive[synergy.id] then
                self.eventBus:publish("synergy_activated", {
                    synergy = synergy,
                    message = "🎭 SYNERGY: " .. (synergy.description or synergy.id)
                })
                print("🎭 Synergy activated: " .. (synergy.description or synergy.id))
            end
        elseif self.previouslyActive[synergy.id] then
            -- Synergy deactivated
            self.eventBus:publish("synergy_deactivated", {
                synergy = synergy,
                message = "🎭 Synergy lost: " .. (synergy.description or synergy.id)
            })
        end
    end
    
    -- Update tracking
    self.previouslyActive = {}
    for _, synergy in ipairs(active) do
        self.previouslyActive[synergy.id] = true
    end
    
    return active
end

function SynergyDetector:checkConditions(conditions, gameState)
    if not conditions then return true end
    
    -- Check "requires_all" conditions
    if conditions.requires_all then
        for _, condition in ipairs(conditions.requires_all) do
            if not self:checkSingleCondition(condition, gameState) then
                return false
            end
        end
    end
    
    -- Check "requires_any" conditions
    if conditions.requires_any then
        local anyMet = false
        for _, condition in ipairs(conditions.requires_any) do
            if self:checkSingleCondition(condition, gameState) then
                anyMet = true
                break
            end
        end
        if not anyMet then return false end
    end
    
    return true
end

function SynergyDetector:checkSingleCondition(condition, gameState)
    -- Item tag condition
    if condition.item_tag then
        local count = self:countItemsWithTag(
            condition.item_tag,
            condition.item_type,
            condition.state,
            -- Forwarder: src.core.synergy_detector -> src.systems.synergy_detector
            return require("src.systems.synergy_detector")
        end
    end
    
    -- Achievement condition
    if condition.achievement then
        local unlocked = gameState.achievements and 
                        gameState.achievements[condition.achievement] or false
        if not unlocked then
            return false
        end
    end
    
    return true
end

function SynergyDetector:countItemsWithTag(tag, itemType, state, gameState)
    local count = 0
    
    -- Count active contracts
    if (not itemType or itemType == "contract") and gameState.activeContracts then
        for _, contract in pairs(gameState.activeContracts) do
            local item = self.itemRegistry:getItem(contract.itemId or contract.id)
            if item and self:hasTag(item, tag) then
                if not state or state == "active" then
                    count = count + 1
                end
            end
        end
    end
    
    -- Count specialists
    if (not itemType or itemType == "specialist") and gameState.specialists then
        for _, specialist in pairs(gameState.specialists) do
            local item = self.itemRegistry:getItem(specialist.itemId or specialist.id)
            if item and self:hasTag(item, tag) then
                if not state or 
                   (state == "active" and specialist.assigned) or
                   (state == "available" and not specialist.assigned) then
                    count = count + 1
                end
            end
        end
    end
    
    -- Count upgrades
    if (not itemType or itemType == "upgrade") and gameState.upgrades then
        for _, upgrade in pairs(gameState.upgrades) do
            local item = self.itemRegistry:getItem(upgrade.itemId or upgrade.id)
            if item and self:hasTag(item, tag) then
                if not state or state == "purchased" then
                    count = count + 1
                end
            end
        end
    end
    
    return count
end

function SynergyDetector:hasTag(item, tag)
    if not item.tags then return false end
    
    for _, itemTag in ipairs(item.tags) do
        if itemTag == tag then
            return true
        end
    end
    
    return false
end

-- Get all currently active synergies as effect items
function SynergyDetector:getActiveSynergiesAsEffectItems(gameState)
    local activeSynergies = self:detectActiveSynergies(gameState)
    local effectItems = {}
    
    for _, synergy in ipairs(activeSynergies) do
        -- Synergies are items with effects, so they can be used directly
        table.insert(effectItems, synergy)
    end
    
    return effectItems
end

return SynergyDetector
