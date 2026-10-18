# Handling and surfaces

The target is playful, recoverable sliding with a clear difference between dirt
and pavement. The prototype uses separate body heading and velocity, smoothed
digital steering, front/rear lateral tyre forces with grip limits, and angular
inertia. Grip changes are eased across surface boundaries to avoid snapping.

## Surface behavior

| Surface | Intended feel |
| --- | --- |
| Pavement | Stronger tyre forces and braking; gathers lateral motion sooner and retains more rear grip under power. |
| Dirt | Lower grip, longer braking and more power oversteer; countersteering can gather a slide. |
| Grass | Lower traction and more rolling resistance off the road. |
| Snow | Very low grip and weaker braking; needs earlier braking and smaller inputs. Snow Pines uses it on and off road. |
| Mud | Lower lateral grip than dirt and stronger rolling resistance. Slides persist, but lifting off loses speed faster than on dirt or snow. |

The handbrake reduces rear grip further. Assisted feel increases rear grip to
limit oversteer; Rally is the default. Down brakes, then reverses at low speed.
Slope gravity affects acceleration, while static friction permits a quiet stop
on a hill. Collisions are gentle and the pause menu can return the car to road.

Surface parameters live in `_init` in [main.lua](../src/main.lua), the force
model in [driving.lua](../src/driving.lua), and road/surface queries in
[world.lua](../src/world.lua).

## Controlled comparisons

Regional mode follows each route's authored surface sections. Dirt, Pavement,
Snow and Mud modes override both the loop and lookout spur without changing
geometry or scenery. Offroad material stays regional. Compare the same bend
with the same camera and terrain first, then flat and rolling hills independently.
Road overrides persist across region changes, so return to Regional before
judging a new region's intended mix.

Useful feedback: is dirt playful and recoverable, or reluctant to turn / too
spin-prone? Does pavement gather the car sooner? Are material changes obvious
without feeling abrupt? See [controls](controls.md) for a short playtest route.

## Regional feel

Snow Pines pairs the surface model with a distinct route, snow-covered pines
and rocks, and high-contrast road edges. Peat Moor mixes mud with firmer gravel
and asphalt sections; reeds are passable, while bare trees have gentle collisions.
Birch Run is the woodland gravel/asphalt comparison. See [regions](regions.md).

The model checks cover grip/braking ordering, steering, powered slip, handbrake,
reverse, grip transitions, mud coasting resistance and slopes. Subjective feel still needs playtesting;
see [validation limits](pico8.md).
