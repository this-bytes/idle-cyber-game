-- Resource Display System
-- Handles the visual presentation of resources, generation rates, and statistics

local display = {}
local resources = require("resources")
local format = require("format")

-- Display state and configuration
local displayState = {
    -- Animation state for smooth number transitions
    animations = {
        dataBits = { current = 0, target = 0, speed = 2.0 },
        processingPower = { current = 0, target = 0, speed = 2.0 },
        securityRating = { current = 0, target = 0, speed = 2.0 },
        dataBitsRate = { current = 0, target = 0, speed = 3.0 },
        processingPowerRate = { current = 0, target = 0, speed = 3.0 },
        securityRatingRate = { current = 0, target = 0, speed = 3.0 },
    },
    
    -- Click feedback effects
    clickEffects = {},
    maxClickEffects = 10,
    
    -- Layout configuration
    layout = {
        headerHeight = 80,
        resourcePanelWidth = 300,
        resourcePanelHeight = 200,
        padding = 20,
        resourceSpacing = 15,
        fontSize = {
            large = 24,
            medium = 18,
            small = 14,
        }
    },
    
    -- Color theme
    colors = format.colors,
    
    -- Display settings
    showDetailedStats = false,
    compactMode = false,
}

-- Initialize display system
function display.init()
    -- Set up initial animation values
    local currentResources = resources.getResources()
    local currentGeneration = resources.getGeneration()
    
    displayState.animations.dataBits.current = currentResources.dataBits
    displayState.animations.dataBits.target = currentResources.dataBits
    displayState.animations.processingPower.current = currentResources.processingPower  
    displayState.animations.processingPower.target = currentResources.processingPower
    displayState.animations.securityRating.current = currentResources.securityRating
    displayState.animations.securityRating.target = currentResources.securityRating
    
    displayState.animations.dataBitsRate.current = currentGeneration.dataBits
    displayState.animations.dataBitsRate.target = currentGeneration.dataBits
    displayState.animations.processingPowerRate.current = currentGeneration.processingPower
    displayState.animations.processingPowerRate.target = currentGeneration.processingPower
    displayState.animations.securityRatingRate.current = currentGeneration.securityRating
    displayState.animations.securityRatingRate.target = currentGeneration.securityRating
end

-- Update display system (called every frame)
function display.update(dt)
    -- Update resource targets
    local currentResources = resources.getResources()
    local currentGeneration = resources.getGeneration()
    
    displayState.animations.dataBits.target = currentResources.dataBits
    displayState.animations.processingPower.target = currentResources.processingPower
    displayState.animations.securityRating.target = currentResources.securityRating
    
    displayState.animations.dataBitsRate.target = currentGeneration.dataBits
    displayState.animations.processingPowerRate.target = currentGeneration.processingPower
    displayState.animations.securityRatingRate.target = currentGeneration.securityRating
    
    -- Animate values towards targets
    for name, anim in pairs(displayState.animations) do
        local diff = anim.target - anim.current
        local maxChange = anim.speed * dt * math.max(math.abs(anim.current), 1)
        
        if math.abs(diff) < maxChange then
            anim.current = anim.target
        else
            anim.current = anim.current + (diff > 0 and maxChange or -maxChange)
        end
    end
    
    -- Update click effects
    for i = #displayState.clickEffects, 1, -1 do
        local effect = displayState.clickEffects[i]
        effect.life = effect.life - dt
        effect.y = effect.y - effect.speed * dt
        effect.alpha = effect.life / effect.maxLife
        
        if effect.life <= 0 then
            table.remove(displayState.clickEffects, i)
        end
    end
end

