-- FormulaEngine - Safe evaluation of data-driven formulas
-- Enables designers to define complex calculations in JSON
-- Part of the AWESOME Backend Architecture

local FormulaEngine = {}

-- Safe math environment for formula evaluation
local function createSafeEnv()
    return {
        -- Math functions
        abs = math.abs,
        ceil = math.ceil,
        floor = math.floor,
        max = math.max,
        min = math.min,
        sqrt = math.sqrt,
        log = math.log,
        exp = math.exp,
        sin = math.sin,
        cos = math.cos,
        
        -- Custom game functions
        pow = function(a, b) return a ^ b end,
        clamp = function(val, min, max) 
            return math.max(min, math.min(max, val))
        end,
        lerp = function(a, b, t)
            return a + (b - a) * t
        end,
        
        -- Constants
        pi = math.pi,
        e = math.exp(1),
    }
end

function FormulaEngine.evaluate(formula, variables)
    if type(formula) ~= "string" then
        print("❌ Formula must be a string")
        return 0
    end
    
    -- Create safe environment
    local env = createSafeEnv()
    
    -- Inject variables
    if variables then
        for k, v in pairs(variables) do
            if type(v) == "number" then
                env[k] = v
            end
        end
    end
    
    -- Compile formula
    local func, err = load("return " .. formula, "formula", "t", env)
    
    if not func then
        print("❌ Formula compilation error: " .. tostring(err))
        print("   Formula: " .. formula)
        return 0
    end
    
    -- Execute with error handling
    local success, result = pcall(func)
    
    if not success then
        print("❌ Formula execution error: " .. tostring(result))
        print("   Formula: " .. formula)
        return 0
    end
    
    -- Ensure result is a number
    if type(result) ~= "number" then
        print("❌ Formula must return a number, got: " .. type(result))
        return 0
    end
    
    -- Check for invalid results
    if result ~= result then -- NaN check
        print("❌ Formula returned NaN")
        return 0
    end
    
    if result == math.huge or result == -math.huge then
        print("❌ Formula returned infinity")
        return 0
    end
    
    return result
end

function FormulaEngine.test()
    print("🧪 Testing FormulaEngine...")
    
    local tests = {
        {
            formula = "base * (1 + level * 0.05)",
            vars = {base = 100, level = 5},
            expected = 125
        },
        {
            formula = "base * pow(growth, count)",
            vars = {base = 100, growth = 1.15, count = 3},
            expected = 152.0875
        },
        {
            formula = "min(max_value, base * multiplier)",
            vars = {base = 100, multiplier = 5, max_value = 400},
            expected = 400
        },
        {
            formula = "floor(base * (1 + sqrt(level)))",
            vars = {base = 100, level = 9},
            expected = 400
        },
        {
            formula = "clamp(value, 0, 100)",
            vars = {value = 150},
            expected = 100
        },
        {
            formula = "lerp(min_val, max_val, progress)",
            vars = {min_val = 0, max_val = 100, progress = 0.5},
            expected = 50
        }
    }
    
    local passed = 0
    for i, test in ipairs(tests) do
        local result = FormulaEngine.evaluate(test.formula, test.vars)
        local diff = math.abs(result - test.expected)
        if diff < 0.0001 then
            print("  ✅ Test " .. i .. " passed")
            passed = passed + 1
        else
            print("  ❌ Test " .. i .. " failed")
            print("     Expected: " .. test.expected)
            print("     Got: " .. result)
        end
    end
    
    print("🧪 Tests completed: " .. passed .. "/" .. #tests .. " passed")
    return passed == #tests
end

return FormulaEngine
