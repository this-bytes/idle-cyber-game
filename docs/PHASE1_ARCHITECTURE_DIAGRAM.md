# Phase 1 SLA System - Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         PHASE 1: CORE SLA SYSTEM                            │
│                              Architecture                                    │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                              EVENT BUS                                       │
│  (Decoupled communication - all systems publish/subscribe to events)        │
└─────────────────────────────────────────────────────────────────────────────┘
           │                    │                    │                    │
           │                    │                    │                    │
           ▼                    ▼                    ▼                    ▼
┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐  ┌──────────┐
│  ContractSystem  │  │    SLASystem     │  │  ResourceManager │  │   UI     │
│                  │  │                  │  │                  │  │          │
│ ┌──────────────┐ │  │ ┌──────────────┐ │  │                  │  │          │
│ │  Capacity    │ │  │ │  Tracking    │ │  │                  │  │          │
│ │  Management  │ │  │ │              │ │  │                  │  │          │
│ │              │ │  │ │ • Compliance │ │  │                  │  │          │
│ │ • Calculate  │ │  │ │ • Incidents  │ │  │                  │  │          │
│ │ • Validate   │ │  │ │ • Rewards    │ │  │                  │  │          │
│ │ • Degrade    │ │  │ │ • Penalties  │ │  │                  │  │          │
│ └──────────────┘ │  │ └──────────────┘ │  │                  │  │          │
└──────────────────┘  └──────────────────┘  └──────────────────┘  └──────────┘
           │                    │                    │
           │                    │                    │
           ▼                    ▼                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                       GAME STATE ENGINE                                      │
│            (Manages save/load for all systems)                               │
│                                                                               │
│  Registered Systems:                                                         │
│  • resourceManager    → getState() / loadState()                            │
│  • contractSystem     → getState() / loadState()                            │
│  • slaSystem          → getState() / loadState()                            │
│  • specialistSystem   → getState() / loadState()                            │
│  • ... (other systems)                                                       │
└─────────────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
                          ┌────────────────┐
                          │  game_state    │
                          │     .json      │
                          └────────────────┘


┌─────────────────────────────────────────────────────────────────────────────┐
│                         CONTRACT LIFECYCLE                                   │
└─────────────────────────────────────────────────────────────────────────────┘

  Generated          Accepted              Active               Completed
     │                  │                    │                      │
     │  ┌───────────────┴──────────────┐    │                      │
     │  │ 1. Check Capacity            │    │                      │
     │  │    canAcceptContract()       │    │                      │
     │  │                              │    │                      │
     │  │ 2. Validate Requirements     │    │                      │
     │  │    - Specialists available   │    │                      │
     │  │    - Not at max overload     │    │                      │
     │  └──────────────┬───────────────┘    │                      │
     │                 │                     │                      │
     ▼                 ▼                     ▼                      ▼
┌─────────┐      ┌─────────┐          ┌─────────┐          ┌─────────┐
│Available│──────│  Check  │──────────│ Active  │──────────│Completed│
│Contract │ YES  │Capacity │   OK     │Contract │ Time=0   │Contract │
└─────────┘      └─────────┘          └─────────┘          └─────────┘
                      │                     │                      │
                      │ NO / WARNING        │                      │
                      │                     │                      │
     ┌────────────────┴────────┐     ┌─────┴────────┐      ┌──────┴────────┐
     │ Events Published:       │     │ Income Gen   │      │ SLA Score     │
     │ • contract_accepted     │     │ • Every 0.1s │      │ • Calculate   │
     │ • contract_capacity_    │     │ • Apply perf │      │ • Rewards     │
     │   changed               │     │   multiplier │      │ • Penalties   │
     │ • contract_overloaded   │     │              │      │               │
     │   (if over capacity)    │     │              │      │               │
     └─────────────────────────┘     └──────────────┘      └───────────────┘
                                            │
                                            │
                                     ┌──────┴──────┐
                                     │ Performance │
                                     │ Multiplier  │
                                     │             │
                                     │ At cap: 1.0 │
                                     │ 1 over: 0.85│
                                     │ 2 over: 0.70│
                                     │ 3+ over:0.50│
                                     └─────────────┘


┌─────────────────────────────────────────────────────────────────────────────┐
│                      CAPACITY CALCULATION FLOW                               │
└─────────────────────────────────────────────────────────────────────────────┘

    ┌──────────────────┐
    │  Specialists     │
    │  Count: N        │
    └────────┬─────────┘
             │
             ▼
    ┌──────────────────┐
    │  Base Capacity   │
    │  floor(N / 5)    │
    └────────┬─────────┘
             │
             ▼
    ┌──────────────────┐     ┌────────────────────┐
    │  Average         │────▶│ Efficiency         │
    │  Efficiency      │     │ Multiplier         │
    │  (from levels)   │     │ 1+(eff-1)*0.5      │
    └──────────────────┘     └────────┬───────────┘
                                      │
                                      ▼
    ┌──────────────────┐     ┌────────────────────┐
    │  Upgrade Bonus   │────▶│ Total Capacity     │
    │  (from upgrades) │     │ max(1, floor(...)) │
    └──────────────────┘     └────────────────────┘
                                      │
                                      ▼
    ┌──────────────────────────────────────────────┐
    │  Active Contracts vs Capacity                │
    │  • Under/At:  Accept with "OK"               │
    │  • 1-3 over:  Accept with "WARNING"          │
    │  • 4+ over:   Reject with "Maximum capacity" │
    └──────────────────────────────────────────────┘


