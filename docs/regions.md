# Regions and playtesting

Use Regional road mode to experience each place's authored material sections.
The road override settings are for controlled comparisons and persist when
changing regions. Every place is a finite loop with a lookout spur; no timer
or game-structure decision is introduced here.

| Region | Road and scenery | Useful comparison |
| --- | --- | --- |
| Birch Run | Finnish-inspired pines and birches around a lake; gravel with two asphalt stretches. | Can the next bend be read at 140% zoom, and does asphalt gather a slide smoothly? |
| Snow Pines | Packed snow loop, gentler hills, snow pines and rocks. | Earlier braking, countersteering and road-edge contrast against snow. |
| Peat Moor | Open wetland, reeds and bare trees; mud stretches linked by gravel and asphalt. | Mud adds drag as well as slip. Lift off after leaving gravel, then compare a powered turn. |
| Pine Lake | The original lake route with mixed gravel/asphalt and woodland scenery. | Familiar route for the closer camera and gentler terrain. |
| Ochre Hills | The original ochre route with rocks, warm trees and mixed surfaces. | The largest hill amplitude in this set, still using the simpler terrain mesh. |

## How regions are authored

[regions.lua](../src/regions.lua) contains compact records: route anchors,
outgoing surface IDs, terrain amplitude, colors, scenery style/count, optional
lake and spur points. The world builder samples those anchors into road segments.
Physics and rendering use the same material lookup, including road overrides.
Scenery is generated from a deterministic region seed; sprites remain Lua-drawn.

Only one region is active at a time. Adding stored region definitions is cheaper
than increasing active road or scenery counts. The 8x8 terrain mesh and bounded
scenery counts leave more room for the closer view. Run the native sweep before
raising density or adding terrain detail.

## Playtest sequence

1. Drive each new region with Rally Low, 140% zoom, Rolling hills, Rally feel
   and Regional road. Try accelerating, lifting, braking and a short handbrake turn.
2. Check Dirt, Pavement, Snow and Mud on one familiar bend. The override affects
   roads; going offroad restores that region's ground material.
3. Compare 100%, 140% and 150%, then High View. Watch for unreadable bends,
   scenery covering the car, and hill crests exposing terrain layering errors.
4. Compare Flat with Rolling and use Return to Road after a detour.

The model checks cover surface behavior, road/spur material queries, roads staying
out of lakes, recovery, region cycling and projection across all five regions.
The native sweep samples both camera heights, eight headings and three zooms;
see [validation](pico8.md). Human feedback is still needed on whether each
surface feels relaxed and recoverable.
