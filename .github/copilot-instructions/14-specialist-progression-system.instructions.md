# Specialist Progression System — Idle Sec Ops

## Overview
This document defines the specialist progression system using **Role-Based Skill Trees + Random Traits** (Option D) to create unique, meaningful character development.

## Core Design Philosophy

**Key Principles:**
1. **Every specialist is unique** - Random traits make each hire feel special
2. **Strategic specialization** - Can't max everything, must make choices
3. **Team composition matters** - Different specialists excel at different crises
4. **Progression feels meaningful** - Each level/skill unlocks tangible power
5. **Long-term depth** - High-level specialists are significantly more capable

## Specialist Roles (Base Classes)

### Role: Security Analyst 🔍
**Starting Stats:**
- Efficiency: 1.2x
- Speed: 1.0x
- Trace: 1.3x
- Defense: 0.9x

**Natural Skill Affinity:**
- Analysis skills: -20% XP cost
- Investigation skills: -15% XP cost
- Network skills: Normal cost
- Response skills: +20% XP cost

**Starting Abilities:**
- basic_analysis (Level 1)
- Choose 1: network_fundamentals OR forensics_basics

**Role Fantasy:** The detective who figures out what's happening

**Best For:**
- Data exfiltration investigations
- Insider threat detection
- APT hunting
- Zero-day research

---

### Role: Network Engineer 🌐
**Starting Stats:**
- Efficiency: 1.0x
- Speed: 1.2x
- Trace: 1.0x
- Defense: 1.3x

**Natural Skill Affinity:**
- Network skills: -20% XP cost
- Infrastructure skills: -15% XP cost
- Analysis skills: Normal cost
- Leadership skills: +20% XP cost

**Starting Abilities:**
- network_fundamentals (Level 1)
- Choose 1: traffic_analysis OR firewall_management

**Role Fantasy:** The defender who builds walls and watches traffic

**Best For:**
- DDoS mitigation
- Network containment
- Traffic analysis
- Infrastructure hardening

---

### Role: Incident Responder 🚨
**Starting Stats:**
- Efficiency: 1.1x
- Speed: 1.3x
- Trace: 0.9x
- Defense: 1.2x

**Natural Skill Affinity:**
- Response skills: -20% XP cost
- Malware skills: -15% XP cost
- Leadership skills: Normal cost
- Network skills: +10% XP cost

**Starting Abilities:**
- basic_response (Level 1)
- Choose 1: malware_analysis OR crisis_management

**Role Fantasy:** The firefighter who handles active threats

**Best For:**
- Ransomware containment
- Malware removal
- Quick crisis resolution
- Emergency response

---

### Role: SOC Manager 👔
**Starting Stats:**
- Efficiency: 1.1x (affects whole team)
- Speed: 1.1x (affects whole team)
- Trace: 1.0x
- Defense: 1.1x

**Natural Skill Affinity:**
- Leadership skills: -25% XP cost
- Coordination skills: -20% XP cost
- All other skills: Normal cost

**Starting Abilities:**
- team_coordination (Level 1)
- Choose 1: negotiation OR strategic_planning

**Role Fantasy:** The leader who makes everyone better

**Best For:**
- Multi-crisis management
- Contract negotiations
- Team buffs
- Crisis combos

**Special:** Manager bonuses affect entire active team (multiplicative)

---

## Random Trait System

### Trait Categories

#### Tier 1: Common Traits (70% chance on hire)

**Learning Traits:**
- **Fast Learner**: -15% XP required for all skills
- **Specialized Learner**: -30% XP for role-affinity skills, +15% for others
- **Jack of All Trades**: -10% XP for non-affinity skills
- **Slow but Steady**: +20% XP required, but +10% to all stats at max level

**Combat Traits:**
- **Precise**: +15% effectiveness with analysis abilities
- **Quick Reflexes**: -10% time taken for all actions
- **Methodical**: +20% success chance on complex tasks, -10% speed
- **Aggressive**: +20% damage to threats, -10% defense

**Personality Traits:**
- **Confident**: +10% effectiveness when solo, -5% in teams
- **Team Player**: +15% effectiveness in teams of 3+, -5% solo
- **Nervous Under Pressure**: -10% effectiveness under 60 seconds remaining
- **Thrives on Pressure**: +15% effectiveness under 60 seconds remaining

#### Tier 2: Uncommon Traits (25% chance on hire)

