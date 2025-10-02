# Incident Design System — Idle Sec Ops

## Overview
This document defines the Incident system design based on SLA-driven contracts, reputation scaling, and unique victory conditions for each threat type.

## Core Design Principles

### 1. SLA-Driven Incident Generation (Contract Focus)
**Philosophy:** More contracts = more attack surface = more crises

**Mechanics:**
- Each active contract has an SLA (Service Level Agreement) defining:
  - **Uptime Guarantee**: 99.9%, 99.99%, etc.
  - **Response Time**: Time to detect and respond to incidents
  - **Threat Coverage**: Which threat types the contract protects against
  - **Incident Frequency**: Base rate of Incident generation per contract

**Incident Generation Formula:**
```
Incident Chance per Minute = 
    Σ(Active Contracts × Contract Risk Factor) 
    × Global Threat Level 
    × (1 - Defense Effectiveness)

Where:
- Contract Risk Factor = 0.5 (low-tier) to 2.0 (government/enterprise)
- Global Threat Level = 1.0 base, increases with reputation
- Defense Effectiveness = 0.0 (no upgrades) to 0.7 (max automation)
```

**Example:**
```
Startup Contract: 1 × 0.5 = 0.5% chance/min (Incident every ~200 min)
FinTech Contract: 1 × 1.2 = 1.2% chance/min (Incident every ~83 min)
Gov Contract: 1 × 2.0 = 2.0% chance/min (Incident every ~50 min)

3 Active Contracts = Combined 3.7% chance/min (Incident every ~27 min)
```

**SLA Impact on Incident Severity:**
- Breaking SLA = Reputation damage
- Maintaining SLA = Reputation bonus
- Perfect response (under time limit) = Contract renewal bonus

### 2. Reputation-Based Threat Unlocks

**Threat Tier System:**

**Tier 1: Opportunistic (0-50 Reputation)**
- Phishing attempts
- Basic malware
- Script kiddie attacks
- **Victory Condition:** Simple containment

**Tier 2: Organized Crime (51-150 Reputation)**
- DDoS attacks
- Ransomware
- Coordinated phishing campaigns
- **Victory Condition:** Multi-stage resolution

**Tier 3: Advanced Threats (151-300 Reputation)**
- Data exfiltration
- Insider threats
- Supply chain attacks
- **Victory Condition:** Investigation + containment

**Tier 4: Nation-State (301+ Reputation)**
- APT (Advanced Persistent Threat)
- Zero-day exploits
- Multi-vector attacks
- **Victory Condition:** Long-term hunt, requires elite specialists

**Unlock Progression:**
```
Rep 0: Phishing, Basic Malware unlocked
Rep 50: DDoS, Ransomware unlocked
Rep 100: Data Exfiltration unlocked
Rep 150: Insider Threat, Supply Chain unlocked
Rep 250: APT unlocked
Rep 400: Zero-Day unlocked
Rep 500: Incident Combos (multiple simultaneous) unlocked
```

### 3. Incident Combo Events (The "OH SH*T" Moments)

**Combo Triggers:**
- 10% chance when reputation > 200
- 20% chance when reputation > 400
- 30% chance when managing 5+ contracts

**Combo Types:**

**Distraction Attack:**
```
DDoS Attack (draws attention)
  └─ While responding → Ransomware deploys (real threat)
Requires: Split team or prioritization decision
```

**Multi-Vector Assault:**
```
Phishing Campaign
  ├─ Compromised Credentials
  │   └─ Insider Threat
  │       └─ Data Exfiltration
Requires: Multi-stage investigation
```

**Coordinated Strike:**
```
Simultaneous:
├─ Client A: Ransomware
├─ Client B: DDoS
└─ Client C: Data Breach
Requires: Team management, specialist allocation
```

**Combo Rewards:**
- 2x XP for all specialists involved
- 3x reputation gain on success
- Rare "Mission Token" rewards
- Unlock special achievements

## Incident Type Design

### Incident Type: Phishing Campaign

**Flavor:** Social engineering attack targeting client employees

