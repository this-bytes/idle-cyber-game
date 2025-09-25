-- Resource Management System
-- Handles all resource tracking, generation, and calculations

local resources = {}

-- Core resource structure
local gameState = {
    resources = {
        dataBits = 0,           -- Data Bits (DB) - primary currency
        processingPower = 0,    -- Processing Power (PP) - computational muscle
        securityRating = 0,     -- Security Rating (SR) - defensive strength
    },
    
    generation = {
        dataBits = 0,           -- DB per second
        processingPower = 0,    -- PP per second
        securityRating = 0,     -- SR per second (usually from upgrades)
    },
    
    multipliers = {
        dataBits = 1.0,         -- DB generation multiplier (affected by PP)
        processingPower = 1.0,  -- PP generation multiplier
        securityRating = 1.0,   -- SR generation multiplier
    },
    
    -- Click mechanics
    clickPower = 1,             -- DB per click
    clickCombo = 1,             -- Current click multiplier (1-5x)
    lastClickTime = 0,          -- For combo tracking
    comboDecayTime = 2.0,       -- Seconds before combo starts decaying
    
    -- Upgrades (enhanced for better gameplay)
    upgrades = {
        -- Manual clicking upgrades
        ergonomicMouse = false,              -- +1 DB/click
        mechanicalKeyboard = false,          -- +2 DB/click  
        gamingSetup = false,                 -- +5 DB/click, enhanced combos
        hapticFeedbackGloves = false,        -- +20 DB/click, 2x critical chance
        
        -- Basic server infrastructure
        refurbishedDesktop = 0,              -- 0.1 DB/sec each
        basicServerRack = 0,                 -- 1 DB/sec each
        smallDataCenter = 0,                 -- 10 DB/sec each
        enterpriseDataCenter = 0,            -- 100 DB/sec each
        hyperscaleCloudFarm = 0,             -- 1000 DB/sec each
        
        -- Processing power infrastructure
        singleCoreProcessor = 0,             -- 0.1 PP/sec, 1.1x DB multiplier
        multiCoreArray = 0,                  -- 1 PP/sec, 1.2x DB multiplier
        parallelProcessingGrid = 0,          -- 10 PP/sec, 1.5x DB multiplier
        quantumProcessor = 0,                -- 100 PP/sec, 2.0x DB multiplier
        
        -- Security infrastructure
        basicPacketFilter = 0,               -- 15% threat reduction per unit
        advancedFirewall = 0,                -- 25% threat reduction per unit
        intrusionDetectionSystem = 0,        -- 35% threat reduction per unit
    }
}

-- Initialize resource system
function resources.init()
    -- Start with some basic resources for testing and better game feel
    gameState.resources.dataBits = 10  -- Give players a head start
    gameState.resources.processingPower = 0
    gameState.resources.securityRating = 100  -- Start with basic security
    
    -- Reset last click time
    gameState.lastClickTime = love.timer.getTime()
    
    -- Calculate initial generation rates
    resources.recalculateGeneration()
    
    print("💻 Resource system initialized")
    print("   💎 Data Bits: " .. gameState.resources.dataBits)
    print("   ⚡ Processing Power: " .. gameState.resources.processingPower)  
    print("   🛡️  Security Rating: " .. gameState.resources.securityRating)
end

