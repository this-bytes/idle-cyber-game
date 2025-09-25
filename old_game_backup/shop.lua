-- Upgrade Shop System
-- Handles purchase and display of upgrades

local shop = {}
local resources = require("resources")
local format = require("format")

-- Shop state
local shopState = {
    isOpen = false,
    selectedCategory = "infrastructure",
    scrollOffset = 0,
    
    layout = {
        width = 400,
        height = 500,
        padding = 20,
        buttonHeight = 60,
        buttonSpacing = 10,
        fontSize = {
            title = 20,
            medium = 16,
            small = 12,
        }
    },
    
    colors = {
        background = {0.1, 0.1, 0.15, 0.95},
        border = {0.3, 0.3, 0.4, 1.0},
        button = {0.2, 0.2, 0.3, 1.0},
        buttonHover = {0.3, 0.3, 0.4, 1.0},
        buttonAffordable = {0.2, 0.4, 0.2, 1.0},
        text = {0.9, 0.9, 0.9, 1.0},
        cost = {1.0, 0.8, 0.2, 1.0},
        affordable = {0.2, 0.8, 0.2, 1.0},
        unaffordable = {0.8, 0.2, 0.2, 1.0},
    }
}

-- Upgrade definitions with costs that scale
local upgradeDefinitions = {
    infrastructure = {
        {
            id = "refurbishedDesktop",
            name = "🖥️ Refurbished Desktop",
            description = "Basic computer for data processing\n+0.1 DB/sec",
            baseCost = 10,
            costMultiplier = 1.15,
            effect = "generation",
            value = 0.1,
        },
        {
            id = "basicServerRack", 
            name = "🖲️ Basic Server Rack",
            description = "Professional server hardware\n+1.0 DB/sec",
            baseCost = 100,
            costMultiplier = 1.15,
            effect = "generation",
            value = 1.0,
        },
        {
            id = "smallDataCenter",
            name = "🏢 Small Data Center", 
            description = "Dedicated facility for data processing\n+10.0 DB/sec, unlocks automation",
            baseCost = 1000,
            costMultiplier = 1.15,
            effect = "generation", 
            value = 10.0,
        },
        {
            id = "enterpriseDataCenter",
            name = "🏭 Enterprise Data Center",
            description = "Industrial-scale computing power\n+100.0 DB/sec",
            baseCost = 25000,
            costMultiplier = 1.20,
            effect = "generation",
            value = 100.0,
        },
        {
            id = "hyperscaleCloudFarm",
            name = "☁️ Hyperscale Cloud Farm",
            description = "Massive distributed computing network\n+1000.0 DB/sec",
            baseCost = 500000,
            costMultiplier = 1.25,
            effect = "generation",
            value = 1000.0,
        },
    },
    
    processing = {
        {
            id = "singleCoreProcessor",
            name = "🔧 Single-Core Processor",
            description = "Basic processing unit\n+0.1 PP/sec, 1.1x DB multiplier",
            baseCost = 50,
            costMultiplier = 1.20,
            effect = "processing",
            value = 0.1,
        },
        {
            id = "multiCoreArray",
            name = "⚡ Multi-Core Array",
            description = "Parallel processing power\n+1.0 PP/sec, 1.2x DB multiplier",
            baseCost = 500,
            costMultiplier = 1.20,
            effect = "processing",
            value = 1.0,
        },
        {
            id = "parallelProcessingGrid",
            name = "🌐 Parallel Processing Grid",
            description = "Distributed computing network\n+10.0 PP/sec, 1.5x DB multiplier",
            baseCost = 5000,
            costMultiplier = 1.20,
            effect = "processing",
            value = 10.0,
        },
        {
            id = "quantumProcessor",
            name = "🔬 Quantum Processor",
            description = "Bleeding-edge quantum computing\n+100.0 PP/sec, 2.0x DB multiplier  ",
            baseCost = 100000,
            costMultiplier = 1.25,
            effect = "processing",
            value = 100.0,
        },
    },
    
    security = {
        {
            id = "basicPacketFilter",
            name = "🛡️ Basic Packet Filter",
            description = "Elementary network security\n15% threat reduction",
            baseCost = 500,
            costMultiplier = 1.25,
            effect = "security",
            value = 0.15,
        },
        {
            id = "advancedFirewall",
            name = "🔥 Advanced Firewall",
            description = "Enhanced network protection\n25% threat reduction",
            baseCost = 2500,
            costMultiplier = 1.30,
            effect = "security",
            value = 0.25,
        },
        {
            id = "intrusionDetectionSystem",
            name = "👁️ Intrusion Detection System",
            description = "AI-powered threat monitoring\n35% threat reduction",
            baseCost = 10000,
            costMultiplier = 1.35,
            effect = "security",
            value = 0.35,
        },
    },
    
    clicking = {
        {
            id = "ergonomicMouse",
            name = "🖱️ Ergonomic Mouse",
            description = "Comfortable clicking experience\n+1 DB per click",
            baseCost = 5,
            costMultiplier = 1.0, -- One-time purchase
            effect = "clickPower",
            value = 1,
            oneTime = true,
        },
        {
            id = "mechanicalKeyboard",
            name = "⌨️ Mechanical Keyboard", 
            description = "Precise input device\n+2 DB per click",
            baseCost = 25,
            costMultiplier = 1.0,
            effect = "clickPower",
            value = 2,
            oneTime = true,
        },
        {
            id = "gamingSetup",
            name = "🎮 Gaming Setup",
            description = "High-end peripherals\n+5 DB per click, enhanced combos",
            baseCost = 100,
            costMultiplier = 1.0,
            effect = "clickPower",
            value = 5,
            oneTime = true,
        },
        {
            id = "hapticFeedbackGloves",
            name = "🧤 Haptic Feedback Gloves",
            description = "Neural-link interface\n+20 DB per click, 2x critical chance",
            baseCost = 1000,
            costMultiplier = 1.0,
            effect = "clickPower",
            value = 20,
            oneTime = true,
        },
    },
}