**Specialist Expertise:**
- **Malware Specialist**: +30% effectiveness vs Malware/Ransomware crises
- **Network Guru**: +30% effectiveness vs DDoS/Network crises
- **Social Engineer**: +30% effectiveness vs Phishing/Insider crises
- **APT Hunter**: +25% effectiveness vs APT/Zero-Day crises

**Efficiency Traits:**
- **Resource Efficient**: Abilities cost 25% less cooldown time
- **Multitasker**: Can deploy to 2 crises simultaneously (reduced effectiveness)
- **Mentor**: Nearby specialists gain +10% XP
- **Innovator**: 10% chance to discover new ability combinations

**Economic Traits:**
- **Frugal**: Hiring cost -30%, but starts at 0.9x base stats
- **Expensive**: Hiring cost +50%, but starts at 1.15x base stats
- **Negotiator**: Generates +10% bonus rewards from resolved crises

#### Tier 3: Rare Traits (5% chance on hire)

**Legendary Traits:**
- **Prodigy**: -50% XP required for ALL skills, starts at level 3
- **Natural Leader**: Provides SOC Manager bonuses even if not Manager role
- **Crisis Magnet**: Attracted to crisis work, +50% XP from all sources
- **Unshakeable**: Immune to pressure penalties, always performs at peak
- **Cyberpunk Legend**: +20% to ALL stats, +25% hiring cost

**Unique Abilities:**
- **Zero-Day Discoverer**: Can research new defensive abilities
- **Hacker Background**: Can use "offensive" abilities (special actions)
- **Government Clearance**: Unlocks special government-only contracts
- **Industry Famous**: Provides passive reputation gain (+1 Rep/hour)

### Trait Visibility & Discovery

**On Hire Screen:**
- Show trait name and basic description
- Show stat modifiers
- **DON'T** show hidden mechanical effects until discovered

**Discovery System:**
- Some trait effects only reveal after conditions met
- Example: "Thrives on Pressure" reveals after first high-pressure success
- Creates "getting to know your team" experience

## Skill Tree Structure

### Tree 1: Analysis & Investigation

```
TIER 1 (Beginner):
├─ basic_analysis (Starting skill for Analysts)
│  ├─ Effect: +5% efficiency, +2% trace per level
│  ├─ Active: Deal 40 damage to threat integrity
│  └─ Max Level: 10
│
└─ forensics_basics
   ├─ Effect: +3% trace, +2% investigation speed per level
   ├─ Active: Gather evidence (reveals threat information)
   └─ Max Level: 10

TIER 2 (Intermediate):
├─ malware_analysis (Requires: basic_analysis Lvl 3, network_fundamentals Lvl 2)
│  ├─ Effect: +15% trace, +10% efficiency per level
│  ├─ Active: Deep analysis, deal 120 damage
│  └─ Max Level: 10
│
├─ behavioral_analysis (Requires: forensics_basics Lvl 5)
│  ├─ Effect: +20% insider threat detection
│  ├─ Active: Profile suspect (identify insider threats)
│  └─ Max Level: 8
│
└─ data_forensics (Requires: forensics_basics Lvl 5, basic_analysis Lvl 3)
   ├─ Effect: +25% data recovery, +10% trace
   ├─ Active: Recover deleted data (undo damage)
   └─ Max Level: 8

TIER 3 (Advanced):
├─ threat_intelligence (Requires: malware_analysis Lvl 7, behavioral_analysis Lvl 5)
│  ├─ Effect: +15% crisis prediction, +20% trace
│  ├─ Active: Predict next stage of APT attack
│  └─ Max Level: 10
│
├─ vulnerability_research (Requires: malware_analysis Lvl 8)
│  ├─ Effect: +30% zero-day detection
│  ├─ Active: Identify unknown exploits
│  └─ Max Level: 8
│
└─ APT_hunting (Requires: threat_intelligence Lvl 5, data_forensics Lvl 5)
   ├─ Effect: +40% APT detection and containment
   ├─ Active: Hunt persistent threats (multi-stage)
   └─ Max Level: 5 (Master skill)
```

### Tree 2: Network & Infrastructure

