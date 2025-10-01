# Complete Engagement Loop — Idle Sec Ops

## Overview
This document maps the complete feedback loop between **Contracts → Crises → Specialists → Reputation → Better Contracts**, creating the addictive core gameplay cycle.

## The Core Loop Visualization

```
┌──────────────────────────────────────────────────────────┐
│                    THE ENGAGEMENT LOOP                    │
└──────────────────────────────────────────────────────────┘

      ┌─────────────┐
      │   Sign      │
      │  Contracts  │──────────┐
      └─────────────┘          │
            ↑                  │ Generate
            │                  │ Crises
            │                  ↓
    ┌───────────────┐    ┌──────────────┐
    │  Better       │    │   Crisis     │
    │  Contracts    │    │   Events     │
    │  Available    │    │   Trigger    │
    └───────────────┘    └──────────────┘
            ↑                  │
            │                  │ Deploy
    ┌───────────────┐          ↓
    │  Reputation   │    ┌──────────────┐
    │   Increases   │←───│  Specialists │
    │  (Perfect     │    │   Respond    │
    │   SLA!)       │    │   to Crisis  │
    └───────────────┘    └──────────────┘
            ↑                  │
            │                  │ Earn XP
            │                  │ & Rewards
            │                  ↓
    ┌───────────────┐    ┌──────────────┐
    │  Crisis       │    │  Specialists │
    │  Resolved!    │────│  Level Up &  │
    │  Rewards!     │    │  Learn Skills│
    └───────────────┘    └──────────────┘
```

## System Integration Details

### 1. Contract System → Crisis Generation

**How Contracts Create Crises:**

```lua
-- Pseudo-code for crisis generation

function updateCrisisGeneration(deltaTime)
    local crisisChance = 0
    
    -- Sum crisis chance from all active contracts
    for _, contract in ipairs(activeContracts) do
        local contractRisk = contract.riskFactor -- 0.5 to 2.0
        local threatModifier = getThreatModifierForContract(contract)
        crisisChance = crisisChance + (contractRisk * threatModifier)
    end
    
    -- Apply global modifiers
    local reputationMultiplier = getReputationThreatMultiplier() -- 1.0 to 2.5
    local defensiveReduction = getDefensiveUpgradeReduction() -- 0.0 to 0.7
    
    crisisChance = crisisChance * reputationMultiplier * (1 - defensiveReduction)
    
    -- Roll for crisis
    if randomChance() < (crisisChance * deltaTime / 60) then
        generateCrisis(selectContractForCrisis())
    end
end
```

**Contract Properties Affecting Crises:**

```
Contract: StartupCo (Tier 1)
├─ Risk Factor: 0.5 (low-value, simple infrastructure)
├─ Threat Types: Tier 1 only (Phishing, Basic Malware)
├─ Crisis Frequency: ~0.5% per minute
└─ Crisis Severity: -20% (easier crises)

Contract: FinTech Inc (Tier 2)
├─ Risk Factor: 1.2 (high-value target, financial data)
├─ Threat Types: Tier 1-2 (+ Ransomware, DDoS)
├─ Crisis Frequency: ~1.2% per minute
└─ Crisis Severity: +10% (harder crises)

Contract: DOD Cyber Command (Tier 4)
├─ Risk Factor: 2.0 (critical infrastructure, nation-state targets)
├─ Threat Types: All tiers (+ APT, Zero-Day)
├─ Crisis Frequency: ~2.0% per minute
└─ Crisis Severity: +60% (hardest crises)
```

**Multi-Contract Synergy:**

```
Single Contract (StartupCo):
├─ Crisis every ~200 minutes
├─ Always Tier 1 threats
└─ Manageable idle experience

Three Contracts (Startup + FinTech + HealthTech):
├─ Combined risk: 0.5 + 1.2 + 1.0 = 2.7
├─ Crisis every ~37 minutes
├─ Threat variety increases
└─ Need team coordination

Five+ Contracts (Mixed tiers):
├─ Combined risk: 5.5+
├─ Crisis every ~18 minutes
├─ Combo events possible (20% chance)
└─ Requires elite team management
```

