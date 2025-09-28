-- IdleGame - Unified Idle Cybersecurity Game Controller
-- Clean, data-driven implementation focused on idle game mechanics
-- Single entry point that handles all game states and data loading

local IdleGame = {}
IdleGame.__index = IdleGame

-- Import core fortress components (they're cleaner than legacy)
local EventBus = require("src.utils.event_bus")
local ResourceManager = require("src.core.resource_manager")
local UIManager = require("src.core.ui_manager")

-- Import new UI helpers and components
local UIHelpers = require("src.ui.ui_helpers")
local QuickMenu = require("src.ui.quick_menu")
local ASCIIRoomParser = require("src.ui.ascii_room_parser")

-- Import data loading utilities
local defs = require("src.data.defs")
local json = require("dkjson")

-- Game states for smooth transitions
local GAME_STATES = {
    LOADING = "loading",
    SPLASH = "splash",
    DASHBOARD = "dashboard",
    PAUSED = "paused"
}

-- Create new idle game instance
function IdleGame.new()
    local self = setmetatable({}, IdleGame)
    
    -- Core game state
    self.initialized = false
    self.currentState = GAME_STATES.LOADING
    self.gameData = {}
    self.lastUpdate = love.timer.getTime()
    
    -- Core components
    self.eventBus = nil
    self.resourceManager = nil
    self.uiManager = nil
    
    -- New UI components
    self.quickMenu = nil
    self.asciiParser = nil
    self.currentLocationASCII = nil
    
    -- Idle game specific state
    self.offlineProgress = {
        lastSave = love.timer.getTime(),
        moneyGenerated = 0,
        contractsCompleted = 0,
        threatsBlocked = 0
    }
    
    -- UI state management
    self.showOfflineModal = false
    self.splashDisplayTime = 0
    self.splashMinTime = 1.0 -- Reduced minimum splash screen time for better UX
    
    return self
end

-- Initialize the idle game
function IdleGame:initialize()
    print("🏗️ Initializing Idle Cybersecurity Game...")
    
    -- Initialize core components
    self:initializeCore()
    
    -- Load game data dynamically
    self:loadGameData()
    
    -- Initialize idle game systems
    self:initializeIdleSystems()
    
    -- Set initial state
    self.currentState = GAME_STATES.SPLASH
    self.initialized = true
    
    print("✅ Idle game initialization complete!")
    return true
end

-- Initialize core components
function IdleGame:initializeCore()
    print("🔧 Initializing core components...")
    
    -- Event bus for system communication
    self.eventBus = EventBus.new()
    
    -- Resource manager for dynamic resource handling
    self.resourceManager = ResourceManager.new(self.eventBus)
    self.resourceManager:initialize()
    
    -- UI manager for all interface elements
    self.uiManager = UIManager.new(self.eventBus, self.resourceManager)
    self.uiManager:initialize()
    
    -- Initialize new UI components
    self.quickMenu = QuickMenu.new(self.eventBus, self.resourceManager)
    self.asciiParser = ASCIIRoomParser.new()
    
    print("🔧 Core components initialized")
end

-- Load game data from JSON files dynamically
function IdleGame:loadGameData()
    print("📊 Loading game data...")
    
    -- Load definitions
    self.gameData.definitions = defs
    
    -- Load contracts
    self:loadJSONData("src/data/contracts.json", "contracts")
    
    -- Load currencies/resources  
    self:loadJSONData("src/data/currencies.json", "currencies")
    
    -- Initialize starting resources based on data
    self:initializeStartingResources()
    
    print("📊 Game data loaded successfully")
end

-- Helper to load JSON data files
function IdleGame:loadJSONData(filePath, dataKey)
    if love.filesystem.getInfo(filePath) then
        local content = love.filesystem.read(filePath)
        local data, pos, err = json.decode(content)
        if data then
            self.gameData[dataKey] = data
            print("   ✅ Loaded " .. dataKey .. " data")
        else
            print("   ❌ Failed to parse " .. dataKey .. ": " .. tostring(err))
            self.gameData[dataKey] = {}
        end
    else
        print("   ⚠️ " .. filePath .. " not found, using defaults")
        self.gameData[dataKey] = {}
    end
end

-- Initialize starting resources from data
function IdleGame:initializeStartingResources()
    -- Add bonus starting resources beyond the ResourceManager defaults
    local bonusResources = {
        reputation = 10,  -- Add 10 reputation (default is 0)
        missionTokens = 5 -- Add 5 mission tokens (default is 0)
    }
    
    for resource, amount in pairs(bonusResources) do
        self.resourceManager:addResource(resource, amount)
    end
    
    print("💰 Starting resources initialized (money: " .. self.resourceManager:getResource("money") .. ", reputation: " .. self.resourceManager:getResource("reputation") .. ")")
end

-- Initialize idle game specific systems
function IdleGame:initializeIdleSystems()
    print("⚙️ Initializing idle game systems...")
    
    -- Set up dynamic money generation based on player resources and capabilities
    self.moneyGeneration = {
        baseRate = 0, -- Start with no automatic generation
        multiplier = 1.0,
        lastUpdate = love.timer.getTime()
    }
    
    -- Calculate initial generation rate based on player capabilities
    self:updateMoneyGenerationRate()
    
    -- Set up contract auto-completion system
    self.autoContracts = {
        enabled = false,
        completionTime = 30, -- seconds per contract
        lastCompletion = love.timer.getTime()
    }
    
    -- Calculate offline progress if applicable
    self:calculateOfflineProgress()
    
    print("⚙️ Idle systems initialized")
end

-- Calculate money generation rate based on player capabilities
function IdleGame:updateMoneyGenerationRate()
    local baseRate = 0
    
    -- Base rate from reputation (reflects your business reputation bringing in work)
    local reputation = self.resourceManager:getResource("reputation") or 0
    baseRate = baseRate + (reputation * 0.5) -- 50 cents per reputation point per second
    
    -- Base rate from completed contracts (reflects residual income from past work)
    local contractsCompleted = self.offlineProgress.contractsCompleted or 0
    baseRate = baseRate + (contractsCompleted * 0.25) -- 25 cents per completed contract per second
    
    -- Minimum viable rate for new players (reflects small freelance work)
    if baseRate < 1 then
        baseRate = 1 -- $1/sec minimum for new players
    end
    
    self.moneyGeneration.baseRate = baseRate
    print("💰 Money generation rate updated: $" .. string.format("%.2f", baseRate) .. "/sec")
end

-- Calculate offline progress (key idle game feature)
function IdleGame:calculateOfflineProgress()
    local currentTime = love.timer.getTime()
    local offlineTime = currentTime - self.offlineProgress.lastSave
    
    -- Only show offline progress if player was away for more than 30 seconds
    if offlineTime > 30 then
        local moneyGenerated = math.floor(offlineTime * self.moneyGeneration.baseRate * self.moneyGeneration.multiplier)
        local contractsCompleted = math.floor(offlineTime / 60) -- 1 per minute offline
        
        self.offlineProgress.moneyGenerated = moneyGenerated
        self.offlineProgress.contractsCompleted = contractsCompleted
        self.offlineProgress.threatsBlocked = math.floor(offlineTime / 45) -- 1 per 45 seconds
        
        -- Add resources
        self.resourceManager:addResource("money", moneyGenerated)
        self.resourceManager:addResource("reputation", contractsCompleted)
        
        -- Show offline modal when we reach dashboard
        self.showOfflineModal = true
        
        print("💤 Offline progress calculated: " .. moneyGenerated .. " money, " .. contractsCompleted .. " contracts")
    else
        self.showOfflineModal = false
    end
end

-- Update game logic
function IdleGame:update(dt)
    if not self.initialized then
        return
    end
    
    -- Update core components
    if self.resourceManager then
        self.resourceManager:update(dt)
    end
    
    -- Handle state-specific updates
    if self.currentState == GAME_STATES.SPLASH then
        self:updateSplash(dt)
    elseif self.currentState == GAME_STATES.DASHBOARD then
        self:updateDashboard(dt)
    end
end

-- Update splash screen
function IdleGame:updateSplash(dt)
    self.splashDisplayTime = self.splashDisplayTime + dt
    
    -- Auto-advance after minimum time (optional - can still be manually advanced)
    if self.splashDisplayTime > self.splashMinTime + 3.0 then
        self:advanceToGame()
    end
end

-- Update dashboard (main game state)
function IdleGame:updateDashboard(dt)
    -- Update idle money generation
    local currentTime = love.timer.getTime()
    local timeDelta = currentTime - self.moneyGeneration.lastUpdate
    
    if timeDelta >= 1.0 then -- Update every second
        local moneyToAdd = math.floor(timeDelta * self.moneyGeneration.baseRate * self.moneyGeneration.multiplier)
        self.resourceManager:addResource("money", moneyToAdd)
        self.moneyGeneration.lastUpdate = currentTime
    end
    
    -- Update auto-contracts if enabled
    if self.autoContracts.enabled then
        local contractTimeDelta = currentTime - self.autoContracts.lastCompletion
        if contractTimeDelta >= self.autoContracts.completionTime then
            self:completeAutoContract()
            self.autoContracts.lastCompletion = currentTime
        end
    end
end

-- Complete an automatic contract
function IdleGame:completeAutoContract()
    -- Find available contracts from game data
    if self.gameData.contracts and #self.gameData.contracts > 0 then
        local contract = self.gameData.contracts[math.random(#self.gameData.contracts)]
        
        -- Award resources
        self.resourceManager:addResource("money", contract.baseBudget or 100)
        self.resourceManager:addResource("reputation", contract.reputationReward or 1)
        
        -- Update contract completion count
        self.offlineProgress.contractsCompleted = (self.offlineProgress.contractsCompleted or 0) + 1
        
        -- Update money generation rate based on new reputation/contracts
        self:updateMoneyGenerationRate()
        
        -- Show notification
        self.eventBus:publish("contract_completed", {
            name = contract.clientName or "Unknown Client",
            reward = contract.baseBudget or 100
        })
        
        print("💼 Auto-completed contract: " .. (contract.clientName or "Unknown"))
    end
end

-- Draw the game
function IdleGame:draw()
    if not self.initialized then
        love.graphics.print("Initializing...", 10, 10)
        return
    end
    
    if self.currentState == GAME_STATES.SPLASH then
        self:drawSplash()
    elseif self.currentState == GAME_STATES.DASHBOARD then
        self:drawDashboard()
    end
end

-- Draw splash screen
function IdleGame:drawSplash()
    local width, height = love.graphics.getDimensions()
    
    -- Background
    love.graphics.setColor(0.1, 0.1, 0.15, 1.0)
    love.graphics.rectangle("fill", 0, 0, width, height)
    
    -- Title
    love.graphics.setColor(0.2, 0.8, 1.0, 1.0)
    local title = "🏰 Cyber Empire Command"
    local font = love.graphics.getFont()
    local titleWidth = font:getWidth(title)
    love.graphics.print(title, (width - titleWidth) / 2, height / 2 - 60)
    
    -- Subtitle
    love.graphics.setColor(0.7, 0.9, 1.0, 1.0)
    local subtitle = "Idle Cybersecurity Tycoon"
    local subtitleWidth = font:getWidth(subtitle)
    love.graphics.print(subtitle, (width - subtitleWidth) / 2, height / 2 - 30)
    
    -- Continue prompt (with better user feedback)
    local alpha = 1.0
    if self.splashDisplayTime <= self.splashMinTime then
        alpha = 0.3 + 0.7 * (self.splashDisplayTime / self.splashMinTime)
        love.graphics.setColor(1.0, 0.6, 0.6, alpha)
        local prompt = "Loading... (please wait)"
        local promptWidth = font:getWidth(prompt)
        love.graphics.print(prompt, (width - promptWidth) / 2, height / 2 + 30)
    else
        love.graphics.setColor(0.2, 1.0, 0.4, alpha)
        local prompt = "🎮 Press any key or click to continue!"
        local promptWidth = font:getWidth(prompt)
        love.graphics.print(prompt, (width - promptWidth) / 2, height / 2 + 30)
    end
end

-- Draw dashboard (main game screen)
function IdleGame:drawDashboard()
    local width, height = love.graphics.getDimensions()
    
    -- Background
    love.graphics.setColor(0.05, 0.05, 0.1, 1.0)
    love.graphics.rectangle("fill", 0, 0, width, height)
    
    -- Draw current location ASCII art if available
    self:drawLocationASCII()
    
    -- Draw dashboard components
    self:drawResourcePanel()
    self:drawContractPanel()
    self:drawStatsPanel()
    
    -- Draw quick menu
    if self.quickMenu then
        self.quickMenu:draw()
    end
    
    -- Draw offline progress modal if needed
    if self.showOfflineModal then
        self:drawOfflineModal()
    end
end

-- Draw resource panel
function IdleGame:drawResourcePanel()
    local x, y = 20, 20
    local width, height = 300, 150
    
    -- Panel background
    love.graphics.setColor(0.15, 0.15, 0.25, 1.0)
    love.graphics.rectangle("fill", x, y, width, height)
    love.graphics.setColor(0.3, 0.4, 0.5, 1.0)
    love.graphics.rectangle("line", x, y, width, height)
    
    -- Title
    love.graphics.setColor(0.2, 0.8, 1.0, 1.0)
    love.graphics.print("💰 Resources", x + 10, y + 10)
    
    -- Resources
    love.graphics.setColor(0.9, 0.9, 0.9, 1.0)
    local yOffset = 35
    local resources = {"money", "reputation", "xp", "missionTokens"}
    
    for _, resource in ipairs(resources) do
        local amount = self.resourceManager:getResource(resource)
        local displayName = resource:gsub("^%l", string.upper):gsub("(%l)(%u)", "%1 %2")
        local text = displayName .. ": " .. string.format("%.0f", amount)
        love.graphics.print(text, x + 10, y + yOffset)
        yOffset = yOffset + 20
    end
end

-- Draw contract panel
function IdleGame:drawContractPanel()
    local x, y = 340, 20
    local width, height = 300, 150
    
    -- Panel background
    love.graphics.setColor(0.15, 0.25, 0.15, 1.0)
    love.graphics.rectangle("fill", x, y, width, height)
    love.graphics.setColor(0.3, 0.5, 0.3, 1.0)
    love.graphics.rectangle("line", x, y, width, height)
    
    -- Title
    love.graphics.setColor(0.2, 1.0, 0.4, 1.0)
    love.graphics.print("💼 Contract System", x + 10, y + 10)
    
    -- Contract info
    love.graphics.setColor(0.9, 0.9, 0.9, 1.0)
    local yOffset = 35
    
    love.graphics.print("Auto-contracts: " .. (self.autoContracts.enabled and "ON" or "OFF"), x + 10, y + yOffset)
    yOffset = yOffset + 20
    
    if self.gameData.contracts and #self.gameData.contracts > 0 then
        love.graphics.print("Available: " .. #self.gameData.contracts, x + 10, y + yOffset)
        yOffset = yOffset + 20
        
        love.graphics.print("Rate: $" .. self.moneyGeneration.baseRate .. "/sec", x + 10, y + yOffset)
    end
end

-- Draw stats panel
function IdleGame:drawStatsPanel()
    local x, y = 20, 190
    local width, height = 620, 100
    
    -- Panel background
    love.graphics.setColor(0.25, 0.15, 0.15, 1.0)
    love.graphics.rectangle("fill", x, y, width, height)
    love.graphics.setColor(0.5, 0.3, 0.3, 1.0)
    love.graphics.rectangle("line", x, y, width, height)
    
    -- Title
    love.graphics.setColor(1.0, 0.4, 0.2, 1.0)
    love.graphics.print("📊 Performance Dashboard", x + 10, y + 10)
    
    -- Stats
    love.graphics.setColor(0.9, 0.9, 0.9, 1.0)
    local currentTime = love.timer.getTime()
    local uptime = currentTime - (self.offlineProgress.lastSave or currentTime)
    
    love.graphics.print("Session uptime: " .. string.format("%.0f", uptime) .. "s", x + 10, y + 35)
    love.graphics.print("Money generation: $" .. self.moneyGeneration.baseRate .. "/sec", x + 10, y + 55)
    love.graphics.print("Next auto-save: " .. string.format("%.0f", 30 - (uptime % 30)) .. "s", x + 300, y + 35)
end

-- Draw current location ASCII art
function IdleGame:drawLocationASCII()
    if not self.asciiParser or not self.gameData.locations then
        return
    end
    
    -- Generate ASCII for current location if not cached
    if not self.currentLocationASCII then
        local locationsData = {}
        if love.filesystem.getInfo("src/data/locations.json") then
            local content = love.filesystem.read("src/data/locations.json")
            local data, pos, err = json.decode(content)
            if data then
                locationsData = data
            end
        end
        
        -- Default to home office
        local buildingId = "home_office"
        local floorId = "main"
        local roomId = "my_office"
        
        self.currentLocationASCII = self.asciiParser:getLocationASCII(locationsData, buildingId, floorId, roomId)
    end
    
    -- Draw ASCII art in center-left area
    if self.currentLocationASCII then
        love.graphics.setColor(UIHelpers.colors.text)
        local startX, startY = 50, 50
        
        for i, line in ipairs(self.currentLocationASCII) do
            if i <= 15 then -- Limit lines to prevent overflow
                love.graphics.print(line, startX, startY + (i - 1) * 15)
            end
        end
        
        -- Location info
        love.graphics.setColor(UIHelpers.colors.accent)
        love.graphics.print("📍 Current Location:", startX, startY - 25)
        love.graphics.print("🏠 Home Office > Main Floor > My Office", startX, startY - 10)
    end
end

-- Draw offline progress modal (key idle game feature)
function IdleGame:drawOfflineModal()
    local width, height = love.graphics.getDimensions()
    local modalWidth, modalHeight = 400, 250
    local x, y = (width - modalWidth) / 2, (height - modalHeight) / 2
    
    -- Semi-transparent background
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, width, height)
    
    -- Modal background
    love.graphics.setColor(0.2, 0.2, 0.3, 1.0)
    love.graphics.rectangle("fill", x, y, modalWidth, modalHeight)
    love.graphics.setColor(0.4, 0.6, 0.8, 1.0)
    love.graphics.rectangle("line", x, y, modalWidth, modalHeight)
    
    -- Title
    love.graphics.setColor(0.2, 0.8, 1.0, 1.0)
    local title = "💤 Welcome Back!"
    local titleWidth = love.graphics.getFont():getWidth(title)
    love.graphics.print(title, x + (modalWidth - titleWidth) / 2, y + 20)
    
    -- Offline progress details
    love.graphics.setColor(0.9, 0.9, 0.9, 1.0)
    local yOffset = 60
    
    love.graphics.print("While you were away:", x + 20, y + yOffset)
    yOffset = yOffset + 30
    
    love.graphics.print("💰 Earned: $" .. self.offlineProgress.moneyGenerated, x + 20, y + yOffset)
    yOffset = yOffset + 25
    
    love.graphics.print("💼 Contracts completed: " .. self.offlineProgress.contractsCompleted, x + 20, y + yOffset)
    yOffset = yOffset + 25
    
    love.graphics.print("🛡️ Threats blocked: " .. self.offlineProgress.threatsBlocked, x + 20, y + yOffset)
    yOffset = yOffset + 40
    
    -- Continue button
    love.graphics.setColor(0.2, 0.8, 0.4, 1.0)
    local buttonText = "Continue (Click or press any key)"
    local buttonWidth = love.graphics.getFont():getWidth(buttonText)
    love.graphics.print(buttonText, x + (modalWidth - buttonWidth) / 2, y + yOffset)
end

-- Handle key presses
function IdleGame:keypressed(key)
    -- Let quick menu handle key presses first
    if self.quickMenu and self.quickMenu:handleKeyPress(key) then
        return -- Quick menu handled the key
    end
    
    if self.currentState == GAME_STATES.SPLASH then
        if self.splashDisplayTime > self.splashMinTime then
            self:advanceToGame()
        end
    elseif self.currentState == GAME_STATES.DASHBOARD then
        if self.showOfflineModal then
            self.showOfflineModal = false
        elseif key == "space" then
            -- Toggle auto-contracts
            self.autoContracts.enabled = not self.autoContracts.enabled
            print("Auto-contracts: " .. (self.autoContracts.enabled and "enabled" or "disabled"))
        end
    end
end

-- Handle mouse presses
function IdleGame:mousepressed(x, y, button)
    -- Let quick menu handle mouse presses first
    if self.quickMenu and self.quickMenu:handleMousePress(x, y, button) then
        return -- Quick menu handled the click
    end
    
    if self.currentState == GAME_STATES.SPLASH then
        if self.splashDisplayTime > self.splashMinTime then
            self:advanceToGame()
        end
    elseif self.currentState == GAME_STATES.DASHBOARD then
        if self.showOfflineModal then
            self.showOfflineModal = false
        end
    end
end

-- Advance from splash to game
function IdleGame:advanceToGame()
    self.currentState = GAME_STATES.DASHBOARD
    print("🎮 Advancing to dashboard")
end

-- Handle window resize
function IdleGame:resize(w, h)
    if self.uiManager then
        self.uiManager:resize(w, h)
    end
end

-- Shutdown and save
function IdleGame:shutdown()
    if self.initialized then
        -- Save offline progress timestamp
        self.offlineProgress.lastSave = love.timer.getTime()
        
        -- Here you would implement proper save system
        print("💾 Game state saved")
        print("🏰 Idle game shutdown complete")
    end
end

return IdleGame