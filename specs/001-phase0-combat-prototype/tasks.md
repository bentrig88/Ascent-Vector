# Tasks: Phase 0 Combat Prototype

**Input**: Design documents from `specs/001-phase0-combat-prototype/`  
**Prerequisites**: plan.md ✓ spec.md ✓ research.md ✓ data-model.md ✓ contracts/signals.md ✓

**Organization**: Tasks grouped by user story — each story is independently implementable and testable.  
**Tests**: Not included (no automated test framework in Phase 0; validation via debug HUD + manual playtesting).

## Format: `[ID] [P?] [Story?] Description — file path`

- **[P]**: Can run in parallel (different files, no shared dependencies)
- **[Story]**: User story this task belongs to (US1–US5)

---

## Phase 1: Setup

**Purpose**: Godot project initialisation — no gameplay, just structure.

- [x] T001 Create Godot 4 project directory structure: `scenes/`, `scripts/`, `autoloads/` with subdirectories matching plan.md layout — `project.godot`
- [x] T002 Configure `project.godot`: set window size (1280×720 default), physics layers 1–8 per GDD collision matrix, register `autoloads/event_bus.gd` as `EventBus` singleton, add gamepad and keyboard Input Map actions (move, aim, jetpack, slam, spin, fire, plug) — `project.godot`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before any user story can start.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [x] T003 Create EventBus autoload with all signal definitions from `contracts/signals.md`: player signals, enemy signals, floor signals, wave signals, session signals — `autoloads/event_bus.gd`
- [x] T004 [P] Create GridManager: initialise `AStarGrid2D` with 10×10 region and 2×2 cell size, expose `is_point_solid()`, `is_over_pit(world_pos)`, `get_path(from, to)`, `get_nearest_solid_to_center()`, and `destroy_tile(grid_pos)` methods — `scripts/systems/grid_manager.gd`
- [x] T005 [P] Create FloorTile scene: `StaticBody3D` with collision on Layer 2, `MeshInstance3D` (2×2×0.5 cube primitive), and `grid_position: Vector2i` export — `scenes/environment/floor_tile.tscn`
- [x] T006 Create Room scene: four `StaticBody3D` walls (4 units tall, Layer 1), floor grid anchor node, and placeholder `Node3D` for Energy Plug mount point; instance and position 100 FloorTiles via `GridManager` in `_ready()` — `scenes/environment/room.tscn`
- [x] T007 [P] Create SessionTracker: track `session_start_time` via `Time.get_ticks_msec()`, expose `get_elapsed_seconds()` and `waves_survived: int`; subscribe to `EventBus.wave_cleared` to increment count — `scripts/systems/session_tracker.gd`
- [x] T008 [P] Create HUD scene: `CanvasLayer` with health bar (`ProgressBar`, max=100), energy bar (`ProgressBar`, max=100), wave label; subscribe to `EventBus.player_health_changed`, `player_energy_changed`, `wave_started` — `scenes/ui/hud.tscn` + `scripts/ui/hud.gd`

**Checkpoint**: EventBus, GridManager, Room, and HUD exist — user story implementation can now begin.

---

## Phase 3: User Story 1 — Ground/Air State Switching (Priority: P1) 🎯 MVP

**Goal**: P.R.O.X.Y. moves, switches between Ground and Air Mode, drains energy in the air, and triggers fall/land correctly. No enemies needed.

**Independent Test**: Launch room with no enemies. Verify: left stick moves at 4.0 u/s on ground; hold jetpack lifts off to 3-unit cap at 7.0 u/s with energy draining; release jetpack begins descent with horizontal control; landing over solid tile reverts to Ground Mode; landing over pit triggers fall (50 damage, respawn); energy hitting 0 over ground forces land; energy hitting 0 over pit triggers fall. Camera zooms in on ground, out in air.