### 2. Crisis Events → Specialist Deployment

**Crisis Detection & Alert Flow:**

```
Crisis Generated
    ↓
EventBus fires: "crisis_detected"
    ↓
UI displays: "🚨 CRISIS ALERT: [Client] - [Threat Type]"
    ↓
Player sees:
├─ Crisis type and severity
├─ Affected contract
├─ Time limit
├─ Required abilities (if known)
└─ Available specialists

Player Decision:
├─ Deploy specialists (which ones?)
├─ Use automated response (if unlocked)
└─ Prioritize (if multiple crises active)

EventBus fires: "specialists_deployed" → {crisisId, specialistIds[]}
    ↓
Crisis system begins resolution
```

**Specialist Selection Strategy:**

```
Player Considerations:
├─ Does specialist have required abilities?
│   └─ Match abilities to crisis type
├─ Is specialist available (not on cooldown)?
│   └─ Recent deployments = cooldown
├─ What's the specialist's level/effectiveness?
│   └─ Higher level = better outcomes
├─ Does specialist have bonus traits for this crisis?
│   └─ "Malware Specialist" trait for ransomware
└─ Can I spare them from other contracts?
    └─ Managing multiple simultaneous crises

Optimal Strategy Emerges:
├─ Build diverse team (cover all crisis types)
├─ Specialize individuals (max out key abilities)
├─ Rotate specialists (avoid cooldown bottlenecks)
└─ Save elite specialists for Tier 4 crises
```

### 3. Specialist Response → Crisis Resolution

**Crisis Resolution Mechanics:**

```
During Crisis:
├─ Specialists use abilities (consume cooldowns)
├─ Threat integrity (HP) decreases
├─ Stages progress based on actions
├─ Timer counts down (pressure!)
└─ Player makes strategic decisions

Effectiveness Calculation:
├─ Base ability damage/effect
├─ × Specialist level multiplier (1.0x to 2.5x)
├─ × Specialist stats (efficiency, speed, etc.)
├─ × Trait bonuses (if applicable)
├─ × Team synergy (if multiple deployed)
└─ = Final effectiveness

Example:
├─ malware_analysis ability: 120 base damage
├─ Level 8 Analyst: ×1.8 multiplier
├─ Efficiency stat: 2.1x
├─ "Malware Specialist" trait: +30%
├─ Total: 120 × 1.8 × 2.1 × 1.3 = 590 damage!
└─ vs Ransomware HP 300 = OVERKILL (perfect resolution)
```

**Resolution Outcomes:**

```
Perfect Resolution:
├─ All stages completed
├─ Under time limit
├─ Minimal/no damage to client
└─ Maximum rewards!

Success Resolution:
├─ All stages completed
├─ Time limit met (may be close)
├─ Some damage to client (within SLA)
└─ Standard rewards

Partial Resolution:
├─ Some stages incomplete
├─ Time limit exceeded OR
├─ Significant damage (SLA breached)
└─ Reduced rewards, reputation penalty

Failure:
├─ Critical failure (timeout, wrong actions)
├─ Major damage to client
├─ SLA severely breached
└─ Reputation loss, possible contract termination
```

### 4. Crisis Resolution → Rewards & Progression

**Immediate Rewards (End of Crisis):**

```
XP Distribution:
├─ Base XP (based on crisis tier and difficulty)
├─ × Outcome multiplier (1.5x perfect, 1.0x success, 0.5x partial)
├─ × First-time bonus (2.0x if first time resolving this crisis type)
├─ Split among deployed specialists (80%)
├─ Shared with non-deployed specialists (20%)
└─ Bonus XP for ability usage

Money Rewards:
├─ Base crisis reward ($1,000 - $10,000)
├─ × Outcome multiplier
├─ + Contract SLA bonus (if maintained)
└─ Added to player budget

Reputation Changes:
├─ Base reputation (based on crisis tier)
├─ × Outcome multiplier
├─ SLA compliance bonus/penalty
└─ Client satisfaction modifier

Mission Tokens (Rare):
├─ 10% chance on perfect resolution (Tier 2+)
├─ 25% chance on perfect APT/Zero-Day
├─ Guaranteed on combo event resolution
└─ Used for elite unlocks
```

