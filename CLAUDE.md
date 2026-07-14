# CLAUDE.md

## Default workflow — delegate through Warboss

Code changes beyond trivial edits get sliced into decided units and dispatched
via the `/warboss-horde:delegate` skill to doer subagents; the dispatcher
judges results by running the paired headless test. Inline work only for
one-line edits, read-only Q&A, investigation.

## What this is

Trickshot is a Godot 4.7 VR trickshot playground for Meta Quest 2. The player
stands in place (room-scale, no artificial locomotion — comfort-first, owner
gets motion sick) and grabs and throws balls and frisbees at targets for
points. Bow and arrow is a stretch goal. The comfort constraint is a hard
design rule, not a preference.

## Commands

Godot exe on this machine: `C:\Users\SCora\Desktop\Godot_v4.7-stable_win64.exe`
(referred to as `godot` below).

- Run game: `godot --path .`
- Re-import after adding class_name scripts: `godot --headless --xr-mode off --path . --import`
  (new `class_name` registrations are not visible to tests until re-import —
  same gotcha applies here)
- Run one test: `godot --headless --xr-mode off --path . --script res://scripts/test_throw_sampler.gd`
- --xr-mode off is required for all headless runs: a system OpenXR runtime (Quest Link) is active on this machine and headless OpenXR init segfaults without it.
- Tests print `ALL_PASS` or `FAILURES=n` on the last line.

## VR constraints (do not break)

- Renderer must stay `gl_compatibility` (Forward+ won't ship on Quest 2)
- `physics_ticks_per_second` stays 72
- No realtime shadows, minimal transparency/overdraw
- NO smooth artificial locomotion ever
- Headless runs have no XR — XR code paths must degrade (see `scripts/main.gd`
  desktop fallback)
- On-device iteration via Quest Link (desktop OpenXR) before Android sideload

## Architecture

Pure logic (RefCounted `class_name` modules, no nodes) is kept separate from
the scene/node layer. Every rule expressible as data + pass/fail check gets a
static module + `test_*.gd` + spec in `specs/`. XR interaction (grab/throw/
teleport) comes from `addons/godot-xr-tools` — prefer wiring its nodes over
reimplementing.

## Specs

`specs/` holds one `<feature>.spec.md` per system paired 1:1 with a headless
test. Start at `specs/README.md`.
