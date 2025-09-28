-- Compatibility shim for legacy tests that require 'src.systems.resource_system'
-- Forwards to the modern ResourceManager implementation at src.core.resource_manager
local ok, rm = pcall(require, 'src.core.resource_manager')
if not ok then
    -- Fallback: try direct require without src prefix
    rm = require('resource_manager')
end
return rm
