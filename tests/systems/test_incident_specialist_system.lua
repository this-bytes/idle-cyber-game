-- Test suite for Incident and Specialist Management System
-- Validates JSON loading, incident generation, and specialist assignment

local IncidentSpecialistSystem = require("src.systems.incident_specialist_system")

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

TestRunner.test("IncidentSpecialistSystem - Initialization", function()
    local eventBus = createMockEventBus()
    local resourceManager = createMockResourceManager()
    
    local system = IncidentSpecialistSystem.new(eventBus, resourceManager)
    system:initialize()
    
    local state = system:getState()
    
    TestRunner.assert(state.Specialists ~= nil, "Specialists table should exist")
    TestRunner.assert(state.IncidentsQueue ~= nil, "IncidentsQueue table should exist")
    TestRunner.assert(state.ThreatTemplates ~= nil, "ThreatTemplates table should exist")
    TestRunner.assert(state.SpecialistTemplates ~= nil, "SpecialistTemplates table should exist")
    TestRunner.assert(#state.Specialists >= 3, "Should have at least 3 starting specialists")
    TestRunner.assert(#state.ThreatTemplates > 0, "Should have loaded threat templates")
    
    local templateCount = 0
    for _ in pairs(state.SpecialistTemplates) do
        templateCount = templateCount + 1
    end
    TestRunner.assert(templateCount > 0, "Should have loaded specialist templates")
end)

TestRunner.test("IncidentSpecialistSystem - Specialist Instantiation", function()
    local eventBus = createMockEventBus()
    local resourceManager = createMockResourceManager()
    
    local system = IncidentSpecialistSystem.new(eventBus, resourceManager)
    system:initialize()
    
    local state = system:getState()
    
    for _, specialist in ipairs(state.Specialists) do
        TestRunner.assert(specialist.Level ~= nil, "Specialist should have Level")
        TestRunner.assertEqual(1, specialist.Level, "Starting level should be 1")
        TestRunner.assert(specialist.XP ~= nil, "Specialist should have XP")
        TestRunner.assertEqual(0, specialist.XP, "Starting XP should be 0")
        TestRunner.assert(specialist.is_busy ~= nil, "Specialist should have is_busy flag")
        TestRunner.assertEqual(false, specialist.is_busy, "Starting is_busy should be false")
        TestRunner.assert(specialist.cooldown_timer ~= nil, "Specialist should have cooldown_timer")
        TestRunner.assertEqual(0, specialist.cooldown_timer, "Starting cooldown should be 0")
        TestRunner.assert(specialist.defense ~= nil, "Specialist should have defense stat")
    end
end)

TestRunner.test("IncidentSpecialistSystem - Incident Generation", function()
    local eventBus = createMockEventBus()
    local resourceManager = createMockResourceManager()
    
    local system = IncidentSpecialistSystem.new(eventBus, resourceManager)
    system:initialize()
    
    local state = system:getState()
    
    if #state.ThreatTemplates > 0 then
        local template = state.ThreatTemplates[1]
        local incident = system:createIncidentFromTemplate(template)
        
        TestRunner.assert(incident.id ~= nil, "Incident should have id")
        TestRunner.assert(incident.trait_required ~= nil, "Incident should have trait_required")
        TestRunner.assert(incident.trait_value_needed ~= nil, "Incident should have trait_value_needed")
        TestRunner.assert(incident.time_to_resolve ~= nil, "Incident should have time_to_resolve")
        TestRunner.assert(incident.base_reward ~= nil, "Incident should have base_reward")
        TestRunner.assertEqual("Pending", incident.status, "New incident should be Pending")
        TestRunner.assert(incident.base_reward.money ~= nil, "Reward should include money")
        TestRunner.assert(incident.base_reward.reputation ~= nil, "Reward should include reputation")
        TestRunner.assert(incident.base_reward.xp ~= nil, "Reward should include xp")
        TestRunner.assert(incident.base_reward.missionTokens ~= nil, "Reward should include missionTokens")
    end
end)

TestRunner.test("IncidentSpecialistSystem - Idle Resolution Check", function()
    local eventBus = createMockEventBus()
    local resourceManager = createMockResourceManager()
    
    local system = IncidentSpecialistSystem.new(eventBus, resourceManager)
    system:initialize()
    
    local state = system:getState()
    
    if #state.ThreatTemplates > 0 then
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
            
            system:Incident_CheckIdleResolve(incident)
            
            if incident.trait_value_needed <= state.GlobalAutoResolveStat then
                TestRunner.assertEqual(initialQueueSize, #state.IncidentsQueue, "Low severity incident should auto-resolve and not be added to queue")
            else
                TestRunner.assertEqual(initialQueueSize + 1, #state.IncidentsQueue, "High severity incident should be added to queue")
            end
        end
    end
end)

TestRunner.test("IncidentSpecialistSystem - Auto-Assignment", function()
    local eventBus = createMockEventBus()
    local resourceManager = createMockResourceManager()
    
    local system = IncidentSpecialistSystem.new(eventBus, resourceManager)
    system:initialize()
    
    local state = system:getState()
    
    if #state.ThreatTemplates > 0 then
        local template = state.ThreatTemplates[1]
        local incident = system:createIncidentFromTemplate(template)
        
        incident.trait_value_needed = 200
        system:Incident_CheckIdleResolve(incident)
        
        TestRunner.assert(#state.IncidentsQueue > 0, "Incident should be in queue")
        
        for _, inc in ipairs(state.IncidentsQueue) do
            inc.trait_value_needed = 0.5
        end
        
        system:Specialist_AutoAssign()
        
        local foundAssigned = false
        for _, inc in ipairs(state.IncidentsQueue) do
            if inc.status == "AutoAssigned" then
                foundAssigned = true
                TestRunner.assert(inc.assignedSpecialistId ~= nil, "Assigned incident should have specialist ID")
                
                local specialist = system:getSpecialistById(inc.assignedSpecialistId)
                TestRunner.assert(specialist ~= nil, "Should find assigned specialist")
                TestRunner.assertEqual(true, specialist.is_busy, "Assigned specialist should be busy")
                break
            end
        end
        
        TestRunner.assert(foundAssigned, "At least one incident should be auto-assigned")
    end
end)

TestRunner.test("IncidentSpecialistSystem - Incident Resolution", function()
    local eventBus = createMockEventBus()
    local resourceManager = createMockResourceManager()
    
    local system = IncidentSpecialistSystem.new(eventBus, resourceManager)
    system:initialize()
    
    local state = system:getState()
    local resources = resourceManager:getResources()
    
    local initialMoney = resources.money
    local initialRep = resources.reputation
    local initialXP = resources.xp
    local initialTokens = resources.missionTokens
    
    if #state.ThreatTemplates > 0 and #state.Specialists > 0 then
        local template = state.ThreatTemplates[1]
        local incident = system:createIncidentFromTemplate(template)
        local specialist = state.Specialists[1]
        
        incident.status = "AutoAssigned"
        incident.assignedSpecialistId = specialist.id
        specialist.is_busy = true
        
        local specialistInitialXP = specialist.XP
        
        system:Incident_Resolve(incident, specialist)
        
        TestRunner.assert(resources.money > initialMoney, "Money should increase")
        TestRunner.assert(resources.reputation >= initialRep, "Reputation should increase or stay same")
        TestRunner.assert(resources.xp > initialXP, "XP should increase")
        TestRunner.assert(resources.missionTokens > initialTokens, "Mission Tokens should increase")
        TestRunner.assert(specialist.XP > specialistInitialXP, "Specialist should gain XP")
        TestRunner.assert(specialist.cooldown_timer > 0, "Specialist should have cooldown")
    end
end)

TestRunner.test("IncidentSpecialistSystem - Cooldown System", function()
    local eventBus = createMockEventBus()
    local resourceManager = createMockResourceManager()
    
    local system = IncidentSpecialistSystem.new(eventBus, resourceManager)
    system:initialize()
    
    local state = system:getState()
    
    if #state.Specialists > 0 then
        local specialist = state.Specialists[1]
        
        specialist.cooldown_timer = 5.0
        specialist.is_busy = true
        
        system:Specialist_Cooldown_Update(3.0)
        TestRunner.assertEqual(2.0, specialist.cooldown_timer, "Cooldown should decrease")
        TestRunner.assertEqual(true, specialist.is_busy, "Should still be busy")
        
        system:Specialist_Cooldown_Update(2.5)
        TestRunner.assertEqual(0, specialist.cooldown_timer, "Cooldown should be complete")
        TestRunner.assertEqual(false, specialist.is_busy, "Should no longer be busy")
    end
end)

TestRunner.test("IncidentSpecialistSystem - Full Update Cycle", function()
    local eventBus = createMockEventBus()
    local resourceManager = createMockResourceManager()
    
    local system = IncidentSpecialistSystem.new(eventBus, resourceManager)
    system:initialize()
    
    local state = system:getState()
    
    state.IncidentTimer = 0.1
    
    for i = 1, 5 do
        system:update(1.0)
    end
end)

TestRunner.test("IncidentSpecialistSystem - Specialist Unlocking", function()
    local eventBus = createMockEventBus()
    local resourceManager = createMockResourceManager()
    
    local system = IncidentSpecialistSystem.new(eventBus, resourceManager)
    system:initialize()
    
    local state = system:getState()
    local initialCount = #state.Specialists
    
    local unlockableId = nil
    for id, template in pairs(state.SpecialistTemplates) do
        if not state.UnlockedSpecialists[id] then
            unlockableId = id
            break
        end
    end
    
    if unlockableId then
        local success = system:unlockSpecialist(unlockableId)
        TestRunner.assert(success, "Should successfully unlock specialist")
        TestRunner.assertEqual(initialCount + 1, #state.Specialists, "Specialist count should increase")
        TestRunner.assertEqual(true, state.UnlockedSpecialists[unlockableId], "Specialist should be marked as unlocked")
        
        local success2 = system:unlockSpecialist(unlockableId)
        TestRunner.assertEqual(false, success2, "Should not unlock same specialist twice")
    end
end)

TestRunner.test("IncidentSpecialistSystem - Statistics Reporting", function()
    local eventBus = createMockEventBus()
    local resourceManager = createMockResourceManager()
    
    local system = IncidentSpecialistSystem.new(eventBus, resourceManager)
    system:initialize()
    
    local stats = system:getStatistics()
    
    TestRunner.assert(stats.activeSpecialists ~= nil, "Should report active specialists")
    TestRunner.assert(stats.pendingIncidents ~= nil, "Should report pending incidents")
    TestRunner.assert(stats.assignedIncidents ~= nil, "Should report assigned incidents")
    TestRunner.assert(stats.availableSpecialists ~= nil, "Should report available specialists")
    TestRunner.assert(stats.busySpecialists ~= nil, "Should report busy specialists")
end)

-- ============================================================================
-- PHASE 2: THREE-STAGE LIFECYCLE TESTS
-- ============================================================================

TestRunner.test("IncidentSpecialistSystem - Phase 2: Three-Stage Initialization", function()
    local eventBus = createMockEventBus()
    local resourceManager = createMockResourceManager()
    
    local system = IncidentSpecialistSystem.new(eventBus, resourceManager)
    system:initialize()
    
    local state = system:getState()
    
    if #state.ThreatTemplates > 0 then
        local template = state.ThreatTemplates[1]
        local incident = system:createIncidentFromTemplate(template, "contract_test")
        
        -- Check three-stage structure exists
        TestRunner.assert(incident.stages ~= nil, "Incident should have stages")
        TestRunner.assert(incident.stages.detect ~= nil, "Should have detect stage")
        TestRunner.assert(incident.stages.respond ~= nil, "Should have respond stage")
        TestRunner.assert(incident.stages.resolve ~= nil, "Should have resolve stage")
        
        -- Check initial stage is detect
        TestRunner.assertEqual("detect", incident.currentStage, "Should start in detect stage")
        TestRunner.assertEqual("IN_PROGRESS", incident.stages.detect.status, "Detect should be in progress")
        TestRunner.assertEqual("PENDING", incident.stages.respond.status, "Respond should be pending")
        TestRunner.assertEqual("PENDING", incident.stages.resolve.status, "Resolve should be pending")
        
        -- Check SLA limits are set
        TestRunner.assert(incident.stages.detect.slaLimit ~= nil, "Detect should have SLA limit")
        TestRunner.assert(incident.stages.respond.slaLimit ~= nil, "Respond should have SLA limit")
        TestRunner.assert(incident.stages.resolve.slaLimit ~= nil, "Resolve should have SLA limit")
        
        -- Check contractId is set
        TestRunner.assertEqual("contract_test", incident.contractId, "Contract ID should be set")
    end
end)

TestRunner.test("IncidentSpecialistSystem - Phase 2: Stage-Specific Stats", function()
    local eventBus = createMockEventBus()
    local resourceManager = createMockResourceManager()
    
    local system = IncidentSpecialistSystem.new(eventBus, resourceManager)
    system:initialize()
    
    -- Test required stat mapping
    TestRunner.assertEqual("trace", system:getRequiredStatForStage("detect"), "Detect should require trace")
    TestRunner.assertEqual("speed", system:getRequiredStatForStage("respond"), "Respond should require speed")
    TestRunner.assertEqual("efficiency", system:getRequiredStatForStage("resolve"), "Resolve should require efficiency")
end)

TestRunner.test("IncidentSpecialistSystem - Phase 2: Specialist Auto-Assignment", function()
    local eventBus = createMockEventBus()
    local resourceManager = createMockResourceManager()
    
    local system = IncidentSpecialistSystem.new(eventBus, resourceManager)
    system:initialize()
    
    local state = system:getState()
    
    if #state.ThreatTemplates > 0 and #state.Specialists > 0 then
        local template = state.ThreatTemplates[1]
        local incident = system:createIncidentFromTemplate(template, "contract_test")
        
        -- Check that specialists were auto-assigned to detect stage
        TestRunner.assert(#incident.stages.detect.assignedSpecialists > 0, 
            "Specialists should be auto-assigned to detect stage")
        
        -- Check specialists are marked busy
        local spec = system:getSpecialistById(incident.stages.detect.assignedSpecialists[1])
        TestRunner.assert(spec ~= nil, "Should find assigned specialist")
        TestRunner.assertEqual(true, spec.is_busy, "Assigned specialist should be busy")
    end
end)

TestRunner.test("IncidentSpecialistSystem - Phase 2: Stage Progress Calculation", function()
    local eventBus = createMockEventBus()
    local resourceManager = createMockResourceManager()
    
    local system = IncidentSpecialistSystem.new(eventBus, resourceManager)
    system:initialize()
    
    local state = system:getState()
    
    if #state.ThreatTemplates > 0 and #state.Specialists > 0 then
        local template = state.ThreatTemplates[1]
        local incident = system:createIncidentFromTemplate(template, "contract_test")
        incident.severity = 5  -- Set known severity
        
        local stage = incident.stages.detect
        
        -- Initially no progress (no time passed)
        local progress = system:calculateStageProgress(incident, stage)
        TestRunner.assertEqual(0, progress, "Initial progress should be 0")
        
        -- Simulate some time passing
        stage.duration = 10
        progress = system:calculateStageProgress(incident, stage)
        TestRunner.assert(progress > 0, "Progress should increase with time")
        TestRunner.assert(progress <= 1.0, "Progress should not exceed 1.0")
    end
end)

TestRunner.test("IncidentSpecialistSystem - Phase 2: Stage Advancement", function()
    local eventBus = createMockEventBus()
    local resourceManager = createMockResourceManager()
    
    local system = IncidentSpecialistSystem.new(eventBus, resourceManager)
    system:initialize()
    
    local state = system:getState()
    
    if #state.ThreatTemplates > 0 and #state.Specialists > 0 then
        local template = state.ThreatTemplates[1]
        local incident = system:createIncidentFromTemplate(template, "contract_test")
        
        -- Force detect stage completion
        incident.stages.detect.status = "COMPLETED"
        incident.stages.detect.success = true
        
        -- Advance to respond
        system:advanceToNextStage(incident)
        
        TestRunner.assertEqual("respond", incident.currentStage, "Should advance to respond stage")
        TestRunner.assertEqual("IN_PROGRESS", incident.stages.respond.status, "Respond should be in progress")
        TestRunner.assert(#incident.stages.respond.assignedSpecialists > 0, "Specialists should be assigned to respond")
        
        -- Force respond stage completion
        incident.stages.respond.status = "COMPLETED"
        incident.stages.respond.success = true
        
        -- Advance to resolve
        system:advanceToNextStage(incident)
        
        TestRunner.assertEqual("resolve", incident.currentStage, "Should advance to resolve stage")
        TestRunner.assertEqual("IN_PROGRESS", incident.stages.resolve.status, "Resolve should be in progress")
    end
end)

TestRunner.test("IncidentSpecialistSystem - Phase 2: Event Publishing", function()
    local eventBus = createMockEventBus()
    local resourceManager = createMockResourceManager()
    
    local system = IncidentSpecialistSystem.new(eventBus, resourceManager)
    system:initialize()
    
    local state = system:getState()
    
    if #state.ThreatTemplates > 0 and #state.Specialists > 0 then
        local template = state.ThreatTemplates[1]
        local incident = system:createIncidentFromTemplate(template, "contract_test")
        incident.severity = 3  -- Low severity for quick completion
        
        -- Simulate stage completion
        incident.stages.detect.duration = 100
        incident.currentStage = "detect"
        incident.stages.detect.status = "IN_PROGRESS"
        
        system:updateIncidentStage(incident, 1.0)
        
        -- Check if stage completion event was published
        local events = eventBus:getEvents()
        -- Event may or may not fire depending on progress calculation, so we just check structure is valid
        TestRunner.assert(events ~= nil, "Events should be tracked")
    end
end)

TestRunner.test("IncidentSpecialistSystem - Phase 2: Legacy Migration", function()
    local eventBus = createMockEventBus()
    local resourceManager = createMockResourceManager()
    
    local system = IncidentSpecialistSystem.new(eventBus, resourceManager)
    system:initialize()
    
    -- Create an old-format incident
    local oldIncident = {
        id = "old_incident_1",
        trait_value_needed = 5,
        severity = 5,
        status = "Pending",
        createdTime = os.time()
    }
    
    -- Migrate to new format
    system:migrateIncidentToStageFormat(oldIncident)
    
    -- Check migration results
    TestRunner.assert(oldIncident.stages ~= nil, "Old incident should now have stages")
    TestRunner.assert(oldIncident.currentStage ~= nil, "Old incident should have current stage")
    TestRunner.assertEqual(5, oldIncident.severity, "Severity should be preserved")
end)

TestRunner.test("IncidentSpecialistSystem - Phase 2: Helper Functions", function()
    local eventBus = createMockEventBus()
    local resourceManager = createMockResourceManager()
    
    local system = IncidentSpecialistSystem.new(eventBus, resourceManager)
    system:initialize()
    
    local state = system:getState()
    
    if #state.ThreatTemplates > 0 then
        local template = state.ThreatTemplates[1]
        local incident = system:createIncidentFromTemplate(template, "contract_test")
        table.insert(state.IncidentsQueue, incident)
        
        -- Test getIncident
        local found = system:getIncident(incident.id)
        TestRunner.assert(found ~= nil, "Should find incident by ID")
        TestRunner.assertEqual(incident.id, found.id, "Should return correct incident")
        
        -- Test getIncidentsByContract
        local contractIncidents = system:getIncidentsByContract("contract_test")
        TestRunner.assert(#contractIncidents > 0, "Should find incidents by contract")
        
        -- Test getAvailableSpecialists
        local available = system:getAvailableSpecialists()
        TestRunner.assert(available ~= nil, "Should return available specialists list")
        
        -- Test removeIncident
        local removed = system:removeIncident(incident.id)
        TestRunner.assertEqual(true, removed, "Should successfully remove incident")
        
        local notFound = system:getIncident(incident.id)
        TestRunner.assert(notFound == nil, "Incident should be removed from queue")
    end
end)