# 13-cyber-empire.instructions.md

## Title
Cyberspace Tycoon — "Cyber Empire Command" (Idle Strategy / Crisis Mode)

## Purpose
A single-file, comprehensive design & art-integration brief for the "Cyber Empire Command" 

concept: an idle-strategy game where the player runs a cybersecurity consultancy firm. This instruction file is the canonical reference for design, art, audio, and early implementation priorities. It is written to be actionable for artists, designers, and developers working in this repository (`love2d`/Lua).

## Short pitch
You are the lead security principal of a growing cybersecurity consultancy. Most of the game is idle — your teams passively generate income, reputation, and experience — but periodically you jump into neon-soaked Crisis Mode: intense, timed tactical scenarios where you assign specialists (SOC analysts, Threat Hunters, PenTesters, Incident Responders, etc.) to stop attacks and win rewards needed to level-up and unlock new capabilities. The aesthetic: retro pixel art with hacker-terminal UI and heavy cyberpunk neon vibes.

## Goals & success criteria
- Deliver a playable vertical slice with:
  - Idle HQ where teams produce resources over time.
  - One Crisis Mode scenario with interactive terminal-based choices and specialist deployment.
  - Pixel art style assets (placeholder acceptable) and one crisis music loop + SFX.
- The vertical slice should clearly communicate the hook: idle progression + adrenaline-filled crisis interaction.
- Assets and code should follow folder and naming conventions described below.

## High-level systems (contract-level overview)
- Clients / Contracts: incoming jobs with budget, risk, reward, and time window.
- Idle resource generation: revenue, reputation, experience, and "intel" or "mission tokens".
- Team & specialists: each specialist has stats, cooldowns, roles, and leveling.
- Upgrades & progression: spend earned currency and tokens on permanent upgrades and new staff.
- Crisis Mode: timed, layered attacks requiring decisions (deploy, quarantine, trace, deep-scan) and specialist assignment.
- Events & random attacks: background events that escalate into Crisis Mode when thresholds are met.
- Prestige / long-term meta: run the firm across multiple eras, unlocking "Legacy" bonuses.

## Core loop (player-facing)
1. Accept/auto-accept contracts from clients (idle).
2. Assign teams to contracts (idle allocations).
3. Generate passive resources (money, XP, reputation, mission tokens).
4. Random or scheduled Crisis Mode triggers require active play:
   - Enter terminal-style Crisis Mode.
   - Inspect logs, select actions, assign specialists (costs: CPU cycles, budget, cooldowns).
   - Successful resolution yields mission tokens or upgrade materials.
5. Spend tokens to hire/level specialists, buy upgrades, or expand operations.
6. Repeat, unlocking better contracts with higher stakes.

<!-- ## Crisis Mode (detailed)
- Presentation: full-screen neon overlay, scanlines, pulsing borders, terminal panels with logs.
- Inputs: keyboard or UI buttons to choose actions (Deploy / Quarantine / Trace / Patch / Divert).
- Time pressure: countdown timer visible; some choices are instant, others take time and specialist busy-duration.
- Specialist interactions: each specialist provides unique abilities (e.g., Threat Hunter = increases trace speed; PenTester = disables backdoors; SOC = stabilizes generation).
- Multi-stage threats: initial detection → escalation → full breach possibility if not handled.
- Rewards: mission tokens (rare), reputation boost, client-specific bonuses.
- Failure states: monetary loss, reputation hit, potential temporary reduction in passive generation. -->

## Specialists (roles & stats)
Each specialist has:
- Role (SOC, Threat Hunter, Incident Responder, PenTester, DevSecOps, Forensics, Social Engineer).
- Base stats: Efficiency, Speed, Trace Power, Defense, Cooldown.
- Special abilities (unique per role), e.g., SOC: "Stabilize" (reduce attack progression), Threat Hunter: "Deep Trace" (locate attacker faster).
- Growth model: XP → Levels → stat increases and unlocked abilities.
- Cooldown model: cooldown between Crisis deployments to prevent spamming.

## Economy & budget model
- Budget is central: each contract has a maximum budget and periodic income flow to the firm.
- Actions consume resources: CPU cycles (a consumable/time-limited resource), budget (money), and personnel hours.
- Idle income scales via upgrades, hired staff, and facilities.
- Contracts: small businesses → mid-market → enterprise → government; higher tiers = higher risk & reward.
- Financial constraints force trade-offs: accept lower-paying but safe jobs vs risky, high-reward work.

## Art direction — "neon hacker pixel vibe"
- Primary style: pixel art with retro, low-res characters and backgrounds.
- Resolution guidance:
  - Character sprites: 32×32 (standard), optionally 48×48 or 64×64 for boss/client portraits.
  - UI icons: 16×16 or 24×24.
  - Screen/backgrounds: art for target viewport (example 320×180 base; scale up for different resolutions).
- Palette (example neon cyberpunk):
  - Canvas / near-black: #0A0A0F
  - Neon cyan: #00FFD5
  - Neon green (terminal): #00FF66
  - Neon magenta: #FF00D2
  - Neon purple: #7A00FF
  - Accent amber/warning: #FFB84D
  - Muted UI gray: #2B2B35
- Animation rules:
  - Specialists: 3-frame idle animation, 4-frame working animation. Crisis animations faster (12–14fps).
  - Glow & rim lighting: separate glow layer recommended to animate pulsing neon without editing base sprite.
  - Effects: scanline overlay, subtle CRT flicker, occasional RGB split/glitch during escalation.

