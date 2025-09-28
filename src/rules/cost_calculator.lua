-- Cost Calculator Interface - Rules Engine Component
-- Configurable interface for key gameplay rules (cost calculation)
-- Architected for future binding to external data/config formats

local CostCalculator = {}
CostCalculator.__index = CostCalculator

-- Create new cost calculator
function CostCalculator.new()
    local self = setmetatable({}, CostCalculator)
    
    -- Cost calculation rules (placeholder interfaces)
    self.baseCosts = {}
    self.scalingFactors = {}
    self.modifiers = {}
    
    return self
end

-- Interface: Calculate base cost for an item/upgrade
function CostCalculator:calculateBaseCost(itemType, itemId)
    -- TODO: Load from external data/config
    -- Placeholder implementation
    
    local baseCost = self.baseCosts[itemType] and self.baseCosts[itemType][itemId]
    if baseCost then
        return baseCost
    end
    
    -- Default fallback costs
    local defaults = {
        upgrade = 100,
        specialist = 500,
        facility = 1000
    }
    
    return defaults[itemType] or 100
end

-- Interface: Calculate scaled cost based on current level/count
function CostCalculator:calculateScaledCost(itemType, itemId, currentLevel)
    local baseCost = self:calculateBaseCost(itemType, itemId)
    local scalingFactor = self:getScalingFactor(itemType, itemId)
    
    -- Standard exponential scaling: baseCost * (scalingFactor ^ currentLevel)
    return math.floor(baseCost * math.pow(scalingFactor, currentLevel or 0))
end

-- Interface: Get scaling factor for cost progression
function CostCalculator:getScalingFactor(itemType, itemId)
    -- TODO: Load from external config
    -- Placeholder implementation
    
    if self.scalingFactors[itemType] and self.scalingFactors[itemType][itemId] then
        return self.scalingFactors[itemType][itemId]
    end
    
    -- Default scaling factors
    local defaults = {
        upgrade = 1.5,
        specialist = 1.8,
        facility = 2.0
    }
    
    return defaults[itemType] or 1.5
end

-- Interface: Apply cost modifiers (discounts, penalties)
function CostCalculator:applyModifiers(baseCost, modifierContext)
    local finalCost = baseCost
    
    -- TODO: Implement modifier system from external config
    -- Placeholder for modifier application
    
    if modifierContext then
        -- Example: reputation discount
        if modifierContext.reputation then
            local discount = math.min(0.3, modifierContext.reputation * 0.001) -- Max 30% discount
            finalCost = finalCost * (1 - discount)
        end
        
        -- Example: bulk purchase discount
        if modifierContext.quantity and modifierContext.quantity > 1 then
            local bulkDiscount = math.min(0.2, (modifierContext.quantity - 1) * 0.05)
            finalCost = finalCost * (1 - bulkDiscount)
        end
    end
    
    return math.floor(finalCost)
end

-- Interface: Calculate total cost with all factors
function CostCalculator:calculateTotalCost(itemType, itemId, options)
    options = options or {}
    
    local currentLevel = options.currentLevel or 0
    local quantity = options.quantity or 1
    local modifierContext = options.modifierContext or {}
    
    local scaledCost = self:calculateScaledCost(itemType, itemId, currentLevel)
    local costWithModifiers = self:applyModifiers(scaledCost, modifierContext)
    
    return costWithModifiers * quantity
end

-- Configuration methods (for future data-driven binding)

-- Set base cost for an item
function CostCalculator:setBaseCost(itemType, itemId, cost)
    if not self.baseCosts[itemType] then
        self.baseCosts[itemType] = {}
    end
    self.baseCosts[itemType][itemId] = cost
end

-- Set scaling factor for an item
function CostCalculator:setScalingFactor(itemType, itemId, factor)
    if not self.scalingFactors[itemType] then
        self.scalingFactors[itemType] = {}
    end
    self.scalingFactors[itemType][itemId] = factor
end

-- Add cost modifier rule
function CostCalculator:addModifier(modifierId, modifierRule)
    self.modifiers[modifierId] = modifierRule
end

-- Remove cost modifier rule
function CostCalculator:removeModifier(modifierId)
    self.modifiers[modifierId] = nil
end

-- Load cost rules from external data (placeholder for future implementation)
function CostCalculator:loadFromConfig(configData)
    -- TODO: Implement data loading from JSON/external format
    -- This is where external data/config binding would happen
    
    if configData.baseCosts then
        self.baseCosts = configData.baseCosts
    end
    
    if configData.scalingFactors then
        self.scalingFactors = configData.scalingFactors
    end
    
    if configData.modifiers then
        self.modifiers = configData.modifiers
    end
end

return CostCalculator