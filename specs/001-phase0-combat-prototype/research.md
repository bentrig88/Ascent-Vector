# Research: Phase 0 Combat Prototype

**Branch**: `001-phase0-combat-prototype` | **Date**: 2026-04-05  
**Phase**: 0 — Resolve all NEEDS CLARIFICATION from Technical Context

---

## Decision 1: Player FSM Architecture

**Decision**: Inner-class FSM inside `player_controller.gd`

**Rationale**: For a two-state FSM (State_Ground, State_Air), inner classes keep related physics logic co-located without the overhead of separate script files or node hierarchies. Each state owns its `physics_process(delta)` implementation; the parent CharacterBody3D delegates to `current_state.physics_process(delta)` each tick. State transitions call `current_state.exit()` then `current_state.enter()` on the new state.

**Alternatives considered**:
- *Separate script files per state*: Better for large FSMs (5+ states) but overkill for two states; adds file-switching overhead during development.
- *Node-based state machine (AnimationTree or custom)*: More visual but requires additional node overhead; inner classes are simpler for a prototype.

**Key implementation notes**:
- The jetpack input is checked at the `player_controller` level, not inside states — it is silently discarded during animation lock (FR-009).
- Input buffering for chained attacks uses a `buffer_timer: float` within State_Ground. Buffer is only active for attack-to-attack chaining; state-switch inputs are never buffered.
- Facing direction (right stick) is read in State_Ground and applied as a `facing_vector` on the parent node, independent of `velocity`.

---

## Decision 2: Grid Pathfinding

**Decision**: `AStarGrid2D` with a 10×10 region and 2×2 cell size

**Rationale**: AStarGrid2D is purpose-built for tile grids in Godot 4. Tile destruction at runtime requires only `astar.set_point_solid(Vector2i(x, y), true)` — no navigation mesh rebake, no server call. Path queries return a `PackedVector2Array` of tile-centre positions; Grunts use these as waypoints for smooth continuous movement (GPS approach described in GDD 8.2). At 10×10 scale, recalculation on tile destruction is negligible in cost.

**Alternatives considered**:
- *NavigationServer3D*: Designed for 3D continuous environments with baked NavMesh. Tile destruction requires partial rebake — expensive and unnecessary for a 10×10 grid.
- *Manual BFS/Dijkstra*: Viable at this scale but AStarGrid2D is already in the engine with heuristic optimisation; no reason to reimplement.

**Key implementation notes**:
- `GridManager` owns the single `AStarGrid2D` instance and emits `tile_destroyed(tile_pos)` when HP hits 0, then calls `set_point_solid`.
- All active Grunts listen to `tile_destroyed` and recalculate their path on the next pathfinding tick (~100ms polling interval is sufficient).
- Spawn-validity checks query `not astar.is_point_solid(pos)` before placing enemies.

---

## Decision 3: Input Buffering

**Decision**: Per-state `buffer_timer: float` + queued action string within State_Ground

**Rationale**: A simple float timer is the lightest implementation and directly maps to the spec's "0.2-second window at the tail end of an animation." No separate node, queue array, or signal needed. The buffer is reset on state exit so no stale inputs carry over to Air Mode.

**Alternatives considered**:
- *Action queue array*: More general but adds complexity not warranted by two attack types.
- *AnimationPlayer callback*: Would work but couples input logic to animation timings; harder to adjust during balance iteration.

**Key implementation notes**:
- `buffer_timer` counts down from attack animation duration (0.8 sec Slam, 0.6 sec Spin).
- Input registered when `buffer_timer > 0` but `buffer_timer <= 0.2` queues the next attack.
- Jetpack input is explicitly **not buffered** in this system (FR-009); it is discarded during any positive `buffer_timer` value.

---

## Decision 4: Camera System

**Decision**: `Camera3D` with `PROJECTION_ORTHOGONAL`, `size` property lerped between two values on state switch

**Rationale**: Godot 4's orthographic `Camera3D` uses the `size` property (not FOV) to control zoom. Lerping `size` between ground_zoom (~6.0) and air_zoom (~10.0) over 0.5 seconds via a `zoom_lerp_timer` produces the smooth easing described in GDD 8.3. The camera's 3D position soft-follows P.R.O.X.Y. using `lerp()` each frame, clamped to room bounds. Isometric angle is set statically via node rotation (Y: 45°, X: ~30°).

**Alternatives considered**:
- *SpringArm3D*: Useful for third-person cameras with collision avoidance, unnecessary here since the room is enclosed and the camera is fixed-angle.
- *Tween node for zoom*: Valid alternative; timer-based lerp chosen to keep the camera script self-contained without external node dependencies.

**Key implementation notes**:
- Room bounds are passed to `proxy_camera.gd` as an `AABB` exported variable set in the Room scene.
- Zoom state switch is triggered by the EventBus signal `player_state_changed(new_state)`.
- Easing is linear lerp — the "ease in-out" feel noted in the GDD can be approximated with `smoothstep()` on the lerp `t` value.

---

## Decision 5: Knockback System

**Decision**: Standalone `knockback_system.gd` autoload that applies velocity impulses via `CharacterBody3D.velocity`

**Rationale**: Centralising knockback in one place ensures the simultaneous-hit rule (only one knockback applied per 0.3-sec cooldown window, FR-031) is enforced consistently regardless of attack source. The system receives attacker position + force, calculates displacement direction, scales by target mass, and applies directly to the target's velocity for one physics frame.

**Alternatives considered**:
- *Per-entity knockback handling*: Simpler initially but requires duplicating cooldown logic across Grunt, Drone, and Player scripts.
- *RigidBody3D physics*: Would give "free" impulse behaviour but RigidBody conflicts with CharacterBody3D movement control needed for precise grid navigation.

**Key implementation notes**:
- Knockback force = `(force_tiles * tile_size) / (mass * physics_delta)` applied as a velocity addition for one frame.
- Cooldown tracked per-entity as a `knockback_cooldown: float` countdown.
- After displacement, `GridManager.is_over_pit(position)` is checked; if true, the fall sequence triggers.
