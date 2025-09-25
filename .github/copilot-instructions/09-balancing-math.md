# Balancing & Mathematical Framework

## Resource Generation Formulas

### Base Generation Calculations
```
Data Bits per second = (Base Server Output × Server Count × Processing Power Multiplier × Efficiency Rating)
Processing Power growth = Exponential curve with diminishing returns after tier thresholds
Security Rating = Sum of all defensive systems with diminishing returns formula
```

### Detailed Calculation Examples

**Data Bit Generation:**
```
DB/sec = Σ(Server_i.output × Server_i.count) × (1 + PP_multiplier) × Zone_bonus × Efficiency_rating
Where:
- PP_multiplier = min(10.0, sqrt(Total_Processing_Power) * 0.01)
- Zone_bonus = 1.0 + (Zone_level * 0.1)
- Efficiency_rating = Product of all efficiency upgrades (capped at 5.0)
```

**Processing Power Multiplier:**
```
PP_total = Σ(Core_i.output × Core_i.count × Core_i.efficiency)
PP_multiplier = log10(1 + PP_total / 100) * 0.5
Maximum PP_multiplier = 3.0 (achieved at 999,900 total PP)
```

**Security Rating Calculation:**
```
SR = √(Σ(Defense_i.rating²)) × Personnel_bonus × Zone_penalty
Where:
- Personnel_bonus = 1.0 + (Personnel_count * 0.05)
- Zone_penalty = max(0.5, 1.0 - (Zone_threat_level * 0.1))
```

## Upgrade Cost Scaling

### Base Cost Formula
```
Upgrade_cost = Base_cost × (Growth_factor ^ Purchase_count) × Zone_multiplier × Rarity_multiplier

Growth Factors by Category:
- Server Infrastructure: 1.15
- Processing Cores: 1.20
- Security Systems: 1.25
- Personnel: 1.30
- Research: 1.35
- Experimental: 1.50
```

### Bulk Purchase Discounts
```
Bulk_discount = min(0.20, Purchase_quantity * 0.01)
Final_cost = Individual_cost × Purchase_quantity × (1 - Bulk_discount)
```

### Zone Cost Multipliers
- Zone 1 (Darknet Basement): 1.0x
- Zone 2 (Corporate District): 1.5x
- Zone 3 (Government Sector): 2.5x
- Zone 4 (Deep Web Ruins): 2.0x (variable based on salvage)
- Zone 5 (Neutral Trade): 3.0x (market fluctuation)
- Zone 6 (Quantum Realm): 5.0x

## Threat Scaling System

### Dynamic Threat Level
```
Base_threat_level = (Player_net_worth ^ 0.75) / 1000
Zone_threat_modifier = Zone_base_threat × (1 + Random(-0.2, +0.3))
Faction_modifier = Sum of negative faction reputation penalties
Final_threat_level = Base_threat_level × Zone_threat_modifier × Faction_modifier
```

### Attack Success Probability
```
Attack_success_chance = max(0.05, min(0.95, 
  (Threat_level × Attack_sophistication) / 
  (Security_rating × Defense_multipliers × Random_factor)
))

Where:
- Attack_sophistication ranges from 0.5 (basic) to 5.0 (advanced AI)
- Defense_multipliers include personnel, equipment, and zone bonuses
- Random_factor = 0.8 to 1.2 (20% variance)
```

### Damage Calculations
```
Base_damage = Threat_base_damage × Threat_level_multiplier
Actual_damage = Base_damage × (1 - Defense_effectiveness) × Critical_multiplier
Critical_multiplier = (Critical_hit_chance > Random(0,1)) ? 2.0 : 1.0

Resource_loss = min(Actual_damage, Current_resources × Max_loss_percentage)
Max_loss_percentage = max(0.05, 0.5 - (Security_rating / Max_security_rating))
```

## Progression Balancing

### Time Gates & Milestones
**Early Game (0-7 days):**
- Progress measured in minutes to hours
- Upgrade costs: 10 DB to 100,000 DB
- Threat frequency: 60-300 seconds
- Maximum loss per attack: 10%

**Mid Game (1-4 weeks):**
- Progress measured in hours to days
- Upgrade costs: 100,000 DB to 100,000,000 DB
- Threat frequency: 300-1800 seconds
- Maximum loss per attack: 25%

**Late Game (1-6 months):**
- Progress measured in days to weeks
- Upgrade costs: 100M DB to 1T DB
- Threat frequency: 1800-7200 seconds
- Maximum loss per attack: 50%

**Endgame (6+ months):**
- Progress measured in weeks to months
- Upgrade costs: 1T+ DB
- Threat frequency: Constant high-level pressure
- Maximum loss per attack: 75% (but better defenses available)

### Experience and Level Scaling
```
XP_required_for_level = Base_XP × (Level ^ 1.8)
Base_XP = 1000

Level bonuses:
- Generation efficiency: +2% per level
- Defense bonus: +1% per level
- Special ability unlock: Every 5 levels
```

