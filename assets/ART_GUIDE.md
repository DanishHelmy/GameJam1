# Art Guide

Art direction for GameJam1: a 2D pixel-art platformer with 6 levels. Each level introduces a new mechanic, and level 6 is the boss.

**Inspirations:** Celeste (readable character, clean tiles, soft parallax) and Terraria (textured dirt and stone, layered underground, small detailed props).

> Note: "low poly" was interpreted as chunky, low-resolution 2D pixel art, not 3D.

## Technical specs

| Item | Value |
|---|---|
| Base resolution | 320x180 (scales exactly 4x to the 1280x720 window) |
| Tile size | 16x16 |
| Player size | 16x24 (or 16x16) |
| Enemies / props | Multiples of 8px, within 16-32px for most |
| Boss | Up to 64x64 or larger |
| Palette | 16-32 colors shared across the game |
| Outlines | 1px, dark (never pure black), or no outline on tiles |
| Anti-aliasing | None. Hard pixel edges only. |
| File format | PNG with transparency |

### Godot settings to match
- Texture filter: Nearest (Project Settings > Rendering > Textures > Default Texture Filter).
- Stretch mode: `canvas_items` with integer scaling.
- Snap 2D transforms to pixel.

## Style rules
- **Readable silhouette:** the player must stand out from the background at a glance. Use a bright accent color on the player (like Madeline's hair in Celeste).
- **Backgrounds are calmer than foregrounds:** lower contrast and saturation, 2-3 parallax layers.
- **Tiles:** a clean, repeatable base with light texture (Terraria-style speckles and cracks). Avoid noisy patterns that hide hazards.
- **Hazards and interactables:** use a consistent warning color (warm red/orange) so players learn it early.
- **Lighting:** a single implied light direction (top-left). Highlights on top and left edges, shadows on bottom and right.
- **Animation:** 4-8 frames for the player run cycle, 2-4 frames for idle and ambient props. Keep the frame size consistent per sprite sheet.

## Level themes (draft, to be confirmed by the team)

Each level has its own dominant hue, so progress is easy to read. Mechanic names are placeholders.

| # | Theme | Hue | New mechanic (placeholder) |
|---|---|---|---|
| 1 | Surface / grassy forest | Green | Basic run and jump |
| 2 | Underground caves | Brown / earthy | TBD |
| 3 | Frozen cavern | Icy blue | TBD |
| 4 | Fungal / crystal depths | Purple / teal | TBD |
| 5 | Lava / ruins | Red / orange | TBD |
| 6 | Boss arena | Dark with high-contrast accent | Boss fight |

## Folder layout

```
assets/
  sprites/
    player/
    enemies/
    tiles/        (one tileset per level: tiles_level1.png ...)
    backgrounds/  (parallax layers)
    props/
    ui/
    boss/
  audio/
  fonts/
```

## Naming
- Lowercase with underscores: `player_run.png`, `tiles_level2.png`, `bg_level3_far.png`.
- Sprite sheets: `<name>_<action>.png`, horizontal frame strip.

## Palette
TBD. Pick the shared palette first, then add it here as a swatch list with hex codes. Every sprite should use only these colors, plus the per-level hues.