- [x] T009 [US1] Create PlayerController: `CharacterBody3D` on Layer 3, inner-class `State` base with `enter()`, `exit()`, `physics_process(delta)`; `current_state` reference; delegate `_physics_process` to state; expose `health: int`, `energy: int`, `facing_vector: Vector3`, `knockback_cooldown: float`, `is_invincible: bool` — `scripts/player/player_controller.gd`
- [x] T010 [P] [US1] Implement `State_Ground`: left stick → velocity at 4.0 u/s via `move_and_slide()`; right stick → update `facing_vector` (XZ plane, normalised); `animation_lock_timer: float` counts down; jetpack input silently discarded while `animation_lock_timer > 0`; emit `EventBus.player_state_changed("ground")` on `enter()` — `scripts/player/state_ground.gd`
- [x] T011 [P] [US1] Implement `State_Air`: left stick → velocity at 7.0 u/s; maintain Y position at 3-unit hover cap via `move_and_slide()`; drain `energy` at 10/sec each physics frame; clamp energy to 0; on energy == 0 check `GridManager.is_over_pit()` — force land or trigger fall; emit `EventBus.player_energy_changed(energy)` each frame — `scripts/player/state_air.gd`
- [x] T012 [US1] Add state transition logic in PlayerController: detect jetpack input press → call `transition_to(State_Air)`; detect jetpack release → begin descent phase (gravity applied, horizontal input retained, `is_descending = true`); on `CharacterBody3D.is_on_floor()` while descending, check `GridManager.is_over_pit()` → land safely or trigger fall sequence — `scripts/player/player_controller.gd`
- [x] T013 [US1] Implement Fall Sequence method in PlayerController: apply 50 damage (`health = max(health - 50, 0)`); find nearest solid tile to room centre via `GridManager.get_nearest_solid_to_center()`; teleport P.R.O.X.Y. there; start 1.5-sec `invincibility_timer`; emit `EventBus.player_health_changed(health)` and `EventBus.player_fell()`; if `health <= 0` emit `EventBus.game_over(session_tracker.waves_survived, session_tracker.get_elapsed_seconds())` — `scripts/player/player_controller.gd`
- [x] T014 [P] [US1] Create ProxyCamera script: `Camera3D` with `PROJECTION_ORTHOGONAL`; fixed 45° isometric rotation (Y: 45°, X: 30°); soft-follow P.R.O.X.Y. position via `lerp()` at speed 5.0; clamp to room `AABB`; on `EventBus.player_state_changed`: lerp `size` from current to `ground_zoom = 6.0` or `air_zoom = 10.0` over 0.5 sec using `smoothstep()` — `scripts/camera/proxy_camera.gd`
- [x] T015 [US1] Assemble Proxy scene: parent `CharacterBody3D` + `PlayerController` script, `CollisionShape3D` (capsule), `MeshInstance3D` (capsule primitive), child `ProxyCamera` node; set collision layers/masks per GDD matrix (Layer 3, masks to 1+2+4+5) — `scenes/player/proxy.tscn`

**Checkpoint**: US1 fully playable and testable with no enemies. Camera, movement, state switching, fall/land all functional.

---

## Phase 4: User Story 2 — Combat & Energy Economy Loop (Priority: P1)

**Goal**: All three attacks work with correct energy costs, animation locks, and knockback. Energy Plug recharges with correct risk feel. KnockbackSystem enforces mass-based displacement and the simultaneous-hit cooldown rule.

**Independent Test**: Spawn a single wave of 4 Grunts via debug HUD. Verify: Slam kills Grunt in 2 hits with no energy cost; Spin hits all surrounding Grunts and costs 20 energy; Machine Gun fires in Air Mode at 6 shots/sec costing 2 energy each; Plug recharges at 25/sec, immobilises player, cancels on input after 0.5s lock-in; plugging at 100 energy does nothing; simultaneous Grunt attacks apply one knockback only.

