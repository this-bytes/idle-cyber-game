-- Idle Mode
-- Main game mode for empire building progression

local IdleMode = {}
IdleMode.__index = IdleMode

local format = require("src.utils.format")
local PlayerSystem = require("src.systems.player_system")
local OfficeMap = require("src.ui.office_map")
local EnhancedOfficeMap = require("src.ui.enhanced_office_map")  -- NEW: Enhanced room rendering

-- Create new idle mode
function IdleMode.new(systems)
    local self = setmetatable({}, IdleMode)
    self.systems = systems
    
    -- UI state for contract selection
    self.contractAreas = {}  -- Store clickable areas for contracts
    self.selectedContract = nil
    
    -- Enhanced room rendering
    self.enhancedMap = EnhancedOfficeMap.new()
    self.useEnhancedMap = true
    
    return self
end

-- Initialize player system when entering idle mode
function IdleMode:enter()
    if not self.player then
        self.player = PlayerSystem.new(self.systems.eventBus)
        -- Subscribe to player interactions
        self.systems.eventBus:subscribe("player_interact", function(data)
            if self.systems.ui then
                self.systems.ui:showNotification("🤝 Interacted with " .. data.name .. " (" .. data.department .. ")")
            end
            -- Dispatch department-specific events so respective systems can handle them
            if data.department == "training" then
                -- Give player/company XP via ResourceSystem and also signal SpecialistSystem
                self.systems.eventBus:publish("add_resource", { resource = "xp", amount = 10 })
                -- Let specialist system know about training (could be listened to by SpecialistSystem)
                self.systems.eventBus:publish("specialist_training", { amount = 10 })
                if self.systems.ui then
                    self.systems.ui:showNotification("⭐ Training complete: +10 XP")
                end
            elseif data.department == "contracts" then
                -- Unlock a new contract generation tick and give a reputation bump
                if self.systems.contracts then
                    self.systems.contracts:generateRandomContract()
                end
                self.systems.eventBus:publish("add_resource", { resource = "reputation", amount = 1 })
                if self.systems.ui then
                    self.systems.ui:showNotification("📈 New opportunities: +1 Rep, new contract generated")
                end
            elseif data.department == "security" then
                -- Decrease threat level slightly via ThreatSystem if present
                if self.systems.threats and self.systems.threats.threatReduction ~= nil then
                    self.systems.threats.threatReduction = math.min((self.systems.threats.threatReduction or 0) + 0.05, 0.9)
                    if self.systems.ui then
                        self.systems.ui:showNotification("🛡️ Security briefing: Threat reduction increased")
                    end
                    self.systems.eventBus:publish("threats_updated", { reduction = self.systems.threats.threatReduction })
                else
                    if self.systems.ui then
                        self.systems.ui:showNotification("🛡️ Security briefing: Defense increased")
                    end
                end
            else
                -- Generic interaction: publish to event bus
                self.systems.eventBus:publish("player_department_interact", data)
            end
        end)
    end
    -- Position player at My Desk as default entry point
    if self.player then
        -- If the game loaded a saved player state earlier, apply it now
        if self.systems and self.systems.eventBus and self.systems.eventBus and self.systems and self.systems.eventBus then
            -- Check for loaded player state on global game state via Game (injected via systems table)
        end
        if self.systems and self.systems.gameState and self.systems.gameState.loadedPlayerState then
            self.player:loadState(self.systems.gameState.loadedPlayerState)
            -- Clear loaded state after applying
            self.systems.gameState.loadedPlayerState = nil
        else
            -- Only set default position if player hasn't been restored from save
            if not self.player.x or not self.player.y or (self.player.x == 0 and self.player.y == 0) then
                self.player.x = 160
                self.player.y = 120
            end
        end
    end
    -- Create office map overlay
    if not self.officeMap then
        self.officeMap = OfficeMap.new(640, 200)
    end

    -- Show tutorial modal on first run (if not seen). Guard to avoid duplicate displays per session.
    if not self._tutorialDisplayed and self.systems and self.systems.gameState and not self.systems.gameState.tutorialSeen then
        if self.systems.ui and self.systems.ui.showTutorial then
            print("📘 Showing tutorial modal (first run)")
            local title = "Welcome to Cyber Empire Command"
            local body = "Walk around the office with WASD or arrow keys. Press E to interact with departments. Accept contracts to earn money and reputation. Press A for Crisis Mode."
            local function onTutorialClose()
                -- Mark tutorial as seen and persist a save immediately
                self.systems.gameState.tutorialSeen = true

                -- Build save snapshot similar to Game.save
                local saveData = {
                    resources = self.systems.resources:getState(),
                    contracts = self.systems.contracts:getState(),
                    specialists = self.systems.specialists:getState(),
                    upgrades = self.systems.upgrades:getState(),
                    threats = self.systems.threats:getState(),
                    zones = self.systems.zones:getState(),
                    factions = self.systems.factions:getState(),
                    achievements = self.systems.achievements:getState(),
                    playerState = self.player and self.player:getState() or nil,
                    tutorialSeen = true,
                    version = "1.0.0",
                    timestamp = os.time()
                }
                if self.systems.save and self.systems.save.save then
                    self.systems.save:save(saveData, function(success, result)
                        if success then
                            print("💾 Tutorial state saved")
                        else
                            print("❌ Failed to save tutorial state: " .. tostring(result))
                        end
                    end)
                end
            end
            self.systems.ui:showTutorial(title, body, onTutorialClose)
            self._tutorialDisplayed = true
        end
    end
