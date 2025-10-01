-- Backwards-compatible shim for ResourceManager
-- Some tests and legacy code require `src.core.resource_manager`; forward to the systems implementation.

return require("src.systems.resource_manager")