┌─────────────────────────────────────────────────────────────────────────────┐
│                         SLA TRACKING FLOW                                    │
└─────────────────────────────────────────────────────────────────────────────┘

  Contract Accepted                Contract Active              Contract Complete
         │                                 │                           │
         ▼                                 │                           │
┌──────────────────┐                       │                           │
│  Create Tracker  │                       │                           │
│  • Start time    │                       │                           │
│  • Requirements  │                       │                           │
│  • Incidents: 0  │                       │                           │
│  • Breaches: 0   │                       │                           │
│  • Score: 1.0    │                       │                           │
└────────┬─────────┘                       │                           │
         │                                 │                           │
         │          During Gameplay        ▼                           │
         │      ┌──────────────────────────────────┐                   │
         │      │  Record Incidents (optional)     │                   │
         │      │  • slaSystem:recordIncident()    │                   │
         │      │  • Checks vs maxAllowedIncidents │                   │
         │      │  • Increments breach count       │                   │
         │      │  • Publishes sla_breach event    │                   │
         │      └──────────────────────────────────┘                   │
         │                                                              │
         └──────────────────────────────────────────────────────────────┘
                                                                        │
                                                                        ▼
                                                         ┌─────────────────────┐
                                                         │ Calculate Score     │
                                                         │ • Check incidents   │
                                                         │ • Check breaches    │
                                                         │ • Score: 0.0 - 1.0  │
                                                         └──────────┬──────────┘
                                                                    │
                                    ┌───────────────────────────────┴────────────┐
                                    │                                            │
                          ┌─────────▼─────────┐                     ┌───────────▼──────────┐
                          │  Rewards          │                     │  Penalties           │
                          │  (if score >= 0.85)│                    │  (if score < 0.75)   │
                          │                   │                     │                      │
                          │ • Perfect: bonus  │                     │ • Breach: fine       │
                          │ • Good: bonus*0.7 │                     │ • Factor: 1-score    │
                          └───────────────────┘                     └──────────────────────┘
                                    │                                            │
                                    └────────────────┬───────────────────────────┘
                                                     │
                                                     ▼
                                             ┌───────────────┐
                                             │ Update Metrics│
                                             │ • Total       │
                                             │ • Compliant   │
                                             │ • Breached    │
                                             │ • Comp. Rate  │
                                             └───────────────┘


┌─────────────────────────────────────────────────────────────────────────────┐
│                         DATA FLOW                                            │
└─────────────────────────────────────────────────────────────────────────────┘

    contracts.json              sla_config.json
         │                            │
         │                            │
         ▼                            ▼
    ┌─────────┐                 ┌─────────┐
    │  Data   │                 │  Data   │
    │ Manager │                 │ Manager │
    └────┬────┘                 └────┬────┘
         │                            │
         ├────────────┬───────────────┘
         │            │
         ▼            ▼
    Contract     SLA System
     System      • Thresholds
    • Templates  • Multipliers
    • SLA reqs   • Settings


┌─────────────────────────────────────────────────────────────────────────────┐
│                    KEY INTEGRATION POINTS                                    │
└─────────────────────────────────────────────────────────────────────────────┘

1. soc_game.lua (Main Integration)
   └─▶ require("src.systems.sla_system")
   └─▶ SLASystem.new(eventBus, contractSystem, resourceManager, dataManager)
   └─▶ gameStateEngine:registerSystem("slaSystem", slaSystem)
   └─▶ slaSystem:initialize()

2. contract_system.lua (Enhanced Methods)
   ├─▶ calculateWorkloadCapacity() → returns number
   ├─▶ canAcceptContract(contract) → returns bool, string
   ├─▶ getPerformanceMultiplier() → returns 0.5 - 1.0
   ├─▶ generateIncome() → applies multiplier
   └─▶ acceptContract() → checks capacity, publishes events

3. sla_system.lua (Event Handlers)
   ├─▶ contract_accepted → onContractAccepted()
   ├─▶ contract_completed → onContractCompleted()
   └─▶ contract_failed → onContractFailed()

4. EventBus (Published Events)
   ├─▶ contract_capacity_changed {capacity, activeCount}
   ├─▶ contract_overloaded {capacity, activeCount, overload}
   ├─▶ sla_breach {contractId, reason, incidentCount}
   ├─▶ sla_bonus_earned {contractId, amount, complianceScore}
   └─▶ sla_penalty_applied {contractId, amount, complianceScore}


┌─────────────────────────────────────────────────────────────────────────────┐
│                           TESTING POINTS                                     │
└─────────────────────────────────────────────────────────────────────────────┘

Unit Tests:
  ✅ SLA System
     • Initialization
     • Config loading
     • Contract tracking
     • Compliance calculation
     • Incident recording
     • State persistence
     • Compliance ratings

  ✅ Contract Capacity
     • Capacity with 0/5/10 specialists
     • Efficiency calculation
     • Performance at capacity
     • Performance degradation
     • Accept validation
     • State persistence

Integration Tests:
  ✅ JSON validation
  ✅ Lua syntax
  ✅ SLA requirements structure
  ✅ Integration points
  ✅ Contract enhancements

Manual Tests (see PHASE1_TESTING_GUIDE.md):
  ⏳ System initialization
  ⏳ Capacity calculation
  ⏳ Contract acceptance
  ⏳ Performance degradation
  ⏳ Save/load persistence
```
