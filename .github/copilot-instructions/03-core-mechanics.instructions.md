# Core Mechanics — Cyber Empire Command

Objective
Define the game's mechanics so developers and designers implement consistent, testable systems. This file maps to the canonical gameplay in the main instruction file.

Primary Systems
- Resources:
  - Money (currency): used to hire, pay staff, buy equipment.
  - Reputation: unlocks higher-tier contracts and faction benefits.
  - XP / Specialist XP: used for leveling specialists.
  - Mission Tokens (or Intel): rare resource earned from Crisis Mode to unlock upgrades or hire elite specialists.

- Contracts:
  - Offer periodic income and reputation; contracts have tier, budget, duration, and risk profile.
  - Contracts can be auto-assigned or manually staffed by the player.
  - Higher-tier contracts increase threat frequency and complexity.

- Team & Specialists:
  - Specialists have Role, Level, Stats (Efficiency, Speed, Trace, Defense), Abilities, and Cooldown.
  - Idle contribution: assigned specialists passively improve contract performance (higher income or lower breach chance).
  - Active contribution: Crisis Mode deployment with unique abilities and temporary busy states.

- Idle Loop:
  - Contracts generate income/reputation/XP over time.
  - Player spends rewards to scale (hire, upgrade, facilities).
  - Random events escalate occasionally into Crisis Mode (per instruction file for events).

- Upgrades & Facilities:
  - Facilities (e.g., Server Farm, Threat Intel Subscription) increase capacity and passive gains.
  - Upgrades scale via growth factors (see balancing file).

Design Constraints
- Ensure idle yield is meaningful but not overwhelming; Crisis Mode must remain relevant as the primary path for rare progression tokens.
- Cooldowns and resource costs prevent trivializing active interactions.

Data-first approach
- Define all contracts, specialists, and upgrades as data (JSON/TOML/Lua tables) so designers can iterate without code changes.
- Keep values in balancing config files, not hard-coded.
