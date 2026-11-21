# SUBJECT 0 - Art Brief (for the artist)

Story in one line: a rejected half-machine boy, Tommy, climbs a dead city to a tower,
collecting his own stolen limbs, and at the top finds the memory of his home.
Full world: `levels.md`. Dialogue: `dialogue/`.

## Style
- Pixel art. Hero 32x32, tiles 16x16, 1280x720 view.
- Mood: quiet, sad, gentle. Rain, dead neon, empty streets.
- **Colour = progress.** L1 grey/blue-grey only. Each level adds ONE warm accent:
  L2 yellow door, L3 amber lamp, L4 orange sunset sky, L5 warm glow in cases, L6 fully warm.
- The only non-pixel image is the memory scene (soft, painted, warm).

## Hero (follow concept_robots.jpeg: round head, antenna, simple body, spring legs)
Hero sprite per level (cumulative):
| Lvl | Sprite state |
|---|---|
| 1 | Head + torso + one right arm, no legs (hops), then spring leg attached |
| 2 | + detachable left arm (separate small sprite: thrown arm, 16x16) |
| 3 | + visor/eye module on head (glows when X-ray is held) |
| 4 | Arm replaced by grapple arm (claw, like sketch) + rope line |
| 5 | + jet legs (flame trail 4 frames) |
| 6 | Full set |
Animations: idle, run, jump, fall, die (flash), respawn.

## Levels: background and props
1. **Lab** - white-grey tiles, flickering lamp, scrap bin, patient file screen "REJECTED", pod. Tiny house doodle on the wall.
2. **Street** - wet road, dead neon signs, bus stop, far tower with ONE lit window, yellow door.
3. **Subway** - dark tunnel, benches with dead cyborgs (sitting), amber lamp, hidden platforms (faint outline, only visible with X-ray).
4. **Skyway** - broken elevated roads, sunset sky, Pip the drone (small, round, one eye), grapple anchors (ring icons).
5. **Tower Core** - glass cases wall labelled "T.", cables, glow, jet leg case.
6. **Roof** - wind, antenna, transmitter. Boss THE UPGRADE: hero sprite, cold white/blue, no antenna, three glowing weak points.

## Recurring icon
The house: 8x8 icon (roof, door, one lit window). Appears on every limb case label.

## Needed UI
Dialogue box skin, limb icons (leg, arm, eye, grapple, jet) for a HUD row that fills as limbs are found, title screen "SUBJECT 0", end card "TOMMY".

## Memory scene (ending)
Dusk. A small house, a lit window, a door open. A boy (~8) on the path, looking back. Soft warm colours.
A sample is saved in `assets/sprites/memory_house.png`.
