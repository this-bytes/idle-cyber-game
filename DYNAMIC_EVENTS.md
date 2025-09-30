# Dynamic Event System - User Guide

## Overview
The Dynamic Event System adds random narrative events to your SOC operations, creating an engaging and unpredictable gameplay experience. Events occur automatically every 25 seconds and can affect your resources, present strategic choices, or provide narrative flavor.

## Event Types

### 🟢 Positive Events
- **Effect**: Grant resources like money or reputation
- **Example**: "A grateful client sent a bonus for your team's excellent passive monitoring!"
- **Result**: Automatic +250 money

### 🔴 Negative Events  
- **Effect**: Cost resources or present challenges
- **Example**: "A server rack has overheated, requiring immediate replacement."
- **Result**: Automatic -75 money

### 🔵 Choice Events
- **Effect**: Present decisions with risk/reward outcomes
- **Example**: "A new, experimental security patch is available. Install it?"
- **Interaction**: Press number keys (1, 2, etc.) to select your choice
- **Outcomes**: Probabilistic results based on your decision

### ⚪ Neutral Events
- **Effect**: Provide narrative flavor without direct resource impact
- **Example**: "Industry conference highlights new trends in threat intelligence."
- **Result**: Team morale and story immersion

## How to Interact

### Simple Events (Positive/Negative/Neutral)
- These events appear as pop-ups at the bottom of your screen
- They display for 5 seconds and auto-dismiss
- Resource changes are applied automatically
- No interaction required

### Choice Events  
1. **Event Appears**: A blue-bordered panel shows the situation and available choices
2. **Review Options**: Read the description and available choices
3. **Make Decision**: Press the number key (1, 2, etc.) corresponding to your choice
4. **See Results**: Probabilistic outcomes are calculated and applied

## Event Panel Guide

### Visual Indicators
- **Green Border**: Positive event (beneficial)
- **Red Border**: Negative event (costly) 
- **Blue Border**: Choice event (decision required)
- **Gray Border**: Neutral event (informational)

### Information Displayed
- Event type indicator (● POSITIVE, ● NEGATIVE, etc.)
- Event description explaining the situation
- For choice events: numbered options with descriptions
- Timer showing auto-close countdown (for simple events)
- Instruction text for choice events

## Strategic Considerations

### Choice Event Example: Security Patch
**Situation**: "A new, experimental security patch is available. Install it?"

**Option 1: Install the patch**
- 70% chance: +500 money, +1 reputation (successful implementation)
- 30% chance: -200 money, -1 reputation (system instability)

**Option 2: Wait for stable release**  
- No immediate effect (safe but no potential benefit)

### Tips
- Choice events often involve risk vs. reward decisions
- Consider your current resource levels before taking risks
- Positive events help build reserves for handling negative events
- Some events may become more frequent or severe as you progress

## Technical Details
- Events trigger automatically every 25 seconds during gameplay
- Choice events pause the auto-trigger until resolved
- All events are defined in `src/data/events.json` for easy modding
- Resource changes are processed through the ResourceManager
- Event probability outcomes use proper random distribution

## Troubleshooting
- **Events not appearing**: Check that the EventSystem is loaded in the game
- **Choices not working**: Ensure you're pressing number keys (1, 2, 3)
- **No resource changes**: Verify ResourceManager is properly integrated
- **Events too frequent/rare**: Adjust `eventInterval` in EventSystem (default: 25 seconds)

The Dynamic Event System adds strategic depth and narrative richness to your idle cybersecurity management experience!