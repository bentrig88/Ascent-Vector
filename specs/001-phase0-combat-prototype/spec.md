# Feature Specification: Ascent Vector — Phase 0 Combat Prototype

**Feature Branch**: `001-phase0-combat-prototype`  
**Created**: 2026-04-05  
**Status**: Draft  
**Input**: GDD v0.3 + Phase 0 Balance Sheet v0.3

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Ground/Air State Switching (Priority: P1)

A player controls P.R.O.X.Y. in a single enclosed room and switches between two distinct combat states — ground melee and airborne ranged — by holding and releasing the jetpack input. Each state feels immediately different in speed, capability, and resource cost. The player must constantly weigh the cost of staying airborne against the danger of staying on the ground.

**Why this priority**: This is the single defining mechanic of the game. Every other system exists to create tension around this choice. Without a working, feel-differentiated state switch, nothing else can be tested meaningfully.

**Independent Test**: Can be tested with no enemies in the room — the player simply activates and deactivates Air Mode, observing speed change, hover height cap, energy drain, and forced landing when energy hits zero.

**Acceptance Scenarios**:

1. **Given** P.R.O.X.Y. is in Ground Mode, **When** the player holds the jetpack input, **Then** P.R.O.X.Y. lifts off smoothly to a maximum height of 3 units, movement speed increases from 4.0 to 7.0 units/sec, and energy begins draining at 10 per second.
2. **Given** P.R.O.X.Y. is in Air Mode, **When** the player releases the jetpack input, **Then** P.R.O.X.Y. begins descending while the player retains full horizontal movement control; if P.R.O.X.Y. is over solid ground at touchdown it lands and reverts to Ground Mode (no invincibility frames); if it is over a pit at touchdown the fall sequence triggers.
3. **Given** P.R.O.X.Y. is hovering over solid ground with energy at 1, **When** energy reaches zero, **Then** P.R.O.X.Y. is forced to land (no fall penalty).
4. **Given** P.R.O.X.Y. is hovering over a pit with energy at 1, **When** energy reaches zero, **Then** the fall sequence triggers (50 damage, respawn at nearest solid tile to room center).

---

### User Story 2 - Combat & Energy Economy Loop (Priority: P1)

A player engages a wave of enemies using all three attacks (Heavy Slam, Spin Attack, Machine Gun) and the Energy Plug recharge station. The player feels constant pressure to make efficient resource decisions: melee is free but dangerous, air combat is safe but expensive, and the Plug is necessary but risky.

**Why this priority**: Equal priority to state switching because the energy loop *is* the game loop. Without working weapons, energy costs, and the Plug, the core tension cannot exist.

**Independent Test**: Can be tested with a single wave of 4 Grunts — verify Slam kills in 2 hits, Spin hits AoE targets, Machine Gun costs energy, and the Energy Plug recharges at the expected rate while immobilizing the player.

**Acceptance Scenarios**:

1. **Given** P.R.O.X.Y. is in Ground Mode adjacent to a Grunt, **When** the player uses Heavy Slam twice, **Then** the Grunt is destroyed and no energy is consumed.
2. **Given** P.R.O.X.Y. is in Ground Mode surrounded by multiple enemies, **When** the player uses Spin Attack, **Then** all enemies within range take 25 damage, P.R.O.X.Y. loses 20 energy, and no floor tiles are damaged.
3. **Given** P.R.O.X.Y. is in Air Mode targeting a Drone, **When** the player fires the Machine Gun for approximately 1.7 seconds (10 shots), **Then** the Drone is destroyed and roughly 37 total energy has been consumed (hover + shots combined).
4. **Given** P.R.O.X.Y. has less than 100 energy and approaches the Energy Plug, **When** the player activates the Plug, **Then** P.R.O.X.Y. is immobilized, energy increases at 25 per second, and tapping any input after the 0.5-second lock-in cancels the recharge while keeping the energy gained.
5. **Given** P.R.O.X.Y. has full energy (100), **When** the player attempts to use the Energy Plug, **Then** nothing happens and no lock-in occurs.

---

### User Story 3 - Floor Destruction & Environmental Kills (Priority: P2)

