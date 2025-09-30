-- Deterministic simulation scenarios for testing game systems
local SimulationRunner = require("tests.tools.simulation_runner")
local EventBus = require("src.utils.event_bus")
local ResourceManager = require("src.core.resource_manager")
local ThreatSimulation = require("src.core.threat_simulation")
local SecurityUpgrades = require("src.core.security_upgrades")

local function run()
    print("🧪 Running simulation scenario tests...")

    -- Scenario 1: Force a LOW phishing attack and run until mitigated
    do
        math.randomseed(12345)
        local runner = SimulationRunner.new()
        local eventBus = runner.eventBus
        local resourceManager = ResourceManager.new(eventBus)
        local securityUpgrades = SecurityUpgrades.new(eventBus, resourceManager)
        local threatSim = ThreatSimulation.new(eventBus, resourceManager, securityUpgrades)

        runner:registerSystem("resourceManager", resourceManager)
        runner:registerSystem("threatSim", threatSim)

        -- baseline money
        local startMoney = resourceManager:getResource("money")

        -- Force generate a LOW phishing attack
        local threat = threatSim:forceGenerateThreat("phishing", "LOW")
        assert(threat, "Threat should be created")

        -- Run simulation for 30 seconds
        runner:runFor(30, 0.5)

        local endMoney = resourceManager:getResource("money")
        assert(endMoney <= startMoney, "Money should not increase from an attack scenario")
        print("✅ Scenario 1 passed: LOW phishing attack affects resources as expected")
    end

    -- Scenario 2: Force a CRITICAL ransomware attack and ensure large impact
    do
        math.randomseed(54321)
        local runner = SimulationRunner.new()
        local eventBus = runner.eventBus
        local resourceManager = ResourceManager.new(eventBus)
        local securityUpgrades = SecurityUpgrades.new(eventBus, resourceManager)
        local threatSim = ThreatSimulation.new(eventBus, resourceManager, securityUpgrades)

        runner:registerSystem("resourceManager", resourceManager)
        runner:registerSystem("threatSim", threatSim)

        local startMoney = resourceManager:getResource("money")

        local threat = threatSim:forceGenerateThreat("ransomware", "CRITICAL")
        assert(threat, "Threat should be created")

        -- Run simulation for 60 seconds
        runner:runFor(60, 0.5)

        local endMoney = resourceManager:getResource("money")
        assert(endMoney < startMoney * 0.7, "Critical ransomware should cause significant loss")
        print("✅ Scenario 2 passed: CRITICAL ransomware causes expected large loss")
    end

    print("🧪 Simulation scenarios completed")
end

run()
return true
