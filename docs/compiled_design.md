# SUBJECT 0 - Compiled Design and Mechanics

Compiled from all three branches: `mechanics/design-doc` (this build), `narrative/story`
(story, `levels.md`, `art_brief.md`) and `danish/art-concepts` (art guide, sprites).
Source docs stay as they are: `docs/design.md`, `narrative/*.md`, `assets/ART_GUIDE.md`.

## One line
A rejected half-machine boy, Tommy (Subject 0), climbs a dead city to a tower, collecting his
own stolen limbs, and at the top finds the memory of his home. Sad, quiet, gentle tone.

## Mechanics (what the build does today)
| Ability | Key | Behaviour |
|---|---|---|
| Run / jump | A/D, Space (Z) | Variable-height jump, coyote time, jump buffer. Without the leg: slow hop (0.55x speed, 0.6x jump). |
| Jet dash | Shift (X) | 8 directions, one charge, refills on landing. |
| Grapple (left arm) | Left click (aims at cursor), E/V (aims with direction keys) | Pulls you to walls, hooks and the thrown arm. One use until you land. Range 560. |
| Detach arm (right arm) | Q / C | Throw, stays where it lands, holds switches, is a grapple anchor. Press again to recall. Down+Q drops it. |
| X-ray eyes | F (toggle) | Reveals and activates hidden platforms and grapple hooks. |
| Respawn | R | Instant, same room. |
| Dialogue | Enter, Space or left click | Advances lines. |

Hazards: spikes, patrolling saws, crumbling platforms (all respawn you in the room).
Pickups: leg, grapple arm, jet legs, X-ray eyes (teal squares), data logs (yellow squares).

## Structure
- **Playable build (`scenes/main.tscn`, `scripts/game.gd`):** 14 single-screen rooms in 5 chapters
  (Lab 4, Street 3, Subway 3, Skyway 3, Tower 1). Rooms are in `scripts/rooms.gd`.
- **Narrative prototype (`scenes/narrative_game.tscn`):** partner's 6-level ASCII-map version with
  the boss and ending. Maps are in `scripts/levels_data.gd`. Kept as a separate scene.
- Difficulty ramp: Lab has no hazards, Street adds spikes, Subway adds saws with X-ray puzzles,
  Skyway adds crumbling platforms, Tower combines everything.

## Story structure (narrative branch, now the canonical plan)
6 levels, one new limb each, replacing the old 5-chapter table:
| Lvl | Place | New limb | Ability |
|---|---|---|---|
| 1 | The Lab | Spring leg | Jump |
| 2 | Street Level | Detachable arm | Throw onto switches |
| 3 | Subway | Eye / head module | X-ray |
| 4 | Skyway | Grapple arm | Grapple to anchors |
| 5 | Tower Core | Jet legs | Air dash |
| 6 | The Roof | none | Boss: THE UPGRADE, then the memory and the TOMMY end card |

## Art (art branch)
Pixel art, 16x16 tiles, 32x32 hero. Palette is grey, with one warm accent added per level.
`assets/sprites/player/player_walk.png` is a 4-frame walk cycle (1024x1024 sheet, background
not transparent yet). Not used in the build yet.

## Conflicts to settle as a team
1. **Limb order.** Build gives the arm in Lab 3 and grapple in Lab 4; the story gives one limb per
   level (arm L2, eye L3, grapple L4, jet L5).
2. **Keys differ between the two versions.** Arm: Q (build) vs E (prototype). X-ray: F toggle vs
   hold X. Grapple: click/E vs F. Dash: Shift/X vs Shift. Pick one scheme.
3. **Level count.** 14 rooms in 5 chapters vs 6 levels with a boss. The boss and ending exist only
   in the prototype.
4. **Resolution.** Art guide says 320x180 scaled 4x; the project is 1280x720 with no pixel snap.
5. **Art guide level themes** (forest, caves, frozen, fungal, lava) do not match the story's
   places (lab, street, subway, skyway, tower). The old concept level PNGs were removed by the
   art branch.
6. **Hero name.** Subject 0 / Tommy in the story; the old design doc listed it as open.
