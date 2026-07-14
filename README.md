# Trickshot

A Godot 4.7 VR trickshot playground for Meta Quest 2. Stand in place, grab balls off a rack, and throw them at targets for points. Built comfort-first by design: room-scale only, no artificial smooth locomotion (hard rule—owner gets motion sick).

## Current Features

- 3 grabbable balls on a rack (godot-xr-tools pickable, grip to grab)
- Throw release velocity from windowed controller-position averaging (smooths tracking jitter)
- Ring target with 25/10/5 points (bullseye to outer ring), in-world floating score display, ring flash and beep on hit
- Balls auto-respawn to the rack when fallen out of world or at rest 5 seconds after a throw
- B/Y button on either controller resets all balls to the rack
- Low-poly hand models on both controllers

## Running (PCVR via Quest Link)

1. Godot 4.7 (standard build), Meta Quest Link app installed, headset connected via Link cable or Air Link
2. Set "Meta Horizon Link" as the active OpenXR runtime in the Link desktop app settings
3. With the Link session active: `godot --path .`
4. Without a headset the game falls back to a flat desktop preview

## Tests

Headless tests cover pure-logic modules and scenes; each has a paired spec in `specs/`.

- Run one test: `godot --headless --xr-mode off --path . --script res://scripts/test_throw_sampler.gd`
- `--xr-mode off` is mandatory for headless (required when an OpenXR runtime like Quest Link is active—otherwise it segfaults)
- After adding `class_name` scripts, re-import first: `godot --headless --xr-mode off --path . --import`
- Tests print `ALL_PASS` or `FAILURES=n` on the last line
- Start at `specs/README.md` for spec format and system overview

## Project Layout

- `scripts/` — game scripts, pure-logic modules (RefCounted, node-free), and their headless tests
- `scenes/` — main playground, ball, and target scenes
- `specs/` — one spec per system, paired 1:1 with headless tests
- `addons/godot-xr-tools/` — XR interaction toolkit (grab, throw, hand models)

## Quest 2 Constraints

gl_compatibility renderer, 72 Hz physics tick rate, no realtime shadows, maximum 24 active rigid bodies.

## Roadmap

More throwable types (different weights and sizes, frisbee with glide and curve physics), Android sideload build for standalone Quest, bow and arrow (stretch goal).
