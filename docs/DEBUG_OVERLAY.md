# Debug Overlay System

The debug overlay provides comprehensive real-time inspection of all game economy systems and state.

## Features

### Toggle Access
- **F3 Key**: Toggle debug overlay on/off
- Works on any scene - overlays on top of current game view
- Semi-transparent dark background for readability

### Information Panels

The debug overlay displays 12 information panels organized in a 3-column x 4-row grid:

#### Column 1: Core Economy
1. **Resources (💰)**
   - Current amounts: Money, Reputation, XP, Mission Tokens
   - Generation rates per second
   - Multipliers from upgrades/specialists
   - Total earned/spent tracking

2. **Contracts (📋)**
   - Available, Active, Completed counts
   - Auto-accept status
   - Generation timer and interval

3. **Threats (🚨)**
   - Active threats count
   - Template count
   - Generation timer
   - System enabled status

4. **Events (🎲)**
   - Total events available
   - Active events
   - Event timer and interval
   - Total event weight

#### Column 2: Systems
5. **Specialists (👥)**
   - Total, Available, Busy counts
   - Next specialist ID

6. **Upgrades (⬆️)**
   - Total upgrades available
   - Purchased count
   - Upgrade trees

7. **Skills (🎯)**
   - Skill definitions count
   - Unlocked skills count

8. **RNG State (🎰)**
   - Sample random values
   - Distribution monitoring
   - Timestamp

#### Column 3: Meta
9. **Idle System (💤)**
   - Last save time
   - Total offline earnings
   - Total offline damage
   - Threat types count

10. **Progression (📊)**
    - Current level
    - XP progress
    - Unlocked features

11. **Achievements (🏆)**
    - Total achievements
    - Unlocked count
    - Completion percentage

12. **Summary (📈)**
    - Net income per second
    - Active systems count
    - Economy health indicator
    - Total uptime

## Usage

### Basic Usage
1. Start the game normally
2. Press **F3** to toggle the debug overlay
3. The overlay shows real-time data updated every 0.1 seconds
4. Press **F3** again to hide the overlay

### Debugging Economy Issues
- Check **Resources** panel for generation rates and multipliers
- Check **Contracts** panel to verify auto-accept is working
- Check **Summary** panel for overall economy health
- Monitor **Net Income** - should be positive for healthy economy

### Monitoring RNG Systems
- Check **RNG State** panel for sample values (should vary)
- Check **Events** panel for timer progression
- Check **Contracts** panel for generation timer
- Check **Threats** panel for generation timer

### Verifying System Integration
- All panels should show non-zero values once game systems initialize
- **Active** counts should increase as game progresses
- **Generation timers** should count up and reset
- **Multipliers** should reflect purchased upgrades

## Technical Details

### Implementation
- Location: `src/ui/debug_overlay.lua`
- Integration: `src/soc_game.lua`
- Toggle: F3 key in `SOCGame:keypressed()`
- Update: Called from `SOCGame:update(dt)`
- Draw: Called from `SOCGame:draw()` (after particles, before UI)

### Performance
- Updates cached data every 0.1 seconds
- Only draws when visible (no performance impact when hidden)
- Minimal memory footprint (cached data only)

### Dependencies
- Requires `love.graphics` for drawing
- Requires `love.timer` for FPS and timestamps
- Accesses all game systems through `self.systems`

## Troubleshooting

### Overlay doesn't appear
- Ensure F3 key is pressed
- Check console for initialization message
- Verify `self.debugOverlay` is not nil in SOCGame

### Missing data in panels
- System may not be initialized yet
- Check if game has been started (not just in main menu)
- Some systems only activate after certain game events

### Layout issues
- Designed for 1024x768 minimum resolution
- Panels are 320x140 with 10px spacing
- May need adjustment for smaller screens

## Future Enhancements
- Click to expand panels for detailed information
- Filtering and search capabilities
- Export debug data to file
- Performance metrics and profiling
- Historical data and graphs
