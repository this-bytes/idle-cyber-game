#!/usr/bin/env lua5.3
-- Debug the probability system

math.randomseed(os.time())

-- Test the probability logic directly
local choice = {
    effects = {
        chance = {
            { probability = 0.7, effect = { money = 500, reputation = 1 } },
            { probability = 0.3, effect = { money = -200, reputation = -1 } }
        }
    }
}

print("🎲 Testing probability distribution (100 samples):")
local positiveCount = 0
local negativeCount = 0

for i = 1, 100 do
    local random = math.random()
    local totalProbability = 0
    
    for j, outcome in ipairs(choice.effects.chance) do
        totalProbability = totalProbability + outcome.probability
        if random <= totalProbability then
            if outcome.effect.money > 0 then
                positiveCount = positiveCount + 1
            else
                negativeCount = negativeCount + 1
            end
            break
        end
    end
end

print("✅ Positive outcomes (70% expected): " .. positiveCount .. "%")
print("❌ Negative outcomes (30% expected): " .. negativeCount .. "%")

-- Test a few individual rolls
print("\n🎯 Individual test rolls:")
for i = 1, 10 do
    local random = math.random()
    local totalProbability = 0
    
    for j, outcome in ipairs(choice.effects.chance) do
        totalProbability = totalProbability + outcome.probability
        if random <= totalProbability then
            local result = outcome.effect.money > 0 and "POSITIVE" or "NEGATIVE"
            print(string.format("Roll %d: %.3f -> %s (%d money)", i, random, result, outcome.effect.money))
            break
        end
    end
end