# Launch Mega Man X8 16-bit Demake

## When to use
Use when the user wants to launch, start, run, or play the Mega Man X8 16-bit demake game.

## Instructions

Launch the game using Wine from `~/gaming/demakes/` (do NOT use Wine virtual desktop — it lands on the wrong monitor):

```bash
cd ~/gaming/demakes && wine "Mega Man X8 16-bit 1.0.0.9.exe" &
```

Then wait for the window to appear and resize via KWin scripting (xdotool can't reliably set the full size):

```bash
sleep 3
cat <<'SCRIPT' > /tmp/kwin_resize.js
var clients = workspace.windowList();
for (var i = 0; i < clients.length; i++) {
    var c = clients[i];
    if (c.caption.indexOf("Mega Man") !== -1) {
        c.frameGeometry = {x: 726, y: 20, width: 2571, height: 1342};
    }
}
SCRIPT
SCRIPT_ID=$(dbus-send --session --dest=org.kde.KWin --print-reply --type=method_call /Scripting org.kde.kwin.Scripting.loadScript string:"/tmp/kwin_resize.js" | grep int32 | awk '{print $2}') && dbus-send --session --dest=org.kde.KWin --type=method_call /Scripting/Script$SCRIPT_ID org.kde.kwin.Script.run
```

Verify it's running and sized correctly:

```bash
pgrep -fa "Mega Man"
xdotool search --name "Mega Man" getwindowgeometry
```

**Important:**
- Launch with `&` and NO pipes or redirects (they break window visibility on Wayland)
- Do NOT use `wine explorer /desktop=` — it lands on the wrong monitor (Dell instead of LG)
- Preferred client size: **2569x1313** at position **(727, 48)** on DP-1 (LG ultrawide, primary)
- Use KWin DBus scripting for resize, not xdotool (which caps the height)
- Confirm the process is running with `pgrep` after launch
