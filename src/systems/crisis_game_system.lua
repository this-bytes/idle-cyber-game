-- Crisis Game System - Interactive real-time crisis response mini-games
-- Provides engaging tactical gameplay during security incidents

local CrisisGameSystem = {}
CrisisGameSystem.__index = CrisisGameSystem

function CrisisGameSystem.new(eventBus)
    local self = setmetatable({}, CrisisGameSystem)
    self.eventBus = eventBus
    
    -- Crisis state
    self.activeCrisis = nil
    self.gameMode = nil -- "packet_filter", "malware_hunt", "social_eng_defense", "incident_response"
    self.gameState = {}
    self.timeRemaining = 0
    self.score = 0
    self.difficulty = 1
    
    -- Game templates
    self.crisisTemplates = {
        ddos_attack = {
            title = "DDoS Attack in Progress",
            description = "Massive traffic surge detected from multiple IP ranges",
            gameMode = "packet_filter",
            duration = 120,
            difficulty = 2,
            rewards = {money = 2500, reputation = 3, missionTokens = 2}
        },
        ransomware_incident = {
            title = "Ransomware Deployment Detected",
            description = "Malicious encryption processes active on network endpoints",
            gameMode = "malware_hunt",
            duration = 180,
            difficulty = 3,
            rewards = {money = 5000, reputation = 5, missionTokens = 4}
        },
        phishing_campaign = {
            title = "Coordinated Phishing Campaign",
            description = "Targeted social engineering attack against executive team",
            gameMode = "social_eng_defense",
            duration = 150,
            difficulty = 2,
            rewards = {money = 3000, reputation = 4, missionTokens = 3}
        },
        data_exfiltration = {
            title = "Data Exfiltration Attempt",
            description = "Unauthorized data transfer detected on network perimeter",
            gameMode = "incident_response",
            duration = 200,
            difficulty = 4,
            rewards = {money = 7500, reputation = 7, missionTokens = 5}
        },
        supply_chain_compromise = {
            title = "Supply Chain Compromise",
            description = "Third-party vendor systems showing signs of compromise",
            gameMode = "incident_response",
            duration = 240,
            difficulty = 5,
            rewards = {money = 10000, reputation = 10, missionTokens = 8}
        }
    }
    
    return self
end

-- Start a crisis mini-game
function CrisisGameSystem:startCrisis(crisisType)
    local template = self.crisisTemplates[crisisType]
    if not template then
        crisisType = self:getRandomCrisisType()
        template = self.crisisTemplates[crisisType]
    end
    
    self.activeCrisis = {
        type = crisisType,
        title = template.title,
        description = template.description,
        startTime = love.timer and love.timer.getTime() or 0
    }
    
    self.gameMode = template.gameMode
    self.timeRemaining = template.duration
    self.difficulty = template.difficulty
    self.score = 0
    
    -- Initialize game-specific state
    self:initializeGameMode(template.gameMode)
    
    -- Emit crisis start event
    if self.eventBus then
        self.eventBus:publish("crisis_started", {
            type = crisisType,
            title = template.title,
            gameMode = template.gameMode
        })
    end
    
    print("🚨 Crisis started: " .. template.title)
    return true
end

-- Initialize specific game mode
function CrisisGameSystem:initializeGameMode(mode)
    if mode == "packet_filter" then
        self:initPacketFilterGame()
    elseif mode == "malware_hunt" then
        self:initMalwareHuntGame()
    elseif mode == "social_eng_defense" then
        self:initSocialEngDefenseGame()
    elseif mode == "incident_response" then
        self:initIncidentResponseGame()
    end
end

-- Packet Filter Game - Block malicious traffic
function CrisisGameSystem:initPacketFilterGame()
    self.gameState = {
        packets = {},
        blockedCount = 0,
        allowedCount = 0,
        wrongBlocks = 0,
        packetSpawnRate = 1.0,
        lastPacketSpawn = 0,
        packetSpeed = 50
    }
    
    -- Generate initial packets
    for i = 1, 3 do
        self:spawnPacket()
    end
end

-- Malware Hunt Game - Identify and quarantine threats
function CrisisGameSystem:initMalwareHuntGame()
    self.gameState = {
        processes = {},
        filesystems = {},
        scanProgress = 0,
        threatsFound = 0,
        falsePositives = 0,
        scanSpeed = 10, -- per second
        suspiciousActivity = {}
    }
    
    -- Generate file system structure with hidden threats
    self:generateFileSystem()
