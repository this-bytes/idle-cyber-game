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
        -- Forwarder: src.core.formula_engine -> src.systems.formula_engine
        return require("src.systems.formula_engine")
        pow = function(a, b) return a ^ b end,
