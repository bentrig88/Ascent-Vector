# Data Model: Phase 0 Combat Prototype

**Branch**: `001-phase0-combat-prototype` | **Date**: 2026-04-05

All entities are Godot 4 nodes (scenes). No external database or file persistence in Phase 0.

---

## Entity: PlayerProxy (P.R.O.X.Y.)

**Node type**: `CharacterBody3D`  
**Scene**: `scenes/player/proxy.tscn`  
**Script**: `scripts/player/player_controller.gd`

| Field | Type | Range / Values | Notes |
|---|---|---|---|
| `health` | `int` | 0 – 100 | Reaching 0 triggers Game Over |
| `energy` | `int` | 0 – 100 | Shared resource for hover, gun, spin |
| `current_state` | `State` (inner class) | State_Ground \| State_Air | Only one active at a time |
| `facing_vector` | `Vector3` | Unit vector, XZ plane | Controlled by right stick in Ground Mode |
| `knockback_cooldown` | `float` | 0.0 – 0.3 sec | No further knockback while > 0 |
| `is_invincible` | `bool` | — | True for 1.5 sec after respawn |
| `invincibility_timer` | `float` | 0.0 – 1.5 sec | Counts down |

**State transitions**:
```
Ground Mode ──[hold jetpack]──► Air Mode
Air Mode    ──[release jetpack, after descent, over solid tile]──► Ground Mode
Air Mode    ──[release jetpack, after descent, over pit]──► Fall Sequence
Air Mode    ──[energy = 0, over solid tile]──► Ground Mode (forced land)
Air Mode    ──[energy = 0, over pit]──► Fall Sequence
```

**Validation rules**:
- `health` and `energy` are clamped to [0, 100] on every modification
- Jetpack input discarded while animation lock timer > 0
- Energy cannot increase above 100 (orb collection and plug recharge both cap at 100)

---

## Entity: FloorTile

**Node type**: `StaticBody3D`  
**Scene**: `scenes/environment/floor_tile.tscn`  
**Script**: `scripts/environment/floor_tile.gd`

| Field | Type | Range / Values | Notes |
|---|---|---|---|
| `tile_hp` | `int` | 0 – 2 | 2 = intact, 1 = cracked, 0 = destroyed (pit) |
| `grid_position` | `Vector2i` | (0,0) – (9,9) | Position in the 10×10 grid |
| `is_walkable` | `bool` | — | False when `tile_hp == 0` |

**State transitions**:
```
Intact (hp=2) ──[Slam hit]──► Cracked (hp=1)  [visual crack applied]
Cracked (hp=1) ──[Slam hit]──► Destroyed (hp=0) [tile removed, pit Area3D spawned]
```

**Validation rules**:
- Only `Slam` attacks reduce `tile_hp` (Spin and Machine Gun deal 0 tile damage)
- Transition to Destroyed is permanent — tiles do not regenerate in Phase 0
- On destruction: emit `tile_destroyed(grid_position)`, mark AStarGrid2D point solid, spawn pit `Area3D`

---

## Entity: Grunt

**Node type**: `CharacterBody3D`  
**Scene**: `scenes/enemies/grunt.tscn`  
**Script**: `scripts/enemies/grunt.gd`

| Field | Type | Range / Values | Notes |
|---|---|---|---|
| `health` | `int` | 0 – 80 | 0 = dead |
| `move_speed` | `float` | 3.5 units/sec | Constant |
| `attack_damage` | `int` | 15 | Applied to player on contact |
| `attack_cooldown_timer` | `float` | 0.0 – 1.2 sec | Counts down between attacks |
| `attack_range` | `float` | 1.5 units | Must be within range to attack |
| `mass` | `float` | 1.0 | Baseline for knockback |
| `ai_state` | `enum` | Chase \| Attack \| Fall | Current AI behaviour |
| `current_path` | `PackedVector2Array` | — | Waypoints from AStarGrid2D |
| `knockback_cooldown` | `float` | 0.0 – 0.3 sec | |

**State transitions**:
```
Chase ──[within attack_range of player]──► Attack
Attack ──[player moves outside attack_range]──► Chase
Attack ──[knocked into pit]──► Fall (instant death, no loot)
Chase/Attack ──[health = 0]──► Dead (despawn, emit enemy_died)
```

**Validation rules**:
- Pathfinding recalculated when `tile_destroyed` received or when target tile changes
- Will not voluntarily path through a solid (pit) grid point
- Knockback from any player attack can override `ai_state` briefly; cooldown prevents chain-pushing

---

## Entity: Drone

**Node type**: `CharacterBody3D` (gravity disabled)  
**Scene**: `scenes/enemies/drone.tscn`  
**Script**: `scripts/enemies/drone.gd`

