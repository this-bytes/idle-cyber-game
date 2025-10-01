# Consolidation Plan - Fix the "Smart" Duplication Problem

## The Problem
When asked to improve files, I created duplicates with "smart_" prefix instead of improving the originals.

## Files to Consolidate

### Main Menu
- **KEEP & IMPROVE**: `src/scenes/main_menu.lua` (rename smart_main_menu.lua to this)
- **DELETE**: `src/scenes/smart_main_menu.lua` (after merging)
- **ACTION**: Copy the working smart_main_menu.lua content to main_menu.lua

### SOC View
- **KEEP & IMPROVE**: `src/scenes/soc_view.lua` (rename smart_soc_view.lua to this)
- **DELETE**: `src/scenes/smart_soc_view.lua` (after merging)
- **ACTION**: Copy the working smart_soc_view.lua content to soc_view.lua

### Update References
- **FILE**: `src/soc_game.lua`
- **CHANGE**: Update requires from "smart_main_menu" to "main_menu"
- **CHANGE**: Update requires from "smart_soc_view" to "soc_view"

## Steps

1. Backup current state (git commit)
2. Copy smart_main_menu.lua → main_menu.lua (overwrite)
3. Copy smart_soc_view.lua → soc_view.lua (overwrite)
4. Update src/soc_game.lua requires
5. Delete smart_*.lua files
6. Test game still runs
7. Commit with message "Consolidate: Remove smart_* duplicates, use canonical scene names"

## Future Behavior
**NEVER create duplicate files**
- If asked to improve X, modify X directly
- If X might break, create a backup branch in git
- ONE file per concept, always
