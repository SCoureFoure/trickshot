# Spec: Arrow nock snap zone

## Requirement

A grabbable arrow (`scenes/arrow_pickable.tscn`) loads the bow by snapping into
an `XRToolsSnapZone` (`NockZone`) at the nock. The zone accepts only objects in
group `"nockable"`. When the zone picks an arrow up it loads the bow
(`_loaded = true`); when it drops the arrow it unloads (`_loaded = false`). The
wiring is shared by both bows via `BowBase`.

## Design decisions (pinned)

- Grabbable arrow is a plain `XRToolsPickable` (`pickable.gd`), in group
  `"nockable"`, NOT group `"arrows"` — distinct from the fired projectile.
- `NockZone` instances `addons/godot-xr-tools/objects/snap_zone.tscn`,
  `snap_require = "nockable"`, `snap_mode = RANGE (1)`.
- `BowBase` connects `NockZone.has_picked_up -> load_arrow` and
  `has_dropped -> unload_arrow`.
- NockZone transform / grab_distance / snap_mode are on-headset tuning values,
  not asserted here.

## Acceptance criteria

1. `pickable_scene_loads`: `scenes/arrow_pickable.tscn` instantiates and can be
   added to the tree.
2. `pickable_is_grabbable`: its root `has_method("pick_up")` and
   `has_method("can_pick_up")` (it is an `XRToolsPickable`).
3. `pickable_in_nockable_group`: its root is in group `"nockable"` and NOT in
   group `"arrows"`.
4. `bow_has_nock_zone`: a `bow.tscn` instance has a child `NockZone` for which
   `is_xr_class("XRToolsSnapZone")` is true.
5. `nock_zone_requires_nockable`: that `NockZone.snap_require == "nockable"`.
6. `snap_loads_bow`: on a `bow.tscn` instance, emitting
   `NockZone.has_picked_up` (any arg) sets `bow._loaded == true`.
7. `drop_unloads_bow`: then emitting `NockZone.has_dropped` sets
   `bow._loaded == false`.
8. `oot_bow_nock_zone_wired`: on an `oot_bow.tscn` instance, emitting its
   `NockZone.has_picked_up` sets `bow._loaded == true`.

## Test

`scripts/test_arrow_nock_zone.gd` — run:

```
godot --headless --xr-mode off --path . --script res://scripts/test_arrow_nock_zone.gd
```

Prints `ALL_PASS` on success or `FAILURES=n` on failure.

## Non-goals

Physical overlap-snap behavior (on-headset); where loose arrows spawn
(quiver/rack); reconciling the snapped pickable with the procedural nocked-arrow
ghost visual.
