-- IdleGame - Simplified Core Idle Cybersecurity Game
-- Focus on core idle game principles: passive income, contracts, offline progress
-- Single unified controller without complex systems

local IdleGame = {}
IdleGame.__index = IdleGame

-- JSON decoder for loading data
local json = require("dkjson")

-- Game states for clean flow
local GAME_STATES = {
    SPLASH = "splash",
    PLAYING = "playing",
    OFFLINE_MODAL = "offline_modal"
}

-- Create new idle game
function IdleGame.new()
    local self = setmetatable({}, IdleGame)
    
    -- Core game state
    self.initialized = false
    self.currentState = GAME_STATES.SPLASH
    self.gameTime = 0
    
    -- Resources (core idle game currencies)
    self.resources = {
        money = 1000,
        reputation = 10,
        experience = 0
    }
    
    -- Money generation (core idle mechanic)
    self.moneyGeneration = {
        baseRate = 10, -- $10 per second base
        multiplier = 1.0,
        lastUpdate = 0
    }
    
    -- Contract system (simple version)
    self.contracts = {}
    self.activeContract = nil
    
    -- Auto-contract system
    self.autoContracts = {
        enabled = false,
        completionTime = 30, -- 30 seconds per contract
        lastCompletion = 0
    }
    
    -- Offline progress tracking
    self.offline = {
        lastSaveTime = 0,
        showModal = false,
        moneyEarned = 0,
        contractsCompleted = 0
    }
    
    -- UI state
    self.splashTime = 0
    self.splashMinTime = 2.0
    
    return self
end

-- Initialize the game
function IdleGame:initialize()
    print("💼 Initializing Core Idle Game...")
    
    -- Load game data
    self:loadGameData()
    
    -- Calculate offline progress
    self:calculateOfflineProgress()
    
    -- Set initial state
    self.currentState = GAME_STATES.SPLASH
    self.moneyGeneration.lastUpdate = love.timer.getTime()
    self.autoContracts.lastCompletion = love.timer.getTime()
    
    self.initialized = true
    print("✅ Core Idle Game initialized!")
    return true
end

-- Load core game data from JSON files
function IdleGame:loadGameData()
    print("📊 Loading core game data...")
    
    -- Load contracts
    self:loadContracts()
    
    -- Update money generation rate based on reputation
    self:updateMoneyGenerationRate()
    
    print("📊 Core game data loaded")
end