**Victory Condition:** Identify and contain before X% of employees click malicious links

**Stages:**
1. **Detection (Auto-complete)**
   - Unusual email volume spike detected
   - Time: Instant
   
2. **Analysis (Decision Point)**
   - Determine scope: How many targets? What's the payload?
   - Options:
     - Deploy Analyst (High accuracy, costs specialist time)
     - Automated Scan (Fast, 70% accuracy)
     - Manual Review (Thorough, slow)
   - Time: 60 seconds
   
3. **Containment (Active)**
   - Block sender domains
   - Quarantine emails
   - Progress bar: Block rate vs click rate
   - Time: 90 seconds
   
4. **User Education (Passive)**
   - Send warnings to employees
   - Auto-completes if containment successful

**Success Conditions:**
- Perfect: <5% employees affected, under time limit → +100 Rep, +75 XP
- Success: <20% employees affected → +50 Rep, +50 XP  
- Partial: <50% employees affected → +10 Rep, +25 XP
- Failure: >50% affected or timeout → -25 Rep, +10 XP (learning experience)

**Required Abilities:** basic_analysis, network_fundamentals
**Scales With:** Number of employees at client (startup vs enterprise)

---

### Incident Type: Ransomware Attack

**Flavor:** Encryption malware spreading through client network

**Victory Condition:** Stop encryption before X% of systems locked OR successfully recover

**Stages:**
1. **Detection (Auto-complete)**
   - File encryption activity detected
   - Time: Instant
   
2. **Isolation (Critical)**
   - Isolate infected systems to prevent spread
   - Network segmentation required
   - Failure = exponential spread
   - Time: 45 seconds (URGENT!)
   
3. **Decision Point: Strategy Choice**
   - Option A: Analyze & Decrypt (Requires malware_analysis skill)
   - Option B: Restore from Backup (Costs money, faster)
   - Option C: Negotiate (Risky, may reduce ransom but costs reputation)
   - Time: 30 seconds to decide
   
4. **Execution**
   - Based on choice, different resolution paths
   - Analysis: Identify variant, find decryption key
   - Backup: Restore systems, patch vulnerability
   - Negotiate: Interact with attackers (mini-game?)
   - Time: 120-180 seconds

**Success Conditions:**
- Perfect: 0% data loss, under 3 minutes → +150 Rep, +100 XP, Mission Token
- Success: <10% data loss → +75 Rep, +75 XP
- Partial: 10-30% data loss → +20 Rep, +40 XP
- Failure: >30% loss or paid ransom → -50 Rep, +15 XP

**Required Abilities:** network_fundamentals (isolation), malware_analysis (decrypt path)
**Scales With:** Client data value (higher tier = more pressure, better rewards)

---

### Incident Type: DDoS Attack

**Flavor:** Distributed botnet flooding client services

**Victory Condition:** Maintain service uptime above SLA threshold

**Stages:**
1. **Detection (Auto-complete)**
   - Massive traffic spike detected
   - Uptime starting to degrade
   
2. **Triage (Real-time)**
   - Identify attack vectors (HTTP flood, UDP amp, etc.)
   - Required: network_fundamentals
   - Time: 30 seconds
   
3. **Mitigation (Active Defense)**
   - Deploy countermeasures based on attack type
   - Rate limiting, traffic filtering, CDN routing
   - **Real-time mini-game:** Balance mitigation vs false positives
   - Uptime bar: Keep above 95% for SLA compliance
   - Time: 120 seconds (attack duration)
   
4. **Source Tracing (Optional Bonus)**
   - Track botnet C&C servers
   - Rewards bonus reputation if successful
   - Requires: advanced network skills
   - Time: 60 seconds after mitigation

**Success Conditions:**
- Perfect: 100% uptime maintained → +100 Rep, +60 XP, Block future DDoS
- Success: >99% uptime (SLA met) → +60 Rep, +45 XP
- Partial: 95-99% uptime (SLA missed) → +20 Rep, +30 XP, -10 Rep penalty
- Failure: <95% uptime → -40 Rep, +15 XP

