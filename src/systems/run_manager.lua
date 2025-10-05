-- Run Manager System - Manages roguelike run state and progression
-- Handles ante/wave progression, scoring, and run lifecycle
-- Core system for card-based roguelike gameplay

local RunManager = {}
RunManager.__index = RunManager

-- System metadata for automatic registration
RunManager.metadata = {
    priority = 55,
    dependencies = {"ResourceManager"},
    systemName = "RunManager"
}

-- Run states
local RUN_STATES = {
    MENU = "menu",           -- Not in a run
    WAVE = "wave",           -- Active wave combat
    SHOP = "shop",           -- Between waves shopping
    VICTORY = "victory",     -- Run completed successfully
    DEFEAT = "defeat"        -- Run failed
}

-- Wave configuration
local WAVE_CONFIG = {
    [1] = {threats = 5, boss = false, reward = 100},
    [2] = {threats = 7, boss = true, reward = 200},
    [3] = {threats = 10, boss = true, mega = true, reward = 500}
}

function RunManager.new(eventBus, resourceManager)
    local self = setmetatable({}, RunManager)
    self.eventBus = eventBus
    self.resourceManager = resourceManager
    
    -- Current run state
    self.currentRun = nil
    self.runState = RUN_STATES.MENU
    
    -- Statistics tracking
    self.totalRuns = 0
    self.totalVictories = 0
    self.highScore = 0
    self.unlockedCards = {}
    
    return self
end

function RunManager:initialize()
    -- Subscribe to run events
    if self.eventBus then
        self.eventBus:subscribe("start_run", function(data)
            self:startRun(data.ante or 1)
        end)
        
        self.eventBus:subscribe("wave_complete", function(data)
            self:completeWave(data.success)
        end)
        
        self.eventBus:subscribe("forfeit_run", function()
            self:endRun(false)
        end)
    end
end

-- Start a new run
function RunManager:startRun(ante)
    ante = ante or 1
    
    self.currentRun = {
        ante = ante,                    -- Difficulty level (1-8)
        wave = 1,                       -- Current wave (1-3)
        score = 0,                      -- Run score
        currency = 100,                 -- Shop currency for this run
        threatsDefeated = 0,
        cardsPlayed = 0,
        startTime = os.time(),
        perfectWaves = 0                -- Waves with no damage taken
    }
    
    self.runState = RUN_STATES.WAVE
    self.totalRuns = self.totalRuns + 1
    
    -- Publish event for other systems
    if self.eventBus then
        self.eventBus:publish("run_started", {
            ante = ante,
            wave = 1
        })
    end
    
    print(string.format("🎮 Run started: Ante %d, Wave 1", ante))
    return true
end

-- Complete current wave
function RunManager:completeWave(success)
    if not self.currentRun then return end
    
    local waveConfig = WAVE_CONFIG[self.currentRun.wave]
    
    if success then
        -- Award currency and score
        local reward = waveConfig.reward * self.currentRun.ante
        self.currentRun.currency = self.currentRun.currency + reward
        self.currentRun.score = self.currentRun.score + reward
        
        print(string.format("✅ Wave %d complete! +$%d", self.currentRun.wave, reward))
        
        -- Check if run is complete
        if self.currentRun.wave >= 3 then
            self:endRun(true)
        else
            -- Advance to next wave
            self.currentRun.wave = self.currentRun.wave + 1
            self.runState = RUN_STATES.SHOP
            
            if self.eventBus then
                self.eventBus:publish("shop_opened", {
                    currency = self.currentRun.currency,
                    wave = self.currentRun.wave
                })
            end
        end
    else
        -- Wave failed
        print("❌ Wave failed!")
        self:endRun(false)
    end
end

-- Continue to next wave from shop
function RunManager:continueToNextWave()
    if not self.currentRun then return end
    
    self.runState = RUN_STATES.WAVE
    
    if self.eventBus then
        self.eventBus:publish("wave_started", {
            ante = self.currentRun.ante,
            wave = self.currentRun.wave
        })
    end
    
    print(string.format("🎯 Starting Wave %d", self.currentRun.wave))
end