A player strategically uses the Heavy Slam to crack and destroy floor tiles, creating pits that serve as both a hazard and a weapon. The player can knock Grunts into pits for instant kills (losing the loot drop), or be knocked into their own pits by Grunt attacks.

**Why this priority**: Floor destruction is the escalating pressure system that makes the prototype finite and dangerous over time. It must work correctly before wave testing is meaningful.

**Independent Test**: Can be tested in isolation by repeatedly Slamming tiles to confirm crack → destroy progression, then knocking an enemy into a pit to confirm instant kill and loot loss.

**Acceptance Scenarios**:

1. **Given** a full-health floor tile, **When** P.R.O.X.Y. uses Heavy Slam on it once, **Then** the tile visually cracks but remains walkable.
2. **Given** a cracked floor tile, **When** P.R.O.X.Y. uses Heavy Slam on it again, **Then** the tile is destroyed, a pit is created, and the tile is no longer walkable.
3. **Given** a Grunt is standing adjacent to a pit, **When** P.R.O.X.Y. Slams the Grunt with enough knockback to push it over the edge, **Then** the Grunt is instantly destroyed and no loot orb is spawned.
4. **Given** P.R.O.X.Y. is standing at the edge of a pit in Ground Mode, **When** a Grunt attacks and applies 0.5-tile knockback, **Then** P.R.O.X.Y. falls into the pit, takes 50 damage, and respawns at the nearest solid tile to room center with 1.5 seconds of invincibility.
5. **Given** P.R.O.X.Y. is in Air Mode and the player releases the jetpack input while over a pit, **When** the player cannot reposition to solid ground before touchdown, **Then** the fall sequence triggers at the moment of touchdown.

---

### User Story 4 - Enemy Behaviour & Wave Progression (Priority: P2)

A player faces escalating waves of enemies — ground-based Grunts that chase and melee, and airborne Drones that kite and shoot from range. Each enemy type requires a different approach, and the wave composition forces the player to manage both threats simultaneously.

**Why this priority**: Enemy AI correctness is required to validate balance decisions around energy spend and combat strategy. Without both enemy types behaving correctly, playtesting data is unreliable.

**Independent Test**: Grunts can be tested independently (spawn, chase, attack, pathfind around pits). Drones can be tested independently (kite, shoot, flee from melee range). Both are valid sub-deliverables.

**Acceptance Scenarios**:

1. **Given** a Grunt spawns at a room edge, **When** P.R.O.X.Y. is visible, **Then** the Grunt pathfinds toward P.R.O.X.Y. using the tile grid, avoids broken tiles, attacks when within 1.5 units, and deals 15 damage per hit with a 1.2-second cooldown.
2. **Given** a Grunt is near a pit, **When** pathfinding toward P.R.O.X.Y., **Then** the Grunt routes around the pit rather than walking into it.
3. **Given** a Drone spawns at a room edge, **When** P.R.O.X.Y. is present, **Then** the Drone positions itself 6–8 units away, fires a projectile every 1.5 seconds dealing 8 damage, and flees if P.R.O.X.Y. closes within 4 units.
4. **Given** P.R.O.X.Y. is in Ground Mode and uses Heavy Slam on a Drone, **Then** no damage is applied (Drones are immune to melee).
5. **Given** all enemies in a wave are destroyed, **When** the 3-second delay expires, **Then** the next wave spawns at room edges on solid tiles at least 8 units from P.R.O.X.Y., with composition following the defined wave table.

---

### User Story 5 - Loot System & Collection Risk (Priority: P3)

A player collects Health and Energy orbs dropped by defeated enemies. Collecting orbs requires being in Ground Mode, creating meaningful decisions about when to land — especially after killing Drones that may have died over pits.

**Why this priority**: Loot is the recovery mechanism that sustains runs. It must work correctly to validate the balance between resource gain and the risk of switching to Ground Mode.

**Independent Test**: Can be tested by killing one Grunt (orb lands on ground) and one Drone over a pit (orb is lost), then attempting to collect the ground orb from both Air Mode (fails) and Ground Mode (succeeds).

**Acceptance Scenarios**:

