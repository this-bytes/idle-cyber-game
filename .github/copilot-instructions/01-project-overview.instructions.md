# Project Overview — Cyber Empire Command (Cyberspace Tycoon)

Goal
You are building "Cyber Empire Command": an idle-strategy game where the player runs a cybersecurity consultancy (SOC). The canonical game loop mixes long-term idle empire-building (contracts, revenue, reputation) with intense, neon-soaked SOC mode (timed tactical scenarios using specialist deployments). This file summarizes the project goals, development principles, and workflow to be followed by all contributors.

Core Principles
- Single canonical vision: "Cyber SOC Company protecting the digital frontier" — all instructions and designs in this repo must align with that concept.
- Iterative vertical-slice first: produce a playable MVP (idle HQ + SOC Dashboard + placeholder pixel assets and audio).
- Git-first workflow: feature branches for new systems, small atomic commits, no direct commits to `main` except hotfixes.
- Minimal, focused scope per iteration: keep features small and testable.

High-Level Deliverables (MVP vertical slice)
- Idle HQ with passive resource generation (revenue, reputation, XP, mission tokens).
- Team & specialists system (3 starter specialists with stats, cooldowns, and level).
- SOC UI and one interactive incident scenario.
- Pixel art palette and a minimal asset pack (3 specialists + HQ bg + terminal).
- One incident music loop + 3 SFX.
- Documentation: this instruction set + assets manifest.

Workflow & Branching
- Branch naming: `feature/<system>-<short>` (e.g., `feature/soc-mode-v1`).
- Commit style: `type(scope): short description` (e.g., `feat(soc): add terminal UI skeleton`).
- Pull requests: PRs must include checklist of acceptance criteria tied to the instructions and link to the instruction section implementing the change.

Acceptance Criteria (for merges)
- New code maps to a section in the instruction set.
- Assets follow `assets/` naming conventions in the instruction files.
- All automated tests (where present) pass; if no tests, a reviewer must verify the vertical-slice behavior locally.

Reference
This file is the short canonical README for contributors. For deep design/art/tech details, see the other instruction files in this folder which all follow the Cyber SOC Company vision.