-- End the run (victory or defeat)
function RunManager:endRun(victory)
    if not self.currentRun then return end
    
    -- Calculate final score
    local finalScore = self:calculateScore()
    self.currentRun.score = finalScore
    
    -- Update statistics
    if victory then
        self.totalVictories = self.totalVictories + 1
        self.runState = RUN_STATES.VICTORY
        print(string.format("🏆 VICTORY! Final Score: %d", finalScore))
    else
        self.runState = RUN_STATES.DEFEAT
        print(string.format("💀 DEFEAT. Final Score: %d", finalScore))
    end
    
    -- Update high score
    if finalScore > self.highScore then
        self.highScore = finalScore
        print(string.format("🌟 NEW HIGH SCORE: %d", finalScore))
    end
    
    -- Unlock rewards based on score/ante
    self:unlockRewards(victory, finalScore)
    
    -- Publish run ended event
    if self.eventBus then
        self.eventBus:publish("run_ended", {
            victory = victory,
            score = finalScore,
            ante = self.currentRun.ante,
            wave = self.currentRun.wave
        })
    end
    
    -- Keep run data for results screen, but mark as ended
    self.currentRun.ended = true
end

-- Calculate final score
function RunManager:calculateScore()
    if not self.currentRun then return 0 end
    
    local score = 0
    
    -- Base score from threats defeated
    score = score + (self.currentRun.threatsDefeated * 50)
    
    -- Bonus for ante difficulty
    score = score + (self.currentRun.ante * 500)
    
    -- Bonus for perfect waves
    score = score + (self.currentRun.perfectWaves * 250)
    
    -- Time bonus (faster is better)
    local duration = os.time() - self.currentRun.startTime
    local timeBonus = math.max(0, 1000 - duration * 2)
    score = score + timeBonus
    
    -- Efficiency bonus (fewer cards played is better)
    if self.currentRun.cardsPlayed > 0 then
        local efficiency = self.currentRun.threatsDefeated / self.currentRun.cardsPlayed
        score = score + math.floor(efficiency * 100)
    end
    
    return score
end

-- Unlock rewards based on performance
function RunManager:unlockRewards(victory, score)
    -- Unlock new cards based on ante cleared
    if victory and self.currentRun.ante >= 1 then
        -- Basic unlocks at ante 1
        table.insert(self.unlockedCards, "senior_analyst")
    end
    
    if victory and self.currentRun.ante >= 2 then
        -- Advanced unlocks at ante 2
        table.insert(self.unlockedCards, "threat_hunter")
    end
    
    -- Could add more unlocks, achievements, etc.
end

-- Add threat defeat
function RunManager:addThreatDefeated()
    if self.currentRun then
        self.currentRun.threatsDefeated = self.currentRun.threatsDefeated + 1
    end
end

-- Track card played
function RunManager:addCardPlayed()
    if self.currentRun then
        self.currentRun.cardsPlayed = self.currentRun.cardsPlayed + 1
    end
end

-- Mark wave as perfect (no damage)
function RunManager:markWavePerfect()
    if self.currentRun then
        self.currentRun.perfectWaves = self.currentRun.perfectWaves + 1
    end
end

-- Getters
function RunManager:isInRun()
    return self.currentRun and not self.currentRun.ended
end

function RunManager:getCurrentAnte()
    return self.currentRun and self.currentRun.ante or 1
end

function RunManager:getCurrentWave()
    return self.currentRun and self.currentRun.wave or 1
end

function RunManager:getRunState()
    return self.runState
end

function RunManager:getCurrency()
    return self.currentRun and self.currentRun.currency or 0
end

function RunManager:getWaveConfig(wave)
    wave = wave or (self.currentRun and self.currentRun.wave or 1)
    return WAVE_CONFIG[wave]
end

-- State management for GameStateEngine
function RunManager:getState()
    return {
        totalRuns = self.totalRuns,
        totalVictories = self.totalVictories,
        highScore = self.highScore,
        unlockedCards = self.unlockedCards,
        currentRun = self.currentRun,
        runState = self.runState
    }
end

function RunManager:loadState(state)
    if not state then return end
    
    self.totalRuns = state.totalRuns or 0
    self.totalVictories = state.totalVictories or 0
    self.highScore = state.highScore or 0
    self.unlockedCards = state.unlockedCards or {}
    self.currentRun = state.currentRun
    self.runState = state.runState or RUN_STATES.MENU
end

return RunManager