1. **Given** an enemy is defeated over a solid tile, **When** it dies, **Then** a Health or Energy orb (50/50 chance) appears on the tile directly beneath where the enemy was.
2. **Given** a Drone is defeated directly above a pit, **When** it dies, **Then** no orb is spawned (loot is lost).
3. **Given** an orb is on the floor and P.R.O.X.Y. is in Air Mode within 1.5 units, **When** the player flies over it, **Then** the orb is NOT collected.
4. **Given** an orb is on the floor and P.R.O.X.Y. is in Ground Mode within 1.5 units, **When** the player walks over it, **Then** the orb is collected (Health Orb restores 15 HP capped at 100; Energy Orb restores 20 energy capped at 100).

---

### Edge Cases

- What happens when all floor tiles are destroyed? → P.R.O.X.Y. cannot stand anywhere in Ground Mode; any landing triggers a fall. With 50 HP per fall and only 100 max HP, two falls cause death.
- What happens when all room edges are pits at wave spawn time? → The spawner picks the nearest valid solid tile for Grunts. If no solid tiles exist, the wave spawns as Drones only.
- What happens when multiple Grunts hit P.R.O.X.Y. simultaneously? → All damage is applied, but only one knockback vector is applied. A 0.3-second knockback cooldown prevents chain-pushing.
- What happens when P.R.O.X.Y. falls and lands with 0 HP? → Game Over is triggered. The 1.5-second invincibility on respawn does not prevent death if HP was already at zero from the fall damage.
- What happens when a Grunt is knocked back by Slam while in its attack animation? → The knockback interrupts the attack; the Grunt's attack cooldown resets.

---

## Clarifications

### Session 2026-04-05

- Q: When P.R.O.X.Y.'s HP reaches 0 (Game Over), what happens next in the prototype? → A: Brief on-screen summary (waves survived + time elapsed), then auto-restart after a few seconds.
- Q: In Ground Mode, does the right stick control facing direction for attacks, or is facing locked to movement? → A: Right stick controls P.R.O.X.Y.'s facing in Ground Mode; Slam fires in the faced direction; Spin Attack always hits 360° regardless of facing.
- Q: Can the player activate Air Mode during a Slam or Spin animation lock? → A: Jetpack input is ignored during animation lock and is NOT buffered — player must wait for the attack to finish before lifting off.
- Q: What is the minimum separation distance between Drones? → A: 3 units minimum (~1.5 tile widths).
- Q: When releasing the jetpack over a pit, does P.R.O.X.Y. fall or stay hovering? → A: Releasing the jetpack begins a descent during which the player retains horizontal movement control; if P.R.O.X.Y. is over solid ground when it touches down it lands safely, if it is over a pit when it touches down the fall sequence triggers.

---

## Requirements *(mandatory)*

### Functional Requirements

**Player & State**

- **FR-001**: P.R.O.X.Y. MUST operate in exactly two mutually exclusive states — Ground Mode and Air Mode — with no simultaneous overlap.
- **FR-002**: P.R.O.X.Y. MUST maintain a Health pool (max 100) and an Energy pool (max 100) that persist across the current room session.
- **FR-003**: P.R.O.X.Y. MUST have zero passive energy regeneration; energy can only be recovered via the Energy Plug or loot orbs.
- **FR-004**: State transitions MUST complete within approximately 0.2–0.3 seconds with no invincibility frames during the transition. During the descent from Air Mode to Ground Mode, the player retains full horizontal movement control; the fall sequence triggers if P.R.O.X.Y. is positioned over a pit at the moment of touchdown.
- **FR-005**: P.R.O.X.Y. MUST be able to queue the next attack input during the final 0.2 seconds of an attack animation (input buffering).

**Ground Mode**

- **FR-006**: In Ground Mode, P.R.O.X.Y. MUST move at 4.0 units/sec and have access to Heavy Slam and Spin Attack only. The right stick controls P.R.O.X.Y.'s facing direction independently of movement direction.
- **FR-007**: Heavy Slam MUST deal 40 damage to enemies in the direction P.R.O.X.Y. is facing, apply 2.5 tiles of knockback to a mass-1.0 target, deal 1 damage to the struck floor tile, and cost zero energy.
- **FR-008**: Spin Attack MUST deal 25 damage to all enemies in a full 360-degree radius regardless of facing direction, apply 1.5 tiles of knockback, NOT damage floor tiles, and cost 20 energy per use.
- **FR-009**: Both Slam (~0.8 sec) and Spin (~0.6 sec) MUST impose an animation lock on movement for their full duration. The jetpack input MUST be ignored during this lock and MUST NOT be buffered — Air Mode activation is only possible after the attack animation completes.

