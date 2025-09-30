-- Debug Logger (archived copy)

local DebugLogger = {}
DebugLogger.__index = DebugLogger

function DebugLogger.new()
    local self = setmetatable({}, DebugLogger)
    self.enabled = true
    self.debugFile = "debug.log"
    self.maxLogSize = 1000
    self.logs = {}
    return self
end

function DebugLogger:log(message, severity, category)
    if not self.enabled then return end
    local timestamp = os.date("%H:%M:%S")
    local logEntry = { timestamp = timestamp, message = message, severity = severity or "info", category = category or "general" }
    table.insert(self.logs, logEntry)
    while #self.logs > self.maxLogSize do table.remove(self.logs,1) end
    io.write("DEBUG: ["..logEntry.timestamp.."] ["..logEntry.severity:upper().."] "..logEntry.message.."\n")
end

function DebugLogger:getRecentLogs(count)
    count = count or 50
    local startIndex = math.max(1, #self.logs - count + 1)
    local result = {}
    for i = startIndex, #self.logs do table.insert(result, self.logs[i]) end
    return result
end

function DebugLogger:clear() self.logs = {} end
function DebugLogger:setEnabled(enabled) self.enabled = enabled end
function DebugLogger:info(m,c) self:log(m,"info",c) end
function DebugLogger:warn(m,c) self:log(m,"warning",c) end
function DebugLogger:error(m,c) self:log(m,"error",c) end
function DebugLogger:debug(m,c) self:log(m,"debug",c) end

return DebugLogger
