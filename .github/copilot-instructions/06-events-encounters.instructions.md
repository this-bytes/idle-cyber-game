# Events & Encounters — Cyber Empire Command

Purpose
Define the event system that creates variety and feeds Crisis Mode. Events are the engine of emergent stories and provide hooks for rewards, reputation shifts, and contract variety.

Event Types
- Random Timed Events: Market crash, patch-release rush, regulator audit.
- Contract Events: client-specific incidents (e.g., data leak at a FinTech startup).
- Global Events: faction wars, seasonal megathreats that affect multiple clients.
- Positive Encounters: defector scientist, data cache discovery — yield bonuses.

Structure of an Event
- ID, name, description, type, frequency, rarity.
- Requirements/Triggers: client-tier, reputation minimum, or time-locked.
- Choices: multiple-choice resolutions (auto-resolve possible) with costs and consequences.
- Rewards and penalties: money, reputation, mission tokens, or negative effects.

Event Flow Integration
- Events run through event bus and are displayed in HQ UI.
- If severity escalates beyond a threshold, the event triggers Crisis Mode.
- Events should be authored as data so designers can add content quickly.

Playtesting & Balancing
- Early playtests should check event frequency and escalation balance to ensure crises remain exciting but not constant.
- Ensure events scale with company progression and do not trivialize idle growth.

Deliverables
- 10 starter events (mix of positive/neutral/negative).
- 5 crisis templates for immediate Crisis Mode conversion.
