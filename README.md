# Project-Echo

First-person exploration/horror set in a vast, decaying megastructure
(BLAME!-inspired). Godot 4.x, GDScript, Forward+ renderer.

Art direction: PS2-era low-poly grunge — hard-edged geometry, muddy desaturated
palette (rust / concrete / sodium orange / cold fluorescent), heavy fog and
volumetric light shafts, subtle grain + vignette + chromatic aberration
post-pass. Scale is a character: rooms should dwarf the player.

## Running

Open the project in Godot 4.3+ (Forward+ renderer required for volumetric fog)
and press **F5**. The main scene is `scenes/levels/test_corridor.tscn`.

## Controls

| Input | Action |
| --- | --- |
| WASD | Move |
| Mouse | Look |
| Shift (hold) | Sprint (limited by stamina) |
| E | Interact |
| Esc | Release mouse (click to recapture) |

## Project layout

- `autoload/game_state.gd` — global singleton (`GameState`), minimal for now
- `scenes/player/` — shared first-person controller scene
- `scenes/levels/` — one scene per level/zone
- `scenes/props/` — interactables and set pieces
- `scenes/effects/post_process.tscn` + `shaders/post_process.gdshader` —
  full-screen grain/vignette/aberration pass, instanced per level
