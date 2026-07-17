# Spec: Grabbable arrow (loose ammo)

## Requirement

A loose arrow (`scenes/arrow_pickable.tscn`) is an `XRToolsPickable` that falls
under gravity and freezes ("sticks") only when its tip strikes a surface —
raycast between successive tip positions, matching the fired arrow's no-CCD
stick. While held (hand or snap zone) it never sticks. It carries no lifetime /
self-cleanup (it is ammo, not a projectile).

## Design decisions (pinned)

- Script `scripts/arrow_pickable.gd` extends `XRToolsPickable`; in group
  `"nockable"`, NOT group `"arrows"`.
- Tip is local -Z at `tip_length` (0.25) from origin.
- Stick raycast runs `_last_tip -> _tip` each physics frame, excluding self.
- `is_picked_up()` short-circuits the stick; a stuck arrow stays stuck until
  grabbed (grabbing clears `freeze` via the pickable base).

## Acceptance criteria

1. `scene_loads`: `scenes/arrow_pickable.tscn` instantiates.
2. `script_is_arrow_pickable`: root script resource_path is exactly
   `"res://scripts/arrow_pickable.gd"`.
3. `is_pickable`: root `has_method("pick_up")` and `has_method("can_pick_up")`.
4. `in_nockable_group`: root is in group `"nockable"` and NOT `"arrows"`.
5. `plants_on_floor`: dropped tip-down above a static floor and stepped through
   physics frames, the arrow ends with `freeze == true` resting near the floor
   (y within [-0.1, 0.5]).
6. `no_floor_keeps_falling`: with no surface below, after the same stepping the
   arrow is NOT frozen (`freeze == false`) and has fallen (y below its start).

## Test

`scripts/test_arrow_pickable_scene.gd` — run:

```
godot --headless --xr-mode off --path . --script res://scripts/test_arrow_pickable_scene.gd
```

Prints `ALL_PASS` on success or `FAILURES=n` on failure.

## Non-goals

Nocking/snap behavior (arrow_nock_zone spec); orientation of planted arrows;
where loose arrows spawn.