**Required Abilities:** network_fundamentals, traffic_analysis (advanced)
**Scales With:** Attack size (100 Mbps → 1 Tbps), client SLA strictness

---

### Incident Type: Data Exfiltration

**Flavor:** Sensitive data being stolen from client systems

**Victory Condition:** Stop data transfer before critical threshold breached

**Stages:**
1. **Detection (Auto-complete)**
   - Unusual outbound data transfer detected
   - Data loss meter starts filling
   
2. **Forensics (Investigation)**
   - Identify: What data? Where going? Who authorized?
   - Requires: basic_analysis + forensics skill
   - Time: 60 seconds
   
3. **Containment (Race Against Time)**
   - Block exfiltration channels
   - Data loss increases over time (progress bar)
   - Must act before critical data threshold (e.g., customer PII, trade secrets)
   - Time: 90 seconds
   
4. **Damage Assessment**
   - Determine what was stolen
   - Impact on client business
   - May trigger follow-up investigations

**Success Conditions:**
- Perfect: <1% data lost, attacker identified → +120 Rep, +90 XP, Mission Token
- Success: <10% data lost → +70 Rep, +60 XP
- Partial: 10-25% data lost → +20 Rep, +35 XP
- Failure: >25% data lost → -60 Rep, +20 XP, possible contract loss

**Required Abilities:** forensics, network_fundamentals, data_analysis
**Scales With:** Data sensitivity (public info vs trade secrets vs PII)

---

### Incident Type: Insider Threat

**Flavor:** Employee or contractor acting maliciously

**Victory Condition:** Identify culprit and contain before they escape/cover tracks

**Stages:**
1. **Detection (Subtle)**
   - Behavioral anomalies detected (privilege escalation, unusual access)
   - Not immediately obvious it's an insider
   
2. **Investigation (Detective Work)**
   - Review access logs, behavior patterns
   - Interview suspects (multiple choice decisions)
   - Build evidence case
   - **Suspicion mechanic:** Tipping off suspect = they flee/destroy evidence
   - Time: 180 seconds
   
3. **Identification**
   - Multiple suspects, must identify correct one
   - Wrong accusation = reputation damage
   - Requires: behavioral_analysis, forensics
   - Time: 60 seconds
   
4. **Containment**
   - Revoke access, secure evidence
   - Prevent data destruction
   - Time: 30 seconds (if identified correctly)

**Success Conditions:**
- Perfect: Correct ID on first try, no data lost → +140 Rep, +110 XP, Mission Token
- Success: Correct ID, minimal data lost → +80 Rep, +70 XP
- Partial: Correct ID but data destroyed → +30 Rep, +40 XP
- Failure: Wrong ID or suspect escapes → -70 Rep, +25 XP, possible legal liability

**Required Abilities:** behavioral_analysis, forensics, investigation
**Scales With:** Insider access level (low-level employee vs admin vs executive)

---

### Incident Type: APT (Advanced Persistent Threat)

**Flavor:** Nation-state actor establishing long-term presence

**Victory Condition:** Hunt and eliminate all persistence mechanisms

**Stages:**
1. **Initial Detection (Delayed)**
   - Subtle indicators discovered (may be weeks after initial compromise)
   - Threat actor already has foothold
   
2. **Reconnaissance (Hunt)**
   - Map attacker infrastructure within network
   - Identify: Entry point, lateral movement, persistence mechanisms
   - **Stealth requirement:** Don't alert attacker that you're hunting
   - Time: 240 seconds
   
3. **Containment Planning**
   - Plan coordinated removal of all attacker infrastructure
   - Must remove ALL at once or they'll realize and adapt
   - Strategic decision: What to remove in what order?
   - Time: 120 seconds
   
4. **Execution (Synchronized Strike)**
   - Deploy specialists to execute removal plan
   - Success depends on planning quality + specialist skills
   - Time: 90 seconds
   
5. **Validation**
   - Verify attacker fully removed
   - Patch vulnerabilities
   - Monitor for re-entry attempts