- [x] T016 [P] [US2] Create SlamHitbox: `Area3D` on Layer 6 masking Layer 4; forward arc shape (box, ~2×1×1 units centred ahead of facing); on body entered: deal 40 damage to Grunt, call `KnockbackSystem.apply(target, slam_force=2.5, source_pos)`; call `GridManager.damage_tile(tile_at_hit_pos)`; emit `EventBus.player_energy_changed` (Slam costs 0 energy); activate for ~0.1 sec during 0.8s animation lock — `scripts/weapons/slam_hitbox.gd`
- [x] T017 [P] [US2] Create SpinHitbox: `Area3D` on Layer 6 masking Layer 4; sphere/cylinder shape (~2-unit radius centred on player); on body entered: deal 25 damage to all overlapping Grunts, call `KnockbackSystem.apply(target, spin_force=1.5, source_pos)` for each; costs 20 energy (`energy = max(energy - 20, 0)`), emit `EventBus.player_energy_changed`; activate for ~0.1 sec during 0.6s animation lock; does NOT damage tiles — `scripts/weapons/spin_hitbox.gd`
- [x] T018 [US2] Wire Slam and Spin into State_Ground: on slam input with `animation_lock_timer == 0`: set `animation_lock_timer = 0.8`, activate SlamHitbox for 0.1s, play animation; on spin input with `animation_lock_timer == 0` and `energy >= 20`: set `animation_lock_timer = 0.6`, activate SpinHitbox; implement input buffer: if slam/spin pressed when `0 < animation_lock_timer <= 0.2`, store `buffered_action` string and execute on lock expiry — `scripts/player/state_ground.gd`
- [x] T019 [P] [US2] Implement Machine Gun in State_Air: on fire input held, fire at 6 shots/sec (`fire_timer` accumulates delta); each shot: spawn `Projectile` node at gun barrel, direction = `facing_vector`, cost 2 energy; if `energy < 2` stop firing; emit `EventBus.player_energy_changed`; right stick still controls facing in Air Mode — `scripts/player/state_air.gd`
- [x] T020 [P] [US2] Create Projectile scene and script: `CharacterBody3D` on Layer 7 masking Layers 4+5; velocity = `facing_vector * 10.0`; on body hit: deal 8 damage to target (Grunt or Drone), apply `KnockbackSystem.apply(target, gun_force_per_hit=0.1, source_pos)`, `queue_free()`; `queue_free()` on room boundary hit — `scenes/enemies/projectile.tscn` + `scripts/weapons/projectile.gd`
- [x] T021 [US2] Create EnergyPlug scene and script: `Area3D` wall-mounted; on player enter + plug input: if `energy == 100` ignore; else set `is_in_use = true`, immobilise player (block all PlayerController input), start `lock_in_timer = 0.5`; each frame: `energy = min(energy + 25 * delta, 100)`, emit `EventBus.player_energy_changed`; after lock-in expires, any input calls `unplug()`: set `is_in_use = false`, restore player input, emit `EventBus.player_unplugged(energy_gained)` — `scenes/environment/energy_plug.tscn` + `scripts/environment/energy_plug.gd`
- [x] T022 [US2] Create KnockbackSystem: `apply(target, force_tiles, source_pos)` method; calculate direction = `(target.global_position - source_pos).normalized()` (XZ only); scale = `force_tiles * tile_size / target.mass`; if `target.knockback_cooldown > 0`: skip knockback (damage still applies); else: add `direction * scale` to `target.velocity` for one frame, set `target.knockback_cooldown = 0.3`; after displacement, if target is player and `GridManager.is_over_pit(target.position)` → trigger fall sequence — `scripts/systems/knockback_system.gd`
- [x] T023 [US2] Subscribe PlayerController to `EventBus.player_took_damage`: deduct health, call `KnockbackSystem.apply()`, check death; connect SlamHitbox and SpinHitbox `body_entered` to emit `EventBus.player_took_damage` from enemy side — `scripts/player/player_controller.gd`

**Checkpoint**: Full combat loop playable. Player can fight, manage energy, and recharge. Knockback and animation lock work correctly.

---

## Phase 5: User Story 3 — Floor Destruction & Environmental Kills (Priority: P2)

**Goal**: Slam degrades and destroys tiles. Pits are permanent and hazardous to Grunts and the player. Grunt pathfinding recalculates on destruction.

**Independent Test**: In an empty room (no waves), repeatedly Slam a tile to verify crack → destroy → pit Area3D. Knock a Grunt into a pit — instant kill, no loot. Walk P.R.O.X.Y. into a pit — fall sequence. Be knocked into a pit by a Grunt melee hit — fall sequence.

