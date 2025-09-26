-- Enhanced Idle Mode
-- Main game mode with hierarchical location system integration

local EnhancedIdleMode = {}
EnhancedIdleMode.__index = EnhancedIdleMode

local format = require("src.utils.format")
local EnhancedPlayerSystem = require("src.systems.enhanced_player_system")
local LocationMap = require("src.ui.location_map")

-- Create new enhanced idle mode
function EnhancedIdleMode.new(systems)
    local self = setmetatable({}, EnhancedIdleMode)
    self.systems = systems
    
    -- UI state
    self.showLocationBrowser = false
    self.selectedBuilding = nil
    self.selectedFloor = nil
    
    -- UI components
    self.locationMap = nil
    
    return self
end

-- Initialize enhanced player system when entering idle mode
function EnhancedIdleMode:enter()
    if not self.player then
        self.player = EnhancedPlayerSystem.new(self.systems.eventBus, self.systems.locations)
        
        -- Subscribe to player interactions
        self.systems.eventBus:subscribe("player_interact", function(data)
            self:handlePlayerInteraction(data)
        end)
        
        -- Subscribe to location changes
        self.systems.eventBus:subscribe("location_changed", function(data)
            print("🏠 Location changed: " .. data.newBuilding .. "/" .. data.newFloor .. "/" .. data.newRoom)
        end)
        
        -- Subscribe to tier promotions
        if self.systems.progression then
            self.systems.eventBus:subscribe("tier_promoted", function(data)
                print("🎉 Congratulations! Promoted to " .. data.tierData.name)
            end)
        end
        
        -- Subscribe to achievement unlocks
        if self.systems.progression then
            self.systems.eventBus:subscribe("achievement_unlocked", function(data)
                print("🏆 Achievement: " .. data.achievement.name)
            end)
        end
    end
    
    -- Initialize location map
    if not self.locationMap then
        self.locationMap = LocationMap.new(640, 400)
    end
end

-- Handle player interactions with departments and locations
function EnhancedIdleMode:handlePlayerInteraction(data)
    if data.type == "department" then
        print("🤝 Interacted with " .. data.name)
        
        -- Department-specific interactions
        if data.department == "training" then
            self:handleTrainingInteraction(data)
        elseif data.department == "research" then
            self:handleResearchInteraction(data)
        elseif data.department == "hr" then
            self:handleHRInteraction(data)
        elseif data.department == "contracts" then
            self:handleContractsInteraction(data)
        elseif data.department == "desk" then
            self:handleDeskInteraction(data)
        end
    end
end

-- Handle specific department interactions
function EnhancedIdleMode:handleTrainingInteraction(data)
    -- Award experience and improve focus
    local baseExp = 25
    local focusBonus = self.player:getState().locationBonuses.skill_gain or 1.0
    local experience = math.floor(baseExp * focusBonus)
    
    self.systems.resources:addResource("experience", experience)
    self.systems.resources:addResource("focus", 20)
    
    print("📚 Training completed! +" .. experience .. " XP, +20 Focus")
end

function EnhancedIdleMode:handleResearchInteraction(data)
    -- Generate research insights and reputation
    local baseRep = 3
    local researchBonus = self.player:getState().locationBonuses.research_speed or 1.0
    local reputation = math.floor(baseRep * researchBonus)
    
    self.systems.resources:addResource("reputation", reputation)
    print("🔬 Research completed! +" .. reputation .. " Reputation")
end

function EnhancedIdleMode:handleHRInteraction(data)
    -- Improve team efficiency and unlock specialists
    if self.systems.specialists then
        self.systems.specialists:improveTeamMorale(10)
    end
    print("👥 HR interaction: Team morale improved!")
end

