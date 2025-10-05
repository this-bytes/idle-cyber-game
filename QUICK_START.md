# 🎮 Quick Start Guide - Idle Cyber Game (First Release)

## 🚀 Launch the Game

```bash
cd /home/localadmin/code/idle-cyber-game
love .
```

Or on Windows:
```bash
"C:\Program Files\LOVE\love.exe" .
```

---

## 🎯 Your First 5 Minutes

### 1. **Main Menu**
- Click **"NEW OPERATION"** to start a fresh game
- Or click **"LOAD OPERATION"** to continue your save

### 2. **SOC Command Center** (Main Dashboard)
You'll see three information panels:

**Left Panel - Active Contracts:**
- Shows contracts you've accepted
- Progress bars update in real-time
- Each contract generates passive income

**Middle Panel - Active Threats:**
- Security threats that appear automatically
- Each has a timer - they must be resolved before time runs out
- Threats currently auto-resolve (manual response coming soon)

**Right Panel - Team Status:**
- Your hired specialists
- Their levels and readiness status

**Top Bar:**
- 💰 Money (your main resource)
- 🌟 Reputation (unlocks better contracts)
- 📈 Income Rate (how much you're earning per second)

### 3. **Accept Your First Contracts**
- Click the **"📋 Contracts"** button
- Right panel shows available contracts
- Click **"ACCEPT"** on a contract
- Left panel now shows it actively earning money
- Navigate back with **"< BACK"** or press **ESC**

### 4. **Hire Your First Specialist**
- Click the **"👥 Specialists"** button
- Right panel shows available specialists for hire
- Each specialist boosts your effectiveness
- Click **"HIRE"** when you have enough money
- Specialists level up automatically from completed work

### 5. **Buy Upgrades**
- Click the **"⬆️ Upgrades"** button
- Browse permanent upgrades organized by category
- Upgrades boost income, efficiency, threat resistance, etc.
- Click **"PURCHASE"** when you can afford one

---

## 📊 Understanding the Gameplay Loop

```
Accept Contracts → Earn Money → Hire Specialists → Buy Upgrades
         ↑                                                    ↓
         ←───────────── Grow Stronger ←──────────────────────┘
```

### Core Mechanics:

1. **Contracts** = Your income source
   - Generate money passively over time
   - Complete automatically when their timer runs out
   - Earn reputation when completed

2. **Threats** = The challenge
   - Appear every 15-25 seconds automatically
   - Reduce your income if not handled
   - Specialists help resolve threats faster

3. **Specialists** = Your team
   - Boost efficiency, speed, and defense
   - Gain XP from completed contracts
   - Level up to become more effective

4. **Upgrades** = Permanent progression
   - One-time purchases with lasting effects
   - Stack multiplicatively for exponential growth
   - Strategic choices matter

5. **Offline Progress** = True idle gameplay
   - Game calculates earnings while you're away
   - You'll see a summary when you return
   - Threats also occur offline (but are handled automatically)

---

## 🔔 Notifications

Watch for toast notifications at the top of the screen:

- **🚨 Threat Detected** - A new security threat has appeared
- **✅ Threat Resolved** - Successfully handled a threat
- **📋 Contract Accepted** - You've taken on new work
- **✅ Contract Completed** - Finished a contract, earned reputation
- **👥 New Specialist Hired** - Team member added
- **⭐ Specialist Leveled Up** - Your team is getting stronger
- **🏆 Achievement Unlocked** - You've hit a milestone
- **💤 Welcome Back** - Shows offline earnings when you return

---

## ⌨️ Keyboard Controls

- **ESC** - Return to previous scene / Main Menu
- **F3** - Toggle debug overlay (shows detailed game state)
- **Mouse Click** - Interact with buttons and UI elements

---

## 🎯 First Session Goals

Try to accomplish these in your first playthrough:

- [ ] Accept at least 3 contracts
- [ ] Hire your first specialist
- [ ] Purchase your first upgrade
- [ ] Earn $10,000
- [ ] Reach 50 reputation
- [ ] Witness a threat appear and resolve
- [ ] Let the game run idle for a minute, see passive income grow
- [ ] Press F3 to explore the debug stats
- [ ] Close the game and reopen it - see your save loaded

---

## 🐛 Troubleshooting

### Game won't start?
- Make sure you have LÖVE 11.4+ installed
- Check console for error messages
- Verify you're in the correct directory

### No contracts appearing?
- Contracts generate every ~10 seconds
- Check the Contracts Board scene
- Press F3 to see contract generation status

### No threats appearing?
- Threats generate every 15-25 seconds
- Watch the middle panel on SOC View
- Press F3 to verify ThreatSystem is running

### Income not increasing?
- You must have ACTIVE contracts (check left panel of SOC View)
- Income appears in small increments every 0.1 seconds
- Press F3 to see current income rate

### Save not loading?
- Saves are automatic every 60 seconds
- Save file location: `<LÖVE save directory>/idle-cyber-game/savegame.json`
- Manual save on exit (Quit button or closing window)

---

## 📈 Tips for Progression

1. **Early Game**: Focus on accepting as many contracts as possible
2. **First Purchase**: Hire a specialist before buying upgrades
3. **Balance**: Don't spend all your money - keep a reserve
4. **Reputation Matters**: Higher reputation unlocks better contracts
5. **Let it Idle**: The game is designed to progress while you're away
6. **Check Threats**: They appear regularly - don't ignore them
7. **F3 is Your Friend**: Use debug overlay to understand systems
8. **Explore**: Click through all scenes to see what's available

---

## 🎮 Controls Summary

| Action | Control |
|--------|---------|
| Navigate Menu | Mouse Click |
| Select/Confirm | Left Click |
| Go Back | ESC or "< BACK" button |
| Debug Overlay | F3 |
| Quit Game | ESC to Main Menu → "TERMINATE" |

---

## 🚀 Have Fun!

This is an **idle/incremental game** - it's designed to be relaxing, rewarding, and satisfying. Don't stress about optimal play in your first session. Experiment, explore, and enjoy watching your SOC operation grow!

The game runs in real-time and continues progressing even when closed. The longer you play (and the more you idle), the faster everything becomes.

**Welcome to your SOC Command Center, Commander! 🛡️**
