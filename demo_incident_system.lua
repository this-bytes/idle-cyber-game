#!/usr/bin/env lua
-- Prototype/Demo for Incident and Specialist Management System
-- Demonstrates the core loop in action with visual output

-- Mock the love.filesystem functions for standalone testing
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
    }
}

-- Set package path
package.path = package.path .. ";./?.lua;./?/init.lua"

local IncidentSpecialistSystem = require("src.systems.incident_specialist_system")

-- Mock EventBus
local function createMockEventBus()
    return {
        publish = function(self, event, data)
            -- Silent for demo
        end,
        subscribe = function(self, event, callback)
            -- Not needed
        end
    }
end

-- Mock ResourceManager with display
local function createMockResourceManager()
    local resources = {
        money = 0,
        reputation = 0,
        xp = 0,
        missionTokens = 0
    }
    
    return {
        addResource = function(self, resource, amount)
            resources[resource] = (resources[resource] or 0) + amount
        end,
        getResource = function(self, resource)
            return resources[resource] or 0
        end,
        getResources = function(self)
            return resources
        end
    }
end

-- Display statistics
local function displayStatistics(system, resourceManager, iteration)
    local stats = system:getStatistics()
    local resources = resourceManager:getResources()
    
    print(string.rep("─", 80))
    print(string.format("📊 ITERATION %d STATUS", iteration))
    print(string.rep("─", 80))
    print(string.format("💰 Resources: $%.0f | 🏆 Rep: %.0f | 📚 XP: %.0f | 🎫 Tokens: %.0f",
        resources.money, resources.reputation, resources.xp, resources.missionTokens))
    print(string.format("👥 Specialists: %d active (%d available, %d busy)",
        stats.activeSpecialists, stats.availableSpecialists, stats.busySpecialists))
    print(string.format("🚨 Incidents: %d pending, %d assigned",
        stats.pendingIncidents, stats.assignedIncidents))
    print(string.rep("─", 80))
end

-- Display specialist details
local function displaySpecialists(system)
    local state = system:getState()
    
    print("\n👥 SPECIALIST ROSTER:")
    print(string.rep("─", 80))
    for _, specialist in ipairs(state.Specialists) do
        local status = "Available"
        if specialist.is_busy then
            status = "🔴 Busy"
        elseif specialist.cooldown_timer > 0 then
            status = string.format("⏳ Cooldown (%.1fs)", specialist.cooldown_timer)
        else
            status = "✅ Available"
        end
        
        print(string.format("  [%d] %s - Level %d (XP: %d) - Defense: %.1f - %s",
            specialist.id, specialist.name, specialist.Level, specialist.XP, 
            specialist.defense, status))
    end
    print(string.rep("─", 80))
end

-- Display incident queue
local function displayIncidentQueue(system)
    local state = system:getState()
    
    if #state.IncidentsQueue > 0 then
        print("\n🚨 ACTIVE INCIDENTS:")
        print(string.rep("─", 80))
        for _, incident in ipairs(state.IncidentsQueue) do
            local statusIcon = "⏸️"
            if incident.status == "AutoAssigned" then
                statusIcon = "🔄"
            elseif incident.status == "ManualAssigned" then
                statusIcon = "👤"
            elseif incident.status == "Resolved" then
                statusIcon = "✅"
            end
            
            local assignedTo = ""
            if incident.assignedSpecialistId then
                local specialist = system:getSpecialistById(incident.assignedSpecialistId)
                if specialist then
                    assignedTo = string.format(" → %s (%.0fs remaining)", 
                        specialist.name, incident.resolutionTimeRemaining)
                end
            end
            
            print(string.format("  %s [%d] %s (Severity: %d)%s",
                statusIcon, incident.id, incident.name, 
                incident.trait_value_needed, assignedTo))
        end
        print(string.rep("─", 80))
    end
end

-- Main demo
local function runDemo()
    print("\n" .. string.rep("=", 80))
    print("INCIDENT AND SPECIALIST MANAGEMENT SYSTEM - PROTOTYPE DEMO")
    print(string.rep("=", 80))
    
    local eventBus = createMockEventBus()
    local resourceManager = createMockResourceManager()
    
    local system = IncidentSpecialistSystem.new(eventBus, resourceManager)
    system:initialize()
    
    print("\n✅ System initialized successfully!")
    
    displaySpecialists(system)
    
    -- Simulate game loop
    print("\n🎮 SIMULATING GAME LOOP (30 seconds of gameplay)")
    print("   Each iteration = 2 seconds of game time\n")
    
    local state = system:getState()
    
    -- Force some incidents to generate by manipulating timer
    for iteration = 1, 15 do
        -- Force incident generation occasionally
        if iteration % 3 == 0 then
            state.IncidentTimer = 0.1
        end
        
        -- Update system (2 seconds per iteration)
        system:update(2.0)
        
        -- Display status every few iterations
        if iteration % 2 == 0 then
            displayStatistics(system, resourceManager, iteration)
            displaySpecialists(system)
            displayIncidentQueue(system)
            print("\n⏳ Advancing time...\n")
        end
        
        -- Small delay for readability
        os.execute("sleep 0.5")
    end
    
    -- Final statistics
    print("\n" .. string.rep("=", 80))
    print("FINAL RESULTS")
    print(string.rep("=", 80))
    displayStatistics(system, resourceManager, 15)
    displaySpecialists(system)
    displayIncidentQueue(system)
    
    local resources = resourceManager:getResources()
    print("\n💎 SESSION SUMMARY:")
    print(string.format("   Total earnings: $%.0f", resources.money))
    print(string.format("   Reputation gained: %.0f", resources.reputation))
    print(string.format("   Total XP earned: %.0f", resources.xp))
    print(string.format("   Mission Tokens collected: %.0f", resources.missionTokens))
    
    print("\n" .. string.rep("=", 80))
    print("DEMO COMPLETE ✨")
    print(string.rep("=", 80) .. "\n")
end

-- Run the demo
runDemo()
