-- AnalyticsCollector - Privacy-respecting game analytics
-- Tracks player behavior and progression for balance insights
-- Part of the AWESOME Backend Architecture

local AnalyticsCollector = {}
AnalyticsCollector.__index = AnalyticsCollector

function AnalyticsCollector.new(eventBus, saveSystem)
    local self = setmetatable({}, AnalyticsCollector)
    self.eventBus = eventBus
    self.saveSystem = saveSystem
    
    -- Local-only analytics (never sent online)
    self.session = {
        start_time = os.time(),
        events = {},
        player_journey = {},
        
        -- Aggregate stats
        total_playtime = 0,
        contracts_completed = 0,
        money_earned = 0,
        upgrades_purchased = 0,
        specialists_hired = 0,
        threats_mitigated = 0,
        crises_resolved = 0,
        
        -- Progression checkpoints
        first_contract = nil,
        first_Incident = nil,
        first_specialist = nil,
        first_upgrade = nil,
        progression_velocity = {}
    }
    
    return self
end

function AnalyticsCollector:initialize()
    print("📊 Initializing Analytics Collector...")
    
    -- Subscribe to key events
    if self.eventBus then
        self.eventBus:subscribe("contract_completed", function(data)
            self:trackEvent("contract_completed", data)
        end)
        
        self.eventBus:subscribe("specialist_hired", function(data)
            self:trackEvent("specialist_hired", data)
        end)
        
        self.eventBus:subscribe("upgrade_purchased", function(data)
            self:trackEvent("upgrade_purchased", data)
        end)
        
        self.eventBus:subscribe("threat_mitigated", function(data)
            self:trackEvent("threat_mitigated", data)
        end)
        
        self.eventBus:subscribe("Incident_resolved", function(data)
            self:trackEvent("Incident_resolved", data)
        end)
        
        self.eventBus:subscribe("synergy_activated", function(data)
            self:trackEvent("synergy_activated", data)
        end)
    end
    
    print("✅ Analytics Collector initialized")
end

function AnalyticsCollector:trackEvent(eventType, data)
    local event = {
        type = eventType,
        timestamp = os.time(),
        data = data
    }
    
    table.insert(self.session.events, event)
    
    -- Update aggregate stats
    if eventType == "contract_completed" then
        self.session.contracts_completed = self.session.contracts_completed + 1
        if not self.session.first_contract then
            self.session.first_contract = os.time()
        end
        if data.reward then
            self.session.money_earned = self.session.money_earned + data.reward
        end
    elseif eventType == "specialist_hired" then
        self.session.specialists_hired = self.session.specialists_hired + 1
        if not self.session.first_specialist then
            self.session.first_specialist = os.time()
        end
    elseif eventType == "upgrade_purchased" then
        self.session.upgrades_purchased = self.session.upgrades_purchased + 1
        if not self.session.first_upgrade then
            self.session.first_upgrade = os.time()
        end
    elseif eventType == "threat_mitigated" then
        self.session.threats_mitigated = self.session.threats_mitigated + 1
    elseif eventType == "Incident_resolved" then
        self.session.crises_resolved = self.session.crises_resolved + 1
        if not self.session.first_Incident then
            self.session.first_Incident = os.time()
        end
    end
    
    -- Keep event buffer manageable
    if #self.session.events > 1000 then
        table.remove(self.session.events, 1)
    end
end

function AnalyticsCollector:update(dt)
    self.session.total_playtime = self.session.total_playtime + dt
end

function AnalyticsCollector:getStats()
    local sessionDuration = os.time() - self.session.start_time
    
    return {
        session = {
            duration = sessionDuration,
            playtime = self.session.total_playtime,
            events_recorded = #self.session.events
        },
        
        activity = {
            contracts_completed = self.session.contracts_completed,
            specialists_hired = self.session.specialists_hired,
            upgrades_purchased = self.session.upgrades_purchased,
            threats_mitigated = self.session.threats_mitigated,
            crises_resolved = self.session.crises_resolved,
            money_earned = self.session.money_earned
        },
        
        milestones = {
            first_contract = self.session.first_contract,
            first_specialist = self.session.first_specialist,
            first_upgrade = self.session.first_upgrade,
            first_Incident = self.session.first_Incident
        },
        
        rates = {
            contracts_per_minute = sessionDuration > 0 and 
                (self.session.contracts_completed / (sessionDuration / 60)) or 0,
            money_per_minute = sessionDuration > 0 and 
                (self.session.money_earned / (sessionDuration / 60)) or 0
        }
    }
end

function AnalyticsCollector:getRecentEvents(count)
    count = count or 10
    local start = math.max(1, #self.session.events - count + 1)
    local recent = {}
    
    for i = start, #self.session.events do
        table.insert(recent, self.session.events[i])
    end
    
    -- Forwarder: src.core.analytics_collector -> src.systems.analytics_collector
    return require("src.systems.analytics_collector")

