-- ECS Resource System - Pure ECS Implementation
-- Manages player resources using Entity-Component-System architecture
-- Replaces legacy ResourceManager with pure ECS approach

local System = require("src.ecs.system")
local ECSResourceSystem = setmetatable({}, {__index = System})
ECSResourceSystem.__index = ECSResourceSystem

-- Create new ECS resource system
function ECSResourceSystem.new(world, eventBus)
    local self = System.new("ECSResourceSystem", world, eventBus)
    -- ECS Resource System - Fortress-inspired resource orchestration for the ECS world
    -- Reimagines ResourceManager concepts (generation, multipliers, storage, categories)
    -- using pure entity-component logic so every gameplay element can bolt on cleanly.

    local System = require("src.ecs.system")

    local DEFAULT_RESOURCES = {
        money = {
            category = "primary",
            initial = 1500,
            generation = 2.0,
            storage = nil,
            description = "Currency for hiring, equipment, and facility growth"
        },
        reputation = {
            category = "primary",
            initial = 0,
            generation = 0,
            storage = nil,
            description = "Unlocks higher-tier contracts and factions"
        },
        xp = {
            category = "primary",
            initial = 0,
            generation = 0,
            storage = nil,
            description = "Company experience used for progression"
        },
        missionTokens = {
            category = "primary",
            initial = 0,
            generation = 0,
            storage = nil,
            description = "Rare Crisis Mode currency for elite upgrades"
        },
        energy = {
            category = "secondary",
            initial = 100,
            generation = 6,
            storage = 100,
            description = "Action energy for specialist deployments"
        },
        specialists = {
            category = "secondary",
            initial = 1,
            generation = 0,
            storage = nil,
            description = "Total specialists on the payroll"
        },
        contracts = {
            category = "derived",
            initial = 0,
            generation = 0,
            storage = nil,
            description = "Active contracts providing revenue"
        }
    }

    local RESOURCE_EVENTS = {
        addSingle = "add_resource",
        addBatch = "add_resources",
        spendSingle = "spend_resource",
        spendBatch = "spend_resources",
        reset = "resources_reset",
        sync = "resource_sync"
    }

    local ECSResourceSystem = setmetatable({}, {__index = System})
    ECSResourceSystem.__index = ECSResourceSystem

    local function deepCopy(tbl)
        local copy = {}
        for k, v in pairs(tbl or {}) do
            if type(v) == "table" then
                copy[k] = deepCopy(v)
            else
                copy[k] = v
            end
        end
        return copy
    end

    local function ensureTables(component)
        component.values = component.values or {}
        component.generation = component.generation or {}
        component.multipliers = component.multipliers or {}
        component.storage = component.storage or {}
        component.categories = component.categories or {}
        component.passiveSources = component.passiveSources or {}
        component.lastTick = component.lastTick or ((love and love.timer and love.timer.getTime()) or os.clock())
        component.totalGenerated = component.totalGenerated or {}
    end

    -- Create new ECS resource system
    function ECSResourceSystem.new(world, eventBus)
        local self = System.new("ECSResourceSystem", world, eventBus)
        setmetatable(self, ECSResourceSystem)

        self:setRequiredComponents({"resources"})

        self.primaryEntity = nil
        self.offlineGraceSeconds = 30
        self.notificationsEnabled = true

        return self
    end

    -- Initialize the system and wire up event listeners
    function ECSResourceSystem:initialize()
        System.initialize(self)

        if self.eventBus then
            self.eventBus:subscribe(RESOURCE_EVENTS.addSingle, function(data)
                if not data then return end
                local target = data.entityId or self:getPrimaryResourceEntity()
                if target then
                    self:addResources(target, {[data.resource] = data.amount}, data.context)
                end
            end)

            self.eventBus:subscribe(RESOURCE_EVENTS.addBatch, function(data)
                if not data or not data.resources then return end
                local target = data.entityId or self:getPrimaryResourceEntity()
                if target then
                    self:addResources(target, data.resources, data.context)
                end
            end)

            self.eventBus:subscribe(RESOURCE_EVENTS.spendSingle, function(data)
                if not data then return end
                local target = data.entityId or self:getPrimaryResourceEntity()
                if target then
                    self:spendResources(target, {[data.resource] = data.amount}, data.context)
                end
            end)

            self.eventBus:subscribe(RESOURCE_EVENTS.spendBatch, function(data)
                if not data or not data.resources then return end
                local target = data.entityId or self:getPrimaryResourceEntity()
                if target then
                    self:spendResources(target, data.resources, data.context)
                end
            end)

            self.eventBus:subscribe("contract_completed", function(data)
                if not data or not data.rewards then return end
                self:applyContractRewards(data.rewards)
            end)

            self.eventBus:subscribe("specialist_hired", function()
                local target = self:getPrimaryResourceEntity()
                if target then
                    self:incrementResource(target, "specialists", 1, {source = "team"})
                end
            end)

            self.eventBus:subscribe("specialist_departed", function()
                local target = self:getPrimaryResourceEntity()
                if target then
                    self:incrementResource(target, "specialists", -1, {source = "team"})
                end
            end)

            self.eventBus:subscribe("game_session_resumed", function()
                local target = self:getPrimaryResourceEntity()
                if target then
                    self:calculateOfflineProgress(target)
                end
            end)
        end

        self:seedDefaultResources()
    end

    function ECSResourceSystem:getPrimaryResourceEntity()
        if self.primaryEntity and self.world:entityExists(self.primaryEntity) then
            return self.primaryEntity
        end

        local entities = self:getMatchingEntities()
        if #entities > 0 then
            self.primaryEntity = entities[1]
            return self.primaryEntity
        end
        return nil
    end

    function ECSResourceSystem:seedDefaultResources()
        local entityId = self:getPrimaryResourceEntity()
        if not entityId then
            entityId = self.world:createEntity()
            self.world:addComponent(entityId, "resources", {})
            self.primaryEntity = entityId
        end

        local component = self:getComponent(entityId, "resources")
        ensureTables(component)

        for name, def in pairs(DEFAULT_RESOURCES) do
            self:registerResourceDefinition(entityId, name, def)
            if component.values[name] == nil then
                component.values[name] = def.initial
            end
        end

        self:calculateOfflineProgress(entityId)
    end

    function ECSResourceSystem:registerResourceDefinition(entityId, resourceName, definition)
        local component = self:getComponent(entityId, "resources")
        if not component then return end

        ensureTables(component)

        component.generation[resourceName] = definition.generation or component.generation[resourceName] or 0
        component.multipliers[resourceName] = component.multipliers[resourceName] or 1.0
        component.storage[resourceName] = definition.storage
        component.categories[resourceName] = definition.category or "primary"
        component.values[resourceName] = component.values[resourceName]
        component.descriptions = component.descriptions or {}
        component.descriptions[resourceName] = definition.description
    end

    -- Passive generation + streak tracking per entity
    function ECSResourceSystem:processEntity(entityId, dt)
        local component = self:getComponent(entityId, "resources")
        if not component then return end

        ensureTables(component)

        local now = (love and love.timer and love.timer.getTime()) or os.clock()
        local deltaSeconds = dt or (now - component.lastTick)
        component.lastTick = now

        for resourceName, baseRate in pairs(component.generation) do
            local rate = baseRate * (component.multipliers[resourceName] or 1.0)
            if rate ~= 0 then
                local gain = rate * deltaSeconds
                self:incrementResource(entityId, resourceName, gain, {source = "generation"})
                component.totalGenerated[resourceName] = (component.totalGenerated[resourceName] or 0) + gain
            end
        end
    end

    function ECSResourceSystem:incrementResource(entityId, resourceName, amount, context)
        if amount == 0 then return 0 end

        local component = self:getComponent(entityId, "resources")
        if not component or not component.values then return 0 end

        ensureTables(component)

        local current = component.values[resourceName] or 0
        local storage = component.storage[resourceName]
        local newValue = current + amount

        if storage then
            if amount > 0 then
                newValue = math.min(newValue, storage)
            else
                newValue = math.max(newValue, 0)
            end
        end

        component.values[resourceName] = newValue

        if self.eventBus then
            self.eventBus:publish("resource_changed", {
                entityId = entityId,
                resource = resourceName,
                newValue = newValue,
                delta = amount,
                category = component.categories[resourceName],
                context = context
            })
        end

        return newValue - current
    end

    function ECSResourceSystem:addResources(entityId, bundle, context)
        local actual = {}
        for resourceName, amount in pairs(bundle or {}) do
            if amount and amount ~= 0 then
                actual[resourceName] = self:incrementResource(entityId, resourceName, amount, context)
            end
        end

        if self.eventBus then
            self.eventBus:publish("resources_added", {
                entityId = entityId,
                added = actual,
                context = context
            })
        end

        return actual
    end

    function ECSResourceSystem:spendResources(entityId, costs, context)
        local component = self:getComponent(entityId, "resources")
        if not component then return false end
        ensureTables(component)

        if not self:canAfford(entityId, costs) then
            return false
        end

        local spent = {}
        for resourceName, amount in pairs(costs or {}) do
            local delta = self:incrementResource(entityId, resourceName, -amount, context)
            spent[resourceName] = -delta
        end

        if self.eventBus then
            self.eventBus:publish("resources_spent", {
                entityId = entityId,
                spent = spent,
                context = context
            })
        end

        return true
    end

    function ECSResourceSystem:canAfford(entityId, costs)
        local component = self:getComponent(entityId, "resources")
        if not component or not component.values then
            return false
        end

        for resourceName, amount in pairs(costs or {}) do
            if amount > 0 then
                if (component.values[resourceName] or 0) < amount then
                    return false
                end
            end
        end
        return true
    end

    function ECSResourceSystem:getResources(entityId)
        local component = self:getComponent(entityId, "resources")
        if not component then return {} end
        ensureTables(component)
        return deepCopy(component.values)
    end

    function ECSResourceSystem:getGenerationRates(entityId)
        local component = self:getComponent(entityId, "resources")
        if not component then return {} end
        ensureTables(component)
        local rates = {}
        for resourceName, rate in pairs(component.generation) do
            rates[resourceName] = rate * (component.multipliers[resourceName] or 1.0)
        end
        return rates
    end

    function ECSResourceSystem:setGeneration(entityId, resourceName, rate)
        local component = self:getComponent(entityId, "resources")
        if not component then return end
        ensureTables(component)
        component.generation[resourceName] = rate

        if self.eventBus then
            self.eventBus:publish("resource_generation_changed", {
                entityId = entityId,
                resource = resourceName,
                rate = rate
            })
        end
    end

    function ECSResourceSystem:addGeneration(entityId, resourceName, delta)
        local component = self:getComponent(entityId, "resources")
        if not component then return end
        ensureTables(component)
        component.generation[resourceName] = (component.generation[resourceName] or 0) + delta

        if self.eventBus then
            self.eventBus:publish("resource_generation_changed", {
                entityId = entityId,
                resource = resourceName,
                rate = component.generation[resourceName]
            })
        end
    end

    function ECSResourceSystem:addMultiplier(entityId, resourceName, delta)
        local component = self:getComponent(entityId, "resources")
        if not component then return end
        ensureTables(component)
        component.multipliers[resourceName] = (component.multipliers[resourceName] or 1.0) + delta

        if self.eventBus then
            self.eventBus:publish("resource_multiplier_changed", {
                entityId = entityId,
                resource = resourceName,
                multiplier = component.multipliers[resourceName]
            })
        end
    end

    function ECSResourceSystem:setMultiplier(entityId, resourceName, value)
        local component = self:getComponent(entityId, "resources")
        if not component then return end
        ensureTables(component)
        component.multipliers[resourceName] = value

        if self.eventBus then
            self.eventBus:publish("resource_multiplier_changed", {
                entityId = entityId,
                resource = resourceName,
                multiplier = value
            })
        end
    end

    function ECSResourceSystem:calculateOfflineProgress(entityId)
        local idleComponent = self.world:getComponent(entityId, "idleState")
        local resourceComponent = self:getComponent(entityId, "resources")
        if not idleComponent or not resourceComponent then return end

        local now = (love and love.timer and love.timer.getTime()) or os.clock()
        local lastSave = idleComponent.lastSeen or now
        idleComponent.lastSeen = now

        local offlineSeconds = now - lastSave
        if offlineSeconds <= self.offlineGraceSeconds then
            return
        end

        ensureTables(resourceComponent)

        local totalMoney = 0
        for resourceName, rate in pairs(resourceComponent.generation) do
            local generated = rate * (resourceComponent.multipliers[resourceName] or 1.0) * offlineSeconds
            if generated > 0 then
                local applied = self:incrementResource(entityId, resourceName, generated, {source = "offline", seconds = offlineSeconds})
                if resourceName == "money" then
                    totalMoney = totalMoney + applied
                end
            end
        end

        idleComponent.offlineSummary = {
            seconds = offlineSeconds,
            moneyEarned = totalMoney
        }

        if self.eventBus then
            self.eventBus:publish("offline_progress_applied", idleComponent.offlineSummary)
        end
    end

    function ECSResourceSystem:recordSessionSnapshot(entityId)
        local idleComponent = self.world:getComponent(entityId, "idleState")
        if not idleComponent then
            self.world:addComponent(entityId, "idleState", {lastSeen = (love and love.timer and love.timer.getTime()) or os.clock()})
        else
            idleComponent.lastSeen = (love and love.timer and love.timer.getTime()) or os.clock()
        end
    end

    function ECSResourceSystem:applyContractRewards(rewards)
        if not rewards then return end
        local target = self:getPrimaryResourceEntity()
        if not target then return end
        self:addResources(target, rewards, {source = "contract"})
    end

    function ECSResourceSystem:getTotalResources()
        local totals = {}
        for _, entityId in ipairs(self:getMatchingEntities()) do
            local component = self:getComponent(entityId, "resources")
            if component and component.values then
                for resourceName, amount in pairs(component.values) do
                    totals[resourceName] = (totals[resourceName] or 0) + amount
                end
            end
        end
        return totals
    end

    function ECSResourceSystem:getStats()
        local entityId = self:getPrimaryResourceEntity()
        local component = entityId and self:getComponent(entityId, "resources") or nil
        local generation = entityId and self:getGenerationRates(entityId) or {}
        local totals = self:getTotalResources()

        return {
            entityCount = #self:getMatchingEntities(),
            totals = totals,
            generation = generation,
            multipliers = component and deepCopy(component.multipliers) or {},
            storage = component and deepCopy(component.storage) or {},
            totalGenerated = component and deepCopy(component.totalGenerated) or {}
        }
    end

    function ECSResourceSystem:resetResources(entityId, newValues)
        local component = self:getComponent(entityId, "resources")
        if not component then return false end
        ensureTables(component)

        component.values = deepCopy(newValues or {})

        if self.eventBus then
            self.eventBus:publish(RESOURCE_EVENTS.reset, {
                entityId = entityId,
                values = deepCopy(component.values)
            })
        end

        return true
    end

    function ECSResourceSystem:syncState(entityId)
        local component = self:getComponent(entityId, "resources")
        if not component or not self.eventBus then return end

        self.eventBus:publish(RESOURCE_EVENTS.sync, {
            entityId = entityId,
            values = deepCopy(component.values),
            generation = deepCopy(component.generation),
            multipliers = deepCopy(component.multipliers)
        })
    end

    return ECSResourceSystem