end

function IdleMode:update(dt)
    -- Handle idle mode specific updates
    if not self.player then self:enter() end
    if self.player then self.player:update(dt) end
    
    -- Update enhanced map animations
    if self.enhancedMap then
        self.enhancedMap:update(dt)
    end
    
    -- Update room system
    if self.systems.rooms then
        self.systems.rooms:update(dt)
    end
    
    -- Update room events
    if self.systems.roomEvents then
        self.systems.roomEvents:update(dt)
    end
end

function IdleMode:keyreleased(key)
    if self.player then
        if key == "up" or key == "w" then self.player:setInput("up", false) end
        if key == "down" or key == "s" then self.player:setInput("down", false) end
        if key == "left" or key == "a" then self.player:setInput("left", false) end
        if key == "right" or key == "d" then self.player:setInput("right", false) end
    end
end

function IdleMode:draw()
    -- Get terminal theme from UI manager
    local theme = self.systems.ui.theme

    -- Prepare department nodes for office rendering
    local deptNodes = {}
    if self.player and self.player.departments then
        for _, d in ipairs(self.player.departments) do
            table.insert(deptNodes, {
                x = d.x,
                y = d.y - 16,
                radius = d.radius,
                name = d.name,
                label = d.name,
                proximity = d.proximity
            })
        end
    end

    -- Draw office map as the background/main screen. Terminal UI will be drawn on top as an overlay.
    -- Check debug flag
    local debugFlag = false
    if self.systems and self.systems.gameState and self.systems.gameState.debugMode then
        debugFlag = true
    end
    
    -- Use enhanced room rendering if available and enabled
    if self.useEnhancedMap and self.systems.rooms and self.enhancedMap then
        -- Enhanced room-based rendering
        love.graphics.push()
        love.graphics.translate(40, 140)
        love.graphics.setColor(1, 1, 1, 1)
        
        self.enhancedMap:draw(self.systems.rooms, self.player, { 
            offsetX = 0, 
            offsetY = 0,
            debug = debugFlag 
        })
        
        love.graphics.pop()
    else
        -- Fallback to traditional office map
        if not self.officeMap then
            self.officeMap = OfficeMap.new(640, 200)
        end
        -- Make office map size adapt to the window so it feels like the main scene
        local winW, winH = love.graphics.getDimensions()
        -- Reserve some space for top UI; draw the office underneath the terminal panels
        self.officeMap.width = math.max(480, winW - 80)
        self.officeMap.height = math.max(200, winH - 340)

        love.graphics.push()
        -- Position the office map slightly below the header/panels so overlays read comfortably
        love.graphics.translate(40, 140)
        love.graphics.setColor(1,1,1,1)
        self.officeMap:draw(self.player, deptNodes, { debug = debugFlag })
        love.graphics.pop()
    end
    -- If UI is in compact mode, don't draw the large terminal UI here so the office remains the main view
    local showFull = false
    if self.systems and self.systems.ui and self.systems.ui.showFullTerminal then
        showFull = self.systems.ui.showFullTerminal
    end
    if not showFull then
        -- Nothing more to draw here; UIManager will draw the HUD overlay on top
        return
    end

    -- Draw terminal header and panels on top of the office map (only when showFull is true)
    local contentY = 0
    local y = 0
    contentY = theme:drawHeader("CYBER EMPIRE COMMAND v2.1.7", "Security Consultancy Management Terminal")
    y = contentY + 20
    local leftPanelX = 20
    local rightPanelX = 520
    local panelWidth = 480
    
    -- Large terminal panels only render when showFull is true. Otherwise rely on compact HUD from UIManager.
    if showFull then
        -- Left panel: Business Resources
        theme:drawPanel(leftPanelX, y, panelWidth, 200, "BUSINESS RESOURCES")
        local resourceY = y + 25

        local resources = self.systems.resources:getAllResources()
        theme:drawText("BUDGET:", leftPanelX + 10, resourceY, theme:getColor("secondary"))
        theme:drawText("$" .. format.number(resources.money or 0, 0), leftPanelX + 200, resourceY, theme:getColor("success"))
        resourceY = resourceY + 20

        theme:drawText("REPUTATION:", leftPanelX + 10, resourceY, theme:getColor("secondary"))
        theme:drawText(format.number(resources.reputation or 0, 0) .. " pts", leftPanelX + 200, resourceY, theme:getColor("accent"))
        resourceY = resourceY + 20

        theme:drawText("EXPERIENCE:", leftPanelX + 10, resourceY, theme:getColor("secondary"))
        theme:drawText(format.number(resources.xp or 0, 0) .. " XP", leftPanelX + 200, resourceY, theme:getColor("primary"))
        resourceY = resourceY + 20

        theme:drawText("MISSION TOKENS:", leftPanelX + 10, resourceY, theme:getColor("secondary"))
        theme:drawText(format.number(resources.missionTokens or 0, 0), leftPanelX + 200, resourceY, theme:getColor("warning"))

        -- Right panel: Operations Status
        theme:drawPanel(rightPanelX, y, panelWidth, 200, "OPERATIONS STATUS")
        local opsY = y + 25

        local contractStats = self.systems.contracts:getStats()
        local specialistStats = self.systems.specialists:getStats()

        theme:drawText("ACTIVE CONTRACTS:", rightPanelX + 10, opsY, theme:getColor("secondary"))
        theme:drawText(tostring(contractStats.activeContracts or 0), rightPanelX + 200, opsY, theme:getColor("warning"))
        opsY = opsY + 20

        theme:drawText("AVAILABLE CONTRACTS:", rightPanelX + 10, opsY, theme:getColor("secondary"))
        theme:drawText(tostring(contractStats.availableContracts or 0), rightPanelX + 200, opsY, theme:getColor("accent"))
        opsY = opsY + 20

        theme:drawText("REVENUE/SEC:", rightPanelX + 10, opsY, theme:getColor("secondary"))
        theme:drawText("$" .. format.number(contractStats.totalIncomeRate or 0, 2), rightPanelX + 200, opsY, theme:getColor("success"))
        opsY = opsY + 20

        theme:drawText("TEAM STATUS:", rightPanelX + 10, opsY, theme:getColor("secondary"))
        theme:drawText(specialistStats.available .. "/" .. specialistStats.total .. " ready", rightPanelX + 200, opsY, theme:getColor("primary"))
        opsY = opsY + 20
        
        -- Room status
        if self.systems.rooms then
            theme:drawText("CURRENT ROOM:", rightPanelX + 10, opsY, theme:getColor("secondary"))
            local currentRoom = self.systems.rooms:getCurrentRoom()
            if currentRoom then
                theme:drawText(currentRoom.name:gsub("🏠 ", ""):gsub("🏢 ", ""):gsub("👤 ", ""):gsub("🍽️ ", ""):gsub("💾 ", ""):gsub("🤝 ", ""):gsub("🚨 ", ""), rightPanelX + 200, opsY, theme:getColor("accent"))
            else
                theme:drawText("NONE", rightPanelX + 200, opsY, theme:getColor("muted"))
            end
            opsY = opsY + 20
        end

        -- Network status
        if self.systems.save and self.systems.save.getConnectionStatus then
            local status = self.systems.save:getConnectionStatus()
            theme:drawText("NETWORK:", rightPanelX + 10, opsY, theme:getColor("secondary"))
            local networkColor = status.isOnline and theme:getColor("success") or theme:getColor("error")
            local networkText = status.isOnline and "ONLINE" or "OFFLINE"
            if status.offlineMode then
                networkText = "DISABLED"
                networkColor = theme:getColor("muted")
            end
            theme:drawText(networkText, rightPanelX + 200, opsY, networkColor)
            opsY = opsY + 20

            theme:drawText("SAVE MODE:", rightPanelX + 10, opsY, theme:getColor("secondary"))
            theme:drawText(string.upper(status.saveMode), rightPanelX + 200, opsY, theme:getColor("accent"))
        end
    end
    
    -- Add progression panel between resources and contracts
    if showFull and self.systems.progression then
        y = y + 220
        theme:drawPanel(leftPanelX, y, panelWidth * 2 + 20, 120, "PROGRESSION STATUS")
        local progY = y + 25
        
        -- Get progression info
        local currentTier = self.systems.progression:getCurrentTier()
        local tierName = currentTier.name or "Unknown"
        local currencies = self.systems.progression:getAllCurrencies()
        
        -- Current tier
        theme:drawText("CURRENT TIER:", leftPanelX + 10, progY, theme:getColor("secondary"))
        theme:drawText(tierName, leftPanelX + 150, progY, theme:getColor("accent"))
        progY = progY + 20
        
        -- Prestige info
        local prestigeLevel = self.systems.progression.prestigeLevel or 0
        local prestigePoints = self.systems.progression:getCurrency("prestigePoints") or 0
        theme:drawText("PRESTIGE LEVEL:", leftPanelX + 10, progY, theme:getColor("secondary"))
        theme:drawText(tostring(prestigeLevel) .. " (" .. format.number(prestigePoints, 0) .. " PP)", leftPanelX + 150, progY, theme:getColor("warning"))
        progY = progY + 20
        
        -- Additional currencies (right side)
        local rightProgX = leftPanelX + 500
        progY = y + 25
        
        -- Research Credits
        local researchCredits = self.systems.progression:getCurrency("researchCredits") or 0
        if researchCredits > 0 then
            theme:drawText("RESEARCH CREDITS:", rightProgX, progY, theme:getColor("secondary"))
            theme:drawText(format.number(researchCredits, 0), rightProgX + 150, progY, theme:getColor("primary"))
            progY = progY + 20
        end
        
        -- Skill Points
        local skillPoints = self.systems.progression:getCurrency("skillPoints") or 0
        if skillPoints > 0 then
            theme:drawText("SKILL POINTS:", rightProgX, progY, theme:getColor("secondary"))
            theme:drawText(format.number(skillPoints, 0), rightProgX + 150, progY, theme:getColor("accent"))
            progY = progY + 20
        end
        
        -- Prestige availability
        if self.systems.progression:canPrestige() then
            theme:drawText("[P] PRESTIGE AVAILABLE!", leftPanelX + 400, y + 85, theme:getColor("warning"))
        end
        
        y = y + 120
    else
        y = y + 220
    end
    
    -- Available contracts panel with improved selection
    if showFull then
        theme:drawPanel(leftPanelX, y, panelWidth * 2 + 20, 180, "AVAILABLE CONTRACTS")
    else
        -- In compact mode, draw a smaller contracts hint panel
        theme:drawPanel(leftPanelX, y, panelWidth * 2 + 20, 60, "CONTRACTS (TAB to open)")
    end
    local contractY = y + 25
    
    -- Clear previous contract areas and rebuild them
    self.contractAreas = {}
    
    local availableContracts = self.systems.contracts:getAvailableContracts()
    local count = 0
    for contractId, contract in pairs(availableContracts) do
        if count >= 3 then break end -- Show max 3 contracts
        
        -- Track clickable area for this contract
        local contractHeight = 60
        self.contractAreas[count + 1] = {
            x = leftPanelX + 10,
            y = contractY,
            width = panelWidth * 2,
            height = contractHeight,
            contractId = contractId,
            contract = contract
        }
        
        -- Highlight selected contract
        local isSelected = (self.selectedContract == contractId)
        if isSelected then
            theme:drawPanel(leftPanelX + 5, contractY - 5, panelWidth * 2 + 10, contractHeight, nil)
        end
        
        -- Contract display
        local arrowColor = isSelected and theme:getColor("warning") or theme:getColor("accent")
        theme:drawText("►", leftPanelX + 10, contractY, arrowColor)
        theme:drawText(contract.clientName, leftPanelX + 30, contractY, theme:getColor("primary"))
        contractY = contractY + 15
        
        theme:drawText("  BUDGET: $" .. format.number(contract.totalBudget, 0) .. 
                      " | DURATION: " .. math.floor(contract.duration) .. "s" ..
                      " | REP: +" .. contract.reputationReward, leftPanelX + 30, contractY, theme:getColor("dimmed"))
        contractY = contractY + 15
        
        theme:drawText("  \"" .. contract.description .. "\"", leftPanelX + 30, contractY, theme:getColor("secondary"))
        contractY = contractY + 25
        count = count + 1
    end
    
    if count == 0 then
        theme:drawText("[ NO CONTRACTS AVAILABLE - BUILDING REPUTATION... ]", leftPanelX + 30, contractY, theme:getColor("muted"))
    else
        theme:drawText("Click contract to select, then SPACE to accept | Selected: " .. 
                      (self.selectedContract and "Contract " .. (self:getSelectedContractIndex() or "?") or "None"), 
                      leftPanelX + 30, contractY + 10, theme:getColor("warning"))
    end
    
    -- Active contracts panel (NEW: Show running contracts for better idle feedback)
    if showFull then
        y = y + 200
        theme:drawPanel(leftPanelX, y, panelWidth * 2 + 20, 160, "ACTIVE CONTRACTS")
    else
        -- In compact mode, compress active contracts into the status hint
        y = y + 80
    end
    local activeY = y + 25
    
    local activeContracts = self.systems.contracts:getActiveContracts()
    local activeCount = 0
    for contractId, contract in pairs(activeContracts) do
        if activeCount >= 2 then break end -- Show max 2 active contracts
        
        -- Calculate progress
        local progress = 1.0 - (contract.remainingTime / contract.originalDuration)
        local progressPercent = math.floor(progress * 100)
        local incomeRate = contract.totalBudget / contract.originalDuration
        
        -- Contract display
        theme:drawText("►", leftPanelX + 10, activeY, theme:getColor("success"))
        theme:drawText(contract.clientName, leftPanelX + 30, activeY, theme:getColor("primary"))
        activeY = activeY + 15
        
        -- Progress bar
        local barWidth = panelWidth * 2 - 40
        local progressWidth = math.floor(barWidth * progress)
        
        -- Draw progress bar background
        love.graphics.setColor(theme:getColor("muted"))
        love.graphics.rectangle("fill", leftPanelX + 30, activeY, barWidth, 8)
        
        -- Draw progress bar fill
        love.graphics.setColor(theme:getColor("success"))
        love.graphics.rectangle("fill", leftPanelX + 30, activeY, progressWidth, 8)
        
        activeY = activeY + 12
        
        theme:drawText("  PROGRESS: " .. progressPercent .. "% | REMAINING: " .. 
                      math.ceil(contract.remainingTime) .. "s | INCOME: $" .. 
                      format.number(incomeRate, 2) .. "/sec", 
                      leftPanelX + 30, activeY, theme:getColor("dimmed"))
        activeY = activeY + 25
        activeCount = activeCount + 1
    end
    
    if activeCount == 0 then
        theme:drawText("[ NO ACTIVE CONTRACTS - ACCEPT CONTRACTS TO START EARNING ]", leftPanelX + 30, activeY, theme:getColor("muted"))
    end
    
    -- Status bar with controls
    if showFull then
        theme:drawStatusBar("READY | [CLICK] Select Contract | [SPACE] Accept | [P] Prestige | [C] Convert | [M] Milestones | [A] Crisis Mode | [ESC] Quit")
    else
        theme:drawStatusBar("READY | [TAB] Toggle Terminal | [P] Prestige | [C] Convert | [M] Milestones | [A] Crisis Mode | [ESC] Quit")
    end

    -- (Office map drawn earlier as the main background)