```
TIER 1 (Beginner):
├─ network_fundamentals (Starting skill for Engineers)
│  ├─ Effect: +5% defense, +3% speed per level
│  ├─ Active: Analyze traffic, deal 60 damage
│  └─ Max Level: 10
│
└─ firewall_management
   ├─ Effect: +4% defense, +2% threat blocking per level
   ├─ Active: Deploy firewall rule (reduce incoming damage)
   └─ Max Level: 10

TIER 2 (Intermediate):
├─ traffic_analysis (Requires: network_fundamentals Lvl 4)
│  ├─ Effect: +10% DDoS mitigation, +15% trace
│  ├─ Active: Identify attack patterns
│  └─ Max Level: 10
│
├─ intrusion_detection (Requires: network_fundamentals Lvl 5, firewall_management Lvl 3)
│  ├─ Effect: +20% threat detection speed
│  ├─ Active: Detect hidden threats (reveal stealth attacks)
│  └─ Max Level: 8
│
└─ network_segmentation (Requires: firewall_management Lvl 5)
   ├─ Effect: +25% containment effectiveness
   ├─ Active: Isolate network segment (prevent spread)
   └─ Max Level: 8

TIER 3 (Advanced):
├─ infrastructure_hardening (Requires: network_segmentation Lvl 6, intrusion_detection Lvl 5)
│  ├─ Effect: -15% crisis frequency (passive!)
│  ├─ Active: Harden defenses (reduce future damage)
│  └─ Max Level: 10
│
├─ DDoS_mitigation_expert (Requires: traffic_analysis Lvl 8)
│  ├─ Effect: +50% DDoS defense
│  ├─ Active: Advanced mitigation (auto-resolve DDoS stages)
│  └─ Max Level: 8
│
└─ zero_trust_architecture (Requires: infrastructure_hardening Lvl 7)
   ├─ Effect: +30% all defenses, -20% crisis severity
   ├─ Passive: Reduces crisis severity before they start
   └─ Max Level: 5 (Master skill)
```

### Tree 3: Incident Response & Crisis Management

```
TIER 1 (Beginner):
├─ basic_response (Starting skill for Responders)
│  ├─ Effect: +10% speed, +5% defense per level
│  ├─ Active: Apply mitigation (reduce threat severity)
│  └─ Max Level: 8
│
└─ rapid_containment
   ├─ Effect: +8% containment speed per level
   ├─ Active: Quick containment (speed-focused)
   └─ Max Level: 10

TIER 2 (Intermediate):
├─ crisis_management (Requires: basic_response Lvl 5)
│  ├─ Effect: +15% effectiveness in multi-stage crises
│  ├─ Active: Prioritize actions (optimize stage order)
│  └─ Max Level: 10
│
├─ malware_removal (Requires: basic_response Lvl 4, network_fundamentals Lvl 2)
│  ├─ Effect: +20% malware/ransomware effectiveness
│  ├─ Active: Remove malware (high damage to malware threats)
│  └─ Max Level: 8
│
└─ backup_recovery (Requires: basic_response Lvl 5)
   ├─ Effect: +30% data recovery speed
   ├─ Active: Restore from backup (recover lost data)
   └─ Max Level: 8

TIER 3 (Advanced):
├─ emergency_coordination (Requires: crisis_management Lvl 7, rapid_containment Lvl 7)
│  ├─ Effect: Can deploy to multiple crises (no penalty!)
│  ├─ Active: Coordinate team (boost all specialists)
│  └─ Max Level: 8
│
├─ ransomware_specialist (Requires: malware_removal Lvl 7, backup_recovery Lvl 6)
│  ├─ Effect: +60% ransomware resolution
│  ├─ Active: Decrypt ransomware (bypass negotiation)
│  └─ Max Level: 8
│
└─ disaster_recovery_expert (Requires: emergency_coordination Lvl 5, backup_recovery Lvl 7)
   ├─ Effect: Can recover from "failed" crises
   ├─ Active: Second chance (retry failed crisis stage)
   └─ Max Level: 5 (Master skill)
```

### Tree 4: Leadership & Team Coordination

