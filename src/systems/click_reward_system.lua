-- Click Reward System - Manual Income Generation for Idle Sec Ops
-- Handles click-based income generation with scaling and statistics
-- Integrates with ResourceManager and provides visual feedback

local ClickRewardSystem = {}
ClickRewardSystem.__index = ClickRewardSystem

function ClickRewardSystem.new(eventBus, resourceManager, upgradeSystem, specialistSystem)
    local self = setmetatable({}, ClickRewardSystem)
    self.eventBus = eventBus
    self.resourceManager = resourceManager
    self.upgradeSystem = upgradeSystem
    self.specialistSystem = specialistSystem

    -- Click reward configuration
    self.baseReward = 1 -- Base $1 per click
    self.clickMultiplier = 1.0 -- Scales with upgrades/specialists
    self.bonusMultiplier = 1.0 -- Additional bonuses

    -- Statistics tracking
    self.stats = {
        totalClicks = 0,
        totalEarned = 0,
        clicksPerSecond = 0,
        lastClickTime = 0,
        clickHistory = {} -- For CPS calculation
    }

    -- Click cooldown (prevents click spam)
    self.clickCooldown = 0.05 -- 50ms minimum between clicks
    self.lastClickTime = 0

    -- Screen shake effect (Phase 2)
    self.screenShake = {
        active = false,
        intensity = 0,
        duration = 0,
        timeLeft = 0,
        offsetX = 0,
        offsetY = 0
    }

    -- Ripple effects (Phase 2)
    self.ripples = {}

    -- Subscribe to input actions
    if eventBus then
        eventBus:subscribe("input_action_manual_income", function(event)
            self:processClick(event.data)
        end)
    end

    print("💰 ClickRewardSystem: Initialized (base reward: $" .. self.baseReward .. ")")
    return self
end

-- Process a click event
function ClickRewardSystem:processClick(data)
    local now = love.timer.getTime()

    -- Check cooldown
    if now - self.lastClickTime < self.clickCooldown then
        return false -- Click too soon, ignore
    end

    self.lastClickTime = now

    -- Calculate reward
    local reward = self:getCurrentClickValue()

    -- Add to resources
    if self.resourceManager and self.resourceManager.addResource then
        self.resourceManager:addResource("money", reward, "manual_click")
    end

    -- Update statistics
    self.stats.totalClicks = self.stats.totalClicks + 1
    self.stats.totalEarned = self.stats.totalEarned + reward

    -- Track click history for CPS calculation (keep last 10 seconds)
    table.insert(self.stats.clickHistory, now)
    -- Remove old clicks (older than 10 seconds)
    while #self.stats.clickHistory > 0 and now - self.stats.clickHistory[1] > 10 do
        table.remove(self.stats.clickHistory, 1)
    end

    -- Calculate clicks per second
    local timeSpan = 10 -- seconds
    if #self.stats.clickHistory > 1 then
        local recentClicks = #self.stats.clickHistory
        local timeRange = now - self.stats.clickHistory[1]
        if timeRange > 0 then
            self.stats.clicksPerSecond = recentClicks / timeRange
        end
    end

    -- Emit event for visual feedback
    if self.eventBus then
        self.eventBus:publish("click_reward_earned", {
            amount = reward,
            totalClicks = self.stats.totalClicks,
            totalEarned = self.stats.totalEarned,
            clicksPerSecond = self.stats.clicksPerSecond,
            position = data or {x = 150, y = 100} -- Default to money counter area
        })
    end

    print(string.format("💰 ClickReward: +$%.0f (Total: $%.0f, Clicks: %d)",
        reward, self.stats.totalEarned, self.stats.totalClicks))

    -- Trigger visual effects (Phase 2)
    self:triggerScreenShake(0.2, 3) -- 0.2 seconds, intensity 3
    self:createRipple(data and data.x or 150, data and data.y or 100, reward)

    return true
end

-- Trigger screen shake effect (Phase 2)
function ClickRewardSystem:triggerScreenShake(duration, intensity)
    self.screenShake.active = true
    self.screenShake.duration = duration
    self.screenShake.timeLeft = duration
    self.screenShake.intensity = intensity
end

-- Create ripple effect at click position (Phase 2)
function ClickRewardSystem:createRipple(x, y, reward)
    local ripple = {
        x = x,
        y = y,
        radius = 0,
        maxRadius = 50 + (reward * 0.5), -- Scale with reward amount
        speed = 200, -- pixels per second
        alpha = 1.0,
        fadeSpeed = 2.0,
        reward = reward
    }
    table.insert(self.ripples, ripple)
end

-- Get current click value (base * upgrade multipliers * specialist multipliers)
function ClickRewardSystem:getCurrentClickValue()
    local value = self.baseReward
    
    -- Apply upgrade multipliers
    local upgradeMultiplier = self:getUpgradeMultiplier()
    value = value * upgradeMultiplier
    
    -- Apply specialist multipliers
    local specialistMultiplier = self:getSpecialistMultiplier()
    value = value * specialistMultiplier
    
    return value
end

-- Calculate click multiplier from purchased upgrades
function ClickRewardSystem:getUpgradeMultiplier()
    local multiplier = 1.0
    
    if self.upgradeSystem then
        local purchasedUpgrades = self.upgradeSystem:getPurchasedUpgrades()
        for _, upgrade in ipairs(purchasedUpgrades) do
            if upgrade.effects and upgrade.effects.passive then
                for _, effect in ipairs(upgrade.effects.passive) do
                    if effect.type == "click_multiplier" then
                        multiplier = multiplier * effect.value
                    end
                end
            end
        end
    end
    
    return multiplier
