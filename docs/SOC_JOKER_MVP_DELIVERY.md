# SOC Joker MVP - Core Systems Implementation

## ✅ Completed: Core Roguelike Systems

### 🎯 Objective
Transform the idle game into a Balatro-inspired card-based roguelike using existing systems. This document summarizes the three core systems delivered.

---

## 📦 Delivered Systems

### 1. RunManager (`src/systems/run_manager.lua`)
**Purpose**: Manages roguelike run state, progression, scoring, and rewards

**Key Features**:
- Run state management (menu, wave, shop, victory, defeat)
- Wave progression (3 waves per run)
- Difficulty scaling via "ante" system (1-8)
- Score calculation based on multiple factors
- Reward unlocking system
- Full GameStateEngine integration

**Core Methods**:
- `startRun(ante)` - Initialize new run with difficulty
- `completeWave(success)` - Handle wave completion and progression
- `endRun(victory)` - Calculate final score and unlock rewards
- `calculateScore()` - Multi-factor scoring system
- `getState()` / `loadState()` - Persistence support

**Statistics Tracked**:
- Threats defeated
- Cards played
- Perfect waves (no damage)
- Run duration
- Total runs/victories
- High score

---

### 2. DeckManager (`src/systems/deck_manager.lua`)
**Purpose**: Card-based deck building, hand management, and gameplay mechanics

**Key Features**:
- Starter deck initialization (3 Junior Analysts, 2 Firewalls)
- Card drawing with auto-shuffle
- Hand management (5 card maximum)
- Card playing and effect resolution
- Multiple card zones (draw pile, hand, discard, exhaust)
- Card types: Specialist, Tool, Threat

**Core Methods**:
- `initializeStarterDeck()` - Create basic starting deck
- `drawCards(count)` - Draw from deck to hand
- `playCard(handIndex, target)` - Play card on threat
- `shuffleDeck()` - Shuffle discard back into draw
- `resolveCardEffect(card, target)` - Apply card effects
- `endTurn()` - Discard hand and draw new cards

**Starter Cards**:
- **Junior Analyst**: Deal 2 damage (common)
- **Firewall**: Block 3 damage (common)
- **Senior Analyst**: Deal 4 damage (uncommon)
- **Threat Hunter**: Deal 3 + splash 1 (uncommon)
- **EDR Platform**: Deal 2 AOE (rare)

---

### 3. ThreatSystem Extensions (`src/systems/threat_system.lua`)
**Purpose**: Generate card-based threat waves for roguelike gameplay

**Key Features**:
- Wave generation based on ante and wave number
- Boss threats with enhanced stats
- Mega boss for final wave
- Health scaling by difficulty
- Uses existing threat templates from JSON
- Falls back to default threats if needed

**New Methods Added**:
- `generateWave(ante, waveNumber)` - Generate full wave of threats
- `createThreatCard(ante)` - Create individual threat from templates
- `createBossThreat(ante, mega)` - Create boss with boosted stats
- `calculateThreatHealth(baseHealth, ante)` - Scale health by difficulty
- `getThreatRarity(severity)` - Determine threat rarity

**Wave Configuration**:
- **Wave 1**: 5 common threats
- **Wave 2**: 7 threats + 1 boss
- **Wave 3**: 10 threats + 1 mega boss

**Difficulty Scaling**:
- Ante 1: 1.0x health multiplier
- Ante 2: 1.5x health multiplier
- Ante 3: 2.0x health multiplier
- Ante 4+: Continues scaling

---

## 🏗️ Architecture Integration

### System Dependencies
```
RunManager (priority: 55)
  └── ResourceManager

DeckManager (priority: 50)
  └── DataManager

ThreatSystem (priority: 30)
  ├── DataManager
  ├── SpecialistSystem
  └── SkillSystem
```

### Event Bus Integration
All systems publish events for cross-system communication:

**RunManager Events**:
- `run_started` - New run begins
- `wave_complete` - Wave finished
- `shop_opened` - Shop phase
- `wave_started` - New wave begins
- `run_ended` - Run completed

**DeckManager Events**:
- `cards_drawn` - Cards added to hand
- `card_played` - Card played on threat

### GameStateEngine Integration
All systems implement:
- `getState()` - Serialize state for saving
- `loadState(state)` - Restore state from save

---

## 🎮 Core Gameplay Loop

```
1. Player starts run (ante selection)
   ↓
2. DeckManager initializes starter deck
   ↓
3. ThreatSystem generates Wave 1 (5 threats)
   ↓
4. Player draws 5 cards
   ↓
5. Player plays cards to defeat threats
   ↓
6. Wave complete → Shop phase (future)
   ↓
7. Repeat for Waves 2-3
   ↓
8. Run ends → Score calculated → Rewards unlocked
```

---

## 🚀 Next Steps

### Phase 2: Basic UI Scene
Create `src/scenes/run_scene_luis.lua`:
- Display threat board (3-5 threats)
- Show player hand (5 cards)
- Click to play mechanics
- Score/wave indicator
- End turn button

### Phase 3: Shop System
Create `src/systems/shop_system.lua`:
- Randomized card offerings
- Purchase mechanics
- Currency management
- Rarity-based pricing

### Phase 4: Integration
- Register systems with SystemRegistry
- Add scene to SceneManager
- Create menu button to start runs
- Wire up event handlers

---

## 📊 Testing Checklist

### RunManager Tests
- [ ] Start run initializes correctly
- [ ] Wave progression works (1→2→3)
- [ ] Victory/defeat handled properly
- [ ] Score calculation accurate
- [ ] State saves/loads correctly

### DeckManager Tests
- [ ] Starter deck has 5 cards
- [ ] Drawing works with auto-shuffle
- [ ] Cards play correctly
- [ ] Hand limit enforced (5 max)
- [ ] Card effects resolve

### ThreatSystem Tests
- [ ] Wave generation creates correct count
- [ ] Boss threats have boosted stats
- [ ] Health scales with ante
- [ ] Falls back to defaults gracefully

---

## 💡 Design Philosophy

**Data-Driven**: All cards and threats can be added via JSON
**Modular**: Systems work independently, connected via events
**Extensible**: Easy to add new card types, effects, waves
**Testable**: Clear interfaces for unit testing
**Performant**: Minimal object creation, efficient data structures

---

## 🎯 MVP Success Criteria

✅ **Core Systems Delivered**:
- RunManager handles run lifecycle
- DeckManager manages cards and hand
- ThreatSystem generates waves

**Remaining for Playable MVP**:
- Basic UI scene for card gameplay
- System registration and integration
- Win/lose condition handling
- Menu navigation

**Estimated Time to Playable**: 4-6 hours of UI development

---

## 📚 Code Quality

- **Lines of Code**: ~800 total
- **Documentation**: Comprehensive inline comments
- **Architecture**: Follows project patterns (SystemRegistry, EventBus, GameStateEngine)
- **No Breaking Changes**: Existing threat system functionality preserved
- **ADHD-Friendly**: Modular design enables incremental additions

---

## 🎉 Conclusion

The three core systems are complete and ready for integration. They provide a solid foundation for a Balatro-inspired cybersecurity roguelike. The modular design allows easy expansion with shops, jokers, deck building, and more content.

**Ready to build the UI and bring it to life!** 🎴⚡🔒
