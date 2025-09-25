-- Number formatting utilities
-- Handles display of large numbers and rates

local format = {}

-- Format large numbers with suffixes
function format.number(value, decimals)
    decimals = decimals or 2
    
    if value < 1000 then
        return string.format("%." .. decimals .. "f", value)
    end
    
    local suffixes = {"", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"}
    local tier = math.floor(math.log10(value) / 3)
    
    if tier >= #suffixes then
        tier = #suffixes - 1
    end
    
    local suffix = suffixes[tier + 1]
    local scaled = value / math.pow(1000, tier)
    
    return string.format("%." .. decimals .. "f%s", scaled, suffix)
end

-- Format generation rates (per second)
function format.rate(value, decimals)
    return format.number(value, decimals) .. "/sec"
end

-- Format time durations
function format.time(seconds)
    if seconds < 60 then
        return string.format("%.0fs", seconds)
    elseif seconds < 3600 then
        return string.format("%.0fm %.0fs", math.floor(seconds / 60), seconds % 60)
    else
        local hours = math.floor(seconds / 3600)
        local minutes = math.floor((seconds % 3600) / 60)
        local secs = seconds % 60
        return string.format("%dh %dm %.0fs", hours, minutes, secs)
    end
end

-- Format percentage
function format.percentage(value, decimals)
    decimals = decimals or 1
    return string.format("%." .. decimals .. "f%%", value * 100)
end

return format