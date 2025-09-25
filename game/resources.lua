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
    
    -- Upgrades (basic set for Phase 1)
    upgrades = {
        -- Manual clicking upgrades
        ergonomicMouse = false,     -- +1 DB/click
        mechanicalKeyboard = false, -- +2 DB/click  
        gamingSetup = false,        -- +5 DB/click, enables combos
        
        -- Basic server infrastructure
        refurbishedDesktop = 0,     -- 0.1 DB/sec each
        basicServerRack = 0,        -- 1 DB/sec each
        smallDataCenter = 0,        -- 10 DB/sec each
        
        -- Processing power infrastructure
        singleCoreProcessor = 0,    -- 0.1 PP/sec, 1.1x DB multiplier
        multiCoreArray = 0,         -- 1 PP/sec, 1.2x DB multiplier
        parallelProcessingGrid = 0, -- 10 PP/sec, 1.5x DB multiplier
    }
}

-- Initialize resource system
function resources.init()
    -- Start with some basic resources for testing
    gameState.resources.dataBits = 0
    gameState.resources.processingPower = 0
    gameState.resources.securityRating = 0
    
    -- Calculate initial generation rates
    resources.recalculateGeneration()
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
    
    -- 5% chance for critical click (10x reward)
    local isCritical = math.random() < 0.05
    local criticalMultiplier = isCritical and 10 or 1
    
    local reward = baseReward * comboMultiplier * criticalMultiplier
    
    -- Add to resources
    gameState.resources.dataBits = gameState.resources.dataBits + reward
    
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
    gameState.resources.dataBits = gameState.resources.dataBits + 
        (gameState.generation.dataBits * gameState.multipliers.dataBits * dt)
    
    gameState.resources.processingPower = gameState.resources.processingPower + 
        (gameState.generation.processingPower * gameState.multipliers.processingPower * dt)
    
    gameState.resources.securityRating = gameState.resources.securityRating + 
        (gameState.generation.securityRating * gameState.multipliers.securityRating * dt)
end

-- Recalculate generation rates based on current upgrades
function resources.recalculateGeneration()
    -- Reset generation
    gameState.generation.dataBits = 0
    gameState.generation.processingPower = 0
    gameState.generation.securityRating = 0
    
    -- Calculate click power
    gameState.clickPower = 1
    if gameState.upgrades.ergonomicMouse then gameState.clickPower = gameState.clickPower + 1 end
    if gameState.upgrades.mechanicalKeyboard then gameState.clickPower = gameState.clickPower + 2 end
    if gameState.upgrades.gamingSetup then gameState.clickPower = gameState.clickPower + 5 end
    
    -- Calculate DB generation from infrastructure
    gameState.generation.dataBits = gameState.generation.dataBits + 
        (gameState.upgrades.refurbishedDesktop * 0.1)
    gameState.generation.dataBits = gameState.generation.dataBits + 
        (gameState.upgrades.basicServerRack * 1.0)
    gameState.generation.dataBits = gameState.generation.dataBits + 
        (gameState.upgrades.smallDataCenter * 10.0)
    
    -- Calculate PP generation
    gameState.generation.processingPower = gameState.generation.processingPower + 
        (gameState.upgrades.singleCoreProcessor * 0.1)
    gameState.generation.processingPower = gameState.generation.processingPower + 
        (gameState.upgrades.multiCoreArray * 1.0)
    gameState.generation.processingPower = gameState.generation.processingPower + 
        (gameState.upgrades.parallelProcessingGrid * 10.0)
    
    -- Calculate DB multiplier from PP
    local ppMultiplier = 1.0
    ppMultiplier = ppMultiplier + (gameState.upgrades.singleCoreProcessor * 0.1)      -- 1.1x per unit
    ppMultiplier = ppMultiplier + (gameState.upgrades.multiCoreArray * 0.2)           -- 1.2x per unit  
    ppMultiplier = ppMultiplier + (gameState.upgrades.parallelProcessingGrid * 0.5)   -- 1.5x per unit
    
    gameState.multipliers.dataBits = ppMultiplier
end

-- Purchase upgrade
function resources.purchaseUpgrade(upgradeName, cost)
    if gameState.resources.dataBits >= cost then
        gameState.resources.dataBits = gameState.resources.dataBits - cost
        
        -- Apply upgrade
        if upgradeName == "ergonomicMouse" or upgradeName == "mechanicalKeyboard" or upgradeName == "gamingSetup" then
            gameState.upgrades[upgradeName] = true
        else
            gameState.upgrades[upgradeName] = gameState.upgrades[upgradeName] + 1
        end
        
        -- Recalculate rates
        resources.recalculateGeneration()
        return true
    end
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

-- Get current generation rates
function resources.getGeneration()
    return {
        dataBits = gameState.generation.dataBits * gameState.multipliers.dataBits,
        processingPower = gameState.generation.processingPower * gameState.multipliers.processingPower,
        securityRating = gameState.generation.securityRating * gameState.multipliers.securityRating,
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