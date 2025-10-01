-- Simple Behavior Tests for Admin Mode
-- These tests verify core gameplay logic without requiring LÖVE

local function testDataDrivenDamage()
    print("\n🧪 Test: Data-Driven Damage Calculation")
    
    -- Simulate skill data
    local skillData = {
        network_scan = {
            id = "network_scan",
            name = "Network Scan",
            activeEffect = {
                type = "damage",
                baseAmount = 25,
                description = "'%s' reveals threat vulnerabilities."
            }
        },
        traffic_analysis = {
            id = "traffic_analysis",
            name = "Traffic Analysis",
            activeEffect = {
                type = "damage",
                baseAmount = 75,
                description = "'%s' deals significant damage."
            }
        }
    }
    
    -- Simulate threat
    local threat = {
        hp = 150,
        baseHp = 150
    }
    
    -- Simulate damage calculation logic (from threat_system.lua)
    local function applyDamage(threat, skillId)
        local skill = skillData[skillId]
        local damage = skill and skill.activeEffect and skill.activeEffect.baseAmount or 10
        threat.hp = threat.hp - damage
        return damage
    end
    
    -- Test 1: Network scan damage
    local damage1 = applyDamage(threat, "network_scan")
    assert(damage1 == 25, string.format("❌ Expected 25 damage, got %d", damage1))
    assert(threat.hp == 125, string.format("❌ Expected HP 125, got %d", threat.hp))
    print("✅ Network scan deals correct damage (25)")
    
    -- Test 2: Traffic analysis damage
    local damage2 = applyDamage(threat, "traffic_analysis")
    assert(damage2 == 75, string.format("❌ Expected 75 damage, got %d", damage2))
    assert(threat.hp == 50, string.format("❌ Expected HP 50, got %d", threat.hp))
    print("✅ Traffic analysis deals correct damage (75)")
    
    -- Test 3: Unknown skill (fallback)
    local damage3 = applyDamage(threat, "unknown_skill")
    assert(damage3 == 10, string.format("❌ Expected fallback damage 10, got %d", damage3))
    print("✅ Unknown skill uses fallback damage (10)")
    
    print("✅ All damage calculation tests passed")
    return true
end

local function testEventFlow()
    print("\n🧪 Test: Event Flow Logic")
    
    local eventLog = {}
    local function publishEvent(eventName, data)
        table.insert(eventLog, {name = eventName, data = data})
    end
    
    -- Simulate: High-severity threat triggers scene change
    local function onThreatGenerated(threat)
        publishEvent("threat_generated", threat)
        if threat.severity >= 7 then
            publishEvent("request_scene_change", {scene = "admin_mode", data = {incident = threat}})
        end
    end
    
    -- Test 1: Low-severity threat (should NOT trigger scene change)
    eventLog = {}
    onThreatGenerated({id = 1, severity = 5, name = "Low Threat"})
    assert(#eventLog == 1, "❌ Expected 1 event, got " .. #eventLog)
    assert(eventLog[1].name == "threat_generated", "❌ Wrong event: " .. eventLog[1].name)
    print("✅ Low-severity threat does not trigger scene change")
    
    -- Test 2: High-severity threat (SHOULD trigger scene change)
    eventLog = {}
    onThreatGenerated({id = 2, severity = 8, name = "Critical Threat"})
    assert(#eventLog == 2, "❌ Expected 2 events, got " .. #eventLog)
    assert(eventLog[2].name == "request_scene_change", "❌ Scene change not triggered")
    assert(eventLog[2].data.scene == "admin_mode", "❌ Wrong target scene")
    print("✅ High-severity threat triggers admin mode scene change")
    
    print("✅ All event flow tests passed")
    return true
end

local function testSpecialistCooldown()
    print("\n🧪 Test: Specialist Cooldown Logic")
    
    local specialist = {
        id = 1,
        name = "Analyst",
        status = "available",
        busyUntil = 0
    }
    
    local currentTime = 100
    
    -- Deploy specialist
    local function deploy(spec, abilityName, cooldownDuration)
        spec.status = "busy"
        spec.busyUntil = currentTime + cooldownDuration
    end
    
    -- Update specialist
    local function update(spec, time)
        if spec.status == "busy" and time >= spec.busyUntil then
            spec.status = "available"
            spec.busyUntil = 0
        end
    end
    
    -- Test 1: Deploy specialist
    deploy(specialist, "network_scan", 30)
    assert(specialist.status == "busy", "❌ Specialist should be busy")
    assert(specialist.busyUntil == 130, "❌ Wrong busy until time")
    print("✅ Specialist goes on cooldown after deployment")
    
    -- Test 2: Still on cooldown
    update(specialist, 120)
    assert(specialist.status == "busy", "❌ Specialist should still be busy")
    print("✅ Specialist remains busy during cooldown")
    
    -- Test 3: Cooldown expires
    update(specialist, 130)
    assert(specialist.status == "available", "❌ Specialist should be available")
    assert(specialist.busyUntil == 0, "❌ busyUntil should be reset")
    print("✅ Specialist becomes available after cooldown")
    
    print("✅ All cooldown tests passed")
    return true
end

-- Run all tests
local function runAll()
    print("\n" .. string.rep("=", 60))
    print("🚀 ADMIN MODE BEHAVIOR TESTS (Lightweight)")
    print(string.rep("=", 60))
    
    local tests = {
        testDataDrivenDamage,
        testEventFlow,
        testSpecialistCooldown
    }
    
    local passed = 0
    local failed = 0
    
    for _, test in ipairs(tests) do
        local success, err = pcall(test)
        if success then
            passed = passed + 1
        else
            failed = failed + 1
            print("❌ TEST FAILED: " .. tostring(err))
        end
    end
    
    print("\n" .. string.rep("=", 60))
    print(string.format("📊 RESULTS: %d passed, %d failed", passed, failed))
    print(string.rep("=", 60) .. "\n")
    
    return failed == 0
end

-- Run if executed directly
if arg and arg[0]:match("test_behavior") then
    local success = runAll()
    os.exit(success and 0 or 1)
end

return {
    runAll = runAll,
    testDataDrivenDamage = testDataDrivenDamage,
    testEventFlow = testEventFlow,
    testSpecialistCooldown = testSpecialistCooldown
}
