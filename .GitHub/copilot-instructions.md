## Project: Idle Cybersecurity Game

**Goal:** To develop an idle game using Lua and LÖVE 2D, focusing on learning software development principles, particularly Git version control, through a engaging cybersecurity theme.

---

### Core Principles for Development

1.  **Iterative Development:**
    * Build features in small, manageable steps.
    * Focus on getting basic functionality working before adding complexity.
    * Each step should represent a logical, self-contained change.

2.  **Git-First Workflow:**
    * **Branches for Features:** Every new feature (e.g., adding a new resource, implementing an upgrade, fixing a bug) will be developed on its own dedicated branch.
    * **Frequent, Atomic Commits:** Commits should be made regularly, after every small, functional change. Each commit message should clearly describe what was changed and why.
        * *Good Example:* `git commit -m "Implement basic data generation per second"`
        * *Bad Example:* `git commit -m "Lots of stuff"`
    * **Clear Commit Messages:** Use imperative mood (e.g., "Add," "Fix," "Implement").
    * **Regular Merging:** Once a feature branch is complete and tested, merge it back into the `main` branch.
    * **No Direct Commits to `main` (unless hotfix):** All development should happen on feature branches. The `main` branch should always represent a stable, playable version of the game.

3.  **Clean Code Practices:**
    * **Readability:** Write code that is easy for others (and your future self) to understand.
    * **Modularity:** Break down larger problems into smaller, testable functions or modules.
    * **Comments:** Use comments to explain complex logic or design decisions, but avoid commenting on obvious code.

4.  **Learning Focus:**
    * Prioritize understanding *why* something works over simply copying code.
    * Actively explore LÖVE 2D documentation and Lua language features.
    * Don't be afraid to experiment and make mistakes – that's what Git branches are for!

---

### Key Areas to Track for Git Practice

* **Initialization:** Setting up the initial Git repository.
* **Basic Workflow:** `git add`, `git commit`.
* **Branching:** `git branch`, `git checkout -b`.
* **Merging:** `git merge`.
* **Viewing History:** `git log`.
* **Stashing (Optional but useful):** `git stash`.

---

### Game Development Milestones (to be developed iteratively)

1.  **Core Resource Generation:** Implement a primary resource (e.g., "Data Bits," "Processing Power") that is generated over time or by clicks.
2.  **Upgrades System:** Allow players to purchase upgrades that increase resource generation or unlock new features.
3.  **Threat/Defense Mechanics:** Introduce a basic threat system (e.g., "Malware Attacks") and a defense system (e.g., "Firewall Upgrades," "Anti-Virus Scanners").
4.  **UI/UX:** Basic visual display of resources, buttons, and progress.

---

## Story & Game Concept: "Cyberspace Tycoon" (or similar working title)

**Setting:** The year is 2042. The world runs on data. You are a fledgling "Cyberspace Architect," starting your own digital fortress. Your goal is to expand your network, accumulate vast amounts of data, and defend against the constant barrage of digital threats from rival corporations, rogue hackers, and state-sponsored entities.

**Player Role:** A "Cyberspace Architect" managing a growing digital infrastructure.

**Core Loop:**
1.  **Generate Resources:** Accumulate "Data Bits" and "Processing Power."
2.  **Upgrade Infrastructure:** Spend resources to buy new servers, better security software, and automated data miners to increase passive generation.
3.  **Defend Against Threats:** Allocate resources (or automated defenses) to repel incoming cyberattacks that attempt to steal data or cripple your systems.
4.  **Expand Network:** Unlock new zones or functionalities as you progress, requiring more complex defenses and offering higher rewards.

**Initial Resources:**
* **Data Bits:** The primary currency. Used for upgrades and expansion.
* **Processing Power:** Increases the rate at which Data Bits are generated.

**Initial Mechanics:**
* **Manual Data Harvesting:** A button to click and generate a small amount of Data Bits.
* **Basic Servers:** Purchase servers to automatically generate Data Bits per second (DP/s).
* **Processing Cores:** Purchase cores to increase your overall Processing Power, which in turn boosts DP/s.
* **Basic Firewall:** A simple defense that reduces the chance of an initial, minor threat getting through.

