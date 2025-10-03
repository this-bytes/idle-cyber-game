local FormulaEngine = {}

local function createSafeEnv()
    return {
        abs = math.abs, ceil = math.ceil, floor = math.floor, max = math.max, min = math.min,
        sqrt = math.sqrt, log = math.log, exp = math.exp, sin = math.sin, cos = math.cos,
        pow = function(a, b) return a ^ b end,
        clamp = function(val, minv, maxv) return math.max(minv, math.min(maxv, val)) end,
        lerp = function(a, b, t) return a + (b - a) * t end,
        pi = math.pi, e = math.exp(1)
    }
end

function FormulaEngine.evaluate(formula, variables)
    if type(formula) ~= "string" then return 0 end
    local env = createSafeEnv()
    if variables then for k, v in pairs(variables) do if type(v) == "number" then env[k] = v end end end
    local func, err = load("return " .. formula, "formula", "t", env)
    if not func then print("❌ Formula compilation error: " .. tostring(err)); return 0 end
    local success, result = pcall(func)
    if not success then print("❌ Formula execution error: " .. tostring(result)); return 0 end
    if type(result) ~= "number" then print("❌ Formula must return a number, got: " .. type(result)); return 0 end
    if result ~= result then print("❌ Formula returned NaN"); return 0 end
    if result == math.huge or result == -math.huge then print("❌ Formula returned infinity"); return 0 end
    return result
end

function FormulaEngine.test()
    local tests = {
        { formula = "base * (1 + level * 0.05)", vars = {base = 100, level = 5}, expected = 125 },
        { formula = "base * pow(growth, count)", vars = {base = 100, growth = 1.15, count = 3}, expected = 152.0875 },
        { formula = "min(max_value, base * multiplier)", vars = {base = 100, multiplier = 5, max_value = 400}, expected = 400 },
        { formula = "floor(base * (1 + sqrt(level)))", vars = {base = 100, level = 9}, expected = 400 },
        { formula = "clamp(value, 0, 100)", vars = {value = 150}, expected = 100 },
        { formula = "lerp(min_val, max_val, progress)", vars = {min_val = 0, max_val = 100, progress = 0.5}, expected = 50 }
    }
    local passed = 0
    for i, test in ipairs(tests) do
        local result = FormulaEngine.evaluate(test.formula, test.vars)
        if math.abs(result - test.expected) < 0.0001 then passed = passed + 1 end
    end
    return passed == #tests
end

return FormulaEngine