- [x] T024 [US3] Implement tile HP in FloorTile script: `tile_hp: int = 2`; expose `take_slam_damage()`: decrement HP, if HP==1 apply crack mesh overlay, if HP==0 call `_destroy()`; `_destroy()`: hide tile mesh, disable `StaticBody3D` collision, emit `EventBus.tile_destroyed(grid_position)`, call `GridManager.destroy_tile(grid_position)` — `scripts/environment/floor_tile.gd`
- [x] T025 [US3] Wire SlamHitbox to call `floor_tile.take_slam_damage()` on the tile at the hit position (raycast or tile lookup by world position) — `scripts/weapons/slam_hitbox.gd`
- [x] T026 [P] [US3] On `EventBus.tile_destroyed` in GridManager: call `astar.set_point_solid(grid_pos, true)`, spawn pit `Area3D` (Layer 8) beneath destroyed tile; the pit Area3D `body_entered` triggers fall sequence on the player if in Ground Mode — `scripts/systems/grid_manager.gd`
- [x] T027 [P] [US3] Subscribe all active Grunt instances to `EventBus.tile_destroyed`: recalculate `current_path` from `GridManager.get_path()` on the next pathfinding tick — `scripts/enemies/grunt.gd`

**Checkpoint**: Floor destruction works. Pits kill Grunts (no loot) and punish the player. Grunt AI routes around broken tiles.

---

## Phase 6: User Story 4 — Enemy Behaviour & Wave Progression (Priority: P2)

**Goal**: Grunts chase and attack. Drones kite and shoot. Waves escalate. All spawn correctly.

**Independent Test**: Use debug HUD to spawn 1 Grunt — verify it pathfinds to player avoiding pits, attacks at 1.5-unit range for 15 damage with 1.2s cooldown. Spawn 1 Drone — verify it stays 6–8 units away, fires every 1.5s, flees if player closes to <4 units, cannot be harmed by melee. Let Wave 1 complete (all 4 Grunts dead) — verify 3s delay then Wave 2 spawns (3 Grunts + 1 Drone).

- [x] T028 [P] [US4] Create Grunt scene: `CharacterBody3D` on Layer 4, capsule collision, capsule mesh (placeholder colour); `health = 80`, `move_speed = 3.5`, `attack_damage = 15`, `attack_cooldown = 1.2`, `attack_range = 1.5`, `mass = 1.0`, `knockback_cooldown = 0.0` — `scenes/enemies/grunt.tscn`
- [x] T029 [P] [US4] Implement Grunt AI FSM in grunt.gd: `State_Chase` — poll `GridManager.get_path()` every 100ms, move toward next waypoint centre using velocity; `State_Attack` — entered when `distance_to_player < attack_range`, deal 15 damage via `EventBus.player_took_damage`, apply 0.5-tile knockback via `KnockbackSystem`, reset `attack_cooldown_timer`; transition back to Chase when player moves out of range — `scripts/enemies/grunt.gd`
- [x] T030 [P] [US4] Create Drone scene: `CharacterBody3D` gravity disabled, Layer 5, capsule collision+mesh; `health = 50`, `move_speed = 6.0`, `mass = 0.3`, `preferred_min = 6.0`, `preferred_max = 8.0`, `flee_range = 4.0`, `fire_timer = 1.5` — `scenes/enemies/drone.tscn`
- [x] T031 [P] [US4] Implement Drone AI FSM in drone.gd: `State_Kite` — move to maintain 6–8 unit distance from player, avoid walls (if cornered, slide along wall surface to escape rather than stopping); enforce 3-unit min separation from other Drones each tick; `State_Flee` — entered when player within 4 units OR player is in Air Mode and closing in (subscribe to `EventBus.player_state_changed`); flee speed remains 6.0 u/s but flee is triggered earlier in Air Mode since player air speed (7.0) nearly matches Drone speed — creating a tense pursuit that burns player energy; `State_Shoot` — fire `Projectile` toward player every 1.5s (reset `fire_timer`), return to prior state; Drone is immune to Layer 6 (melee) hits — `scripts/enemies/drone.gd`
- [x] T032 [US4] Wire enemy death in both grunt.gd and drone.gd: on `health <= 0`, check `GridManager.is_over_pit(global_position)`, emit `EventBus.enemy_died(type, global_position, over_pit)`, `queue_free()` — `scripts/enemies/grunt.gd` + `scripts/enemies/drone.gd`
- [x] T033 [US4] Create WaveManager: `wave_number = 0`, `enemies_alive = 0`; `start_next_wave()` calculates composition per spec wave table (W1: 4G, W2: 3G+1D, W3: 2G+2D, W4+: +1 alternating); spawn enemies at room edge solid tiles ≥8 units from player (validate via GridManager); cap at 8 total; if no solid edge tiles, fall back to Drones; subscribe to `EventBus.enemy_died` → decrement `enemies_alive`; if 0 → emit `wave_cleared`, start 3s `spawn_delay_timer` then call `start_next_wave()` — `scripts/systems/wave_manager.gd`
- [x] T034 [US4] Assemble main scene: instance Room, Proxy (player), WaveManager, SessionTracker, HUD, and DebugHUD as children of `main.tscn`; call `WaveManager.start_next_wave()` on `_ready()` — `scenes/main.tscn`