-- Manual click for Data Bits
function resources.clickForDataBits()
    local currentTime = love.timer.getTime()
    local timeSinceLastClick = currentTime - gameState.lastClickTime
    
    -- Update click combo
    if timeSinceLastClick <= gameState.comboDecayTime then
        gameState.clickCombo = math.min(gameState.clickCombo + 0.2, 5.0)
    else
        gameState.clickCombo = 1.0
    end
    
    gameState.lastClickTime = currentTime
    
    -- Calculate click reward
    local baseReward = gameState.clickPower
    local comboMultiplier = gameState.clickCombo
    
    -- Enhanced critical hit chance (5% base + processing power bonus)
    local critChance = 0.05 + (gameState.resources.processingPower * 0.0005)
    local isCritical = math.random() < critChance
    local criticalMultiplier = isCritical and 10 or 1
    
    local reward = math.floor(baseReward * comboMultiplier * criticalMultiplier)
    
    -- Add to resources
    gameState.resources.dataBits = gameState.resources.dataBits + reward
    
    -- Track achievement progress
    local achievements = require("achievements")
    achievements.trackClick(reward, comboMultiplier, isCritical)
    achievements.trackDataEarned(reward)
    
    -- Enhanced feedback
    if isCritical then
        print("💥 CRITICAL HIT! +" .. reward .. " Data Bits!")
    elseif comboMultiplier > 2.0 then
        print("🔥 COMBO x" .. string.format("%.1f", comboMultiplier) .. "! +" .. reward .. " Data Bits!")
    end
    
    return {
        reward = reward,
        combo = comboMultiplier,
        critical = isCritical
    }
end

-- Update resource generation (called every frame)
function resources.update(dt)
    -- Update click combo decay
    local currentTime = love.timer.getTime()
    local timeSinceLastClick = currentTime - gameState.lastClickTime
    
    if timeSinceLastClick > gameState.comboDecayTime then
        gameState.clickCombo = math.max(gameState.clickCombo - dt * 2, 1.0)
    end
    
    -- Generate resources based on per-second rates
    -- Apply threat-based generation reduction if threats module is available
    local threatMultiplier = 1.0
    if package.loaded.threats then
        threatMultiplier = require("threats").getGenerationMultiplier()
    end
    
    gameState.resources.dataBits = gameState.resources.dataBits + 
        (gameState.generation.dataBits * gameState.multipliers.dataBits * threatMultiplier * dt)
    
    gameState.resources.processingPower = gameState.resources.processingPower + 
        (gameState.generation.processingPower * gameState.multipliers.processingPower * threatMultiplier * dt)
    
    gameState.resources.securityRating = gameState.resources.securityRating + 
        (gameState.generation.securityRating * gameState.multipliers.securityRating * threatMultiplier * dt)
end

-- Recalculate generation rates based on current upgrades
function resources.recalculateGeneration()
    -- Reset generation
    gameState.generation.dataBits = 0
    gameState.generation.processingPower = 0
    gameState.generation.securityRating = 0
    
    -- Calculate click power with enhanced upgrades
    gameState.clickPower = 1
    if gameState.upgrades.ergonomicMouse then gameState.clickPower = gameState.clickPower + 1 end
    if gameState.upgrades.mechanicalKeyboard then gameState.clickPower = gameState.clickPower + 2 end
    if gameState.upgrades.gamingSetup then gameState.clickPower = gameState.clickPower + 5 end
    if gameState.upgrades.hapticFeedbackGloves then gameState.clickPower = gameState.clickPower + 20 end
    
    -- Calculate DB generation from infrastructure
    gameState.generation.dataBits = gameState.generation.dataBits + 
        (gameState.upgrades.refurbishedDesktop * 0.1)
    gameState.generation.dataBits = gameState.generation.dataBits + 
        (gameState.upgrades.basicServerRack * 1.0)
    gameState.generation.dataBits = gameState.generation.dataBits + 
        (gameState.upgrades.smallDataCenter * 10.0)
    gameState.generation.dataBits = gameState.generation.dataBits + 
        (gameState.upgrades.enterpriseDataCenter * 100.0)
    gameState.generation.dataBits = gameState.generation.dataBits + 
        (gameState.upgrades.hyperscaleCloudFarm * 1000.0)
    
    -- Calculate PP generation
    gameState.generation.processingPower = gameState.generation.processingPower + 
        (gameState.upgrades.singleCoreProcessor * 0.1)
    gameState.generation.processingPower = gameState.generation.processingPower + 
        (gameState.upgrades.multiCoreArray * 1.0)
    gameState.generation.processingPower = gameState.generation.processingPower + 
        (gameState.upgrades.parallelProcessingGrid * 10.0)
    gameState.generation.processingPower = gameState.generation.processingPower + 
        (gameState.upgrades.quantumProcessor * 100.0)
    
    -- Calculate DB multiplier from PP (enhanced scaling)
    local ppMultiplier = 1.0
    ppMultiplier = ppMultiplier + (gameState.upgrades.singleCoreProcessor * 0.1)      -- 1.1x per unit
    ppMultiplier = ppMultiplier + (gameState.upgrades.multiCoreArray * 0.2)           -- 1.2x per unit  
    ppMultiplier = ppMultiplier + (gameState.upgrades.parallelProcessingGrid * 0.5)   -- 1.5x per unit
    ppMultiplier = ppMultiplier + (gameState.upgrades.quantumProcessor * 1.0)         -- 2.0x per unit
    
    gameState.multipliers.dataBits = ppMultiplier
    
    -- Debug output for significant changes
    if gameState.generation.dataBits > 0 or gameState.generation.processingPower > 0 then
        print("📊 Generation recalculated:")
        print("   💎 DB/sec: " .. string.format("%.1f", gameState.generation.dataBits) .. 
              " (x" .. string.format("%.1f", ppMultiplier) .. ")")
        print("   ⚡ PP/sec: " .. string.format("%.1f", gameState.generation.processingPower))
    end