-- Initialize shop system
function shop.init()
    shopState.isOpen = false
end

-- Update shop (handle animations, etc.)
function shop.update(dt)
    -- Add any shop-specific animations here
end

-- Draw the shop interface
function shop.draw()
    if not shopState.isOpen then
        return
    end
    
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    local layout = shopState.layout
    
    -- Center the shop window
    local x = (screenW - layout.width) / 2
    local y = (screenH - layout.height) / 2
    
    -- Draw shop background
    love.graphics.setColor(shopState.colors.background)
    love.graphics.rectangle("fill", x, y, layout.width, layout.height)
    
    -- Draw shop border
    love.graphics.setColor(shopState.colors.border)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, layout.width, layout.height)
    
    -- Draw title
    love.graphics.setColor(shopState.colors.text)
    love.graphics.setFont(love.graphics.newFont(layout.fontSize.title))
    love.graphics.print("Upgrade Shop", x + layout.padding, y + layout.padding)
    
    -- Draw category tabs
    shop.drawCategoryTabs(x, y + layout.padding + 30)
    
    -- Draw upgrades for selected category
    shop.drawUpgrades(x, y + layout.padding + 80)
    
    -- Draw close button
    shop.drawCloseButton(x + layout.width - 30, y + 10)
end

-- Draw category tabs
function shop.drawCategoryTabs(x, y)
    local categories = {"infrastructure", "processing", "security", "clicking"}
    local tabWidth = 120
    local tabHeight = 30
    
    for i, category in ipairs(categories) do
        local tabX = x + 20 + (i - 1) * (tabWidth + 10)
        local isSelected = category == shopState.selectedCategory
        
        -- Draw tab background
        if isSelected then
            love.graphics.setColor(shopState.colors.buttonHover)
        else
            love.graphics.setColor(shopState.colors.button)
        end
        love.graphics.rectangle("fill", tabX, y, tabWidth, tabHeight)
        
        -- Draw tab border
        love.graphics.setColor(shopState.colors.border)
        love.graphics.rectangle("line", tabX, y, tabWidth, tabHeight)
        
        -- Draw tab text
        love.graphics.setColor(shopState.colors.text)
        love.graphics.setFont(love.graphics.newFont(shopState.layout.fontSize.medium))
        local text = category:gsub("^%l", string.upper)
        local textWidth = love.graphics.getFont():getWidth(text)
        love.graphics.print(text, tabX + (tabWidth - textWidth) / 2, y + 6)
    end
end

