# Fixed: The "Smart_" Duplication Anti-Pattern

## What Was Wrong
When asked to improve a file (e.g., "make the menu smarter"), I was creating duplicate files with "smart_" prefixes instead of improving the original files. This caused:
- Code duplication and confusion
- Unused files taking up space
- Unclear which version is actually running
- Wasted effort on files not used by the game

## What I Fixed
1. **Consolidated main_menu.lua**: Replaced with the working smart_main_menu.lua content, deleted duplicate
2. **Consolidated soc_view.lua**: Replaced with the working smart_soc_view.lua content, deleted duplicate
3. **Updated references**: Changed src/soc_game.lua to use canonical names
4. **Renamed classes**: Changed internal class names from Smart* to canonical names

## The Rule Going Forward

### ✅ CORRECT BEHAVIOR
When asked to improve a file:
1. **Edit the existing file directly**
2. If worried about breaking things, create a git branch first
3. ONE file per concept - never duplicate

### ❌ NEVER DO THIS
- Creating "smart_X.lua" alongside "X.lua"
- Creating "new_X.lua" alongside "X.lua"  
- Creating "better_X.lua" alongside "X.lua"
- Any pattern that creates parallel versions

## About the Instruction Files
The user asked if the extensive instruction files might be making my judgment skew. My analysis:

**The instructions are NOT the problem.** The problem was my interpretation:
- Instructions say: "Be modular, extensible, follow patterns"
- I misinterpreted as: "Don't break existing code, create new files"
- What they actually mean: "Improve existing code in a modular way"

The instructions are detailed because they provide:
- Game design vision (story, mechanics, progression)
- Architecture principles (how to structure code)
- Development workflow (how to work with the codebase)

These are GOOD. They prevent random implementation decisions and keep the project coherent.

## What I Should Do Instead
When asked to improve something:
1. **Read the existing file**
2. **Understand what it does**
3. **Modify it directly** to add the improvement
4. **Test that it still works**
5. **Commit with clear description**

Never create a second version. Improve what exists.

## Verification
✅ Game runs correctly with consolidated files
✅ All 49 tests passing
✅ No more smart_* duplicates in src/scenes/
✅ Clear canonical file names (main_menu.lua, soc_view.lua)

## Future Checks
Before creating any new file, ask:
1. Does a file for this concept already exist?
2. If yes, can I improve that file instead?
3. If creating a new file is truly needed, is the name clear and canonical?

The default should always be: **Improve what exists.**
