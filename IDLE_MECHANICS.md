# Idle Mechanics System - Cybersecurity Focus

## Overview

The idle mechanics system simulates realistic cybersecurity threats and defenses while the player is offline. This creates an engaging risk/reward dynamic where players must invest in security infrastructure to protect their resources during idle periods.

## Core Mechanics

### Threat Types

The system simulates 6 different categories of cyber threats:

1. **Phishing Attacks** - Email-based social engineering
   - Frequency: Every 5 minutes (average)
   - Base Damage: $50
   - Counter: Email Security Filter

2. **Malware Detection** - Malicious software infiltration  
   - Frequency: Every 10 minutes (average)
   - Base Damage: $100
   - Counter: Enterprise Antivirus

3. **Brute Force Attacks** - Automated password cracking
   - Frequency: Every 30 minutes (average)
   - Base Damage: $200
   - Counter: Access Control System

4. **DDoS Attacks** - Distributed denial of service
   - Frequency: Every hour (average)
   - Base Damage: $300
   - Counter: Traffic Analysis System

5. **Advanced Persistent Threats** - Sophisticated infiltration
   - Frequency: Every 2 hours (average)
   - Base Damage: $800
   - Counter: Threat Intelligence Platform

6. **Zero-Day Exploits** - Unknown vulnerability exploitation
   - Frequency: Every 4 hours (average)
   - Base Damage: $1,200
   - Counter: Behavioral Analysis Engine

### Security Infrastructure

Players can invest in specialized security upgrades that provide targeted defense against specific threat types:

#### Tier 2 Defenses
- **Email Security Filter** - 10% additional protection against phishing
- **Enterprise Antivirus** - 15% additional protection against malware

#### Tier 3 Defenses  
- **Access Control System** - 20% additional protection against brute force
- **Traffic Analysis System** - 25% additional protection against DDoS

#### Tier 4+ Defenses
- **Threat Intelligence Platform** - 30% additional protection against APTs
- **Behavioral Analysis Engine** - 35% additional protection against zero-days

### Damage Calculation

The final damage from each threat is calculated as:

```
Base Damage × (1 - General Threat Reduction) × (1 - Specialized Defense) × Random Variance
```

Where:
- **General Threat Reduction**: From basic security upgrades (firewalls, packet filters)
- **Specialized Defense**: From targeted security systems
- **Random Variance**: ±30% to add unpredictability

### Protection Mechanics

1. **Damage Caps**: Maximum loss is limited to 10-30% of current money (based on security level)
2. **Mitigation Scaling**: Higher security ratings reduce both frequency and damage
3. **Experience Bonus**: Base security improves with XP (cybersecurity skills)
4. **Earnings Bonus**: Better security provides small idle earnings bonus

### Balance Considerations

- **Early Game**: Low security means frequent small attacks, encouraging basic security investment
- **Mid Game**: Specialized defenses become cost-effective against specific threat types  
- **Late Game**: High-tier threats require advanced countermeasures to maintain profitability
- **Progression**: Experience from handling threats gradually improves baseline security

## Implementation Details

### Core Files
- `src/systems/idle_system.lua` - Main idle mechanics logic
- `src/systems/upgrade_system.lua` - Security infrastructure upgrades
- `src/ui/ui_manager.lua` - Offline progress summary display

### Integration Points
- Resource System: Handles earnings and damage application
- Threat System: Provides base threat reduction values
- Upgrade System: Provides security infrastructure data
- Event Bus: Coordinates between systems

### Testing
- Unit tests in `tests/systems/test_idle_system.lua`
- Covers threat simulation, damage calculation, and state management

## Future Enhancements

1. **Dynamic Threat Landscape**: Seasonal or event-based threat patterns
2. **Security Automation**: Upgrades that auto-purchase countermeasures
3. **Threat Intelligence**: Learning system that adapts to player's weak points
4. **Recovery Mechanisms**: Insurance or backup systems for major incidents
5. **Multiplayer Elements**: Shared threat intelligence or cooperative defense