# Trickshot

A room-scale VR trickshot playground for Meta Quest 2 — grab balls and
frisbees, throw them at targets, score points.

## Why

The owner gets motion sick. The game design removes vection entirely by
keeping the player stationary at all times, with performance targets tuned to
hold 72 Hz on Quest 2 hardware.

## Design rules

- Stationary / room-scale only — no artificial locomotion, ever
- 72 Hz floor — perf regressions are bugs, not tech debt
- Comfort > fidelity

## Roadmap

- [x] Project scaffold (OpenXR + XR Tools + CI-able headless tests)
- [ ] Grab + throw with velocity-averaged release
- [ ] Targets + scoring
- [ ] Frisbee aerodynamics (lift, drag, gyroscopic stability)
- [ ] Quest 2 Android export + sideload
- [ ] Stretch: bow and arrow

## Getting started

1. Open the project in Godot 4.7.
2. Enable Quest Link for desktop VR testing.
3. Press F5.

Run the headless test suite:

```
godot --headless --path . --script res://scripts/test_throw_sampler.gd
```

## Tech

- Godot 4.7
- GL Compatibility renderer
- OpenXR
- godot-xr-tools 4.5.1 (vendored)
- Jolt-style simple physics scenes