end

-- Helper function to get selected contract index for display
function IdleMode:getSelectedContractIndex()
    if not self.selectedContract then return nil end
    
    for i, area in ipairs(self.contractAreas) do
        if area.contractId == self.selectedContract then
            return i
        end
    end
    return nil
end

function IdleMode:mousepressed(x, y, button)
    -- Handle clicking to select contracts (improved UI framework)
    if button == 1 then -- Left click
        -- Check if click is within any contract area
        for i, area in ipairs(self.contractAreas) do
            if x >= area.x and x <= area.x + area.width and
               y >= area.y and y <= area.y + area.height then
                -- Select this contract
                self.selectedContract = area.contractId
                print("📋 Selected contract: " .. area.contract.clientName .. 
                      " - Budget: $" .. area.contract.totalBudget)
                return true
            end
        end
        
        -- If no contract area was clicked, try to accept selected contract
        if self.selectedContract then
            local success = self.systems.contracts:acceptContract(self.selectedContract)
            if success then
                local contract = self:getSelectedContractData()
                if contract then
                    print("📝 Accepted contract: " .. contract.clientName .. 
                          " - Budget: $" .. contract.totalBudget .. 
                          " | Duration: " .. math.floor(contract.duration) .. "s")
                    
                    -- Show immediate feedback
                    if self.systems.ui then
                        self.systems.ui.lastAction = {
                            message = "Contract accepted: " .. contract.clientName,
                            timer = 3.0
                        }
                    end
                    self.selectedContract = nil -- Clear selection
                    return true
                end
            end
        else
            print("💼 Click on a contract to select it, then press SPACE to accept or click again to accept directly.")
        end
    end
    return false
