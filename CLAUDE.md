# Mega Man X8 16-bit Demake

## Game Location
- Executable: `~/gaming/demakes/Mega Man X8 16-bit 1.0.0.9.exe`
- Launched via Wine

## Preferred Settings
- Window size: **2569x1313** at position **(727, 48)**
- Monitor: DP-1 (LG ultrawide, 3440x1440, primary)

## Launch
- Use `/launch` skill to start the game
- Do NOT use Wine virtual desktop (`explorer /desktop=`) — it lands on the wrong monitor
- Launch plain Wine, then resize with `xdotool`

## Notes
- This is a Windows game fan demake, run via Wine on Linux
- Use `&` with no pipes/redirects for Wayland compatibility
- 8BitDo SN30 Pro controller (shows as Xbox 360). Run `fix-controller-autosuspend.sh` if joystick drops out
