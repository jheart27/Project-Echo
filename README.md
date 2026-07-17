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
| Space | Jump (low, weighty hop) |
| Shift (hold) | Sprint (limited by stamina) |
| E | Interact |
| G | Toggle thermal optics (once goggles are found) |
| Esc | Release mouse (click to recapture) |

## Current build

Following the "Beginning" board of the Construct map: corridor → keycard
(look for the flickering light) → security door → Grand Columns chamber
(catwalk loop above) → wrecked records office (thermal goggles) → bridge
over a chasm → stairwell down → dark maintenance tunnels → pump station
(prime the generator) → back up: the NO POWER door on the platform now
opens → Grand Hall → Elevator lobby (dead shaft to Floors 25/50/75) →
Labs and Controls → the cyber mutant pen. From the lobby, ramps climb to
upper catwalks and a high doorway into the Titan Approach — sprint-jump
the collapsed floor (falling drops you into a crawl duct that spits you
back out over the lobby) — ending at the Titan Construct zone: a half-
built 48m titan in scaffolding, gantry crane, elevated control room, and
the hermetic gate to the next zone. Progression uses GameState flags, not
an inventory — pickups/levers/generators just set flags that gates check.

## Sector streaming

The level is split into sector scenes (`scenes/levels/sectors/`) streamed
by `sector_loader.gd` around the player: the start sector (corridor →
chasm → maintenance level) and the deep sector (grand hall → lobby →
titan wing). Bands overlap ~50m so both exist while crossing the bridge/
hall boundary; the far sector unloads once fog and walls hide the seam.
Light panels and the big standalone omnis also distance-fade. New zones
should follow this pattern: one scene per sector, registered in the
loader.

## Textures

`textures/` holds 256px procedurally generated PS2-grunge albedo maps
(low-quality JPEG on purpose — the compression artifacts are part of the
look), applied via world-space triplanar materials in `materials/` with
nearest-neighbour filtering. Sourcing CC0 photo textures (ambientCG /
Poly Haven) is blocked from this dev environment's network; drop-in
replacements just need to keep the same filenames.

## NPCs

A lost kid hides in the Labs and Controls room (warm glow, behind a
desk). Interact to have her follow — interact again to make her wait —
and lead her to the floor vent in the lobby; she escapes somewhere you
can't follow. One hit kills her, permanently for that run, and the hall
Stalker's patrol now sweeps into the lobby. Time the crossing.

## Enemies

Stalker Synths patrol the Grand Hall and the Titan assembly floor: tall,
hunched, asymmetric machines with a sweeping searchlight eye (cyan while
calm, red while hunting). They chase slightly faster than you can sprint —
escape by breaking line of sight (pillars, doorways, the labs), not by
outrunning them. One hit is death: the screen cuts to SIGNAL LOST and the
stratum reassembles you at the start — but flags (keycard, power, optics,
rescue) survive.

## Project layout

- `autoload/game_state.gd` — global singleton (`GameState`), minimal for now
- `scenes/player/` — shared first-person controller scene
- `scenes/levels/` — one scene per level/zone
- `scenes/props/` — interactables and set pieces
- `scenes/effects/post_process.tscn` + `shaders/post_process.gdshader` —
  full-screen grain/vignette/aberration pass, instanced per level