**Specialist Progression:**

```
Specialists gain XP from crisis:
    ↓
Check level-up thresholds
    ↓
If enough XP:
├─ Level up!
├─ +10% all stats
├─ +1 skill point
├─ Fire "specialist_leveled_up" event
└─ Display level-up notification

Skill points can be spent on:
├─ Learning new skills (if prerequisites met)
├─ Leveling existing skills
└─ Saved for expensive Tier 3 skills

XP can also be spent directly:
├─ Pay XP cost to level skill
├─ No skill point needed
└─ Useful for cheap Tier 1/2 skills
```

### 5. Specialist Progression → Better Crisis Outcomes

**How Progression Improves Performance:**

```
Level 1 Analyst vs Level 10 Analyst:

Level 1:
├─ Base stats: 1.0x
├─ basic_analysis Lvl 1: 40 damage
├─ No advanced skills
├─ Total crisis effectiveness: ~50 damage
└─ Can handle Tier 1 crises

Level 10:
├─ Stats: 2.0x (10 levels × 10% each)
├─ basic_analysis Lvl 10: 40 damage × 2.0 stats = 80 damage
├─ malware_analysis Lvl 7: 120 damage × 2.0 = 240 damage
├─ threat_intelligence Lvl 5: Reveals APT patterns
├─ Total crisis effectiveness: ~350+ damage
└─ Can handle Tier 3-4 crises effortlessly

Result:
├─ 7x damage increase
├─ Access to Tier 3 skills
├─ Can solo crises that needed 3 specialists before
└─ Enables taking higher-tier contracts
```

**Skill Synergies Create Power Spikes:**

```
Milestone Progression:

Level 3 - First Tier 2 Skill:
├─ Unlock intermediate abilities
├─ ~2x effectiveness increase
└─ Can handle Tier 2 crises confidently

Level 7 - First Tier 3 Skill:
├─ Unlock advanced abilities
├─ ~5x effectiveness from start
└─ Ready for elite contracts

Level 10 - Multiple Tier 3 Skills:
├─ Specialist specialization complete
├─ ~10x effectiveness from start
└─ Can carry team through Tier 4 crises

Level 15 - Master Skills:
├─ Legendary capabilities
├─ ~20x effectiveness from start
└─ Prestige-ready
```

### 6. Better Performance → Reputation Growth

**Reputation Sources:**

```
Crisis Resolution:
├─ Perfect: +50 to +200 Rep (based on tier)
├─ Success: +25 to +100 Rep
├─ Partial: +5 to +30 Rep
└─ Failure: -20 to -100 Rep

SLA Compliance:
├─ Monthly SLA met: +10 to +75 Rep per contract
├─ Perfect SLA (100%): +50% bonus Rep
└─ SLA breached: -5 to -50 Rep per contract

Contract Milestones:
├─ First month with client: +20 Rep
├─ 6 months with client: +50 Rep
├─ 1 year with client: +100 Rep
└─ Perfect year: +200 Rep

Special Achievements:
├─ First APT resolution: +100 Rep
├─ Zero-Day discovered: +150 Rep
├─ Combo event resolved: +200 Rep
└─ Industry recognition milestones
```

**Reputation Unlock Thresholds:**

