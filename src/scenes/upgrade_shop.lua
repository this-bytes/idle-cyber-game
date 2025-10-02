-- Upgrade Shop Scene - SOC Security Infrastructure Management
-- Allows purchasing and managing cybersecurity upgrades for the SOC
-- Aligned with real-world security tools and infrastructure

local UpgradeShop = {}
UpgradeShop.__index = UpgradeShop

-- Create new upgrade shop scene
function UpgradeShop.new(eventBus)
    local self = setmetatable({}, UpgradeShop)
    
    -- Scene state
    self.eventBus = eventBus
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
    
    -- UI layout
    self.layout = {
        headerHeight = 60,
        categoryWidth = 200,
        upgradeListWidth = 300,
        panelSpacing = 10
    }
    
    print("🛒 UpgradeShop: Initialized security upgrade shop")
    return self
end

-- Enter upgrade shop scene
function UpgradeShop:enter(data)
    -- Systems are injected by SceneManager
    print("🛒 UpgradeShop: Entered security upgrade shop")
end

-- Exit upgrade shop scene
function UpgradeShop:exit()
    print("🛒 UpgradeShop: Exited security upgrade shop")
end

-- Update upgrade shop
function UpgradeShop:update(dt)
    -- Shop updates can go here
end

-- Draw upgrade shop
function UpgradeShop:draw()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Background
    love.graphics.setColor(0.03, 0.06, 0.09, 1) -- Dark background
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
    
    -- Draw header
    self:drawHeader()
    
    -- Draw categories sidebar
    self:drawCategories()
    
    -- Draw upgrade list
    self:drawUpgradeList()
    
    -- Draw upgrade details
    self:drawUpgradeDetails()
    
    -- Draw resource status
    self:drawResourceStatus()
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

-- Draw header
function UpgradeShop:drawHeader()
    local screenWidth = love.graphics.getWidth()
    local headerHeight = self.layout.headerHeight
    
    -- Header background
    love.graphics.setColor(0.1, 0.15, 0.2, 1)
    love.graphics.rectangle("fill", 0, 0, screenWidth, headerHeight)
    
    -- Title
    love.graphics.setColor(0.2, 0.8, 1, 1)
    love.graphics.print("🛒 SOC Security Upgrade Shop", 20, 20)
    
    -- Navigation hint
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.print("Press [ESC] to return to SOC | [TAB] to switch categories", 20, 40)
end

-- Draw categories sidebar
function UpgradeShop:drawCategories()
    local categoryWidth = self.layout.categoryWidth
    local screenHeight = love.graphics.getHeight()
    local startY = self.layout.headerHeight + self.layout.panelSpacing
    
    -- Category background
    love.graphics.setColor(0.06, 0.1, 0.14, 1)
    love.graphics.rectangle("fill", 0, startY, categoryWidth, screenHeight - startY)
    
    -- Category title
    love.graphics.setColor(0.8, 0.8, 0.8, 1)
    love.graphics.print("Categories", 15, startY + 15)
    
    -- Category list
    local itemHeight = 40
    local listStartY = startY + 50
    
    for i, category in ipairs(self.categories) do
        local y = listStartY + (i - 1) * (itemHeight + 5)
        local isSelected = (i == self.selectedCategory)
        
        -- Highlight selected category
        if isSelected then
            love.graphics.setColor(0.2, 0.4, 0.6, 0.8)
            love.graphics.rectangle("fill", 5, y - 2, categoryWidth - 10, itemHeight)
        end
        
        -- Category text
        local textColor = isSelected and {1, 1, 1, 1} or {0.7, 0.7, 0.7, 1}
        love.graphics.setColor(textColor)
        love.graphics.print(category.name, 15, y + 10)
    end
end