end

-- Social Engineering Defense Game - Identify phishing attempts
function CrisisGameSystem:initSocialEngDefenseGame()
    self.gameState = {
        emails = {},
        currentEmail = 1,
        correctIdentifications = 0,
        falseAlarms = 0,
        emailQueue = {},
        suspicionLevel = 0
    }
    
    -- Generate email samples
    self:generateEmailSamples()
end

-- Incident Response Game - Coordinate response actions
function CrisisGameSystem:initIncidentResponseGame()
    self.gameState = {
        responseActions = {},
        completedActions = {},
        timeline = {},
        resourceAllocation = {
            analysts = 0,
            investigators = 0,
            communications = 0
        },
        stakeholderSatisfaction = 100,
        containmentProgress = 0
    }
    
    -- Generate response scenario
    self:generateResponseScenario()
end

-- Update crisis game state
function CrisisGameSystem:update(dt)
    if not self.activeCrisis then return end
    
    self.timeRemaining = self.timeRemaining - dt
    
    -- Check for game over conditions
    if self.timeRemaining <= 0 then
        self:endCrisis(false) -- Time expired
        return
    end
    
    -- Update specific game mode
    if self.gameMode == "packet_filter" then
        self:updatePacketFilterGame(dt)
    elseif self.gameMode == "malware_hunt" then
        self:updateMalwareHuntGame(dt)
    elseif self.gameMode == "social_eng_defense" then
        self:updateSocialEngDefenseGame(dt)
    elseif self.gameMode == "incident_response" then
        self:updateIncidentResponseGame(dt)
    end
    
    -- Check for victory conditions
    self:checkVictoryConditions()
end

-- Update packet filter game
function CrisisGameSystem:updatePacketFilterGame(dt)
    local state = self.gameState
    
    -- Spawn new packets
    state.lastPacketSpawn = state.lastPacketSpawn + dt
    if state.lastPacketSpawn >= state.packetSpawnRate then
        self:spawnPacket()
        state.lastPacketSpawn = 0
        
        -- Increase difficulty over time
        state.packetSpawnRate = math.max(0.3, state.packetSpawnRate - dt * 0.01)
        state.packetSpeed = state.packetSpeed + dt * 2
    end
    
    -- Move packets
    for i = #state.packets, 1, -1 do
        local packet = state.packets[i]
        packet.x = packet.x + packet.speed * dt
        
        -- Remove packets that reached the end
        if packet.x > 800 then
            table.remove(state.packets, i)
            if packet.malicious then
                -- Malicious packet got through
                self.score = self.score - 10
            else
                -- Legitimate packet got through (good)
                state.allowedCount = state.allowedCount + 1
                self.score = self.score + 2
            end
        end
    end
end

-- Update malware hunt game
function CrisisGameSystem:updateMalwareHuntGame(dt)
    local state = self.gameState
    
    -- Simulate scanning progress
    state.scanProgress = state.scanProgress + state.scanSpeed * dt
    
    -- Periodically reveal suspicious activity
    if math.random() < dt * 0.3 then
        self:revealSuspiciousActivity()
    end
end

-- Update social engineering defense game
function CrisisGameSystem:updateSocialEngDefenseGame(dt)
    local state = self.gameState
    
    -- Advance through email queue
    if #state.emailQueue > 0 and math.random() < dt * 0.5 then
        local nextEmail = table.remove(state.emailQueue, 1)
        table.insert(state.emails, nextEmail)
        state.currentEmail = #state.emails
    end
end

-- Update incident response game
function CrisisGameSystem:updateIncidentResponseGame(dt)
    local state = self.gameState
    
    -- Progress containment based on resource allocation
    local totalResources = state.resourceAllocation.analysts + 
                          state.resourceAllocation.investigators + 
                          state.resourceAllocation.communications
    
    if totalResources > 0 then
        state.containmentProgress = state.containmentProgress + dt * totalResources * 2
    end
    
    -- Stakeholder satisfaction decreases over time if not managed
    if state.resourceAllocation.communications < 2 then
        state.stakeholderSatisfaction = state.stakeholderSatisfaction - dt * 5
    end
end