```
Reputation: 0-50 (Startup Tier)
├─ Contracts: Tier 1 only (Startups, SMBs)
├─ Threats: Tier 1 (Phishing, Basic Malware)
├─ Specialist Pool: Common specialists only
└─ Status: "Garage SOC"

Reputation: 51-150 (Established Tier)
├─ Contracts: Tier 1-2 (Mid-market companies)
├─ Threats: Tier 2 unlocked (DDoS, Ransomware)
├─ Specialist Pool: Uncommon specialists appear
├─ Facility Upgrade: Office available
└─ Status: "Growing Consultancy"

Reputation: 151-300 (Professional Tier)
├─ Contracts: Tier 2-3 (Large enterprises)
├─ Threats: Tier 3 unlocked (Data Exfil, Insider)
├─ Specialist Pool: Rare specialists appear
├─ Facility Upgrade: Corporate HQ available
└─ Status: "Professional SOC"

Reputation: 301-500 (Elite Tier)
├─ Contracts: Tier 3-4 (Fortune 500, Government)
├─ Threats: Tier 4 unlocked (APT, Zero-Day)
├─ Specialist Pool: Legendary specialists appear
├─ Facility Upgrade: Global Center available
├─ Combo Events: Common (30% chance)
└─ Status: "Elite Cyber Defense Firm"

Reputation: 501+ (Legendary Tier)
├─ Contracts: Premium government, black-market
├─ Threats: All threats + special variants
├─ Specialist Pool: All specialists available
├─ Prestige System: Unlocked
└─ Status: "Legendary SOC - Industry Leader"
```

### 7. Reputation → Better Contracts

**Contract Unlocking System:**

```
Contract Availability Formula:
├─ Base contract pool (always available)
├─ + Reputation-gated contracts
├─ + Faction-specific contracts (if reputation with faction)
└─ - Already active contracts (can't sign twice)

Example Contract Progression:

Rep 0:
├─ DevShop Co (Startup, $500/month)
├─ Local Retail Chain ($750/month)
└─ Small Clinic ($600/month)

Rep 75:
├─ All Tier 1 contracts
├─ + FinTech Startup ($2,000/month)
├─ + Mid-Size Hospital ($1,800/month)
└─ + Regional Bank ($2,500/month)

Rep 200:
├─ All Tier 1-2 contracts
├─ + Fortune 500 Company ($10,000/month)
├─ + University Research Lab ($8,000/month)
└─ + State Government Agency ($12,000/month)

Rep 400:
├─ All contracts available
├─ + Department of Defense ($50,000/month)
├─ + International Bank ($45,000/month)
└─ + Special Black Market Contracts (variable)
```

**Contract Selection Strategy:**

```
Early Game (Rep < 100):
├─ Take 2-3 Tier 1 contracts
├─ Focus on steady income
├─ Build reputation slowly
└─ Goal: Unlock Tier 2 contracts

Mid Game (Rep 100-300):
├─ Mix of Tier 1 and Tier 2
├─ Balance income vs crisis frequency
├─ Specialize in certain industries
└─ Goal: Build elite team

Late Game (Rep 300+):
├─ High-value Tier 3-4 contracts
├─ Accept crisis frequency (you're ready!)
├─ Focus on SLA perfection
└─ Goal: Maximize reputation for prestige
```

### 8. Better Contracts → More Crises (Loop Closes!)

**The Escalating Spiral:**

```
Contract Tier Progression Creates Challenge Spiral:

Phase 1: Comfortable (2-3 Tier 1 contracts)
├─ Crisis every ~3-5 minutes
├─ Tier 1 threats only
├─ Easy to maintain perfect SLA
└─ Reputation grows steadily

Phase 2: Busy (4-5 mixed contracts)
├─ Crisis every ~2-3 minutes
├─ Tier 1-2 threats
├─ Some multitasking required
├─ Specialists leveling up
└─ Reputation accelerating

Phase 3: Intense (6+ contracts, some Tier 3)
├─ Crisis every ~1-2 minutes
├─ Tier 2-3 threats
├─ Frequent multitasking
├─ Combo events appearing
├─ Specialists reaching elite levels
└─ Reputation at professional tier

Phase 4: Elite Endgame (8+ contracts, Tier 4)
├─ Multiple crises simultaneously
├─ Tier 4 threats (APT, Zero-Day)
├─ Combo events common
├─ Team coordination essential
├─ Specialists at legendary levels
└─ Reputation maxed, prestige unlocked
```

