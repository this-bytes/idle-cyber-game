# SOC Joker Implementation Guide

## Quick Start

To access SOC Joker mode:
1. Launch the game with `love .`
2. Select "NEW OPERATION" or "LOAD OPERATION" from main menu
3. In the SOC View, click the **🃏 SOC Joker** button
4. Select your ante (difficulty level)
5. Start playing!

## Implementation Details

### Core Files

**New Files:**
- `src/scenes/soc_joker.lua` - Complete scene implementation (750 lines)
- `docs/SOC_JOKER.md` - Gameplay documentation
- `tests/scene/test_soc_joker.lua` - Unit tests

**Modified Files:**
- `src/soc_game.lua` - Added scene registration
- `src/scenes/soc_view_luis.lua` - Added navigation button

### Architecture

The scene follows a **hybrid UI approach**:

1. **LUIS Components** for menus/overlays:
   - Buttons for navigation
   - Labels for stats
   - Grid-based layout

2. **Custom Love2D Drawing** for cards:
   - Card visuals with hover effects
   - Threat cards with health bars
   - Hand display at bottom
   - Threats display at top

### State Management

The scene manages 4 distinct states:

```lua
-- Run states (from RunManager)
"menu"    -> Show ante selection
"wave"    -> Active combat
"shop"    -> Between-wave card purchasing
"victory" -> Successful run completion
"defeat"  -> Run failure
```

### Event System

The scene communicates via EventBus:

**Subscribes to:**
- `run_started` - Initialize wave threats
- `wave_started` - Generate new wave
- `shop_opened` - Show shop UI
- `run_ended` - Show results
- `cards_drawn` - Refresh hand display
- `card_played` - Update UI after card

**Publishes:**
- `wave_complete` - Signal wave success/failure
- `forfeit_run` - Abandon run
- `request_scene_change` - Navigation

### Game Loop

```
Menu
  ↓ [Player selects ante]
RunManager:startRun()
  ↓
DeckManager:initializeStarterDeck()
  ↓ [Draws 5 cards]
Wave Phase
  ├─ Player plays cards
  │  └─ DeckManager:playCard()
  │     └─ Threat takes damage
  ├─ Player ends turn
  │  ├─ Threats attack player
  │  └─ DeckManager:endTurn() (discard, redraw)
  └─ Wave complete?
     ├─ YES → Shop Phase
     │        ├─ Generate 3 random cards
     │        ├─ Player purchases cards
     │        └─ Continue to next wave
     └─ NO → Continue wave
```

### Visual Layout

#### Wave Phase
```
┌─────────────────────────────────────────────────────┐
│ Ante 1 - Wave 1/3 | Threats: 5        [HEADER]     │
│ ❤️ Health: 100/100 | 💰 Currency: $100             │
├─────────────────────────────────────────────────────┤
│                                                      │
│   ┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐    │
│   │Phish│  │Ranso│  │ DDoS│  │  SQL│  │Zero │    │
│   │ ❤️8 │  │ ❤️6 │  │ ❤️5 │  │ ❤️10│  │ ❤️7 │    │
│   └─────┘  └─────┘  └─────┘  └─────┘  └─────┘    │
│                 [THREATS]                            │
│                                                      │
│                                                      │
│                                                      │
│                                                      │
├─────────────────────────────────────────────────────┤
│  ┌────┐  ┌────┐  ┌────┐  ┌────┐  ┌────┐           │
│  │Jun │  │Fire│  │Sen │  │Fire│  │Jun │           │
│  │Anal│  │wall│  │Anal│  │wall│  │Anal│           │
│  │💥 2│  │🛡️ 3│  │💥 4│  │🛡️ 3│  │💥 2│           │
│  └────┘  └────┘  └────┘  └────┘  └────┘           │
│                  [YOUR HAND]                         │
│                                                      │
│  🎴 Deck: 10 | 🗑️ Discard: 3    [End Turn] [Forfeit]│
└─────────────────────────────────────────────────────┘
```

#### Shop Phase
```
┌─────────────────────────────────────────────────────┐
│                   🛒 SHOP                            │
│              💰 Available: $200                      │
├─────────────────────────────────────────────────────┤
│                                                      │
│   ┌─────────────┐  ┌─────────────┐  ┌───────────┐ │
│   │Threat Hunter│  │EDR Platform │  │  Backup   │ │
│   │             │  │             │  │  Protocol │ │
│   │Deal 3 DMG + │  │Deal 2 DMG to│  │ Restore   │ │
│   │1 splash to  │  │all threats  │  │ 20 health │ │
│   │adjacent     │  │    (AOE)    │  │           │ │
│   │             │  │             │  │           │ │
│   │  [Buy $100] │  │  [Buy $200] │  │ [Buy $75] │ │
│   └─────────────┘  └─────────────┘  └───────────┘ │
│                                                      │
│                                                      │
│          [Continue to Next Wave]                     │
└─────────────────────────────────────────────────────┘
```

