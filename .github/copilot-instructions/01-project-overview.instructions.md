# Project Overview & Development Principles

## Project: Cyberspace Tycoon (Idle Cybersecurity Game)

**Goal:** To develop an idle game using Lua and LÖVE 2D, focusing on learning software development principles, particularly Git version control, through an engaging cybersecurity theme.

## Core Principles for Development

### 1. Iterative Development
- Build features in small, manageable steps
- Focus on getting basic functionality working before adding complexity
- Each step should represent a logical, self-contained change

### 2. Git-First Workflow
- **Branches for Features:** Every new feature (e.g., adding a new resource, implementing an upgrade, fixing a bug) will be developed on its own dedicated branch
- **Frequent, Atomic Commits:** Commits should be made regularly, after every small, functional change. Each commit message should clearly describe what was changed and why
  - *Good Example:* `git commit -m "Implement basic data generation per second"`
  - *Bad Example:* `git commit -m "Lots of stuff"`
- **Clear Commit Messages:** Use imperative mood (e.g., "Add," "Fix," "Implement")
- **Regular Merging:** Once a feature branch is complete and tested, merge it back to the `main` branch
- **No Direct Commits to `main` (unless hotfix):** All development should happen on feature branches. The `main` branch should always represent a stable, playable version of the game

### 3. Clean Code Practices
- **Readability:** Write code that is easy for others (and your future self) to understand
- **Modularity:** Break down larger problems into smaller, testable functions or modules
- **Comments:** Use comments to explain complex logic or design decisions, but avoid commenting on obvious code

### 4. Learning Focus
- Prioritize understanding *why* something works over simply copying code
- Actively explore LÖVE 2D documentation and Lua language features
- Don't be afraid to experiment and make mistakes – that's what Git branches are for!

## Key Areas to Track for Git Practice

- **Initialization:** Setting up the initial Git repository
- **Basic Workflow:** `git add`, `git commit`
- **Branching:** `git branch`, `git checkout -b`
- **Merging:** `git merge`
- **Viewing History:** `git log`
- **Stashing (Optional but useful):** `git stash`

## Game Development Milestones (to be developed iteratively)

1. **Core Resource Generation:** Implement a primary resource (e.g., "Data Bits," "Processing Power") that is generated over time or by clicks
2. **Upgrades System:** Allow players to purchase upgrades that increase resource generation or unlock new features
3. **Threat/Defense Mechanics:** Introduce a basic threat system (e.g., "Malware Attacks") and a defense system (e.g., "Firewall Upgrades," "Anti-Virus Scanners")
4. **UI/UX:** Basic visual display of resources, buttons, and progress

## Modular Instruction Structure

This project uses a modular approach to copilot instructions. Each aspect of development has its own focused instruction file:

- `02-game-story-narrative.instructions.md` - World setting, factions, and narrative context
- `03-core-mechanics.instructions.md` - Resources, generation systems, and upgrade mechanics
- `04-defense-threat-systems.instructions.md` - Threat classification and defense infrastructure
- `05-progression-prestige.instructions.md` - Character advancement and prestige systems
- `06-events-encounters.instructions.md` - Dynamic events and faction relations
- `07-endgame-meta.instructions.md` - Endgame content and meta-progression
- `08-quality-accessibility.instructions.md` - Quality of life and accessibility features
- `09-balancing-math.instructions.md` - Mathematical frameworks and balancing
- `10-ui-design.instructions.md` - Visual design and interface goals
- `11-technical-architecture.instructions.md` - Platform considerations and optimization
- `12-development-roadmap.instructions.md` - Development phases and roadmap

When working on specific features, reference the appropriate instruction file for detailed guidance on that aspect of the game.