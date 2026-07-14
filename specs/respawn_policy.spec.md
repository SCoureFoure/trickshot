# Spec: Respawn policy

## Requirement

Thrown objects return to their rack home so active rigid-body count stays
bounded (≤ 24 per `specs/trickshot_playground.spec.md`). A pure module decides
*when*; the ball node applies it.

## Design decisions (pinned)

- Floor threshold: y < −2.0 (strict).
- Rest timeout: 5.0 s (strict).
- Rest speed: 0.1 m/s (strict).
- Never-released sentinel: −1.0 seconds (< 0.0 always means never released).
- Held-wins rule: ball in player's grip never respawns regardless of state.
- Pure RefCounted module `RespawnPolicy`, no nodes, headless-testable.

## Acceptance criteria

- Held ball: `should_respawn(true, 10.0, -5.0, 0.0) == false` — player holding
  ball prevents respawn even if below floor.
- Floor rule for never-released: `should_respawn(false, -1.0, -2.5, 0.0) == true`
  — y below floor triggers respawn.
- Floor boundary strict: `should_respawn(false, -1.0, -2.0, 0.0) == false` —
  exactly y = −2.0 does not respawn.
- Rack ball at rest: `should_respawn(false, -1.0, 0.5, 0.0) == false` — never-
  released sentinel with no release means no respawn.
- Rested past timeout: `should_respawn(false, 6.0, 0.1, 0.05) == true` —
  released long enough and moving slowly triggers respawn.
- Timeout boundary strict: `should_respawn(false, 5.0, 0.1, 0.05) == false` —
  exactly 5.0 s does not trigger respawn.
- Speed boundary strict: `should_respawn(false, 6.0, 0.1, 0.1) == false` —
  speed exactly 0.1 m/s does not trigger respawn.
- Still moving: `should_respawn(false, 6.0, 0.1, 2.0) == false` — ball rolling
  at higher speed is not recalled even if timeout passed.
- Recently thrown: `should_respawn(false, 2.0, 0.1, 0.0) == false` — released
  and at rest but timeout not yet reached.

## Test

`scripts/test_respawn_policy.gd` — run:

```
godot --headless --xr-mode off --path . --script res://scripts/test_respawn_policy.gd
```

Prints `ALL_PASS` on success or `FAILURES=n` on failure.

## Non-goals

Respawn animation, scoring-triggered instant respawn.
