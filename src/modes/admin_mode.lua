-- Admin Mode - "The Admin's Watch"
-- Real-time operations mode and comprehensive admin panel

local AdminMode = {}
AdminMode.__index = AdminMode

local format = require("src.utils.format")

-- Create new admin mode
function AdminMode.new(systems)
    local self = setmetatable({}, AdminMode)
    self.systems = systems
    
    -- Admin panel state
    self.currentTab = "overview" -- overview, resources, upgrades, systems, debug
    self.selectedResource = nil
    self.editMode = false
    self.editValue = ""
    
    -- Admin mode specific state (original functionality preserved)
    self.corporateClient = {
        name = "TechCorp Industries",
        sector = "Technology",
        uptime = 99.9,
        budget = 50000
    }
    
    self.operationalResources = {
        cpuCycles = 100,
        bandwidth = 1000,
        personnelHours = 40,
        emergencyFunds = 10000
    }
    
    -- Tab definitions for the admin panel
    self.tabs = {
        {id = "overview", name = "📊 Overview", key = "1"},
        {id = "resources", name = "💎 Resources", key = "2"},
        {id = "upgrades", name = "🔧 Upgrades", key = "3"},
        {id = "systems", name = "⚙️ Systems", key = "4"},
        {id = "debug", name = "🐛 Debug", key = "5"}
    }
    
    return self
end

function AdminMode:update(dt)
    -- Handle admin mode specific updates
end

function AdminMode:draw()
    -- Draw admin panel header
    love.graphics.setColor(0.1, 0.8, 0.1) -- Green text for "hacker" feel
    love.graphics.print("👨‍💻 THE ADMIN'S WATCH - Backend Management Console", 20, 20)
    
    -- Draw tab navigation
    love.graphics.setColor(1, 1, 1)
    local tabY = 50
    local tabX = 20
    for i, tab in ipairs(self.tabs) do
        local isActive = tab.id == self.currentTab
        if isActive then
            love.graphics.setColor(0.2, 0.8, 0.2) -- Highlight active tab
        else
            love.graphics.setColor(0.7, 0.7, 0.7) -- Inactive tab
        end
        
        love.graphics.print("[" .. tab.key .. "] " .. tab.name, tabX, tabY)
        tabX = tabX + 150
    end
    
    -- Draw tab content
    love.graphics.setColor(1, 1, 1)
    local contentY = 80
    
    if self.currentTab == "overview" then
        self:drawOverviewTab(contentY)
    elseif self.currentTab == "resources" then
        self:drawResourcesTab(contentY)
    elseif self.currentTab == "upgrades" then
        self:drawUpgradesTab(contentY)
    elseif self.currentTab == "systems" then
        self:drawSystemsTab(contentY)
    elseif self.currentTab == "debug" then
        self:drawDebugTab(contentY)
    end
    
    -- Footer instructions
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print("Press 'A' to return to Idle Mode | Use 1-5 to switch tabs", 20, love.graphics.getHeight() - 60)
    if self.currentTab == "resources" then
        love.graphics.print("E=Edit Mode | R=Reset | M=+1000 DB | P=+100 PP | X=Max All", 20, love.graphics.getHeight() - 40)
    elseif self.currentTab == "upgrades" then
        love.graphics.print("G=Grant Upgrade | C=Clear All", 20, love.graphics.getHeight() - 40)
    elseif self.currentTab == "systems" then
        love.graphics.print("S=Save | L=Load | N=New Game", 20, love.graphics.getHeight() - 40)
    elseif self.currentTab == "debug" then
        love.graphics.print("M=GC | T=Debug Toggle | P=Print State", 20, love.graphics.getHeight() - 40)
    end
end

