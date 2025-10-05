# 🃏 SOC Joker - Card-Based Roguelike Mode

> **A Balatro-inspired cybersecurity breach containment game**

## Quick Start

### Playing the Game
1. Launch game: `love .`
2. Select "NEW OPERATION" or "LOAD OPERATION"
3. In SOC View, click **"🃏 SOC Joker"** button
4. Select ante difficulty (1-3)
5. Play cards to defeat threats!

### How to Play
- **Click a card** in your hand to select it
- **Click a threat** to play your selected card on it
- **End Turn** to let threats attack and draw new cards
- **Purchase cards** in the shop between waves
- **Complete 3 waves** to win the run!

## Game Overview

SOC Joker is a fast-paced card game where you manage cybersecurity breach containment runs. Build your deck of specialists and tools to defeat increasingly difficult waves of threats.

### Core Loop
```
Menu → Wave 1 → Shop → Wave 2 → Shop → Wave 3 → Results
```

Each wave, you play cards from your hand to defeat threats. Between waves, you visit the shop to strengthen your deck. Complete all 3 waves to win!

## Game Mechanics

### Your Deck
Start with a basic deck:
- **3x Junior Analyst** - Deal 2 damage
- **2x Firewall** - Block 3 damage

Expand your deck through shop purchases!

### Wave Structure
- **Wave 1**: 5 threats
- **Wave 2**: 7 threats + boss
- **Wave 3**: 10 threats + mega boss

### Difficulty Levels (Antes)
- **Ante 1**: Base difficulty (Easy)
- **Ante 2**: 2x threat health and damage
- **Ante 3**: 3x threat health and damage

### Shop System
Between waves, purchase new cards:
- **3 random cards** offered each shop
- **Prices** vary by rarity ($50-$250)
- **Currency** earned by completing waves

### Scoring
Score points for:
- Defeating threats (50 each)
- Ante difficulty (500 per ante)
- Perfect waves (250 bonus)
- Speed and efficiency bonuses

## Card Types

### Specialist Cards (Damage Dealers)
- **Junior Analyst**: Deal 2 damage
- **Senior Analyst**: Deal 4 damage
- **Threat Hunter**: Deal 3 + 1 splash to adjacent

### Tool Cards (Utilities)
- **Firewall**: Block 3 damage
- **EDR Platform**: Deal 2 damage to ALL threats (AOE)
- **Backup Protocol**: Restore 20 health

## Implementation Details

### Architecture
- **Scene**: `src/scenes/soc_joker.lua` (711 lines)
- **Systems**: RunManager, DeckManager, ThreatSystem
- **UI**: Hybrid LUIS + custom Love2D graphics
- **Events**: EventBus for inter-system communication

### File Structure
```
src/scenes/soc_joker.lua          # Main scene implementation
src/soc_game.lua                  # Scene registration
src/scenes/soc_view_luis.lua      # Navigation integration
tests/scene/test_soc_joker.lua    # Unit tests
docs/SOC_JOKER*.md                # Documentation (4 files)
```

### Key Methods
- `buildMenuUI()` - Ante selection screen
- `buildWaveUI()` - Active combat screen
- `buildShopUI()` - Card purchasing screen
- `buildResultsUI()` - Victory/defeat screen
- `playCard(cardIndex, threatIndex)` - Card playing logic
- `endTurn()` - Turn resolution

## Documentation

### Complete Guides
1. **[SOC_JOKER.md](SOC_JOKER.md)** - Gameplay guide with ASCII diagrams
2. **[SOC_JOKER_IMPLEMENTATION.md](SOC_JOKER_IMPLEMENTATION.md)** - Technical implementation
3. **[SOC_JOKER_VISUAL_REFERENCE.md](SOC_JOKER_VISUAL_REFERENCE.md)** - Visual mockups
4. **[SOC_JOKER_SUMMARY.md](SOC_JOKER_SUMMARY.md)** - Complete summary

### Quick References
- **Controls**: Click cards, click threats, use buttons
- **Goal**: Defeat all threats across 3 waves
- **Strategy**: Build synergistic deck, manage health
- **Scoring**: Higher ante = more points

## Testing

### Automated Tests
```bash
lua tests/scene/test_soc_joker.lua
```

**10 tests** covering:
- Scene instantiation
- UI generation
- Threat generation
- Card mechanics
- Shop functionality
- State management

### Manual Testing
1. Navigate to SOC Joker from SOC View
2. Select ante and start run
3. Play cards on threats
4. Use End Turn button
5. Purchase cards in shop
6. Complete or fail run
7. Check results screen

## Visual Design

### Color Scheme
- **Threats**: Red theme (`#4D1A1A`, `#FF3333`)
- **Cards**: Cyan theme (`#0D4D66`, `#00FFFF`)
- **Background**: Dark blue (`#05050D`)
- **Text**: Cyan-green (`#00FFB4`)

### Interactions
- **Hover**: Cards lift 20px, threats highlight
- **Select**: Blue glow on selected card
- **Damage**: Health bars update smoothly
- **Complete**: Transition to next state

## Future Enhancements

### Planned Features
- [ ] More card types (expand to 20-30)
- [ ] Joker system (permanent modifiers)
- [ ] Card animations
- [ ] Sound effects and music
- [ ] Card synergies
- [ ] Unlockable cards
- [ ] Leaderboards

### Content Ideas
- New specialists: Incident Responder, Penetration Tester
- New tools: SIEM, Honeypot, Zero Trust
- Special threats with abilities
- Daily challenges
- Achievement system

## Technical Notes

### Performance
- Efficient rendering (no lag)
- Event-driven updates only
- Minimal memory footprint

### Compatibility
- Works with existing game systems
- No breaking changes
- Follows project architecture

### Code Quality
- Clean, readable code
- Comprehensive documentation
- Unit test coverage
- Error handling

## Credits

- **Design**: Inspired by [Balatro](https://www.playbalatro.com/) by LocalThunk
- **Theme**: Cybersecurity SOC operations
- **Implementation**: GitHub Copilot AI Assistant
- **Systems**: RunManager, DeckManager, ThreatSystem (existing)
- **UI Framework**: LUIS + Love2D

## Status

✅ **Production Ready**
- Complete functionality
- Tested and verified
- Documented thoroughly
- Ready to play!

## Support

For issues or questions:
1. Check documentation in `docs/` folder
2. Review test cases in `tests/scene/`
3. Open issue on GitHub

---

**Have fun playing SOC Joker! 🎮**

*"Just one more run..."*