### Prestige Requirements
```
Prestige_cost[n] = Base_requirement × (Prestige_layer ^ 2.5) × (Previous_prestiges ^ 1.2)

Base Requirements:
- Local Prestige: 100M total DB earned
- Regional Prestige: 10B total DB earned
- Global Prestige: 1T total DB earned
- Galactic Prestige: 100T total DB earned
- Multiversal Prestige: 10Q total DB earned
```

## Resource Balance Framework

### Resource Conversion Rates
```
Conversion_efficiency = Base_efficiency × Facility_level × Research_bonus
Base conversion rates:
- DB to RP: 1000:1 (base efficiency 0.1%)
- RD to NNF: 100:1 (base efficiency 1%)
- PP to QET: 10000:1 (base efficiency 0.01%)
```

### Market Fluctuation Model
```
Market_price = Base_price × Demand_factor × Supply_factor × Event_modifier
Demand_factor = 0.5 + (Global_demand / Max_demand)
Supply_factor = 2.0 - (Global_supply / Max_supply)
Event_modifier = 0.25 to 4.0 (based on current events)
```

### Resource Decay Rates
- Basic resources (DB, PP): No decay
- Advanced resources (RP, RD): 1% per day if not used
- Ultra-rare resources (NNF, QET): 0.1% per day baseline
- Experimental resources: Variable decay based on stability

## Achievement Scaling

### Achievement Point Values
```
Achievement_points = Base_value × Difficulty_multiplier × Rarity_multiplier × Time_factor

Base Values:
- Resource milestones: 10-100 points
- Combat achievements: 25-250 points
- Exploration achievements: 50-500 points
- Social achievements: 75-750 points
- Endgame achievements: 1000+ points
```

### Achievement Requirements Scaling
- Tier 1 achievements: Reachable in first week
- Tier 2 achievements: Reachable in first month
- Tier 3 achievements: Reachable in 3-6 months
- Tier 4 achievements: Reachable in 6-12 months
- Tier 5 achievements: Reachable only through exceptional play or community effort

## Balance Testing Framework

### Automated Balance Testing
- **Simulation Runs:** Automated playthroughs testing progression curves
- **Edge Case Testing:** Extreme min/max scenarios
- **Regression Testing:** Ensure changes don't break existing balance
- **Performance Testing:** Mathematical operations don't cause lag

### Player Data Analysis
- **Progression Tracking:** Monitor real player advancement rates
- **Engagement Metrics:** Identify points where players quit or lose interest
- **Economy Monitoring:** Track resource inflation and deflation
- **Difficulty Spikes:** Identify and smooth out frustrating difficulty jumps

### Balance Adjustment Procedures
1. **Data Collection:** Gather 2 weeks of player data minimum
2. **Statistical Analysis:** Identify outliers and patterns
3. **Theoretical Modeling:** Predict effects of proposed changes
4. **Limited Testing:** Beta test with small player group
5. **Gradual Rollout:** Implement changes incrementally
6. **Monitoring:** Track effects for 1 month post-change

## Mathematical Constants Reference

### Core Game Constants
```
const GAME_CONSTANTS = {
  // Resource generation
  BASE_CLICK_VALUE: 1,
  MAX_CLICK_MULTIPLIER: 5.0,
  CRITICAL_CLICK_CHANCE: 0.05,
  CRITICAL_CLICK_MULTIPLIER: 10.0,
  
  // Upgrade scaling
  SERVER_GROWTH_FACTOR: 1.15,
  PROCESSING_GROWTH_FACTOR: 1.20,
  SECURITY_GROWTH_FACTOR: 1.25,
  
  // Threat system
  BASE_THREAT_INTERVAL: 120, // seconds
  THREAT_LEVEL_SCALING: 0.75,
  MAX_ATTACK_SUCCESS: 0.95,
  MIN_ATTACK_SUCCESS: 0.05,
  
  // Prestige system
  PRESTIGE_SCALING_EXPONENT: 2.5,
  QUANTUM_ECHO_EFFICIENCY: 0.01,
  
  // Zone multipliers
  ZONE_COST_MULTIPLIERS: [1.0, 1.5, 2.5, 2.0, 3.0, 5.0],
  ZONE_THREAT_MULTIPLIERS: [1.0, 1.2, 2.0, 1.8, 1.5, 3.0]
}
```

### Balancing Validation Formulas
```
// Ensure no upgrade becomes impossible to afford
function validateUpgradeCost(baseCost, count, growthFactor) {
  const cost = baseCost * Math.pow(growthFactor, count);
  const maxAffordableCount = Math.log(MAX_REASONABLE_COST / baseCost) / Math.log(growthFactor);
  return count <= maxAffordableCount;
}

// Ensure progression maintains engagement
function validateProgressionPacing(currentLevel, targetLevel, expectedHours) {
  const progressRate = (targetLevel - currentLevel) / expectedHours;
  return progressRate >= MIN_PROGRESS_RATE && progressRate <= MAX_PROGRESS_RATE;
}
```