-- Draw upgrade list
function UpgradeShop:drawUpgradeList()
    local categoryWidth = self.layout.categoryWidth
    local upgradeListWidth = self.layout.upgradeListWidth
    local screenHeight = love.graphics.getHeight()
    local startY = self.layout.headerHeight + self.layout.panelSpacing
    local startX = categoryWidth + self.layout.panelSpacing
    
    -- Upgrade list background
    love.graphics.setColor(0.05, 0.08, 0.12, 1)
    love.graphics.rectangle("fill", startX, startY, upgradeListWidth, screenHeight - startY)
    
    -- Get upgrades for selected category
    local selectedCategory = self.categories[self.selectedCategory]
    local upgrades = self:getUpgradesForCategory(selectedCategory.key)
    
    -- Category title
    love.graphics.setColor(0.8, 0.8, 0.8, 1)
    love.graphics.print(selectedCategory.name .. " Upgrades", startX + 15, startY + 15)
    
    -- Upgrade list
    local itemHeight = 60
    local listStartY = startY + 50
    
    for i, upgrade in ipairs(upgrades) do
        local y = listStartY + (i - 1) * (itemHeight + 5)
        local isSelected = (i == self.selectedUpgrade)
        local canAfford = self:canAffordUpgrade(upgrade)
        local isOwned = self:isUpgradeOwned(upgrade)
        
        -- Highlight selected upgrade
        if isSelected then
            love.graphics.setColor(0.2, 0.4, 0.6, 0.8)
            love.graphics.rectangle("fill", startX + 5, y - 2, upgradeListWidth - 10, itemHeight)
        end
        
        -- Upgrade name
        local nameColor = {1, 1, 1, 1}
        if not canAfford then
            nameColor = {0.5, 0.5, 0.5, 1}
        elseif isOwned then
            nameColor = {0.2, 0.8, 0.2, 1}
        end
        love.graphics.setColor(nameColor)
        love.graphics.print(upgrade.name, startX + 15, y + 5)
        
        -- Cost and status
        love.graphics.setColor(0.7, 0.7, 0.7, 1)
        local costText = "$" .. (upgrade.cost or 0)
        if isOwned then
            costText = "OWNED"
        elseif not canAfford then
            costText = costText .. " (Too expensive)"
        end
        love.graphics.print(costText, startX + 15, y + 25)
        
        -- Brief description
        love.graphics.setColor(0.6, 0.6, 0.6, 1)
        local description = upgrade.description or "Security upgrade"
        if #description > 35 then
            description = description:sub(1, 35) .. "..."
        end
        love.graphics.print(description, startX + 15, y + 40)
    end
    
    if #upgrades == 0 then
        love.graphics.setColor(0.6, 0.6, 0.6, 1)
        love.graphics.print("No upgrades available", startX + 15, listStartY)
    end
end

-- Draw upgrade details
function UpgradeShop:drawUpgradeDetails()
    local categoryWidth = self.layout.categoryWidth
    local upgradeListWidth = self.layout.upgradeListWidth
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local startY = self.layout.headerHeight + self.layout.panelSpacing
    local startX = categoryWidth + upgradeListWidth + self.layout.panelSpacing * 2
    local detailsWidth = screenWidth - startX - self.layout.panelSpacing
    
    -- Details background
    love.graphics.setColor(0.04, 0.07, 0.11, 1)
    love.graphics.rectangle("fill", startX, startY, detailsWidth, screenHeight - startY)
    
    -- Get selected upgrade
    local selectedCategory = self.categories[self.selectedCategory]
    local upgrades = self:getUpgradesForCategory(selectedCategory.key)
    local upgrade = upgrades[self.selectedUpgrade]
    
    if upgrade then
        -- Upgrade name
        love.graphics.setColor(0.2, 0.8, 1, 1)
        love.graphics.print(upgrade.name, startX + 15, startY + 15)
        
        -- Description
        love.graphics.setColor(0.8, 0.8, 0.8, 1)
        love.graphics.print("Description:", startX + 15, startY + 45)
        love.graphics.setColor(0.7, 0.7, 0.7, 1)
        self:drawWrappedText(upgrade.description or "No description available", 
                           startX + 15, startY + 70, detailsWidth - 30)
        
        -- Effects
        love.graphics.setColor(0.8, 0.8, 0.8, 1)
        love.graphics.print("Effects:", startX + 15, startY + 140)
        
        local effectY = startY + 165
        love.graphics.setColor(0.2, 0.8, 0.2, 1)
        if upgrade.threatReduction then
            love.graphics.print("• Threat Reduction: +" .. (upgrade.threatReduction * 100) .. "%", 
                              startX + 15, effectY)
            effectY = effectY + 25
        end
        if upgrade.detectionImprovement then
            love.graphics.print("• Detection: +" .. upgrade.detectionImprovement .. "%", 
                              startX + 15, effectY)
            effectY = effectY + 25
        end
        if upgrade.responseImprovement then
            love.graphics.print("• Response Time: +" .. upgrade.responseImprovement .. "%", 
                              startX + 15, effectY)
            effectY = effectY + 25
        end
        
        -- Cost and purchase button
        love.graphics.setColor(0.8, 0.8, 0.8, 1)
        love.graphics.print("Cost:", startX + 15, effectY + 30)
        love.graphics.setColor(1, 1, 0.2, 1)
        love.graphics.print("$" .. (upgrade.cost or 0), startX + 70, effectY + 30)
        
        -- Purchase status
        local canAfford = self:canAffordUpgrade(upgrade)
        local isOwned = self:isUpgradeOwned(upgrade)
        
        if isOwned then
            love.graphics.setColor(0.2, 0.8, 0.2, 1)
            love.graphics.print("OWNED", startX + 15, effectY + 60)
        elseif canAfford then
            love.graphics.setColor(0.2, 0.8, 0.2, 1)
            love.graphics.print("Press [ENTER] to purchase", startX + 15, effectY + 60)
        else
            love.graphics.setColor(0.8, 0.2, 0.2, 1)
            love.graphics.print("Insufficient funds", startX + 15, effectY + 60)
        end
    else
        love.graphics.setColor(0.6, 0.6, 0.6, 1)
        love.graphics.print("Select an upgrade to view details", startX + 15, startY + 15)
    end
