## Description
Implement the Processing Power (PP) resource and Processing Cores that act as multipliers for Data Bit generation. This adds strategic depth by requiring investment in both generators and multipliers.

## Acceptance Criteria
- [ ] Processing Power resource tracked and displayed
- [ ] Single-Core Processor (50 DB): 0.1 PP/sec, 1.1x DB multiplier
- [ ] Multi-Core Array (500 DB): 1 PP/sec, 1.2x DB multiplier
- [ ] Processing Power multiplies all Data Bit generation
- [ ] Multiplier effect visible in resource display tooltips
- [ ] PP generation works like DB generation (real-time)

## Technical Requirements
- **Multiplier Calculation:** Apply PP multiplier to all DB generation sources
- **Resource Integration:** PP displayed alongside DB in resource panel
- **Performance:** Efficient multiplier application for all generators
- **Balance:** Meaningful but not overpowered multiplier effects
- **Precision:** Handle fractional multipliers accurately

## Implementation Notes
- Reference `.github/copilot-instructions/03-core-mechanics.md` for processing core definitions
- Implement PP as separate resource with its own generation
- Apply PP multiplier to total DB/sec rather than individual generators for efficiency
- Design multiplier formula for future expansion and balance
- Consider diminishing returns for very high PP values

## Files to Create/Modify
- `core/resources.lua` - Add Processing Power resource
- `mechanics/processing.lua` - Processing Power system
- `data/processingdata.lua` - Processing core definitions
- `mechanics/generators.lua` - Update to apply PP multipliers
- `ui/resourcedisplay.lua` - Display PP alongside DB

## Testing Checklist
- [ ] PP generates at expected rates
- [ ] PP multipliers apply correctly to DB generation
- [ ] Resource display shows both DB and PP accurately
- [ ] Multiplier effects scale properly with PP amount
- [ ] Save/load preserves PP and processing cores
- [ ] Performance remains good with multiplier calculations

## Definition of Done
- [ ] Processing Power system fully functional
- [ ] First tier processing cores implemented
- [ ] Multiplier effects working and balanced
- [ ] UI integration complete and clear
- [ ] Foundation ready for advanced processing tiers

## Branch
`feature/processing-cores`

## Dependencies
- Basic Server Farm Infrastructure (#6)
- Resource Display System (#3)