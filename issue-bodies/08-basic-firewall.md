## Description
Implement the basic threat and defense system with simple Script Kiddie attacks and Basic Packet Filter firewall. This introduces risk/reward mechanics and the need for defensive investment.

## Acceptance Criteria
- [ ] Script Kiddie Attacks occur every 60-120 seconds
- [ ] Attacks steal 1-5% of current Data Bits if successful
- [ ] Basic Packet Filter firewall (500 DB) provides 15% attack reduction
- [ ] Attack success/failure notifications to player
- [ ] Security Rating resource tracked and displayed
- [ ] Firewall upgrades increase Security Rating

## Technical Requirements
- **Timing System:** Random intervals for threat occurrence
- **Damage Calculation:** Percentage-based resource loss
- **Defense System:** Security Rating vs Threat Level calculations
- **Notifications:** Visual/audio feedback for attacks
- **Balance:** Meaningful but not frustrating threat frequency

## Implementation Notes
- Reference `.github/copilot-instructions/04-defense-threat-systems.md` for threat definitions
- Implement simple random timer system for attack frequency
- Use percentage-based damage to scale with player progress
- Design threat system for easy expansion to more threat types
- Consider player feedback on threat frequency and impact

## Files to Create/Modify
- `mechanics/threats.lua` - Threat system core
- `mechanics/defense.lua` - Defense and Security Rating system
- `data/threatdata.lua` - Threat definitions and parameters
- `data/defensedata.lua` - Defense upgrade definitions
- `ui/notifications.lua` - Attack notification system
- `core/resources.lua` - Add Security Rating resource

## Testing Checklist
- [ ] Threats occur at expected intervals
- [ ] Attack damage calculations work correctly
- [ ] Firewall reduces attack success rate
- [ ] Notifications appear for attack events
- [ ] Security Rating affects defense effectiveness
- [ ] Save/load preserves defense state

## Definition of Done
- [ ] Basic threat and defense system operational
- [ ] First tier firewall upgrade functional
- [ ] Attack mechanics balanced and fair
- [ ] Player feedback system working
- [ ] Foundation ready for advanced threat types

## Branch
`feature/basic-firewall`

## Dependencies
- Processing Cores System (#7)
- Resource Display System (#3)