| Field | Type | Range / Values | Notes |
|---|---|---|---|
| `health` | `int` | 0 – 50 | 0 = dead |
| `move_speed` | `float` | 6.0 units/sec | Constant |
| `projectile_damage` | `int` | 8 | Per shot |
| `fire_rate_timer` | `float` | 0.0 – 1.5 sec | Time between shots |
| `preferred_min_range` | `float` | 6.0 units | Minimum preferred distance from player |
| `preferred_max_range` | `float` | 8.0 units | Maximum preferred distance from player |
| `flee_trigger_range` | `float` | 4.0 units | Flee if player closer than this |
| `mass` | `float` | 0.3 | Light — nudged by gun hits |
| `ai_state` | `enum` | Kite \| Flee \| Shoot | Current AI behaviour |
| `knockback_cooldown` | `float` | 0.0 – 0.3 sec | |

**State transitions**:
```
Kite ──[player within flee_trigger_range]──► Flee
Flee ──[player outside preferred_min_range]──► Kite
Kite/Flee ──[fire_rate_timer = 0]──► Shoot (fire projectile, reset timer, return to prior state)
Kite/Flee/Shoot ──[health = 0]──► Dead
```

**Validation rules**:
- Immune to Slam and Spin (FR-028); only Machine Gun deals damage
- Minimum 3 units separation from other Drones enforced each movement tick (FR-029)
- Does not interact with floor tiles — flies over pits freely
- Loot orb spawns at floor directly below death position; if over a pit, orb is discarded

---

## Entity: EnergyPlug

**Node type**: `Area3D`  
**Scene**: `scenes/environment/energy_plug.tscn`  
**Script**: `scripts/environment/energy_plug.gd`

| Field | Type | Range / Values | Notes |
|---|---|---|---|
| `is_in_use` | `bool` | — | True while player is plugged in |
| `lock_in_timer` | `float` | 0.0 – 0.5 sec | Minimum commitment before cancel is possible |
| `recharge_rate` | `float` | 25.0 energy/sec | Constant |

**State transitions**:
```
Idle ──[player activates while energy < 100]──► Charging (lock-in starts)
Idle ──[player activates while energy = 100]──► Idle (input ignored)
Charging ──[lock_in_timer expires + any input]──► Idle (player keeps energy gained)
```

**Validation rules**:
- Immobilises player completely during `is_in_use = true` (no movement, no attacks, no hover)
- Cancel is only possible after `lock_in_timer` reaches 0 (0.5 sec minimum)
- Recharge stops immediately on cancel; no partial-tick rounding

---

## Entity: LootOrb

**Node type**: `Area3D`  
**Scene**: `scenes/pickups/health_orb.tscn` or `scenes/pickups/energy_orb.tscn`  
**Script**: `scripts/pickups/loot_orb.gd`

| Field | Type | Range / Values | Notes |
|---|---|---|---|
| `orb_type` | `enum` | Health \| Energy | Determined at spawn (50/50) |
| `restore_amount` | `int` | 15 (Health) \| 20 (Energy) | |
| `collection_radius` | `float` | 1.5 units | Contact-based |

**Validation rules**:
- Spawned at the floor tile directly beneath the enemy's world position at death
- If spawned above a pit: immediately `queue_free()` — no orb placed
- Collection only occurs when P.R.O.X.Y. is in Ground Mode (Air Mode contacts ignored)
- Restore is capped: `health = min(health + 15, 100)` / `energy = min(energy + 20, 100)`

---

## Entity: Wave

**Node**: Managed by `wave_manager.gd` (not a scene; lives on WaveManager node in `main.tscn`)

| Field | Type | Range / Values | Notes |
|---|---|---|---|
| `wave_number` | `int` | 1 – ∞ | Increments on wave clear |
| `enemies_alive` | `int` | 0 – 8 | Decremented on each `enemy_died` signal |
| `spawn_delay_timer` | `float` | 0.0 – 3.0 sec | Between wave clear and next spawn |
| `max_enemies_alive` | `int` | 8 | Hard cap; constant |

**Spawn composition logic**:
```
Wave 1: 4 Grunts
Wave 2: 3 Grunts + 1 Drone
Wave 3: 2 Grunts + 2 Drones
Wave 4+: previous wave + 1 enemy, alternating type (Grunt on even delta, Drone on odd)
Cap at max_enemies_alive = 8 regardless of wave number
```

---

## Entity: SessionTracker

**Node**: Autoload or child of WaveManager

| Field | Type | Notes |
|---|---|---|
| `session_start_time` | `float` | `Time.get_ticks_msec()` at session start |
| `elapsed_seconds` | `float` | Updated each frame; displayed on Game Over screen |
| `waves_survived` | `int` | Equals `wave_number - 1` at Game Over |
