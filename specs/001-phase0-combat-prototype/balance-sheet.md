# Ascent Vector — Phase 0 Balance Sheet

**Version:** 0.3 — Updated with all Phase 0 balance decisions  
**Last Updated:** April 2026  
**Purpose:** Provide concrete numbers to implement and playtest. All values are starting estimates — expect heavy iteration.

---

## Design Intent (Read This First)

The entire balance rests on one tension: **Ground Mode is free but dangerous. Air Mode is safe but expensive.**

- Melee should be the most energy-efficient way to kill Grunts.
- The Machine Gun should feel wasteful against Grunts but necessary against Drones.
- Energy should constantly feel like it's running out — the player should *want* to stay in the air but *can't afford to*.
- The floor destruction system should gradually shrink the safe ground, pressuring the player into harder choices.

---

## 1. P.R.O.X.Y. — Player Stats

| Stat | Value | Notes |
|---|---|---|
| Max Health | 100 | |
| Max Energy | 100 | |
| Ground Move Speed | 4.0 units/sec | Feels deliberate, not sluggish |
| Air Move Speed | 7.0 units/sec | Noticeably faster — reward for spending energy |
| Hover Height Cap | 3.0 units | High enough to clear pits, low enough to feel close to the action |

---

## 2. Energy Economy

This is the most important table in the document. If these numbers are wrong, nothing else matters.

| Action | Energy Cost | Notes |
|---|---|---|
| Hovering (Jetpack) | 10 / sec | Full energy = ~10 sec of flight max |
| Machine Gun (per shot) | 2 / shot | At 6 shots/sec, that's 12/sec on top of hover |
| Spin Attack (per use) | 20 flat | ~5 uses on a full bar |
| Energy Plug Recharge | +25 / sec | ~4 sec for full recharge from empty |
| Passive Regen | 0 | No free energy — forces plug usage and loot pickups |

### Key Ratios to Validate During Playtesting

| Scenario | Cost | Time |
|---|---|---|
| Hover only (no shooting) | 10/sec | ~10 sec until empty |
| Hover + shoot continuously | 22/sec | ~4.5 sec until empty |
| Kill one Drone while hovering | ~37 energy | ~1.7 sec |
| Kill one Grunt with gun (wasteful) | ~59 energy | ~2.7 sec |
| Full recharge at Energy Plug | 0 (time cost) | ~4 sec immobilized |

**The Feeling You're Targeting:** The player lifts off, takes out a Drone, maybe sprays a few Grunts, then *has* to land because energy is draining fast. That pressure is the core loop.

---

## 3. Weapons — Damage Table

| Weapon | Damage | Fire Rate | DPS | Energy Cost | Knockback |
|---|---|---|---|---|---|
| Heavy Slam (X) | 40 | ~0.8 sec cooldown | ~50 | Free | 2.5 tiles |
| Spin Attack (O) | 25 (AoE) | ~0.6 sec animation | ~42 | 20 per use | 1.5 tiles |
| Machine Gun (R2) | 5 per bullet | 6 shots/sec | 30 | 2 per shot | 0.1 tiles per hit |

### Hits to Kill

| Weapon vs Target | Hits Needed | Notes |
|---|---|---|
| Slam → Grunt | 2 hits | Clean, efficient, no energy spent |
| Spin → Grunt | 4 hits (80 energy) | Less efficient but hits everything around you |
| Gun → Grunt | ~16 shots (~2.7 sec) | Expensive — use melee instead |
| Gun → Drone | ~10 shots (~1.7 sec) | The intended use — Drones are gun-only targets |
| Slam → Drone | Immune | Cannot hit airborne enemies with melee |

---

## 4. Enemy Stats

### Type A — "The Grunt" (Ground Melee)

| Stat | Value | Notes |
|---|---|---|
| Health | 80 | |
| Move Speed | 3.5 units/sec | Slightly slower than P.R.O.X.Y. on ground — catchable but not trivial |
| Attack Damage | 15 | ~7 hits to kill the player from full HP |
| Attack Cooldown | 1.2 sec | |
| Attack Range | 1.5 units | Must be adjacent |
| Mass | 1.0 | Baseline for knockback calculations |
| Pit Avoidance | Yes | Paths around broken tiles — won't walk into holes on its own |
| Can Be Knocked Into Pits | Yes | Instant kill — this is a key player strategy |

