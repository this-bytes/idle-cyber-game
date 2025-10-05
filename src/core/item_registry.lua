-- ItemRegistry - Universal item loading and validation system
-- Loads all game items from JSON and provides unified access
-- Part of the AWESOME Backend Architecture

local ItemRegistry = {}
ItemRegistry.__index = ItemRegistry

function ItemRegistry.new(dataManager)
    local self = setmetatable({}, ItemRegistry)
    self.dataManager = dataManager
    
    -- Item storage by type
    self.items = {
        contract = {},
        specialist = {},
        upgrade = {},
        threat = {},
        event = {},
        synergy = {}
    }
    
    -- Quick lookup by ID (across all types)
    self.itemsById = {}
    
    -- Tags index for fast queries
    self.itemsByTag = {}
    
    return self
end

-- Loads all items and builds indices
function ItemRegistry:initialize()
    print("🗂️ Initializing Item Registry...")
    
    -- Load all item types
    self:loadItemType("contracts", "contract")
    self:loadItemType("specialists", "specialist")
    self:loadItemType("upgrades", "upgrade")
    self:loadItemType("threats", "threat")
    self:loadItemType("events", "event")
    self:loadItemType("synergies", "synergy")
    
    -- Build indices
    self:buildIndices()
    
    print("✅ Item Registry initialized with " .. self:getTotalItemCount() .. " items")
end

-- Loads all items of a specific type from a data file
function ItemRegistry:loadItemType(dataKey, itemType)
    local data = self.dataManager:getData(dataKey)
    
    if not data then
        print("⚠️ No data found for: " .. dataKey)
        return
    end
    
    -- Handle different data structures
    local items = data
    if type(data) == "table" and data[dataKey] then
        items = data[dataKey]
    end
    
    if type(items) ~= "table" then
        print("⚠️ Invalid data structure for: " .. dataKey)
        return
    end
    
    -- Load each item
    local count = 0
    for key, itemData in pairs(items) do
        -- Handle both array and table structures
        if type(itemData) == "table" then
            -- Ensure type is set
            itemData.type = itemData.type or itemType
            
            -- If no id, use the key
            if not itemData.id then
                itemData.id = key
            end
            
            -- Validate and register
            if self:validateItem(itemData) then
                self:registerItem(itemData)
                count = count + 1
            end
        end
    end
    
    print("  📄 Loaded " .. count .. " " .. itemType .. " items")
end

-- Validates a single item's data
function ItemRegistry:validateItem(item)
    -- Forwarder: src.core.item_registry -> src.systems.item_registry
    return require("src.systems.item_registry")
end
-- Get a single item by its unique ID
function ItemRegistry:getItem(id)
    return self.itemsById[id]
end

-- Get all items of a specific type
function ItemRegistry:getItemsByType(itemType)
    return self.items[itemType] or {}
end

-- Get all items with a specific tag
function ItemRegistry:getItemsByTag(tag)
    return self.itemsByTag[tag] or {}
end

-- Performs a complex query on all items using a filter table
function ItemRegistry:queryItems(filter)
    local results = {}
    
    for id, item in pairs(self.itemsById) do
        if self:matchesFilter(item, filter) then
            table.insert(results, item)
        end
    end
    
    return results
end

-- Helper function to check if an item matches a filter
function ItemRegistry:matchesFilter(item, filter)
    -- Type filter
    if filter.type and item.type ~= filter.type then
        return false
    end
    
    -- Tag filter (requires ALL tags)
    if filter.tags then
        if not item.tags then return false end
        for _, requiredTag in ipairs(filter.tags) do
            local hasTag = false
            for _, itemTag in ipairs(item.tags) do
                if itemTag == requiredTag then
                    hasTag = true
                    break
                end
            end
            if not hasTag then return false end
        end
    end
    
    -- Rarity filter
    if filter.rarity and item.rarity ~= filter.rarity then
        return false
    end
    
    -- Tier filter
    if filter.tier and item.tier ~= filter.tier then
        return false
    end
    
    return true
end

-- Get the total number of items in the registry
function ItemRegistry:getTotalItemCount()
    local count = 0
    for id, _ in pairs(self.itemsById) do
        count = count + 1
    end
    return count
end

-- Get a summary of item counts by type
function ItemRegistry:getStats()
    local stats = {
        total = self:getTotalItemCount(),
        byType = {}
    }
    
    for itemType, items in pairs(self.items) do
        stats.byType[itemType] = #items
    end
    
    return stats
end

return ItemRegistry
