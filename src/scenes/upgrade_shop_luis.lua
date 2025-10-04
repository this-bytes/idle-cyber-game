--[[
    Upgrade Shop Scene
    This is a self-contained scene file that follows the original, working architecture.
]]

local UpgradeShopScene = {}
UpgradeShopScene.__index = UpgradeShopScene

function UpgradeShopScene.new(eventBus, luis, systems)
    local self = setmetatable({}, UpgradeShopScene)
    self.eventBus = eventBus
    self.luis = luis
    self.systems = systems
    self.layerName = "upgrade_shop"

    local cyberpunkTheme = {
        textColor = {0, 1, 180/255, 1},                      
        bgColor = {10/255, 25/255, 20/255, 0.8},            
        borderColor = {0, 1, 180/255, 0.4},                 
        borderWidth = 1,
        hoverTextColor = {20/255, 30/255, 25/255, 1},       
        hoverBgColor = {0, 1, 180/255, 1},                    
        hoverBorderColor = {0, 1, 180/255, 1},
        activeTextColor = {20/255, 30/255, 25/255, 1},
        activeBgColor = {0.8, 1, 1, 1},                       
        activeBorderColor = {0.8, 1, 1, 1},
        Label = { textColor = {0, 1, 180/255, 0.9} },
        disabledTextColor = {0.5, 0.5, 0.5, 0.5},
        disabledBgColor = {0.1, 0.1, 0.1, 0.5},
        disabledBorderColor = {0.3, 0.3, 0.3, 0.5},
    }
    if self.luis.setTheme then
        self.luis.setTheme(cyberpunkTheme)
    end

    self.upgrades = {}
    self.categories = {}
    return self
end

function UpgradeShopScene:load(data)
    self.luis.newLayer(self.layerName)
    self.luis.setCurrentLayer(self.layerName)
    self:updateUpgrades()
end

function UpgradeShopScene:exit()
    if self.luis.isLayerEnabled(self.layerName) then
        self.luis.disableLayer(self.layerName)
    end
end

function UpgradeShopScene:updateUpgrades()
    if self.systems and self.systems.upgradeSystem and self.systems.upgradeSystem.getVisibleUpgrades then
        self.upgrades = self.systems.upgradeSystem:getVisibleUpgrades()
        self:categorizeUpgrades()
    else
        self.upgrades = {}
    end
    self:rebuildUI()
end

function UpgradeShopScene:categorizeUpgrades()
    self.categories = {}
    for _, upgrade in ipairs(self.upgrades) do
        local cat = upgrade.category or "uncategorized"
        if not self.categories[cat] then
            self.categories[cat] = {}
        end
        table.insert(self.categories[cat], upgrade)
    end
end

function UpgradeShopScene:rebuildUI()
    if not self.luis then return end
    self.luis.removeLayer(self.layerName)
    self.luis.newLayer(self.layerName)
    self.luis.setCurrentLayer(self.layerName)
    self:buildUI()
end

function UpgradeShopScene:buildUI()
    local luis = self.luis
    local numCols = math.floor(love.graphics.getWidth() / luis.gridSize)

    luis.insertElement(self.layerName, luis.newLabel("UPGRADE SHOP", numCols, 3, 2, 1, "center"))
    luis.insertElement(self.layerName, luis.newButton("< BACK", 15, 3, function() 
        self.eventBus:publish("request_scene_change", {scene = "soc_view"}) 
    end, nil, 2, 3))

    if not self.upgrades or #self.upgrades == 0 then
        luis.insertElement(self.layerName, luis.newLabel("No upgrades available.", numCols, 3, 10, 1, "center"))
    else
        self:buildUpgradeList()
    end
end

function UpgradeShopScene:buildUpgradeList()
    local luis = self.luis
    local numCols = math.floor(love.graphics.getWidth() / luis.gridSize)
    local cardWidth = numCols - 10
    local cardCol = 6
    local currentRow = 6

    for categoryName, upgradesInCategory in pairs(self.categories) do
        luis.insertElement(self.layerName, luis.newLabel(string.upper(categoryName), cardWidth, 2, currentRow, cardCol, "left"))
        currentRow = currentRow + 2

        for _, upgrade in ipairs(upgradesInCategory) do
            local canAfford = self.systems.resourceManager:hasSufficientResources(upgrade.cost)
            local isPurchased = self.systems.upgradeSystem:isPurchased(upgrade.id)

            luis.insertElement(self.layerName, luis.newLabel(upgrade.displayName, cardWidth, 1, currentRow, cardCol, "left"))
            currentRow = currentRow + 1
            luis.insertElement(self.layerName, luis.newLabel(upgrade.description, cardWidth, 2, currentRow, cardCol, "left"))
            currentRow = currentRow + 2
            local costString = "Cost: "
            for currency, amount in pairs(upgrade.cost) do
                costString = costString .. amount .. " " .. currency .. " "
            end
            luis.insertElement(self.layerName, luis.newLabel(costString, cardWidth, 1, currentRow, cardCol, "left"))
            
            local buttonText = isPurchased and "PURCHASED" or "PURCHASE"
            local purchaseButton = luis.newButton(buttonText, 20, 2, function() 
                if not isPurchased and canAfford then
                    self.systems.upgradeSystem:purchaseUpgrade(upgrade.id)
                    self:updateUpgrades()
                end
            end, nil, currentRow - 1, cardCol + cardWidth - 22)
            
            if isPurchased or not canAfford then
                purchaseButton:setDisabled(true)
            end
            luis.insertElement(self.layerName, purchaseButton)

            currentRow = currentRow + 3
        end
    end
end

function UpgradeShopScene:draw()
    love.graphics.clear(0.05, 0.05, 0.1, 1.0)
end

function UpgradeShopScene:update(dt) end
function UpgradeShopScene:keypressed(key) end
function UpgradeShopScene:mousepressed(x, y, button) end

return UpgradeShopScene
