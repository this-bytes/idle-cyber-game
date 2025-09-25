# UI Design — Cyber Empire Command

Design Goals
- Clear, readable HUD that shows Budget, Reputation, Revenue/sec, Active Teams, and pending Contracts.
- Strong visual contrast during Crisis Mode: neon terminal overlay with readable logs and action buttons.
- Pixel-perfect assets and consistent spacing for a retro-pixel feel.

HUD (Idle)
- Top bar: Budget, Income/sec, Reputation.
- Left/Right panels: Contracts and Facility/Upgrade quick panels.
- Bottom bar: Specialist roster with level, cooldown, and quick-deploy buttons.

Crisis UI
- Full-screen neon overlay with terminal panels (logs, suggested actions, countdown).
- Specialist panel with animated avatars, busy indicator, and ability buttons.
- Large countdown timer and clear cost/cooldown readouts for each action.
- Use mono bitmap font for logs; use colored text (green/amber/magenta) for severity levels.

Art & Pixel rules
- Base viewport reference: 320×180. Use integer scaling for crisp pixels.
- Sprite sizes: character 32×32, portraits 64×64, icons 16×16/24×24.
- Keep UI elements modular and data-driven so artists/developers can swap themes.

Accessibility & Interaction
- Keyboard shortcuts for core actions (deploy, quarantine, patch).
- Touch-friendly button sizes and layout for mobile builds.
- High-contrast toggle and reduced-motion options.

Deliverables
- UI mockups for HQ and Crisis Mode.
- Sprite/UI asset spec describing sizes, anchor points, and layer order.
