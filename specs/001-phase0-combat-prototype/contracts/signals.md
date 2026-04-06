# Signal Architecture: Phase 0 Combat Prototype

**Branch**: `001-phase0-combat-prototype` | **Date**: 2026-04-05  
**Source**: GDD v0.3 Section 8.4 — Signal / Event Architecture

All signals are emitted and received through a single global autoload: `autoloads/event_bus.gd`.  
This keeps all systems decoupled — no direct node references between unrelated systems.

---

## EventBus Signal Definitions

```gdscript
# autoloads/event_bus.gd
extends Node

# --- Player ---
signal player_state_changed(new_state: String)       # "ground" | "air"
signal player_health_changed(new_health: int)
signal player_energy_changed(new_energy: int)
signal player_took_damage(damage: int, source_position: Vector3)
signal player_fell()
signal player_respawned()
signal player_plugged_in()
signal player_unplugged(energy_gained: float)

# --- Enemies ---
signal enemy_died(enemy_type: String, world_position: Vector3, over_pit: bool)
signal enemy_count_changed(count: int)

# --- Floor ---
signal tile_damaged(grid_pos: Vector2i, new_hp: int)
signal tile_destroyed(grid_pos: Vector2i)

# --- Waves ---
signal wave_started(wave_number: int)
signal wave_cleared(wave_number: int)

# --- Session ---
signal game_over(waves_survived: int, elapsed_seconds: float)
signal session_restarted()
```

---

## Event Chains

### Enemy Dies

**Emitter**: `grunt.gd` / `drone.gd` on `health <= 0`  
**Signal**: `enemy_died(enemy_type, world_position, over_pit)`

| Receiver | Action |
|---|---|
| `loot_system.gd` | If `over_pit = false`: spawn Health or Energy orb (50/50) at floor beneath `world_position`. If `over_pit = true`: no orb. |
| `wave_manager.gd` | Decrement `enemies_alive`. If `enemies_alive == 0`: emit `wave_cleared`. |

---

### Tile Takes Damage / Breaks

**Emitter**: `floor_tile.gd` on Slam contact  
**Signals**: `tile_damaged(grid_pos, new_hp)` then `tile_destroyed(grid_pos)` when hp hits 0

| Receiver | Action |
|---|---|
| `grid_manager.gd` | On `tile_destroyed`: call `astar.set_point_solid(grid_pos, true)`. Spawn pit `Area3D` beneath destroyed tile. Check if any spawn points remain valid. |
| All active `grunt.gd` instances | On `tile_destroyed`: recalculate path on next pathfinding tick. |
| `wave_manager.gd` | On `tile_destroyed`: re-validate edge spawn points. |

---

### Wave Cleared

**Emitter**: `wave_manager.gd` when `enemies_alive == 0`  
**Signal**: `wave_cleared(wave_number)`

| Receiver | Action |
|---|---|
| `wave_manager.gd` (self) | Start 3-second `spawn_delay_timer`. On expiry: calculate next wave composition, spawn enemies at valid edge tiles ≥ 8 units from player, emit `wave_started(wave_number + 1)`. |
| `hud.gd` | Update wave counter display. |

---

### Energy Hits Zero in Air

**Emitter**: `state_air.gd` when `energy == 0`  
**Handled internally** in `player_controller.gd`:

| Condition | Outcome |
|---|---|
| Over solid ground (`grid_manager.is_over_pit() == false`) | Force transition to Ground Mode. Emit `player_state_changed("ground")`. |
| Over pit (`grid_manager.is_over_pit() == true`) | Trigger fall sequence (see below). |

---

### Player Falls Into Pit

**Emitter**: `player_controller.gd` (fall sequence trigger)  
**Signal**: `player_fell()`

| Receiver | Action |
|---|---|
| `player_controller.gd` (self) | Apply 50 damage. Find nearest solid tile to room center. Teleport P.R.O.X.Y. there. Start 1.5-sec invincibility timer. Check if `health <= 0` → if so, emit `game_over`. |
| `hud.gd` | React to `player_health_changed`. |

---

### Player Plugs Into Energy Plug

**Emitter**: `energy_plug.gd`  
**Signals**: `player_plugged_in()`, `player_unplugged(energy_gained)`

| Receiver | Action |
|---|---|
| `player_controller.gd` | On `player_plugged_in`: immobilise (block all input except cancel). Begin listening for cancel input after 0.5-sec lock-in. On cancel: call `unplug()`. |
| `energy_plug.gd` (self) | Each physics frame while plugged: `player.energy = min(player.energy + 25 * delta, 100)`. Emit `player_energy_changed`. |
| `hud.gd` | React to `player_energy_changed`. |

---

### Player Takes Damage

**Emitter**: `grunt.gd` (melee), `projectile.gd` (Drone bullet)  
**Signal**: `player_took_damage(damage, source_position)`

| Receiver | Action |
|---|---|
| `player_controller.gd` | If `is_invincible`: ignore. Else: reduce `health` by `damage`. Emit `player_health_changed`. Apply knockback via `knockback_system.gd` if not in cooldown. Start 0.3-sec knockback cooldown. After displacement, check `grid_manager.is_over_pit()`. |
| `hud.gd` | React to `player_health_changed`. Update health bar. |

---

### Game Over

**Emitter**: `player_controller.gd` when `health <= 0` after fall (or damage)  
**Signal**: `game_over(waves_survived, elapsed_seconds)`

| Receiver | Action |
|---|---|
| `game_over_screen.gd` | Display waves survived + elapsed time as MM:SS. Begin auto-restart countdown (~3–5 sec). |
| `wave_manager.gd` | Stop all wave timers and spawning. |
| `session_tracker.gd` | Freeze elapsed time. |

---

### Session Restart

**Emitter**: `game_over_screen.gd` after auto-restart delay  
**Signal**: `session_restarted()`

| Receiver | Action |
|---|---|
| All systems | Reset to initial state: reload main scene or call individual `reset()` methods. |
