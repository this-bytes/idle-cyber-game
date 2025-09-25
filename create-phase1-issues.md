# Phase 1 Issues Creation Guide

This document provides the exact GitHub issues that need to be created for Phase 1 development of the Cyberspace Tycoon idle game.

## Issues Overview

The following 8 issues need to be created in the repository in the specified order (due to dependencies):

1. **Core UI Framework** - Foundation system (no dependencies)
2. **Game Loop Foundation** - Foundation system (no dependencies)
3. **Resource Display System** - Depends on Core UI Framework
4. **Manual Data Harvest** - Depends on UI Framework, Game Loop
5. **Simple Upgrade System** - Depends on UI Framework, Game Loop
6. **Basic Server Farm Infrastructure** - Depends on Upgrade System, Resource Display
7. **Processing Cores System** - Depends on Server Farm, Resource Display
8. **Basic Firewall/Threat System** - Depends on Processing Cores, Resource Display

## Labels to Create First

Before creating issues, ensure these labels exist in the repository:
- `enhancement`
- `phase-1`
- `ui`
- `foundation`
- `priority-high`
- `priority-medium`
- `core`
- `mechanics`
- `clicking`
- `resources`
- `upgrades`
- `automation`
- `multipliers`
- `defense`
- `threats`

## Milestone to Create

Create a milestone called "Phase 1 - Foundation" with description:
"Core gameplay mechanics and foundation systems for the idle cybersecurity game. Includes basic resource generation, clicking mechanics, upgrades, and simple threat system."

## Detailed Issue Content

See the `phase1-issues` file for complete issue descriptions with:
- Full titles and descriptions
- Acceptance criteria checklists
- Technical requirements
- Implementation notes
- Files to create/modify
- Testing checklists
- Definition of done criteria

## GitHub CLI Commands (if using CLI)

```bash
# Create milestone
gh milestone create "Phase 1 - Foundation" --description "Core gameplay mechanics and foundation systems"

# Create labels
gh label create "phase-1" --color "0052cc" --description "Phase 1 development tasks"
gh label create "foundation" --color "5319e7" --description "Foundation systems that other features depend on"
gh label create "priority-high" --color "d73a4a" --description "High priority issue"
gh label create "priority-medium" --color "fbca04" --description "Medium priority issue"

# Create issues (use content from phase1-issues file)
gh issue create --title "[PHASE 1] Core UI Framework - Basic Game Interface" --body-file issue1-body.txt --label "enhancement,phase-1,ui,foundation,priority-high" --milestone "Phase 1 - Foundation"
# ... repeat for all 8 issues
```

## Branch Creation Strategy

Each issue should have a corresponding feature branch:
- `feature/core-ui`
- `feature/game-loop`
- `feature/resource-display`
- `feature/manual-data-harvest`
- `feature/simple-upgrades`
- `feature/basic-server-farm`
- `feature/processing-cores`
- `feature/basic-firewall`

## Development Order

Follow the dependency order when assigning and working on issues:

**Week 1 (Foundation):**
1. Core UI Framework
2. Game Loop Foundation  
3. Resource Display System

**Week 2 (Core Mechanics):**
4. Manual Data Harvest
5. Simple Upgrade System

**Week 3 (Automation & Defense):**
6. Basic Server Farm Infrastructure
7. Processing Cores System
8. Basic Firewall/Threat System

This order ensures that each issue can be completed without waiting for dependencies.