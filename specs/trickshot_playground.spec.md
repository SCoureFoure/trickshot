# Spec: Trickshot playground (game design)

## Requirement

A simple VR playground: pick up balls/frisbees from racks, throw them at
targets, score points. Sessions are short pick-up-and-play. Zero motion
sickness by design.

## Design decisions (pinned)

- Player never translates artificially (stand/room-scale; optional
  teleport-to-station later, never smooth-stick)
- 72 Hz minimum framerate is a hard budget — perf regressions are bugs
- Throw release uses windowed velocity averaging (see
  `throw_release_velocity.spec.md`)
- Objects respawn to racks rather than accumulate (bounded physics body
  count, target ≤ 24 active rigid bodies)
- Targets give immediate audio+visual feedback within 100 ms of hit

## Perf budget (Quest 2)

- ≤ 150 draw calls
- No realtime shadows, baked/ambient light
- MSAA 4x
- Fixed foveated rendering enabled
- No transparent overdraw stacks

## Acceptance criteria

- Playable start-to-throw within 5 s of app launch
- Ball throw lands where a real throw would intuitively go (tuned on device)
- Frisbee visibly glides and curves (not ballistic)
- Scoring visible in-world (no HUD stuck to face)
- Sustained 72 Hz on device with 24 active bodies

## Non-goals

- Multiplayer
- Progression/unlocks
- Smooth locomotion (never)
- Photorealism
