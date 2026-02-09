# Launch Mega Man X8 16-bit Demake

## When to use
Use when the user wants to launch, start, run, or play the Mega Man X8 16-bit demake game.

## Instructions

Launch the game using Wine from `~/gaming/demakes/`:

```bash
cd ~/gaming/demakes && wine explorer /desktop=MMX8,2567x1322 "Mega Man X8 16-bit 1.0.0.9.exe" &
```

Then verify it's running:

```bash
sleep 2 && pgrep -fa "Mega Man"
```

**Important:**
- Launch with `&` and NO pipes or redirects (they break window visibility on Wayland)
- The preferred window size is **2567x1322** (use Wine virtual desktop to set this)
- If the user wants a different size, adjust the `explorer /desktop=MMX8,WIDTHxHEIGHT` parameter
- Confirm the process is running with `pgrep` after launch
