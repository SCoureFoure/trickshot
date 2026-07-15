# Trickshot

Godot 4.7 VR trickshot playground for Meta Quest 2 (OpenXR, gl_compatibility renderer, 72 Hz physics). Room-scale only, zero artificial locomotion—comfort-first design for standing or seated play within reach.

## Features

- Four ball types (bouncy, beach, heavy, baseball) with distinct physics defined in `scripts/ball_types.gd`
- Throw system using release-velocity sampling via `ThrowSampler` to smooth tracking jitter
- Scoring target with ring-based points, hit flash and beep; scores balls and arrows
- Poke-button panel: RESET button (full scene reset) and spawn buttons for each ball type; buttons respond to finger poke or thrown ball impacts, with spawn cap via `SpawnBudget`
- Bounce wall on left side for ricochet shots
- Collision hands with physical presence in world and poke fingers (no pickable-shoving)
- Bow and arrow: two-hand draw (grip + string), KayKit CC0 models, procedural two-segment string with visible bend, nocked-arrow visual, draw dead zone, arrows stick on impact and despawn after 10 seconds
- Medieval archery-range environment (KayKit Hexagon pack, CC0) in `scenes/range_environment.tscn`
- Anti-tunneling via thick static colliders (CCD off by design—kills bounce)

## Running

1. Quest Link session active (Meta Horizon Link as OpenXR runtime)
2. `godot --path .` to play; headless tests need `--headless --xr-mode off`
3. After adding `class_name` scripts: `godot --headless --xr-mode off --path . --import`

## Tests

Headless tests paired 1:1 with specs in `specs/`. Run one test: `godot --headless --xr-mode off --path . --script res://scripts/test_throw_sampler.gd`. Tests print `ALL_PASS` or `FAILURES=n`. Start at `specs/README.md` for system overview.

## Architecture

Pure-logic RefCounted modules (scripts with `class_name`, no nodes) separated from scene layer. Every rule has a spec and paired headless test.

## Assets

`assets/kaykit/` and `assets/kaykit_hex/` — KayKit packs by Kay Lousberg, CC0 with license files included.
