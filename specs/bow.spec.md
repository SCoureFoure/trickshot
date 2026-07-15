# Spec: Bow scene

## Requirement

Two-hand bow. The first grabbing hand holds the grip (primary); the second
grabs the string (secondary). Draw ratio comes from BowDraw applied to the
distance between the two hands. Releasing the string at or above the fire
threshold spawns an arrow at the Spawn node and fires it; below the threshold
the arrow is quietly un-nocked.

## Design decisions (pinned)

- Grab order determines role, not grab-point mode: the first hand to grab
  becomes `_grip_hand`, the second becomes `_string_hand` — tracked via the
  bow's own `grabbed`/`released` signal handlers.
- Releasing the grip hand drops everything (clears both hands); releasing the
  string hand alone never clears `_grip_hand`.
- `second_hand_grab = 2` (`SecondHandGrab.SECOND`) is required for the second
  grab to register at all.
- `NOCK_PULL = 0.35` m: how far the string/nocked arrow slide back at full
  draw.
- `STRING_REST = 0.2` m: rest z of the string and nocked arrow in bow-local
  space (at the string, behind the grip).
- String/nock/string-grabs rest at z = 0.2 (at the string, not the grip).
- String is two unit-length segments (`StringTop` and `StringBottom`), each
  stretched from its limb tip to the nock position each frame; the bend
  appears naturally as the nock moves back with draw.
- Limb tip positions: `STRING_TIP_TOP = Vector3(0, 0.69, 0.21)`,
  `STRING_TIP_BOTTOM = Vector3(0, -0.69, 0.21)` (bow-local).
- Nocked and fired arrow meshes are flipped 180° on Y (tip flies first,
  fletching at string).
- Mass 1.2 kg; collision layer 5 (same as balls/arrows).
- Bow mesh basis remap: model Z→scene Y (limbs vertical), model X→scene −Z
  (belly bulk faces away, string side faces +Z), model Y→scene −X (thickness).
  Determinant +1. Tips toward +Z, belly toward −Z (awaits on-headset confirmation).
- Arrow spawns as a sibling of the bow (added to the bow's parent), not as a
  child of the bow.
- String/nocked-arrow grab points (`StringGrabLeft`/`StringGrabRight`) use
  `drive_position = 0.0`, `drive_angle = 0.0`, `drive_aim = 1.0` so the bow
  pivots toward the pulling hand without being dragged.
- `reset_to_home()` restores the bow's transform and zeroes velocities, for
  the scene reset button.

## Acceptance criteria

1. `scene_loads`: `scenes/bow.tscn` is a valid PackedScene that instantiates
   and can be added to the scene tree.
2. `script_is_bow_gd`: script resource_path is exactly `"res://scripts/bow.gd"`.
3. `second_hand_grab_enabled`: `bow.second_hand_grab == 2`.
4. `has_spawn_node`: `bow.get_node_or_null("Spawn") != null`.
5. `grab_points_configured`: exactly 2 children with a script ending
   `grab_point_hand.gd` and `mode == 1` (grip), and exactly 2 with
   `mode == 2` (string).
6. `draw_tracks_hands`: after grabbing with two hands 0.5 m apart,
   `abs(bow._draw - 1.0) < 0.0001`.
7. `nocked_arrow_visible_when_drawn`: `NockedArrow.visible == true` while
   drawn.
8. `fires_arrow_on_release`: releasing the string hand at draw 1.0 leaves
   exactly one node in group `"arrows"` with `linear_velocity.length()`
   approximately `30.0` (`BowDraw.arrow_speed(1.0)`).
9. `string_rest_offset_applied`: while drawn, the String node position z
   equals `STRING_REST + NOCK_PULL * _draw`.
10. `string_resets_after_fire`: after firing, `bow._draw == 0.0` and
   `NockedArrow.visible == false`.
11. `no_fire_below_threshold`: re-grabbing the string hand at 0.05 m
    separation and releasing produces no new arrow (still exactly 1 in
    group `"arrows"`).
12. `reset_restores_home`: displacing the bow then calling `reset_to_home()`
    restores the origin within 0.001 m.

## Test

`scripts/test_bow_scene.gd` — run:

```
godot --headless --xr-mode off --path . --script res://scripts/test_bow_scene.gd
```

Prints `ALL_PASS` on success or `FAILURES=n` on failure.

## Non-goals

Pull animation blending (needs an animated model; KayKit bow is static — the
string visual is procedural); hand poses; quiver/ammo limits (SpawnBudget
integration lives in main.gd).

## Tutorial alignment notes

- Hand-distance remap uses a rest dead zone (`BowDraw.REST_DISTANCE`).
- Collision hands/poke no longer push pickables (see playground spec/tests).
- AnimationTree pull-blend deliberately not adopted — the KayKit mesh has no
  animations, the procedural string stands in.