-- Draw upgrades for the selected category
function shop.drawUpgrades(x, y)
    local upgrades = upgradeDefinitions[shopState.selectedCategory]
    if not upgrades then return end
    
    local layout = shopState.layout
    local currentResources = resources.getResources()
    local currentUpgrades = resources.getUpgrades()
    
    for i, upgrade in ipairs(upgrades) do
        local buttonY = y + (i - 1) * (layout.buttonHeight + layout.buttonSpacing)
        
        -- Calculate current cost
        local owned = currentUpgrades[upgrade.id] or 0
        -- Convert boolean ownership to numeric for one-time upgrades
        if type(owned) == "boolean" then
            owned = owned and 1 or 0
        end
        local cost = shop.calculateCost(upgrade, owned)
        local canAfford = currentResources.dataBits >= cost
        local isMaxed = upgrade.oneTime and owned > 0
        
        -- Draw upgrade button
        local buttonColor = shopState.colors.button
        if canAfford and not isMaxed then
            buttonColor = shopState.colors.buttonAffordable
        end
        
        love.graphics.setColor(buttonColor)
        love.graphics.rectangle("fill", x + 20, buttonY, layout.width - 60, layout.buttonHeight)
        
        love.graphics.setColor(shopState.colors.border)
        love.graphics.rectangle("line", x + 20, buttonY, layout.width - 60, layout.buttonHeight)
        
        -- Draw upgrade info
        love.graphics.setColor(shopState.colors.text)
        love.graphics.setFont(love.graphics.newFont(layout.fontSize.medium))
        love.graphics.print(upgrade.name, x + 30, buttonY + 5)
        
        if owned > 0 then
            local ownedText = " (Owned: " .. owned .. ")"
            love.graphics.setColor(0.7, 0.7, 0.7, 1.0)
            love.graphics.setFont(love.graphics.newFont(layout.fontSize.small))
            love.graphics.print(ownedText, x + 30 + love.graphics.getFont():getWidth(upgrade.name), buttonY + 7)
        end
        
        -- Draw description
        love.graphics.setColor(0.8, 0.8, 0.8, 1.0)
        love.graphics.setFont(love.graphics.newFont(layout.fontSize.small))
        love.graphics.print(upgrade.description, x + 30, buttonY + 22)
        
        -- Draw cost
        if not isMaxed then
            local costColor = canAfford and shopState.colors.affordable or shopState.colors.unaffordable
            love.graphics.setColor(costColor)
            love.graphics.setFont(love.graphics.newFont(layout.fontSize.medium))
            local costText = format.currency(cost)
            local costWidth = love.graphics.getFont():getWidth(costText)
            love.graphics.print(costText, x + layout.width - 40 - costWidth, buttonY + 5)
        else
            love.graphics.setColor(0.5, 0.5, 0.5, 1.0)
            love.graphics.print("OWNED", x + layout.width - 80, buttonY + 5)
        end
    end
end

-- Draw close button
function shop.drawCloseButton(x, y)
    love.graphics.setColor(0.8, 0.2, 0.2, 1.0)
    love.graphics.rectangle("fill", x, y, 20, 20)
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(14))
    love.graphics.print("X", x + 6, y + 2)
end

-- Calculate the cost of an upgrade based on how many are owned
function shop.calculateCost(upgrade, owned)
    if upgrade.oneTime and owned > 0 then
        return math.huge -- Can't buy again
    end
    
    return math.floor(upgrade.baseCost * (upgrade.costMultiplier ^ owned))
end

-- Handle mouse clicks on shop
function shop.mousepressed(x, y, button)
    if not shopState.isOpen then
        return false
    end
    
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    local layout = shopState.layout
    
    local shopX = (screenW - layout.width) / 2
    local shopY = (screenH - layout.height) / 2
    
    -- Check close button
    local closeX = shopX + layout.width - 30
    local closeY = shopY + 10
    if x >= closeX and x <= closeX + 20 and y >= closeY and y <= closeY + 20 then
        shopState.isOpen = false
        return true
    end
    
    -- Check category tabs
    local tabY = shopY + layout.padding + 30
    local categories = {"infrastructure", "processing", "clicking"}
    for i, category in ipairs(categories) do
        local tabX = shopX + 20 + (i - 1) * 130
        if x >= tabX and x <= tabX + 120 and y >= tabY and y <= tabY + 30 then
            shopState.selectedCategory = category
            return true
        end
    end
    
    -- Check upgrade buttons
    local upgradeY = shopY + layout.padding + 80
    local upgrades = upgradeDefinitions[shopState.selectedCategory]
    if upgrades then
        for i, upgrade in ipairs(upgrades) do
            local buttonY = upgradeY + (i - 1) * (layout.buttonHeight + layout.buttonSpacing)
            if x >= shopX + 20 and x <= shopX + layout.width - 20 and
               y >= buttonY and y <= buttonY + layout.buttonHeight then
                shop.purchaseUpgrade(upgrade)
                return true
            end
        end
    end
    
    return true -- Consume all clicks when shop is open
end

-- Attempt to purchase an upgrade
function shop.purchaseUpgrade(upgrade)
    local currentUpgrades = resources.getUpgrades()
    local owned = currentUpgrades[upgrade.id] or 0
    -- Convert boolean ownership to numeric for one-time upgrades
    if type(owned) == "boolean" then
        owned = owned and 1 or 0
    end
    local cost = shop.calculateCost(upgrade, owned)
    
    if resources.purchaseUpgrade(upgrade.id, cost) then
        print("Purchased " .. upgrade.name .. " for " .. format.currency(cost))
    else
        print("Cannot afford " .. upgrade.name .. " (Cost: " .. format.currency(cost) .. ")")
    end
end

-- Toggle shop visibility
function shop.toggle()
    shopState.isOpen = not shopState.isOpen
end

-- Check if shop is open
function shop.isOpen()
    return shopState.isOpen
end

return shop