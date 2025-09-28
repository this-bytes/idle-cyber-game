local DebugLogger = require('src.utils.debug_logger')

local Notifier = {}

-- Notify via UI if available, otherwise publish on eventBus, otherwise log to debug
function Notifier.notify(eventBus, ui, message, messageType)
    messageType = messageType or 'info'
    if ui and type(ui.showNotification) == 'function' then
        pcall(function() ui:showNotification(message, messageType) end)
        return true
    end

    if eventBus and type(eventBus.publish) == 'function' then
        pcall(function() eventBus:publish('ui_notification', { message = message, type = messageType }) end)
        return true
    end

    -- Fallback: developer debug log so messages are not printed to stdout
    local logger = DebugLogger.new()
    logger:info(message, 'notifier')
    return false
end

return Notifier
