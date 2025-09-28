🛡️ SOC Refactor PR: Incident Report & Response Plan
Incident Summary
The current game systems are in a critical failure state. Legacy code, half-implemented systems, and broken UI are introducing vulnerabilities that block progress. The last attempted “refactor” was never fully implemented, leaving the architecture fragmented and unstable.

This PR initiates a full SOC (Security Operations Centre) Refactor, rebuilding the core systems into a stable, extensible framework so that the cybersecurity idle game can scale safely in the future.

Root Cause Analysis
Legacy Baggage: Old, unused systems left unchecked, adding complexity without value.

Incomplete Refactor: Previous architectural plans were never executed—structure exists only on paper.

UI Vulnerabilities:

Overlapping components are visually broken.

Keybindings collide, rendering the UI unusable.

Unbounded Resource Generation: Income loops provide infinite rewards, breaking progression.

Navigation Breach: Room movement is inconsistent and “modes” add unnecessary complication for an idle structure.

Idle Loop Corruption: Core stats (offense, defense, detection, analysis) are undefined or unconnected, breaking the premise of idle growth.

Refactor Plan (Phased Response)
Phase 1 – Core SOC Overhaul

Remove legacy and dead code.

Establish clean frameworks: GameLoop, ResourceManager, StatsSystem, UpgradeSystem, ThreatSimulation, UIManager.

Add dependency injection and clear system boundaries.

Phase 2 – Idle & Stat Growth Foundation

Rebuild progression systems to prevent infinite loops.

Define offensive/defensive/analysis stats as the idle growth backbone.

Tie stat scaling directly to resource and progression mechanics.

Phase 3 – UI Rebuild (SOC Dashboard)

Scrap unusable legacy UI.

Build a clean SOC console view—organized, modular, and extensible.

Assign unique input mappings to prevent overlap.

Phase 4 – Room Interaction Redesign

Rooms → functional SOC units (Training, Threat Lab, Operations).

No separate "modes"—all actions feed into the idle growth engine.

Phase 5 – SOC Hardening

Add unit tests and quality gates like defense layers.

Build monitoring scaffolds (logs, debug hooks).

Once the SOC core is stable, open new issues for expansions (prestige loops, advanced threats, client contracts, employee skill trees).

Mitigations / Safeguards
Tests enforce stability: Each subsystem will have dedicated unit coverage.

Config-driven design: Expansion handled by data/configs, not hardcoded logic.

Clean separation of concerns: Each refactored system has single ownership of responsibilities.

Next Steps / Future Issues
Introduce advanced threats tied to stats and idle growth.

Layer in prestige systems for long-term replayability.

Add employee training trees, expanding idle depth with SOC staff specialization.

Expand the UI dashboard into modular “panels” for new features.

Ensure extensibility for multiplayer/company vs attacker modes in future.