-- Load contracts from JSON
function IdleGame:loadContracts()
    if love.filesystem.getInfo("src/data/contracts.json") then
        local content = love.filesystem.read("src/data/contracts.json")
        local data, pos, err = json.decode(content)
        if data then
            self.contracts = data
            print("   ✅ Loaded " .. #data .. " contracts")
        else
            print("   ❌ Failed to parse contracts: " .. tostring(err))
            self.contracts = {}
        end
    else
        print("   ❌ contracts.json not found")
        self.contracts = {}
    end
end

-- Update money generation rate based on reputation (core idle mechanic)
function IdleGame:updateMoneyGenerationRate()
    -- Base rate starts at $10/sec
    local baseRate = 10
    
    -- Reputation bonus: 50 cents per reputation point
    baseRate = baseRate + (self.resources.reputation * 0.5)
    
    self.moneyGeneration.baseRate = baseRate
    print("💰 Money generation: $" .. string.format("%.2f", baseRate) .. "/sec")
end

-- Calculate offline progress (key idle game feature)
function IdleGame:calculateOfflineProgress()
    local currentTime = love.timer.getTime()
    
    -- If this is first run or no save time, set it
    if self.offline.lastSaveTime == 0 then
        self.offline.lastSaveTime = currentTime
        return
    end
    
    local offlineTime = currentTime - self.offline.lastSaveTime
    
    -- Only show offline progress if away for more than 30 seconds
    if offlineTime > 30 then
        -- Calculate money earned while offline
        local moneyEarned = math.floor(offlineTime * self.moneyGeneration.baseRate)
        
        -- Calculate contracts completed (1 per minute)
        local contractsCompleted = math.floor(offlineTime / 60)
        
        -- Apply offline earnings
        self.resources.money = self.resources.money + moneyEarned
        self.resources.reputation = self.resources.reputation + contractsCompleted
        
        -- Store for modal display
        self.offline.moneyEarned = moneyEarned
        self.offline.contractsCompleted = contractsCompleted
        self.offline.showModal = true
        
        print("💤 Offline progress: $" .. moneyEarned .. " earned, " .. contractsCompleted .. " contracts completed")
    end
    
    -- Update save time
    self.offline.lastSaveTime = currentTime
end

-- Main update loop
function IdleGame:update(dt)
    if not self.initialized then
        return
    end
    
    self.gameTime = self.gameTime + dt
    
    -- Handle different game states
    if self.currentState == GAME_STATES.SPLASH then
        self:updateSplash(dt)
    elseif self.currentState == GAME_STATES.PLAYING then
        self:updatePlaying(dt)
    end
end

-- Update splash screen
function IdleGame:updateSplash(dt)
    self.splashTime = self.splashTime + dt
    
    -- Auto-advance after minimum time
    if self.splashTime > self.splashMinTime + 2.0 then
        self:advanceToGame()
    end
end

-- Advance from splash to main game
function IdleGame:advanceToGame()
    if self.offline.showModal then
        self.currentState = GAME_STATES.OFFLINE_MODAL
    else
        self.currentState = GAME_STATES.PLAYING
    end
end

-- Update main game state
function IdleGame:updatePlaying(dt)
    -- Update money generation (core idle mechanic)
    self:updateMoneyGeneration(dt)
    
    -- Update auto-contracts if enabled
    if self.autoContracts.enabled then
        self:updateAutoContracts(dt)
    end
    
    -- Update active contract
    if self.activeContract then
        self:updateActiveContract(dt)
    end
end

-- Update money generation
function IdleGame:updateMoneyGeneration(dt)
    local currentTime = love.timer.getTime()
    local timeDelta = currentTime - self.moneyGeneration.lastUpdate
    
    if timeDelta >= 1.0 then -- Update every second
        local moneyToAdd = math.floor(timeDelta * self.moneyGeneration.baseRate)
        self.resources.money = self.resources.money + moneyToAdd
        self.moneyGeneration.lastUpdate = currentTime
    end
end

-- Update auto-contract system
function IdleGame:updateAutoContracts(dt)
    local currentTime = love.timer.getTime()
    local timeDelta = currentTime - self.autoContracts.lastCompletion
    
    if timeDelta >= self.autoContracts.completionTime then
        self:completeAutoContract()
        self.autoContracts.lastCompletion = currentTime
    end
end

-- Complete an automatic contract
function IdleGame:completeAutoContract()
    -- Find first available contract
    if #self.contracts > 0 then
        local contract = self.contracts[1]
        
        -- Add rewards
        self.resources.money = self.resources.money + (contract.baseBudget or 100)
        self.resources.reputation = self.resources.reputation + (contract.reputationReward or 1)
        self.resources.experience = self.resources.experience + 10
        
        -- Update money generation rate
        self:updateMoneyGenerationRate()
        
        print("🤖 Auto-completed contract: " .. (contract.clientName or "Unknown"))
    end
end

-- Update active contract
function IdleGame:updateActiveContract(dt)
    if self.activeContract then
        self.activeContract.timeRemaining = self.activeContract.timeRemaining - dt
        
        if self.activeContract.timeRemaining <= 0 then
            self:completeContract(self.activeContract)
            self.activeContract = nil
        end
    end
end

-- Complete a contract manually
function IdleGame:completeContract(contract)
    -- Add rewards
    self.resources.money = self.resources.money + contract.baseBudget
    self.resources.reputation = self.resources.reputation + contract.reputationReward
    self.resources.experience = self.resources.experience + 20
    
    -- Update money generation rate
    self:updateMoneyGenerationRate()
    
    print("✅ Completed contract: " .. contract.clientName)
end

-- Start a contract
function IdleGame:startContract(contractIndex)
    if self.activeContract then
        print("❌ Already working on a contract")
        return
    end
    
    if contractIndex >= 1 and contractIndex <= #self.contracts then
        local contract = self.contracts[contractIndex]
        self.activeContract = {
            id = contract.id,
            clientName = contract.clientName,
            baseBudget = contract.baseBudget,
            reputationReward = contract.reputationReward,
            timeRemaining = contract.baseDuration or 30
        }
        print("🚀 Started contract: " .. contract.clientName)
    end
end

-- Main draw function
function IdleGame:draw()
    if not self.initialized then
        love.graphics.print("Initializing...", 10, 10)
        return
    end
    
    -- Draw based on current state
    if self.currentState == GAME_STATES.SPLASH then
        self:drawSplash()
    elseif self.currentState == GAME_STATES.OFFLINE_MODAL then
        self:drawOfflineModal()
    elseif self.currentState == GAME_STATES.PLAYING then
        self:drawGame()
    end
end

-- Draw splash screen
function IdleGame:drawSplash()
    local w, h = love.graphics.getDimensions()
    
    -- Background
    love.graphics.setColor(0.1, 0.1, 0.2, 1)
    love.graphics.rectangle("fill", 0, 0, w, h)
    
    -- Title
    love.graphics.setColor(0, 1, 1, 1)
    love.graphics.printf("💼 CYBER EMPIRE COMMAND", 0, h/2 - 60, w, "center")
    love.graphics.printf("Core Idle Game", 0, h/2 - 30, w, "center")
    
    -- Instructions
    love.graphics.setColor(1, 1, 1, 0.7)
    if self.splashTime > self.splashMinTime then
        love.graphics.printf("Press any key to continue", 0, h/2 + 20, w, "center")
    else
        love.graphics.printf("Loading...", 0, h/2 + 20, w, "center")
    end
    
    love.graphics.setColor(1, 1, 1, 1)
end

-- Draw offline modal
function IdleGame:drawOfflineModal()
    local w, h = love.graphics.getDimensions()
    
    -- Background
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, w, h)
    
    -- Modal
    local modalW, modalH = 400, 200
    local modalX, modalY = (w - modalW) / 2, (h - modalH) / 2
    
    love.graphics.setColor(0.2, 0.2, 0.3, 1)
    love.graphics.rectangle("fill", modalX, modalY, modalW, modalH)
    
    love.graphics.setColor(0, 1, 1, 1)
    love.graphics.rectangle("line", modalX, modalY, modalW, modalH)
    
    -- Title
    love.graphics.setColor(0, 1, 1, 1)
    love.graphics.printf("💤 While You Were Away", modalX, modalY + 20, modalW, "center")
    
    -- Progress info
    love.graphics.setColor(0, 1, 0, 1)
    love.graphics.printf("💰 Money Earned: $" .. self.offline.moneyEarned, modalX, modalY + 60, modalW, "center")
    love.graphics.printf("⭐ Contracts Completed: " .. self.offline.contractsCompleted, modalX, modalY + 80, modalW, "center")
    
    -- Instructions
    love.graphics.setColor(1, 1, 1, 0.7)
    love.graphics.printf("Press any key to continue", modalX, modalY + 140, modalW, "center")
    
    love.graphics.setColor(1, 1, 1, 1)