-- Draw overview tab
function AdminMode:drawOverviewTab(y)
    love.graphics.print("🎮 GAME STATUS OVERVIEW", 20, y)
    y = y + 30
    
    -- Game state info
    local gameState = self.systems
    love.graphics.print("🏠 Current Mode: " .. (gameState.currentMode or "admin"), 30, y)
    y = y + 20
    love.graphics.print("⏸️ Paused: " .. (gameState.paused and "Yes" or "No"), 30, y)
    y = y + 20
    love.graphics.print("🐛 Debug Mode: " .. (gameState.debugMode and "Yes" or "No"), 30, y)
    y = y + 40
    
    -- Client information (original admin mode content)
    love.graphics.print("🏢 CLIENT INFORMATION:", 20, y)
    y = y + 25
    love.graphics.print("  Client: " .. self.corporateClient.name, 30, y)
    y = y + 20
    love.graphics.print("  Uptime: " .. self.corporateClient.uptime .. "%", 30, y)
    y = y + 20
    love.graphics.print("  Budget: $" .. format.number(self.corporateClient.budget), 30, y)
    y = y + 40
    
    -- Operational resources (original admin mode content)
    love.graphics.print("🔧 OPERATIONAL RESOURCES:", 20, y)
    y = y + 25
    for resource, value in pairs(self.operationalResources) do
        love.graphics.print("  " .. resource .. ": " .. format.number(value), 30, y)
        y = y + 20
    end
    y = y + 20
    
    -- Network status
    love.graphics.print("🌐 NETWORK STATUS:", 20, y)
    love.graphics.setColor(0.2, 0.8, 0.2)
    love.graphics.print("  All systems operational", 30, y + 25)
    love.graphics.setColor(1, 1, 1)
end

-- Draw resources tab
function AdminMode:drawResourcesTab(y)
    love.graphics.print("💎 RESOURCE MANAGEMENT", 20, y)
    y = y + 30
    
    local resources = self.systems.resources:getAllResources()
    local generation = self.systems.resources:getAllGeneration()
    
    love.graphics.print("Current Resources:", 30, y)
    y = y + 25
    
    local col1X, col2X, col3X = 40, 200, 350
    love.graphics.print("Resource", col1X, y)
    love.graphics.print("Amount", col2X, y)
    love.graphics.print("Generation/sec", col3X, y)
    y = y + 20
    
    for resourceName, amount in pairs(resources) do
        if amount > 0 or generation[resourceName] > 0 then
            -- Highlight selected resource for editing
            if self.selectedResource == resourceName and self.editMode then
                love.graphics.setColor(1, 1, 0) -- Yellow for editing
            end
            
            local emoji = self:getResourceEmoji(resourceName)
            love.graphics.print(emoji .. " " .. resourceName, col1X, y)
            
            if self.selectedResource == resourceName and self.editMode then
                love.graphics.print("> " .. self.editValue .. "_", col2X, y)
            else
                love.graphics.print(format.number(amount, 2), col2X, y)
            end
            
            love.graphics.print("+" .. format.rate(generation[resourceName], 1), col3X, y)
            
            love.graphics.setColor(1, 1, 1) -- Reset color
            y = y + 20
        end
    end
    
    if self.editMode then
        y = y + 20
        love.graphics.setColor(0.2, 0.8, 0.2)
        love.graphics.print("EDIT MODE: Enter new value, press ENTER to confirm, ESC to cancel", 30, y)
        love.graphics.setColor(1, 1, 1)
    end
end

