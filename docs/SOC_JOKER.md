# SOC Joker - Card-Based Roguelike Mode

## Overview

SOC Joker is a Balatro-inspired card-based roguelike game mode where players manage breach containment runs using a deck of cybersecurity specialists and tools to defeat waves of threats.

## Gameplay Flow

```
┌─────────────────┐
│   MAIN MENU     │
│                 │
│  Select Ante:   │
│  • Ante 1 (Easy)│
│  • Ante 2       │
│  • Ante 3 (Hard)│
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────────────────┐
│           WAVE 1 (5 Threats)                │
│                                             │
│  ┌───────┐ ┌───────┐ ┌───────┐            │
│  │Threat │ │Threat │ │Threat │ ...        │
│  │ HP: 8 │ │ HP: 6 │ │ HP: 5 │            │
│  └───────┘ └───────┘ └───────┘            │
│                                             │
│  Player Health: ❤️ 100/100                 │
│                                             │
│  Your Hand:                                 │
│  ┌────────┐ ┌────────┐ ┌────────┐         │
│  │ Junior │ │Firewall│ │ Senior │ ...     │
│  │Analyst │ │        │ │Analyst │         │
│  │ DMG: 2 │ │BLK: 3  │ │ DMG: 4 │         │
│  └────────┘ └────────┘ └────────┘         │
│                                             │
│  [End Turn] [Forfeit]                      │
└──────────────┬──────────────────────────────┘
               │ (Wave Complete)
               ▼
┌─────────────────────────────────────────────┐
│              SHOP                           │
│                                             │
│  Currency: $200                             │
│                                             │
│  ┌──────────────┐ ┌──────────────┐        │
│  │ Threat Hunter│ │ EDR Platform │ ...    │
│  │ DMG: 3+Splash│ │ AOE DMG: 2   │        │
│  │  $100        │ │  $200        │        │
│  └──────────────┘ └──────────────┘        │
│                                             │
│  [Continue to Next Wave]                   │
└──────────────┬──────────────────────────────┘
               │
               ▼
           (Repeat for Wave 2 & 3)
               │
               ▼
┌─────────────────────────────────────────────┐
│        VICTORY / DEFEAT                     │
│                                             │
│  Final Score: 3,250                         │
│  Threats Defeated: 22                       │
│  Cards Played: 34                           │
│                                             │
│  [Play Again] [Back to Menu]               │
└─────────────────────────────────────────────┘
```

## Card Types

### Specialist Cards (Blue)
- **Junior Analyst**: Deal 2 damage
- **Senior Analyst**: Deal 4 damage
- **Threat Hunter**: Deal 3 damage + 1 splash to adjacent
- **Firewall**: Block 3 damage from network threats

### Tool Cards (Green)
- **EDR Platform**: Deal 2 damage to all threats (AOE)
- **SIEM System**: Reveal hidden threats
- **Backup Protocol**: Recover health

## Wave Configuration

| Wave | Threats | Boss | Reward |
|------|---------|------|--------|
| 1    | 5       | No   | $100   |
| 2    | 7       | Yes  | $200   |
| 3    | 10      | Yes  | $500   |

## Ante Difficulty

- **Ante 1**: Base difficulty
- **Ante 2**: 2x threat health and damage
- **Ante 3**: 3x threat health and damage

## Controls

### Menu
- Click buttons to select ante difficulty
- ESC to return to main menu

### Wave Phase
- **Click card** to select it
- **Click threat** to target it with selected card
- **Hover** over cards/threats to highlight them
- **End Turn**: Discard hand, draw 5 new cards, threats attack player
- **Forfeit**: Abandon run immediately

### Shop Phase
- Click cards to purchase them (if you have currency)
- Continue button to start next wave

## Scoring System

Score is calculated based on:
- **Threats Defeated**: 50 points each
- **Ante Difficulty**: 500 points per ante level
- **Perfect Waves**: 250 bonus points per wave with no damage taken
- **Time Bonus**: Up to 1000 points for faster completion
- **Efficiency Bonus**: Based on threats defeated per card played ratio

## Technical Implementation

### Files Modified
- `src/scenes/soc_joker.lua` - Main scene implementation (NEW)
- `src/soc_game.lua` - Scene registration
- `src/scenes/soc_view_luis.lua` - Added navigation button

### Systems Used
- **RunManager**: Run state, wave progression, scoring
- **DeckManager**: Hand management, card playing, deck building
- **ThreatSystem**: Wave generation (extended functionality)
- **EventBus**: Inter-system communication

### UI Architecture
- **LUIS**: Grid-based UI for menus and overlays
- **Custom Drawing**: Love2D graphics for cards and threats
- **Hybrid Approach**: Best of both systems

## Future Enhancements

### Potential Additions
- [ ] More card types (20+ cards planned)
- [ ] Joker cards (permanent modifiers)
- [ ] Card synergies (combo effects)
- [ ] More threat types with special abilities
- [ ] Difficulty modifiers (artifacts)
- [ ] Unlockable cards via progression
- [ ] Leaderboards for high scores
- [ ] Card animation effects
- [ ] Sound effects and music
- [ ] Save/resume mid-run

### Card Ideas
- **Incident Responder**: Remove all damage from one threat
- **AI Assistant**: Draw 2 extra cards
- **Zero Trust**: Prevents threat attacks for one turn
- **Honeypot**: Attracts and traps attackers
- **Backup System**: Restores 20 health
- **Network Segmentation**: Prevents splash damage
- **Automation Expert**: Auto-play cheapest card each turn

## Design Philosophy

This mode follows the Balatro formula:
1. **Short runs**: 15-30 minutes per run
2. **Randomized content**: Different threats and shop offerings each run
3. **Strategic depth**: Deck building and resource management
4. **Risk/reward**: Higher antes = better unlocks
5. **Addictive loop**: "Just one more run" syndrome
6. **Skill progression**: Learn threat patterns and optimal plays

The cybersecurity theme provides authentic tension - real threats, real tools, real consequences - but in a fast-paced, accessible package that's infinitely replayable.
