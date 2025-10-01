# Backend Directory - DEPRECATED

⚠️ **This directory has been deprecated as part of the AWESOME Backend Architecture migration.**

## What happened?

The legacy Python Flask backend (`app.py`, `game_data.py`) has been **removed** in favor of the new AWESOME (Adaptive Workflow Engine for Self-Organizing Mechanics and Emergence) backend architecture implemented in Lua.

## New Architecture

The game now uses a data-driven, effect-based backend system written entirely in Lua:

- **ItemRegistry** (`src/core/item_registry.lua`) - Universal item loading and validation
- **EffectProcessor** (`src/core/effect_processor.lua`) - Cross-system effect calculations
- **FormulaEngine** (`src/core/formula_engine.lua`) - Safe, data-driven formula evaluation
- **ProcGen** (`src/core/proc_gen.lua`) - Procedural content generation
- **SynergyDetector** (`src/core/synergy_detector.lua`) - Automatic synergy detection
- **AnalyticsCollector** (`src/core/analytics_collector.lua`) - Privacy-respecting game analytics

## Benefits

✅ **Data-driven**: All game content defined in JSON  
✅ **No server required**: Game runs entirely client-side  
✅ **Emergent gameplay**: Synergies and effects combine automatically  
✅ **Procedural generation**: Infinite unique content  
✅ **Better performance**: Native Lua integration with LÖVE 2D  

## Migration

For documentation on the new architecture, see:

- `/docs/AWESOME_BACKEND_README.md` - Overview and quick start
- `/docs/BACKEND_VISION.md` - Architecture philosophy
- `/docs/BACKEND_IMPLEMENTATION_GUIDE.md` - Technical implementation
- `/ARCHITECTURE.md` - Updated technical documentation

The Python backend was designed for online multiplayer features that were never fully implemented. The new Lua-based system provides all the necessary functionality for the idle game mechanics with better performance and maintainability.
