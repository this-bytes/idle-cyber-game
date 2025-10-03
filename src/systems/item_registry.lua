-- ItemRegistry (systems copy)
local ItemRegistry = {}
ItemRegistry.__index = ItemRegistry

function ItemRegistry.new(dataManager)
    local self = setmetatable({}, ItemRegistry)
    self.dataManager = dataManager
    self.items = { contract = {}, specialist = {}, upgrade = {}, threat = {}, event = {}, synergy = {} }
    self.itemsById = {}
    self.itemsByTag = {}
    return self
end

function ItemRegistry:initialize()
    self:loadItemType("contracts", "contract")
    self:loadItemType("specialists", "specialist")
    self:loadItemType("upgrades", "upgrade")
    self:loadItemType("threats", "threat")
    self:loadItemType("events", "event")
    self:loadItemType("synergies", "synergy")
    self:buildIndices()
end

function ItemRegistry:loadItemType(dataKey, itemType)
    local data = self.dataManager:getData(dataKey)
    if not data then return end
    local items = data
    if type(data) == "table" and data[dataKey] then items = data[dataKey] end
    if type(items) ~= "table" then return end
    for key, itemData in pairs(items) do
        if type(itemData) == "table" then
            itemData.type = itemData.type or itemType
            if not itemData.id then itemData.id = key end
            if self:validateItem(itemData) then self:registerItem(itemData) end
        end
    end
end

function ItemRegistry:validateItem(item)
    if not item.id then return false end
    if not item.type then return false end
    if self.itemsById[item.id] then return false end
    return true
end

function ItemRegistry:registerItem(item)
    if not self.items[item.type] then self.items[item.type] = {} end
    table.insert(self.items[item.type], item)
    self.itemsById[item.id] = item
end

function ItemRegistry:buildIndices()
    self.itemsByTag = {}
    for id, item in pairs(self.itemsById) do
        if item.tags then
            for _, tag in ipairs(item.tags) do
                if not self.itemsByTag[tag] then self.itemsByTag[tag] = {} end
                table.insert(self.itemsByTag[tag], item)
            end
        end
    end
end

function ItemRegistry:getItem(id) return self.itemsById[id] end
function ItemRegistry:getItemsByType(t) return self.items[t] or {} end
function ItemRegistry:getItemsByTag(tag) return self.itemsByTag[tag] or {} end
function ItemRegistry:queryItems(filter)
    local results = {}
    for id, item in pairs(self.itemsById) do if self:matchesFilter(item, filter) then table.insert(results, item) end end
    return results
end

function ItemRegistry:matchesFilter(item, filter)
    if not filter then return true end
    if filter.type and item.type ~= filter.type then return false end
    if filter.tags then
        if not item.tags then return false end
        for _, requiredTag in ipairs(filter.tags) do
            local hasTag = false
            for _, itemTag in ipairs(item.tags) do if itemTag == requiredTag then hasTag = true break end end
            if not hasTag then return false end
        end
    end
    if filter.rarity and item.rarity ~= filter.rarity then return false end
    if filter.tier and item.tier ~= filter.tier then return false end
    return true
end

function ItemRegistry:getTotalItemCount()
    local count = 0
    for id, _ in pairs(self.itemsById) do count = count + 1 end
    return count
end

function ItemRegistry:getStats()
    local stats = { total = self:getTotalItemCount(), byType = {} }
    for itemType, items in pairs(self.items) do stats.byType[itemType] = #items end
    return stats
end

return ItemRegistry