## Moment-to-Moment Gameplay Experience

### Session 1: First Hour

```
0:00 - Tutorial
├─ Learn basic UI
├─ Understand contracts
├─ Experience first crisis (guided)
└─ Hire first specialist

0:15 - Building Roster
├─ Sign 2nd contract
├─ Hire 2nd specialist
├─ Handle 2-3 simple crises
└─ Specialists reach Level 2-3

0:30 - First Challenge
├─ Sign 3rd contract (FinTech)
├─ Face first Tier 2 crisis (DDoS)
├─ Deploy multiple specialists
└─ Perfect resolution! Big XP reward

0:45 - Progression Unlocks
├─ Specialist reaches Level 4
├─ Unlock first Tier 2 skill
├─ Reputation hits 50 (unlock Tier 2 threats)
└─ Player feels "I'm getting stronger!"

End of Hour 1:
├─ 3 active contracts
├─ 3-4 specialists (Level 3-5)
├─ Reputation: 60-80
├─ Income: ~$4,000/month
└─ Hook: "Just need a bit more Rep for that Office upgrade..."
```

### Session 2: Mid-Game (Hours 5-10)

```
Player State:
├─ 5-7 specialists (Level 6-9)
├─ Office facility unlocked
├─ Reputation: 150-250
├─ 5-6 active contracts (mixed tiers)
└─ Income: $15,000/month

Typical 30-Minute Session:
├─ 8-12 crises (varied types)
├─ 1-2 specialist level-ups
├─ 1 Tier 2 skill unlock
├─ ~$5,000 earned
├─ +30 Reputation
└─ Progress toward next milestone

Player Thoughts:
├─ "My Analyst is becoming an APT hunter!"
├─ "Should I hire a SOC Manager for team buffs?"
├─ "That ransomware was close... need better malware skills"
└─ "Almost enough Rep for enterprise contracts!"
```

### Session 3: Late Game (Hours 15-25)

```
Player State:
├─ 12-18 specialists (Level 9-13)
├─ Corporate HQ
├─ Reputation: 350-450
├─ 8-10 contracts (Tier 3-4 dominant)
└─ Income: $60,000/month

Typical 30-Minute Session:
├─ 15-20 crises (including combos)
├─ 1 APT or Zero-Day event (major)
├─ Specialists hitting Tier 3 skill milestones
├─ Perfect SLA maintenance across all contracts
├─ +50 Reputation
├─ 1-2 Mission Tokens earned
└─ Working toward prestige

Player Thoughts:
├─ "My team is a well-oiled machine!"
├─ "I can handle simultaneous crises now"
├─ "Just hunted down a nation-state APT group!"
└─ "Should I prestige for legacy bonuses?"
```

## Idle vs Active Balance

### Idle Mechanics

**Passive Income:**
```
While not actively playing:
├─ Contracts generate income (40% of active play)
├─ Automated defenses handle some crises (if upgraded)
├─ Specialists on cooldown recover
└─ Resources accumulate (capped at 8 hours)

Offline Progress:
├─ Calculate time away
├─ Generate passive income
├─ Roll for crisis events (auto-resolved by automation)
├─ Award passive XP (20% of normal rate)
└─ Display summary on return

Example: 4 hours offline with 5 contracts
├─ Income: ~$8,000 (passive rate)
├─ Crises auto-handled: 8 (if automation upgraded)
├─ XP earned: ~200 (passive rate)
├─ Reputation: +10 (auto-resolution bonuses)
└─ Display: "While you were away: ..."
```

