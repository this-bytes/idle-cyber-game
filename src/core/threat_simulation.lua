-- ThreatSimulation - Realistic cyber threat engine
-- Handles threat types: Phishing, Malware, APT, Zero-day, Ransomware, DDoS, Social Engineering, Supply Chain

-- Adapter: forward legacy core.threat_simulation API to canonical systems/threat_system
local ThreatSystem = require("src.systems.threat_system")

local Adapter = {}
Adapter.__index = Adapter

function Adapter.new(eventBus, resourceManager, securityUpgrades)
    -- Create an underlying ThreatSystem and expose a small compatibility surface
    local threat = ThreatSystem.new(eventBus, resourceManager, nil, nil)
    local self = setmetatable({}, Adapter)
    self._threatSystem = threat
    -- Forwarder: src.core.threat_simulation -> src.systems.threat_system
    return require("src.systems.threat_system")
end