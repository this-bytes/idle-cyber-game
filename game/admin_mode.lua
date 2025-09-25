-- "The Admin's Watch" Real-Time Operations Mode
-- Network Operations Center for corporate cybersecurity management

local adminMode = {}
local resources = require("resources")
local format = require("format")

-- Admin mode state
local adminState = {
    isActive = false,
    
    -- Corporate client management
    currentClient = {
        name = "TechCorp Industries",
        sector = "Technology",
        stockPrice = 100.00,
        uptime = 99.9,
        budget = 50000,  -- Daily operational budget
        reputation = 75,
    },
    
    -- Real-time resources
    operationalResources = {
        cpuCycles = 100,        -- Available CPU cycles (0-100)
        bandwidth = 1000,       -- Network bandwidth (Mbps)
        personnelHours = 40,    -- Security team availability
        emergencyFunds = 10000, -- Emergency response budget
    },
    
    -- Network topology (simplified for Phase 2)
    networkNodes = {
        webServer = { health = 100, threats = 0, secured = true },
        database = { health = 100, threats = 0, secured = true },
        userDesktops = { health = 90, threats = 1, secured = false },
        iotDevices = { health = 80, threats = 2, secured = false },
    },
    
    -- Active incidents requiring response
    activeIncidents = {},
    
    -- Performance metrics
    metrics = {
        threatsBlocked = 0,
        uptime = 100.0,
        budget_spent = 0,
        client_satisfaction = 100,
    },
    
    -- UI state
    ui = {
        selectedNode = nil,
        incidentPanel = true,
        networkMap = true,
        resourcePanel = true,
    }
}

-- Initialize Admin's Watch mode
function adminMode.init()
    print("🏢 The Admin's Watch mode initialized")
    print("   Client: " .. adminState.currentClient.name)
    print("   Budget: $" .. format.currency(adminState.currentClient.budget))
    print("   Stock Price: $" .. string.format("%.2f", adminState.currentClient.stockPrice))
    
    -- Schedule first incident in 30 seconds
    adminMode.scheduleIncident(30)
end

-- Toggle Admin's Watch mode
function adminMode.toggle()
    adminState.isActive = not adminState.isActive
    
    if adminState.isActive then
        print("🎯 Entering The Admin's Watch - Real-Time Operations")
        print("   You are now managing " .. adminState.currentClient.name)
        print("   Budget: $" .. format.currency(adminState.currentClient.budget))
    else
        print("🏠 Returning to Idle Empire Building mode")
    end
    
    return adminState.isActive
end

-- Check if Admin's Watch mode is active
function adminMode.isActive()
    return adminState.isActive
end

-- Update Admin's Watch mode (called every frame)
function adminMode.update(dt)
    if not adminState.isActive then
        return
    end
    
    -- Update resource regeneration
    adminMode.updateResources(dt)
    
    -- Update active incidents
    adminMode.updateIncidents(dt)
    
    -- Update network health
    adminMode.updateNetworkHealth(dt)
    
    -- Update client metrics
    adminMode.updateClientMetrics(dt)
end

-- Update operational resources
function adminMode.updateResources(dt)
    -- CPU cycles regenerate slowly
    if adminState.operationalResources.cpuCycles < 100 then
        adminState.operationalResources.cpuCycles = math.min(100, 
            adminState.operationalResources.cpuCycles + dt * 5) -- 5% per second
    end
    
    -- Personnel hours regenerate over time (simulating shift changes)
    if adminState.operationalResources.personnelHours < 40 then
        adminState.operationalResources.personnelHours = math.min(40,
            adminState.operationalResources.personnelHours + dt * 0.5) -- 30 minutes per hour
    end
    
    -- Bandwidth is generally stable unless under attack
    -- Emergency funds regenerate from daily budget
end

