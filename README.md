# Quiet Miles

A relaxed PICO-8 rally-driving prototype inspired by Art of Rally. The current
focus is camera position and driving feel: rolling hills, recoverable slides,
and different grip on dirt and pavement. The choice between free roaming and
stages is still open. Code, scenery and sound are original.

## Play

For the [free Education Edition](https://www.pico-8-edu.com/), package the game
with Node.js from the repository root (no packages to install):

```sh
node tools/build.js
```

In PICO-8, press Escape to stop a running cart, type `load`, and select
`build/quiet_miles.p8`. Press Ctrl+R, then X to leave settings and drive.
The generated file is plain text and is ignored by Git.

Desktop PICO-8 can load the root [quiet_miles.p8](quiet_miles.p8) directly when
the checkout is inside its carts directory. Keep `src/` beside it for the
includes to resolve. The packaged file also works on desktop.

| Control | Action |
| --- | --- |
| Left / Right | Steer |
| Z or Up | Accelerate |
| Down | Brake; hold at low speed to reverse |
| X | Handbrake |
| P or Enter | Pause menu: settings, road recovery, restart |

Drive Settings offers two regions, rolling or flat terrain, low or high camera
angles, and 100-150% zoom with a 120% default. Select Zoom for a preview, use
Left/Right to adjust, and press X to resume. Mixed roads alternate dirt and
pavement; Snow Test experiments with low grip on the same landscape.

See [the full controls and comparison guide](docs/controls.md).

## Develop

`.p8` is PICO-8's text cartridge format: Lua source plus optional asset data.
It is an input to PICO-8, not a compiled binary. Our root cartridge is a small
entry file with native `#include` directives. The build script substitutes the
Lua files to make one browser-loadable text cartridge; it does not compile code.
See the [official include documentation](https://www.lexaloffle.com/dl/docs/pico-8_manual.html#_INCLUDE).

Edit these files, then rerun the build for browser play:

| File | Responsibility |
| --- | --- |
| [src/main.lua](src/main.lua) | Initialization, settings, frame loop and UI |
| [src/world.lua](src/world.lua) | Regions, terrain, roads and surface queries |
| [src/driving.lua](src/driving.lua) | Car physics, recovery, particles and engine pitch |
| [src/camera.lua](src/camera.lua) | Camera following, projection and visibility |
| [src/render.lua](src/render.lua) | Terrain, road, car and scenery drawing |
| [src/assets.lua](src/assets.lua) | Procedural sprites and synthesized sound |

The included files share PICO-8's global environment. Sprites and sound are
created in code at startup, so no binary assets are required. Keep binaries out
of Git unless essential; use PR attachments for screenshots. Keep authored code
files around 300 lines or fewer, splitting at responsibility boundaries. The
generated single-file cartridge is an ignored output and may be longer.

Run the existing handling and projection checks from the repository root with
Node.js and Lua 5.4:

```sh
node tools/build.js
lua tests/handling.lua
```

The harness reads the packaged cartridge and checks surface behavior, braking,
steering, handbrake slip, reverse, terrain effects, recovery and projection.
It uses ordinary Lua numbers and mocked PICO-8 graphics/audio APIs. It cannot
measure native fixed-point behavior or PICO-8 CPU use.

To generate the native performance-check cartridge, use Node.js (no packages
to install):

```sh
node tools/make-sweep.js
```

Load `build/quiet_miles_sweep.p8` in PICO-8. It samples 1,600 scenes across both
regions at the closest 150% zoom, exercises physics and particle buffers, and
reports CPU use against the 30 fps budget. The generated cart is ignored by Git.

See [PICO-8 limits and validation](docs/pico8.md) for prior measurements and
native checks. Keep screenshots and exports under ignored `build/`.

## Design notes

- [Direction and game structure](docs/plan.md): priorities, options and next decisions.
- [Camera and rendering](docs/camera.md): framing, hills and rendering tradeoffs.
- [Handling and surfaces](docs/handling.md): sliding, grip and future snow regions.

## Current scope

The game presents at 30 fps and integrates physics twice per frame at 60 Hz.
It has two small finite regions, simplified terrain layering, and a quiet audio
sketch. Snow is a surface test rather than a finished winter level. There are
no jumps, saved progress or connected world yet. Camera settings last for the
current session only.