```
TIER 1 (Beginner):
├─ team_coordination (Starting skill for Managers)
│  ├─ Effect: +2% efficiency and speed to ALL team members per level
│  ├─ Active: Rally team (temporary boost to all)
│  └─ Max Level: 5
│
└─ negotiation
   ├─ Effect: +5% contract payouts per level
   ├─ Active: Negotiate crisis outcome (reduce penalties)
   └─ Max Level: 10

TIER 2 (Intermediate):
├─ strategic_planning (Requires: team_coordination Lvl 3)
│  ├─ Effect: +10% crisis preparation (see incoming threats earlier)
│  ├─ Active: Plan response (pre-deploy specialists)
│  └─ Max Level: 8
│
├─ client_relations (Requires: negotiation Lvl 5)
│  ├─ Effect: +15% reputation gains, -20% SLA penalties
│  ├─ Active: Smooth talk (mitigate reputation loss)
│  └─ Max Level: 10
│
└─ resource_optimization (Requires: team_coordination Lvl 4)
   ├─ Effect: -20% specialist cooldowns
   ├─ Active: Optimize resources (instant cooldown refresh)
   └─ Max Level: 8

TIER 3 (Advanced):
├─ executive_leadership (Requires: strategic_planning Lvl 6, client_relations Lvl 7)
│  ├─ Effect: +20% ALL team stats (massive buff!)
│  ├─ Active: Inspire team (double effectiveness temporarily)
│  └─ Max Level: 10
│
├─ crisis_prediction (Requires: strategic_planning Lvl 7)
│  ├─ Effect: +30% warning time before crises
│  ├─ Active: Predict crisis (reveals next crisis details)
│  └─ Max Level: 8
│
└─ legendary_SOC_director (Requires: executive_leadership Lvl 8, crisis_prediction Lvl 6)
   ├─ Effect: Company-wide bonuses, prestige unlocks
   ├─ Passive: Your SOC is legendary (reputation grows passively)
   └─ Max Level: 5 (Master skill)
```

## XP & Leveling System

### Character Levels
```
Level 1: Starting level (0 XP)
Level 2: 100 XP
Level 3: 250 XP
Level 4: 500 XP
Level 5: 1,000 XP
Level 6: 2,000 XP
Level 7: 4,000 XP
Level 8: 8,000 XP
Level 9: 16,000 XP
Level 10: 32,000 XP
Level 11: 50,000 XP (Elite threshold)
Level 12: 75,000 XP
Level 13: 110,000 XP
Level 14: 160,000 XP
Level 15: 230,000 XP (Legendary)
```

### Level-Up Bonuses
```
Each level grants:
├─ +10% to all base stats (multiplicative)
├─ +1 skill point
└─ +5% crisis effectiveness

Example: Level 5 specialist
├─ Stats = Base × 1.4 (140% of hiring stats)
├─ 5 skill points to spend
└─ +25% crisis effectiveness
```

### Skill Leveling
```
Each skill has independent levels and XP requirements.

Base XP Cost (from skills.json):
- Tier 1 skills: 100-200 XP per level
- Tier 2 skills: 300-500 XP per level
- Tier 3 skills: 600-1000 XP per level

Modified by:
├─ Role affinity (-20% for natural skills)
├─ Trait bonuses (Fast Learner = -15%, etc.)
└─ XP growth multiplier (1.2x - 1.8x per level)

Example: malware_analysis for Security Analyst
- Base: 400 XP per level
- With affinity: 320 XP per level
- With Fast Learner: 272 XP per level
- At Level 5: 272 × 1.5^4 = 1,377 XP (getting expensive!)
```

### Skill Points vs Direct XP
```
Two ways to level skills:

1. Spend Skill Points (from character level-ups)
   - Instant level up
   - Ignore XP cost
   - Limited resource (1 per character level)

2. Spend XP directly
   - Pay full XP cost
   - Unlimited (if you have XP)
   - More flexible

Strategy:
- Use skill points on expensive Tier 3 skills
- Use XP on cheap Tier 1/2 skills
- Creates interesting resource management
```

## XP Sources & Distribution

### Crisis XP Awards
```
Base XP per crisis:
├─ Tier 1 (Phishing, Basic Malware): 50 XP
├─ Tier 2 (DDoS, Ransomware): 75-100 XP
├─ Tier 3 (Data Exfil, Insider): 90-110 XP
└─ Tier 4 (APT, Zero-Day): 140-150 XP

Multipliers:
├─ Perfect resolution: ×1.5
├─ Under time pressure: ×1.3
├─ First time: ×2.0
├─ Combo event: ×2.0
└─ Using optimal abilities: ×1.2

Distribution:
├─ Deployed specialists: 80% split equally
├─ Non-deployed: 20% split equally (learning)
└─ Specialists on cooldown: 0% (they're resting)
```

