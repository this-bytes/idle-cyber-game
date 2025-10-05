# Phase 1 SLA System - Manual Testing Guide

## Overview
This document provides manual testing procedures for Phase 1 of the SLA System implementation.

## Prerequisites
- Game must be able to launch: `love .`
- Console output should be visible

## Test 1: System Initialization

**Expected Result**: All systems initialize without errors

**Steps**:
1. Launch the game: `love .`
2. Check console output

**Success Criteria**:
- ✅ See: "🛡️ Initializing SOC Game Systems..."
- ✅ See: "📊 SLASystem: Initializing..."
- ✅ See: "📊 SLASystem: Initialized"
- ✅ No error messages related to SLA system
- ✅ Game reaches main menu

## Test 2: Capacity Calculation

**Expected Result**: Capacity is calculated based on specialist count

**Steps**:
1. Start a new game
2. Check initial capacity (should be 1 with 1 specialist)
3. Hire 4 more specialists (5 total)
4. Capacity should still be 1 (5 specialists = 1 capacity)
5. Hire 5 more specialists (10 total)
6. Capacity should increase to 2

**Success Criteria**:
- ✅ Capacity formula: floor(specialists / 5)
- ✅ Minimum capacity is 1
- ✅ Capacity increases with specialists

## Test 3: Contract Acceptance Up To Capacity

**Expected Result**: Can accept contracts up to capacity limit

**Steps**:
1. Start with 5 specialists (capacity = 1)
2. Accept 1 contract
3. Try to accept another contract
4. Should accept with warning

**Success Criteria**:
- ✅ First contract accepted without warning
- ✅ Second contract accepted with warning
- ✅ Console shows: "⚠️ Contracts overloaded!"

## Test 4: Performance Degradation

**Expected Result**: Performance degrades when over capacity

**Steps**:
1. Have 5 specialists (capacity = 1)
2. Accept 2 contracts (1 over capacity)
3. Check income rate (should be 85% of normal)
4. Accept 3rd contract (2 over capacity)
5. Check income rate (should be 70% of normal)
6. Accept 4th contract (3 over capacity)
7. Check income rate (should be 50% of normal)

**Success Criteria**:
- ✅ At capacity: 100% income
- ✅ 1 over: 85% income
- ✅ 2 over: 70% income
- ✅ 3+ over: 50% income (minimum)

## Test 5: Maximum Capacity Rejection

**Expected Result**: Cannot accept contracts beyond max overload

**Steps**:
1. Have 5 specialists (capacity = 1)
2. Accept 4 contracts
3. Try to accept 5th contract
4. Should be rejected

**Success Criteria**:
- ✅ Console shows capacity warning
- ✅ Contract is not accepted
- ✅ Available contracts list still shows the contract

## Test 6: SLA Requirements on Contracts

**Expected Result**: Contracts with SLA requirements load correctly

**Steps**:
1. Start game
2. View available contracts
3. Check that some contracts have SLA requirements

**Success Criteria**:
- ✅ At least 5 contract types have SLA requirements
- ✅ SLA requirements include: maxAllowedIncidents
- ✅ Contracts have capacity requirements, rewards, and penalties
- ✅ Game doesn't crash when loading contracts

## Test 7: Contract Lifecycle Events

**Expected Result**: Events are published correctly

**Steps**:
1. Accept a contract
2. Check console for "contract_accepted" event
3. Wait for contract to complete
4. Check console for "contract_completed" event

**Success Criteria**:
- ✅ "contract_accepted" published with contract data
- ✅ "contract_capacity_changed" published when accepting
- ✅ "contract_completed" published when done
- ✅ SLA tracking starts on acceptance

## Test 8: Save and Load

**Expected Result**: State persists across sessions

**Steps**:
1. Start game and accept some contracts
2. Check capacity and active contracts
3. Save game (automatic after 60 seconds)
4. Close and restart game
5. Load saved game

**Success Criteria**:
- ✅ Active contracts restored
- ✅ Capacity calculation still correct
- ✅ SLA tracking state preserved
- ✅ Performance multiplier still applies

## Test 9: SLA Tracking

**Expected Result**: SLA metrics are tracked per contract

**Steps**:
1. Accept a contract with SLA requirements
2. Complete the contract
3. Check SLA metrics

**Success Criteria**:
- ✅ SLA tracker created on acceptance
- ✅ Compliance score calculated on completion
- ✅ Metrics updated (total contracts, compliant contracts)

## Debugging Tips

### Console Commands
If the game has a console, try:
```lua
-- Check capacity
print(game.systems.contractSystem:calculateWorkloadCapacity())

-- Check performance multiplier
print(game.systems.contractSystem:getPerformanceMultiplier())

-- Check SLA metrics
print(game.systems.slaSystem:getMetrics())
```

### Common Issues

**Issue**: "attempt to index nil value (field 'specialistSystem')"
- **Cause**: SpecialistSystem not initialized before ContractSystem
- **Fix**: Check initialization order in soc_game.lua

**Issue**: Capacity always 1
- **Cause**: Specialists not being counted correctly
- **Fix**: Verify specialistSystem.specialists table is populated

**Issue**: Performance multiplier not applying
- **Cause**: Income calculation not calling getPerformanceMultiplier()
- **Fix**: Check generateIncome() and getTotalIncomeRate()

## Expected Console Output

On successful startup, you should see:
```
🛡️ Initializing SOC Game Systems...
🎨 LUIS initialized.
📂 Loaded game state from previous session (or Starting new game)
📜 Contract system initialized with X contract types
📊 SLASystem: Initializing...
📊 SLASystem: Initialized
✅ SOC Game Systems Initialized!
```

When accepting contracts:
```
Accepted contract: [Client Name] (Assigned: CEO)
📊 SLASystem: Tracking started for contract [ID]
```

When over capacity:
```
⚠️ Contracts overloaded! Capacity: 1, Active: 2
```

## Test Results Template

Date: ___________
Tester: ___________

| Test | Pass | Fail | Notes |
|------|------|------|-------|
| Test 1: Initialization | ☐ | ☐ | |
| Test 2: Capacity Calc | ☐ | ☐ | |
| Test 3: Accept Contracts | ☐ | ☐ | |
| Test 4: Performance Degradation | ☐ | ☐ | |
| Test 5: Rejection | ☐ | ☐ | |
| Test 6: SLA Requirements | ☐ | ☐ | |
| Test 7: Events | ☐ | ☐ | |
| Test 8: Save/Load | ☐ | ☐ | |
| Test 9: SLA Tracking | ☐ | ☐ | |
