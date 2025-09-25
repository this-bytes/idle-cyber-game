# Defense & Threat Systems — Cyber Empire Command

Purpose
Define the threat taxonomy, escalation mechanics, and how threats interact with idle and Crisis Mode gameplay.

Threat Tiers
- Tier 1: Script Kiddies, Basic Malware — low damage, frequent.
- Tier 2: Ransomware, Targeted Phishing, DDoS — medium impact, needs specialist coordination.
- Tier 3: APTs, Supply Chain, Zero-Day Chains — high-impact, multi-stage, Crisis Mode material.

Threat Properties
- Vector: technical path (network, app, supply chain, social).
- Severity: determines resources required to respond and possible losses.
- Detection Time & Escalation: time windows before escalation; Crisis Mode begins when escalation threshold or contract conditions are met.

Crisis Triggering
- Random or rule-based events during contracts: repeated low-level events, critical detection thresholds, or time-based scheduled audits.
- Each crisis has metadata: duration, stages, initial detection feed, client-specific modifiers.

Defense Mechanics
- Passive: facility upgrades, auto-defence scripts, subscription intelligence reduce chance/severity of events.
- Active: Crisis Mode actions—Deploy, Trace, Quarantine, Patch, Divert — mapped to specialist abilities.
- Adaptive learning: repeated use of same countermeasure reduces its efficiency (attackers adapt), encouraging varied play.

Outcome System
- Success: mission tokens, reputation, client retention bonus.
- Partial success: reduced reward, reputation diminishes slightly, possible temporary penalties (reduced income).
- Failure: major budget loss, contract termination, reputation hit.

Implementation notes
- Model threats as data-driven sequences so new threats or stages can be authored without code changes.
- Use event bus to broadcast threat state changes to UI, audio, and progression systems.
