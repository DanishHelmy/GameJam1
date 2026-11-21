# GameJam1

Godot 4.7 game for the Xsolla game jam. Team of 3.

## Getting started
1. Install Godot 4.7.2 (stable).
2. Clone this repo and open `project.godot` in Godot.

## Folders
- `scenes/` – .tscn scenes (main scene: `scenes/main.tscn`)
- `scripts/` – GDScript files
- `ui/` – UI scenes and themes
- `assets/` – sprites, audio, fonts

## Team workflow
- Never commit straight to `main`; work on a branch (`name/feature`) and open a PR.
- Pull before you start: `git pull --rebase`.
- Avoid two people editing the same `.tscn` at once; split work per scene.
- Commit the `.import` files next to assets, but never the `.godot/` folder.
