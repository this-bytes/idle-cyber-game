# Idle Sec Ops - Development TODO
## Development Notes

### Current Architecture Strengths
- Event-driven system communication
- Modular system design
- Comprehensive test coverage
- Data-driven approach for flexibility

### Areas for Improvement
- engaging game - go from want to play to need to play
- incident scenarios should be data-driven
- UI needs component-based architecture
- Resource management could be more sophisticated
- Performance monitoring for complex simulations

### Design Philosophy
- Maintain cybersecurity SOC theme authenticity althought the content can be tongue in check puns etc
- COre idle engine needs to be robust to allow for multiplcation through stat/skill tree and other scable factors
- Balanced idle progression with incident engagement
- Player agency in business growth strategy

### Incident System 
- [ ] Create upgradable office starting with garage and expand, feeds into the stats of game initially then can be scene changes
- [ ] Multiple incident scenarios with different threat types
- [ ] Dynamic incident generation based on active contracts, use some sort of rng engine to determine stats. Need a word list to use to generate random names etc
- [ ] Specialist system with upgrade, cooldowns etc
- [ ] incident outcome affects client reputation and contract renewals

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