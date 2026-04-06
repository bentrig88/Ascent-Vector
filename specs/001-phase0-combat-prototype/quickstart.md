# Quickstart: Phase 0 Combat Prototype

**Branch**: `001-phase0-combat-prototype` | **Date**: 2026-04-06

---

## Prerequisites

- Godot 4.1 or later (download from godotengine.org)
- A gamepad (Xbox / PlayStation / Switch Pro) — keyboard + mouse works but is secondary for Phase 0
- No other dependencies — all systems use Godot 4 built-ins only

---

## Project Setup

1. Open Godot 4 and choose **Import**
2. Navigate to the `Ascent_Vector/` repository root and select `project.godot`
3. Click **Import & Edit**

---

## Running the Prototype

- Press **F5** (or the Play button) to launch from the main scene (`scenes/main.tscn`)
- The room loads immediately — no menu, no tutorial, Wave 1 begins after a brief delay

---

## Controls (Gamepad — PS5 / DualSense)

| Input | Action |
|---|---|
| Left Stick | Move P.R.O.X.Y. (screen-relative: up = screen-up) |
| Right Stick | Aim / face direction (Air Mode only) |
| L2 (axis, hold) | Jetpack thrust — hold to rise, release to descend |
| X Button | Heavy Slam (Ground Mode only) |
| O Button | Spin Attack (Ground Mode only) |
| R2 (axis, hold) | Fire Machine Gun (Air Mode only) |
| Approach Energy Plug + any button | Plug in to recharge |
| Any button (after 0.5 sec lock-in) | Unplug early |

> **Note (2026-04-06):** L2/R2 are mapped as joypad axes (4/5) with deadzone 0.3, not button presses. Ground Mode facing follows movement direction (left stick), not the right stick.

---

## Controls (Keyboard + Mouse)

| Input | Action |
|---|---|
| WASD | Move (screen-relative: W = screen-up) |
| Mouse | Aim / face direction |
| Hold Space | Enter Air Mode |
| Release Space | Begin descent |
| Left Click | Heavy Slam / Fire Machine Gun (context-dependent) |
| Right Click | Spin Attack (Ground Mode) |
| E near plug | Plug in |

*Keyboard bindings are approximate — finalise in Project Settings > Input Map.*

> **Note (2026-04-06):** Movement input is rotated +45° around Y axis so that pressing "up" moves the character toward the top of the screen in the isometric view, not along world-space north.

---

## Debug HUD

Press **Tab** (or assign in Input Map) to toggle the debug overlay. Available tools:

| Tool | Function |
|---|---|
| Spawn Grunt | Place a Grunt at cursor position |
| Spawn Drone | Place a Drone at cursor position |
| Kill All | Instantly despawn all active enemies |
| Wave Skip | Jump to any wave number |
| God Mode | Toggle invincibility |
| Infinite Energy | Toggle unlimited energy (independent of God Mode) |
| Floor Reset | Restore all tiles to full HP |
| Show Hitboxes | Toggle collision shape visibility |
| Show Pathfinding | Toggle A* grid and Grunt path visualisation |
| Show Aggro Ranges | Toggle enemy detection and attack range indicators |
| On-Screen Stats | Real-time HP, energy, wave number, enemy count, tiles destroyed % |

---

## Playtesting Checklist

After each session, use `specs/001-phase0-combat-prototype/checklists/requirements.md` and the tuning checklist from the Balance Sheet to record observations. Update balance values in the Balance Sheet doc with findings.

Key things to watch:
- Does a run last 3–5 minutes? (SC-001)
- Does the Slam feel like the obvious choice for Grunts? (SC-002)
- Is the Energy Plug scary to use? (SC-004)
- Does floor destruction stay below 40% per wave? (SC-003)
