# Idle Sec Ops - Development TODO

## Completed ✅
- [x] Resource system refactor (Money, Reputation, XP, Mission Tokens)
- [x] Contract system implementation with client tiers
- [x] Specialist system with team management
- [x] incident Mode foundation with sample scenario
- [x] UI refactor to Idle Sec Ops theme
- [x] Test suite with 46 tests (42 passing, 4 legacy issues)
- [x] Save/load integration for all systems
- [x] **Fortress Architecture Implementation (PR #37)**
  - [x] GameLoop - Central system orchestration with priority-based updates
  - [x] ResourceManager - Unified resource handling with event-driven updates
  - [x] SecurityUpgrades - Realistic cybersecurity infrastructure system
  - [x] ThreatSimulation - Authentic cyber threat engine with 8 threat types
  - [x] UIManager - Modern reactive UI system with cybersecurity theming
  - [x] FortressGame - Integrated controller replacing monolithic game.lua
  - [x] fortress_main.lua - Modern LÖVE 2D entry point
  - [x] 12 comprehensive fortress architecture tests
  - [x] 100% backward compatibility with legacy systems
  - [x] Performance monitoring and real-time metrics
  - [x] Industry-standard SOLID design principles

## Phase 2: Core Systems Expansion

### Incident System (HIGH PRIORITY)
- [x] Fortress ThreatSimulation with 8 authentic threat types
- [x] Severity-based damage calculations with defense effectiveness
- [x] Real-time threat mitigation progress tracking
- [ ] Create upgradable office starting with garage and expand
- [ ] Multiple incident scenarios with different threat types
- [ ] Dynamic incident generation based on active contracts
- [ ] Specialist abilities integration with incident responses
- [ ] incident outcome affects client reputation and contract renewals

### Facility & Upgrade System 
- [x] Fortress SecurityUpgrades system with 4 categories (Infrastructure, Tools, Personnel, Research)
- [x] Authentic cybersecurity upgrade catalog with cost scaling
- [x] Threat reduction calculations based on actual security implementations
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
- [x] Fortress architecture provides modern alternative to legacy systems
- [x] Maintained backward compatibility for existing save files  
- [ ] Remove DataBits, ProcessingPower, SecurityRating resources (replaced by fortress ResourceManager)
- [ ] Remove zone system (replace with office/facility system) - fortress provides foundation
- [ ] Remove old upgrade definitions (replaced by fortress SecurityUpgrades)
- [ ] Clean up unused code paths

### Testing Expansion
- [x] Fortress architecture tests (12/12 passing)
- [x] Integration tests validating fortress-legacy compatibility
- [x] Performance benchmarking and metrics validation
- [x] Mock LÖVE 2D environment for headless testing
- [ ] incident system tests
- [ ] UI interaction tests
- [ ] Save/load validation tests
- [ ] Performance benchmarks

## Documentation
- [x] **Fortress Architecture Documentation (This PR)**
  - [x] Updated ARCHITECTURE.md with comprehensive fortress architecture docs
  - [x] Updated technical architecture instruction file with fortress patterns
  - [x] Documented fortress entry points and system integration
  - [x] Updated TODO.md to reflect completed fortress implementation
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
- [x] **Fortress Architecture Implementation (PR #37)** — Complete architectural overhaul
  - [x] GameLoop with priority-based system orchestration
  - [x] ResourceManager with unified resource handling  
  - [x] SecurityUpgrades with realistic cybersecurity infrastructure
  - [x] ThreatSimulation with 8 authentic threat types
  - [x] UIManager with modern reactive UI system
  - [x] FortressGame controller replacing monolithic game.lua
  - [x] 100% backward compatibility with legacy systems
- [x] Centralized contract template registry (`src/data/contracts.lua`) — templates and instantiate API
- [x] Wired contract registry into `ContractSystem` so contract generation uses templates
- [x] **Documentation Updates for Fortress Refactor** — Proper documentation of architectural changes

### Next (short-term)
- [ ] Use template `unlockRequirement` in `ContractSystem:generateRandomContract` to gate higher-tier templates by reputation/mission tokens
- [ ] Add JSON/YAML loader to `src/data/contracts` so designers can add templates as data files (data/contracts/*.json)
- [ ] Add unit tests for template instantiation, overrides, and registration
- [ ] Leverage fortress ThreatSimulation for dynamic incident generation based on active contracts
- [ ] Integrate fortress SecurityUpgrades with contract difficulty and threat mitigation
