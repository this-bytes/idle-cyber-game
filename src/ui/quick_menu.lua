-- Quick Menu System - Interactive Game Menu with Keyboard/Mouse Navigation
-- Provides instant access to game functions and navigation
-- Supports both keyboard shortcuts and mouse interaction

local QuickMenu = {}
QuickMenu.__index = QuickMenu

local UIHelpers = require("src.ui.ui_helpers")

function QuickMenu.new(eventBus, resourceManager)
    local self = setmetatable({}, QuickMenu)
    
    self.eventBus = eventBus
    self.resourceManager = resourceManager
    
    -- Menu state
    self.visible = false
    self.selectedIndex = 1
    self.lastToggleTime = 0
    
    -- Menu structure
    self.menuItems = {
        {
            text = "Toggle Auto-Contracts",
            icon = "💼",
            key = "space",
            action = "toggle_auto_contracts",
            description = "Enable/disable automatic contract completion"
        },
        {
            text = "View Resources",
            icon = "💰", 
            key = "r",
            action = "show_resources",
            description = "Display current resources and generation rates"
        },
        {
            text = "Location Navigator",
            icon = "🏢",
            key = "l",
            action = "show_locations", 
            description = "Navigate between buildings, floors, and rooms"
        },
        {
            text = "Upgrade Security",
            icon = "🛡️",
            key = "u",
            action = "show_upgrades",
            description = "Purchase security upgrades and defenses"
        },
        {
            text = "Contracts & Jobs",
            icon = "📋",
            key = "c",
            action = "show_contracts",
            description = "View available contracts and progress"
        },
        {
            text = "Performance Stats", 
            icon = "📊",
            key = "p",
            action = "show_stats",
            description = "View game statistics and performance metrics"
        },
        {
            text = "Game Settings",
            icon = "⚙️",
            key = "o",
            action = "show_settings",
            description = "Adjust game settings and preferences"
        },
        {
            text = "Help & Controls",
            icon = "❓",
            key = "h",
            action = "show_help",
            description = "View controls and game help information"
        }
    }
    
    -- Current panel/view state
    self.currentView = "dashboard"
    self.viewData = {}
    
    return self
end

function QuickMenu:toggle()
    local currentTime = love.timer.getTime()
    
    -- Prevent rapid toggling
    if currentTime - self.lastToggleTime < 0.2 then
        return
    end
    
    self.visible = not self.visible
    self.lastToggleTime = currentTime
    
    if self.visible then
        self.selectedIndex = 1
        print("🎮 Quick Menu: Opened")
    else
        print("🎮 Quick Menu: Closed")
    end
end