-- Handle input for crisis games
function CrisisGameSystem:keypressed(key)
    if not self.activeCrisis then return false end
    
    if self.gameMode == "packet_filter" then
        return self:handlePacketFilterInput(key)
    elseif self.gameMode == "malware_hunt" then
        return self:handleMalwareHuntInput(key)
    elseif self.gameMode == "social_eng_defense" then
        return self:handleSocialEngInput(key)
    elseif self.gameMode == "incident_response" then
        return self:handleIncidentResponseInput(key)
    end
    
    return false
end

function CrisisGameSystem:mousepressed(x, y, button)
    if not self.activeCrisis then return false end
    
    if self.gameMode == "packet_filter" then
        return self:handlePacketFilterClick(x, y, button)
    elseif self.gameMode == "malware_hunt" then
        return self:handleMalwareHuntClick(x, y, button)
    elseif self.gameMode == "social_eng_defense" then
        return self:handleSocialEngClick(x, y, button)
    elseif self.gameMode == "incident_response" then
        return self:handleIncidentResponseClick(x, y, button)
    end
    
    return false
end

-- Packet filter input handling
function CrisisGameSystem:handlePacketFilterInput(key)
    if key == "space" then
        -- Block nearest packet
        local nearest = self:findNearestPacket()
        if nearest then
            self:blockPacket(nearest)
        end
        return true
    end
    return false
end

function CrisisGameSystem:handlePacketFilterClick(x, y, button)
    if button == 1 then
        -- Click to block packet
        local clickedPacket = self:findPacketAt(x, y)
        if clickedPacket then
            self:blockPacket(clickedPacket)
        end
        return true
    end
    return false
end

-- Social engineering input handling
function CrisisGameSystem:handleSocialEngInput(key)
    local state = self.gameState
    if not state.emails[state.currentEmail] then return false end
    
    if key == "y" then
        -- Mark as phishing
        self:markEmailAsPhishing(state.currentEmail)
        return true
    elseif key == "n" then
        -- Mark as legitimate
        self:markEmailAsLegitimate(state.currentEmail)
        return true
    elseif key == "right" and state.currentEmail < #state.emails then
        state.currentEmail = state.currentEmail + 1
        return true
    elseif key == "left" and state.currentEmail > 1 then
        state.currentEmail = state.currentEmail - 1
        return true
    end
    
    return false
end

-- Generate game content
function CrisisGameSystem:spawnPacket()
    local malicious = math.random() < 0.3 -- 30% malicious
    local packet = {
        x = -50,
        y = 200 + math.random(-100, 100),
        speed = self.gameState.packetSpeed + math.random(-10, 20),
        malicious = malicious,
        sourceIP = self:generateIP(),
        packetType = malicious and self:getMaliciousPacketType() or "HTTP",
        size = math.random(64, 1500)
    }
    
    table.insert(self.gameState.packets, packet)
end

function CrisisGameSystem:generateIP()
    return math.random(1, 255) .. "." .. math.random(1, 255) .. "." .. 
           math.random(1, 255) .. "." .. math.random(1, 255)
end

