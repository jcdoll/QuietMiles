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
| Snow Test | Very low grip and weaker braking across the entire region; needs earlier braking and smaller inputs. |

The handbrake reduces rear grip further. Assisted feel increases rear grip to
limit oversteer; Rally is the default. Down brakes, then reverses at low speed.
Slope gravity affects acceleration, while static friction permits a quiet stop
on a hill. Collisions are gentle and the pause menu can return the car to road.

Surface parameters live in `_init` in [main.lua](../src/main.lua), the force
model in [driving.lua](../src/driving.lua), and road/surface queries in
[world.lua](../src/world.lua).

## Controlled comparisons

Mixed mode alternates dirt and pavement around the loop. Dirt and Pavement
modes change the main loop's material without changing geometry; the lookout
spur stays dirt. Compare the same bend with the same camera and terrain first.
Then compare flat and rolling hills independently.

Useful feedback: is dirt playful and recoverable, or reluctant to turn / too
spin-prone? Does pavement gather the car sooner? Are material changes obvious
without feeling abrupt? See [controls](controls.md) for a short playtest route.

## Snow later

Snow Test uses existing roads and scenery with low grip and a temporary palette.
A finished winter region would reuse the surface model but add appropriate
roads, scenery and atmosphere. Snow handling can be tuned before committing to
that content or deciding the game's overall structure.

The model checks cover grip/braking ordering, steering, powered slip, handbrake,
reverse, grip transitions and slopes. Subjective feel still needs playtesting;
see [validation limits](pico8.md).