### Type B — "The Drone" (Air Ranged)

| Stat | Value | Notes |
|---|---|---|
| Health | 50 | Fragile — but hard to hit |
| Move Speed | 6.0 units/sec | Very fast, kites away from player |
| Projectile Damage | 8 | Less per hit than Grunt, but constant chip damage |
| Fire Rate | 1 shot / 1.5 sec | |
| Projectile Speed | 10 units/sec | Dodgeable if you're moving |
| Preferred Range | 6–8 units | Tries to stay far away |
| Min Range (flee trigger) | 4 units | If player gets closer, Drone repositions |
| Mass | 0.3 | Light — Gun knockback nudges it slowly |
| Immune to Melee | Yes | Can only be damaged by Machine Gun |
| Flies Over Pits | Yes | Ignores floor destruction |

### Drone Kiting Behaviour (Clarification)

The Drone should pick a position that is:
1. Within its preferred range (6–8 units) from P.R.O.X.Y.
2. Not against a wall (if cornered, it slides along the wall to escape).
3. If multiple Drones exist, they should loosely spread out — not stack on the same spot.

If P.R.O.X.Y. enters Air Mode and chases a Drone, the Drone should flee faster since its speed (6.0) is close to P.R.O.X.Y.'s air speed (7.0). This creates a tense pursuit that burns energy.

---

## 5. Room & Grid

| Parameter | Value | Notes |
|---|---|---|
| Grid Size | 10 × 10 tiles | 100 total tiles |
| Tile Size | 2 × 2 units | Room = 20 × 20 unit playable area |
| Wall Height | 4 units | Taller than hover cap — no escaping |
| Tile HP | 2 | 1 Slam = cracked / 2 Slams = destroyed |
| Spin Attack tile damage | 0 | Spin does NOT break tiles — only Slam does |
| Machine Gun tile damage | 0 | Gun does NOT break tiles — only Slam does |

### Floor Destruction Pacing

At 100 tiles, only Slam attacks degrade the floor — one tile per 2 hits. Since Spin and Machine Gun do not damage tiles, floor destruction is entirely under the player's deliberate control. The floor degrades more slowly and predictably than if all attacks damaged tiles.

**Suggested Watch Metric:** If more than 40% of tiles are destroyed before the room is cleared, spawn counts may need adjusting.

---

## 6. Knockback & Physics

| Parameter | Value |
|---|---|
| Grunt Mass | 1.0 |
| Drone Mass | 0.3 |
| P.R.O.X.Y. Mass | 1.5 |
| Slam Knockback Force | 2.5 tiles of displacement on a mass-1.0 target |
| Spin Knockback Force | 1.5 tiles |
| Gun Knockback Force | 0.1 tiles per hit |
| Grunt Attack Knockback on Player | 0.5 tiles |
| Player Knockback Cooldown | 0.3 sec | 

### Critical Ruling: Can P.R.O.X.Y. Be Knocked Into Pits?

**Yes.** Grunt melee attacks apply 0.5 tiles of knockback to the player. If P.R.O.X.Y. is standing next to a pit and gets hit, it can be pushed in. This makes floor destruction a double-edged sword — exactly as intended.

### Simultaneous Knockback

If multiple Grunts hit P.R.O.X.Y. at the same time, only one knockback applies. After being knocked back, there is a 0.3 sec cooldown where no further knockback can occur. The player still takes damage from all hits, but cannot be chain-pushed across the room into a pit.

---

## 7. Energy Plug

| Parameter | Value | Notes |
|---|---|---|
| Recharge Rate | +25 energy/sec | ~4 sec from empty to full |
| Immobilizes Player | Yes | Cannot move, attack, or hover while plugged in |
| Can Take Damage While Plugged | Yes | High risk — enemies will swarm you |
| Can Cancel Early | Yes | Tap any input to unplug instantly — you keep whatever energy you recharged |
| Minimum Lock-In | 0.5 sec | Tiny commitment so it doesn't feel laggy |
| Visual/Audio Cue | Bright charging beam + audio hum | Should be obvious to attract enemy aggro |
| Plug Count Per Room | 1 | Wall-mounted, fixed position |