end

-- Draw main game interface
function IdleGame:drawGame()
    local w, h = love.graphics.getDimensions()
    
    -- Background
    love.graphics.setColor(0.05, 0.05, 0.1, 1)
    love.graphics.rectangle("fill", 0, 0, w, h)
    
    -- Title
    love.graphics.setColor(0, 1, 1, 1)
    love.graphics.print("💼 Cyber Empire Command - Core Idle Game", 10, 10)
    
    -- Resources
    love.graphics.setColor(0, 1, 0, 1)
    love.graphics.print(string.format("💰 Money: $%d (+ $%.1f/sec)", self.resources.money, self.moneyGeneration.baseRate), 10, 40)
    love.graphics.print(string.format("⭐ Reputation: %d", self.resources.reputation), 10, 60)
    love.graphics.print(string.format("📚 Experience: %d", self.resources.experience), 10, 80)
    
    -- Auto-contract status
    local autoStatus = self.autoContracts.enabled and "ON" or "OFF"
    love.graphics.setColor(self.autoContracts.enabled and {0, 1, 0} or {1, 1, 1})
    love.graphics.print("🤖 Auto-Contracts: " .. autoStatus .. " (SPACE to toggle)", 10, 110)
    
    -- Active contract
    if self.activeContract then
        love.graphics.setColor(1, 0.5, 0, 1)
        love.graphics.print(string.format("🔥 Working on: %s (%.1fs remaining)", 
                           self.activeContract.clientName, self.activeContract.timeRemaining), 10, 140)
    end
    
    -- Available contracts
    love.graphics.setColor(1, 1, 0, 1)
    love.graphics.print("📋 Available Contracts:", 10, 180)
    
    local y = 200
    for i, contract in ipairs(self.contracts) do
        if i <= 5 then -- Show first 5 contracts
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print(string.format("  %d. %s - $%d, +%d rep (%ds)", 
                              i, contract.clientName or "Unknown", 
                              contract.baseBudget or 100,
                              contract.reputationReward or 1,
                              contract.baseDuration or 30), 10, y)
            y = y + 20
        end
    end
    
    -- Instructions
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.print("Press 1-5 to start contracts, SPACE for auto-contracts, ESC to quit", 10, h - 20)
    
    love.graphics.setColor(1, 1, 1, 1)
end

-- Handle key presses
function IdleGame:keypressed(key)
    if self.currentState == GAME_STATES.SPLASH then
        if self.splashTime > self.splashMinTime then
            self:advanceToGame()
        end
    elseif self.currentState == GAME_STATES.OFFLINE_MODAL then
        self.offline.showModal = false
        self.currentState = GAME_STATES.PLAYING
    elseif self.currentState == GAME_STATES.PLAYING then
        -- Contract selection
        if key >= "1" and key <= "5" then
            local contractIndex = tonumber(key)
            self:startContract(contractIndex)
        elseif key == "space" then
            -- Toggle auto-contracts
            self.autoContracts.enabled = not self.autoContracts.enabled
            print("🤖 Auto-contracts " .. (self.autoContracts.enabled and "enabled" or "disabled"))
        end
    end
end

-- Shutdown
function IdleGame:shutdown()
    -- Update save time for offline progress
    self.offline.lastSaveTime = love.timer.getTime()
    print("💾 Core idle game saved")
end

return IdleGame