### Color Scheme

**Threats (Red theme):**
- Background: `rgb(77, 26, 26)` - Dark red
- Border: `rgb(255, 51, 51)` - Bright red
- Health bar: `rgb(255, 77, 77)` - Red gradient

**Cards (Cyan theme):**
- Background: `rgb(13, 77, 102)` - Dark cyan
- Border: `rgb(0, 255, 255)` - Bright cyan
- Hover lift: 20px up

**UI Elements:**
- Background: `rgb(5, 5, 13)` - Very dark blue
- Text: `rgb(0, 255, 180)` - Cyan-green
- Borders: `rgb(0, 255, 180, 0.4)` - Semi-transparent cyan

### Card Properties

Each card has these properties:
```lua
{
    id = "threat_hunter",      -- Unique identifier
    type = "specialist",        -- specialist/tool/threat
    name = "Threat Hunter",     -- Display name
    effect = "Deal 3 damage...", -- Description
    damage = 3,                 -- Damage dealt
    splash = 1,                 -- Splash damage
    aoe = 0,                    -- Area damage
    block = 0,                  -- Block amount
    cost = 0,                   -- Energy cost (unused)
    rarity = "uncommon"         -- common/uncommon/rare/legendary
}
```

### Threat Properties

Each threat has:
```lua
{
    id = "threat_1",
    name = "Phishing Attack",
    type = "network",           -- network/malware/social/data
    health = 8,                 -- Current health
    maxHealth = 8,              -- Maximum health
    damage = 2,                 -- Damage dealt per turn
    isBoss = false             -- Is this a boss threat?
}
```

## Testing

### Manual Testing Checklist

- [ ] Launch game and navigate to SOC Joker from SOC View
- [ ] Verify menu shows ante selection and stats
- [ ] Start Ante 1 run
- [ ] Verify 5 threats appear
- [ ] Verify hand shows 5 cards
- [ ] Click a card to select it
- [ ] Click a threat to play card on it
- [ ] Verify threat takes damage
- [ ] Verify card is removed from hand
- [ ] Click "End Turn"
- [ ] Verify threats attack player
- [ ] Verify hand is discarded and redrawn
- [ ] Defeat all threats in wave
- [ ] Verify shop appears with 3 cards
- [ ] Purchase a card
- [ ] Continue to Wave 2
- [ ] Complete or fail run
- [ ] Verify results screen shows score
- [ ] Test "Play Again" button
- [ ] Test "Back to Menu" button
- [ ] Test ESC key for quick exit

### Automated Tests

Run the scene unit tests:
```bash
cd /home/runner/work/idle-cyber-game/idle-cyber-game
lua tests/scene/test_soc_joker.lua
```

Expected output:
```
🧪 Testing SOC Joker Scene...
✅ Scene instantiation successful
✅ Menu load successful
✅ Generated 5 threats
✅ Shop generation successful
✅ Generated threat name: Phishing Attack
✅ Generated threat type: network
✅ Card play mechanics work
✅ Card purchase works
✅ Hover state updates work
✅ All required methods exist
🎉 All SOC Joker scene tests passed!
```

## Troubleshooting

### Scene doesn't appear in menu
- Check `src/soc_game.lua` has `SOCJoker` require and registration
- Check `src/scenes/soc_view_luis.lua` has the navigation button
- Restart the game completely

### Cards don't play
- Check that RunManager is in "wave" state
- Verify threats exist in scene.threats table
- Check console for error messages

### Shop doesn't show cards
- Verify DeckManager has available cards loaded
- Check generateShopOfferings() is being called
- Look for errors in shop currency display

### Performance issues
- Reduce number of cards in deck
- Simplify card visuals in draw() method
- Check for event subscription leaks

## Future Development

### Priority Enhancements
1. **Card animations** - Smooth transitions when playing cards
2. **Sound effects** - Audio feedback for actions
3. **More cards** - Expand to 20-30 unique cards
4. **Joker system** - Permanent run modifiers
5. **Unlockables** - Progression system

### Code Improvements
1. Move card data to JSON files
2. Add card effect engine for complex interactions
3. Implement card preview tooltips
4. Add replay/history system
5. Optimize rendering for large hands

### Balance Tuning
- Adjust threat health scaling
- Fine-tune card damage values
- Balance shop prices
- Calibrate scoring formula

## Credits

- **Design**: Inspired by Balatro by LocalThunk
- **Theme**: Cybersecurity SOC operations
- **Architecture**: LUIS UI + Love2D graphics
- **Systems**: RunManager, DeckManager, ThreatSystem (pre-existing)

## License

Part of the Idle Cyber Game project. See main LICENSE file.