**Checkpoint**: Full endless wave loop running. Grunts and Drones behave correctly. Waves escalate and spawn correctly.

---

## Phase 7: User Story 5 — Loot System & Collection Risk (Priority: P3)

**Goal**: Every enemy death spawns a Health or Energy orb at its floor position (except over pits). Orbs are only collectible in Ground Mode.

**Independent Test**: Kill a Grunt — orb appears at tile below it, collect in Ground Mode (+15 HP or +20 energy), attempt collection in Air Mode (ignored). Kill a Drone over a pit — no orb spawns. Kill a Drone over solid ground — orb on tile below.

- [x] T035 [P] [US5] Create HealthOrb and EnergyOrb scenes: `Area3D` on Layer 2, sphere mesh (placeholder colour), `CollisionShape3D` (sphere radius 0.75); export `orb_type: String` and `restore_amount: int` (15 HP / 20 energy) — `scenes/pickups/health_orb.tscn` + `scenes/pickups/energy_orb.tscn`
- [x] T036 [US5] Create LootSystem: subscribe to `EventBus.enemy_died`; if `over_pit == true`: return (no orb); else: pick orb type (50/50 via `randi() % 2`), instantiate correct orb scene at `Vector3(world_pos.x, floor_y, world_pos.z)` (floor Y from tile surface), add to scene tree — `scripts/systems/loot_system.gd`
- [x] T037 [US5] Implement orb collection in loot_orb.gd: on `Area3D.body_entered` with player body: check `player.current_state is State_Ground`; if false: ignore; if true: apply restore (`health = min(health + restore_amount, 100)` or `energy = min(energy + restore_amount, 100)`), emit `EventBus.player_health_changed` or `player_energy_changed`, `queue_free()` — `scripts/pickups/loot_orb.gd`

**Checkpoint**: All 5 user stories independently functional. Core prototype is complete.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Game feel, Game Over flow, Debug HUD — affects multiple user stories.

- [x] T038 [P] Implement Game Over screen: subscribe to `EventBus.game_over(waves_survived, elapsed_seconds)`; display "GAME OVER", waves survived count, elapsed time formatted as MM:SS; auto-restart by calling `get_tree().reload_current_scene()` after 4 seconds — `scenes/ui/game_over.tscn` + `scripts/ui/game_over_screen.gd`
- [x] T039 [P] Low energy warning: in hud.gd subscribe to `EventBus.player_energy_changed`; if `energy < 20` set energy bar modulate to flash (alternate alpha via `sin(Time.get_ticks_msec())`) and show screen vignette `ColorRect`; revert when energy ≥ 20 — `scripts/ui/hud.gd`
- [x] T040 [P] Game feel — screen shake on Slam/Spin hit: in proxy_camera.gd, on `EventBus.player_state_changed` (or direct call), add random offset to camera position for 0.15s (Slam) / 0.10s (Spin), lerp back to target — `scripts/camera/proxy_camera.gd`
- [x] T041 [P] Game feel — hit-flash on enemy damage: in grunt.gd and drone.gd, on `take_damage()` call: set `MeshInstance3D` material to solid white for one physics frame, then revert — `scripts/enemies/grunt.gd` + `scripts/enemies/drone.gd`
- [x] T042 [P] Game feel — freeze-frame on kill: in loot_system.gd (or GameFeel autoload), on `EventBus.enemy_died`: set `Engine.time_scale = 0.05` for 0.05 real seconds via `await get_tree().create_timer(0.05, true).timeout`, then restore `Engine.time_scale = 1.0` — `scripts/systems/loot_system.gd`
- [x] T043 [P] Game feel — knockback dust: add `GPUParticles3D` child to Grunt scene; emit a brief burst when knockback velocity is applied (call `particles.restart()` from grunt.gd on knockback) — `scenes/enemies/grunt.tscn`
- [x] T044 Create Debug HUD: toggleable `CanvasLayer` (press Tab); buttons/labels for: Spawn Grunt at cursor, Spawn Drone at cursor, Kill All Enemies, Wave Skip (spinbox), God Mode toggle, Infinite Energy toggle, Floor Reset, Show Hitboxes (toggle `get_tree().debug_collisions_hint`), Show Pathfinding (draw A* grid), Show Aggro Ranges; on-screen stats label showing HP, Energy, Wave, Enemy Count, Tiles Destroyed % — `scenes/ui/debug_hud.tscn` + `scripts/ui/debug_hud.gd`
- [x] T045 Run quickstart.md validation: open `project.godot` in Godot 4.1+, press F5, verify room loads, Wave 1 starts, gamepad input maps correctly, all debug HUD tools functional, Game Over summary displays correctly and auto-restarts

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — start immediately
- **Phase 2 (Foundational)**: Depends on Phase 1 — blocks all user story phases
- **Phase 3 (US1)**: Depends on Phase 2 — no dependency on other user stories
- **Phase 4 (US2)**: Depends on Phase 3 (US1 player must exist before attacks can be wired)
- **Phase 5 (US3)**: Depends on Phase 2 + T016 (SlamHitbox) from Phase 4
- **Phase 6 (US4)**: Depends on Phase 2 + Phase 4 complete (enemies need combat system to deal/take damage)
- **Phase 7 (US5)**: Depends on Phase 6 (enemy_died signal must exist)
- **Phase 8 (Polish)**: Depends on all user story phases complete

