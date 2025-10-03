-- Example integration of Incident and Specialist Management System
-- This file demonstrates how to integrate the system into the main game

-- Example: Integration into an idle game main file

local IncidentSpecialistSystem = require("src.systems.incident_specialist_system")
local EventBus = require("src.utils.event_bus")
local ResourceManager = require("src.systems.resource_manager")

-- Mock game object for demonstration
local Game = {}
Game.__index = Game

function Game.new()
    local self = setmetatable({}, Game)
    
    -- Initialize core systems
    self.eventBus = EventBus.new()
    self.resourceManager = ResourceManager.new(self.eventBus)
    
    -- Initialize incident/specialist system
    self.incidentSystem = IncidentSpecialistSystem.new(self.eventBus, self.resourceManager)
    
    -- Subscribe to system events for UI updates
    self:setupEventHandlers()
    
    return self
end

function Game:initialize()
    print("🎮 Initializing game...")
    
    -- Initialize incident system (loads JSON data)
    self.incidentSystem:initialize()
    
    print("✅ Game ready!")
end

function Game:setupEventHandlers()
    -- Handle incident auto-resolution
    self.eventBus:subscribe("incident_auto_resolved", function(data)
        print(string.format("🔧 Auto-resolved: %s", data.incident.name))
        -- Update UI notification
    end)
    
    -- Handle incident escalation
    self.eventBus:subscribe("incident_escalated", function(data)
        print(string.format("⚠️  ALERT: %s requires attention!", data.incident.name))
        -- Show alert notification
        -- Play alert sound
    end)
    
    -- Handle incident assignment
    self.eventBus:subscribe("incident_auto_assigned", function(data)
        print(string.format("👤 %s is handling %s", 
            data.specialist.name, 
            data.incident.name))
        -- Update UI to show specialist is busy
    end)
    
    -- Handle incident resolution
    self.eventBus:subscribe("incident_resolved", function(data)
        print(string.format("✅ %s completed by %s", 
            data.incident.name, 
            data.specialist.name))
        print(string.format("   Rewards: $%.0f, %.0f Rep, %.0f XP, %.0f Tokens",
            data.reward.money,
            data.reward.reputation,
            data.reward.xp,
            data.reward.missionTokens))
        -- Show completion notification
        -- Update statistics
    end)
    
    -- Handle specialist availability
    self.eventBus:subscribe("specialist_available", function(data)
        print(string.format("✅ %s is now available", data.specialist.name))
        -- Update UI to show specialist is available
    end)
    
    -- Handle specialist unlocking
    self.eventBus:subscribe("specialist_unlocked", function(data)
        print(string.format("🎉 New specialist unlocked: %s!", data.name))
        -- Show unlock notification
        -- Play unlock sound
    end)
end

function Game:update(dt)
    -- Update incident system (handles all core loop logic)
    self.incidentSystem:update(dt)
    
    -- Other game systems would update here...
end

function Game:draw()
    -- Get statistics for UI display
    local stats = self.incidentSystem:getStatistics()
    local state = self.incidentSystem:getState()
    
    -- Draw resource display
    love.graphics.print(string.format("💰 Money: $%.0f", self.resourceManager:getResource("money") or 0), 10, 10)
    love.graphics.print(string.format("🏆 Rep: %.0f", self.resourceManager:getResource("reputation") or 0), 10, 30)
    love.graphics.print(string.format("📚 XP: %.0f", self.resourceManager:getResource("xp") or 0), 10, 50)
    love.graphics.print(string.format("🎫 Tokens: %.0f", self.resourceManager:getResource("missionTokens") or 0), 10, 70)
    
    -- Draw specialist roster
    love.graphics.print("👥 Specialists:", 10, 110)
    local y = 130
    for _, specialist in ipairs(state.Specialists) do
        local status = specialist.is_busy and "BUSY" or "Available"
        local color = specialist.is_busy and {1, 0.5, 0.5} or {0.5, 1, 0.5}
        
        love.graphics.setColor(color)
        love.graphics.print(string.format("  [%d] %s - Lv%d (%s)", 
            specialist.id, 
            specialist.name, 
            specialist.Level,
            status), 10, y)
        love.graphics.setColor(1, 1, 1)
        y = y + 20
    end
    
    -- Draw incident queue
    if #state.IncidentsQueue > 0 then
        love.graphics.print("🚨 Active Incidents:", 400, 110)
        local y = 130
        for _, incident in ipairs(state.IncidentsQueue) do
            local statusColor = {1, 1, 1}
            if incident.status == "Pending" then
                statusColor = {1, 1, 0}
            elseif incident.status == "AutoAssigned" then
                statusColor = {0, 1, 1}
            end
            
            love.graphics.setColor(statusColor)
            love.graphics.print(string.format("  [%d] %s - %s", 
                incident.id,
                incident.name,
                incident.status), 400, y)
            
            if incident.assignedSpecialistId then
                love.graphics.print(string.format("    Time: %.0fs", 
                    incident.resolutionTimeRemaining), 400, y + 15)
            end
            
            love.graphics.setColor(1, 1, 1)
            y = y + 35
        end
    end
    
    -- Draw statistics
    love.graphics.print(string.format("📊 Stats: %d/%d specialists available, %d pending incidents",
        stats.availableSpecialists,
        stats.activeSpecialists,
        stats.pendingIncidents), 10, 550)
