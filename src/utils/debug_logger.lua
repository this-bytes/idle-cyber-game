-- Debug Logger
-- Separates debug logging from user-facing messages

local DebugLogger = {}
DebugLogger.__index = DebugLogger

-- Create new debug logger
function DebugLogger.new()
    local self = setmetatable({}, DebugLogger)
    self.enabled = true
    self.debugFile = "debug.log"
    self.maxLogSize = 1000 -- Max lines to keep in memory
    self.logs = {}
    return self
end

-- Log debug message (for developers)
function DebugLogger:log(message, severity, category)
    if not self.enabled then return end
    
    local timestamp = os.date("%H:%M:%S")
    local logEntry = {
        timestamp = timestamp,
        message = message,
        severity = severity or "info",
        category = category or "general"
    }
    
    -- Add to memory logs
    table.insert(self.logs, logEntry)
    
    -- Keep log size manageable
    while #self.logs > self.maxLogSize do
        table.remove(self.logs, 1)
    end
    
    -- Write to debug file if available
    self:writeToFile(logEntry)
end

-- Write log entry to file
function DebugLogger:writeToFile(logEntry)
    -- In a real LÖVE 2D environment, this would use love.filesystem
    -- For now, we'll just write to stdout with a debug prefix
    local logLine = string.format("[%s] [%s] [%s] %s", 
        logEntry.timestamp, 
        logEntry.severity:upper(), 
        logEntry.category:upper(),
        logEntry.message)
    
    -- In development, write to console with DEBUG prefix
    -- In production, this would write to love.filesystem
    io.write("DEBUG: " .. logLine .. "\n")
end

-- Get recent logs
function DebugLogger:getRecentLogs(count)
    count = count or 50
    local startIndex = math.max(1, #self.logs - count + 1)
    local result = {}
    
    for i = startIndex, #self.logs do
        table.insert(result, self.logs[i])
    end
    
    return result
end

-- Clear logs
function DebugLogger:clear()
    self.logs = {}
end

-- Enable/disable debug logging
function DebugLogger:setEnabled(enabled)
    self.enabled = enabled
end

-- Convenience methods for different severity levels
function DebugLogger:info(message, category)
    self:log(message, "info", category)
end

function DebugLogger:warn(message, category)
    self:log(message, "warning", category)
end

function DebugLogger:error(message, category)
    self:log(message, "error", category)
end

function DebugLogger:debug(message, category)
    self:log(message, "debug", category)
end

return DebugLogger