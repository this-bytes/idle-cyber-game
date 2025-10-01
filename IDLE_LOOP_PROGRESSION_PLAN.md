# Idle Resource Generation Loop - Progression Plan
**Focus**: Make the core idle loop FUN and JUICY while architecting for future systems

## 🎯 Alignment with Instructions

### From `03-core-mechanics.instructions.md`
✅ **Resources**: Money, Reputation, XP, Mission Tokens (we have these)
✅ **Idle Loop**: Generate resources → Spend on upgrades → More generation
✅ **Data-first**: All generators defined in JSON (idle_generators.json exists)
✅ **Modular**: ResourceManager and IdleGenerators are separate, event-driven

### From `09-balancing-math.instructions.md`
✅ **Growth factors**: `UpgradeCost = BaseCost * (GrowthFactor ^ Count)`
✅ **Configurable**: Keep constants in data files for easy tuning
✅ **Testing**: Need simulation to verify balance

### From `01-project-overview.instructions.md`
✅ **Vertical Slice**: Focus on making ONE thing playable
✅ **Rewarding Loop**: Player feels progress both passively and actively
✅ **Simplicity**: Keep it intuitive

## 📋 What We Have (Current State)

### ✅ Already Implemented
- `ResourceManager` - tracks money, reputation, XP, mission tokens
- `IdleGenerators` - loads generator definitions from JSON
- `idle_generators.json` - 15+ generator types defined
- Generation rates and multipliers in place
- Event bus for cross-system communication

### ❌ Missing (What Makes It NOT Fun Yet)
- **No visual feedback** - numbers change but player doesn't see/feel it
- **No click interaction** - can't actively participate
- **No purchase UI** - can't buy generators in-game
- **No progression feel** - unclear what to do or why
- **No save/load** - progress doesn't persist

## 🎮 The Fun Loop (What We're Building)

```
Click/Wait → See numbers go UP → Buy generator → Numbers go UP FASTER → Feel GOOD
```

## 📦 Modular Tasks (Can Be Delegated)

### Phase 1: Visual Feedback (THE JUICE) 🧃
**Goal**: Make number changes feel satisfying
**Aligns with**: `10-ui-design.instructions.md` - visual feedback

**Task 1.1: Animated Number Displays**
- File: `src/ui/components/resource_display.lua` (improve existing)
- Show current resources with animated counting
- Pop animation when values change
- Color coding (green=gain, red=loss, yellow=special)
- **Acceptance**: Numbers visibly count up when resources are added

**Task 1.2: Floating "+X" Popups**
- File: `src/ui/components/floating_text.lua` (improve existing)
- When resources change, show "+$50" floating upward
- Fade out and scale animation
- Queue multiple popups so they don't overlap
- **Acceptance**: Click or wait, see "+$X" float up from resource counter

**Task 1.3: Per-Second Counter**
- File: `src/ui/components/resource_display.lua` (improve existing)
- Show "($50/sec)" next to money display
- Update in real-time as rates change
- Visual indicator when rate increases
- **Acceptance**: Can see how fast money is being earned

---

### Phase 2: Click Interaction (ACTIVE ENGAGEMENT) 👆
**Goal**: Give player something to DO while idling
**Aligns with**: `03-core-mechanics.instructions.md` - active engagement