**Air Mode**

- **FR-010**: Air Mode MUST be entered by holding the jetpack input and exited by releasing it, with hovering capped at 3.0 units height.
- **FR-011**: Hovering MUST drain 10 energy per second; reaching 0 energy over solid ground MUST force a landing; reaching 0 energy over a pit MUST trigger the fall sequence.
- **FR-012**: In Air Mode, P.R.O.X.Y. MUST move at 7.0 units/sec and have access to Machine Gun only (melee unavailable).
- **FR-013**: Machine Gun MUST fire at 6 shots/second, deal 5 damage per shot, apply 0.1-tile knockback per hit, cost 2 energy per shot, and NOT damage floor tiles.

**Energy Plug**

- **FR-014**: The Energy Plug MUST recharge energy at 25 per second while P.R.O.X.Y. is plugged in.
- **FR-015**: Plugging in MUST completely immobilize P.R.O.X.Y. (no movement, attacks, or hovering) and impose a minimum 0.5-second lock-in.
- **FR-016**: After the lock-in period, any player input MUST immediately cancel the plug session; energy gained up to that point is kept.
- **FR-017**: Attempting to plug in at full energy (100) MUST be ignored with no lock-in applied.

**Floor & Pits**

- **FR-018**: Each floor tile MUST have 2 HP; one Slam hit reduces HP to 1 (cracked); a second Slam hit destroys the tile and creates a permanent pit.
- **FR-019**: Broken tiles MUST be marked as unwalkable immediately and trigger a pathfinding recalculation for all active Grunts.
- **FR-020**: Walking over a pit in Ground Mode MUST trigger the fall sequence. Flying over a pit in Air Mode MUST be safe up to the hover height cap.

**Fall Sequence**

- **FR-021**: Falling MUST apply 50 damage (always 50% of max HP, not current HP), respawn P.R.O.X.Y. on the nearest solid tile to room center, and grant 1.5 seconds of invincibility. Energy is unchanged by falling.
- **FR-022**: If a fall reduces HP to 0, Game Over MUST be triggered: the session ends, a brief on-screen summary displaying waves survived and time elapsed is shown, and the prototype auto-restarts after a few seconds.

**Enemies — Grunt**

- **FR-023**: Grunts MUST have 80 HP, move at 3.5 units/sec on ground, attack at 1.5-unit range for 15 damage with a 1.2-second cooldown, and apply 0.5-tile knockback to P.R.O.X.Y. on hit.
- **FR-024**: Grunts MUST pathfind around broken tiles (A* on the tile grid) and MUST NOT voluntarily walk into pits.
- **FR-025**: Grunts CAN be knocked into pits by player attacks, resulting in instant death with no loot drop.

**Enemies — Drone**

- **FR-026**: Drones MUST have 50 HP, move at 6.0 units/sec in air, fire a projectile every 1.5 seconds dealing 8 damage, and ignore floor tiles entirely (including broken ones).
- **FR-027**: Drones MUST maintain a preferred range of 6–8 units from P.R.O.X.Y. and reposition if the player closes within 4 units.
- **FR-028**: Drones MUST be immune to all melee attacks (Slam and Spin); only the Machine Gun can damage them.
- **FR-029**: Multiple Drones in the same room MUST maintain a minimum separation of 3 units from each other — they MUST NOT stack at the same position.

**Knockback**

- **FR-030**: All knockback MUST be calculated using mass: P.R.O.X.Y. mass = 1.5, Grunt mass = 1.0, Drone mass = 0.3.
- **FR-031**: When multiple simultaneous hits occur on P.R.O.X.Y., MUST apply only one knockback vector and enforce a 0.3-second knockback cooldown before the next knockback can apply.

**Loot**

