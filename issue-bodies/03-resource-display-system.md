## Description
Create the resource display system to show Data Bits (DB), generation rates, and basic statistics. This system will expand to show all resources as the game grows.

## Acceptance Criteria
- [ ] Data Bits current amount displayed prominently
- [ ] Data Bits per second generation rate shown
- [ ] Numbers format properly (1.2K, 3.4M, etc.)
- [ ] Real-time updates as resources change
- [ ] Smooth number animations/transitions
- [ ] Color coding for different resource types

## Technical Requirements
- **Update Frequency:** Real-time (every frame for smooth animation)
- **Number Formatting:** Scientific notation for large numbers
- **Performance:** Minimal impact on frame rate
- **Extensibility:** Easy to add new resource types
- **Precision:** Handle floating point carefully for accuracy

## Implementation Notes
- Reference `.github/copilot-instructions/03-core-mechanics.md` for resource definitions
- Use proper number formatting for readability
- Implement smooth animation for number changes
- Design system to easily add Processing Power and Security Rating later
- Consider color-blind accessibility in design

## Files to Create/Modify
- `ui/resourcedisplay.lua` - Main resource display component
- `utils/numberformat.lua` - Number formatting utilities
- `core/resources.lua` - Resource data structure
- `ui/components/counter.lua` - Animated counter component

## Testing Checklist
- [ ] Resource values display correctly
- [ ] Large numbers format properly (millions, billions)
- [ ] Real-time updates work smoothly
- [ ] Animations don't cause performance issues
- [ ] Display works with zero/negative values
- [ ] Precision maintained for small decimal changes

## Definition of Done
- [ ] Resource display functional and attractive
- [ ] Number formatting handles all expected ranges
- [ ] System ready for additional resource types
- [ ] Performance optimized for continuous updates
- [ ] Visual design matches game theme

## Branch
`feature/resource-display`

## Dependencies
- Core UI Framework (#1)