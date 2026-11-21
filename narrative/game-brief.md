# SUBJECT 0 - Game Brief (DRAFT)

**Title:** SUBJECT 0 (working). On the ending card the title changes to **TOMMY**.
**Human name:** Tommy (the hero's name before the machine; revealed only in the ending).
**Genre / theme:** 2D precision platformer, Action. Sad, quiet tone.
Items marked **(?)** are my guesses.

## Objective
- **Player goal:** climb to the top of the central tower and reach the signal.
- **Story goal:** find out what you were. The answer is Tommy.
- **Per room:** reach the exit using the legs, grapple and detached arm.
- **Optional:** find the data logs (2-3 per chapter) that tell the evacuation story.

## Story
Subject 0 wakes in an abandoned lab, missing a leg and an arm, marked
REJECTED. Outside is a silent, evacuated downtown and a lit window on the
tower. Climbing it, the hero learns the other subjects were upgraded until
nothing human was left. The hero was rejected because one human memory
would not delete. At the top the signal turns out to be an "all clear" that
was never sent. Instead the terminal plays that memory: a boy, Tommy, in front of
a small house at dusk, someone calling his name. Full detail in `story.md`.

## Loop
**Moment to moment (seconds):** run, jump, grapple, dash, throw the arm, die,
respawn instantly in the same room, try again.
**Room loop (1-3 min):** read the room -> work out the route -> fail a few
times -> clear it -> next room.
**Chapter loop (10-15 min):** arrive in a new district -> learn or combine an
ability -> clear ~5 rooms -> find logs -> a story beat -> next district.
**Whole game:** Lab -> Street -> Subway -> Skyway -> Tower -> the memory.

## Structure
| Ch | Place | Rooms | Ability focus | Story beat |
|---|---|---|---|---|
| 0 | The Lab | 4 | Hop, spring leg, detach arm, grapple arm | Wake up, REJECTED file, escape |
| 1 | Street Level | 5 | Spring pads, jump | Looping announcement, tower in view |
| 2 | Collapsed Subway | 5 | Detach puzzles (switches) | Dead cyborgs, "past being human" |
| 3 | Broken Skyway | 5 | Grapple, grapple to arm | Meets Pip, learns the evacuation |
| 4 | The Tower Core | 5 | Everything | The signal, the memory, the ending |
About 24 rooms. Single-screen rooms, instant respawn.

## Teach
One idea per room, shown before it is tested (Celeste-style):
1. **Show** - a safe room where the new ability is the only way forward.
2. **Test** - the same idea with a small risk.
3. **Twist** - combine it with an old ability.
No tutorial text walls. Teaching happens through level design and short lines:
- Lab: the arm is thrown onto a switch to open a door (the signature mechanic).
- Grapple: the exit sits beyond a gap only reachable by a swing.
- Dash: a gap too wide for a jump, sized to one dash.
- Pip may give one hint line per chapter, never instructions.
Controls are shown once, in the world (a glowing key prompt), not in menus. **(?)**

## Feedback
**Mechanical (instant, readable):**
- Arm thrown: visible arc, sound on landing, a light on the switch when pressed.
- Grapple: line draws on fire, a clunk on hit, a red flash if it misses.
- Dash: jet flame trail, charge icon on the player that refills on landing.
- Death: a quick flash and respawn in under a second, so retrying never feels like a punishment.
**Narrative (quiet):**
- Collecting a data log: soft chime, the log text appears in the dialogue box.
- Colour is the progress meter: the world starts grey and cold, picks up
  tiny warm accents as the hero nears the tower, and the ending is the first
  fully warm scene.
- The looping announcement changes each chapter, so the player hears distance.
**Audio:** sparse ambient hum and rain, a single piano motif that returns in the ending. **(?)**

## Scope
**Must have (the jam build):**
- Chapters 0-2 playable: Lab, Street, Subway (14 rooms).
- Spring legs, detach arm, grapple, dash all working.
- Dialogue box with chapter 0 + one log per chapter.
- The ending memory scene, even as a still image with text.
- Title screen and a Tommy end card.

**Should have:**
- Chapter 3 (Skyway) and Pip the drone.
- Sound effects and one music loop.
- 2 logs per chapter.

**Could have (cut first):**
- Chapter 4 as a full level (otherwise a short climb straight into the ending).
- All 3 logs per chapter, animated memory scene, collectible completion screen.

**Not doing:** ability swapping, branching endings, voice acting, save slots.
**Cut rule:** if time runs short, drop rooms, never the ending.

## Team split (suggested) **(?)**
- **Narrative (you):** story, logs, dialogue, the ending, title and end card.
- **Mechanics:** player, rooms, puzzles.
- **Art/audio:** sprites, tilesets, the house memory scene, sound.

## Open questions
1. Is "SUBJECT 0" the title you want? Alternatives: *Rejected*, *Still Here*, *The Last Unit*.
2. How old is Tommy in the memory (a kid, or an adult)?
3. Who is calling his name (a parent, a sibling)?
4. How many rooms can the mechanics person realistically build?
