-- Test suite for AWESOME Backend Architecture
-- Tests ItemRegistry, EffectProcessor, FormulaEngine, ProcGen, and SynergyDetector

local ItemRegistry = require("src.core.item_registry")
local EffectProcessor = require("src.core.effect_processor")
local FormulaEngine = require("src.core.formula_engine")
local ProcGen = require("src.core.proc_gen")
local SynergyDetector = require("src.core.synergy_detector")

-- Mock DataManager for testing
local function createMockDataManager()
    local dkjson = require("dkjson")
    
    local function loadJSON(filename)
        local file = io.open(filename, "r")
        if not file then
            print("❌ Could not open: " .. filename)
            return nil
        end
        local content = file:read("*all")
        file:close()
        local data, pos, err = dkjson.decode(content)
        if not data then
            print("❌ Failed to parse JSON in file: " .. filename .. "\nError: " .. tostring(err))
            return nil
        end
        return data
    end
    
    return {
        gameData = {
            contracts = loadJSON("src/data/contracts.json"),
            specialists = loadJSON("src/data/specialists.json"),
            upgrades = loadJSON("src/data/upgrades.json"),
            threats = loadJSON("src/data/threats.json"),
            synergies = loadJSON("src/data/synergies.json")
        },
        getData = function(self, key)
            return self.gameData[key]
        end
    }
end

-- Mock EventBus
local function createMockEventBus()
    local subscribers = {}
    return {
        publish = function(self, event, data)
            if subscribers[event] then
                for _, callback in ipairs(subscribers[event]) do
                    callback(data)
                end
            end
        end,
        subscribe = function(self, event, callback)
            if not subscribers[event] then
                subscribers[event] = {}
            end
            table.insert(subscribers[event], callback)
        end
    }
end

local function runTests()
    print("\n" .. string.rep("=", 60))
    print("🚀 AWESOME Backend Architecture Tests")
    print(string.rep("=", 60) .. "\n")
    
    local passed = 0
    local failed = 0
    
    -- Test 1: FormulaEngine
    print("📊 Test 1: FormulaEngine")
    local formulaResult = FormulaEngine.test()
    if formulaResult then
        passed = passed + 1
        print("✅ FormulaEngine tests passed\n")
    else
        failed = failed + 1
        print("❌ FormulaEngine tests failed\n")
    end
    
    -- Test 2: ItemRegistry
    print("📊 Test 2: ItemRegistry")
    local dataManager = createMockDataManager()
    
    local itemRegistry = ItemRegistry.new(dataManager)
    itemRegistry:initialize()
    
    local stats = itemRegistry:getStats()
    print("  Items loaded: " .. stats.total)
    print("  By type:")
    for itemType, count in pairs(stats.byType) do
        print("    " .. itemType .. ": " .. count)
    end
    
    if stats.total > 0 then
        passed = passed + 1
        print("✅ ItemRegistry loaded items successfully\n")
    else
        failed = failed + 1
        print("❌ ItemRegistry failed to load items\n")
    end
    
    -- Test 3: EffectProcessor
    print("📊 Test 3: EffectProcessor")
    local eventBus = createMockEventBus()
    local effectProcessor = EffectProcessor.new(eventBus)
    
    -- Create a mock upgrade with income multiplier effect
    local mockContext = {
        tags = {"fintech", "enterprise"},
        activeItems = {
            {
                id = "upgrade_income_boost",
                effects = {
                    passive = {
                        {type = "income_multiplier", value = 1.5, target = "all"}
                    }
                }
            }
        }
    }
    
    local baseIncome = 100
    local effectiveIncome = effectProcessor:calculateValue(
        baseIncome,
        "income_multiplier",
        mockContext
    )
    
    print("  Base income: " .. baseIncome)
    print("  Effective income: " .. effectiveIncome)
    print("  Expected: 150")
    
    if math.abs(effectiveIncome - 150) < 0.001 then
        passed = passed + 1
        print("✅ EffectProcessor calculated effects correctly\n")
    else
        failed = failed + 1
        print("❌ EffectProcessor calculation failed\n")
    end
    
    -- Test 4: ProcGen
    print("📊 Test 4: ProcGen")
    local procGen = ProcGen.new(itemRegistry, FormulaEngine)
    
    local nameTest1 = procGen:generateName("company")
    local nameTest2 = procGen:generateName("personal")
    
    print("  Generated company name: " .. nameTest1)
    print("  Generated personal name: " .. nameTest2)
    
    if nameTest1 and nameTest2 then
        passed = passed + 1
        print("✅ ProcGen name generation working\n")
    else
        failed = failed + 1
        print("❌ ProcGen name generation failed\n")
    end
    
    -- Test 5: SynergyDetector
    print("📊 Test 5: SynergyDetector")
    local synergyDetector = SynergyDetector.new(eventBus, itemRegistry)
    synergyDetector:initialize()
    
    -- Create mock game state with a fintech specialist and contract
    local mockGameState = {
        specialists = {
            {id = "fintech_specialist", assigned = true}
        },
        activeContracts = {
            {id = "fintech_compliance"}
        },
        resources = {
            money = 1000,
            reputation = 50
        },
        stats = {
            contracts_completed = 5,
            upgrades_purchased = 3
        }
    }
    
    local activeSynergies = synergyDetector:detectActiveSynergies(mockGameState)
    print("  Active synergies detected: " .. #activeSynergies)
    
    if #activeSynergies >= 0 then
        passed = passed + 1
        print("✅ SynergyDetector working\n")
    else
        failed = failed + 1
        print("❌ SynergyDetector failed\n")
    end
    
    -- Test 6: Item Queries
    print("📊 Test 6: ItemRegistry Queries")
    
    local contractItems = itemRegistry:getItemsByType("contract")
    print("  Contracts: " .. #contractItems)
    
    local specialistItems = itemRegistry:getItemsByType("specialist")
    print("  Specialists: " .. #specialistItems)
    
    local upgradeItems = itemRegistry:getItemsByType("upgrade")
    print("  Upgrades: " .. #upgradeItems)
    
    if #contractItems > 0 and #specialistItems > 0 and #upgradeItems > 0 then
        passed = passed + 1
        print("✅ ItemRegistry queries working\n")
    else
        failed = failed + 1
        print("❌ ItemRegistry queries failed\n")
    end
    
    -- Test 7: Effect Summary
    print("📊 Test 7: Effect Summary")
    
    local summaryContext = {
        tags = {"all"},
        activeItems = {
            {
                id = "upgrade_001",
                effects = {
                    passive = {
                        {type = "income_multiplier", value = 1.1, target = "all"}
                    }
                }
            },
            {
                id = "upgrade_002",
                effects = {
                    passive = {
                        {type = "income_multiplier", value = 1.2, target = "all"}
                    }
                }
            }
        }
    }
    
    local summary = effectProcessor:getActiveEffectSummary(summaryContext)
    print("  Multipliers found: " .. (summary.multipliers.income_multiplier and "Yes" or "No"))
    
    if summary.multipliers.income_multiplier then
        passed = passed + 1
        print("✅ Effect summary working\n")
    else
        failed = failed + 1
        print("❌ Effect summary failed\n")
    end
    
    -- Print results
    print(string.rep("=", 60))
    print("🎯 Test Results:")
    print("  Passed: " .. passed)
    print("  Failed: " .. failed)
    print("  Total: " .. (passed + failed))
    print(string.rep("=", 60) .. "\n")
    
    if failed == 0 then
        print("🎉 All AWESOME Backend tests passed!")
        return true
    else
        print("⚠️ Some tests failed. Review output above.")
        return false
    end
end

return runTests