function EnhancedIdleMode:handleContractsInteraction(data)
    -- Show available contracts with location bonuses
    local contracts = self.systems.contracts:getAvailableContracts()
    local locationBonuses = self.player:getState().locationBonuses
    
    print("📋 Available contracts: " .. #contracts .. " (Location bonuses active)")
    for i, contract in ipairs(contracts) do
        if i <= 3 then -- Show first 3
            local bonus = locationBonuses.contract_success or 1.0
            print("  " .. contract.title .. " (Success +" .. string.format("%.0f%%", (bonus-1)*100) .. ")")
        end
    end
end

function EnhancedIdleMode:handleDeskInteraction(data)
    -- Focus work session
    local focusBonus = self.player:getState().locationBonuses.focus or 1.0
    local moneyGain = math.floor(50 * focusBonus)
    
    self.systems.resources:addResource("money", moneyGain)
    self.systems.resources:addResource("energy", -10)
    
    print("💼 Work session completed! +" .. moneyGain .. " Money, -10 Energy")
end

-- Update game state
function EnhancedIdleMode:update(dt)
    if self.player then
        self.player:update(dt)
    end
    
    -- Update progression system if available
    if self.systems.progression then
        self.systems.progression:update(dt)
    end
end

-- Handle input
function EnhancedIdleMode:keypressed(key)
    if key == "space" then
        if self.player then
            local success, obj = self.player:interact()
            if success then
                print("✅ Interaction with: " .. obj.name)
            else
                print("❌ No interaction available")
            end
        end
    elseif key == "tab" then
        -- Toggle location browser
        self.showLocationBrowser = not self.showLocationBrowser
    elseif key == "1" then
        -- Quick travel to different rooms (for testing)
        self:quickTravel("home_office", "main", "my_office")
    elseif key == "2" then
        self:quickTravel("home_office", "main", "kitchen")
    elseif key == "f" then
        -- Toggle fullscreen location map
        self.showFullLocationMap = not self.showFullLocationMap
    end
end

-- Quick travel for testing
function EnhancedIdleMode:quickTravel(building, floor, room)
    if self.systems.locations:isValidLocation(building, floor, room) then
        self.systems.eventBus:publish("player_move_to_room", {
            building = building,
            floor = floor,
            room = room
        })
    else
        print("❌ Invalid location: " .. building .. "/" .. floor .. "/" .. room)
    end
end

-- Handle movement input
function EnhancedIdleMode:setInput(key, isDown)
    if self.player then
        self.player:setInput(key, isDown)
    end
end

-- Draw game interface
function EnhancedIdleMode:draw()
    -- Get terminal theme from UI manager
    local theme = self.systems.ui and self.systems.ui.theme or {}
    
    -- Get window dimensions
    local winW, winH = love.graphics.getDimensions()
    
    -- Draw location map as main view
    love.graphics.push()
    love.graphics.translate(20, 60)
    
    local mapWidth = math.min(winW - 40, 800)
    local mapHeight = math.min(winH - 200, 500)
    
    self.locationMap.width = mapWidth
    self.locationMap.height = mapHeight
    
    local debugFlag = self.systems.gameState and self.systems.gameState.debugMode
    self.locationMap:draw(self.player, self.systems.locations, { debug = debugFlag })
    
    love.graphics.pop()
    
    -- Draw UI panels
    self:drawTopPanel()
    self:drawBottomPanel()
    
    if self.showLocationBrowser then
        self:drawLocationBrowser()
    end
    
    -- Draw help text
    self:drawHelpText()
end

-- Draw top information panel
function EnhancedIdleMode:drawTopPanel()
    local winW = love.graphics.getDimensions()
    
    -- Panel background
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, winW, 50)
    
    -- Current location info
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(12))
    
    local location = self.systems.locations:getCurrentLocation()
    local locationText = "📍 " .. location.building .. " → " .. location.floor .. " → " .. location.room
    love.graphics.print(locationText, 10, 15)
    
    -- Currency display
    local currencies = {"money", "reputation", "experience", "energy", "focus"}
    local x = 300
    
    for _, currency in ipairs(currencies) do
        local value = self.systems.resources:getResource(currency) or 0
        local displayValue = format.number(value)
        
        -- Currency color coding
        if currency == "money" then
            love.graphics.setColor(0.2, 0.8, 0.2, 1)
        elseif currency == "reputation" then
            love.graphics.setColor(0.9, 0.7, 0.2, 1)
        elseif currency == "experience" then
            love.graphics.setColor(0.2, 0.6, 0.9, 1)
        elseif currency == "energy" then
            love.graphics.setColor(1.0, 0.5, 0.2, 1)
        elseif currency == "focus" then
            love.graphics.setColor(0.6, 0.2, 0.9, 1)
        end
        
        local text = currency:sub(1,3):upper() .. ": " .. displayValue
        love.graphics.print(text, x, 15)
        x = x + 100
    end
end

