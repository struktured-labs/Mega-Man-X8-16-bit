# Fix Controller Setup

## When to use
Use when the user has controller issues — turbo/rapid-fire, wrong button mappings, triggers not working, or needs to set up a new controller for the Mega Man X8 16-bit demake.

## Key Facts

### 8BitDo Ultimate 2 Wireless Controller
- **USB ID**: `2dc8:310b`
- **Driver**: `xpad` (Linux kernel)
- **NOT in Godot 3.6's built-in SDL controller database** — SDL mapping via `Input.add_joy_mapping()` did NOT work reliably
- **Has built-in turbo mode** — holding the Turbo button + a face/shoulder button enables rapid-fire on that button. The LED in the center of the controller flashes when turbo is active on any button.

### Turbo Mode (Common Gotcha!)
If a button appears to "turbo" (rapid press/release every ~30ms), check for turbo mode FIRST:
- **Symptom**: Button or trigger rapidly toggles True/False, axis slams between 1.0 and -1.0
- **Diagnosis**: LED flashing in center of controller when that button is pressed
- **Fix**: Hold Turbo button + press each affected button to toggle turbo off

### Godot 3.6 Raw xpad Button Indices (No SDL Mapping)
Since SDL mapping doesn't apply reliably, use raw indices in `project.godot`:

| Physical Button | Raw Index | Type |
|---|---|---|
| A (bottom) | btn 0 | JoypadButton |
| B (right) | btn 1 | JoypadButton |
| X (left) | btn 2 | JoypadButton |
| Y (top) | btn 3 | JoypadButton |
| LB (left bumper) | btn 4 | JoypadButton |
| RB (right bumper) | btn 5 | JoypadButton |
| Back/Select (square, left inner) | btn 6 | JoypadButton |
| Start/Menu (star, right inner) | btn 7 | JoypadButton |
| Guide/Home | btn 8 | JoypadButton |
| L3 (left stick click) | btn 9 | JoypadButton |
| R3 (right stick click) | btn 10 | JoypadButton |
| D-pad Up | btn 12 | JoypadButton (hat auto-mapped) |
| D-pad Down | btn 13 | JoypadButton (hat auto-mapped) |
| D-pad Left | btn 14 | JoypadButton (hat auto-mapped) |
| D-pad Right | btn 15 | JoypadButton (hat auto-mapped) |

### Raw xpad Axis Indices
| Physical Input | Raw Index | Rest Value |
|---|---|---|
| Left Stick X | axis 0 | 0 |
| Left Stick Y | axis 1 | 0 |
| **LT (left trigger)** | **axis 2** | **-32767 (-1.0)** |
| Right Stick X | axis 3 | 0 |
| Right Stick Y | axis 4 | 0 |
| **RT (right trigger)** | **axis 5** | **-32767 (-1.0)** |

**CRITICAL**: Axes 2 and 5 are triggers, NOT stick axes. The game's subweapon wheel (analog_left/right/up/down) must use axes 3/4 (right stick), NOT axis 2.

### Current Game Mapping (User Preference)
| Action | Button | Raw Index |
|---|---|---|
| Jump | A | btn 0 |
| Fire | X | btn 2 |
| Alt Fire | Y | btn 3 |
| Dash | LB (L1) | btn 4 |
| Weapon Cycle Left | B | btn 1 |
| Weapon Cycle Right | RB | btn 5 |
| Pause | Square (left inner) | btn 6 |
| Select | Star (right inner) | btn 7 |
| Select Special | L3 | btn 9 |
| Back to Buster | R3 | btn 10 |
| Subweapon Left/Right | Right Stick X | axis 3 |
| Subweapon Up/Down | Right Stick Y | axis 4 |

## Debugging Steps

1. **Add joypad logger** to `InputManager.gd` `_input()` — log button indices and axis values to `user://joy_log.txt`
2. **Check raw events**: Read `/dev/input/js0` with Python to see kernel-level joystick data
3. **Compute Godot GUID**: Read evdev `EVIOCGID` from `/dev/input/event*` — format: `busLE16 0000 vendorLE16 0000 productLE16 0000 versionLE16 0000`
4. **Check SDL DB**: `strings ~/bin/godot3 | grep "VENDOR_HEX"` to see if controller is in built-in DB

## Files Modified
- `project.godot` — `[input]` section with raw button/axis indices, `[locale]` set to `test="en"`
- `src/System/InputManager.gd` — keybind reset hack in `load_modified_keys()`, joy logging (temporary)
- Save file at `~/.local/share/godot/app_userdata/Mega Man X8 16-bit/savegame.save` — contains stale `keys` section that overrides project.godot defaults

## Important Notes
- The save file's `keys` section persists custom remappings — if mappings seem wrong, check if stale saved bindings are overriding project.godot defaults
- `InputManager.load_modified_keys()` currently has a TEMP hack to skip loading saved keys and force `InputMap.load_from_globals()` — remove this once bindings are stable
- `TranslationServer.set_locale("en")` is called in `load_modified_keys` to force English — the project default locale was `"br"` (changed to `"en"` in project.godot)