-- Draw upgrades tab
function AdminMode:drawUpgradesTab(y)
    love.graphics.print("🔧 UPGRADE MANAGEMENT", 20, y)
    y = y + 30
    
    if not self.systems.upgrades then
        love.graphics.print("Upgrade system not available", 30, y)
        return
    end
    
    love.graphics.print("Owned Upgrades:", 30, y)
    y = y + 25
    
    local owned = self.systems.upgrades:getOwnedUpgrades()
    local hasUpgrades = false
    
    for upgradeId, count in pairs(owned) do
        if count > 0 then
            hasUpgrades = true
            local upgrade = self.systems.upgrades:getUpgrade(upgradeId)
            if upgrade then
                love.graphics.print("  " .. upgrade.name .. " x" .. count, 40, y)
                y = y + 20
                love.graphics.setColor(0.7, 0.7, 0.7)
                love.graphics.print("    " .. upgrade.description, 40, y)
                love.graphics.setColor(1, 1, 1)
                y = y + 25
            end
        end
    end
    
    if not hasUpgrades then
        love.graphics.print("  No upgrades owned yet", 40, y)
        y = y + 20
    end
    
    y = y + 20
    love.graphics.print("Available Upgrades:", 30, y)
    y = y + 25
    
    local allUpgrades = self.systems.upgrades:getAllUpgrades()
    local availableCount = 0
    for upgradeId, upgrade in pairs(allUpgrades) do
        if upgrade.unlocked and (not owned[upgradeId] or owned[upgradeId] < upgrade.maxCount) then
            availableCount = availableCount + 1
            local cost = self.systems.upgrades:getUpgradeCost(upgradeId)
            local costText = ""
            for resource, amount in pairs(cost) do
                costText = costText .. format.number(amount, 0) .. " " .. resource .. " "
            end
            
            love.graphics.setColor(0.8, 0.8, 1.0)
            love.graphics.print("  " .. upgrade.name .. " - " .. costText, 40, y)
            love.graphics.setColor(1, 1, 1)
            y = y + 20
            if y > love.graphics.getHeight() - 120 then
                love.graphics.print("  ... and more", 40, y)
                break
            end
        end
    end
    
    if availableCount == 0 then
        love.graphics.print("  No upgrades available for purchase", 40, y)
        y = y + 20
    end
    
    y = math.max(y + 20, love.graphics.getHeight() - 100)
    love.graphics.print("Available Actions:", 30, y)
    y = y + 20
    love.graphics.print("  Press 'G' to grant first available upgrade", 40, y)
    y = y + 20
    love.graphics.print("  Press 'C' to clear all upgrades", 40, y)
end

-- Draw systems tab
function AdminMode:drawSystemsTab(y)
    love.graphics.print("⚙️ SYSTEM STATUS", 20, y)
    y = y + 30
    
    -- System status overview
    local systems = {
        {name = "Resource System", obj = self.systems.resources, status = "✅ Online"},
        {name = "Upgrade System", obj = self.systems.upgrades, status = "✅ Online"},
        {name = "Save System", obj = self.systems.save, status = "✅ Online"},
        {name = "Zone System", obj = self.systems.zones, status = "✅ Online"},
        {name = "Threat System", obj = self.systems.threats, status = "✅ Online"},
        {name = "Faction System", obj = self.systems.factions, status = "✅ Online"},
        {name = "Achievement System", obj = self.systems.achievements, status = "✅ Online"},
        {name = "Event Bus", obj = self.systems.eventBus, status = "✅ Online"}
    }
    
    for _, system in ipairs(systems) do
        local status = system.obj and system.status or "❌ Offline"
        love.graphics.print("  " .. system.name .. ": " .. status, 30, y)
        y = y + 20
    end
    
    y = y + 20
    love.graphics.print("Game Actions:", 30, y)
    y = y + 20
    love.graphics.print("  Press 'S' to force save game", 40, y)
    y = y + 20
    love.graphics.print("  Press 'L' to reload game", 40, y)
    y = y + 20
    love.graphics.print("  Press 'N' to start new game", 40, y)
end

-- Draw debug tab
function AdminMode:drawDebugTab(y)
    love.graphics.print("🐛 DEBUG INFORMATION", 20, y)
    y = y + 30
    
    -- Performance info
    love.graphics.print("Performance:", 30, y)
    y = y + 20
    love.graphics.print("  FPS: " .. love.timer.getFPS(), 40, y)
    y = y + 20
    love.graphics.print("  Memory: " .. math.floor(collectgarbage("count")) .. " KB", 40, y)
    y = y + 20
    
    -- Event bus stats if available
    if self.systems.eventBus and self.systems.eventBus.getStats then
        local stats = self.systems.eventBus:getStats()
        love.graphics.print("  Events Published: " .. (stats.published or 0), 40, y)
        y = y + 20
        love.graphics.print("  Subscribers: " .. (stats.subscribers or 0), 40, y)
        y = y + 20
    end
    
    y = y + 20
    love.graphics.print("Debug Actions:", 30, y)
    y = y + 20
    love.graphics.print("  Press 'M' to run garbage collection", 40, y)
    y = y + 20
    love.graphics.print("  Press 'T' to toggle debug mode", 40, y)
    y = y + 20
    love.graphics.print("  Press 'P' to print game state to console", 40, y)
end