**Task 2.1: Big Click Button**
- File: `src/scenes/soc_view.lua` (improve existing)
- Large, obvious "Process Alert" or "Handle Incident" button
- Clicking adds resources (formula: base + multiplier)
- Cooldown indicator (can't spam)
- **Acceptance**: Can click button, get money, see visual feedback

**Task 2.2: Click Upgrade System**
- File: `src/systems/click_upgrades.lua` (NEW - but simple)
- Upgrades that improve click value
- Upgrades that reduce click cooldown
- Data-driven from JSON (follows patterns)
- **Acceptance**: Can buy upgrades that make clicks better

**Task 2.3: Click Combo System**
- File: `src/systems/click_upgrades.lua` (improve after 2.2)
- Rapid clicks = combo multiplier
- Visual feedback for combo state
- Resets after pause
- **Acceptance**: Fast clicking = bigger rewards = FUN

---

### Phase 3: Generator Purchase UI (PROGRESSION) 🛒
**Goal**: Let player buy generators to increase idle income
**Aligns with**: `03-core-mechanics.instructions.md` - spend to scale

**Task 3.1: Generator Shop Panel**
- File: `src/ui/panels/generator_shop.lua` (improve existing or create minimal)
- List all available generators from JSON
- Show: name, cost, owned count, production rate
- Grayed out if can't afford
- **Acceptance**: Can see all generators and their stats

**Task 3.2: Purchase Button & Logic**
- File: `src/systems/idle_generators.lua` (improve existing)
- Click to buy generator
- Deduct cost, add generator, update rate
- Cost increases per formula: `cost * (1.15 ^ owned)`
- **Acceptance**: Can buy generators, see cost increase, see income increase

**Task 3.3: Generator Categories & Tooltips**
- File: `src/ui/panels/generator_shop.lua` (improve)
- Group by category (equipment, personnel, infrastructure)
- Hover tooltips with details
- Show requirements (if any)
- **Acceptance**: Easy to understand what each generator does

---

### Phase 4: Progress Persistence (TRUST) 💾
**Goal**: Player trusts that progress is saved
**Aligns with**: Core requirement for any idle game

**Task 4.1: Auto-Save System**
- File: `src/systems/save_system.lua` (improve existing)
- Auto-save every 30 seconds
- Save resources, owned generators, upgrades
- Use existing save system patterns
- **Acceptance**: Close game, reopen, progress is there

**Task 4.2: Offline Progress Calculation**
- File: `src/systems/idle_system.lua` (improve existing)
- Calculate earnings while game was closed
- Cap at reasonable amount (e.g., 4 hours worth)
- Show "Welcome back! You earned $X" popup
- **Acceptance**: Close for 5 mins, reopen, get offline earnings

**Task 4.3: Save Validation & Recovery**
- File: `src/systems/save_system.lua` (improve)
- Validate save data on load
- Recover from corrupted saves gracefully
- Version migration support
- **Acceptance**: Won't lose progress if save is corrupted

---

### Phase 5: Progression Feel (DOPAMINE) 🎉
**Goal**: Make player FEEL like they're making progress
**Aligns with**: `01-project-overview.instructions.md` - rewarding loop

**Task 5.1: Milestone Celebrations**
- File: `src/ui/components/celebration.lua` (NEW but simple)
- Trigger on milestones ($1k, $10k, $100k, etc.)
- Screen flash, particle burst, sound effect
- "Achievement Unlocked" style popup
- **Acceptance**: Hit milestone, see celebration, feel good

**Task 5.2: Progression Stats Panel**
- File: `src/ui/panels/stats_panel.lua` (improve existing)
- Total earned, highest income rate, time played
- Generators owned by type
- "Next milestone" progress bar
- **Acceptance**: Can see overall progress and goals

**Task 5.3: Unlock Notifications**
- File: `src/ui/components/notification.lua` (improve existing)
- "New generator unlocked!" when affordable
- "Upgrade available!" notifications
- Can dismiss or click to navigate
- **Acceptance**: Game guides player to next purchase

---

### Phase 6: Balance & Polish (FEELS GOOD) ⚖️
**Goal**: Tune numbers so progression feels right
**Aligns with**: `09-balancing-math.instructions.md`

**Task 6.1: Balance Testing Script**
- File: `tools/balance_simulator.lua` (NEW)
- Simulate 1 hour of play with different strategies
- Output: time to each milestone, income curves
- Adjust JSON values based on results
- **Acceptance**: Can generate balance reports

**Task 6.2: Early Game Tuning**
- File: `src/data/idle_generators.json` (improve)
- First 5 minutes should feel rewarding
- First purchase affordable in ~10 seconds
- First upgrade affordable in ~30 seconds
- **Acceptance**: New player gets hooked in 2 minutes

**Task 6.3: Audio Feedback**
- File: `src/systems/sound_system.lua` (improve existing)
- Purchase sound (satisfying "cha-ching")
- Click sound (tactile feedback)
- Milestone sound (celebration)
- **Acceptance**: Audio makes actions feel impactful

---

## 🎯 Success Criteria (Before Moving to Next System)

### Minimum Viable Fun (MVF)
- [ ] Can click button and get money with visual feedback
- [ ] Can see money accumulate per second
- [ ] Can buy at least 3 generator types
- [ ] Generators actually increase income rate
- [ ] Progress saves and loads
- [ ] Offline progress works
- [ ] New player can have fun for 2 minutes without instructions

### Alignment Check
- [ ] Uses existing ResourceManager (no duplication)
- [ ] Uses existing IdleGenerators (no duplication)
- [ ] Data-driven from JSON (easy to balance)
- [ ] Event-driven (other systems can hook in later)
- [ ] Modular (can add contracts/specialists later without refactor)

---

## 🚀 Delegation Strategy

### Solo Developer Mode (You)
Work through phases 1-6 sequentially. Each phase builds on previous.

### Team Mode (Multiple Developers)
- **Dev A**: Phase 1 (Visual Feedback) - Can work independently
- **Dev B**: Phase 2 (Click System) - Can work independently  
- **Dev C**: Phase 3 (Purchase UI) - Depends on IdleGenerators API
- **Dev D**: Phase 4 (Save/Load) - Can work independently
- **Dev E**: Phase 5 (Polish) - Can work in parallel once others are done
- **Dev F**: Phase 6 (Balance) - Final pass after everything works

### AI Agent Mode (Copilot)
Each task is self-contained with clear acceptance criteria. Can be prompted:
> "Implement Task 1.1: Animated Number Displays. The file is src/ui/components/resource_display.lua. Follow the acceptance criteria in the plan."

---

## 📝 Next Steps (Immediate)

1. **Confirm this plan aligns with your vision**
2. **Choose starting point**: Phase 1, 2, or 3?
3. **I implement the chosen phase** with full transparency
4. **Test in actual game** (not just unit tests)
5. **Iterate until it feels fun**
6. **Move to next phase**

---

## 🔄 How This Avoids Future Refactors

### Architecture Decisions
- **ResourceManager is the single source of truth** for all resources
- **Event bus for all resource changes** (contracts/specialists can subscribe later)
- **JSON-driven generators** (easy to add contract-based generators later)
- **Modular UI components** (can reuse for different game modes)
- **Save system handles any data** (add new systems without breaking saves)

### Future System Integration
- **Contracts**: Just another source of resource generation events
- **Specialists**: Modify ResourceManager multipliers via events
- **Upgrades**: Already follows same JSON pattern as generators
- **Crisis Mode**: Can grant mission tokens through ResourceManager
- **Prestige**: Reset ResourceManager state, keep persistent bonuses

The architecture is **extensible without refactoring** because we're following the instruction file patterns from the start.

---

**Ready to start? Which phase should we tackle first?**