**Automation Upgrades:**
```
Tier 1: Basic Automation ($10,000)
├─ Auto-resolves Tier 1 crises (50% effectiveness)
├─ Offline income: 40% of active

Tier 2: Advanced Automation ($50,000)
├─ Auto-resolves Tier 1-2 crises (60% effectiveness)
├─ Offline income: 50% of active

Tier 3: AI-Powered SOC ($200,000)
├─ Auto-resolves Tier 1-3 crises (70% effectiveness)
├─ Offline income: 60% of active
├─ Can handle crises while you're actively playing (background)

Note: Tier 4 crises (APT, Zero-Day) always require player involvement
```

### Active Play Rewards

**Why Active Play is Better:**
```
Active Crisis Resolution:
├─ 2.5x XP compared to automated
├─ Perfect resolutions possible (automation always "success" at best)
├─ Mission Token chances (automation never earns these)
├─ Better reputation gains
└─ More engaging and strategic

Manual Specialist Management:
├─ Optimal specialist deployment
├─ Ability synergies and combos
├─ Strategic skill point spending
└─ Team composition optimization

Strategic Decision-Making:
├─ Which contracts to prioritize
├─ When to take risks (hard crises for big rewards)
├─ Resource management (money, Mission Tokens, skill points)
└─ Long-term progression planning
```

## Feedback Loops Summary

### Short Loop (Per Crisis)
```
Crisis Alert → Deploy Specialists → Use Abilities → Resolve Crisis
→ Earn XP → Specialists Level → Better Performance → Harder Crises
(~3-5 minutes per loop)
```

### Medium Loop (Per Session)
```
Sign Contracts → Multiple Crises → Specialist Progression
→ Unlock New Skills → Better Crisis Outcomes → Reputation Increase
→ New Contracts Available
(~30-60 minutes per loop)
```

### Long Loop (Prestige Cycle)
```
Build SOC → Master All Crisis Types → Max Reputation
→ Unlock Prestige → Start Fresh with Bonuses → Build Stronger SOC
(~20-40 hours per loop)
```

## Balancing the Loop

### Pacing Goals

**Early Game (Hours 0-5):**
```
Goal: Hook player with progression
├─ Crises feel challenging but winnable
├─ Level-ups feel frequent (every 20-30 min)
├─ Reputation grows steadily
├─ Each milestone feels rewarding
└─ Player understands all systems
```

**Mid Game (Hours 5-20):**
```
Goal: Deepen engagement with specialization
├─ Crises require strategy (can't brute force)
├─ Specialists diverging in builds
├─ Team composition matters
├─ Reputation unlocks feel meaningful
└─ Player optimizing strategies
```

**Late Game (Hours 20+):**
```
Goal: Mastery and preparation for prestige
├─ Elite crisis management
├─ Perfect SLA maintenance
├─ Legendary specialists
├─ Efficient resource optimization
└─ Player ready for prestige or endgame content
```

### Break Points & Difficulty Spikes

**Designed Pressure Points:**

```
Break Point 1: 3rd Contract (Hour 1-2)
├─ Crisis frequency increases noticeably
├─ Forces learning crisis prioritization
└─ Reward: Rep 50 unlock (Tier 2 threats)

Break Point 2: First Tier 3 Contract (Hour 8-12)
├─ Higher difficulty crises
├─ Team coordination required
├─ Combo events introduced
└─ Reward: Corporate HQ unlock

Break Point 3: First Tier 4 Contract (Hour 18-25)
├─ APT/Zero-Day complexity
├─ Multiple simultaneous crises
├─ Elite team required
└─ Reward: Prestige system unlock
```

## Player Progression Milestones

### Achievement-Based Milestones

```
"First Crisis Resolved"
├─ Complete first guided crisis
└─ Unlock: Free specialist hire

"Team of Five"
├─ Hire 5th specialist
└─ Unlock: SOC Manager role available

"Professional SOC"
├─ Reach 200 Reputation
└─ Unlock: Corporate HQ facility

"APT Hunter"
├─ Successfully resolve first APT crisis
└─ Unlock: Elite specialist hiring pool

"Perfect SLA Month"
├─ Maintain 100% SLA for 1 month across all contracts
└─ Unlock: Prestige system

"Crisis Master"
├─ Resolve 100 crises with perfect outcomes
└─ Unlock: Special legendary specialist
```

