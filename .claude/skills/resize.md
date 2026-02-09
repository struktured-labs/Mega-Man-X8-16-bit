# Resize Mega Man X8 16-bit Demake

## When to use
Use when the user wants to resize, reposition, or fix the size of the running Mega Man X8 16-bit demake window.

## Instructions

Use KWin scripting via DBus to resize (xdotool can't reliably set the full size).

The frame geometry must compensate for window decorations (1px left/right/bottom, 28px top title bar):
- frame x = desired_x - 1
- frame y = desired_y - 28
- frame width = desired_width + 2
- frame height = desired_height + 29

Default resize to **2569x1313** at **(727, 48)**:

```bash
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

Verify:

```bash
xdotool search --name "Mega Man" getwindowgeometry
```

If the user provides a custom size (e.g. `/resize 1920x1080`), compute the frame geometry by applying the decoration offsets above.

**Defaults:**
- Client size: **2569x1313**
- Client position: **(727, 48)** (on DP-1 LG ultrawide)
- Frame geometry: {x: 726, y: 20, width: 2571, height: 1342}
