# Implementation Plan: Phase 0 Combat Prototype

**Branch**: `001-phase0-combat-prototype` | **Date**: 2026-04-05 | **Spec**: [spec.md](spec.md)  
**Input**: Feature specification from `specs/001-phase0-combat-prototype/spec.md`

---

## Summary

Build the Ascent Vector Phase 0 vertical slice: a single enclosed 3D isometric room where the player controls P.R.O.X.Y., a combat droid with two mutually exclusive states — Ground Mode (free melee, slower) and Air Mode (costly ranged, faster). The core tension is an energy economy that constantly pressures the player to land. The prototype runs as an endless wave sandbox (no win condition) used to validate balance figures from the GDD v0.3 Balance Sheet.

**Technical approach**: Godot 4.x project in GDScript. Inner-class FSM for the player controller. AStarGrid2D for Grunt pathfinding on the 10×10 tile grid. CharacterBody3D + `move_and_slide()` for physics and knockback. Orthographic Camera3D with lerp-based zoom switching between modes. Signal-driven event architecture for all gameplay chains (enemy death, tile break, wave clear, etc.).

---

## Technical Context

**Language/Version**: GDScript / Godot 4.x (4.1+)  
**Primary Dependencies**: Godot 4 built-ins only — CharacterBody3D, AStarGrid2D, Area3D, Camera3D (orthographic), AnimationPlayer  
**Storage**: N/A — no persistence between runs in Phase 0  
**Testing**: Manual playtesting via in-engine debug HUD; no automated test framework in Phase 0  
**Target Platform**: PC desktop (Windows/macOS/Linux); gamepad required, keyboard + mouse secondary  
**Project Type**: 3D action game prototype  
**Performance Goals**: Stable 60 fps with up to 8 enemies, full 10×10 tile physics grid, and active projectiles  
**Constraints**: Single room, max 8 simultaneous enemies, 10×10 tile grid (100 tiles), offline only  
**Scale/Scope**: Phase 0 prototype — one room, endless waves, ~3–5 min runs

---

## Constitution Check

> **⚠️ NOTE**: `memory/constitution.md` contains only placeholder text — no project-specific principles have been ratified yet. Constitution check cannot be performed against real gates. Proceeding without violations. **Action required**: run `/speckit.constitution` to define project principles before Phase 1 development begins.

No violations to justify.

---

## Project Structure

### Documentation (this feature)

```text
specs/001-phase0-combat-prototype/
├── plan.md              ← this file
├── research.md          ← Phase 0 output
├── data-model.md        ← Phase 1 output
├── quickstart.md        ← Phase 1 output
├── contracts/
│   └── signals.md       ← Phase 1 output (event/signal architecture)
├── checklists/
│   └── requirements.md
└── tasks.md             ← Phase 2 output (created by /speckit.tasks)
```

### Source Code (Godot 4 project root)

