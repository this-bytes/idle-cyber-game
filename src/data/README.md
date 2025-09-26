Data files for game tuning

We moved core data structures (contracts, defs) into JSON so the backend can load and edit them for live tuning.

Files
- `contracts.json` - array of contract templates. Each entry should include `id`, `clientName`, `description`, `baseBudget`, `baseDuration`, `reputationReward`, `riskLevel`, and `requiredResources`.
- `defs.json` - top-level object with `Resources`, `Departments`, and `GameModes`.

Usage
- In LÖVE runtime, `src/data/contracts.lua` and `src/data/defs.lua` will attempt to load these JSON files from `src/data/` and fall back to embedded defaults if missing or invalid.
- The Lua modules expose `saveToJSON()` to write changes back to disk (useful for backend/editor workflows).

Editing from backend
- The backend can edit `src/data/*.json` directly and, if required, trigger a reload by restarting the game or implementing a small API endpoint to write the file and notify the running client.