end

-- Draw resource status
function UpgradeShop:drawResourceStatus()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Resource background
    love.graphics.setColor(0.1, 0.1, 0.1, 0.8)
    love.graphics.rectangle("fill", screenWidth - 200, screenHeight - 100, 190, 90)
    
    -- Resource info
    love.graphics.setColor(0.8, 0.8, 0.8, 1)
    love.graphics.print("Resources:", screenWidth - 190, screenHeight - 90)
    
    if self.resourceManager then
        love.graphics.setColor(1, 1, 0.2, 1)
        love.graphics.print("Money: $" .. (self.resourceManager:getResource("money") or 0), 
                          screenWidth - 190, screenHeight - 70)
        love.graphics.setColor(0.2, 0.8, 1, 1)
        love.graphics.print("Rep: " .. (self.resourceManager:getResource("reputation") or 0), 
                          screenWidth - 190, screenHeight - 50)
        love.graphics.setColor(0.8, 0.2, 1, 1)
        love.graphics.print("XP: " .. (self.resourceManager:getResource("xp") or 0), 
                          screenWidth - 190, screenHeight - 30)
    end
end

-- Handle key input
function UpgradeShop:keypressed(key)
    if key == "escape" then
        self.eventBus:publish("scene_request", {scene = "soc_view"})
    elseif key == "tab" then
        self.selectedCategory = (self.selectedCategory % #self.categories) + 1
        self.selectedUpgrade = 1 -- Reset upgrade selection
    elseif key == "up" then
        local selectedCategory = self.categories[self.selectedCategory]
        local upgrades = self:getUpgradesForCategory(selectedCategory.key)
        if #upgrades > 0 then
            self.selectedUpgrade = math.max(1, self.selectedUpgrade - 1)
        end
    elseif key == "down" then
        local selectedCategory = self.categories[self.selectedCategory]
        local upgrades = self:getUpgradesForCategory(selectedCategory.key)
        if #upgrades > 0 then
            self.selectedUpgrade = math.min(#upgrades, self.selectedUpgrade + 1)
        end
    elseif key == "return" or key == "enter" then
        self:purchaseSelectedUpgrade()
    end
end

-- Handle mouse input
function UpgradeShop:mousepressed(x, y, button)
    if button == 1 then -- Left click
        -- Check category selection
        local categoryWidth = self.layout.categoryWidth
        local startY = self.layout.headerHeight + self.layout.panelSpacing
        
        if x <= categoryWidth and y >= startY + 50 then
            local itemHeight = 45
            local listStartY = startY + 50
            
            for i, category in ipairs(self.categories) do
                local categoryY = listStartY + (i - 1) * itemHeight
                if y >= categoryY and y <= categoryY + itemHeight then
                    self.selectedCategory = i
                    self.selectedUpgrade = 1
                    break
                end
            end
        end
        
        -- Check upgrade selection
        local upgradeListWidth = self.layout.upgradeListWidth
        local upgradeStartX = categoryWidth + self.layout.panelSpacing
        
        if x >= upgradeStartX and x <= upgradeStartX + upgradeListWidth and y >= startY + 50 then
            local selectedCategory = self.categories[self.selectedCategory]
            local upgrades = self:getUpgradesForCategory(selectedCategory.key)
            local itemHeight = 65
            local listStartY = startY + 50
            
            for i, upgrade in ipairs(upgrades) do
                local upgradeY = listStartY + (i - 1) * itemHeight
                if y >= upgradeY and y <= upgradeY + itemHeight then
                    self.selectedUpgrade = i
                    break
                end
            end
        end
    end
end

-- Helper methods
function UpgradeShop:getUpgradesForCategory(category)
    if not self.systems or not self.systems.upgradeSystem then
        return {}
    end
    
    local upgradeTrees = self.systems.upgradeSystem.upgradeTrees or {}
    return upgradeTrees[category] or {}
end

function UpgradeShop:canAffordUpgrade(upgrade)
    if not self.systems or not self.systems.resourceManager or not upgrade or not upgrade.cost then
        return false
    end
    
    local resources = self.systems.resourceManager:getState()
    
    -- Check money cost
    if upgrade.cost.money and resources.money < upgrade.cost.money then
        return false
    end
    
    -- Check reputation cost
    if upgrade.cost.reputation and resources.reputation < upgrade.cost.reputation then
        return false
    end
    
    return true
end

function UpgradeShop:isUpgradeOwned(upgrade)
    if not self.systems or not self.systems.upgradeSystem or not upgrade then
        return false
    end
    
    return self.systems.upgradeSystem.purchasedUpgrades[upgrade.id] ~= nil
end

function UpgradeShop:purchaseSelectedUpgrade()
    local selectedCategory = self.categories[self.selectedCategory]
    local upgrades = self:getUpgradesForCategory(selectedCategory.key)
    local upgrade = upgrades[self.selectedUpgrade]
    
    if not upgrade then
        return
    end
    
    if self:isUpgradeOwned(upgrade) then
        print("🛒 UpgradeShop: Upgrade already owned - " .. upgrade.name)
        return
    end
    
    if not self:canAffordUpgrade(upgrade) then
        print("🛒 UpgradeShop: Cannot afford upgrade - " .. upgrade.name)
        return
    end
    
    -- Purchase upgrade
    if self.systems and self.systems.upgradeSystem and self.systems.upgradeSystem.purchaseUpgrade then
        local success = self.systems.upgradeSystem:purchaseUpgrade(upgrade.id)
        if success then
            print("🛒 UpgradeShop: Purchased upgrade - " .. upgrade.name)
            self.eventBus:publish("security_upgrade_purchased", upgrade)
        else
            print("🛒 UpgradeShop: Failed to purchase upgrade - " .. upgrade.name)
        end
    end
end

function UpgradeShop:drawWrappedText(text, x, y, maxWidth)
    local font = love.graphics.getFont()
    local words = {}
    for word in text:gmatch("%S+") do
        table.insert(words, word)
    end
    
    local lines = {}
    local currentLine = ""
    
    for _, word in ipairs(words) do
        local testLine = currentLine == "" and word or currentLine .. " " .. word
        if font:getWidth(testLine) <= maxWidth then
            currentLine = testLine
        else
            if currentLine ~= "" then
                table.insert(lines, currentLine)
            end
            currentLine = word
        end
    end
    
    if currentLine ~= "" then
        table.insert(lines, currentLine)
    end
    
    for i, line in ipairs(lines) do
        love.graphics.print(line, x, y + (i - 1) * font:getHeight())
    end
end

return UpgradeShop