-- Update active incidents
function adminMode.updateIncidents(dt)
    for i = #adminState.activeIncidents, 1, -1 do
        local incident = adminState.activeIncidents[i]
        incident.timeRemaining = incident.timeRemaining - dt
        
        -- Incident escalates if not handled
        if incident.timeRemaining <= 0 then
            adminMode.escalateIncident(incident)
            table.remove(adminState.activeIncidents, i)
        end
    end
    
    -- Schedule new incidents randomly
    adminMode.scheduleRandomIncident(dt)
end

-- Update network health
function adminMode.updateNetworkHealth(dt)
    for nodeName, node in pairs(adminState.networkNodes) do
        -- Unsecured nodes slowly degrade
        if not node.secured and node.threats > 0 then
            node.health = math.max(0, node.health - dt * node.threats * 2)
        end
        
        -- Secured nodes slowly recover
        if node.secured and node.health < 100 then
            node.health = math.min(100, node.health + dt * 5)
        end
    end
end

-- Update client satisfaction and business metrics
function adminMode.updateClientMetrics(dt)
    local overallHealth = 0
    local nodeCount = 0
    
    for _, node in pairs(adminState.networkNodes) do
        overallHealth = overallHealth + node.health
        nodeCount = nodeCount + 1
    end
    
    adminState.metrics.uptime = overallHealth / nodeCount
    
    -- Client satisfaction based on uptime and incident response
    local targetSatisfaction = math.min(100, adminState.metrics.uptime)
    adminState.metrics.client_satisfaction = adminState.metrics.client_satisfaction + 
        (targetSatisfaction - adminState.metrics.client_satisfaction) * dt * 0.1
    
    -- Stock price fluctuates based on performance
    local targetStock = adminState.currentClient.stockPrice * (1 + (adminState.metrics.uptime - 95) * 0.001)
    adminState.currentClient.stockPrice = adminState.currentClient.stockPrice + 
        (targetStock - adminState.currentClient.stockPrice) * dt * 0.05
end

