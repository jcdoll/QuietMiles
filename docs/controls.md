# Controls and playtesting

Follow [README loading instructions](../README.md#play) to package and run the
cartridge. Press X to close Drive Settings and start driving.

| Driving control | Action |
| --- | --- |
| Left / Right | Steer relative to the car |
| Z or Up | Accelerate |
| Down | Brake; hold at low speed to reverse |
| X | Handbrake, including while accelerating |
| P or Enter | PICO-8 pause menu |

The pause menu offers Drive Settings, Return to Road and Restart Drive.
Escape stops the cartridge in the development environment; Ctrl+R resets it.

## Settings

Up/Down selects a row. Left/Right or Z cycles the setting; X resumes driving.

| Setting | Options and behavior |
| --- | --- |
| Road | Mixed alternates dirt/pavement; Dirt or Pavement changes the main loop. The lookout spur stays dirt. Snow Test applies low grip throughout. |
| Hills | Rolling or Flat; changing it rebuilds terrain and returns the car to road. |
| View | Rally Low or High View; both follow travel direction with delayed yaw. |
| Zoom | 100-150% in 10% steps, default 120%. Selecting the row shows a live preview. Left/Right adjusts, Z cycles, X drives; Up/Down returns to other settings. |
| Feel | Rally or Assisted; Assisted increases rear grip to limit oversteer. |
| Place | Pine Lake or Ochre Hills, each with rolling terrain. |
| Sound | Quiet original audio sketch, or silence. |

Zoom is independent of View. It survives region changes and Restart Drive, but
Ctrl+R resets it to 120%. Other settings also last only for the current session.

## Suggested comparison

1. Start with Rally Low, 120% zoom, Rally feel, Rolling hills and Mixed road.
2. Accelerate into a bend, ease off and use short steering inputs.
3. Briefly hold X while turning, then release and countersteer.
4. Compare Dirt and Pavement on the same bend. Pavement should gather the car
   sooner; dirt should carry a slide and need more room to stop.
5. Try Flat and High View independently to judge visibility and camera motion.
6. Try Snow Test with earlier braking and smaller steering inputs.

Focus feedback on upcoming-bend visibility, camera settling after slides,
recoverability and readable surface changes. Structure options are still open;
see [the plan](plan.md).
