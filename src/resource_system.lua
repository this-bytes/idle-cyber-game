-- Compatibility shim for legacy tests: resource_system -> src.core.resource_manager
local ResourceManager = require("src.core.resource_manager")
return ResourceManager
