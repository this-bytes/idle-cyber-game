-- src/core/resource_manager.lua

local ResourceManager = {}
ResourceManager.__index = ResourceManager

function ResourceManager.new(eventBus)
    local instance = setmetatable({}, ResourceManager)
    instance.eventBus = eventBus
    instance.resources = {
        money = 1000,
        reputation = 0,
        xp = 0,
        mission_tokens = 0
    }
    
    if eventBus then
        instance:subscribeToEvents()
    else
        print("CRITICAL ERROR: ResourceManager initialized without an EventBus.")
    end
    
    return instance
end

function ResourceManager:subscribeToEvents()
    self.eventBus:subscribe("spend_resource", function(data)
        self:spendResource(data.resource, data.amount)
    end)
    self.eventBus:subscribe("spend_resources", function(data)
        if not data.costs or type(data.costs) ~= "table" then return end
        for resource, cost in pairs(data.costs) do
            if not self:spendResource(resource, cost) then
                print("WARN: Could not spend " .. cost .. " of " .. resource)
            end
        end
    end)
    self.eventBus:subscribe("add_resource", function(data)
        self:addResource(data.resource, data.amount)
    end)
    self.eventBus:subscribe("contract_completed", function(data)
        if not data.contract or not data.contract.rewards or type(data.contract.rewards) ~= "table" then return end
        for resource, amount in pairs(data.contract.rewards) do
            self:addResource(resource, amount)
        end
    end)
end

function ResourceManager:addResource(name, amount)
    if self.resources[name] ~= nil then
        self.resources[name] = self.resources[name] + amount
        if self.eventBus then
            self.eventBus:publish("resource_changed", { resource = name, new_value = self.resources[name] })
        end
    else
        print("Warning: Resource '" .. name .. "' not found.")
    end
end

function ResourceManager:getResource(name)
    return self.resources[name] or 0
end

function ResourceManager:spendResource(name, amount)
    if self:getResource(name) >= amount then
        self.resources[name] = self.resources[name] - amount
        if self.eventBus then
            self.eventBus:publish("resource_changed", { resource = name, new_value = self.resources[name] })
        end
        return true
    end
    print("Warning: Not enough " .. name .. " to spend " .. amount)
    return false
end

function ResourceManager:getState()
    return self.resources
end

function ResourceManager:loadState(data)
    if data and type(data) == "table" then
        for k, v in pairs(data) do
            if self.resources[k] ~= nil then
                self.resources[k] = v
            end
        end
        if self.eventBus then
            self.eventBus:publish("resource_state_loaded", { resources = self.resources })
        end
    end
end

return ResourceManager