## Asset manifest & file organization
Suggested `assets/` layout (place under project root):
- `assets/sprites/characters/` — `specialist_soc_01_32x32.png`, `specialist_hunter_01_32x32.png` ...
- `assets/sprites/portraits/` — `client_nexus_64x64.png`
- `assets/sprites/ui/` — `button_primary_16x16.png`, `icon_deploy_16x16.png`
- `assets/sprites/terminal/` — `terminal_frame_320x180.png`, `ascii_logo_nexus.png`
- `assets/backgrounds/` — `hq_interior_320x180.png`, `neon_skyline_640x360.png`
- `assets/tiles/` — office floor tiles (16px)
- `assets/audio/music/` — `crisis_loop.ogg`, `idle_loop.ogg`
- `assets/audio/sfx/` — `alert_beep.ogg`, `typing_loop.ogg`, `success_sting.ogg`
- `assets/palettes/` — `palette_neon.json` (swatches)

Naming rules:
- Lowercase snake_case.
- Include role/type and size when helpful: `specialist_threat_hunter_32x32.png`.
- Sprite-sheets accept accompanying JSON metadata if used.

## UI & terminal specifics
- Two modes:
  - HQ UI (idle): pixel HUD showing Budget, Reputation, Revenue/sec, Active Teams, Contracts.
  - Crisis UI: terminal panels with log stream, options, countdown; specialist list with cooldowns and quick-deploy buttons.
- Terminal aesthetic: green monospace bitmap font for logs, amber for warnings, magenta for high-priority flags. Blinking cursor and ASCII logos for clients.
- Accessibility: colorblind-friendly indicator shapes next to colors; adjustable font size.

## Audio & music
- Layered music approach:
  - Idle loop: ambient synth with light beat (calm).
  - Crisis loop: urgent driving synth loop (builds tension; can layer extra percussion).
  - SFX: alert beeps for escalation (crescendo), typing loop for active specialists, success/failure stings.
- Formats: OGG preferred for LÖVE; keep loops short and low-latency.

## Technical notes (engine-neutral, LÖVE friendly)
- Keep art scalable: create at base resolution (320×180) and scale so UI and pixel art remain crisp.
- Use separate glow layers for neon so glow intensity can be adjusted at runtime.
- Sounds: stream longer music, pre-load short SFX as static.
- Save structure: JSON-based save with versioning and checksums (see `src/systems/save_system.lua`).
- Event-driven: use `utils/event_bus.lua` for decoupling Crisis Mode triggers.

## Progression roadmap — phases & milestones
Phase 1 — Foundation (MVP vertical slice)
- Implement idle HQ skeleton with basic resource generation (`resource_system.lua`).
- Implement simple team structure and specialist data.
- Wire a single contract type and one Crisis Mode event.
- Placeholder art: 3 specialists, 1 HQ background, terminal frame.
- Add crisis music loop + 3 SFX.

Phase 2 — Expand core gameplay
- More specialist types, leveling, and cooldowns.
- Multiple contract tiers and client variety.
- Threat escalation logic and multi-stage Crisis Mode.
- UI polish and terminal action flows.

Phase 3 — Polish & content
- Add audio layering, particle effects, RGB glitches, and animated neon skyline.
- Implement prestige/legacy system.
- Add more content: clients, events, achievements.

Phase 4 — Platform & release prep
- Cross-platform tests (desktop + mobile).
- Accessibility pass and localization.
- Build, package, and prepare release.

## Minimum deliverables for the vertical slice
- Game: idle HQ + one Crisis Mode scenario wired to an in-repo keypress (simulate crisis).
- Assets: placeholder pixel sprites for 3 specialists, 1 client portrait, 1 HQ background, terminal frame.
- Audio: one crisis loop + 3 SFX.
- Documentation: this instruction file committed to `.github/copilot-instructions/13-cyber-empire.instructions.md`.

## Acceptance criteria (how we verify)
- Entering Crisis Mode visually matches neon, scanline, and terminal layer description.
- Specialist deployments show cooldowns, consume resources, and impact crisis outcome.
- Rewards from Crisis Mode are used to unlock one upgrade or hire one specialist.
- Art direction uses the specified palette and sprite sizes, and placeholder assets are readable and evocative of the vibe.

## Artist/Producer checklist (for handing off)
- Provide PNG or sprite sheets with metadata (JSON/x,y,width,height).
- Supply palette swatch PNG + `palette_neon.json`.
- Provide a 4–8 second loop for crisis music (OGG) and SFX (OGG).
- Name assets using the convention above and place under `assets/` structure.
- Provide a short description for each specialist (role and ability) and a 1-line client summary for each contract.

## Suggested playtesting checklist (early testing)
- Simulate crisis via keypress; measure readability and reaction time.
- Test cooldown balance: can't spam a single specialist to trivialize crises.
- Verify consequences for both success and failure are clear and meaningful.
- Test audio layering transitions when crisis starts/stops.

## Next steps & options (pick one)
- A) Create the placeholder asset pack (palette swatch, 3 specialist sprites, terminal frame) and add to `assets/` (art-first).
- B) Produce a Crisis Mode design document (flowcharts for attack stages, specialist abilities, decision tree).
- C) Write a GDD vertical-slice spec (detailed numbers for budgets, cooldowns, reward amounts).
- D) I can scaffold the `Crisis Mode` behaviour in a new design-only file that maps to existing code modules (no code, just mapping).

If you want me to add this file to the repo, run the commands below (from the repo root) to create and commit it:

```bash
# from project root - create file and open for editing
cat > .github/copilot-instructions/13-cyber-empire.instructions.md <<'EOF'
# (paste the contents of this file here - or copy/paste from the editor)
EOF

git add .github/copilot-instructions/13-cyber-empire.instructions.md
git commit -m "docs(instructions): add cyber-empire design & art instructions"
git push origin main