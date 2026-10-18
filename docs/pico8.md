# PICO-8 limits and validation

## Platform budget

The [official manual](https://www.lexaloffle.com/dl/docs/pico-8_manual.html)
documents a 128x128 display, 16 display colors, six-button input, 8,192 code
tokens, 65,535 source characters and roughly four million VM instructions per
second. Numbers use 16.16 fixed point. The default map is 128x32 tiles, with
another 32 rows sharing sprite memory; that is storage, not a world-size limit.
There are four audio channels, 64 KiB base RAM, a separate 2 MiB Lua heap and
32 KiB of cartridge data in PNG carts.

The manual's compressed-code ceiling is below 15,360 bytes for PNG/ROM. The
tested Education Edition's INFO displayed 15,616; keep below the stricter
threshold. Includes still count toward normal code limits. At 60 fps the
per-frame CPU budget halves relative to 30 fps.

## Choices for this prototype

Perspective terrain exceeded the 60 fps budget in an early stress run. The
game therefore presents at 30 fps with two physics and camera steps per frame.
Inputs are sampled at the rendered-frame rate. Region generation can briefly
pause; it is excluded from steady-scene performance measurements.

Generated regions avoid a large stored map. Coordinates are bounded and
distance calculations scale before squaring to avoid fixed-point overflow.
Scenery is culled, tree sprites are cached, and particle counts are capped.
An endless world would need local coordinates and deterministic chunks.

## Source and packaging

The root `.p8` is a text cartridge using native `#include` directives. Desktop
PICO-8 resolves these relative to that cartridge at boot. For a single browser
upload, `node tools/build.js` inserts the Lua files into `build/quiet_miles.p8`.
This is text assembly, not compilation. Edit `src/`, not generated output.
Sprites and audio are generated at startup; no binary assets are required.

## Run checks

From the repository root, with Node.js and Lua 5.4:

```sh
node tools/build.js
lua tests/handling.lua
node tools/make-sweep.js
```

The Lua harness reads the packaged cartridge. It checks ordered surface slip
and braking, steering, powered turns, handbrake, reverse, smooth grip changes,
slope gravity, body pitch, road recovery and projection around both regions.
Graphics/audio are mocked and numbers are ordinary Lua floating point, so
this cannot measure native fixed-point behavior or PICO-8 CPU use.

Load `build/quiet_miles_sweep.p8` in PICO-8 and run it to completion. It exercises
1,600 scenes across both regions at the closest 150% zoom, with full particle
buffers and two physics steps. It reports peak CPU and sampled over-budget
frames. The sweep alternates camera height with heading; it is a sample of
combinations, not an exhaustive rendering guarantee.

Manual checks should cover combined driving inputs, the pause menu, surfaces,
flat/hilly terrain, both camera heights, and zoom's 100% and 150% endpoints,
120% default, preview and return to driving.

## Recorded measurements

The assembled cartridge was checked after the source-file split in PICO-8 0.2.7
Education Edition. It loaded, ran, and accepted combined driving/handbrake input.

| Check | Observed result |
| --- | --- |
| Assembled cartridge INFO | 5,566 tokens; 18,578 characters; 7,915 compressed bytes |
| Closest-zoom sweep, 1,600 scenes | Peak CPU 0.8475 of the 30 fps budget; zero sampled over-budget frames |
| Earlier wide-framing hilly sweep | Peak CPU 0.9017; zero sampled over-budget frames |

The closest-zoom sweep was rerun after assembly; the earlier wide-framing result
is retained for context. These are native observations, not Lua harness results.
Rerun native checks after renderer or packaging changes. Keep screenshots and
exports under ignored `build/` or attach them to the PR rather than tracking
them in Git.
