-- ProcGen - Procedural content generation system
-- Creates unique game items from templates
-- Part of the AWESOME Backend Architecture

local ProcGen = {}
ProcGen.__index = ProcGen

function ProcGen.new(itemRegistry, formulaEngine)
    local self = setmetatable({}, ProcGen)
    self.itemRegistry = itemRegistry
    self.formulaEngine = formulaEngine
    
    -- Name generation parts
    self.nameParts = {
        adjectives = {
            "Agile", "Secure", "Digital", "Cloud", "Quantum", "Cyber",
            "Smart", "Rapid", "Global", "Dynamic", "Elite", "Prime",
            "Advanced", "Innovative", "Strategic", "Tactical", "Unified"
        },
        techNouns = {
            "Systems", "Solutions", "Technologies", "Networks", "Security",
            "Data", "Analytics", "Platforms", "Services", "Labs",
            "Infrastructure", "Operations", "Defense", "Intelligence"
        },
        companySuffixes = {
            "Inc", "Corp", "LLC", "Ltd", "Group", "Partners", "Ventures",
            "Holdings", "Enterprises", "Consulting"
        },
        founderNames = {
            "Alice", "Bob", "Carol", "Dave", "Eve", "Frank", "Grace",
            "Henry", "Iris", "Jack", "Kate", "Leo", "Maya", "Nathan"
        }
    }
    
    -- Initialize random seed
    math.randomseed(os.time())
    
    return self
end

function ProcGen:generateContract(template, playerContext)
    -- Get base template
    local baseItem = self.itemRegistry:getItem(template.base_template)
    if not baseItem then
        print("❌ Base template not found: " .. tostring(template.base_template))
        return nil
    end
    
    -- Deep copy base
    local generated = self:deepCopy(baseItem)
    
    -- Generate unique ID
    generated.id = "proc_" .. self:generateUUID()
    
    -- Apply variations
    if template.variations then
        -- Generate name
        if template.variations.client_name then
            generated.clientName = self:generateName(
                template.variations.client_name
            )
        end
        
        -- Apply risk multiplier
        if template.variations.risk_multiplier then
            local riskMult = self:sampleDistribution(
                template.variations.risk_multiplier
            )
            generated.riskMultiplier = riskMult
            
            -- Scale difficulty
            if generated.riskLevel then
                if riskMult > 1.5 then
                    generated.riskLevel = "EXTREME"
                elseif riskMult > 1.2 then
                    generated.riskLevel = "HIGH"
                elseif riskMult < 0.8 then
                    generated.riskLevel = "LOW"
                end
            end
        end
        
        -- Calculate scaled budget
        if template.variations.budget_scaling and generated.baseBudget then
            local scaledBudget = self.formulaEngine.evaluate(
                template.variations.budget_scaling.formula or "base * risk_multiplier",
                {
                    base = generated.baseBudget,
                    player_level = playerContext.level or 1,
                    risk_multiplier = generated.riskMultiplier or 1.0,
                }
            )
            generated.baseBudget = math.floor(scaledBudget)
        end
    end
    
    return generated
end

function ProcGen:generateName(nameType)
    if nameType == "company" then
        local adj = self.nameParts.adjectives[math.random(#self.nameParts.adjectives)]
        local noun = self.nameParts.techNouns[math.random(#self.nameParts.techNouns)]
        local suffix = self.nameParts.companySuffixes[math.random(#self.nameParts.companySuffixes)]
        
        return adj .. " " .. noun .. " " .. suffix
    elseif nameType == "personal" then
        local name = self.nameParts.founderNames[math.random(#self.nameParts.founderNames)]
        local noun = self.nameParts.techNouns[math.random(#self.nameParts.techNouns)]
        
        return name .. "'s " .. noun
    else
        return "Generated Client"
    end
end

function ProcGen:sampleDistribution(dist)
    if dist.type == "normal" then
        -- Box-Muller transform for normal distribution
        local u1 = math.random()
        local u2 = math.random()
        local z0 = math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2)
        
        local value = (dist.mean or 1.0) + z0 * (dist.stddev or 0.2)
        
        -- Apply bounds
        if dist.min then value = math.max(value, dist.min) end
        if dist.max then value = math.min(value, dist.max) end
        
        return value
    elseif dist.type == "uniform" then
        local min = dist.min or 0
        local max = dist.max or 1
        return min + math.random() * (max - min)
    else
        return dist.mean or 1.0
    end
end

function ProcGen:rollWeightedTable(table)
    -- Calculate total weight
    local totalWeight = 0
    for _, entry in ipairs(table) do
        totalWeight = totalWeight + (entry.weight or 1)
    end
    
    -- Roll random value
    local roll = math.random() * totalWeight
    
    -- Find matching entry
    local accumulated = 0
    for _, entry in ipairs(table) do
        accumulated = accumulated + (entry.weight or 1)
        if roll <= accumulated then
            return entry.value
        end
    end
    
    return nil
end

function ProcGen:generateUUID()
    -- Simple UUID v4 generation
    local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
    return string.gsub(template, "[xy]", function(c)
        local v = (c == "x") and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format("%x", v)
    end)
end

function ProcGen:deepCopy(original)
    local copy
    if type(original) == "table" then
        copy = {}
        for k, v in pairs(original) do
            copy[k] = self:deepCopy(v)
        end
    else
        copy = original
    end
    return copy
end

return ProcGen