-- Render the resource display
function display.draw()
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    local layout = displayState.layout
    
    -- Draw background panel
    love.graphics.setColor(0.1, 0.1, 0.15, 0.9)
    love.graphics.rectangle("fill", layout.padding, layout.padding, 
                           layout.resourcePanelWidth, layout.resourcePanelHeight)
    
    -- Draw panel border
    love.graphics.setColor(0.3, 0.3, 0.4, 1.0)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", layout.padding, layout.padding, 
                           layout.resourcePanelWidth, layout.resourcePanelHeight)
    
    -- Draw header
    love.graphics.setColor(0.8, 0.8, 0.9, 1.0)
    love.graphics.setFont(love.graphics.newFont(layout.fontSize.large))
    love.graphics.print("Resources", layout.padding + 10, layout.padding + 5)
    
    -- Draw resources
    local yOffset = layout.padding + layout.headerHeight / 2
    
    display.drawResource("Data Bits", 
                        displayState.animations.dataBits.current,
                        displayState.animations.dataBitsRate.current,
                        displayState.colors.dataBits,
                        layout.padding + 10, yOffset)
    yOffset = yOffset + layout.resourceSpacing * 2
    
    display.drawResource("Processing Power", 
                        displayState.animations.processingPower.current,
                        displayState.animations.processingPowerRate.current,
                        displayState.colors.processingPower,
                        layout.padding + 10, yOffset)
    yOffset = yOffset + layout.resourceSpacing * 2
    
    display.drawResource("Security Rating", 
                        displayState.animations.securityRating.current,
                        displayState.animations.securityRatingRate.current,
                        displayState.colors.securityRating,
                        layout.padding + 10, yOffset)
    
    -- Draw click info if available
    display.drawClickInfo()
    
    -- Draw click effects
    display.drawClickEffects()
    
    -- Draw detailed stats if enabled
    if displayState.showDetailedStats then
        display.drawDetailedStats()
    end
end

-- Draw individual resource with value and generation rate
function display.drawResource(name, value, rate, color, x, y)
    local layout = displayState.layout
    
    -- Resource name
    love.graphics.setColor(0.9, 0.9, 0.9, 1.0)
    love.graphics.setFont(love.graphics.newFont(layout.fontSize.medium))
    love.graphics.print(name, x, y)
    
    -- Resource value
    love.graphics.setColor(color)
    love.graphics.setFont(love.graphics.newFont(layout.fontSize.medium))
    local valueText = format.number(value, 2)
    love.graphics.print(valueText, x, y + layout.resourceSpacing)
    
    -- Generation rate (if > 0)
    if rate > 0 then
        love.graphics.setColor(color[1] * 0.8, color[2] * 0.8, color[3] * 0.8, 0.8)
        love.graphics.setFont(love.graphics.newFont(layout.fontSize.small))
        local rateText = "(+" .. format.rate(rate, 1) .. ")"
        local valueWidth = love.graphics.getFont():getWidth(valueText)
        love.graphics.print(rateText, x + valueWidth + 10, y + layout.resourceSpacing + 2)
    end
end

-- Draw click mechanics information
function display.drawClickInfo()
    local clickInfo = resources.getClickInfo()
    local layout = displayState.layout
    
    -- Click power display
    local x = layout.padding + layout.resourcePanelWidth + layout.padding
    local y = layout.padding
    
    love.graphics.setColor(0.1, 0.1, 0.15, 0.9)
    love.graphics.rectangle("fill", x, y, 200, 80)
    
    love.graphics.setColor(0.3, 0.3, 0.4, 1.0)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, 200, 80)
    
    love.graphics.setColor(0.8, 0.8, 0.9, 1.0)
    love.graphics.setFont(love.graphics.newFont(layout.fontSize.medium))
    love.graphics.print("Click Power", x + 10, y + 5)
    
    love.graphics.setColor(displayState.colors.dataBits)
    love.graphics.print(format.number(clickInfo.power) .. " DB", x + 10, y + 25)
    
    -- Combo display
    if clickInfo.combo > 1.0 then
        love.graphics.setColor(displayState.colors.combo)
        love.graphics.setFont(love.graphics.newFont(layout.fontSize.small))
        local comboText = "Combo: " .. format.combo(clickInfo.combo)
        love.graphics.print(comboText, x + 10, y + 45)
        
        -- Combo bar
        local barWidth = 180
        local barHeight = 6
        local comboProgress = (clickInfo.combo - 1) / (clickInfo.maxCombo - 1)
        
        love.graphics.setColor(0.2, 0.2, 0.3, 1.0)
        love.graphics.rectangle("fill", x + 10, y + 65, barWidth, barHeight)
        
        love.graphics.setColor(displayState.colors.combo)
        love.graphics.rectangle("fill", x + 10, y + 65, barWidth * comboProgress, barHeight)
    end
