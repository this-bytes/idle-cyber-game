# Legacy System Migration Analysis

This document analyzes the "cool concept" files found in `src/legacy` and outlines a path for their potential integration into the modern game architecture.

## 1. `room_system.lua` & `room_event_system.lua`

*   **Concept:** These systems managed a physical layout of the Security Operations Center (SOC). Different rooms could be built, upgraded, and would host different specialists or equipment. Events could trigger within specific rooms.
*   **Potential:** This is a fantastic concept for adding a deeper layer of simulation and visual progression. Instead of an abstract SOC, the player would build and manage a physical space.
*   **Migration Path:**
    1.  **Data Model:** Define room data in JSON (`src/data/rooms.json`). This would include room types (e.g., "Analyst Bay", "Server Room", "Forensics Lab"), costs, upgrade paths, and effects (e.g., +1 specialist slot, +5% detection capability).
    2.  **System Integration:** Create a new `RoomSystem` in `src/systems/`. This system would manage the player's owned rooms, handle construction, and apply passive bonuses from those rooms to other systems (like `ThreatSystem` or `SpecialistSystem`).
    3.  **UI Integration:** The `soc_view.lua` scene could be updated to include a new panel for "SOC Layout" or "Infrastructure". This would visually represent the built rooms. A more advanced implementation could render a simple 2D map of the SOC.
    4.  **Event Integration:** The `RoomEventSystem` concept can be merged into the main `EventSystem`. Dynamic events could have a new property, `"location"`, which would tie them to a specific room, adding narrative flavor.

## 2. `zone_system.lua`

*   **Concept:** This system appears to have managed different network "zones" or areas of operation, possibly for deploying specialists or running contracts.
*   **Potential:** This aligns perfectly with the idea of expanding the player's influence and taking on more complex challenges. It provides a clear progression path beyond just upgrading the SOC itself.
*   **Migration Path:**
    1.  **Data Model:** This is already partially implemented with `src/data/locations.json`. We should expand this file to define zones, their unlock requirements, and the types of contracts or threats found within them.
    2.  **System Integration:** A new `ZoneSystem` (or `LocationSystem`) in `src/systems/` would manage which zones the player has unlocked. The `ContractSystem` would then use this information to generate contracts specific to unlocked zones.
    3.  **UI Integration:** The `soc_view.lua` could feature a "World Map" or "Network View" panel, showing the different zones and the player's progress in securing them.

## 3. `particle_system.lua` & `sound_system.lua`

*   **Concept:** These are for adding visual flair (particles) and audio feedback (sound effects, music).
*   **Potential:** Essential for creating an engaging and polished player experience.
*   **Migration Path:**
    1.  **Modernization:** These systems can be moved directly from `src/legacy` to `src/systems/`.
    2.  **Review & Refactor:** Review the code to ensure it aligns with the current event bus architecture. For example, the `SoundSystem` should subscribe to events like `"threat_detected"`, `"contract_completed"`, etc., to play appropriate sound effects. The `ParticleSystem` could be used to create effects on the UI when events occur.
    3.  **Asset Loading:** Implement proper loading of sound and image assets from the `assets/` directory.

By integrating these legacy concepts, we can significantly enrich the gameplay, moving closer to the vision of a deep, engaging RPG-idle game.
