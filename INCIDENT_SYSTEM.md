```markdown
# INCIDENT SYSTEM - CONSOLIDATED

This document describes the canonical incident/crisis handling approach in the codebase.

Summary
-------
The project previously contained multiple, conflicting implementations of an incident/crisis/admin system. Those duplicates have been consolidated into a single canonical implementation: `src/systems/incident_specialist_system.lua` (the "IncidentSpecialistSystem").

What changed
------------
- A canonical incident/specialist system now exists at `src/systems/incident_specialist_system.lua` and is registered with the `GameStateEngine`.
- Deprecated duplicate implementations were removed to reduce confusion and avoid conflicting behavior. Notable removals done during the consolidation:
	- `src/systems/crisis_system.lua` (kept as a thin compatibility adapter delegating to `src/systems/incident_specialist_system.lua`)
	- `src/scenes/admin_mode.lua` (kept as a compatibility wrapper delegating to `src.modes.admin_mode` when available)

Why this matters
-----------------
Keeping a single source of truth for incident logic ensures predictable behavior, a single persistence path via `getState()`/`loadState()`, and delivers a clean API for UI layers and other systems (specialists, threats, resource management) to interact with incidents.

How to use the canonical system
------------------------------
- The canonical system exposes the runtime API through the `Incident` system registered on the `GameStateEngine`. From other systems or scenes use:
	- `systems.Incident:initialize()` — load data and prepare the system
	- `systems.Incident:startIncident(id)` — begin an incident by definition id
	- `systems.Incident:getActiveIncident()` — inspect the active incident
	- `systems.Incident:useAbility(specialistId, abilityId, stageId, specialistAbilities)` — apply specialist ability to a stage
	- `systems.Incident:getAllIncidentDefinitions()` — retrieve data-driven definitions

Integration and admin tooling
----------------------------
The admin-mode and incident-response UI should talk to the canonical system via the event bus and the public API above. For debugging and editor workflows, the admin tooling can publish events such as `admin_command_deploy_specialist` which are handled by `SpecialistSystem` and the incident system.

Further reading
---------------
- `ARCHITECTURE.md` — high-level architecture and status of the refactor (the incident duplication item has been updated to "resolved").
- `docs/INCIDENT_REFACTOR.md` — short log of the refactor, files changed, and rationale.

If you need the old, deleted implementations for audit/history purposes they are available in the repository history (git). Prefer the canonical system for all future work.
```