### Within-Phase Parallel Opportunities

**Phase 2**: T004, T005, T007, T008 can all run in parallel after T003 (EventBus must exist first).

**Phase 3**: T010 (State_Ground) and T011 (State_Air) and T014 (Camera) can be written in parallel; T009 (Controller shell) must exist first; T012, T013, T015 depend on both states existing.

**Phase 4**: T016 (Slam), T017 (Spin), T019 (Machine Gun), T020 (Projectile) can all be written in parallel; T018 and T022 wire them together afterward.

**Phase 5**: T024→T025 must be sequential; T026 and T027 can run in parallel after T024.

**Phase 6**: T028+T029 (Grunt) and T030+T031 (Drone) are fully parallel streams; T032 and T033 depend on both enemy types existing; T034 (main scene assembly) is last.

**Phase 7**: T035 (scenes) is parallel to T036 (LootSystem); T037 depends on both.

**Phase 8**: T038–T043 are all parallel. T044 (Debug HUD) is independent. T045 (validation) is last.

---

## Parallel Execution Example: Phase 6 (Enemy + Wave)

```
Stream A — Grunt:
  T028 Create Grunt scene
  T029 Implement Grunt AI FSM

Stream B — Drone:
  T030 Create Drone scene
  T031 Implement Drone AI FSM

Both complete →
  T032 Wire enemy death signals (both scripts)
  T033 Create WaveManager
  T034 Assemble main.tscn
```

---

## Implementation Strategy

### MVP Scope (US1 only — Phases 1–3)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (EventBus, GridManager, Room, HUD)
3. Complete Phase 3: US1 (player movement + state switching + camera)
4. **STOP and VALIDATE**: Player moves, lifts off, drains energy, lands/falls correctly. Camera zooms. No enemies needed.

### Incremental Delivery

1. **Phases 1–3** → P.R.O.X.Y. moves and switches states *(MVP)*
2. **+ Phase 4** → Full combat and energy economy
3. **+ Phase 5** → Floor destruction and pits
4. **+ Phase 6** → Enemies and waves — prototype is now fully playable
5. **+ Phase 7** → Loot loop complete
6. **+ Phase 8** → Game Over flow, feel, and debug tools — ready for playtesting sessions

---

## Notes

- No automated tests — manual validation via debug HUD tools and playtesting checklist in `checklists/requirements.md`
- All balance values (damage, energy costs, speeds) are starting estimates; expect iteration after every playtest session
- Constitution is unfilled — run `/speckit.constitution` before starting implementation
- Commit after each phase checkpoint minimum; prefer per-task commits for easier rollback
- `[P]` tasks = different files, safe to work on simultaneously
- Debug HUD (T044) must never be bundled in a release build
