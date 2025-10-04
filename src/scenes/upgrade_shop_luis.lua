-- Upgrade Shop Scene - SOC Security Infrastructure Management (LUIS Version)
-- Allows purchasing and managing cybersecurity upgrades for the SOC
-- Migrated to LUIS (Love UI System) - Simplified functional version

local UpgradeShopLuis = {}
UpgradeShopLuis.__index = UpgradeShopLuis

function UpgradeShopLuis.new(eventBus, luis)
    local self = setmetatable({}, UpgradeShopLuis)
    
    self.eventBus = eventBus
    self.luis = luis
    self.layerName = "upgrade_shop"
    self.resourceManager = nil
    self.securityUpgrades = nil
    
    -- Shop state
    self.selectedCategory = 1
    self.selectedUpgrade = 1
    self.categories = {
        {name = "Infrastructure", key = "infrastructure"},
        {name = "Security Tools", key = "tools"},
        {name = "Personnel", key = "personnel"},
        {name = "Research", key = "research"}
    }
    
    print("🛒 UpgradeShopLuis: Initialized security upgrade shop")
    return self
end

function UpgradeShopLuis:load(data)
    print("🛒 UpgradeShopLuis: Entered security upgrade shop")
    
    -- Create LUIS layer
    self.luis.newLayer(self.layerName)
    self.luis.setCurrentLayer(self.layerName)
    
    -- Build UI
    self:buildUI()
end

function UpgradeShopLuis:buildUI()
    local luis = self.luis
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local gridSize = luis.gridSize
    
    local centerCol = math.floor(screenWidth / gridSize / 2)
    local centerRow = math.floor(screenHeight / gridSize / 2)
    
    -- Title
    local title = luis.newLabel("🛒 SOC Security Upgrade Shop", 35, 2, 2, centerCol - 17)
    luis.insertElement(self.layerName, title)
    
    -- Category buttons (left side)
    local leftCol = 2
    local startRow = 5
    
    for i, category in ipairs(self.categories) do
        local button = luis.newButton(
            category.name,
            15, 2,
            function()
                self.selectedCategory = i
                print("Selected category: " .. category.name)
            end,
            nil,
            startRow + (i-1) * 3,
            leftCol
        )
        luis.insertElement(self.layerName, button)
    end
    
    -- Info text
    local info = luis.newLabel("Select a category to view upgrades", 40, 2, centerRow, centerCol - 20)
    luis.insertElement(self.layerName, info)
    
    -- Return button
    local returnButton = luis.newButton(
        "↩ Return to SOC View (ESC)",
        25, 3,
        function()
            if self.eventBus then
                self.eventBus:publish("scene_request", {scene = "soc_view"})
            end
        end,
        nil,
        centerRow + 15,
        centerCol - 12
    )
    luis.insertElement(self.layerName, returnButton)
    
    print("🛒 UpgradeShopLuis: UI built")
end

function UpgradeShopLuis:update(dt)
    -- Shop updates
end

function UpgradeShopLuis:exit()
    print("🛒 UpgradeShopLuis: Exited security upgrade shop")
    
    if self.luis.isLayerEnabled(self.layerName) then
        self.luis.disableLayer(self.layerName)
    end
end

function UpgradeShopLuis:keypressed(key)
    if key == "escape" then
        self.eventBus:publish("scene_request", {scene = "soc_view"})
    elseif key == "tab" then
        self.selectedCategory = (self.selectedCategory % #self.categories) + 1
    end
end

return UpgradeShopLuis