-- Draw bottom control panel
function EnhancedIdleMode:drawBottomPanel()
    local winW, winH = love.graphics.getDimensions()
    local panelHeight = 120
    local panelY = winH - panelHeight
    
    -- Panel background
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, panelY, winW, panelHeight)
    
    -- Location bonuses
    love.graphics.setColor(0.8, 0.9, 0.6, 1)
    love.graphics.setFont(love.graphics.newFont(11))
    love.graphics.print("Active Location Bonuses:", 20, panelY + 10)
    
    local bonuses = self.systems.locations:getCurrentLocationBonuses()
    local y = panelY + 30
    local col = 0
    
    for bonusType, multiplier in pairs(bonuses) do
        local bonusText = bonusType:gsub("_", " "):gsub("(%a)(%w*)", function(a,b) return a:upper()..b end)
        bonusText = bonusText .. ": +" .. string.format("%.0f%%", (multiplier - 1) * 100)
        
        love.graphics.print(bonusText, 20 + (col * 200), y)
        col = col + 1
        if col >= 3 then
            col = 0
            y = y + 20
        end
    end
    
    -- Available actions
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(10))
    love.graphics.print("Available Actions:", 20, panelY + 80)
    
    if self.player then
        local roomLayout = self.player:getRoomLayout()
        local actionText = ""
        
        for _, obj in ipairs(roomLayout) do
            if obj.type == "department" then
                actionText = actionText .. obj.name .. " • "
            elseif obj.type == "connection" then
                actionText = actionText .. obj.name .. " → " .. (obj.leadsTo or "?") .. " • "
            end
        end
        
        if actionText ~= "" then
            actionText = actionText:sub(1, -3) -- Remove last " • "
        else
            actionText = "Move closer to objects to interact"
        end
        
        love.graphics.print(actionText, 20, panelY + 95)
    end
end

-- Draw location browser (building/floor navigation)
function EnhancedIdleMode:drawLocationBrowser()
    local winW, winH = love.graphics.getDimensions()
    local browserW = 400
    local browserH = 300
    local browserX = winW - browserW - 20
    local browserY = 100
    
    -- Browser background
    love.graphics.setColor(0, 0, 0, 0.9)
    love.graphics.rectangle("fill", browserX, browserY, browserW, browserH, 8, 8)
    
    love.graphics.setColor(0.4, 0.4, 0.5, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", browserX, browserY, browserW, browserH, 8, 8)
    
    -- Title
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(14))
    love.graphics.print("Location Browser", browserX + 10, browserY + 10)
    
    -- Available buildings
    love.graphics.setFont(love.graphics.newFont(12))
    love.graphics.print("Buildings:", browserX + 10, browserY + 40)
    
    local buildings = self.systems.locations:getAvailableBuildings()
    local y = browserY + 60
    
    for _, building in ipairs(buildings) do
        love.graphics.setColor(0.7, 0.9, 0.7, 1)
        love.graphics.print("• " .. building.name, browserX + 20, y)
        love.graphics.setColor(0.6, 0.6, 0.6, 1)
        love.graphics.print("(" .. building.floorCount .. " floors)", browserX + 200, y)
        y = y + 20
    end
    
    -- Current floor rooms
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Current Floor Rooms:", browserX + 10, browserY + 160)
    
    local rooms = self.systems.locations:getAvailableRooms()
    y = browserY + 180
    
    for _, room in ipairs(rooms) do
        local current = self.systems.locations:getCurrentLocation()
        if room.id == current.room then
            love.graphics.setColor(0.9, 0.7, 0.2, 1) -- Highlight current room
        else
            love.graphics.setColor(0.7, 0.7, 0.9, 1)
        end
        
        love.graphics.print("• " .. room.name, browserX + 20, y)
        y = y + 15
    end
end

-- Draw help text
function EnhancedIdleMode:drawHelpText()
    love.graphics.setColor(0.6, 0.6, 0.6, 1)
    love.graphics.setFont(love.graphics.newFont(10))
    
    local helpText = "WASD: Move • SPACE: Interact • TAB: Location Browser • 1/2: Quick Travel • F: Toggle Debug"
    love.graphics.print(helpText, 10, love.graphics.getHeight() - 20)
end

-- Handle mouse input
function EnhancedIdleMode:mousepressed(x, y, button)
    -- Pass to location map for navigation
    if self.locationMap then
        if self.locationMap:mousepressed(x - 20, y - 60, button, self.systems.locations, self.player) then
            return true
        end
    end
    
    return false
end

return EnhancedIdleMode