end

-- Example: Player actions

function Game:tryUnlockSpecialist(specialistId)
    local state = self.incidentSystem:getState()
    local template = state.SpecialistTemplates[specialistId]
    
    if not template then
        print("❌ Unknown specialist: " .. specialistId)
        return false
    end
    
    -- Check if player can afford
    local cost = template.cost or {}
    
    local canAfford = true
    for resource, amount in pairs(cost) do
        local current = self.resourceManager:getResource(resource) or 0
        if current < amount then
            canAfford = false
            print(string.format("❌ Not enough %s (need %d, have %.0f)", 
                resource, amount, current))
            break
        end
    end
    
    if not canAfford then
        return false
    end
    
    -- Spend resources
    for resource, amount in pairs(cost) do
        self.resourceManager:spendResource(resource, amount)
    end
    
    -- Unlock specialist
    return self.incidentSystem:unlockSpecialist(specialistId)
end

function Game:adjustAutoResolveStat(newValue)
    -- This could be tied to facility upgrades
    local state = self.incidentSystem:getState()
    state.GlobalAutoResolveStat = newValue
    print(string.format("🔧 Auto-resolve threshold set to %d", newValue))
end

-- Example usage demonstration
local function demonstrateIntegration()
    print("\n" .. string.rep("=", 80))
    print("INCIDENT SYSTEM INTEGRATION EXAMPLE")
    print(string.rep("=", 80) .. "\n")
    
    local game = Game.new()
    game:initialize()
    
    print("\n🎮 Running game simulation...")
    
    -- Simulate game loop
    for i = 1, 10 do
        print(string.format("\n--- Frame %d (%.1f seconds) ---", i, i * 0.5))
        game:update(0.5)
        
        -- Example: Try to unlock a specialist after 5 seconds
        if i == 10 then
            print("\n💡 Player attempts to unlock new specialist...")
            game:tryUnlockSpecialist("test_specialist")
        end
    end
    
    -- Show final statistics
    local stats = game.incidentSystem:getStatistics()
    print("\n" .. string.rep("=", 80))
    print("FINAL STATISTICS")
    print(string.rep("=", 80))
    print(string.format("Active Specialists: %d", stats.activeSpecialists))
    print(string.format("Available: %d, Busy: %d", stats.availableSpecialists, stats.busySpecialists))
    print(string.format("Pending Incidents: %d", stats.pendingIncidents))
    print(string.format("Assigned Incidents: %d", stats.assignedIncidents))
    
    print(string.format("\n💰 Resources earned:"))
    print(string.format("  Money: $%.0f", game.resourceManager:getResource("money") or 0))
    print(string.format("  Reputation: %.0f", game.resourceManager:getResource("reputation") or 0))
    print(string.format("  XP: %.0f", game.resourceManager:getResource("xp") or 0))
    print(string.format("  Mission Tokens: %.0f", game.resourceManager:getResource("missionTokens") or 0))
    
    print("\n" .. string.rep("=", 80))
    print("INTEGRATION EXAMPLE COMPLETE ✨")
    print(string.rep("=", 80) .. "\n")
end

-- Run demonstration if executed directly
if not love then
    -- Mock love for standalone testing
    love = {
        filesystem = {
            getInfo = function(path)
                local file = io.open(path, "r")
                if file then
                    file:close()
                    return {type = "file"}
                end
                return nil
            end,
            read = function(path)
                local file = io.open(path, "r")
                if file then
                    local content = file:read("*a")
                    file:close()
                    return content
                end
                return nil
            end
        },
        graphics = {
            print = function(text, x, y)
                -- Stub for non-LOVE environment
            end,
            setColor = function(r, g, b, a)
                -- Stub
            end
        }
    }
    
    -- Set package path
    package.path = package.path .. ";./?.lua;./?/init.lua"
    
    -- Run the demonstration
    demonstrateIntegration()
end

return Game
