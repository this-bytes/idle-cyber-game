## Description  
Implement the core clicking mechanics that allow players to manually generate Data Bits by clicking. This is the primary active gameplay element and the foundation for all resource generation.

## Acceptance Criteria
- [ ] Click anywhere on screen generates 1 Data Bit initially
- [ ] Visual feedback when clicking (animation, sound effect)
- [ ] Click rate limiting to prevent exploitation
- [ ] Integration with resource display system
- [ ] Support for upgrade modifications to click value
- [ ] Basic click combo system (rapid clicking bonus)

## Technical Requirements
- **Click Detection:** Mouse input handling via LÖVE 2D
- **Rate Limiting:** Reasonable maximum clicks per second (10-15)
- **Visual Feedback:** Particle effects or animations
- **Audio:** Click sound effects (optional for Phase 1)
- **Performance:** No impact on framerate during rapid clicking

## Implementation Notes
- Reference `.github/copilot-instructions/03-core-mechanics.md` for click upgrade path
- Implement basic version of click combos (max 1.5x multiplier initially)
- Design system to support future upgrades (ergonomic mouse, neural interface, etc.)
- Consider mobile/touch support in design
- Plan for critical click mechanics (5% chance for bonus)

## Files to Create/Modify
- `mechanics/clicking.lua` - Click detection and processing
- `mechanics/datacollection.lua` - Data Bit generation logic
- `ui/clickfeedback.lua` - Visual feedback system
- `core/resources.lua` - Update to handle resource changes
- `utils/ratelimit.lua` - Click rate limiting

## Testing Checklist
- [ ] Single clicks generate expected Data Bits
- [ ] Rapid clicking works without issues
- [ ] Rate limiting prevents exploitation
- [ ] Visual feedback provides satisfying response
- [ ] Integration with resource display is smooth
- [ ] No performance degradation during clicking

## Definition of Done
- [ ] Clicking mechanics fully functional
- [ ] Visual and audio feedback implemented
- [ ] Rate limiting and anti-cheat measures active
- [ ] System ready for upgrade integration
- [ ] Player feedback confirms satisfying click experience

## Branch
`feature/manual-data-harvest`

## Dependencies
- Core UI Framework (#1)
- Game Loop Foundation (#2) 
- Resource Display System (#3)