function CrisisGameSystem:getMaliciousPacketType()
    local types = {"BOTNET", "DDOS", "EXPLOIT", "MALWARE", "BACKDOOR"}
    return types[math.random(#types)]
end

function CrisisGameSystem:generateEmailSamples()
    local legitimate = {
        {
            subject = "Q4 Budget Review Meeting",
            sender = "finance@company.com",
            content = "Please review the attached budget documents before our meeting on Friday.",
            phishing = false
        },
        {
            subject = "System Maintenance Window",
            sender = "it-support@company.com", 
            content = "Scheduled maintenance will occur this weekend. No action required.",
            phishing = false
        }
    }
    
    local phishing = {
        {
            subject = "URGENT: Account Verification Required",
            sender = "security@company-verification.net", -- suspicious domain
            content = "Click here to verify your account immediately or it will be suspended.",
            phishing = true,
            indicators = {"Urgent language", "Suspicious domain", "Threatening tone"}
        },
        {
            subject = "You've won a prize!",
            sender = "ceo@company.com", -- spoofed internal email
            content = "Congratulations! Click this link to claim your reward.",
            phishing = true,
            indicators = {"CEO impersonation", "Prize scam", "Suspicious link"}
        }
    }
    
    -- Mix legitimate and phishing emails
    local allEmails = {}
    for _, email in ipairs(legitimate) do
        table.insert(allEmails, email)
    end
    for _, email in ipairs(phishing) do
        table.insert(allEmails, email)
    end
    
    -- Shuffle the emails
    for i = #allEmails, 2, -1 do
        local j = math.random(i)
        allEmails[i], allEmails[j] = allEmails[j], allEmails[i]
    end
    
    self.gameState.emails = allEmails
    self.gameState.emailQueue = {}
end

-- Victory condition checking
function CrisisGameSystem:checkVictoryConditions()
    local victory = false
    
    if self.gameMode == "packet_filter" then
        local state = self.gameState
        local accuracy = (state.blockedCount > 0) and (state.blockedCount / (state.blockedCount + state.wrongBlocks)) or 0
        victory = state.blockedCount >= 10 and accuracy >= 0.8
    elseif self.gameMode == "malware_hunt" then
        victory = self.gameState.scanProgress >= 100 and self.gameState.threatsFound >= 5
    elseif self.gameMode == "social_eng_defense" then
        victory = self.gameState.correctIdentifications >= 8 and self.gameState.falseAlarms <= 2
    elseif self.gameMode == "incident_response" then
        victory = self.gameState.containmentProgress >= 100 and self.gameState.stakeholderSatisfaction >= 70
    end
    
    if victory then
        self:endCrisis(true)
    end
end

-- End crisis (victory or failure)
function CrisisGameSystem:endCrisis(victory)
    if not self.activeCrisis then return end
    
    local crisisType = self.activeCrisis.type
    local template = self.crisisTemplates[crisisType]
    
    if victory then
        -- Award rewards
        if self.eventBus and template.rewards then
            for currency, amount in pairs(template.rewards) do
                self.eventBus:publish("add_resource", {
                    resource = currency,
                    amount = amount
                })
            end
        end
        
        -- Emit success event
        if self.eventBus then
            self.eventBus:publish("crisis_resolved", {
                type = crisisType,
                score = self.score,
                rewards = template.rewards
            })
        end
        
        print("✅ Crisis resolved successfully! Score: " .. self.score)
    else
        -- Handle failure
        if self.eventBus then
            self.eventBus:publish("crisis_failed", {
                type = crisisType,
                score = self.score
            })
        end
        
        print("❌ Crisis response failed. Score: " .. self.score)
    end
    
    -- Reset state
    self.activeCrisis = nil
    self.gameMode = nil
    self.gameState = {}
    self.timeRemaining = 0
    self.score = 0
end

-- Utility methods
function CrisisGameSystem:getRandomCrisisType()
    local types = {}
    for crisisType, _ in pairs(self.crisisTemplates) do
        table.insert(types, crisisType)
    end
    return types[math.random(#types)]
end

function CrisisGameSystem:isActive()
    return self.activeCrisis ~= nil
end

function CrisisGameSystem:getCurrentCrisis()
    return self.activeCrisis
end

function CrisisGameSystem:getGameState()
    return {
        mode = self.gameMode,
        timeRemaining = self.timeRemaining,
        score = self.score,
        difficulty = self.difficulty,
        state = self.gameState
    }
end

-- Helper methods for packet filter game
function CrisisGameSystem:findNearestPacket()
    local nearest = nil
    local minDistance = math.huge
    
    for _, packet in ipairs(self.gameState.packets or {}) do
        local distance = packet.x
        if distance < minDistance and distance > 0 then
            minDistance = distance
            nearest = packet
        end
    end
    
    return nearest
end

function CrisisGameSystem:findPacketAt(x, y)
    for _, packet in ipairs(self.gameState.packets or {}) do
        local px, py = packet.x, packet.y
        if x >= px - 20 and x <= px + 20 and y >= py - 15 and y <= py + 15 then
            return packet
        end
    end
    return nil
end

function CrisisGameSystem:blockPacket(packet)
    if not packet then return end
    
    -- Remove packet from list
    for i, p in ipairs(self.gameState.packets) do
        if p == packet then
            table.remove(self.gameState.packets, i)
            break
        end
    end
    
    -- Update score and stats
    if packet.malicious then
        self.gameState.blockedCount = self.gameState.blockedCount + 1
        self.score = self.score + 10
        
        -- Emit success event
        if self.eventBus then
            self.eventBus:publish("ui.success", {})
        end
    else
        self.gameState.wrongBlocks = self.gameState.wrongBlocks + 1
        self.score = self.score - 5
        
        -- Emit error event
        if self.eventBus then
            self.eventBus:publish("ui.error", {})
        end
    end
end

return CrisisGameSystem