**Success Conditions:**
- Perfect: Complete removal, no data loss, vulnerabilities patched → +200 Rep, +150 XP, 2 Mission Tokens
- Success: Attacker removed, minimal damage → +100 Rep, +100 XP, Mission Token
- Partial: Attacker removed but data stolen/damaged → +40 Rep, +60 XP
- Failure: Attacker persists or returns → -100 Rep, +30 XP, contract at risk

**Required Abilities:** Advanced forensics, threat_intelligence, network_analysis, malware_analysis
**Scales With:** Attacker sophistication (criminal group vs nation-state)

---

### Incident Type: Zero-Day Exploit

**Flavor:** Unknown vulnerability being actively exploited

**Victory Condition:** Identify vulnerability and deploy mitigation before widespread damage

**Stages:**
1. **Detection (Cryptic)**
   - Unusual system behavior, no known signature
   - "Unknown exploit detected" - no details
   
2. **Research (Puzzle-solving)**
   - Reverse-engineer the exploit
   - Identify affected systems
   - **Research mini-game:** Analyze memory dumps, network traces
   - Requires: Advanced skills + time
   - Time: 180 seconds (PRESSURE!)
   
3. **Mitigation Development**
   - Create temporary patch or workaround
   - Trade-off: Quick dirty fix vs thorough solution
   - Quick = may have gaps, Thorough = takes longer
   - Time: 120 seconds
   
4. **Deployment**
   - Roll out mitigation to affected systems
   - Monitor for exploitation attempts
   - Time: 90 seconds

**Success Conditions:**
- Perfect: Identified + patched before exploitation → +180 Rep, +140 XP, 2 Mission Tokens, Industry Recognition
- Success: Patched, minimal exploitation → +90 Rep, +90 XP, Mission Token
- Partial: Patched but significant damage → +30 Rep, +50 XP
- Failure: Unpatched or severe damage → -80 Rep, +35 XP

**Required Abilities:** malware_analysis (advanced), vulnerability_research, exploit_development
**Scales With:** Vulnerability impact (low-priority service vs critical infrastructure)

---

## Incident Scaling Mechanics

### Time Pressure Scaling
```
Early Game (Rep 0-100):
- Base time limits: 180-300 seconds
- Grace periods for mistakes
- Tutorial hints available

Mid Game (Rep 101-300):
- Base time limits: 120-180 seconds  
- Multiple stages required
- Combo events start appearing

Late Game (Rep 301+):
- Base time limits: 60-120 seconds
- Complex multi-stage crises
- Frequent combos
- Requires specialized teams
```

### Difficulty Modifiers
```
Contract Tier Multiplier:
- Startup/SMB: 0.8x difficulty (easier, lower rewards)
- Mid-Market: 1.0x difficulty (baseline)
- Enterprise: 1.3x difficulty (harder, better rewards)
- Government: 1.6x difficulty (hardest, best rewards)

Active Contract Count:
- 1-2 contracts: Normal frequency
- 3-5 contracts: +50% Incident frequency
- 6+ contracts: +100% Incident frequency, +20% combo chance

Facility Level:
- Garage: No defensive bonuses
- Office: -10% Incident frequency (basic automation)
- Corporate HQ: -25% Incident frequency, +10% success chance
- Global Center: -40% Incident frequency, +20% success chance, early warnings
```

## SLA System Integration

### Contract SLA Examples

**Startup Contract - "DevShop Co"**
```
SLA Terms:
- Uptime: 99% (lenient)
- Response Time: <5 minutes
- Coverage: Tier 1 threats only
- Incident Frequency: Low (0.5% per min)
- Penalty for SLA breach: -5 Rep
- Bonus for perfect month: +10 Rep
```

**FinTech Contract - "CryptoPay Inc"**
```
SLA Terms:
- Uptime: 99.9% (strict)
- Response Time: <2 minutes
- Coverage: Tier 1 & 2 threats
- Incident Frequency: Medium (1.2% per min)
- Penalty for SLA breach: -20 Rep, -$5000
- Bonus for perfect month: +30 Rep, +$10000
```

