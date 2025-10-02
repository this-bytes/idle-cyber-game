# Balancing & Mathematical Framework — Idle Sec Ops

Purpose
Provide balancing formulas, constants, and testing guidance so designers can tune progression and keep Incident Mode relevant.

Core Concepts
- Growth factors: use configurable multipliers for upgrade costs and income scaling (data-driven).
- Diminishing returns: apply soft caps to passive boosts so active Incident rewards remain valuable.
- Threat scaling: threat frequency and severity scale with company net worth and contracts.

Example formulas (data-driven)
- UpgradeCost = BaseCost * (GrowthFactor ^ Count)
- PassiveIncome/sec = Σ(contract_base × assigned_efficiency) × (1 + facility_bonus)
- ThreatLevel = (NetWorth ^ 0.75) × ZoneModifier × RandomVariance

Active Mode calculations
- AttackProgressRate = BaseRate × (ThreatSeverity / DefenseRating) × AdaptationFactor
- SpecialistEffectiveness = BaseSkill × (1 + Level * 0.05) × (role_multiplier)
- Cooldown scaling: Cooldown = BaseCooldown × (1 - skill_reduction_percent)

Balance testing
- Simulation harness: run thousands of simulated days with randomized contract mix to detect runaway growth.
- Edge case tests: simulate no-player-interaction (pure idle) vs high-activity players (frequent Incident engagements).
- Target pacing: first prestige available within targeted timeframe (e.g., 1–2 weeks of active play for committed players).

Data & Config
- Keep constants in a single balancing config file to permit live tuning.
- Provide a data export tool for analytics (CSV / JSON) to feed iterative balance passes.

Deliverables
- Starter constant file with base values for the vertical slice (costs, growth factors, cooldowns).
- A small simulation script (or guidance for one) to run progression tests locally.
