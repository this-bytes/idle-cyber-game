## Description
Implement the first tier of server farm infrastructure that provides automated Data Bit generation. This introduces the core idle gameplay mechanics where resources generate over time.

## Acceptance Criteria
- [ ] Refurbished Desktop upgrade (10 DB): 0.1 DB/sec
- [ ] Basic Server Rack upgrade (100 DB): 1 DB/sec  
- [ ] Small Data Center upgrade (1,000 DB): 10 DB/sec
- [ ] Multiple copies of same upgrade can be purchased
- [ ] Generation rates stack additively
- [ ] Real-time generation visible in resource display

## Technical Requirements
- **Generation Timing:** Frame-independent using delta time
- **Precision:** Handle fractional DB/sec accurately
- **Performance:** Efficient calculation for multiple generators
- **Scalability:** Support for hundreds of generator buildings
- **Persistence:** Save generator counts and apply on load

## Implementation Notes
- Reference `.github/copilot-instructions/03-core-mechanics.md` for server farm tier definitions
- Implement per-second generation using delta time accumulation
- Design generator data structure for easy expansion to more tiers
- Consider generation rate modifiers for future Processing Power integration
- Plan for different generator types with unique properties

## Files to Create/Modify
- `mechanics/generators.lua` - Generator system core
- `data/generatordata.lua` - Generator definitions and stats
- `ui/generatorpanel.lua` - Generator purchase UI
- `mechanics/idlegeneration.lua` - Automated resource generation
- `core/savedata.lua` - Save generator counts and states

## Testing Checklist
- [ ] Generators produce expected DB/sec rates
- [ ] Multiple generators stack properly
- [ ] Generation continues when game is idle
- [ ] Resource display shows generation accurately
- [ ] Save/load preserves generator counts
- [ ] Performance acceptable with many generators active

## Definition of Done
- [ ] First tier server farm fully implemented
- [ ] Idle generation mechanics working smoothly
- [ ] UI integration complete and intuitive
- [ ] System ready for Processing Power multipliers
- [ ] Performance validated for expected scale

## Branch
`feature/basic-server-farm`

## Dependencies
- Simple Upgrade System (#5)
- Resource Display System (#3)