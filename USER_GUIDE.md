# Idle Sec Ops - Player Guide

## Welcome to Your Security Operations Center!

This guide will help you understand the game mechanics and how to build a successful cybersecurity company.

## Table of Contents
1. [Getting Started](#getting-started)
2. [Contracts & SLA Management](#contracts--sla-management)
3. [Specialists & Team Building](#specialists--team-building)
4. [Incident Response](#incident-response)
5. [Enhanced Admin Mode](#enhanced-admin-mode)
6. [Performance Metrics](#performance-metrics)
7. [Tips & Strategies](#tips--strategies)

---

## Getting Started

### Your First Steps

1. **Starting Resources**: You begin with:
   - $10,000 in funds
   - Your CEO (you!)
   - A basic SOC infrastructure

2. **First Contract**: Accept your first contract to start generating income
   - Contracts provide steady income over time
   - Each contract has Service Level Agreement (SLA) requirements

3. **Hire Specialists**: Use your earnings to hire specialists
   - Each specialist increases your capacity
   - Specialists help handle incidents faster
   - Better specialists = better performance

### Core Game Loop

```
Accept Contracts → Generate Income → Hire Specialists → 
Handle Incidents → Complete Contracts → Earn Rewards → Repeat
```

---

## Contracts & SLA Management

### Understanding Contracts

**Contract Types** (by tier):
- **Tier 1**: Small businesses (coffee shops, local stores)
- **Tier 2**: Startups and growing companies
- **Tier 3**: Enterprises and large corporations
- **Tier 4+**: Government and critical infrastructure

**Contract Properties**:
- **Base Budget**: The income you'll earn over the contract duration
- **Duration**: How long the contract runs
- **SLA Requirements**: Performance targets you must meet
- **Reputation Reward**: Reputation points earned on completion

### Service Level Agreements (SLA)

Every contract has SLA requirements that you must meet:

#### SLA Metrics

1. **Detection Time SLA**: Maximum time to detect an incident
2. **Response Time SLA**: Maximum time to respond to an incident
3. **Resolution Time SLA**: Maximum time to fully resolve an incident
4. **Maximum Incidents**: Total incidents allowed before breach

#### SLA Compliance Ratings

- **Excellent** (95%+): 🌟 Maximum bonus rewards
- **Good** (85-95%): ✅ Bonus rewards
- **Acceptable** (75-85%): ⚪ Standard rewards
- **Poor** (60-75%): ⚠️ Reduced rewards
- **Critical** (<60%): ❌ Penalties applied

#### Rewards & Penalties

**Meeting SLA requirements:**
- ✅ Bonus payments (10-20% of contract value)
- ✅ Reputation bonuses
- ✅ Unlocks better contracts

**Failing SLA requirements:**
- ❌ Financial penalties (30-50% of contract value)
- ❌ Reputation loss
- ❌ Risk of contract termination

### Contract Capacity

Your capacity determines how many contracts you can handle simultaneously:

**Capacity Formula**: `Floor(Specialists / 3)`

**Examples**:
- 1-2 specialists = 1 contract capacity
- 3-5 specialists = 1-2 capacity
- 6-8 specialists = 2-3 capacity
- 9-11 specialists = 3-4 capacity

**Over Capacity**:
- You can accept contracts beyond your capacity
- ⚠️ **Warning**: Performance degrades 15% per contract over capacity
- 🚨 **Tip**: Hire more specialists or complete existing contracts first

---

## Specialists & Team Building

### Specialist Types

Each specialist has three core stats:

1. **Trace** 🔍: Used for detecting incidents (Detect stage)
2. **Speed** ⚡: Used for responding to incidents (Respond stage)
3. **Efficiency** 💼: Used for resolving incidents (Resolve stage)

### Specialist Progression

- **Levels**: Specialists gain XP and level up
- **Skills**: Unlock skills in the skill tree
- **Specialization**: Focus on specific stat types
- **Team Synergy**: Different specialist types work better together

### Hiring Strategy

**Early Game** (First 5 specialists):
- Focus on balanced stats
- Prioritize "Junior Security Analyst" type
- Build minimum capacity (1-2 contracts)

**Mid Game** (5-15 specialists):
- Start specializing roles
- Mix of Trace, Speed, and Efficiency specialists
- Aim for 3-5 capacity

**Late Game** (15+ specialists):
- Highly specialized teams
- Senior specialists with advanced skills
- Multiple simultaneous contracts

---

## Incident Response

### Three-Stage Incident Lifecycle

Every incident goes through three stages:

#### 1. Detect Stage 🔍
- **Goal**: Identify the security threat
- **Required Stat**: Trace
- **SLA**: Fastest time limit
- **Auto-Assignment**: Specialists with highest Trace are assigned

#### 2. Respond Stage ⚡
- **Goal**: Contain and mitigate the threat
- **Required Stat**: Speed
- **SLA**: Medium time limit
- **Auto-Assignment**: Specialists with highest Speed are assigned

#### 3. Resolve Stage 💼
- **Goal**: Fully remediate and document
- **Required Stat**: Efficiency
- **SLA**: Longest time limit
- **Auto-Assignment**: Specialists with highest Efficiency are assigned

### Incident Severity

Incidents have severity levels that affect:
- Time required to complete each stage
- SLA time limits (tighter for high severity)
- Rewards for successful resolution

**Severity Scale**: 1 (Low) → 5 (Critical)

### Automatic vs Manual Assignment

**Automatic Assignment** (Default):
- System assigns best-available specialists
- Based on stat matching (Trace/Speed/Efficiency)
- Handles most situations effectively

**Manual Assignment** (Advanced):
- Use Enhanced Admin Mode (press `A` key)
- Tactical control over specialist deployment
- Useful for:
  - Critical incidents requiring specific specialists
  - Balancing workload across team
  - Training junior specialists
  - Emergency situations

---

## Enhanced Admin Mode

Access by pressing **A** key (or clicking "Enhanced Admin" button).

### Dashboard Layout

#### Top: Performance Metrics
```
┌─────────────────────────────────────────────────────┐
│ 📊 PERFORMANCE METRICS                              │
├─────────────────────────────────────────────────────┤
│ Workload: OPTIMAL (50%)    SLA: 95%                 │
│ Contracts: 3    Specialists: 5 (Lvl 2.4)            │
│ Avg Response: 45s                                   │
└─────────────────────────────────────────────────────┘
```

#### Left: Active Incidents
```
┌──────────────────────────────────┐
│ 🚨 ACTIVE INCIDENTS              │
├──────────────────────────────────┤
│ Phishing Attack [detect]         │
│ Progress: 45% | SLA: 30s/60s     │
│ Assigned: Bob                    │
│ [ASSIGN SPECIALIST]              │
└──────────────────────────────────┘
```

#### Right: Specialists Panel
```
┌──────────────────────────────────┐
│ 👥 SPECIALISTS & WORKLOAD        │
├──────────────────────────────────┤
│ Alice (Level 3)                  │
│ Trace: 5 | Speed: 7 | Eff: 8    │
│ Workload: 2 incidents (BUSY)     │
│ [ASSIGN TO INCIDENT...]          │
└──────────────────────────────────┘
```

### Manual Assignment Workflow

1. **Select Incident**: Click on an incident card
2. **Choose Specialist**: Click "ASSIGN TO [INCIDENT]" on a specialist card
3. **Confirmation**: Specialist is added to the incident stage
4. **Track Performance**: Stats update in real-time

### Workload Indicators

**Specialist Workload Colors**:
- 🟢 **Green** (0 incidents): Available
- 🟡 **Yellow** (1-2 incidents): Busy
- 🔴 **Red** (3+ incidents): Overloaded

**Company Workload Status**:
- 🟢 **OPTIMAL** (0-50% capacity): Running smoothly
- 🟡 **HIGH** (50-66% capacity): Approaching limits
- 🟠 **CRITICAL** (66-100% capacity): Near maximum
- 🔴 **OVERLOADED** (>100% capacity): Performance degraded

---

## Performance Metrics

### Key Metrics to Track

1. **SLA Compliance Rate**
   - Target: >85% for sustainable growth
   - Below 75%: Risk of penalties
   - Above 95%: Excellent bonuses

2. **Average Resolution Time**
   - Decreases with better specialists
   - Increases when overloaded
   - Aim for under SLA time limits

3. **Specialist Efficiency**
   - Average level of your team
   - Higher levels = faster resolution
   - Invest in training and upgrades

4. **Manual vs Auto Assignments**
   - Track your tactical interventions
   - Manual assignments show engagement
   - Auto assignments for routine work

### Milestones

Unlock achievements by hitting these milestones:

- ✨ **First Contract**: Complete your first contract
- 🎯 **10 Contracts**: Become an established SOC
- 🔥 **100 Incidents**: Master incident response
- 👥 **Team of 10**: Build a substantial team
- 💰 **$1M Revenue**: Financial success
- 🌟 **Perfect Contract**: 100% SLA compliance

---

## Tips & Strategies

### Early Game Tips

1. **Don't rush hiring**: Save money for quality specialists
2. **Focus on one contract**: Build competency before expanding
3. **Watch SLA compliance**: Even small bonuses compound
4. **Upgrade wisely**: Prioritize efficiency upgrades first

### Mid Game Tips

1. **Specialize your team**: Different specialists for different stages
2. **Monitor capacity**: Stay under capacity when possible
3. **Use manual assignment**: For critical high-value contracts
4. **Train specialists**: Invest in skills and leveling

### Late Game Tips

1. **Optimize team composition**: Balance Trace/Speed/Efficiency
2. **Multiple contracts**: Run 3-5 contracts simultaneously
3. **Target high-tier contracts**: Better rewards, harder requirements
4. **Perfect SLA runs**: Aim for 100% compliance on important contracts

### Common Mistakes to Avoid

❌ **Over-extending**: Accepting too many contracts
❌ **Ignoring SLA**: Focusing only on income, not performance
❌ **Unbalanced team**: All specialists with same stat type
❌ **Not upgrading**: Saving money instead of investing
❌ **Manual micromanagement**: Over-using manual assignments

### Optimal Strategies

✅ **Steady growth**: Expand capacity gradually
✅ **SLA focus**: Prioritize compliance over quantity
✅ **Specialist diversity**: Mix of trace/speed/efficiency
✅ **Smart investments**: Upgrades + Specialists + Training
✅ **Tactical manual**: Use manual assignment for critical situations

---

## Troubleshooting

### "Cannot Accept Contract"

**Problem**: Not enough capacity
**Solution**: 
- Hire more specialists (3 per contract capacity)
- Complete existing contracts
- Check specialist count in Admin Mode

### Poor SLA Compliance

**Problem**: Incidents taking too long
**Solution**:
- Hire better specialists
- Reduce active contracts
- Use manual assignment for critical incidents
- Upgrade specialist stats

### Specialists Overloaded

**Problem**: Red workload indicators
**Solution**:
- Hire additional specialists
- Complete some contracts before accepting new ones
- Distribute workload more evenly via manual assignment

### Lost Money on Penalties

**Problem**: SLA breaches
**Solution**:
- Review SLA requirements before accepting
- Ensure adequate specialist levels
- Don't over-extend capacity
- Consider declining difficult contracts

---

## Debug Overlay (F3)

Press **F3** to toggle the debug overlay showing:
- Real-time resource generation
- System statistics
- Achievement progress
- RNG state
- Performance metrics

**Note**: Debug overlay is for advanced players and testing.

---

## Keyboard Shortcuts

- **A**: Open Enhanced Admin Mode
- **F3**: Toggle Debug Overlay
- **ESC**: Close current overlay/return to main view
- **Space**: Pause/Resume (if implemented)

---

## Glossary

- **SLA**: Service Level Agreement - performance targets for contracts
- **Capacity**: Maximum number of simultaneous contracts
- **Workload**: Current usage vs. maximum capacity
- **Trace**: Detection stat for identifying incidents
- **Speed**: Response stat for containing incidents
- **Efficiency**: Resolution stat for fully resolving incidents
- **Compliance**: Meeting SLA requirements
- **Breach**: Failing to meet SLA time limits
- **Milestone**: Achievement unlocked at specific thresholds

---

## Support & Community

- **Documentation**: Check the `docs/` folder for technical details
- **Testing**: See `TESTING.md` for game mechanics validation
- **Architecture**: See `ARCHITECTURE.md` for system design
- **Issues**: Report bugs via GitHub Issues

---

**Version**: Phase 5 Complete
**Last Updated**: January 2025

Enjoy building your cybersecurity empire! 🛡️🚀
