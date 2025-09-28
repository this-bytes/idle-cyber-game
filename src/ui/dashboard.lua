local Dashboard = {}
Dashboard.__index = Dashboard

function Dashboard.new(systems)
    local self = setmetatable({}, Dashboard)
    self.systems = systems or {}
    return self
end

function Dashboard:enter()
    -- Initialize or refresh dashboard data
    if self.systems and self.systems.uiManager then
        self.systems.uiManager:clearSelectables()
        
        local Selectable = require("src.ui.selectable")
        local screenWidth = self.systems.uiManager.screenWidth or 1024
        local screenHeight = self.systems.uiManager.screenHeight or 768
        
        -- Create selectables for different game modes/views
        local buttonWidth = 200
        local buttonHeight = 50
        local startX = (screenWidth - buttonWidth) / 2
        local startY = 150
        local spacing = 70
        
        -- Idle Mode button
        local idleBtn = Selectable.new("idle_mode", startX, startY, buttonWidth, buttonHeight, "🏢 Start Idle Mode", function() 
            if self.systems and self.systems.eventBus then
                self.systems.eventBus:publish("switch_mode", {mode = "idle"})
            end
        end)
        self.systems.uiManager:registerSelectable(idleBtn)
        
        -- Admin Mode button
        local adminBtn = Selectable.new("admin_mode", startX, startY + spacing, buttonWidth, buttonHeight, "🚨 Admin Mode", function() 
            if self.systems and self.systems.eventBus then
                self.systems.eventBus:publish("switch_mode", {mode = "admin"})
            end
        end)
        self.systems.uiManager:registerSelectable(adminBtn)
        
        -- Contracts button
        local contractsBtn = Selectable.new("contracts", startX, startY + spacing * 2, buttonWidth, buttonHeight, "📋 View Contracts", function() 
            if self.systems and self.systems.eventBus then
                self.systems.eventBus:publish("ui_action", {action = "open_contracts"})
            end
        end)
        self.systems.uiManager:registerSelectable(contractsBtn)
        
        -- Upgrades button
        local upgradesBtn = Selectable.new("upgrades", startX, startY + spacing * 3, buttonWidth, buttonHeight, "⬆️ Security Upgrades", function() 
            if self.systems and self.systems.eventBus then
                self.systems.eventBus:publish("ui_action", {action = "open_upgrades"})
            end
        end)
        self.systems.uiManager:registerSelectable(upgradesBtn)
        
        -- Stats button
        local statsBtn = Selectable.new("stats", startX, startY + spacing * 4, buttonWidth, buttonHeight, "📊 SOC Statistics", function() 
            if self.systems and self.systems.eventBus then
                self.systems.eventBus:publish("ui_action", {action = "open_stats"})
            end
        end)
        self.systems.uiManager:registerSelectable(statsBtn)
        
        -- Set initial focus
        if #self.systems.uiManager.selectables > 0 then
            self.systems.uiManager.selectables[1].focused = true
            self.systems.uiManager.focusIndex = 1
        end
    end
end

function Dashboard:update(dt)
    -- Dashboard-specific updates
end

function Dashboard:draw()
    -- Drawing handled centrally by UIManager for now
end

return Dashboard
