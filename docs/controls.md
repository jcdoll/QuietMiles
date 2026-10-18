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
| Road | Regional uses authored surface sections. Dirt, Pavement, Snow or Mud overrides the loop and spur for comparison; offroad terrain keeps its regional material. |
| Hills | Rolling or Flat; changing it rebuilds terrain and returns the car to road. |
| View | Rally Low or High View; both follow travel direction with delayed yaw. |
| Zoom | 100-150% in 10% steps, default 140%. Selecting the row shows a live preview. Left/Right adjusts, Z cycles, X drives; Up/Down returns to other settings. |
| Feel | Rally or Assisted; Assisted increases rear grip to limit oversteer. |
| Place | Birch Run, Snow Pines, Peat Moor, Pine Lake or Ochre Hills. |
| Sound | Quiet original audio sketch, or silence. |

Zoom is independent of View. It survives region changes and Restart Drive, but
Ctrl+R resets it to 140%. Other settings also last only for the current session.
The Road override survives a region change too; select Regional to try the new
place's intended materials.

## Suggested comparison

1. Start in Birch Run with Rally Low, 140% zoom, Rally feel, Rolling hills and Regional road.
2. Accelerate into a bend, ease off and use short steering inputs.
3. Briefly hold X while turning, then release and countersteer.
4. Compare Dirt and Pavement on the same bend. Pavement should gather the car
   sooner; dirt should carry a slide and need more room to stop.
5. Try Flat and High View independently to judge visibility and camera motion.
6. Select Snow Pines with Regional road. Use earlier braking and smaller steering inputs.
7. Try Peat Moor: compare momentum on its gravel and mud sections. Mud should
   carry lateral slip but lose forward speed more quickly when you lift off.

Focus feedback on upcoming-bend visibility, camera settling after slides,
recoverability and readable surface changes. Structure options are still open;
see [the plan](plan.md) and [region playtest notes](regions.md).
