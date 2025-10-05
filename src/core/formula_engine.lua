-- FormulaEngine - Safe evaluation of data-driven formulas
-- Enables designers to define complex calculations in JSON
-- Part of the AWESOME Backend Architecture

local FormulaEngine = {}

-- Safe math environment for formula evaluation
local function createSafeEnv()
    return require("src.systems.formula_engine")

end

return FormulaEngine