```text
project.godot

scenes/
├── main.tscn                     # Root scene: Room + WaveManager + HUD
├── player/
│   └── proxy.tscn                # P.R.O.X.Y. CharacterBody3D + FSM + camera
├── enemies/
│   ├── grunt.tscn                # Grunt CharacterBody3D + AI
│   └── drone.tscn                # Drone CharacterBody3D (gravity-free) + AI
├── environment/
│   ├── room.tscn                 # Walls, floor grid anchor, Energy Plug position
│   ├── floor_tile.tscn           # Individual StaticBody3D tile with HP
│   └── energy_plug.tscn          # Wall-mounted Area3D recharge station
├── pickups/
│   ├── health_orb.tscn           # Area3D pickup (+15 HP)
│   └── energy_orb.tscn           # Area3D pickup (+20 energy)
└── ui/
    ├── hud.tscn                  # Health bar, energy bar, wave counter
    ├── game_over.tscn            # End-of-run summary overlay
    └── debug_hud.tscn            # Dev-only toggle overlay

scripts/
├── player/
│   ├── player_controller.gd     # CharacterBody3D + inner-class FSM entry point
│   ├── state_ground.gd          # Ground state: movement, Slam, Spin, facing
│   └── state_air.gd             # Air state: hover, energy drain, Machine Gun
├── enemies/
│   ├── grunt.gd                 # Chase/Attack FSM + AStarGrid2D pathfinding
│   └── drone.gd                 # Kite/Flee/Shoot FSM + spread enforcement
├── weapons/
│   ├── slam_hitbox.gd           # Area3D: forward arc damage + tile damage
│   ├── spin_hitbox.gd           # Area3D: 360° damage, no tile damage
│   └── projectile.gd            # Drone bullet: kinematic, deals damage on hit
├── systems/
│   ├── grid_manager.gd          # 10×10 AStarGrid2D, tile HP, pit Area3D spawning
│   ├── wave_manager.gd          # Wave composition, spawn logic, delay timer
│   ├── knockback_system.gd      # Mass-based force application, cooldown tracking
│   ├── loot_system.gd           # Orb type selection, pit-check, spawn
│   └── session_tracker.gd       # Elapsed time, wave count for Game Over summary
├── environment/
│   ├── floor_tile.gd            # Tile HP, crack visual, destruction + signal emit
│   └── energy_plug.gd           # Lock-in timer, recharge loop, cancel logic
├── pickups/
│   └── loot_orb.gd              # Collection detection (Ground Mode only)
├── camera/
│   └── proxy_camera.gd          # Soft-follow, room clamp, orthographic zoom lerp
└── ui/
    ├── hud.gd                   # Reacts to HP/energy/wave signals
    ├── game_over_screen.gd      # Displays summary, triggers auto-restart
    └── debug_hud.gd             # Spawner, god mode, infinite energy, floor reset, etc.

autoloads/
└── event_bus.gd                 # Global signal bus (see contracts/signals.md)
```

**Structure Decision**: Single Godot 4 project. All gameplay systems are scene-instanced nodes communicating via a global `EventBus` autoload (decoupled signal architecture). No external packages — Godot built-ins only. Debug HUD is a separate scene toggled by a keypress and never ships.

---

---

## Session 2026-04-06 — Architecture Updates

### Player Scene Hierarchy (proxy.tscn)

The player scene uses a two-level pivot for sword rotation to separate code-driven facing from animation-driven swing:

```text
Proxy (CharacterBody3D)
├── CollisionShape3D
├── MeshInstance3D (body)
├── FaceMarker (dark sphere — facing indicator)
├── SwordFacingPivot (Node3D — rotation.y set by code to match facing_vector)
│   └── SwordPivot (Node3D — animated by AnimationPlayer for slam/spin)
│       ├── SwordBlade (MeshInstance3D)
│       ├── SwordHandle (MeshInstance3D)
│       └── SlamHitbox (Area3D — activated via AnimationPlayer method call track)
├── SpinHitbox (Area3D — activated from state_ground.gd code)
├── AnimationPlayer (animations: slam, spin, RESET)
├── ProxyCamera (Camera3D — top_level=true, orthographic)
├── StateGround (Node)
└── StateAir (Node)
```

### Key Architectural Decisions

- **Screen-relative movement**: All movement input is rotated +45° around Y axis (`raw.rotated(Vector3.UP, deg_to_rad(45.0))`) so that pressing "up" moves toward the top of the isometric screen.
- **Camera detached**: `ProxyCamera` uses `top_level = true` and computes its own offset from `global_transform.basis.z * 40.0` to stay centered in orthographic view.
- **Slam hitbox timing**: Activated via AnimationPlayer method call track at t=0.23s (when sword hits ground), not from code on button press.
- **Grid pathfinding**: `get_nav_path()` with `cell_size = (1, 1)` — coordinates are grid indices, not world units.
- **Invisible walls**: South and East walls have collision but no mesh (`show_mesh=false`) to prevent camera occlusion in the isometric view.

---

## Complexity Tracking

*No constitution violations — section not applicable.*