end

-- Input handling for player movement and interactions
-- Consolidated input handling for player movement and interactions
function IdleMode:keypressed(key)
    -- Handle escape key for conversion mode exit
    if key == "escape" and self.conversionMode then
        self.conversionMode = false
        if self.systems.ui then
            self.systems.ui:showNotification("💱 Exited conversion mode")
        end
        return
    end
    
    -- Movement keys: set input state
    if self.player then
        if key == "up" or key == "w" then self.player:setInput("up", true) end
        if key == "down" or key == "s" then self.player:setInput("down", true) end
        if key == "left" or key == "a" then self.player:setInput("left", true) end
        if key == "right" or key == "d" then self.player:setInput("right", true) end

        -- Interaction
        if key == "e" then
            local interacted, dept = self.player:interact()
            if interacted then
                -- Traditional department interaction
                return
            else
                -- Try room area interaction
                if self.systems.rooms then
                    local currentRoom = self.systems.rooms:getCurrentRoom()
                    if currentRoom and self.enhancedMap then
                        local area = self.enhancedMap:getAreaAtPosition(currentRoom, self.player.x, self.player.y, 0, 0)
                        if area then
                            self.systems.rooms:handleAreaInteraction(area.id, "player")
                            return
                        end
                    end
                end
                if self.systems.ui then
                    self.systems.ui:showNotification("🔍 No nearby interactions. Move closer and press E", 2.0)
                end
            end
            return
        end
        
        -- Room help (H key when in room)
        if key == "h" and not self.roomMenuActive then
            self:showRoomHelp()
            return
        end
        
        -- Room navigation (R key)
        if key == "r" then
            self:showRoomMenu()
            return
        end
    end

    -- Contract acceptance (SPACE)
    if key == "space" then
        if self.selectedContract then
            local success = self.systems.contracts:acceptContract(self.selectedContract)
            if success then
                local contract = self:getSelectedContractData()
                if contract then
                    print("📝 Accepted contract: " .. contract.clientName .. 
                          " - Budget: $" .. contract.totalBudget .. 
                          " | Duration: " .. math.floor(contract.duration) .. "s")
                    self.selectedContract = nil
                end
            else
                print("❌ Failed to accept contract. Check requirements.")
            end
            return
        else
            print("💼 No contract selected. Click on a contract first.")
            return
        end
    end

    -- Room menu number selection and event choices
    if self.roomMenuActive then
        local num = tonumber(key)
        if num and num >= 1 and num <= 9 then
            if self:selectRoom(num) then
                return
            end
        elseif key == "escape" then
            self.roomMenuActive = false
            self.availableRooms = nil
            print("🚪 Room menu cancelled")
            return
        end
    else
        -- Handle room event choices when not in room menu
        local num = tonumber(key)
        if num and num >= 1 and num <= 9 then
            if self:handleEventChoice(num) then
                return
            end
        end
    end

    -- Other mode keys: show details, info, zones, achievements, upgrades
    if key == "enter" then
        if self.selectedContract then
            local contract = self:getSelectedContractData()
            if contract then
                print("📋 CONTRACT DETAILS:")
                print("   Client: " .. contract.clientName)
                print("   Description: " .. contract.description)
                print("   Budget: $" .. format.number(contract.totalBudget, 0))
                print("   Duration: " .. math.floor(contract.duration) .. "s")
                print("   Reputation Reward: +" .. contract.reputationReward)
                print("   Risk Level: " .. (contract.riskLevel or "LOW"))
            end
        else
            print("💼 No contract selected. Click on a contract to view details.")
        end
        return
    elseif key == "i" then
        print("💼 BUSINESS INFORMATION:")
        local resources = self.systems.resources:getAllResources()
        print("   Current Funds: $" .. format.number(resources.money or 0, 0))
        print("   Reputation Level: " .. format.number(resources.reputation or 0, 0))
        print("   Experience Points: " .. format.number(resources.xp or 0, 0))
        print("   Mission Tokens: " .. format.number(resources.missionTokens or 0, 0))
        local contractStats = self.systems.contracts:getStats()
        print("   Active Contracts: " .. contractStats.activeContracts)
        print("   Revenue Rate: $" .. format.number(contractStats.totalIncomeRate, 2) .. "/sec")
        if self.systems.save and self.systems.save.getConnectionStatus then
            local status = self.systems.save:getConnectionStatus()
            print("🌐 NETWORK STATUS:")
            print("   Server Connection: " .. (status.isOnline and "ONLINE" or "OFFLINE"))
            print("   Save Mode: " .. string.upper(status.saveMode))
            print("   Player ID: " .. status.username)
            if status.offlineMode then
                print("   Mode: OFFLINE (Network disabled)")
            end
        end
        return
    elseif key == "z" then
        print("🗺️ Zone System:")
        local zones = self.systems.zones:getUnlockedZones()
        local currentZoneId = self.systems.zones:getCurrentZoneId()
        for zoneId, zone in pairs(zones) do
            local current = zoneId == currentZoneId and " (CURRENT)" or ""
            print("   " .. zone.name .. current .. " - " .. zone.description)
        end
        print("")
        print("🏢 Room System:")
        if self.systems.rooms then
            local rooms = self.systems.rooms:getAvailableRooms()
            local currentRoom = self.systems.rooms:getCurrentRoom()
            print("   Current: " .. (currentRoom and currentRoom.name or "None"))
            print("   Available Rooms:")
            for _, room in ipairs(rooms) do
                local indicator = room.current and " (HERE)" or ""
                print("     • " .. room.name .. indicator)
                print("       " .. room.description)
            end
            print("   Press R to open room navigation menu")
        else
            print("   Room system not available")
        end
        return
    elseif key == "h" then
        print("🏆 Achievements:")
        local achievements = self.systems.achievements:getAllAchievements()
        local progress = self.systems.achievements:getProgress()
        print("   📊 Progress:")
        print("      Total Clicks: " .. progress.totalClicks)
        print("      Upgrades Purchased: " .. progress.totalUpgradesPurchased)
        print("      Max Combo: " .. format.number(progress.maxClickCombo, 1) .. "x")
        print("      Critical Hits: " .. progress.criticalHits)
        local unlockedCount = 0
        local totalCount = 0
        for achievementId, achievement in pairs(achievements) do
            totalCount = totalCount + 1
            local status = achievement.unlocked and "✅" or "❌"
            local reqText = ""
            if achievement.requirement.type == "clicks" then
                reqText = " (" .. progress.totalClicks .. "/" .. achievement.requirement.value .. " clicks)"
            elseif achievement.requirement.type == "maxCombo" then
                reqText = " (" .. format.number(progress.maxClickCombo, 1) .. "/" .. achievement.requirement.value .. "x combo)"
            elseif achievement.requirement.type == "upgrades" then
                reqText = " (" .. progress.totalUpgradesPurchased .. "/" .. achievement.requirement.value .. " upgrades)"
            end
            print("   " .. status .. " " .. achievement.name .. reqText)
            print("      " .. achievement.description)
            if achievement.unlocked then unlockedCount = unlockedCount + 1 end
        end
        print("")
        print("   🎯 Progress: " .. unlockedCount .. "/" .. totalCount .. " achievements unlocked")
        return
    elseif key == "p" then
        -- Handle prestige
        if self.systems.progression and self.systems.progression:canPrestige() then
            local pointsToEarn = self.systems.progression:calculatePrestigePoints()
            print("🌟 PRESTIGE AVAILABLE!")
            print("   Points to earn: " .. pointsToEarn)
            print("   Current level: " .. (self.systems.progression.prestigeLevel or 0))
            print("   This will reset your company but grant permanent bonuses.")
            print("   Press P again to confirm prestige.")
            -- Simple confirmation - in real game, you'd want a proper confirmation dialog
            if self.prestigeConfirmation then
                local success = self.systems.progression:performPrestige()
                if success then
                    print("🌟 PRESTIGE COMPLETE! Welcome to your new company!")
                end
                self.prestigeConfirmation = false
            else
                self.prestigeConfirmation = true
            end
        else
            print("🌟 Prestige not available. Check progression requirements.")
        end
        return
    elseif key == "c" then
        -- Handle currency conversions
        if self.systems.progression then
            self.conversionMode = true
            print("💱 CURRENCY CONVERSIONS:")
            print("   [1] Convert 100 XP → 1 Skill Point")
            print("   [2] Convert $1000 → 1 Research Credit") 
            print("   [3] Show conversion status")
            print("   [ESC] Exit conversion mode")
            print("   Press number to perform conversion.")
        end
        return
    elseif key == "m" then
        -- Show progression milestones and status
        if self.systems.progression then
            print("🎯 PROGRESSION STATUS:")
            local currentTier = self.systems.progression:getCurrentTier()
            print("   Current Tier: " .. (currentTier.name or "Unknown"))
            print("   Tier Description: " .. (currentTier.description or ""))
            
            print("")
            print("🏆 COMPLETED MILESTONES:")
            local milestones = self.systems.progression.config.milestones or {}
            local completed = self.systems.progression.completedMilestones or {}
            for milestoneId, milestone in pairs(milestones) do
                local status = completed[milestoneId] and "✅" or "❌"
                print("   " .. status .. " " .. milestone.name)
                print("      " .. milestone.description)
                if milestone.rewards then
                    local rewardText = "Rewards: "
                    for rewardType, amount in pairs(milestone.rewards) do
                        rewardText = rewardText .. amount .. " " .. rewardType .. " "
                    end
                    print("      " .. rewardText)
                end
            end
            
            print("")
            print("💰 CURRENCY STATUS:")
            local currencies = self.systems.progression:getAllCurrencies()
            for currencyId, data in pairs(currencies) do
                local config = data.config
                local symbol = config.symbol or currencyId:upper()
                print("   " .. config.name .. ": " .. format.number(data.amount, 0) .. " " .. symbol)
                if data.totalEarned > 0 then
                    print("      Total Earned: " .. format.number(data.totalEarned, 0))
                end
            end
        end
        return
    elseif key >= "1" and key <= "9" then
        local numKey = tonumber(key)
        
        -- Handle currency conversions if in conversion mode
        if self.conversionMode and self.systems.progression then
            if numKey == 1 then
                local success = self.systems.progression:convertCurrency("xpToSkillPoints")
                if success then
                    print("✅ Converted 100 XP to 1 Skill Point!")
                else
                    print("❌ Conversion failed. Check XP amount and daily limits.")
                end
            elseif numKey == 2 then
                local success = self.systems.progression:convertCurrency("moneyToResearch")
                if success then
                    print("✅ Converted $1000 to 1 Research Credit!")
                else
                    print("❌ Conversion failed. Check money amount and daily limits.")
                end
            elseif numKey == 3 then
                local dailyConversions = self.systems.progression.dailyConversions[os.date("%Y-%m-%d")] or {}
                print("📊 Today's Conversions:")
                print("   XP→SP: " .. (dailyConversions["xpToSkillPoints"] or 0) .. "/10")
                print("   Money→RC: " .. (dailyConversions["moneyToResearch"] or 0) .. "/5")
            end
            self.conversionMode = false
            return
        end
        
        -- Handle upgrade purchases (original behavior)
        local upgradeIndex = numKey
        local upgrades = self.systems.upgrades:getUnlockedUpgrades()
        local upgradeIds = {}
        for upgradeId, upgrade in pairs(upgrades) do table.insert(upgradeIds, upgradeId) end
        if upgradeIndex <= #upgradeIds then
            local upgradeId = upgradeIds[upgradeIndex]
            local success = self.systems.upgrades:purchaseUpgrade(upgradeId)
            if not success then
                local upgrade = self.systems.upgrades:getUpgrade(upgradeId)
                local cost = self.systems.upgrades:getUpgradeCost(upgradeId)
                local owned = self.systems.upgrades:getUpgradeCount(upgradeId)
                if owned >= upgrade.maxCount then
                    print("❌ Cannot purchase: Already at maximum count (" .. upgrade.maxCount .. ")")
                else
                    local costText = ""
                    for resource, amount in pairs(cost) do
                        costText = costText .. format.number(amount, 0) .. " " .. resource .. " "
                    end
                    print("❌ Cannot afford: Need " .. costText)
                end
            end
        end
        return
    end

    -- If not handled above, let UI handle the key (e.g., modal close)
    if self.systems and self.systems.ui and self.systems.ui.keypressed then
        self.systems.ui:keypressed(key)
    end
