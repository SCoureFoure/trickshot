# Spec: Bow hand roles

## Requirement

Hand-role assignment on the two-hand bow must be idempotent: a hand already
holding a role (grip or string) is ignored if it fires a second grab, so a
duplicate grab event cannot land the same hand in both slots and collapse the
draw to zero.

## Design decisions (pinned)

- First hand to grab an empty bow becomes `_grip_hand`; the next DIFFERENT hand
  becomes `_string_hand` (grab order sets role — unchanged).
- A grab from a hand equal to `_grip_hand` or `_string_hand` is a no-op.
- Behavior lives in `BowBase._on_bow_grabbed`, shared by both bows.

## Acceptance criteria

1. `first_grab_sets_grip`: after grabbing with handA on an ungrabbed bow,
   `_grip_hand == handA` and `_string_hand == null`.
2. `duplicate_grip_grab_ignored`: grabbing again with handA leaves
   `_string_hand == null` (handA not duplicated into the string slot).
3. `draw_stays_zero_on_duplicate`: after the duplicate grab, `_process(0.0)`
   leaves `_draw == 0.0` (not collapsed by a self-distance).
4. `second_hand_sets_string`: grabbing with a different handB then sets
   `_string_hand == handB`, and with the hands 0.5 m apart `_process(0.0)`
   gives `abs(_draw - 1.0) < 0.0001`.
5. `duplicate_string_grab_ignored`: grabbing again with handB does not change
   `_grip_hand` or `_string_hand`.

## Test

`scripts/test_bow_hand_roles.gd` — run:

```
godot --headless --xr-mode off --path . --script res://scripts/test_bow_hand_roles.gd
```

Prints `ALL_PASS` on success or `FAILURES=n` on failure.

## Non-goals

Role swapping (grip<->string) mid-draw; grab-point-based role selection.
