-- Test suite for Incident and Specialist Management System
-- Validates JSON loading, incident generation, and specialist assignment

local IncidentSpecialistSystem = require("src.systems.incident_specialist_system")

local TestIncidentSpecialistSystem = {}

-- Mock EventBus for testing
local function createMockEventBus()
    local events = {}
    return {
        publish = function(self, event, data)
            events[event] = events[event] or {}
            table.insert(events[event], data)
        end,
        subscribe = function(self, event, callback)
            -- Not needed for basic testing
        end,
        getEvents = function(self)
            return events
        end
    }
end

-- Mock ResourceManager for testing
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

-- Test 1: System initialization
function TestIncidentSpecialistSystem.test_initialization()
    print("\n=== Test 1: System Initialization ===")
    
    local eventBus = createMockEventBus()
    local resourceManager = createMockResourceManager()
    
    local system = IncidentSpecialistSystem.new(eventBus, resourceManager)
    system:initialize()
    
    local state = system:getState()
    
    -- Verify GameState structure
    assert(state.Specialists ~= nil, "Specialists table should exist")
    assert(state.IncidentsQueue ~= nil, "IncidentsQueue table should exist")
    assert(state.ThreatTemplates ~= nil, "ThreatTemplates table should exist")
    assert(state.SpecialistTemplates ~= nil, "SpecialistTemplates table should exist")
    
    -- Verify starting specialists were instantiated
    assert(#state.Specialists >= 3, "Should have at least 3 starting specialists")
    
    -- Verify threat templates were loaded
    assert(#state.ThreatTemplates > 0, "Should have loaded threat templates")
    
    -- Verify specialist templates were loaded
    local templateCount = 0
    for _ in pairs(state.SpecialistTemplates) do
        templateCount = templateCount + 1
    end
    assert(templateCount > 0, "Should have loaded specialist templates")
    
    print("✅ System initialization test passed")
    return true
end

-- Test 2: Specialist instantiation
function TestIncidentSpecialistSystem.test_specialist_instantiation()
    print("\n=== Test 2: Specialist Instantiation ===")
    
    local eventBus = createMockEventBus()
    local resourceManager = createMockResourceManager()
    
    local system = IncidentSpecialistSystem.new(eventBus, resourceManager)
    system:initialize()
    
    local state = system:getState()
    
    -- Check each specialist has required GDD fields
    for _, specialist in ipairs(state.Specialists) do
        assert(specialist.Level ~= nil, "Specialist should have Level")
        assert(specialist.Level == 1, "Starting level should be 1")
        assert(specialist.XP ~= nil, "Specialist should have XP")
        assert(specialist.XP == 0, "Starting XP should be 0")
        assert(specialist.is_busy ~= nil, "Specialist should have is_busy flag")
        assert(specialist.is_busy == false, "Starting is_busy should be false")
        assert(specialist.cooldown_timer ~= nil, "Specialist should have cooldown_timer")
        assert(specialist.cooldown_timer == 0, "Starting cooldown should be 0")
        
        -- Check stats (Traits)
        assert(specialist.defense ~= nil, "Specialist should have defense stat")
        
        print(string.format("   ✓ %s: Level=%d, XP=%d, Defense=%.1f", 
            specialist.name, specialist.Level, specialist.XP, specialist.defense))
    end
    
    print("✅ Specialist instantiation test passed")
    return true
end

-- Test 3: Incident generation from templates
function TestIncidentSpecialistSystem.test_incident_generation()
    print("\n=== Test 3: Incident Generation ===")
    
    local eventBus = createMockEventBus()
    local resourceManager = createMockResourceManager()
    
    local system = IncidentSpecialistSystem.new(eventBus, resourceManager)
    system:initialize()
    
    local state = system:getState()
    
    -- Manually trigger incident generation
    if #state.ThreatTemplates > 0 then
        local template = state.ThreatTemplates[1]
        local incident = system:createIncidentFromTemplate(template)
        
        -- Verify incident structure
        assert(incident.id ~= nil, "Incident should have id")
        assert(incident.trait_required ~= nil, "Incident should have trait_required")
        assert(incident.trait_value_needed ~= nil, "Incident should have trait_value_needed")
        assert(incident.time_to_resolve ~= nil, "Incident should have time_to_resolve")
        assert(incident.base_reward ~= nil, "Incident should have base_reward")
        assert(incident.status == "Pending", "New incident should be Pending")
        
        -- Verify reward structure
        assert(incident.base_reward.money ~= nil, "Reward should include money")
        assert(incident.base_reward.reputation ~= nil, "Reward should include reputation")
        assert(incident.base_reward.xp ~= nil, "Reward should include xp")
        assert(incident.base_reward.missionTokens ~= nil, "Reward should include missionTokens")
        
        print(string.format("   ✓ Created incident: %s", incident.name))
        print(string.format("   ✓ Severity: %d, Time to Resolve: %ds", 
            incident.trait_value_needed, incident.time_to_resolve))
        print(string.format("   ✓ Rewards: $%.0f, %d Rep, %d XP, %d Tokens", 
            incident.base_reward.money, 
            incident.base_reward.reputation,
            incident.base_reward.xp,
            incident.base_reward.missionTokens))
    end
    
    print("✅ Incident generation test passed")
    return true
end

-- Test 4: Idle resolution check
function TestIncidentSpecialistSystem.test_idle_resolution()
    print("\n=== Test 4: Idle Resolution Check ===")
    
    local eventBus = createMockEventBus()
    local resourceManager = createMockResourceManager()
    
    local system = IncidentSpecialistSystem.new(eventBus, resourceManager)
    system:initialize()
    
    local state = system:getState()
    
    -- Test auto-resolve (low severity)
    if #state.ThreatTemplates > 0 then
        -- Find a low-severity threat
        local lowThreat = nil
        for _, template in ipairs(state.ThreatTemplates) do
            if template.baseSeverity and template.baseSeverity <= 5 then
                lowThreat = template
                break
            end
        end
        
        if lowThreat then
            local incident = system:createIncidentFromTemplate(lowThreat)
            local initialQueueSize = #state.IncidentsQueue
            
            -- Should auto-resolve if GlobalAutoResolveStat (100) >= severity
            system:Incident_CheckIdleResolve(incident)
            
            if incident.trait_value_needed <= state.GlobalAutoResolveStat then
                assert(#state.IncidentsQueue == initialQueueSize, 
                    "Low severity incident should auto-resolve and not be added to queue")
                print("   ✓ Low severity incident auto-resolved")
            else
                assert(#state.IncidentsQueue == initialQueueSize + 1, 
                    "High severity incident should be added to queue")
                print("   ✓ High severity incident escalated to queue")
            end
        end
    end
    
    print("✅ Idle resolution test passed")
    return true
end

-- Test 5: Specialist auto-assignment
function TestIncidentSpecialistSystem.test_auto_assignment()
    print("\n=== Test 5: Specialist Auto-Assignment ===")
    
    local eventBus = createMockEventBus()
    local resourceManager = createMockResourceManager()
    
    local system = IncidentSpecialistSystem.new(eventBus, resourceManager)
    system:initialize()
    
    local state = system:getState()
    
    -- Create a low-severity incident that will escalate
    if #state.ThreatTemplates > 0 then
        local template = state.ThreatTemplates[1]
        local incident = system:createIncidentFromTemplate(template)
        
        -- Force escalation by setting high severity
        incident.trait_value_needed = 200  -- Higher than GlobalAutoResolveStat
        system:Incident_CheckIdleResolve(incident)
        
        -- Should be in queue now
        assert(#state.IncidentsQueue > 0, "Incident should be in queue")
        
        -- Adjust requirement so specialists can handle it
        for _, inc in ipairs(state.IncidentsQueue) do
            inc.trait_value_needed = 0.5  -- Very low, any specialist can handle
        end
        
        -- Try auto-assignment
        system:Specialist_AutoAssign()
        
        -- Check if any incident was assigned
        local foundAssigned = false
        for _, inc in ipairs(state.IncidentsQueue) do
            if inc.status == "AutoAssigned" then
                foundAssigned = true
                assert(inc.assignedSpecialistId ~= nil, "Assigned incident should have specialist ID")
                
                -- Find the specialist and verify they're busy
                local specialist = system:getSpecialistById(inc.assignedSpecialistId)
                assert(specialist ~= nil, "Should find assigned specialist")
                assert(specialist.is_busy == true, "Assigned specialist should be busy")
                
                print(string.format("   ✓ %s assigned to incident", specialist.name))
                break
            end
        end
        
        assert(foundAssigned, "At least one incident should be auto-assigned")
    end
    
    print("✅ Auto-assignment test passed")
    return true
end

-- Test 6: Incident resolution and rewards
function TestIncidentSpecialistSystem.test_incident_resolution()
    print("\n=== Test 6: Incident Resolution ===")
    
    local eventBus = createMockEventBus()
    local resourceManager = createMockResourceManager()
    
    local system = IncidentSpecialistSystem.new(eventBus, resourceManager)
    system:initialize()
    
    local state = system:getState()
    local resources = resourceManager:getResources()
    
    -- Get initial resource values
    local initialMoney = resources.money
    local initialRep = resources.reputation
    local initialXP = resources.xp
    local initialTokens = resources.missionTokens
    
    -- Create and assign an incident
    if #state.ThreatTemplates > 0 and #state.Specialists > 0 then
        local template = state.ThreatTemplates[1]
        local incident = system:createIncidentFromTemplate(template)
        local specialist = state.Specialists[1]
        
        incident.status = "AutoAssigned"
        incident.assignedSpecialistId = specialist.id
        specialist.is_busy = true
        
        local specialistInitialXP = specialist.XP
        
        -- Resolve the incident
        system:Incident_Resolve(incident, specialist)
        
        -- Verify rewards were awarded
        assert(resources.money > initialMoney, "Money should increase")
        assert(resources.reputation >= initialRep, "Reputation should increase or stay same")
        assert(resources.xp > initialXP, "XP should increase")
        assert(resources.missionTokens > initialTokens, "Mission Tokens should increase")
        
        -- Verify specialist gained XP
        assert(specialist.XP > specialistInitialXP, "Specialist should gain XP")
        
        -- Verify specialist cooldown
        assert(specialist.cooldown_timer > 0, "Specialist should have cooldown")
        
        print(string.format("   ✓ Resources awarded: $%.0f, %d Rep, %d XP, %d Tokens", 
            resources.money - initialMoney,
            resources.reputation - initialRep,
            resources.xp - initialXP,
            resources.missionTokens - initialTokens))
        print(string.format("   ✓ Specialist XP gained: %d", specialist.XP - specialistInitialXP))
    end
    
    print("✅ Incident resolution test passed")
    return true
end

-- Test 7: Specialist cooldown
function TestIncidentSpecialistSystem.test_cooldown_system()
    print("\n=== Test 7: Specialist Cooldown ===")
    
    local eventBus = createMockEventBus()
    local resourceManager = createMockResourceManager()
    
    local system = IncidentSpecialistSystem.new(eventBus, resourceManager)
    system:initialize()
    
    local state = system:getState()
    
    if #state.Specialists > 0 then
        local specialist = state.Specialists[1]
        
        -- Set cooldown
        specialist.cooldown_timer = 5.0
        specialist.is_busy = true
        
        -- Update with 3 seconds
        system:Specialist_Cooldown_Update(3.0)
        assert(specialist.cooldown_timer == 2.0, "Cooldown should decrease")
        assert(specialist.is_busy == true, "Should still be busy")
        
        -- Update with remaining time
        system:Specialist_Cooldown_Update(2.5)
        assert(specialist.cooldown_timer == 0, "Cooldown should be complete")
        assert(specialist.is_busy == false, "Should no longer be busy")
        
        print("   ✓ Cooldown system working correctly")
    end
    
    print("✅ Cooldown test passed")
    return true
end

-- Test 8: Full update cycle
function TestIncidentSpecialistSystem.test_full_update_cycle()
    print("\n=== Test 8: Full Update Cycle ===")
    
    local eventBus = createMockEventBus()
    local resourceManager = createMockResourceManager()
    
    local system = IncidentSpecialistSystem.new(eventBus, resourceManager)
    system:initialize()
    
    local state = system:getState()
    
    -- Force incident timer to trigger
    state.IncidentTimer = 0.1
    
    -- Run several update cycles
    for i = 1, 5 do
        system:update(1.0)  -- 1 second per update
        
        local stats = system:getStatistics()
        print(string.format("   Cycle %d: Pending=%d, Assigned=%d, Available=%d, Busy=%d", 
            i, 
            stats.pendingIncidents, 
            stats.assignedIncidents,
            stats.availableSpecialists,
            stats.busySpecialists))
    end
    
    print("✅ Full update cycle test passed")
    return true
end

-- Test 9: Specialist unlocking
function TestIncidentSpecialistSystem.test_specialist_unlocking()
    print("\n=== Test 9: Specialist Unlocking ===")
    
    local eventBus = createMockEventBus()
    local resourceManager = createMockResourceManager()
    
    local system = IncidentSpecialistSystem.new(eventBus, resourceManager)
    system:initialize()
    
    local state = system:getState()
    local initialCount = #state.Specialists
    
    -- Try to unlock a specialist that exists in templates
    local unlockableId = nil
    for id, template in pairs(state.SpecialistTemplates) do
        if not state.UnlockedSpecialists[id] then
            unlockableId = id
            break
        end
    end
    
    if unlockableId then
        local success = system:unlockSpecialist(unlockableId)
        assert(success, "Should successfully unlock specialist")
        assert(#state.Specialists == initialCount + 1, "Specialist count should increase")
        assert(state.UnlockedSpecialists[unlockableId] == true, "Specialist should be marked as unlocked")
        
        print(string.format("   ✓ Successfully unlocked specialist: %s", unlockableId))
        
        -- Try to unlock again (should fail)
        local success2 = system:unlockSpecialist(unlockableId)
        assert(success2 == false, "Should not unlock same specialist twice")
        print("   ✓ Duplicate unlock prevented")
    else
        print("   ⚠️  All specialists already unlocked in test")
    end
    
    print("✅ Specialist unlocking test passed")
    return true
end

-- Test 10: Statistics reporting
function TestIncidentSpecialistSystem.test_statistics()
    print("\n=== Test 10: Statistics Reporting ===")
    
    local eventBus = createMockEventBus()
    local resourceManager = createMockResourceManager()
    
    local system = IncidentSpecialistSystem.new(eventBus, resourceManager)
    system:initialize()
    
    local stats = system:getStatistics()
    
    assert(stats.activeSpecialists ~= nil, "Should report active specialists")
    assert(stats.pendingIncidents ~= nil, "Should report pending incidents")
    assert(stats.assignedIncidents ~= nil, "Should report assigned incidents")
    assert(stats.availableSpecialists ~= nil, "Should report available specialists")
    assert(stats.busySpecialists ~= nil, "Should report busy specialists")
    
    print(string.format("   Active Specialists: %d", stats.activeSpecialists))
    print(string.format("   Available: %d, Busy: %d", stats.availableSpecialists, stats.busySpecialists))
    print(string.format("   Incidents - Pending: %d, Assigned: %d", 
        stats.pendingIncidents, stats.assignedIncidents))
    
    print("✅ Statistics test passed")
    return true
end

-- Run all tests
function TestIncidentSpecialistSystem.run_all_tests()
    print("\n" .. string.rep("=", 60))
    print("INCIDENT AND SPECIALIST MANAGEMENT SYSTEM - TEST SUITE")
    print(string.rep("=", 60))
    
    local tests = {
        TestIncidentSpecialistSystem.test_initialization,
        TestIncidentSpecialistSystem.test_specialist_instantiation,
        TestIncidentSpecialistSystem.test_incident_generation,
        TestIncidentSpecialistSystem.test_idle_resolution,
        TestIncidentSpecialistSystem.test_auto_assignment,
        TestIncidentSpecialistSystem.test_incident_resolution,
        TestIncidentSpecialistSystem.test_cooldown_system,
        TestIncidentSpecialistSystem.test_full_update_cycle,
        TestIncidentSpecialistSystem.test_specialist_unlocking,
        TestIncidentSpecialistSystem.test_statistics
    }
    
    local passed = 0
    local failed = 0
    local errors = {}
    
    for i, test in ipairs(tests) do
        local success, err = pcall(test)
        if success then
            passed = passed + 1
        else
            failed = failed + 1
            table.insert(errors, {test = i, error = err})
            print("❌ Test failed: " .. tostring(err))
        end
    end
    
    print("\n" .. string.rep("=", 60))
    print(string.format("TEST RESULTS: %d passed, %d failed", passed, failed))
    print(string.rep("=", 60))
    
    if #errors > 0 then
        print("\nFailed tests:")
        for _, err in ipairs(errors) do
            print(string.format("  Test %d: %s", err.test, err.error))
        end
    end
    
    return passed, failed
end

return TestIncidentSpecialistSystem
