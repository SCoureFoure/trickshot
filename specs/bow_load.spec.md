# Spec: Bow load state & dry-fire

## Requirement

The two-hand bow starts empty. An empty bow shows no nocked arrow and, when
drawn and released above the fire threshold, "dry fires": it plays a distinct
`DryFireSound` (not the twang `ReleaseSound`) and spawns no arrow. Calling
`load_arrow()` loads it; a loaded bow shows the nocked arrow while drawn and, on
a full-draw release, fires one real arrow and returns to empty. `unload_arrow()`
clears the load without firing. A sub-threshold release never fires, never
dry-fires, and leaves the load unchanged.

## Design decisions (pinned)

- State lives in `BowBase._loaded` (shared by both bows); default `false`.
- `load_arrow()` sets it true; `unload_arrow()` sets it false.
- Nocked-arrow visibility is `_draw > 0.0 and _loaded`.
- Firing (`_fire`) happens only on a full-draw release while loaded; it consumes
  the load (`_loaded` -> false).
- Dry fire (`_dry_fire`) happens on a full-draw release while empty; it plays
  `$DryFireSound` and spawns nothing.
- `DryFireSound` is an `AudioStreamPlayer3D` whose stream
  (`arrow_wood_impact.mp3`) is a placeholder, distinct from `ReleaseSound`'s
  twang. The audible thunk-vs-twang distinction is verified on-headset.

## Acceptance criteria

Driven through `res://scenes/bow.tscn` with two `Node3D` hands 0.5 m apart:

1. `starts_empty`: a freshly instantiated bow has `_loaded == false`.
2. `empty_no_nock_visual`: grab both hands, `load_arrow()` NOT called,
   `_process(0.0)` -> `NockedArrow.visible == false` even though `_draw` ~ 1.0.
3. `empty_release_dry_fires`: from that drawn empty state, releasing the string
   hand leaves ZERO nodes in group `"arrows"`.
4. `dry_fire_sound_wired`: `DryFireSound` is an `AudioStreamPlayer3D` with a
   non-null `AudioStreamMP3` stream, and that stream is NOT the same resource as
   `ReleaseSound.stream`.
5. `load_makes_nock_visible`: on a fresh bow, grab both hands, `load_arrow()`,
   `_process(0.0)` -> `NockedArrow.visible == true`.
6. `loaded_release_fires_one`: from that loaded drawn state, releasing the
   string hand leaves exactly ONE node in group `"arrows"` with
   `linear_velocity.length()` approx `30.0`.
7. `fire_consumes_load`: after that fire, `_loaded == false`.
8. `unload_clears`: on a loaded bow, `unload_arrow()` sets `_loaded == false`.
9. `subthreshold_keeps_load`: on a loaded bow, grab hands only 0.05 m apart,
   `_process(0.0)`, release the string hand -> no new arrow AND `_loaded` is
   still `true` (quiet un-nock does not consume the load).

## Test

`scripts/test_bow_load.gd` — run:

```
godot --headless --xr-mode off --path . --script res://scripts/test_bow_load.gd
```

Prints `ALL_PASS` on success or `FAILURES=n` on failure.

## Non-goals

Snap-zone / pickable-arrow wiring (Slice C2); quiver/ammo source; the actual
dry-fire audio asset (placeholder for now).
