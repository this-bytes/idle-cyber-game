#!/usr/bin/env lua5.3
-- Create a text-based mockup of the buff UI to show what players would see

print("🔮 Cyberspace Tycoon - Buff System UI Mockup")
print("============================================")
print()

-- Simulate the game UI with active buffs
local function createUIFrame(title, content, width, height)
    width = width or 60
    height = height or 20
    
    local frame = {}
    
    -- Top border
    table.insert(frame, "┌" .. string.rep("─", width - 2) .. "┐")
    
    -- Title
    local titlePadding = math.floor((width - 2 - #title) / 2)
    local titleLine = "│" .. string.rep(" ", titlePadding) .. title .. 
                     string.rep(" ", width - 2 - titlePadding - #title) .. "│"
    table.insert(frame, titleLine)
    table.insert(frame, "├" .. string.rep("─", width - 2) .. "┤")
    
    -- Content
    for _, line in ipairs(content) do
        local contentLine = "│ " .. line .. string.rep(" ", width - 3 - #line) .. "│"
        table.insert(frame, contentLine)
    end
    
    -- Bottom border
    table.insert(frame, "└" .. string.rep("─", width - 2) .. "┘")
    
    return frame
end

-- Create main game window mockup
print("Main Game Window:")
print("================")

local gameContent = {
    "🏢 Cyber Empire Command - SOC Operations Center",
    "",
    "💰 Money: $12,847 (+15.2/sec) [📈 +82% boost]",
    "⭐ Reputation: 234 (+3.1/sec) [😊 +50% boost]", 
    "🎯 XP: 1,847 (+12.8/sec) [⚡ +2x multiplier]",
    "🎖️ Mission Tokens: 23",
    "",
    "📋 Active Contracts: 3/5",
    "🛡️ Threat Level: Low (🔥 -60% reduction)",
    "👥 Specialists: 8/12 (🎖️ +30% efficiency)",
    "",
    "Recent Activity:",
    "✅ Contract 'SecureBank Analysis' completed",
    "🔥 Firewall upgrade installed",
    "⚔️ Crisis 'APT-29 Intrusion' resolved",
    "",
    "[ESC] Menu  [B] Toggle Buffs  [C] Contracts"
}

local gameFrame = createUIFrame("Cyberspace Tycoon v1.0", gameContent, 70, 20)
for _, line in ipairs(gameFrame) do
    print(line)
end

print()

-- Create buff display panel
print("Active Buffs Panel (Press B to toggle):")
print("======================================")

local buffContent = {
    "📈 Contract Efficiency Boost (x2)     4m 23s",
    "   +20% efficiency, +1.2x money multiplier",
    "",
    "🧠 Enhanced Focus (x5)                 2m 17s", 
    "   +50% efficiency, +25% speed, +1.5x XP",
    "",
    "🛡️ Enhanced Security (x3)              8m 45s",
    "   +75% threat reduction, +30 defense",
    "",
    "😊 Client Satisfaction                12m 01s",
    "   +1.3x money, +1.5x reputation",
    "",
    "🏢 Advanced Infrastructure                 ∞",
    "   +5 money/sec, +1 reputation/sec",
    "",
    "🎖️ Elite Training Program                  ∞", 
    "   +30% efficiency, +2 specialist slots",
    "",
    "... +3 more buffs"
}

local buffFrame = createUIFrame("🔮 Active Buffs", buffContent, 50, 18)
for _, line in ipairs(buffFrame) do
    print("    " .. line)  -- Indent to show it's a side panel
end

print()

-- Show effect summary
print("📊 Current Buff Effects Summary:")
print("===============================")
print("💰 Money Generation: +82% multiplier, +5/sec bonus")
print("⭐ Reputation: +50% multiplier, +1/sec bonus") 
print("🎯 XP Gain: +100% multiplier")
print("⚡ Efficiency: +130% total bonus")
print("🛡️ Threat Reduction: 75%")
print("🏃 Speed Bonus: +25%")
print("👥 Team Capacity: +2 specialists")

print()

-- Show recent buff events
print("📨 Recent Buff Events:")
print("=====================")
print("✨ Applied: 📈 Contract Efficiency Boost (from contract completion)")
print("🔻 Removed: ⚡ Research Acceleration (expired)")
print("📚 Stacked: 🧠 Enhanced Focus +2 stacks (from skill training)")
print("🎉 Unlocked: 🕸️ Threat Intelligence Network (achievement reward)")

print()

-- Show controls help
print("🎮 Buff System Controls:")
print("========================")
print("B         - Toggle buff display panel")
print("Click     - Interact with buff panel")
print("R-Click   - Hide/show specific buffs")
print("Hover     - Show detailed buff tooltip")

print()

-- Show gameplay tips
print("💡 Gameplay Tips:")
print("=================")
print("• Complete contracts to gain efficiency boosts")
print("• Resolve crises for defensive bonuses")  
print("• Stack focus buffs for maximum productivity")
print("• Permanent buffs from upgrades last forever")
print("• Rare buffs have powerful unique effects")
print("• Time your activities to maximize buff synergy")

print()
print("🎉 The buff system adds deep RPG-style progression")
print("   to your cybersecurity empire building experience!")