## Meta-Progression Goals

### What Carries Forward (Prestige System)

```
After Prestige:
├─ Keep: Reputation milestones (% bonus for fresh start)
├─ Keep: Unlocked crisis types (knowledge)
├─ Reset: Specialists (start fresh)
├─ Reset: Contracts (rebuild SOC)
├─ Bonus: Legacy perks (permanent buffs)
└─ Bonus: Special cosmetics/titles

Legacy Perks (Choose 1-3):
├─ "Seasoned Negotiator": +20% contract income
├─ "Veteran Trainer": Specialists gain XP 15% faster
├─ "Crisis Veteran": Start with +50 Reputation
├─ "Industry Legend": Start with 1 legendary specialist
└─ "Efficient Operations": -20% specialist cooldowns
```

## Implementation Checklist

**Phase 1: Core Loop (Coding Agent Currently Building)**
- [In Progress] Crisis generation from contracts
- [In Progress] Specialist deployment mechanics
- [In Progress] XP earning and distribution
- [In Progress] Level-up system
- [In Progress] Reputation tracking

**Phase 2: Loop Refinement (Next)**
- [ ] SLA tracking per contract
- [ ] Reputation-based contract unlocking
- [ ] Trait system for specialists
- [ ] Skill tree implementation
- [ ] Automation upgrades

**Phase 3: Advanced Features (Future)**
- [ ] Combo crisis events
- [ ] Offline/idle progress
- [ ] Achievement system
- [ ] Prestige system
- [ ] Legendary specialists

## Player Retention Hooks

### Daily/Weekly Hooks

```
Daily Incentives:
├─ Daily specialist recruit refresh (new random specialists)
├─ Daily crisis bonus (first crisis of day = 2x XP)
├─ Daily contract (special high-reward one-off)
└─ Daily login bonus (Mission Tokens)

Weekly Incentives:
├─ Weekly challenge (special crisis scenario)
├─ Weekly leaderboard (fastest crisis resolution)
├─ Weekly reputation milestone rewards
└─ Weekly specialist sale (discounted hire costs)
```

### Long-Term Hooks

```
Progression Goals:
├─ "I need X more Rep for Government contracts"
├─ "My Analyst is almost ready for APT hunting"
├─ "Just a few more Mission Tokens for that legendary hire"
└─ "One more Tier 3 skill and I'll be unstoppable"

Collection Goals:
├─ Collect all legendary trait specialists
├─ Master all crisis types (achievement)
├─ Unlock all facility upgrades
└─ Complete all prestige legacy perks

Social Goals (Future):
├─ Leaderboard ranking
├─ Guild/team features
├─ Share legendary crisis resolutions
└─ Collaborative crisis events
```

## Summary: Why This Loop is Addictive

```
✅ Clear short-term goals (next crisis, next level-up)
✅ Satisfying medium-term progression (unlocking skills, contracts)
✅ Meaningful long-term goals (prestige, legendary team)
✅ Multiple progression paths (specialists, facilities, contracts)
✅ Strategic depth (team building, specialist specialization)
✅ Risk/reward decisions (harder contracts = better rewards)
✅ "One more crisis" hook (always something to do)
✅ Visible power growth (going from struggling to dominating)
✅ Replayability (prestige system, random traits)
✅ Idle-friendly but rewards active play
```

**The engagement loop creates a natural gameplay rhythm:**
1. **Tension**: Crisis alert!
2. **Agency**: Deploy your specialists
3. **Skill**: Use abilities strategically
4. **Reward**: XP, money, reputation
5. **Progression**: Specialists level up
6. **Power**: Become stronger
7. **Challenge**: Unlock harder content
8. **Repeat**: At higher stakes

This is the core of why Idle Sec Ops will be addictive! 🚀