end

-- Purchase upgrade
function resources.purchaseUpgrade(upgradeName, cost)
    if gameState.resources.dataBits >= cost then
        gameState.resources.dataBits = gameState.resources.dataBits - cost
        
        -- Apply upgrade (enhanced for new upgrades)
        local oneTimeUpgrades = {
            "ergonomicMouse", "mechanicalKeyboard", "gamingSetup", "hapticFeedbackGloves"
        }
        
        local isOneTime = false
        for _, upgrade in ipairs(oneTimeUpgrades) do
            if upgradeName == upgrade then
                gameState.upgrades[upgradeName] = true
                isOneTime = true
                break
            end
        end
        
        if not isOneTime then
            gameState.upgrades[upgradeName] = gameState.upgrades[upgradeName] + 1
        end
        
        -- Track achievement progress
        local achievements = require("achievements")
        achievements.trackUpgradePurchase(upgradeName, cost)
        
        -- Recalculate rates
        resources.recalculateGeneration()
        
        -- Success feedback
        print("🛒 Purchased: " .. upgradeName .. " (-" .. cost .. " DB)")
        
        return true
    end
    print("❌ Insufficient Data Bits for " .. upgradeName .. " (need " .. cost .. " DB)")
    return false
end

-- Get current resource values
function resources.getResources()
    return {
        dataBits = gameState.resources.dataBits,
        processingPower = gameState.resources.processingPower,
        securityRating = gameState.resources.securityRating,
    }
end

-- Get current generation rates (with zone bonuses)
function resources.getGeneration()
    local baseGeneration = {
        dataBits = gameState.generation.dataBits * gameState.multipliers.dataBits,
        processingPower = gameState.generation.processingPower * gameState.multipliers.processingPower,
        securityRating = gameState.generation.securityRating * gameState.multipliers.securityRating,
    }
    
    -- Apply zone bonuses
    local achievements = require("achievements")
    local zoneBonus = achievements.getCurrentZoneBonus()
    
    return {
        dataBits = baseGeneration.dataBits * zoneBonus.dataBitsMultiplier,
        processingPower = baseGeneration.processingPower,
        securityRating = baseGeneration.securityRating,
    }
end

-- Get click information
function resources.getClickInfo()
    return {
        power = gameState.clickPower,
        combo = gameState.clickCombo,
        maxCombo = 5.0,
    }
end

-- Get upgrade information
function resources.getUpgrades()
    return gameState.upgrades
end

-- Save/Load functionality (for later persistence)
function resources.save()
    return gameState
end

function resources.load(savedState)
    if savedState then
        gameState = savedState
        resources.recalculateGeneration()
    end
end

return resources