- **FR-032**: Every enemy death MUST spawn exactly one loot orb (50% Health Orb = +15 HP, 50% Energy Orb = +20 energy) at the floor tile directly beneath the enemy's position at death.
- **FR-033**: Loot orbs spawned above a pit (including Drone kills over pits) MUST be destroyed immediately — no orb is placed.
- **FR-034**: Loot orbs MUST only be collectible in Ground Mode within 1.5 units of contact; Air Mode collection MUST be ignored.

**Wave System**

- **FR-035**: The prototype MUST run as an endless wave-based sandbox with no win condition.
- **FR-036**: Wave composition MUST follow the defined escalation: Wave 1 = 4 Grunts; Wave 2 = 3 Grunts + 1 Drone; Wave 3 = 2 Grunts + 2 Drones; Wave 4+ = add 1 enemy per wave, alternating type.
- **FR-037**: Enemies MUST spawn at room edges on solid tiles at least 8 units from P.R.O.X.Y., with a 3-second delay between wave clear and next wave spawn.
- **FR-038**: Maximum 8 enemies MUST be alive simultaneously.

### Key Entities

- **P.R.O.X.Y.**: The player-controlled combat droid. Has Health (0–100), Energy (0–100), current state (Ground/Air), position, and knockback cooldown timer.
- **Floor Tile**: A 2×2 unit grid cell with HP (0–2). At 0 HP it becomes a permanent pit.
- **Grunt**: A ground enemy with Health, position on the tile grid, current AI state (Chase/Attack), and pathfinding data.
- **Drone**: An airborne enemy with Health, position in 3D space, current AI state (Kite/Flee/Shoot), and last-shot timer.
- **Energy Plug**: A fixed wall-mounted station. Tracks whether it is currently in use and is accessible only when P.R.O.X.Y. has less than 100 energy.
- **Loot Orb**: A Health or Energy pickup. Has a type, floor position, and collection radius. Destroyed immediately if spawned over a pit.
- **Wave**: Tracks current wave number, enemies remaining alive, spawn composition, the between-wave delay timer, and session elapsed time (for the Game Over summary).

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A typical playtest run lasts between 3 and 5 minutes before P.R.O.X.Y. is overwhelmed and the session ends.
- **SC-002**: Playtesters consistently identify the Heavy Slam as the most efficient method for killing Grunts without being prompted.
- **SC-003**: No more than 40% of floor tiles are destroyed before any given wave is cleared; if this threshold is consistently exceeded, wave spawn counts require adjustment.
- **SC-004**: Playtesters voluntarily engage with the Energy Plug at least once per run, indicating energy pressure is felt as real and consequential.
- **SC-005**: Playtesters describe the choice to collect loot (requiring landing) after airborne combat as a deliberate decision rather than an automatic action.
- **SC-006**: Playtesters describe getting knocked into a self-created pit as feeling fair and strategically foreseeable, not random.
- **SC-007**: Wave 1 (Grunts only) is completable by new players with no prior instruction, validating that ground combat is learnable in isolation.
- **SC-008**: Wave 2 (first Drone appearance) causes a measurable shift in player behaviour toward Air Mode, confirming the Drone creates air combat necessity as intended.

---

## Assumptions

- Scope is strictly Phase 0: a single enclosed room with no floor transitions, no meta-progression, and no persistent save state between runs.
- The prototype is played on a gamepad (twin-stick controller layout); keyboard and mouse support is a secondary concern for Phase 0.
- Visual assets are placeholder primitives (capsules, cubes, spheres); art fidelity is out of scope for this phase.
- The room always contains exactly one Energy Plug at a fixed wall-mounted position.
- All balance values (damage, energy costs, speeds, HP) are starting estimates sourced from the GDD v0.3 and Balance Sheet v0.3, and are expected to change based on playtesting data.
- Elevator access between floors is non-functional in Phase 0; the room is entirely self-contained.
- There is no in-game tutorial, UI onboarding, or guided instruction for Phase 0 playtests.
- The debug HUD (enemy spawner, god mode, infinite energy, floor reset, hitbox visualisation, etc.) is a required part of this deliverable for playtesting support, but is not a shipped feature.
