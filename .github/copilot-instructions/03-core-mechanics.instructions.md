# Core Mechanics — Idle Sec Ops

Objective
Define the game's mechanics so developers and designers implement consistent, testable systems. This file maps to the canonical gameplay in the main instruction file.

That's a smart move. Merging both concepts into a single document ensures consistency and provides the coding agent with a definitive blueprint.

Here is the consolidated **Game Design Document: Idle Sec Ops** structure, combining your core mechanics with the detailed Incident and Specialist system.

---

## Game Design Document: Idle Sec Ops

### 1. Core Systems & Resources

This section defines the fundamental economic and progression elements of the game.

#### A. Resources
| Resource | Purpose | Acquisition / Usage |
| :--- | :--- | :--- |
| **Money** (Currency) | Primary economy | Used to hire, pay staff, buy equipment, and upgrade facilities. Generated passively from Contracts. |
| **Reputation** | Progression gate | Unlocks higher-tier Contracts, Faction benefits, and special facilities. Generated passively from Contracts. |
| **XP / Specialist XP** | Unit leveling | **XP** is gained by specialists who successfully resolve Incidents. Used to level up Specialists and boost their Traits/Stats. |
| **Mission Tokens** (Intel) | Rare resource | **Primary reward for resolving Incidents.** Used to unlock powerful Upgrades or hire elite Specialists. |

#### B. Contracts
Contracts are the source of passive income and progression.
* **Properties:** Tier, Budget (Money), Duration, and Risk Profile.
* **Mechanics:** Generate periodic **Money**, **Reputation**, and general XP over time.
* **Constraint:** Higher-tier contracts inherently increase the frequency and complexity of **Incident Mode** triggers.

---

### 2. The Core Loop: Idle & Active Contribution

The game uses a two-tiered resolution system to determine if a triggered threat is handled passively (**Idle**) or requires player interaction (**Active**).

#### A. The Idle Loop
1.  **Contract Income:** Contracts generate passive income, reputation, and XP.
2.  **Spending:** Player spends rewards to scale (hire, upgrade, facilities).
3.  **Threat Check:** An internal **Incident Generation Timer** runs continuously, checking for a potential threat escalation (per the current contract risk profile).

#### B. The Incident Mode System (Active Loop)
When a threat is detected, it immediately runs the **Idle Resolution Check**.

1.  **Idle Resolution Check:**
    * The Incident's required **Trait Value** (e.g., Security $\ge 50$) is compared against the player's **Global Auto-Resolve Stat** (derived from Facilities and Specialists' passive contribution).
    * **Success (Idle Yield):** Threat is instantly and automatically resolved. Player receives a **reduced reward** (e.g., $+50\%$ of base reward) and a log entry. The threat is **not** added to the queue.
    * **Failure (Escalation):** A unique **Incident Entity** is created and pushed to the **Alerts Queue**, initiating **Incident Mode** (player intervention required).

2.  **Resolution:** The player must assign an available **Specialist** manually, or the system auto-assigns the best fit. Successful resolution grants the **full base reward** and **Mission Tokens**.

---

### 3. Incident & Specialist Management System

This system handles the unique escalation events and the units required to resolve them.

#### A. Specialist Entity (Data Structure)
Specialists are unique units with stats and a mandatory cooldown.

| Property | Description | Integration to Gameplay |
| :--- | :--- | :--- |
| **Role** | Archetype (e.g., Hacker, Enforcer) | Determines base **Traits** and available **Abilities**. |
| **Level / XP** | Progression tracker | Determines the Specialist's current **Trait** values. Gains XP only on successful Incident resolution. |
| **Traits** | Skill mapping | A map of skills and values (e.g., `{Security = 80, Engineering = 20}`). Used for Incident resolution checks. |
| **`is_busy`** | State | `true` when assigned to an active Incident. Prevents re-assignment. |
| **`cooldown_timer`** | Time gate | Specialist is unusable after resolving an Incident until the cooldown expires. |

#### B. Incident Entity (Data Structure)
Each escalation is a unique, trackable object.

| Property | Description | Role in System |
| :--- | :--- | :--- |
| **`id`** | Unique Identifier | Ensures trackability in the Alerts Queue. |
| **`trait_required`** | Key Trait | The specific trait needed (e.g., "Security," "Engineering"). |
| **`trait_value_needed`** | Difficulty | The minimum skill value required for successful resolution. |
| **`time_to_resolve`** | Duration | The time a specialist will be busy resolving the Incident. |
| **`base_reward`** | Full Payout | The rewards granted on successful manual/auto-assignment (includes **Mission Tokens**). |
| **`status`** | State | `Pending`, `AutoAssigned`, `ManualAssigned`, `Resolved`, `Failed`. |

#### C. Specialist Assignment Logic
This process determines how Incidents are handled once they enter the queue.

| Assignment Type | Trigger / Criteria | Outcome |
| :--- | :--- | :--- |
| **Auto-Assignment** | Runs periodically on **Pending** Incidents with **available** Specialists. **Criteria:** Finds the Specialist with the **highest relevant Trait value** that exceeds the Incident's requirement. | Sets Incident status to `AutoAssigned`. Specialist becomes busy and the resolution timer starts. |
| **Manual Assignment** | Player action on a **Pending** Incident. Player chooses an **available** Specialist who meets the Trait requirement. | Sets Incident status to `ManualAssigned`. Specialist becomes busy and the resolution timer starts. **Allows player to use unique Abilities for bonus rewards/effects.** |

---

### 4. Upgrades & Facilities

Facilities and upgrades affect the overall capacity and passive defense of the organization.

| Component | Functionality | Tie-In to New System |
| :--- | :--- | :--- |
| **Facilities** | Increase capacity and passive gains. | Direct contribution to the **Global Auto-Resolve Stat**, improving the chance that threats pass the **Idle Resolution Check**. |
| **Upgrades** | Scale resource generation and specialist stats. | May increase specialist **Traits** (improving their ability to resolve Incidents) or reduce **Specialist Cooldown**. |

### Design Constraints (Summary)
* **Data-first approach:** All contracts, specialists, and upgrades must be defined in external configuration files (e.g., Lua tables, JSON).
* **Active Relevance:** **Mission Tokens** must remain the primary reward for **Incident Mode** resolution to keep the active loop engaging.
* **Balance:** **Cooldowns** and resource costs must prevent trivializing active interaction.