end

-- Draw click effect animations
function display.drawClickEffects()
    for _, effect in ipairs(displayState.clickEffects) do
        love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.alpha)
        love.graphics.setFont(love.graphics.newFont(effect.size))
        love.graphics.print(effect.text, effect.x, effect.y)
    end
end

-- Draw detailed statistics panel
function display.drawDetailedStats()
    local screenW = love.graphics.getWidth()
    local layout = displayState.layout
    
    local x = screenW - 250 - layout.padding
    local y = layout.padding
    
    love.graphics.setColor(0.1, 0.1, 0.15, 0.9)
    love.graphics.rectangle("fill", x, y, 250, 300)
    
    love.graphics.setColor(0.3, 0.3, 0.4, 1.0)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, 250, 300)
    
    love.graphics.setColor(0.8, 0.8, 0.9, 1.0)
    love.graphics.setFont(love.graphics.newFont(layout.fontSize.medium))
    love.graphics.print("Statistics", x + 10, y + 5)
    
    -- Add detailed stats here (multipliers, efficiency, etc.)
    local upgrades = resources.getUpgrades()
    local yPos = y + 30
    
    love.graphics.setFont(love.graphics.newFont(layout.fontSize.small))
    love.graphics.setColor(0.7, 0.7, 0.8, 1.0)
    
    -- Show some basic upgrade counts
    love.graphics.print("Desktops: " .. upgrades.refurbishedDesktop, x + 10, yPos)
    yPos = yPos + 15
    love.graphics.print("Servers: " .. upgrades.basicServerRack, x + 10, yPos)
    yPos = yPos + 15
    love.graphics.print("Data Centers: " .. upgrades.smallDataCenter, x + 10, yPos)
end

-- Add a click effect animation
function display.addClickEffect(x, y, reward, isCritical, combo)
    if #displayState.clickEffects >= displayState.maxClickEffects then
        table.remove(displayState.clickEffects, 1)
    end
    
    local effect = {
        x = x + math.random(-20, 20),
        y = y,
        text = "+" .. format.number(reward),
        color = isCritical and displayState.colors.critical or displayState.colors.dataBits,
        size = isCritical and 20 or (combo > 2 and 18 or 16),
        life = 2.0,
        maxLife = 2.0,
        speed = 50 + (combo * 10),
        alpha = 1.0,
    }
    
    table.insert(displayState.clickEffects, effect)
end

-- Toggle detailed stats display
function display.toggleDetailedStats()
    displayState.showDetailedStats = not displayState.showDetailedStats
end

-- Toggle compact mode
function display.toggleCompactMode()
    displayState.compactMode = not displayState.compactMode
    -- Adjust layout for compact mode
    if displayState.compactMode then
        displayState.layout.resourceSpacing = 12
        displayState.layout.fontSize.medium = 16
        displayState.layout.fontSize.small = 12
    else
        displayState.layout.resourceSpacing = 15
        displayState.layout.fontSize.medium = 18
        displayState.layout.fontSize.small = 14
    end
end

-- Handle clicks on the resource display (for interactive elements)
function display.mousepressed(x, y, button)
    local layout = displayState.layout
    
    -- Check if click is on main resource panel (for clicking to earn DB)
    if x >= layout.padding and x <= layout.padding + layout.resourcePanelWidth and
       y >= layout.padding and y <= layout.padding + layout.resourcePanelHeight then
        
        -- Perform click action
        local clickResult = resources.clickForDataBits()
        
        -- Add visual effect
        display.addClickEffect(x, y, clickResult.reward, clickResult.critical, clickResult.combo)
        
        return true
    end
    
    return false
end

-- Get display state for debugging
function display.getState()
    return displayState
end

return display