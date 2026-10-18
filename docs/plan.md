# Direction and game structure

Keep the pleasure of placing a small car through a landscape. Make the clock
optional. Camera and driving feel come first; the user has deferred choosing
between free driving and stages until those work well.

## What to preserve

[Funselektor](https://www.artofrally.com/) emphasizes expressive handling,
including countersteering and handbrake turns. Gameplay developer
[Jacob Vincent](https://www.jacobvincent.com/projects/art-of-rally/) describes
the elevated view as a way to read upcoming road features without pace notes.
For Quiet Miles, these suggest readable bends, visible slip and space to enjoy
the scenery. This is a design interpretation, not an attempt to reproduce the
original game's physics or assets.

Relaxed driving still needs inertia. Instant alignment with the car's nose
would erase the sensation of a slide; repeated spins would demand too much
attention. Recovery should be forgiving and scenery should invite lingering.

## Structure options

| Option | Benefit | Cost |
| --- | --- | --- |
| Authored stages | Control over bends, reveals and moments of rest; a destination can work without a timer. | Restarts and route boundaries interrupt wandering. |
| One connected world | Memorable junctions, viewpoints and journeys between areas. | More navigation, world design and data management; empty space is easy to make. |
| Procedural endless road | Continuous driving with little stored road data. | Needs curvature, sight-distance and scenery rules to avoid repetitive or unreadable roads. |
| Small regions with optional routes | Free driving by default; the same roads can support destinations or timed runs. | Less seamless; each region needs distinctive roads and landmarks. |

Small regions with optional routes remain a promising direction, not a
commitment. Continuous driving does not require infinite terrain: a varied
network can support repeated laps and detours.

## Current prototype

Pine Lake and Ochre Hills each have a main loop and a dirt lookout spur.
Both use rolling terrain. The earlier stage experiment is parked while the
user compares camera and handling settings. The prototype has road recovery,
gentle collisions, dust, skid marks and a quiet audio sketch.

There is no connected world, endless generation, jumping, saved progress,
finished soundtrack or extensive set of authored landmarks. Snow currently
changes grip and palette on existing geometry.

## Next decisions

1. Playtest framing and camera settling after countersteering. Keep the manual
   zoom and low/high comparison while tuning.
2. Compare dirt and pavement on the same bend, then snow. Tune recoverability
   before adding speed, punishment or progression.
3. Once driving feels right, compare a gentle destination route with free
   driving on the same roads. Decide structure from that experience.
4. Build a distinctive winter region if snow handling is enjoyable; use road
   design and atmosphere as well as a palette change.

Related notes: [camera](camera.md), [handling](handling.md),
[PICO-8 limits](pico8.md), [playtest controls](controls.md).
