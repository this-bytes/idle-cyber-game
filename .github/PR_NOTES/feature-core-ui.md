# PR notes — feature/core-ui

Branch: `feature/core-ui`

Summary:
- Implement the core UI vertical slice: top HUD, resource bindings, and specialist roster placeholder.

Files to change (suggested):
- `src/core/ui_manager.lua` (register UI panels)
- `src/ui/` (new HUD and roster components)
- `src/core/resource_manager.lua` (ensure read API)

Testing:
- Add unit tests under `tests/` for ResourceManager outputs and UI formatting utilities.

Acceptance criteria:
- See `issues/001-core-ui.md`.
