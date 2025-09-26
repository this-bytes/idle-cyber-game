# Cyber Empire Command - Development TODO

## Completed ✅
- [x] Resource system refactor (Money, Reputation, XP, Mission Tokens)
- [x] Contract system implementation with client tiers
- [x] Specialist system with team management
- [x] incident Mode foundation with sample scenario
- [x] UI refactor to Cyber Empire Command theme
- [x] Test suite with 9 passing tests
- [x] Save/load integration for all systems

## Phase 2: Core Systems Expansion

### Incident System (HIGH PRIORITY)
- [ ] Create upgradable office starting with garage and expand
- [ ] Multiple incident scenarios with different threat types
- [ ] Dynamic incident generation based on active contracts
- [ ] Specialist abilities integration with incident responses
- [ ] incident outcome affects client reputation and contract renewals

### Facility & Upgrade System 
- [ ] Refactor existing upgrade system for business context
- [ ] Office upgrades: Better equipment, more space, security improvements
- [ ] Technology upgrades: AI tools, automation, threat detection
- [ ] Upgrade trees tied to company growth phases (garage → office → enterprise)

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

## Phase 3: Polish & Balance

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
- [ ] Client relationship achievements
- [ ] Specialist training achievements

## Phase 4: Advanced Features

### Automation & QoL
- [ ] Auto-accept contracts based on criteria
- [ ] Specialist auto-assignment to contracts
- [ ] incident response automation (with efficiency penalties)
- [ ] Resource management alerts

### Prestige System
- [ ] Company "exit" events (acquisition, IPO)
- [ ] Prestige bonuses for new game plus
- [ ] Legacy reputation affecting new company starts

### Multiplayer Concepts (Future)
- [ ] Industry rankings/leaderboards
- [ ] Contract market (compete for premium clients)
- [ ] Specialist sharing/trading
- [ ] Collaborative incident response

## Technical Debt & Cleanup

### Code Organization
- [ ] Move incident scenarios to data files
- [ ] Extract constants to config files
- [ ] Improve error handling and validation
- [ ] Performance optimization for large specialist teams

### Legacy System Removal
- [ ] Remove DataBits, ProcessingPower, SecurityRating resources
- [ ] Remove zone system (replace with office/facility system)
- [ ] Remove old upgrade definitions
- [ ] Clean up unused code paths

### Testing Expansion
- [ ] incident system tests
- [ ] UI interaction tests
- [ ] Save/load validation tests
- [ ] Performance benchmarks

## Documentation
- [ ] Player manual for game mechanics
- [ ] Developer API documentation
- [ ] Modding guide for custom scenarios
- [ ] Balance spreadsheet with formulas

---

## Development Notes

### Current Architecture Strengths
- Event-driven system communication
- Modular system design
- Comprehensive test coverage
- Data-driven approach for flexibility

### Areas for Improvement
- incident scenarios should be data-driven
- UI needs component-based architecture
- Resource management could be more sophisticated
- Performance monitoring for complex simulations

### Design Philosophy
- Maintain cybersecurity theme authenticity
- Progressive complexity (garage to global enterprise)
- Balanced idle progression with incident engagement
- Player agency in business growth strategy

---

## Recent work & next tasks

### Recent (completed)
- [x] Centralized contract template registry (`src/data/contracts.lua`) — templates and instantiate API
- [x] Wired contract registry into `ContractSystem` so contract generation uses templates

### Next (short-term)
- [ ] Use template `unlockRequirement` in `ContractSystem:generateRandomContract` to gate higher-tier templates by reputation/mission tokens
- [ ] Add JSON/YAML loader to `src/data/contracts` so designers can add templates as data files (data/contracts/*.json)
- [ ] Add unit tests for template instantiation, overrides, and registration
