# Ascent_Vector Development Guidelines

Auto-generated from all feature plans. Last updated: 2026-04-05

## Active Technologies

- GDScript / Godot 4.x (4.1+) + Godot 4 built-ins only — CharacterBody3D, AStarGrid2D, Area3D, Camera3D (orthographic), AnimationPlayer (001-phase0-combat-prototype)

## Project Structure

```text
project.godot
scenes/          # Godot scene files (.tscn)
scripts/         # GDScript files (.gd)
autoloads/       # Global singletons (EventBus)
```

See `specs/001-phase0-combat-prototype/plan.md` for full directory layout.

## Commands

# Run: Open project.godot in Godot 4, press F5
# No build step required — Godot interprets GDScript directly

## Code Style

GDScript / Godot 4.x (4.1+): Follow standard conventions

## Code Principles

- **Reuse shared code via base classes and subclasses.** When multiple entities share common logic (e.g. enemies sharing health, damage, death, health bars), extract shared behavior into a base class and have each type extend it with overrides. Avoid duplicating the same logic across scripts.
- **Create reusable scenes for shared UI/visuals.** When the same visual component appears on multiple entities (e.g. health bars), make it a standalone scene with exports, not inline code per entity.

## Entity Hierarchy

```
Entity (scripts/entities/entity.gd) — CharacterBody3D
├── health, knockback_cooldown, die_in_pit()
├── EnemyBase (scripts/enemies/enemy_base.gd)
│   ├── health bar, take_damage, flash_hit, stagger, _die()
│   ├── Grunt (scripts/enemies/grunt.gd)
│   └── Drone (scripts/enemies/drone.gd)
└── PlayerController (scripts/player/player_controller.gd)
    └── energy, god_mode, states, weapons, camera
```

## Recent Changes

- 001-phase0-combat-prototype: Added GDScript / Godot 4.x (4.1+) + Godot 4 built-ins only — CharacterBody3D, AStarGrid2D, Area3D, Camera3D (orthographic), AnimationPlayer

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
