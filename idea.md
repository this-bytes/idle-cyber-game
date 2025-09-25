# game_story_and_mechanics.md

## Project: Cyberspace Tycoon (Working Title)

### 1. Game Story & Narrative Context

**The Year is 2042:** The internet, once a vast open frontier, has coalesced into a series of massive, interconnected corporate and state-controlled networks. Data is the new oil, and whoever controls the most data, controls the world. Beneath the gleaming surface of digital commerce and communication lies a shadowy warzone, a constant battle for information, influence, and survival.

**You are a Cyberspace Architect:** A renegade programmer, weary of corporate overlords, or perhaps a fresh graduate with an ambitious vision. You've secured a small, dilapidated server farm in the deepest corners of the darknet – a forgotten node, ripe for renovation. Your goal: to build a dominant digital empire.

**The Stakes:** It's not just about accumulating numbers. Every server you bring online, every line of code you deploy, makes you a target. Rival corporations will try to infiltrate your network, rogue hacker collectives will attempt to siphon your data, and shadowy government agencies will probe your defenses. Your success depends not just on expansion, but on unyielding defense.

**The Vision:** Grow from a single click-farm to a sprawling, multi-layered digital fortress, humming with automated data pipelines, impenetrable firewalls, and advanced AI defenders. Become the ultimate "Cyberspace Tycoon."

---

### 2. Core Game Mechanics

#### A. Resources

* **Data Bits (DB):**
    * *Description:* The fundamental currency of your digital empire. Represents raw information, code, and digital assets.
    * *Generation:* Manual clicks, automated servers, advanced mining protocols.
    * *Usage:* Purchasing all upgrades, expanding infrastructure, developing defenses.

* **Processing Power (PP):**
    * *Description:* The computational muscle of your network. Drives the speed of data generation and defense protocols.
    * *Generation:* Processing Cores, advanced server arrays, quantum processors.
    * *Usage:* Multiplier for Data Bit generation. Later, might be consumed by advanced defensive actions or attacks.

* **Security Rating (SR):**
    * *Description:* An abstract metric representing the overall strength of your network's defenses.
    * *Generation:* Firewall upgrades, Anti-Virus software, AI defense systems, skilled SysOps.
    * *Usage:* Reduces the chance and severity of incoming threats. *Not a currency, but a critical stat.*

#### B. Generation & Upgrades

1.  **Manual Data Harvest (Clicker):**
    * Initial mechanic. A large button that grants `X` Data Bits per click.
    * Upgrades: "Improved Mouse Sensors," "Automated Clicker Bot (low level AI)" – increases DB/click.

2.  **Server Farm (Passive DB Generation):**
    * *Entry Level:* `Basic Server Rack` (Generates `Y` DB/sec).
    * *Upgrades:*
        * `Enhanced Server Clusters`: Increases DB/sec per server.
        * `Cloud Hosting Contracts`: Unlocks passive DB/sec based on outsourced resources.
        * `Quantum Data Silos`: High-tier generators.

3.  **Processing Cores (Passive PP Generation & DB Multiplier):**
    * *Entry Level:* `Single Core Processor` (Generates `Z` PP/sec, provides `1.1x` DB multiplier).
    * *Upgrades:*
        * `Multi-Threaded Arrays`: Increases PP/sec and multiplier.
        * `Dedicated GPU Miners`: Significant boost to PP/sec.
        * `Neural Net Processors`: Top-tier, massive PP/sec and multiplier.

#### C. Defense Mechanics

1.  **Threat System:**
    * *Nature:* Threats appear periodically, attempting to steal Data Bits or disrupt Processing Power.
    * *Types:*
        * `Basic Malware Injection`: Attempts to siphon small amounts of DB.
        * `DDoS Attack`: Temporarily reduces Processing Power.
        * `Data Breach Attempt`: Targets a percentage of your total DB.
        * `Ransomware`: Locks a portion of your DB until a "decryption fee" (more DB) is paid or threat is cleared.
    * *Difficulty:* Scales with your total DB and infrastructure value. Higher Security Rating reduces threat frequency and impact.

2.  **Defensive Infrastructure:**
    * **Firewalls:**
        * `Basic Packet Filter`: Reduces incoming threat chance by `X%`.
        * `Deep Packet Inspection Firewall`: Higher reduction, also slows down sophisticated threats.
        * `AI-Driven Adaptive Firewall`: Learns and adapts to new threat patterns.
    * **Anti-Virus/Malware Scanners:**
        * `Basic Signature Scanner`: Detects known threats, clears them over time.
        * `Heuristic Scanner`: Attempts to identify new, unknown malware by behavior.
        * `Proactive Threat Hunter AI`: Actively searches for and neutralizes threats before they fully materialize.
    * **Intrusion Detection Systems (IDS):**
        * `Network Anomaly Detector`: Alerts you to suspicious activity. Can be upgraded to automatically deploy countermeasures.
    * **Encryption Protocols:**
        * `Basic Data Encryption`: Reduces stolen DB by a percentage if a breach occurs.
        * `Quantum-Resistant Encryption`: Near-impenetrable data protection.

3.  **Player Interaction with Threats:**
    * When a threat appears, a small notification or visual indicator will appear.
    * Initially, the player might need to click a "Defend" button to activate defenses, consuming some PP or DB for a temporary boost to SR.
    * As defenses are upgraded, they will become more automated, reducing the need for constant manual intervention.

---

### 3. User Interface (UI) Goals

* **Clean and Functional:** Prioritize clear display of information and easy access to buttons.
* **Resource Display:** Prominently show current Data Bits, Data Bits/sec, Processing Power, and Security Rating.
* **Upgrade Panels:** Clear sections for purchasing servers, processors, and defensive upgrades.
* **Threat Indicator:** A visible, possibly flashing, alert when an attack is underway.
* **Minimalist Aesthetic:** Leaning into a "digital interface" feel, with stark colors, pixel fonts, and simple icons.

---

### 4. Git Workflow Integration (Reminder from `copilot-instructions.md`)

* **`main` branch:** Will hold the latest stable, playable version.
* **Feature branches:**
    * `feature/manual-data-harvest`
    * `feature/basic-server-farm`
    * `feature/processing-cores`
    * `feature/basic-firewall`
    * `feature/threat-system-v1`
* **Commit Messages:** Descriptive and atomic (e.g., "Add button for Manual Data Harvest," "Implement logic for Basic Server Rack generation").
