-- Threat System
-- Handles cyber threats, attacks, and security interactions

local threats = {}
local resources = require("resources")

-- Threat system state
local threatState = {
    -- Active threats (enhanced)
    threats = {
        scriptKiddie = {
            name = "🤖 Script Kiddie Attack",
            description = "Automated attack scripts targeting vulnerabilities",
            minInterval = 45,  -- 45 seconds minimum
            maxInterval = 90,  -- 90 seconds maximum
            nextAttack = 0,
            damage = {min = 0.02, max = 0.08}, -- 2-8% of Data Bits
            type = "steal_resources",
            active = true,
            icon = "🤖",
        },
        basicMalware = {
            name = "🦠 Basic Malware",
            description = "Simple malicious software disrupting operations",
            minInterval = 80,  -- 80 seconds minimum
            maxInterval = 160, -- 160 seconds maximum
            nextAttack = 0,
            damage = {reduction = 0.15, duration = 25}, -- 15% generation reduction for 25 seconds
            type = "reduce_generation",
            active = true,
            icon = "🦠",
        },
        ddosAttack = {
            name = "⚡ DDoS Attack",
            description = "Distributed denial of service overwhelming your systems",
            minInterval = 120, -- 2 minutes minimum
            maxInterval = 300, -- 5 minutes maximum
            nextAttack = 0,
            damage = {reduction = 0.50, duration = 15}, -- 50% generation reduction for 15 seconds
            type = "reduce_generation",
            active = true,
            icon = "⚡",
        },
        ransomware = {
            name = "🔒 Ransomware",
            description = "Malicious encryption of your data systems",
            minInterval = 300, -- 5 minutes minimum
            maxInterval = 600, -- 10 minutes maximum
            nextAttack = 0,
            damage = {percentage = 0.20}, -- Steals 20% of current Data Bits
            type = "steal_resources",
            active = true,
            icon = "🔒",
        },
    },
    
    -- Active effects
    activeEffects = {},
    
    -- Security mitigation
    security = {
        threatReduction = 0, -- Percentage reduction in threat frequency/damage
    },
}

-- Initialize threat system
function threats.init()
    -- Schedule initial attacks
    for _, threat in pairs(threatState.threats) do
        if threat.active then
            threats.scheduleNextAttack(threat)
        end
    end
    
    print("Threat system initialized - cyber dangers are active!")
end

-- Schedule the next attack for a threat
function threats.scheduleNextAttack(threat)
    local interval = math.random(threat.minInterval, threat.maxInterval)
    
    -- Apply security reduction to frequency (longer intervals = less frequent attacks)
    local securityReduction = threats.calculateSecurityReduction()
    interval = interval * (1 + securityReduction)
    
    threat.nextAttack = love.timer.getTime() + interval
end

-- Calculate total security reduction from upgrades
function threats.calculateSecurityReduction()
    local upgrades = resources.getUpgrades()
    local totalReduction = 0
    
    -- Enhanced security calculation
    if upgrades.basicPacketFilter then
        totalReduction = totalReduction + (upgrades.basicPacketFilter * 0.15)
    end
    if upgrades.advancedFirewall then
        totalReduction = totalReduction + (upgrades.advancedFirewall * 0.25)
    end
    if upgrades.intrusionDetectionSystem then
        totalReduction = totalReduction + (upgrades.intrusionDetectionSystem * 0.35)
    end
    
    -- Cap reduction at 85% (threats should always pose some risk)
    return math.min(totalReduction, 0.85)
end

-- Update threat system (called every frame)
function threats.update(dt)
    local currentTime = love.timer.getTime()
    
    -- Check for triggered attacks
    for _, threat in pairs(threatState.threats) do
        if threat.active and currentTime >= threat.nextAttack then
            threats.executeAttack(threat)
            threats.scheduleNextAttack(threat)
        end
    end
    
    -- Update active effects
    for i = #threatState.activeEffects, 1, -1 do
        local effect = threatState.activeEffects[i]
        effect.duration = effect.duration - dt
        
        if effect.duration <= 0 then
            -- Remove expired effect
            table.remove(threatState.activeEffects, i)
            print("Effect expired: " .. effect.name)
            
            -- Recalculate generation rates when effects end
            resources.recalculateGeneration()
        end
    end
end