### Contract XP
```
Passive XP from active contracts:
├─ Per hour of contract: 5-15 XP per specialist
├─ Monthly SLA bonus: 50-200 XP to all specialists
└─ Contract completion: 25-75 XP to assigned specialists
```

### Training XP
```
Future feature: Dedicated training mode
├─ Specialists can enter "training mode"
├─ Can't deploy to crises while training
├─ Earn focused XP in specific skills
└─ Trade-off: unavailable for crises
```

## Hiring & Recruitment

### Specialist Hiring
```
Hiring Pool:
├─ 3-5 available specialists at any time
├─ Random roles and traits
├─ Refresh every 24 hours (in-game time)
└─ Can force refresh with Mission Tokens

Hiring Costs:
├─ Junior (Lvl 1): $5,000 - $10,000
├─ Experienced (Lvl 3-5): $15,000 - $30,000
├─ Elite (Lvl 7-10): $50,000 - $100,000
└─ Legendary (Lvl 11+): $150,000+ or Mission Tokens

Trait affects cost:
├─ Frugal trait: -30% cost
├─ Expensive/Rare trait: +50% cost
├─ Legendary trait: +100% cost
```

### Specialist Roster Limits
```
Max specialists by facility:
├─ Garage: 3 specialists
├─ Office: 8 specialists
├─ Corporate HQ: 20 specialists
└─ Global Center: Unlimited (practically 30-40)
```

## Progression Curves

### Early Game (Hours 0-3)
```
Goal: Learn mechanics, build starter team

Typical Progression:
├─ Start with CEO (You) at Lvl 1
├─ Hire 2 specialists (Analyst + Responder)
├─ Level specialists to Lvl 3-4
├─ Unlock Tier 2 skills
└─ Handle Tier 1-2 crises comfortably
```

### Mid Game (Hours 3-10)
```
Goal: Specialize team, handle variety

Typical Progression:
├─ Team of 5-8 specialists
├─ Specialists reaching Lvl 6-8
├─ First Tier 3 skills unlocked
├─ Diverse role coverage (1-2 of each role)
└─ Handle Tier 2-3 crises, occasional Tier 4
```

### Late Game (Hours 10-30)
```
Goal: Elite team, master difficult content

Typical Progression:
├─ Team of 12-20 specialists
├─ Core team at Lvl 10-13
├─ Multiple Tier 3 skills mastered
├─ Specialized "builds" per specialist
└─ Consistently handle Tier 4, combo events
```

### Endgame (Hours 30+)
```
Goal: Perfect team, prestige prep

Typical Progression:
├─ Elite specialists at Lvl 13-15
├─ Master skills unlocked
├─ Legendary traits collected
├─ Perfect SLA compliance
└─ Ready for prestige/legacy system
```

## Team Composition Strategy

### Recommended Team Builds

**Starter Team (3 specialists):**
```
├─ Security Analyst (You/CEO) - Investigation focus
├─ Incident Responder - Fast response
└─ Network Engineer - Defense
```

**Balanced Mid-Game Team (8 specialists):**
```
├─ 2× Security Analysts (Investigation, APT hunting)
├─ 2× Network Engineers (DDoS, containment)
├─ 2× Incident Responders (Crisis resolution)
├─ 1× SOC Manager (Team buffs)
└─ 1× Specialist with rare trait
```

**Late-Game Elite Team (15+ specialists):**
```
├─ 4× Security Analysts (2 APT hunters, 2 forensics)
├─ 4× Network Engineers (2 DDoS experts, 2 infrastructure)
├─ 4× Incident Responders (2 ransomware, 2 general)
├─ 2× SOC Managers (Leadership, negotiation)
└─ 1× Legendary specialist (unique abilities)
```

## Ability Synergies

### Combo Abilities
```
When multiple specialists deployed together:

Network Engineer + Security Analyst:
└─ "Coordinated Analysis": +30% trace effectiveness

Incident Responder + SOC Manager:
└─ "Crisis Leadership": +25% response speed

Multiple Responders:
└─ "Response Team": +15% per additional responder

Specialist with Mentor trait + Junior specialists:
└─ "Training Session": +50% XP for juniors
```

## UI/UX for Progression

