# Skill System Integration Plan

This document outlines the plan to fully integrate the existing 'Skills' system into the modern game architecture, making it a core part of specialist and player progression.

## 1. Current State Analysis

*   **`SKILL_SYSTEM.md`**: Provides a solid conceptual overview of a data-driven skill system. It describes categories, effects, and a clear process for adding new skills.
*   **`src/data/skills.json`**: A basic JSON file exists with two skills ("Basic Analysis", "Incident Response"). It's a good starting point but needs to be expanded. The documentation refers to a `.lua` file, indicating a likely refactor from Lua tables to JSON.
*   **`src/systems/skill_system.lua`**: A `SkillSystem` exists but it is **non-functional and disconnected**. It requires a `src/data/skills.lua` file which does not exist in the current data-driven JSON architecture. It has placeholder logic for awarding XP and calculating effects but is not called by any other active system.

**Conclusion:** We have a great design document and a skeleton implementation, but the system is currently dormant and needs to be wired into the rest of the game.

## 2. Integration & Refactoring Plan

### Step 1: Refactor `SkillSystem` to use JSON
*   **Task:** Modify `src/systems/skill_system.lua` to load its data from `src/data/skills.json` instead of the non-existent `skills.lua`.
*   **Implementation:**
    *   The `SkillSystem.new()` constructor will receive the `DataManager` as a dependency.
    *   It will call `dataManager:getData("skills")` to load the skill definitions.
    *   All internal functions will be updated to reference the skills loaded from the JSON data structure.

### Step 2: Integrate with `SpecialistSystem`
*   **Task:** Connect skills to specialists to allow them to level up and gain new abilities.
*   **Implementation:**
    1.  **Initialization:** When a specialist is hired in `SpecialistSystem`, call `skillSystem:initializeEntity(specialist.id, specialist.type)` to grant them their starting skills.
    2.  **XP Gain:** When a specialist completes a contract or resolves a threat, the `ContractSystem` or `ThreatSystem` will publish an event (e.g., `award_skill_xp`). The `SkillSystem` will subscribe to this event and award XP to the relevant specialist and skill.
    3.  **Applying Effects:** The `SpecialistSystem`'s `getStats` or `getCapabilities` function will be modified. It will call `skillSystem:getSkillEffects(specialist.id)` and add the returned bonuses (e.g., `efficiency`, `speed`) to the specialist's base stats.

### Step 3: Integrate with `ContractSystem` & `ThreatSystem`
*   **Task:** Make contract and threat outcomes dependent on specialist skills.
*   **Implementation:**
    1.  **Contract Performance:** When calculating contract success or rewards, the `ContractSystem` will factor in the skill-modified stats of the assigned specialists.
    2.  **Threat Resolution:** In `ThreatSystem`, when a specialist is assigned to a threat, their skill effects (`defense`, `crisisSuccessRate`, etc.) will be used to calculate the probability of success.
    3.  **XP Awards:** Upon completion of a contract or threat, these systems will be responsible for publishing the event to award skill XP. The amount of XP can be based on the difficulty of the task.

### Step 4: UI Integration in `soc_view.lua`
*   **Task:** Create a new UI panel in the main `soc_view` to display specialist skills and progression.
*   **Implementation:**
    1.  **New Panel:** Add a "Skills" or "Training" panel to the `soc_view`.
    2.  **Display Logic:** This panel will iterate through the player's specialists. For each specialist, it will call `skillSystem:getEntitySkills(specialist.id)` to get their unlocked skills, levels, and XP.
    3.  **UI Elements:** The UI will display each skill, its current level, an XP bar showing progress to the next level, and the effects the skill provides. This makes the progression tangible to the player.

### Step 5: Expand Skill Data
*   **Task:** Populate `src/data/skills.json` with a wider variety of skills based on the categories outlined in `SKILL_SYSTEM.md`.
*   **Implementation:** Add at least 5-10 new skills covering categories like "Network Security", "Leadership", and more "Specialized" skills. This will provide a meaningful progression path for the player to explore.

By following this plan, the 'Skills' system will transform from a dormant concept into a central, engaging RPG mechanic that directly impacts gameplay and player strategy.
