# Project Overview — Idle Sec Ops

Goal
Build Idle Sec Ops: an engaging idle/incremental game where players manage a Security Operations Center (SOC). The game balances passive security management (automatic defense and client satisfaction) with active skill-building (training staff, upgrading tools, and developing capabilities) to secure higher-value contracts and grow into a premier managed SOC provider.

Core Principles
- Single Vision: All work aligns with the concept of Idle Sec Ops.
- Vertical Slice First: Deliver a playable MVP (Idle HQ + active response on a 'hacker' terminal + placeholder pixel assets/audio).
- Git-First Workflow: Use feature branches, atomic commits, and protect main (hotfixes only).
- Modular Design: Build extensible systems that are dynamic in nature and use a JSON model to create the items for that particular system. This allows for easy expansion and balancing without code changes.Systems should not care about any specific item, just the properties that an item for that system should have.
- Idle Progression: Background stats, staff skills, and tools keep clients protected automatically.
- Active Engagement: Players advance by upskilling, upgrading, and unlocking bigger contracts.
- Simplicity: Keep mechanics intuitive and approachable, flavored with light cybersecurity humor.
- Scalable Depth: Start simple, expand into automation, client tiers, and prestige/reset systems.
- Thematic Consistency: Strike a playful balance between cybersecurity jargon and player accessibility.
- Rewarding Loop: Ensure players feel progress both passively (idling) and actively (choices).

High-Level Deliverables
- Core Systems
    - Idle HQ with passive resource generation (revenue, reputation, XP, mission tokens).
    - Team & Specialist system (3 starter specialists with stats, cooldowns, and leveling).
    - Idle dashboard view and active is classic terminal interface to solve the puzzles.
    - Mouse and 
    - Defined resources: Credits, Contracts, Alerts, Experience.
    - Clear Game Loop documentation (passive defense + active progression).
    - Progression framework (staff skill trees, contract tiers, tool upgrades, prestige).
- Assets & Presentation
    - Pixel art set: 3 specialists, SOC HQ background, terminal interface.
    - Minimal audio: one crisis loop, three SFX.
    - Basic UI/UX wireframes (idle dashboards, contracts, upgrade trees, skills).
- Documentation
    - Instruction set (this file).
    - Asset manifest.
    - Technical specs (platforms: mobile, web, PC; save/progress; monetization outline).
    - Thematic flavor guide with pun-based names (e.g., False Positive Filter, Phish Tank, Patch Pipeline).

Workflow & Branching
- Branch naming: `feature/<system>-<short>` (e.g., `feature/crisis-mode-v1`).
- Commit style: `type(scope): short description` (e.g., `feat(crisis): add terminal UI skeleton`).
- Pull requests: PRs must include checklist of acceptance criteria tied to the instructions and link to the instruction section implementing the change.

Acceptance Criteria (for merges)
- New code maps to a section in the instruction set.
- Assets follow `assets/` naming conventions in the instruction files.
- All automated tests (where present) pass; if no tests, a reviewer must verify the vertical-slice behavior locally.

Reference
This file is the short canonical README for contributors. For deep design/art/tech details, see the other instruction files in this folder which all follow the Idle Sec Ops vision.
