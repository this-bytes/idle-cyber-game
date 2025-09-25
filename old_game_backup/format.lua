-- Number Formatting Utilities
-- Handles proper display of large numbers with suffixes (K, M, B, etc.)

local format = {}

-- Number suffixes for large values
local suffixes = {
    [1] = "",           -- 1-999
    [2] = "K",          -- 1,000-999,999 (Thousand)
    [3] = "M",          -- 1,000,000-999,999,999 (Million)
    [4] = "B",          -- 1,000,000,000-999,999,999,999 (Billion)
    [5] = "T",          -- 1,000,000,000,000+ (Trillion)
    [6] = "Qa",         -- Quadrillion
    [7] = "Qi",         -- Quintillion
    [8] = "Sx",         -- Sextillion
    [9] = "Sp",         -- Septillion
    [10] = "Oc",        -- Octillion
    [11] = "No",        -- Nonillion
    [12] = "Dc",        -- Decillion
    [13] = "UDc",       -- Undecillion
    [14] = "DDc",       -- Duodecillion
    [15] = "TDc",       -- Tredecillion
    [16] = "QaDc",      -- Quattuordecillion
    [17] = "QiDc",      -- Quindecillion
    [18] = "SxDc",      -- Sexdecillion
    [19] = "SpDc",      -- Septendecillion
    [20] = "OcDc",      -- Octodecillion
    [21] = "NoDc",      -- Novemdecillion
    [22] = "Vg",        -- Vigintillion
}

-- Format a number with appropriate suffix and precision
function format.number(value, precision)
    precision = precision or 2
    
    if value < 0 then
        return "-" .. format.number(-value, precision)
    end
    
    if value < 1000 then
        -- For numbers less than 1000, show appropriate decimal places
        if value < 10 then
            return string.format("%.2f", value)
        elseif value < 100 then
            return string.format("%.1f", value)
        else
            return string.format("%.0f", value)
        end
    end
    
    -- Determine the appropriate suffix
    local magnitude = 1
    local workingValue = value
    
    while workingValue >= 1000 and magnitude < #suffixes do
        workingValue = workingValue / 1000
        magnitude = magnitude + 1
    end
    
    -- Format the number with appropriate precision
    local formattedNumber
    if workingValue < 10 then
        formattedNumber = string.format("%." .. precision .. "f", workingValue)
    elseif workingValue < 100 then
        formattedNumber = string.format("%." .. math.max(precision - 1, 1) .. "f", workingValue)
    else
        formattedNumber = string.format("%." .. math.max(precision - 2, 0) .. "f", workingValue)
    end
    
    return formattedNumber .. suffixes[magnitude]
end

-- Format a number for rates (per second)
function format.rate(value, precision)
    precision = precision or 1
    local baseFormat = format.number(value, precision)
    return baseFormat .. "/sec"
end

-- Format a number for currency display (Data Bits)
function format.currency(value, precision)
    precision = precision or 2
    local baseFormat = format.number(value, precision)
    return baseFormat .. " DB"
end

-- Format processing power
function format.processingPower(value, precision)
    precision = precision or 2
    local baseFormat = format.number(value, precision)
    return baseFormat .. " PP"
end

-- Format security rating
function format.securityRating(value, precision)
    precision = precision or 1
    local baseFormat = format.number(value, precision)
    return baseFormat .. " SR"
end

-- Format time duration (for upgrades, events, etc.)
function format.time(seconds)
    if seconds < 60 then
        return string.format("%.1fs", seconds)
    elseif seconds < 3600 then
        local minutes = seconds / 60
        return string.format("%.1fm", minutes)
    elseif seconds < 86400 then
        local hours = seconds / 3600
        return string.format("%.1fh", hours)
    else
        local days = seconds / 86400
        return string.format("%.1fd", days)
    end
end

-- Format percentage
function format.percentage(value, precision)
    precision = precision or 1
    return string.format("%." .. precision .. "f%%", value * 100)
end

-- Format multiplier (e.g., 2.5x)
function format.multiplier(value, precision)
    precision = precision or 2
    return string.format("%." .. precision .. "fx", value)
end

-- Format combo multiplier for click mechanics
function format.combo(value)
    if value <= 1.0 then
        return ""
    else
        return string.format("%.1fx", value)
    end
end

-- Utility function to add commas to numbers (for very precise displays)
function format.withCommas(value)
    local formatted = tostring(math.floor(value))
    local k
    
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then
            break
        end
    end
    
    return formatted
end

-- Color coding for different number types
format.colors = {
    dataBits = {0.2, 0.8, 0.2},        -- Green for Data Bits
    processingPower = {0.2, 0.6, 1.0}, -- Blue for Processing Power  
    securityRating = {1.0, 0.6, 0.2},  -- Orange for Security Rating
    positive = {0.2, 0.8, 0.2},        -- Green for positive changes
    negative = {0.8, 0.2, 0.2},        -- Red for negative changes
    neutral = {0.8, 0.8, 0.8},         -- Gray for neutral text
    combo = {1.0, 0.8, 0.2},           -- Yellow/Gold for combos
    critical = {1.0, 0.2, 0.8},        -- Pink/Magenta for critical hits
}

-- Animation-friendly number interpolation
function format.lerp(from, to, progress)
    return from + (to - from) * progress
end

-- Check if a number has changed significantly enough to trigger animation
function format.significantChange(oldValue, newValue, threshold)
    threshold = threshold or 0.01 -- 1% change threshold
    
    if oldValue == 0 then
        return newValue > 0
    end
    
    local change = math.abs(newValue - oldValue) / oldValue
    return change >= threshold
end

-- Format upgrade costs
function format.upgradeCost(cost)
    return "Cost: " .. format.currency(cost)
end

-- Format upgrade effects
function format.upgradeEffect(effectType, value)
    if effectType == "clickPower" then
        return "+" .. format.number(value) .. " DB/click"
    elseif effectType == "generation" then
        return "+" .. format.rate(value)
    elseif effectType == "multiplier" then
        return format.multiplier(value) .. " DB generation"
    else
        return format.number(value)
    end
end

return format