end

-- Calculate click multiplier from hired specialists
function ClickRewardSystem:getSpecialistMultiplier()
    local multiplier = 1.0
    
    if self.specialistSystem then
        local specialists = self.specialistSystem:getAllSpecialists()
        for _, specialist in pairs(specialists) do
            if specialist.effects and specialist.effects.passive then
                for _, effect in ipairs(specialist.effects.passive) do
                    if effect.type == "click_multiplier" then
                        multiplier = multiplier * effect.value
                    end
                end
            end
        end
    end
    
    return multiplier
end

-- Set click multiplier (from upgrades)
function ClickRewardSystem:setClickMultiplier(multiplier)
    self.clickMultiplier = multiplier
    print("💰 ClickReward: Multiplier set to " .. multiplier)
end

-- Add bonus multiplier (from specialists, events, etc.)
function ClickRewardSystem:addBonusMultiplier(bonus)
    self.bonusMultiplier = self.bonusMultiplier * bonus
    print("💰 ClickReward: Bonus multiplier applied (" .. bonus .. "x), total: " .. self.bonusMultiplier)
end

-- Reset bonus multipliers (for prestige, etc.)
function ClickRewardSystem:resetBonusMultipliers()
    self.bonusMultiplier = 1.0
    print("💰 ClickReward: Bonus multipliers reset")
end

-- Get click statistics
function ClickRewardSystem:getStats()
    return {
        totalClicks = self.stats.totalClicks,
        totalEarned = self.stats.totalEarned,
        clicksPerSecond = self.stats.clicksPerSecond,
        currentValue = self:getCurrentClickValue(),
        multiplier = self.clickMultiplier,
        bonusMultiplier = self.bonusMultiplier
    }
end

-- Update (for any time-based mechanics)
function ClickRewardSystem:update(dt)
    -- Could add time-based bonuses or effects here
    -- For now, just update CPS calculation
    local now = love.timer.getTime()

    -- Clean old click history periodically
    if #self.stats.clickHistory > 0 and now - self.stats.clickHistory[1] > 10 then
        while #self.stats.clickHistory > 0 and now - self.stats.clickHistory[1] > 10 do
            table.remove(self.stats.clickHistory, 1)
        end

        -- Recalculate CPS
        if #self.stats.clickHistory > 1 then
            local timeRange = now - self.stats.clickHistory[1]
            if timeRange > 0 then
                self.stats.clicksPerSecond = #self.stats.clickHistory / timeRange
            end
        else
            self.stats.clicksPerSecond = 0
        end
    end

    -- Update screen shake (Phase 2)
    if self.screenShake.active then
        self.screenShake.timeLeft = self.screenShake.timeLeft - dt
        if self.screenShake.timeLeft <= 0 then
            self.screenShake.active = false
            self.screenShake.offsetX = 0
            self.screenShake.offsetY = 0
        else
            -- Calculate shake offset using sine waves for natural feel
            local progress = 1 - (self.screenShake.timeLeft / self.screenShake.duration)
            local shakeAmount = self.screenShake.intensity * (1 - progress)
            self.screenShake.offsetX = (math.random() - 0.5) * shakeAmount * 2
            self.screenShake.offsetY = (math.random() - 0.5) * shakeAmount * 2
        end
    end

    -- Update ripples (Phase 2)
    for i = #self.ripples, 1, -1 do
        local ripple = self.ripples[i]
        ripple.radius = ripple.radius + ripple.speed * dt
        ripple.alpha = ripple.alpha - ripple.fadeSpeed * dt

        -- Remove completed ripples
        if ripple.alpha <= 0 or ripple.radius >= ripple.maxRadius then
            table.remove(self.ripples, i)
        end
    end
end

-- Get current screen shake offset (Phase 2)
function ClickRewardSystem:getScreenShakeOffset()
    if self.screenShake.active then
        return self.screenShake.offsetX, self.screenShake.offsetY
    end
    return 0, 0
end

-- Draw ripple effects (Phase 2)
function ClickRewardSystem:drawRipples()
    love.graphics.setColor(0.2, 0.9, 0.2, 0.3) -- Green ripple color
    for _, ripple in ipairs(self.ripples) do
        love.graphics.setColor(0.2, 0.9, 0.2, ripple.alpha * 0.3)
        love.graphics.circle("line", ripple.x, ripple.y, ripple.radius)
        
        -- Draw reward amount at ripple center when ripple is small
        if ripple.radius < ripple.maxRadius * 0.3 then
            love.graphics.setColor(0.2, 0.9, 0.2, ripple.alpha)
            local font = love.graphics.getFont()
            local text = "$" .. ripple.reward
            local textWidth = font:getWidth(text)
            love.graphics.print(text, ripple.x - textWidth/2, ripple.y - font:getHeight()/2)
        end
    end
    love.graphics.setColor(1, 1, 1, 1) -- Reset color
end

-- Get formatted display value for UI
function ClickRewardSystem:getDisplayValue()
    local value = self:getCurrentClickValue()
    if value >= 1000000 then
        return string.format("$%.1fM", value / 1000000)
    elseif value >= 1000 then
        return string.format("$%.1fK", value / 1000)
    else
        return string.format("$%.0f", value)
    end
end

-- Debug: Reset statistics
function ClickRewardSystem:resetStats()
    self.stats = {
        totalClicks = 0,
        totalEarned = 0,
        clicksPerSecond = 0,
        lastClickTime = 0,
        clickHistory = {}
    }
    print("💰 ClickReward: Statistics reset")
end

return ClickRewardSystem