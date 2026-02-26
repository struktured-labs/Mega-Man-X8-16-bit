# Restore Key Bindings

## When to use
Use when the user wants to restore their key bindings to the known-good backup. By default this skill **restores** only. Only update the backup if the user explicitly asks to.

## Instructions

### Restore (default behavior)

```bash
cp /home/struktured/projects/megaman-x8-16bit-demake/project.godot.keybinds-backup /home/struktured/projects/megaman-x8-16bit-demake/project.godot
```

```bash
cp ~/.local/share/godot/app_userdata/"Mega Man X8 16-bit"/savegame.save.keybinds-backup ~/.local/share/godot/app_userdata/"Mega Man X8 16-bit"/savegame.save
```

Then relaunch the game if it's running (use the `/launch` skill).

### Update backup (ONLY if user explicitly asks)
Only do this if the user says something like "update the backup", "save current as backup", etc.

```bash
cp /home/struktured/projects/megaman-x8-16bit-demake/project.godot /home/struktured/projects/megaman-x8-16bit-demake/project.godot.keybinds-backup
```

```bash
cp ~/.local/share/godot/app_userdata/"Mega Man X8 16-bit"/savegame.save ~/.local/share/godot/app_userdata/"Mega Man X8 16-bit"/savegame.save.keybinds-backup
```

## Notes
- Backup created 2026-02-25 after dual joypad QoL work with correct raw xpad mappings for 8BitDo Ultimate 2 Wireless
- `project.godot` is the file that matters — `InputManager.load_modified_keys()` resets to its defaults on load
- Restart the game after restoring for changes to take effect
