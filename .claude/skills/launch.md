# Launch Mega Man X8 16-bit Demake

## When to use
Use when the user wants to launch, start, run, or play the Mega Man X8 16-bit demake game.

## Instructions

### Step 1: Kill any existing instance
```bash
pkill -f godot3
```
Wait briefly if needed, but do NOT chain with the launch command.

### Step 2: Launch the game
**From source (default — use this when modifying code):**
```bash
~/bin/godot3 --path /home/struktured/projects/megaman-x8-16bit-demake &
```

**From release build (Wine):**
```bash
cd ~/gaming/demakes && wine "Mega Man X8 16-bit 1.0.0.9.exe" &
```

### Step 3: Verify it's running
```bash
sleep 1 && pgrep -f godot3
```

### Step 4: Fullscreen (optional, on request)
```bash
qdbus6 org.kde.kglobalaccel /component/kwin invokeShortcut "Window Fullscreen"
```

## CRITICAL Rules
- **Each step must be a SEPARATE Bash tool call** — no chaining kill+launch or launch+verify in one command
- Launch with `&` and **NO pipes or redirects** (they break window visibility on Wayland)
- Do NOT use `wine explorer /desktop=` — it lands on the wrong monitor
- The source launch uses `~/bin/godot3` (Godot 3.6), NOT system `godot` (which is 4.4)
- Preferred display: DP-1 (LG ultrawide 3440x1440, primary monitor)
- For resize, use the `/resize` skill