-- Helper function to get resource emoji
function AdminMode:getResourceEmoji(resourceName)
    local emojis = {
        dataBits = "💎",
        processingPower = "⚡",
        securityRating = "🛡️",
        reputationPoints = "⭐",
        researchData = "🔬",
        neuralNetworkFragments = "🧠",
        quantumEntanglementTokens = "🌌"
    }
    return emojis[resourceName] or "❓"
end

function AdminMode:mousepressed(x, y, button)
    -- Handle admin mode clicking
    if self.currentTab == "resources" and button == 1 then
        -- Click on resources to select for editing
        local resources = self.systems.resources:getAllResources()
        local generation = self.systems.resources:getAllGeneration()
        
        local startY = 135 -- Approximate start of resource list
        local lineHeight = 20
        local resourceIndex = 0
        
        for resourceName, amount in pairs(resources) do
            if amount > 0 or generation[resourceName] > 0 then
                local resourceY = startY + (resourceIndex * lineHeight)
                if y >= resourceY and y <= resourceY + lineHeight then
                    self.selectedResource = resourceName
                    self.editMode = false
                    self.editValue = ""
                    print("Selected resource: " .. resourceName)
                    return true
                end
                resourceIndex = resourceIndex + 1
            end
        end
    end
    return false
end

function AdminMode:keypressed(key)
    -- Handle tab switching
    if key >= "1" and key <= "5" then
        local tabIndex = tonumber(key)
        if self.tabs[tabIndex] then
            self.currentTab = self.tabs[tabIndex].id
            self.editMode = false -- Exit edit mode when switching tabs
            self.selectedResource = nil
            print("Switched to " .. self.tabs[tabIndex].name .. " tab")
        end
        return
    end
    
    -- Handle edit mode
    if self.currentTab == "resources" then
        if key == "e" and self.selectedResource then
            self.editMode = not self.editMode
            if self.editMode then
                local currentValue = self.systems.resources:getResource(self.selectedResource)
                self.editValue = tostring(math.floor(currentValue))
                print("Editing " .. self.selectedResource .. " - current value: " .. self.editValue)
            else
                print("Exited edit mode")
            end
        elseif self.editMode then
            if key == "return" or key == "kpenter" then
                -- Confirm edit
                local newValue = tonumber(self.editValue)
                if newValue and newValue >= 0 then
                    self.systems.resources:setResource(self.selectedResource, newValue)
                    print("Set " .. self.selectedResource .. " to " .. newValue)
                else
                    print("Invalid value entered")
                end
                self.editMode = false
                self.selectedResource = nil
            elseif key == "escape" then
                -- Cancel edit
                self.editMode = false
                print("Cancelled edit")
            elseif key == "backspace" then
                -- Remove last character
                self.editValue = self.editValue:sub(1, -2)
            elseif key:match("%d") then
                -- Add digit
                self.editValue = self.editValue .. key
            elseif key == "." and not self.editValue:find("%.") then
                -- Add decimal point
                self.editValue = self.editValue .. key
            end
        elseif key == "r" then
            -- Reset all resources
            print("Resetting all resources...")
            for resourceName, _ in pairs(self.systems.resources:getAllResources()) do
                self.systems.resources:setResource(resourceName, 0)
            end
            print("All resources reset to 0")
        elseif key == "m" then
            -- Give money (Data Bits)
            local currentBits = self.systems.resources:getResource("dataBits")
            self.systems.resources:setResource("dataBits", currentBits + 1000)
            print("💎 Added 1000 Data Bits")
        elseif key == "p" then
            -- Give processing power
            local currentPower = self.systems.resources:getResource("processingPower")
            self.systems.resources:setResource("processingPower", currentPower + 100)
            print("⚡ Added 100 Processing Power")
        elseif key == "x" then
            -- Max out all resources
            print("Maxing out all resources...")
            local bigNumber = 999999999
            for resourceName, _ in pairs(self.systems.resources:getAllResources()) do
                self.systems.resources:setResource(resourceName, bigNumber)
            end
            print("All resources set to maximum")
        end
    end
    
    -- Handle upgrades tab
    if self.currentTab == "upgrades" then
        if key == "g" then
            -- Grant first available upgrade
            print("Granting first available upgrade...")
            local allUpgrades = self.systems.upgrades:getAllUpgrades()
            local owned = self.systems.upgrades:getOwnedUpgrades()
            
            for upgradeId, upgrade in pairs(allUpgrades) do
                if upgrade.unlocked and (not owned[upgradeId] or owned[upgradeId] < upgrade.maxCount) then
                    -- Add one copy of this upgrade directly
                    if not owned[upgradeId] then
                        owned[upgradeId] = 0
                    end
                    owned[upgradeId] = owned[upgradeId] + 1
                    
                    -- Apply upgrade effects via resource system
                    if self.systems.resources and upgrade.effects then
                        for effectType, value in pairs(upgrade.effects) do
                            self.systems.resources:applyUpgradeEffect(upgradeId, effectType, value)
                        end
                    end
                    
                    print("✨ Granted: " .. upgrade.name .. " (now x" .. owned[upgradeId] .. ")")
                    break
                end
            end
        elseif key == "c" then
            -- Clear all upgrades
            print("Clearing all upgrades...")
            local owned = self.systems.upgrades:getOwnedUpgrades()
            for upgradeId, _ in pairs(owned) do
                owned[upgradeId] = 0
            end
            print("All upgrades cleared")
        end
    end
    
    -- Handle systems tab actions
    if self.currentTab == "systems" then
        if key == "s" then
            -- Force save
            print("Force saving game...")
            if self.systems.save then
                local gameData = {
                    resources = self.systems.resources:getState(),
                    upgrades = self.systems.upgrades:getState(),
                    threats = self.systems.threats and self.systems.threats:getState() or {},
                    zones = self.systems.zones and self.systems.zones:getState() or {},
                    factions = self.systems.factions and self.systems.factions:getState() or {},
                    achievements = self.systems.achievements and self.systems.achievements:getState() or {},
                    version = "1.0.0",
                    timestamp = os.time()
                }
                
                if self.systems.save:save(gameData) then
                    print("✅ Game saved successfully")
                else
                    print("❌ Save failed")
                end
            else
                print("❌ Save system not available")
            end
        elseif key == "l" then
            -- Reload game
            print("Reloading game...")
            if self.systems.save then
                local savedData = self.systems.save:load()
                if savedData then
                    -- Load the saved data into systems
                    if savedData.resources and self.systems.resources then
                        self.systems.resources:loadState(savedData.resources)
                    end
                    if savedData.upgrades and self.systems.upgrades then
                        self.systems.upgrades:loadState(savedData.upgrades)
                    end
                    print("✅ Game reloaded successfully")
                else
                    print("❌ No save file found")
                end
            else
                print("❌ Save system not available")
            end
        elseif key == "n" then
            -- New game (reset to default state)
            print("Starting new game...")
            
            -- Reset all resources
            for resourceName, _ in pairs(self.systems.resources:getAllResources()) do
                self.systems.resources:setResource(resourceName, 0)
                self.systems.resources:setGeneration(resourceName, 0)
            end
            
            -- Set default starting resources
            self.systems.resources:setResource("dataBits", 0)
            self.systems.resources:setResource("processingPower", 0)
            self.systems.resources:setResource("securityRating", 0)
            
            -- Clear all upgrades
            local owned = self.systems.upgrades:getOwnedUpgrades()
            for upgradeId, _ in pairs(owned) do
                owned[upgradeId] = 0
            end
            
            print("✅ New game started - all progress reset")
        end
    end
    
    -- Handle debug tab actions
    if self.currentTab == "debug" then
        if key == "m" then
            -- Run garbage collection
            local before = collectgarbage("count")
            collectgarbage("collect")
            local after = collectgarbage("count")
            print("Garbage collection: " .. math.floor(before - after) .. " KB freed")
        elseif key == "t" then
            -- Toggle debug mode
            print("Debug mode toggle requested")
        elseif key == "p" then
            -- Print game state
            print("=== GAME STATE DEBUG ===")
            local resources = self.systems.resources:getAllResources()
            for name, value in pairs(resources) do
                print(name .. ": " .. value)
            end
        end
    end
    
    -- Original admin mode functionality
    if key == "1" or key == "2" or key == "3" then
        if self.currentTab == "overview" then
            print("🚨 Incident response " .. key .. " activated")
        end
    end
end

function AdminMode:update(dt)
    -- Handle admin mode specific updates
    -- Could add real-time monitoring, alerts, etc.
end

return AdminMode