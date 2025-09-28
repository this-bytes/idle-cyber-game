-- Compatibility shim: legacy require 'src.systems.threat_system' -> modern 'src.core.threat_simulation'
local ok, ts = pcall(require, 'src.core.threat_simulation')
if not ok then
    ts = require('threat_simulation')
end
return ts