**Government Contract - "DOD Cyber Command"**
```
SLA Terms:
- Uptime: 99.99% (critical)
- Response Time: <60 seconds
- Coverage: All threat tiers including APT
- Incident Frequency: High (2.0% per min)
- Incident Difficulty: +60%
- Penalty for SLA breach: -50 Rep, contract termination risk
- Bonus for perfect month: +75 Rep, +$25000, Mission Tokens
```

### SLA Tracking
```
Per Contract:
- Uptime percentage (real-time)
- Average response time
- Incidents detected vs resolved
- SLA compliance score (0-100%)

Player Dashboard:
- Overall SLA compliance across all contracts
- "At Risk" contract warnings
- SLA bonuses available this month
- Next SLA review dates
```

## Incident Rewards

### XP Distribution
```
Incident Base XP:
- Phishing: 50 XP
- DDoS: 75 XP
- Malware: 60 XP
- Ransomware: 100 XP
- Data Exfil: 90 XP
- Insider: 110 XP
- APT: 150 XP
- Zero-Day: 140 XP

Multipliers:
- Perfect resolution: 1.5x XP
- Under time pressure: 1.3x XP
- Using correct abilities: 1.2x XP
- First time solving Incident type: 2.0x XP
- Combo event: 2.0x XP per Incident

Distribution:
- Deployed specialists: Share 80% of XP equally
- Non-deployed specialists: Share 20% of XP (learning from team)
```

### Reputation Impact
```
Success: +Rep based on Incident tier and client importance
Partial: Small +Rep, SLA may be affected
Failure: -Rep, SLA breach, possible contract loss

Reputation Milestones:
- 50 Rep: Unlock Tier 2 threats
- 100 Rep: Unlock mid-market contracts
- 150 Rep: Unlock Tier 3 threats
- 200 Rep: Unlock enterprise contracts  
- 300 Rep: Unlock government contracts
- 400 Rep: Unlock Tier 4 elite threats
- 500 Rep: Legendary status, prestige options
```

### Mission Tokens
```
Earned From:
- Perfect Incident resolution (random chance)
- APT/Zero-Day successful hunts (guaranteed)
- Combo event resolution (guaranteed)
- Monthly SLA bonus (government contracts)

Used For:
- Hire elite specialists
- Unlock advanced research
- Emergency response (instant specialist recall)
- Prestige system activation
```

## Player Experience Goals

### Early Game (0-2 hours)
- Learn Incident mechanics with simple phishing/malware
- Understand SLA system through starter contracts
- Feel tension: "Oh no, Incident! But I can handle this."
- Build confidence through successful resolutions

### Mid Game (2-8 hours)
- Juggle multiple contracts and Incident types
- Strategic specialist deployment decisions
- Experience first combo event ("OH SH*T moment")
- Build specialized team roles

### Late Game (8+ hours)
- Master complex multi-stage crises
- Handle simultaneous crises across contracts
- Hunt APTs and zero-days like a pro
- Feel like cybersecurity legend

### Endgame (Prestige Ready)
- Perfect SLA compliance across all contracts
- Elite team of specialized experts
- Consistent APT/Zero-Day victories
- Ready to "exit" and start with legacy bonuses

## Implementation Notes for Coding Agent

When implementing crises:
1. Each Incident type should be data-driven (crises.json)
2. Stage progression should fire events for UI updates
3. Timer system should respect pause/slow-mo for accessibility
4. SLA tracking should be persistent (save/load)
5. Reputation changes should fire through ResourceManager
6. XP distribution should use SpecialistSystem methods
7. All Incident mechanics should be testable without UI

## Future Expansion Ideas

- **Dynamic Incident Generation:** Procedurally generate Incident variations
- **Incident History Log:** Review past crises for learning
- **Incident Simulator:** Practice mode for learning mechanics
- **Weekly/Monthly Challenges:** Special Incident events with leaderboards
- **Client-Specific Crises:** Each client type has unique Incident flavors
- **Incident Chains:** Resolving one Incident prevents/triggers follow-up crises