-- Execute a specific threat attack
function threats.executeAttack(threat)
    local securityReduction = threats.calculateSecurityReduction()
    
    if threat.type == "steal_resources" then
        threats.executeResourceSteal(threat, securityReduction)
    elseif threat.type == "reduce_generation" then
        threats.executeGenerationReduction(threat, securityReduction)
    end
end

-- Execute resource stealing attack
function threats.executeResourceSteal(threat, securityReduction)
    local currentResources = resources.getResources()
    
    -- Calculate damage with enhanced logic
    local baseDamage
    if threat.damage.percentage then
        -- Percentage-based damage (like ransomware)
        baseDamage = threat.damage.percentage
    else
        -- Range-based damage (like script kiddie)
        baseDamage = math.random() * (threat.damage.max - threat.damage.min) + threat.damage.min
    end
    
    local actualDamage = baseDamage * (1 - securityReduction)
    
    -- Steal Data Bits
    local stolenAmount = math.floor(currentResources.dataBits * actualDamage)
    local currentDB = currentResources.dataBits
    
    -- Update resources directly (this is a special case)
    local gameState = resources.save()
    gameState.resources.dataBits = math.max(0, currentDB - stolenAmount)
    resources.load(gameState)
    
    -- Enhanced attack feedback
    print("🚨 CYBERATTACK! " .. threat.icon .. " " .. threat.name)
    print("   💰 Stolen: " .. stolenAmount .. " Data Bits (" .. 
          string.format("%.1f", actualDamage * 100) .. "% damage)")
    
    if securityReduction > 0 then
        print("   🛡️  Security mitigated " .. string.format("%.1f", securityReduction * 100) .. "% of damage")
    else
        print("   ⚠️  No security defenses active!")
    end
end

-- Execute generation reduction attack
function threats.executeGenerationReduction(threat, securityReduction)
    -- Calculate reduction percentage (reduced by security)
    local baseReduction = threat.damage.reduction
    local actualReduction = baseReduction * (1 - securityReduction)
    local duration = threat.damage.duration
    
    -- Add effect to active effects
    local effect = {
        name = threat.name,
        type = "generation_reduction",
        reduction = actualReduction,
        duration = duration,
        maxDuration = duration,
    }
    
    table.insert(threatState.activeEffects, effect)
    
    -- Enhanced attack feedback
    print("🚨 CYBERATTACK! " .. threat.icon .. " " .. threat.name)
    print("   📉 Generation reduced by " .. string.format("%.1f", actualReduction * 100) .. 
          "% for " .. duration .. " seconds")
    
    if securityReduction > 0 then
        print("   🛡️  Security mitigated " .. string.format("%.1f", securityReduction * 100) .. "% of effect")
    else
        print("   ⚠️  No security defenses active!")
    end
    
    -- Immediately recalculate generation to apply the reduction
    resources.recalculateGeneration()
end

-- Get current threat reduction multiplier for generation
function threats.getGenerationMultiplier()
    local multiplier = 1.0
    
    for _, effect in ipairs(threatState.activeEffects) do
        if effect.type == "generation_reduction" then
            multiplier = multiplier * (1 - effect.reduction)
        end
    end
    
    return multiplier
end

-- Get threat system status for UI display
function threats.getStatus()
    local status = {
        totalSecurity = threats.calculateSecurityReduction(),
        activeEffects = {},
        nextAttacks = {},
    }
    
    -- Copy active effects
    for _, effect in ipairs(threatState.activeEffects) do
        table.insert(status.activeEffects, {
            name = effect.name,
            type = effect.type,
            duration = effect.duration,
            reduction = effect.reduction,
        })
    end
    
    -- Get next attack times
    local currentTime = love.timer.getTime()
    for name, threat in pairs(threatState.threats) do
        if threat.active then
            status.nextAttacks[name] = math.max(0, threat.nextAttack - currentTime)
        end
    end
    
    return status
end

-- Toggle threat system on/off (for debugging/testing)
function threats.setActive(active)
    for _, threat in pairs(threatState.threats) do
        threat.active = active
    end
    
    if not active then
        -- Clear active effects when disabling
        threatState.activeEffects = {}
        resources.recalculateGeneration()
    end
    
    print("Threat system " .. (active and "enabled" or "disabled"))
end

return threats