**The Feeling:** Using the Plug should feel like a desperate pit stop — you dash to the wall, plug in, watch the Grunts closing in, and rip out at the last second with just enough energy to lift off.

---

## 8. Loot & Pickups

| Drop Type | Restore Amount | Notes |
|---|---|---|
| Health Orb | +15 HP | |
| Energy Orb | +20 Energy | Slightly more valuable since energy is the core resource |
| Drop Chance on Kill | 100% | Every enemy drops something — one Health OR one Energy orb (50/50) |
| Pickup Range | 1.5 units | Contact-based with a small magnet radius |
| Pickup Works in Air Mode | **No** | Must be in Ground Mode to collect — forces the player to land |
| Loot Drop Location | Floor below enemy | All loot falls straight down to the tile beneath where the enemy died |
| Grunt Pit Kill Loot | Lost forever | Enemy falls in, loot falls in — risk/reward for environmental kills |
| Drone Killed Over Pit | Lost forever | Loot drops through the hole — choose *where* you kill Drones carefully |
| Drone Killed Over Solid Ground | Lands on tile | Orb sits on the tile below the Drone's position at death |

### Loot Philosophy

Environmental pit kills are instant and free, but you lose the drop. Melee kills are efficient and give you loot, but cost time and risk. Gun kills cost energy but give loot. Air Mode lets you fight safely, but you must land to collect rewards — and Drone kills over pits waste the drop entirely. This creates a constant trade-off triangle that reinforces the Ground/Air tension.

---

## 9. Spawn & Wave Logic (Phase 0)

| Parameter | Value | Notes |
|---|---|---|
| Mode | Wave-based sandbox | No win state for Phase 0 — endless waves for testing |
| Wave 1 | 4 Grunts | Pure melee — learn ground combat |
| Wave 2 | 3 Grunts + 1 Drone | Introduces Air Mode necessity |
| Wave 3 | 2 Grunts + 2 Drones | Mixed pressure |
| Wave 4+ | +1 enemy per wave, alternating type | Escalates until player dies |
| Spawn Delay Between Waves | 3 sec | Brief breathing room |
| Spawn Location | Room edges, away from player | Min 8 units from P.R.O.X.Y. |
| Max Enemies Alive | 8 | Performance + readability cap |

**Phase 0 Goal:** There is no "win." The prototype is an endless combat sandbox. The implicit goal is to survive as long as possible. This gives you maximum playtesting data on the balance.

---

## 10. Fall Penalty

| Parameter | Value | Notes |
|---|---|---|
| Damage on Fall | 50% of **Max** HP (= 50 damage) | Not 50% of current HP — always hurts the same |
| Respawn Location | Nearest solid tile to room center | Deterministic — avoids edge cases with equidistant tiles |
| Invincibility After Respawn | 1.5 sec | Brief window so you don't fall and instantly die to a Grunt |
| Energy After Respawn | Unchanged | You keep whatever energy you had — falling is an HP punishment, not energy |

> **Phase 1 Note:** This respawn system is Phase 0 only. In Phase 1, falling through the floor will drop P.R.O.X.Y. to the previous floor below. The player will need to take the elevator back up, with all enemies on the current floor reset. This replaces the HP damage + respawn mechanic entirely.

---

## 11. Tuning Checklist (For Playtesting)

Use this list to track what feels right and what doesn't during playtesting sessions:

- [ ] Does Ground Mode feel deliberately slow without being frustrating?
- [ ] Does Air Mode feel fast and powerful but unsustainably expensive?
- [ ] Is the Slam the clearly best option for Grunts? (It should be)
- [ ] Do Drones feel threatening but killable in a short burst?
- [ ] Does the floor degrade at a good pace — not too fast, not ignorable?
- [ ] Does knocking a Grunt into a pit feel satisfying even though you lose the loot?
- [ ] Is the Energy Plug scary to use but necessary?
- [ ] Does having to land to collect loot create good tension after air combat?
- [ ] Do players think about *where* they kill Drones to avoid losing loot over pits?
- [ ] Does getting knocked into your own pits feel fair or frustrating?
- [ ] Does a typical run last 3–5 minutes before the player is overwhelmed?
- [ ] Do you ever run out of safe floor tiles before you run out of HP?

---

*This is a living document. Update values after every playtest session and note what changed and why.*
