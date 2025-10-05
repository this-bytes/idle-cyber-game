# Idle Sec Ops - Development TODO

## Current Priority: UI Modernization

### 🎯 Next: Refactor idle_debug.lua to SmartUIManager
Per user directive: "This should be the first screen we apply it to as its the in game screen to see the engine"

**Goals**:
- Replace manual love.graphics calls with SmartUIManager components
- Establish pattern for all future UI work
- Maintain debug functionality while improving UX
- Create reusable component library

---

## Development Notes

### Current Architecture Strengths
- ✅ **Event-driven system communication**
- ✅ **Modular system design**
- ✅ **Comprehensive test coverage** (NEW!)
- ✅ **Data-driven approach for flexibility**
- ✅ **Validated core mechanics** (NEW!)

### Areas for Improvement
- UI needs component-based architecture (IN PROGRESS - idle_debug.lua target)
- Engaging game progression - go from "want to play" to "need to play"
- Incident scenarios should be data-driven
- Resource management could be more sophisticated
- Performance monitoring for complex simulations

### Design Philosophy
- Maintain cybersecurity SOC theme authenticity (content can be tongue-in-cheek puns)
- Core idle engine needs to be robust to allow multiplication through stat/skill trees
- Balanced idle progression with incident engagement
- Player agency in business growth strategy

---

## Backlog

# Player Stats
All game stats need to save to the player. We need to handle persistence of this.

# Dashboard controls for selected item
When on dashboard and viewing the alert feed, need to be able to select any item

Game debug screen should be a complete snapshot of game and current multipliers as a live view of game state.

### Incident System 
- [ ] Create upgradable office starting with garage and expand, feeds into stats initially then scene changes
- [ ] Multiple incident scenarios with different threat types
- [ ] Dynamic incident generation based on active contracts, use RNG engine to determine stats
- [ ] Specialist system with upgrade, cooldowns etc (PARTIALLY COMPLETE - has leveling/skills)
- [ ] Incident outcome affects client reputation and contract renewals

### Facility & Upgrade System 
- [ ] Office facility expansion (garage → office → enterprise progression)
- [ ] Physical facility upgrades affecting capacity and bonuses
- [ ] Upgrade trees tied to company growth phases

### Advanced Contract System
- [ ] Contract requirements (minimum reputation, specialist types)
- [ ] Client retention and relationship building
- [ ] Contract failure consequences
- [ ] Premium contracts with special rewards
- [ ] Government contracts with mission token requirements

### Faction System Enhancement
- [ ] Client factions: FinTech, HealthTech, Government, etc.
- [ ] Faction reputation tracking
- [ ] Faction-specific contract types and threats
- [ ] Faction bonuses and penalties


### UI/UX Improvements
- [ ] Better contract selection interface (scrollable list, filters)
- [ ] Specialist hiring interface with detailed stats
- [ ] incident Mode visual improvements (terminal animations)
- [ ] Resource change notifications (floating text)
- [ ] Audio feedback for actions

### Game Balance
- [ ] Contract income vs specialist costs balance
- [ ] incident difficulty scaling with reputation
- [ ] Resource generation rate tuning
- [ ] Upgrade cost progression curves

### Achievement System
- [ ] Business milestones (first $100K revenue, 10 specialists, etc.)
- [ ] incident response achievements
- [ ] Dynamic generation
- [ ] Client relationship achievements
- [ ] Specialist training achievements


### Automation & QoL
- [ ] Auto-accept contracts based on criteria
- [ ] Specialist auto-assignment to contracts
- [ ] incident response automation (with efficiency penalties)
- [ ] Resource management alerts

### Prestige System
- [ ] Company "exit" events (acquisition, IPO)
- [ ] Prestige bonuses for new game plus
- [ ] Legacy reputation affecting new company starts


## Technical Debt & Cleanup

### Code Organization
- [ ] Move incident scenarios to data files
- [ ] Extract constants to config files
- [ ] Improve error handling and validation
- [ ] Performance optimization for large specialist teams

### Legacy System Removal
- [ ] Remove DataBits, ProcessingPower, SecurityRating resources (replaced by fortress ResourceManager)
- [ ] Remove zone system (replace with office/facility system) - fortress provides foundation
- [ ] Remove old upgrade definitions (replaced by fortress SecurityUpgrades)
- [ ] Clean up unused code paths

### Testing Expansion
- [ ] Need to be able to test game engine directly with out waiting for time to pass.
- [ ] incident system tests
- [ ] UI interaction tests
- [ ] Save/load validation tests
- [ ] Performance benchmarks

## Documentation
- [ ] Player manual for game mechanics
- [ ] Developer API documentation
- [ ] Balance spreadsheet with formulas