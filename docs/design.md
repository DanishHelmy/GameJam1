# Design Doc (draft)

Working title: **Salvage** (placeholder)

## Pitch
A Celeste-style precision platformer set in a ruined downtown. You are a cyborg,
roughly 80% machine, who wakes up in an abandoned lab missing a leg and an arm.
Your robotic limbs each have a job: springy legs for movement, a grapple arm for
reach, and a detachable arm for puzzles.

## The body (fixed kit, no part swapping)
| Part | Ability | Trade-off |
|------|---------|-----------|
| Spring legs (both) | Higher variable jump, bounce off springy pads, strong wall jump | Slower run speed, harder to land precisely |
| Left arm (grapple) | Fire in the aimed direction at walls, floors, ceilings, hooks or the thrown arm, and pull yourself to the hit point | Limited range, one use until you land, needs line of sight |
| Right arm (detachable) | Throw it, it stays where it lands and works on its own (holds switches, triggers sensors, acts as a platform or anchor) | While detached you lose that arm's use; must recall or retrieve it |
| Jet legs (dash) | 8-direction dash with jet flame effect | One charge, refills on landing |
| Torso / head | Core, fixed | None |

Scope note: three abilities instead of a swap system. Easier to build, easier to
teach, and every level can use all of them.

## Core movement
- Run, variable-height jump (spring legs), coyote time, jump buffering,
  corner correction.
- Instant respawn at room start. Single-screen rooms.
- Grapple: aim, fire, swing, release for momentum. Limited charge refills on
  touching ground.

## Jet dash (legs)
- Celeste-style dash with a jet flame effect from the legs.
- 8 directions, aim with the direction keys. One charge, refills on landing.
- Can dash-jump off the ground for extra distance.
- Dashing cancels a grapple pull, and a pull does not spend the dash.

## Detach mechanic (the signature twist)
- Press **Arm** to throw the arm in the aimed direction (Down + Arm drops it at
  your feet). It flies in an arc and lands where it hits a surface.
- Detached arm can: hold down pressure switches, trip sensors, block a laser,
  or serve as a grapple anchor for the other arm.
- Press **Arm** again to recall it. It flies back to you and re-attaches.
- Puzzle shape: leave the arm on a switch, cross using the legs and grapple,
  then get it back later by a different route.
- Combo: detach the arm, then grapple to it.

## Opening (Chapter 0: The Lab)
- You wake on an operating table with a leg and an arm missing.
- Start with the right (detachable) arm and one spring leg. Movement is limited: slow
  hop, no grapple.
- Rooms:
  1. Hop and drag across the floor (base movement).
  2. Find the **missing left leg** in a storage locker. Full spring jump unlocked.
  3. Learn **detach**: throw the arm onto a switch to open a door.
  4. Find the **left (grapple) arm** in a broken containment pod. Swing to the exit.
- Environmental storytelling: lab logs, your patient file, other empty pods.

## Level structure
Chapters, each themed on a district, with ~5 rooms each:
0. **The Lab** - tutorial, recover leg and grapple arm, learn detach.
1. **Street Level** - spring jumps over collapsed road gaps, bounce pads.
2. **Collapsed Subway** - dark and flooded, detach puzzles with switches.
3. **Broken Skyway** - heights and gaps, grapple swings, grapple to detached arm.
4. **The Tower Core** - mixes all three abilities, final climb.

## Story outline
**Premise:** You wake in an abandoned lab with a leg and an arm missing and no
memory of why. Outside, the downtown is ruined and silent. A faint signal comes
from the top of the central tower, and the lab's logs hint your missing parts
were taken, not lost.

**Beats**
0. *The Lab:* You wake up broken. Logs show you were a test subject, patient
   file partly wiped. You recover your limbs and escape.
1. *The Street:* A looping city-AI announcement plays over the ruins. You see
   the signal tower for the first time and set out for it.
2. *The Subway:* Other cyborgs lie dead here. Their logs show they were subjects
   like you, upgraded far past the point of being human.
3. *The Skyway:* A friendly drone, the only other thing still working, joins you
   and tells you what happened: the district was evacuated, and the subjects
   were left behind.
4. *The Tower:* The signal is a recorded "all clear" that was never sent. You
   learn how much of you is still human. You choose to broadcast it. Ending:
   the city's lights come back on, or you stay as the last unit. (Pick one for
   the jam.)

**Collectibles:** Data logs in hidden spots, 2-3 per chapter, that fill in the
evacuation and experiment story.

**Theme:** What remains of a person after the body is replaced.

## Open questions
- Assumed: right arm detachable, left arm grapple, left leg is the missing one
  recovered in the lab. Confirm.
- Official jam theme, to check this fits.
- ~~Protagonist name and tone~~ Decided in `narrative/`: hero is Subject 0 (Tommy, revealed at the end), sad and quiet tone; drone is Pip.
- Art guide lists 6 levels (surface, caves, frozen, fungal, lava, boss); story lists 5 chapters. Reconcile.
- Why were the limbs removed, and who took them? (Needs an answer by the tower.)
- Art style and who handles sprites.
- Final ending choice.
