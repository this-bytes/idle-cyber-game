# INCIDENT SYSTEM - DEPRECATED

**WARNING: This document is deprecated and does not reflect the current state of the codebase.**

The codebase contains at least four different, conflicting implementations of an incident/crisis/admin system. The logic is spread across:

- `src/modes/admin_mode.lua`
- `src/scenes/admin_mode.lua`
- `src/scenes/incident_response.lua`
- `src/systems/crisis_system.lua`

This architectural inconsistency is a critical issue that must be resolved.

**DO NOT USE THIS DOCUMENT AS A REFERENCE.**

A full refactoring is required to consolidate these different implementations into a single, canonical system. Once that is complete, this document should be rewritten to reflect the new, unified architecture.