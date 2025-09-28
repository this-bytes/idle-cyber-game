-- Compatibility shim for legacy tests: event_bus -> src.utils.event_bus
local EventBus = require("src.utils.event_bus")
return EventBus