end

-- Helper function to get selected contract data
function IdleMode:getSelectedContractData()
    if not self.selectedContract then return nil end
    
    local availableContracts = self.systems.contracts:getAvailableContracts()
    return availableContracts[self.selectedContract]
end

-- Show room navigation menu
function IdleMode:showRoomMenu()
    if not self.systems.rooms then 
        print("🏢 Room system not available")
        return 
    end
    
    local availableRooms = self.systems.rooms:getAvailableRooms()
    if #availableRooms == 0 then
        print("🔒 No rooms available")
        return
    end
    
    print("🚪 Available Rooms:")
    for i, room in ipairs(availableRooms) do
        local status = room.current and " [CURRENT]" or ""
        print("   " .. i .. ". " .. room.name .. status)
        print("      " .. room.description)
    end
    print("Enter room number (1-" .. #availableRooms .. ") or ESC to cancel:")
    
    -- Set room menu state for number key handling
    self.roomMenuActive = true
    self.availableRooms = availableRooms
end

-- Show room-specific help and interaction guide
function IdleMode:showRoomHelp()
    if not self.systems.rooms then 
        print("🏢 Room system not available")
        return 
    end
    
    local currentRoom = self.systems.rooms:getCurrentRoom()
    if not currentRoom then
        print("❓ No active room")
        return
    end
    
    print("❓ " .. currentRoom.name .. " - Help & Interactions")
    print("📋 " .. currentRoom.description)
    print("")
    
    if currentRoom.areas and #currentRoom.areas > 0 then
        print("🎯 Available Interactions:")
        for _, area in ipairs(currentRoom.areas) do
            print("   " .. (area.icon or "●") .. " " .. area.name)
            print("      Action: " .. (area.action or "interact"):gsub("_", " "))
        end
        print("")
        print("💡 Move close to an area and press E to interact")
    else
        print("   No interactive areas in this room")
    end
    
    if currentRoom.bonuses then
        print("⚡ Room Bonuses:")
        for bonusName, multiplier in pairs(currentRoom.bonuses) do
            if type(multiplier) == "number" and multiplier > 1 then
                local bonus = math.floor((multiplier - 1) * 100)
                print("   • " .. bonusName:gsub("Multiplier", ""):gsub("Bonus", "") .. ": +" .. bonus .. "%")
            end
        end
    end
    
    if currentRoom.atmosphere then
        print("")
        print("🌟 Atmosphere: " .. currentRoom.atmosphere)
    end
    
    -- Show active events if any
    if self.systems.roomEvents then
        local activeEvents = self.systems.roomEvents:getActiveEvents()
        if #activeEvents > 0 then
            print("")
            print("🎭 Active Events in This Room:")
            for _, event in ipairs(activeEvents) do
                if event.roomId == currentRoom.id then
                    local urgency = event.critical and "🔥 CRITICAL" or event.urgent and "⚡ URGENT" or "📢"
                    print("   " .. urgency .. " " .. event.title)
                    if event.duration then
                        print("      ⏱️ " .. math.floor(event.duration) .. " seconds remaining")
                    end
                end
            end
        end
    end
    
    print("")
    print("🎮 Controls:")
    print("   WASD/Arrows - Move around")
    print("   E - Interact with nearby areas")
    print("   R - Room navigation menu")
    print("   H - This help (room-specific)")
    print("   1-9 - Make event choices")
end

-- Handle room selection
function IdleMode:selectRoom(roomIndex)
    if not self.roomMenuActive or not self.availableRooms then return false end
    
    local room = self.availableRooms[roomIndex]
    if not room then
        print("❌ Invalid room selection")
        return false
    end
    
    if room.current then
        print("📍 Already in " .. room.name)
    else
        self.systems.rooms:changeRoom(room.id, "menu_selection")
        -- Update player position to room center
        if self.player and self.systems.rooms then
            local newRoom = self.systems.rooms:getCurrentRoom()
            if newRoom then
                self.player.x = (newRoom.width or 640) / 2
                self.player.y = (newRoom.height or 400) / 2
            end
        end
    end
    
    -- Clear room menu state
    self.roomMenuActive = false
    self.availableRooms = nil
    return true
end

-- Get room index for area under cursor (for mouse interaction)
function IdleMode:getAreaUnderCursor(x, y)
    if not self.systems.rooms or not self.enhancedMap then return nil end
    
    local currentRoom = self.systems.rooms:getCurrentRoom()
    if not currentRoom then return nil end
    
    -- Adjust coordinates based on office map position
    local adjustedX = x - 40
    local adjustedY = y - 140
    
    return self.enhancedMap:getAreaAtPosition(currentRoom, adjustedX, adjustedY, 0, 0)
end

-- Handle mouse interaction with room areas
function IdleMode:mousepressed(x, y, button)
    if button == 1 then -- Left click
        local area = self:getAreaUnderCursor(x, y)
        if area then
            self.systems.rooms:handleAreaInteraction(area.id, "player")
            return true
        end
    end
    return false
end

-- Handle room event choices
function IdleMode:handleEventChoice(choiceNum)
    if not self.systems.roomEvents then return false end
    
    local activeEvents = self.systems.roomEvents:getActiveEvents()
    if #activeEvents == 0 then return false end
    
    -- Use the most recent event (first in list)
    local event = activeEvents[1]
    if event.choices and choiceNum <= #event.choices then
        local success = self.systems.roomEvents:makeEventChoice(event.id, choiceNum)
        if success then
            print("📝 Choice selected: " .. event.choices[choiceNum].text)
            return true
        end
    end
    
    return false
end

-- Get current room status for display
function IdleMode:getRoomStatus()
    if not self.systems.rooms then return "Room system unavailable" end
    
    local currentRoom = self.systems.rooms:getCurrentRoom()
    if not currentRoom then return "No active room" end
    
    local status = "📍 " .. currentRoom.name
    
    -- Add room bonuses info
    if currentRoom.bonuses then
        local bonusCount = 0
        for _ in pairs(currentRoom.bonuses) do bonusCount = bonusCount + 1 end
        if bonusCount > 0 then
            status = status .. " (" .. bonusCount .. " active bonuses)"
        end
    end
    
    -- Add occupancy if applicable
    if currentRoom.maxOccupancy then
        local occupancy = currentRoom.currentOccupancy or 1
        status = status .. " [" .. occupancy .. "/" .. currentRoom.maxOccupancy .. "]"
    end
    
    return status
end

-- Display room events in UI
function IdleMode:drawRoomEvents(theme, x, y, width)
    if not self.systems.roomEvents then return y end
    
    local activeEvents = self.systems.roomEvents:getActiveEvents()
    if #activeEvents == 0 then return y end
    
    y = y + 10
    theme:drawText("🎭 ACTIVE EVENTS", x, y, theme:getColor("warning"))
    y = y + 20
    
    for i, event in ipairs(activeEvents) do
        if i > 2 then break end -- Show max 2 events to save space
        
        -- Event title with urgency indicator
        local titleColor = event.critical and theme:getColor("danger") or 
                          event.urgent and theme:getColor("warning") or 
                          theme:getColor("accent")
        local prefix = event.critical and "🔥 " or event.urgent and "⚡ " or "📢 "
        
        theme:drawText(prefix .. event.title, x + 5, y, titleColor)
        y = y + 15
        
        -- Description
        theme:drawText("  " .. event.description, x + 5, y, theme:getColor("secondary"))
        y = y + 12
        
        -- Time remaining
        if event.duration then
            local timeLeft = math.max(0, math.floor(event.duration))
            theme:drawText("  ⏱️ " .. timeLeft .. "s remaining", x + 5, y, theme:getColor("muted"))
            y = y + 12
        end
        
        -- Choices
        if event.choices then
            theme:drawText("  💭 Press number key:", x + 5, y, theme:getColor("dimmed"))
            y = y + 12
            for j, choice in ipairs(event.choices) do
                if j <= 3 then -- Show max 3 choices
                    theme:drawText("    " .. j .. ". " .. choice.text, x + 5, y, theme:getColor("primary"))
                    y = y + 12
                end
            end
        end
        
        y = y + 5 -- Spacing between events
    end
    
    return y
end


return IdleMode