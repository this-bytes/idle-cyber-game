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
    self.eventBus:subscribe("resource_spend", function(data)
        self:spendResources(data)
    end)
    self.eventBus:subscribe("resource_add", function(data)
        self:addResources(data)
    end)
    self.eventBus:subscribe("resource_spend_request", function(data)
        self:handleSpendRequest(data)
    end)
    
    -- Threat resolution rewards and penalties
    self.eventBus:subscribe("threat_resolved", function(data)
        self:handleThreatResolution(data)
    end)
end

function ResourceManager:addResources(resourcesToAdd)
    if type(resourcesToAdd) ~= "table" then return end
    for name, amount in pairs(resourcesToAdd) do
        if self.resources[name] ~= nil and type(amount) == "number" then
            self.resources[name] = self.resources[name] + amount
            self.eventBus:publish("resource_changed", { resource = name, newValue = self.resources[name] })
        end
    end
end

function ResourceManager:spendResources(resourcesToSpend)
    if type(resourcesToSpend) ~= "table" then return false end

    -- First, check if all resources can be spent
    for name, amount in pairs(resourcesToSpend) do
        if self:getResource(name) < amount then
            print("Warning: Not enough " .. name .. " to spend " .. amount)
            self.eventBus:publish("insufficient_funds", { resource = name, needed = amount, has = self:getResource(name) })
            return false
        end
    end

    -- If all checks pass, spend the resources
    for name, amount in pairs(resourcesToSpend) do
        self.resources[name] = self.resources[name] - amount
        self.eventBus:publish("resource_changed", { resource = name, newValue = self.resources[name] })
    end
    
    return true
end

function ResourceManager:handleSpendRequest(request)
    if not request or not request.cost or not request.onSuccess or not request.onFailure then
        print("Error: Invalid spend request received.")
        return
    end

    local canAfford = true
    for resource, amount in pairs(request.cost) do
        if self:getResource(resource) < amount then
            canAfford = false
            break
        end
    end

    if canAfford then
        for resource, amount in pairs(request.cost) do
            self.resources[resource] = self.resources[resource] - amount
            self.eventBus:publish("resource_changed", { resource = resource, newValue = self.resources[resource] })
        end
        request.onSuccess()
    else
        request.onFailure()
    end
end

function ResourceManager:handleThreatResolution(data)
    if not data then return end
    
    if data.status == "success" and data.rewards then
        -- Apply rewards for successful threat resolution
        for resource, amount in pairs(data.rewards) do
            if self.resources[resource] ~= nil then
                self.resources[resource] = self.resources[resource] + amount
                self.eventBus:publish("resource_changed", { resource = resource, newValue = self.resources[resource] })
                print("✅ Threat reward: +" .. amount .. " " .. resource)
            end
        end
    elseif data.status == "failure" and data.penalties then
        -- Apply penalties for failed threat resolution
        for resource, amount in pairs(data.penalties) do
            if self.resources[resource] ~= nil then
                self.resources[resource] = math.max(0, self.resources[resource] - amount)
                self.eventBus:publish("resource_changed", { resource = resource, newValue = self.resources[resource] })
                print("❌ Threat penalty: -" .. amount .. " " .. resource)
            end
        end
    end
end

function ResourceManager:getResource(name)
    return self.resources[name] or 0
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