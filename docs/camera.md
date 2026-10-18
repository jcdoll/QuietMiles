# Camera and rendering

The user wants a lower, farther-back view resembling the feel of Art of Rally,
but found the first perspective framing too distant. Angle and zoom are
independent so the prototype can compare visibility with a larger car.

## Current camera

| Setting | Downward angle | Distance behind | Height above tracked ground |
| --- | --- | --- | --- |
| Rally Low | About 27.4 degrees | 90 world units | 60 world units |
| High View | About 46 degrees | 65 world units | 85 world units |

These are prototype tuning values, not measurements of Art of Rally. The
camera follows travel direction with 15% body-heading influence. Yaw changes
are smoothed and capped, preserving visible countersteer. Ground-height tracking
is slower and includes a small look ahead. There is no shake or speed zoom.

Six manual zoom steps span 100-150%, with 120% as the default. Zoom changes
focal length while keeping the car near the same screen height. Closer framing
shows less surrounding road. Selecting Zoom in settings shows a live preview.
Zoom survives drive restarts and region changes, but resets with the cartridge.

Follow and projection code is in [camera.lua](../src/camera.lua). Lens, angle
and screen framing are set at the start of `_draw` in [main.lua](../src/main.lua).

## Rendering approaches considered

| Approach | Assessment |
| --- | --- |
| Fixed oblique 2.5D | Cheap and stable, but steering is less intuitive when approaching the viewer. |
| Soft-follow oblique 2.5D | Used in the first prototype; readable and cheap, but lacked perspective depth and felt too high. |
| Perspective low-poly 3D | Current approach: height field, road mesh, polygon car and upright scenery sprites. Communicates hills but costs more CPU. |
| Road-strip pseudo-3D | Suitable for a forward-only scenic road; branching, reversing and exploration become harder. |

Elevation changes the road mesh, scenery positions and car height. Local slopes
affect body pitch/roll and acceleration. The terrain is coarse, with no jumps
or general depth buffer: terrain is drawn before roads, then scenery and the
car are depth-bucketed. Difficult viewpoints can expose layering inaccuracies.

## Relevant PICO-8 references

- [Driftmania](https://www.lexaloffle.com/bbs/?tid=140202): expressive driving
  and compact pseudo-3D presentation.
- [Ghost Rally](https://github.com/freds72/ghost-rally): a physics reference;
  its author notes the handling is demanding and hard to retune.
- [Ramps](https://www.lexaloffle.com/bbs/?pid=77496): scaled-sprite 3D racing.

These are feasibility references. Their code and assets were not incorporated.

## Playtest questions

- Is the next bend visible early enough at the preferred zoom?
- Does the camera settle naturally after countersteering?
- Are hills readable without obscuring the road or shrinking the car too far?

See [controls](controls.md) for comparison steps and [native validation](pico8.md)
for the rendering budget.
