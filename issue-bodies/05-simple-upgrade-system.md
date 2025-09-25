## Description
Create the basic upgrade purchase system that allows players to spend Data Bits on improvements. Start with simple click upgrades and basic infrastructure purchases.

## Acceptance Criteria
- [ ] Upgrade menu/panel displays available upgrades
- [ ] Purchase button for each upgrade shows cost
- [ ] Sufficient resources check before allowing purchase
- [ ] Resource deduction on successful purchase
- [ ] Upgrade effects applied immediately
- [ ] Basic cost scaling for repeated purchases

## Technical Requirements
- **Cost Calculation:** Exponential scaling (base cost × growth_factor ^ owned)
- **Resource Validation:** Prevent purchases without sufficient resources
- **UI Integration:** Clean upgrade display with costs and descriptions
- **Data Persistence:** Save upgrade levels and apply on load
- **Extensibility:** Easy to add new upgrade types

## Implementation Notes
- Reference `.github/copilot-instructions/03-core-mechanics.md` for upgrade definitions
- Start with first few click upgrades: Ergonomic Mouse (5 DB), Mechanical Keyboard (25 DB)
- Implement exponential cost scaling with reasonable growth factors
- Design upgrade data structure for easy expansion
- Consider bulk purchase options for future implementation

## Files to Create/Modify
- `mechanics/upgrades.lua` - Upgrade system core
- `data/upgradedata.lua` - Upgrade definitions and costs
- `ui/upgradepanel.lua` - Upgrade UI components
- `mechanics/clicking.lua` - Update to apply click upgrades
- `core/savedata.lua` - Save/load upgrade states

## Testing Checklist
- [ ] Upgrades can be purchased with sufficient resources
- [ ] Purchases blocked when resources insufficient
- [ ] Upgrade effects apply correctly
- [ ] Cost scaling works as expected
- [ ] Save/load preserves upgrade progress
- [ ] UI updates properly after purchases

## Definition of Done
- [ ] Basic upgrade system fully functional
- [ ] First tier of click upgrades implemented
- [ ] Cost scaling and resource management working
- [ ] System architecture ready for expansion
- [ ] Save/load integration complete

## Branch
`feature/simple-upgrades`

## Dependencies
- Core UI Framework (#1)
- Game Loop Foundation (#2)
- Resource Display System (#3)