-- Schedule a new incident
function adminMode.scheduleIncident(delay)
    local incidentTypes = {
        {
            name = "🦠 Malware Detection",
            description = "Suspicious activity detected on user desktops",
            urgency = "medium",
            timeLimit = 120, -- 2 minutes
            target = "userDesktops",
            responses = {"isolate", "scan", "monitor"}
        },
        {
            name = "⚡ DDoS Attack",
            description = "Massive traffic spike overwhelming web servers",
            urgency = "high", 
            timeLimit = 60, -- 1 minute
            target = "webServer",
            responses = {"traffic_filter", "scale_up", "blackhole"}
        },
        {
            name = "🔍 Suspicious Login",
            description = "Multiple failed login attempts from unknown location",
            urgency = "low",
            timeLimit = 300, -- 5 minutes
            target = "database",
            responses = {"lockdown", "investigate", "notify"}
        },
        {
            name = "🏭 IoT Compromise",
            description = "Unusual network traffic from IoT devices",
            urgency = "medium",
            timeLimit = 180, -- 3 minutes  
            target = "iotDevices",
            responses = {"segment", "update", "replace"}
        }
    }
    
    -- Add incident after delay
    local function addIncident()
        local incident = incidentTypes[math.random(#incidentTypes)]
        incident.timeRemaining = incident.timeLimit
        incident.id = love.timer.getTime() -- Unique ID
        
        table.insert(adminState.activeIncidents, incident)
        
        print("🚨 NEW INCIDENT: " .. incident.name)
        print("   " .. incident.description)
        print("   ⏰ Time limit: " .. incident.timeLimit .. " seconds")
        
        -- Schedule next incident (random interval)
        adminMode.scheduleIncident(math.random(45, 120))
    end
    
    -- Simple timer implementation (would use proper timer in full LÖVE)
    local timer = delay
    local function checkTimer(dt)
        timer = timer - dt
        if timer <= 0 then
            addIncident()
        end
    end
    
    -- Store timer function for updates (simplified)
    adminState.nextIncidentTimer = delay
end

-- Schedule random incidents during gameplay
function adminMode.scheduleRandomIncident(dt)
    if not adminState.nextIncidentTimer then
        return
    end
    
    adminState.nextIncidentTimer = adminState.nextIncidentTimer - dt
    if adminState.nextIncidentTimer <= 0 then
        -- This will be properly implemented with the actual incident system
        adminState.nextIncidentTimer = math.random(45, 120) -- Next incident in 45-120 seconds
    end
end

-- Escalate unhandled incident
function adminMode.escalateIncident(incident)
    print("🔥 INCIDENT ESCALATED: " .. incident.name)
    print("   Client satisfaction decreased!")
    
    -- Damage client satisfaction
    adminState.metrics.client_satisfaction = math.max(0, 
        adminState.metrics.client_satisfaction - 25)
    
    -- Damage the target network node
    if adminState.networkNodes[incident.target] then
        adminState.networkNodes[incident.target].health = math.max(0,
            adminState.networkNodes[incident.target].health - 30)
        adminState.networkNodes[incident.target].threats = 
            adminState.networkNodes[incident.target].threats + 1
    end
    
    -- Stock price impact
    adminState.currentClient.stockPrice = adminState.currentClient.stockPrice * 0.95
end

-- Handle incident response
function adminMode.respondToIncident(incidentId, response)
    for i, incident in ipairs(adminState.activeIncidents) do
        if incident.id == incidentId then
            local success = adminMode.executeResponse(incident, response)
            
            if success then
                print("✅ Successfully handled: " .. incident.name)
                print("   Response: " .. response)
                
                -- Remove incident
                table.remove(adminState.activeIncidents, i)
                
                -- Improve metrics
                adminState.metrics.threatsBlocked = adminState.metrics.threatsBlocked + 1
                adminState.metrics.client_satisfaction = math.min(100,
                    adminState.metrics.client_satisfaction + 5)
                
                return true
            else
                print("❌ Response failed: " .. response)
                return false
            end
        end
    end
    
    return false
end

-- Execute incident response
function adminMode.executeResponse(incident, response)
    -- Check resource requirements
    local resourceCost = adminMode.getResponseCost(response)
    
    if not adminMode.canAffordResponse(resourceCost) then
        print("❌ Insufficient resources for " .. response)
        return false
    end
    
    -- Consume resources
    adminMode.consumeResources(resourceCost)
    
    -- Apply response effects
    if incident.target and adminState.networkNodes[incident.target] then
        local node = adminState.networkNodes[incident.target]
        
        if response == "isolate" or response == "segment" then
            node.secured = true
            node.threats = math.max(0, node.threats - 1)
        elseif response == "scan" then
            node.threats = 0  -- Full scan removes all threats
        elseif response == "lockdown" then
            node.secured = true
            -- Temporary security but impacts performance
        end
    end
    
    return true
end

-- Get resource cost for response
function adminMode.getResponseCost(response)
    local costs = {
        isolate = { cpuCycles = 20, personnelHours = 2, budget = 1000 },
        scan = { cpuCycles = 50, personnelHours = 1, budget = 500 },
        monitor = { cpuCycles = 10, personnelHours = 5, budget = 200 },
        traffic_filter = { bandwidth = 200, budget = 2000 },
        scale_up = { budget = 5000, emergencyFunds = 2000 },
        blackhole = { cpuCycles = 30, budget = 3000 },
        lockdown = { cpuCycles = 15, personnelHours = 3, budget = 800 },
        investigate = { personnelHours = 8, budget = 1500 },
        notify = { budget = 100 },
        segment = { cpuCycles = 25, budget = 1200 },
        update = { personnelHours = 4, budget = 800 },
        replace = { budget = 10000, emergencyFunds = 5000 }
    }
    
    return costs[response] or {}
end

-- Check if response is affordable
function adminMode.canAffordResponse(cost)
    local resources = adminState.operationalResources
    local client = adminState.currentClient
    
    if cost.cpuCycles and resources.cpuCycles < cost.cpuCycles then return false end
    if cost.bandwidth and resources.bandwidth < cost.bandwidth then return false end
    if cost.personnelHours and resources.personnelHours < cost.personnelHours then return false end
    if cost.budget and client.budget < cost.budget then return false end
    if cost.emergencyFunds and resources.emergencyFunds < cost.emergencyFunds then return false end
    
    return true
end

-- Consume resources for response
function adminMode.consumeResources(cost)
    local resources = adminState.operationalResources
    local client = adminState.currentClient
    
    if cost.cpuCycles then resources.cpuCycles = resources.cpuCycles - cost.cpuCycles end
    if cost.bandwidth then resources.bandwidth = resources.bandwidth - cost.bandwidth end
    if cost.personnelHours then resources.personnelHours = resources.personnelHours - cost.personnelHours end
    if cost.budget then 
        client.budget = client.budget - cost.budget
        adminState.metrics.budget_spent = adminState.metrics.budget_spent + cost.budget
    end
    if cost.emergencyFunds then resources.emergencyFunds = resources.emergencyFunds - cost.emergencyFunds end
end

-- Get current admin mode state for UI
function adminMode.getState()
    return {
        isActive = adminState.isActive,
        client = adminState.currentClient,
        resources = adminState.operationalResources,
        incidents = adminState.activeIncidents,
        network = adminState.networkNodes,
        metrics = adminState.metrics,
        ui = adminState.ui
    }
end

-- Draw Admin's Watch interface
function adminMode.draw()
    if not adminState.isActive then
        return
    end
    
    -- This will be a complex UI, for now just draw basic info
    local y = 10
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(16))
    
    -- Header
    love.graphics.print("🏢 The Admin's Watch - " .. adminState.currentClient.name, 10, y)
    y = y + 25
    
    -- Resources
    love.graphics.setFont(love.graphics.newFont(12))
    love.graphics.print("💰 Budget: $" .. format.currency(adminState.currentClient.budget), 10, y)
    y = y + 20
    love.graphics.print("⚡ CPU: " .. math.floor(adminState.operationalResources.cpuCycles) .. "%", 10, y)
    y = y + 20
    love.graphics.print("👥 Personnel: " .. math.floor(adminState.operationalResources.personnelHours) .. "h", 10, y)
    y = y + 25
    
    -- Active incidents
    if #adminState.activeIncidents > 0 then
        love.graphics.print("🚨 ACTIVE INCIDENTS:", 10, y)
        y = y + 20
        
        for _, incident in ipairs(adminState.activeIncidents) do
            love.graphics.setColor(1, 0.3, 0.3, 1)
            love.graphics.print("   " .. incident.name .. " (" .. 
                               math.floor(incident.timeRemaining) .. "s)", 10, y)
            y = y + 15
        end
    else
        love.graphics.setColor(0.3, 1, 0.3, 1)
        love.graphics.print("✅ All systems secure", 10, y)
    end
    
    -- Instructions
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    y = love.graphics.getHeight() - 60
    love.graphics.print("Press 'A' to toggle Admin's Watch mode", 10, y)
    y = y + 15
    love.graphics.print("Press '1-3' to respond to incidents", 10, y)
end

-- Handle mouse input for Admin's Watch
function adminMode.mousepressed(x, y, button)
    if not adminState.isActive then
        return false
    end
    
    -- Handle network node selection, incident responses, etc.
    -- This will be implemented with the full UI
    
    return true -- Consume all clicks in admin mode
end

-- Handle keyboard input for Admin's Watch
function adminMode.keypressed(key)
    if key == "a" then
        adminMode.toggle()
        return true
    end
    
    if not adminState.isActive then
        return false
    end
    
    -- Handle incident responses
    if key >= "1" and key <= "3" then
        local incidentIndex = tonumber(key)
        if adminState.activeIncidents[incidentIndex] then
            local incident = adminState.activeIncidents[incidentIndex]
            local response = incident.responses[1] -- Use first available response
            adminMode.respondToIncident(incident.id, response)
            return true
        end
    end
    
    return false
end

return adminMode