function QuickMenu:handleKeyPress(key)
    if key == "escape" or key == "q" then
        if self.visible then
            self.visible = false
            return true
        elseif self.currentView ~= "dashboard" then
            self.currentView = "dashboard"
            return true
        end
    end
    
    -- Toggle menu with Tab key
    if key == "tab" then
        self:toggle()
        return true
    end
    
    -- Handle menu navigation when visible
    if self.visible then
        if key == "up" or key == "w" then
            self.selectedIndex = math.max(1, self.selectedIndex - 1)
            return true
        elseif key == "down" or key == "s" then
            self.selectedIndex = math.min(#self.menuItems, self.selectedIndex + 1)
            return true
        elseif key == "return" or key == "space" then
            self:executeAction(self.menuItems[self.selectedIndex].action)
            return true
        end
    end
    
    -- Handle direct shortcuts (even when menu not visible)
    for _, item in ipairs(self.menuItems) do
        if key == item.key then
            self:executeAction(item.action)
            return true
        end
    end
    
    return false
end

function QuickMenu:handleMousePress(x, y, button)
    if self.visible then
        -- Check if click is on menu
        local menuBounds = self:getMenuBounds()
        if UIHelpers.pointInRect(x, y, menuBounds.x, menuBounds.y, menuBounds.width, menuBounds.height) then
            -- Calculate which item was clicked
            local itemHeight = 30
            local itemIndex = math.floor((y - menuBounds.y - 10) / itemHeight) + 1
            
            if itemIndex >= 1 and itemIndex <= #self.menuItems then
                self.selectedIndex = itemIndex
                self:executeAction(self.menuItems[itemIndex].action)
            end
            return true
        else
            -- Click outside menu - close it
            self.visible = false
            return true
        end
    end
    
    return false
end

function QuickMenu:executeAction(action)
    print("🎮 Quick Menu: Executing action - " .. action)
    
    if action == "toggle_auto_contracts" then
        -- This would integrate with the main game's auto-contract system
        if self.eventBus then
            self.eventBus:emit("toggle_auto_contracts")
        end
        self.visible = false
        
    elseif action == "show_resources" then
        self.currentView = "resources"
        self:updateResourcesView()
        self.visible = false
        
    elseif action == "show_locations" then
        self.currentView = "locations"
        self:updateLocationsView()
        self.visible = false
        
    elseif action == "show_upgrades" then
        self.currentView = "upgrades"
        self:updateUpgradesView()
        self.visible = false
        
    elseif action == "show_contracts" then
        self.currentView = "contracts"
        self:updateContractsView()
        self.visible = false
        
    elseif action == "show_stats" then
        self.currentView = "stats"
        self:updateStatsView()
        self.visible = false
        
    elseif action == "show_settings" then
        self.currentView = "settings"
        self:updateSettingsView()
        self.visible = false
        
    elseif action == "show_help" then
        self.currentView = "help"
        self:updateHelpView()
        self.visible = false
    end
end

function QuickMenu:updateResourcesView()
    self.viewData.resources = {}
    
    if self.resourceManager then
        local resources = self.resourceManager:getAllResources()
        for resourceType, amount in pairs(resources) do
            table.insert(self.viewData.resources, {
                type = resourceType,
                amount = amount,
                icon = self:getResourceIcon(resourceType)
            })
        end
    else
        -- Mock data for testing
        self.viewData.resources = {
            {type = "money", amount = 5420, icon = "💰"},
            {type = "reputation", amount = 185, icon = "⭐"},
            {type = "missionTokens", amount = 12, icon = "🎫"}
        }
    end
end

function QuickMenu:updateLocationsView()
    self.viewData.locations = {
        current = {
            building = "home_office",
            floor = "main", 
            room = "my_office"
        },
        available = {
            {name = "🏠 Home Office", id = "home_office", unlocked = true},
            {name = "🏢 Corporate Office", id = "corporate_office", unlocked = false}
        }
    }
end

function QuickMenu:updateContractsView()
    self.viewData.contracts = {
        active = 2,
        completed = 15,
        available = 3,
        autoEnabled = false -- This would come from game state
    }
end

function QuickMenu:updateStatsView()
    self.viewData.stats = {
        uptime = love.timer.getTime(),
        moneyGenerated = 1250,
        contractsCompleted = 15,
        threatsBlocked = 8,
        currentRate = "$45/sec"
    }
end

function QuickMenu:updateUpgradesView()
    self.viewData.upgrades = {
        available = 5,
        owned = 3,
        nextUpgrade = "Firewall Level 2 ($2500)"
    }
end

function QuickMenu:updateSettingsView()
    self.viewData.settings = {
        autoSave = true,
        soundEnabled = true,
        theme = "cybersecurity",
        difficulty = "normal"
    }
end

function QuickMenu:updateHelpView()
    self.viewData.help = {
        version = "v1.0.0",
        controls = {
            {"Tab", "Toggle Quick Menu"},
            {"ESC", "Close Menu/Return to Dashboard"},
            {"Space", "Toggle Auto-Contracts"},
            {"R", "View Resources"},
            {"L", "Location Navigator"},
            {"C", "Contracts & Jobs"},
            {"U", "Upgrade Security"},
            {"P", "Performance Stats"},
            {"H", "Help & Controls"}
        }
    }
end

function QuickMenu:getResourceIcon(resourceType)
    local icons = {
        money = "💰",
        reputation = "⭐",
        missionTokens = "🎫",
        energy = "⚡",
        influence = "🏛️",
        data = "💾"
    }
    return icons[resourceType] or "📊"
end

function QuickMenu:getMenuBounds()
    local width, height = love.graphics.getDimensions()
    local menuWidth = 280
    local menuHeight = #self.menuItems * 30 + 20
    
    return {
        x = width - menuWidth - 20,
        y = 20,
        width = menuWidth,
        height = menuHeight
    }
end

function QuickMenu:draw()
    -- Draw current view
    self:drawCurrentView()
    
    -- Draw quick menu if visible
    if self.visible then
        self:drawMenu()
    end
    
    -- Draw menu toggle hint
    self:drawToggleHint()
end

function QuickMenu:drawCurrentView()
    local width, height = love.graphics.getDimensions()
    
    if self.currentView == "resources" then
        self:drawResourcesPanel()
    elseif self.currentView == "locations" then
        self:drawLocationsPanel()
    elseif self.currentView == "contracts" then
        self:drawContractsPanel()
    elseif self.currentView == "upgrades" then
        self:drawUpgradesPanel()
    elseif self.currentView == "stats" then
        self:drawStatsPanel()
    elseif self.currentView == "settings" then
        self:drawSettingsPanel()
    elseif self.currentView == "help" then
        self:drawHelpPanel()
    end
end

function QuickMenu:drawResourcesPanel()
    local width, height = love.graphics.getDimensions()
    local panelWidth = 350
    local panelHeight = 200
    local x = 20
    local y = height - panelHeight - 20
    
    -- Panel background
    love.graphics.setColor(UIHelpers.colors.backgroundLight)
    love.graphics.rectangle("fill", x, y, panelWidth, panelHeight)
    
    -- Panel border
    love.graphics.setColor(UIHelpers.colors.border)
    love.graphics.rectangle("line", x, y, panelWidth, panelHeight)
    
    -- Title
    love.graphics.setColor(UIHelpers.colors.accent)
    love.graphics.print("💰 Resources", x + 15, y + 15)
    
    -- Resource list
    love.graphics.setColor(UIHelpers.colors.text)
    local startY = y + 45
    
    if self.viewData.resources then
        for i, resource in ipairs(self.viewData.resources) do
            local resourceY = startY + (i - 1) * 25
            love.graphics.print(resource.icon .. " " .. resource.type .. ": " .. resource.amount, 
                              x + 15, resourceY)
        end
    end
end

function QuickMenu:drawLocationsPanel()
    local width, height = love.graphics.getDimensions()
    local panelWidth = 400
    local panelHeight = 250
    local x = 20
    local y = 20
    
    -- Panel background
    love.graphics.setColor(UIHelpers.colors.backgroundLight)
    love.graphics.rectangle("fill", x, y, panelWidth, panelHeight)
    
    -- Panel border
    love.graphics.setColor(UIHelpers.colors.border)
    love.graphics.rectangle("line", x, y, panelWidth, panelHeight)
    
    -- Title
    love.graphics.setColor(UIHelpers.colors.accent)
    love.graphics.print("🏢 Location Navigator", x + 15, y + 15)
    
    -- Current location
    love.graphics.setColor(UIHelpers.colors.text)
    if self.viewData.locations and self.viewData.locations.current then
        local current = self.viewData.locations.current
        love.graphics.print("Current: " .. current.building .. " > " .. current.floor .. " > " .. current.room,
                          x + 15, y + 45)
    end
    
    -- Available locations
    love.graphics.setColor(UIHelpers.colors.textDim)
    love.graphics.print("Available Buildings:", x + 15, y + 75)
    
    if self.viewData.locations and self.viewData.locations.available then
        for i, location in ipairs(self.viewData.locations.available) do
            local locY = y + 95 + (i - 1) * 25
            local color = location.unlocked and UIHelpers.colors.text or UIHelpers.colors.textDim
            love.graphics.setColor(color)
            local status = location.unlocked and "✅" or "🔒"
            love.graphics.print(status .. " " .. location.name, x + 25, locY)
        end
    end
end

function QuickMenu:drawContractsPanel()
    local width, height = love.graphics.getDimensions()
    local panelWidth = 350
    local panelHeight = 180
    local x = width - panelWidth - 20
    local y = 20
    
    -- Panel background
    love.graphics.setColor(UIHelpers.colors.backgroundLight)
    love.graphics.rectangle("fill", x, y, panelWidth, panelHeight)
    
    -- Panel border
    love.graphics.setColor(UIHelpers.colors.border)
    love.graphics.rectangle("line", x, y, panelWidth, panelHeight)
    
    -- Title
    love.graphics.setColor(UIHelpers.colors.accent)
    love.graphics.print("📋 Contracts & Jobs", x + 15, y + 15)
    
    -- Contract stats
    love.graphics.setColor(UIHelpers.colors.text)
    if self.viewData.contracts then
        local data = self.viewData.contracts
        love.graphics.print("Active Contracts: " .. data.active, x + 15, y + 45)
        love.graphics.print("Completed: " .. data.completed, x + 15, y + 65)
        love.graphics.print("Available: " .. data.available, x + 15, y + 85)
        
        local autoStatus = data.autoEnabled and "ON" or "OFF"
        local autoColor = data.autoEnabled and UIHelpers.colors.success or UIHelpers.colors.textDim
        love.graphics.setColor(autoColor)
        love.graphics.print("Auto-Contracts: " .. autoStatus, x + 15, y + 110)
    end
end

function QuickMenu:drawStatsPanel()
    local width, height = love.graphics.getDimensions()
    local panelWidth = 400
    local panelHeight = 200
    local x = (width - panelWidth) / 2
    local y = (height - panelHeight) / 2
    
    -- Panel background
    love.graphics.setColor(UIHelpers.colors.backgroundLight)
    love.graphics.rectangle("fill", x, y, panelWidth, panelHeight)
    
    -- Panel border
    love.graphics.setColor(UIHelpers.colors.border)
    love.graphics.rectangle("line", x, y, panelWidth, panelHeight)
    
    -- Title
    love.graphics.setColor(UIHelpers.colors.accent)
    love.graphics.print("📊 Performance Statistics", x + 15, y + 15)
    
    -- Stats
    love.graphics.setColor(UIHelpers.colors.text)
    if self.viewData.stats then
        local data = self.viewData.stats
        love.graphics.print("Session Uptime: " .. string.format("%.0f", data.uptime) .. "s", x + 15, y + 45)
        love.graphics.print("Money Generated: $" .. data.moneyGenerated, x + 15, y + 65)
        love.graphics.print("Contracts Completed: " .. data.contractsCompleted, x + 15, y + 85)
        love.graphics.print("Threats Blocked: " .. data.threatsBlocked, x + 15, y + 105)
        love.graphics.print("Current Rate: " .. data.currentRate, x + 15, y + 125)
    end
end

function QuickMenu:drawUpgradesPanel()
    local width, height = love.graphics.getDimensions()
    local panelWidth = 350
    local panelHeight = 150
    local x = width - panelWidth - 20
    local y = height - panelHeight - 20
    
    -- Panel background
    love.graphics.setColor(UIHelpers.colors.backgroundLight)
    love.graphics.rectangle("fill", x, y, panelWidth, panelHeight)
    
    -- Panel border
    love.graphics.setColor(UIHelpers.colors.border)
    love.graphics.rectangle("line", x, y, panelWidth, panelHeight)
    
    -- Title
    love.graphics.setColor(UIHelpers.colors.accent)
    love.graphics.print("🛡️ Security Upgrades", x + 15, y + 15)
    
    -- Upgrade info
    love.graphics.setColor(UIHelpers.colors.text)
    if self.viewData.upgrades then
        local data = self.viewData.upgrades
        love.graphics.print("Available: " .. data.available, x + 15, y + 45)
        love.graphics.print("Owned: " .. data.owned, x + 15, y + 65)
        love.graphics.print("Next: " .. data.nextUpgrade, x + 15, y + 85)
    end
end

function QuickMenu:drawSettingsPanel()
    -- Implementation for settings panel
    local width, height = love.graphics.getDimensions()
    love.graphics.setColor(UIHelpers.colors.text)
    love.graphics.print("⚙️ Settings Panel (Coming Soon)", 50, 50)
end

function QuickMenu:drawHelpPanel()
    local width, height = love.graphics.getDimensions()
    local panelWidth = 500
    local panelHeight = 400
    local x = (width - panelWidth) / 2
    local y = (height - panelHeight) / 2
    
    -- Panel background
    love.graphics.setColor(UIHelpers.colors.backgroundLight)
    love.graphics.rectangle("fill", x, y, panelWidth, panelHeight)
    
    -- Panel border
    love.graphics.setColor(UIHelpers.colors.border)
    love.graphics.rectangle("line", x, y, panelWidth, panelHeight)
    
    -- Title
    love.graphics.setColor(UIHelpers.colors.accent)
    love.graphics.print("❓ Help & Controls", x + 15, y + 15)
    
    -- Controls list
    love.graphics.setColor(UIHelpers.colors.text)
    if self.viewData.help and self.viewData.help.controls then
        love.graphics.print("Keyboard Controls:", x + 15, y + 50)
        
        for i, control in ipairs(self.viewData.help.controls) do
            local controlY = y + 75 + (i - 1) * 20
            love.graphics.setColor(UIHelpers.colors.warning)
            love.graphics.print(control[1], x + 25, controlY)
            love.graphics.setColor(UIHelpers.colors.text)
            love.graphics.print("- " .. control[2], x + 80, controlY)
        end
    end
    
    -- Version info
    love.graphics.setColor(UIHelpers.colors.textDim)
    love.graphics.print("Cyber Empire Command " .. (self.viewData.help and self.viewData.help.version or ""), 
                      x + 15, y + panelHeight - 30)
end

function QuickMenu:drawMenu()
    local bounds = self:getMenuBounds()
    
    -- Prepare menu items for display
    local menuItems = {}
    for i, item in ipairs(self.menuItems) do
        table.insert(menuItems, {
            text = item.text,
            icon = item.icon,
            key = item.key,
            selected = (i == self.selectedIndex)
        })
    end
    
    UIHelpers.drawQuickMenu(menuItems, self.selectedIndex, {
        x = bounds.x,
        y = bounds.y,
        width = bounds.width
    })
end

function QuickMenu:drawToggleHint()
    if not self.visible then
        local width, height = love.graphics.getDimensions()
        love.graphics.setColor(UIHelpers.colors.textDim)
        love.graphics.print("Press [Tab] for Quick Menu", width - 200, height - 25)
    end
end

return QuickMenu