### Specialist Card Display
```
┌─────────────────────────────────────┐
│ 🔍 Alex "Tracer" Rodriguez          │
│ Security Analyst | Level 7          │
│ ⭐ Trait: APT Hunter                │
├─────────────────────────────────────┤
│ XP: 4,250 / 8,000 [████████▒▒▒▒] 53%│
├─────────────────────────────────────┤
│ Stats:                              │
│ ├─ Efficiency: 1.8x (↑ Base 1.2x)  │
│ ├─ Speed: 1.4x                      │
│ ├─ Trace: 2.1x (★ Role Bonus)      │
│ └─ Defense: 1.2x                    │
├─────────────────────────────────────┤
│ Skills: (5 skill points available)  │
│ ├─ basic_analysis: Lvl 10 [MAX]    │
│ ├─ malware_analysis: Lvl 7         │
│ ├─ threat_intelligence: Lvl 5      │
│ └─ APT_hunting: Lvl 2 [LEARNING]   │
├─────────────────────────────────────┤
│ Status: Available                   │
│ Cooldown: Ready                     │
└─────────────────────────────────────┘
```

### Skill Tree UI
```
Visual tree showing:
├─ Unlocked skills (bright, clickable)
├─ Available skills (requirements met, glowing)
├─ Locked skills (grayed out, show requirements)
└─ Lines connecting prerequisites

Hover over skill shows:
├─ XP cost to level up
├─ Current/max level
├─ Stat bonuses per level
├─ Active ability details
└─ Next level benefits
```

### Level-Up Notification
```
┌─────────────────────────────────────┐
│        🎉 LEVEL UP! 🎉              │
│                                     │
│  Alex "Tracer" Rodriguez            │
│      Level 6 → Level 7              │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ +10% All Stats                  │ │
│ │ +1 Skill Point (Total: 2)       │ │
│ │ +5% Crisis Effectiveness        │ │
│ └─────────────────────────────────┘ │
│                                     │
│    [Spend Skill Point] [Later]     │
└─────────────────────────────────────┘
```

## Balancing Guidelines

### XP Tuning
```
Target pace:
├─ Level 5: 3-4 hours of play
├─ Level 10: 15-20 hours of play
├─ Level 15: 60-80 hours of play

If too fast:
├─ Reduce crisis XP rewards
├─ Increase level thresholds
├─ Reduce passive contract XP

If too slow:
├─ Add bonus XP events
├─ Increase perfect resolution multipliers
├─ Add training modes
```

### Skill Power Scaling
```
Power curve should feel:
├─ Levels 1-3: Learning basics
├─ Levels 4-6: Becoming competent
├─ Levels 7-9: Feeling powerful
├─ Levels 10-12: Elite expertise
└─ Levels 13-15: Legendary mastery

Tier 3 skills should be:
├─ 3-5x more powerful than Tier 1
├─ Noticeable impact on crisis outcomes
└─ Worth the investment to unlock
```

## Implementation Notes

### Data Structure (specialists.json)
```json
{
  "roles": {
    "security_analyst": {
      "name": "Security Analyst",
      "baseStats": {"efficiency": 1.2, "speed": 1.0, "trace": 1.3, "defense": 0.9},
      "skillAffinities": {
        "analysis": -0.2,
        "investigation": -0.15,
        "network": 0.0,
        "response": 0.2
      },
      "startingAbilities": ["basic_analysis"],
      "startingChoice": ["network_fundamentals", "forensics_basics"]
    }
  },
  "traits": {
    "fast_learner": {
      "tier": 1,
      "chance": 0.15,
      "effects": {"xpMultiplier": 0.85},
      "description": "Learns skills 15% faster"
    }
  }
}
```

### Event Integration
```
New events to fire:
├─ "specialist_leveled_up" → {specialistId, oldLevel, newLevel, bonuses}
├─ "specialist_learned_skill" → {specialistId, skillId, skillLevel}
├─ "skill_point_available" → {specialistId, availablePoints}
├─ "trait_discovered" → {specialistId, traitId, effect}
└─ "specialist_mastery" → {specialistId, skillId} (when skill maxed)
```

## Future Expansion Ideas

- **Specialist Retirement**: Long-term specialists can retire with legacy bonuses
- **Mentorship System**: Veterans train juniors faster
- **Specialist Stories**: Procedural narrative events for high-level specialists
- **Legendary Equipment**: Items that boost specific roles/skills
- **Prestige Skills**: Skills that carry over after prestige
- **Specialist Specialization**: Late-game branching within roles
