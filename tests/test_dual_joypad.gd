extends SceneTree
# Unit tests for dual joypad bindings, clear binding, and conflict detection
# Run: ~/bin/godot3 --no-window --path . -s tests/test_dual_joypad.gd

var pass_count := 0
var fail_count := 0
var test_action := "_test_action"

func _init() -> void:
	print("\n=== Dual Joypad Bindings Tests ===\n")

	setup_test_action()

	test_switch_events_with_old_event()
	test_switch_events_without_old_event_preserves_existing()
	test_clear_action_event()
	test_clear_action_event_null_is_safe()
	test_dual_joypad_bindings()
	test_clear_one_joypad_keeps_other()
	test_switch_replaces_correct_event_in_multi_binding()
	test_joypad_axis_binding()
	test_conflict_groups()
	test_short_joy_names()
	test_axis_index_fallback()
	test_unmapped_controller_names()

	print("\n=== Results: %d passed, %d failed ===" % [pass_count, fail_count])
	if fail_count > 0:
		print("FAIL")
		quit(1)
	else:
		print("OK")
		quit(0)

func setup_test_action() -> void:
	if not InputMap.has_action(test_action):
		InputMap.add_action(test_action)

func reset_test_action() -> void:
	InputMap.action_erase_events(test_action)

# Mirrors InputManager.switch_events() — the FIXED version
func switch_events(event, action, old_event) -> void:
	if old_event:
		InputMap.action_erase_event(action, old_event)
	InputMap.action_add_event(action, event)
	InputMap.action_set_deadzone(action, .85)

# Mirrors InputManager.switch_events() — the OLD BUGGY version
func switch_events_buggy(event, action, old_event) -> void:
	if not old_event:
		InputMap.action_erase_events(action)
	else:
		InputMap.action_erase_event(action, old_event)
	InputMap.action_add_event(action, event)
	InputMap.action_set_deadzone(action, .85)

# Mirrors InputManager.clear_action_event()
func clear_action_event(action, old_event) -> void:
	if old_event:
		InputMap.action_erase_event(action, old_event)

# Mirrors InputManager conflict group logic
var conflict_groups := {
	"gameplay": [
		"move_left", "move_right", "move_up", "move_down",
		"fire", "alt_fire", "jump", "dash",
		"select_special", "weapon_select_left", "weapon_select_right",
		"reset_weapon"
	],
	"menu": ["pause", "ui_accept"],
	"weapon_wheel": ["analog_left", "analog_right", "analog_up", "analog_down"],
}

func get_conflict_group(action: String) -> String:
	for group in conflict_groups:
		if action in conflict_groups[group]:
			return group
	return ""

func actions_can_conflict(action_a: String, action_b: String) -> bool:
	var group_a = get_conflict_group(action_a)
	var group_b = get_conflict_group(action_b)
	return group_a != "" and group_a == group_b

func make_joy_button(index: int) -> InputEventJoypadButton:
	var ev := InputEventJoypadButton.new()
	ev.button_index = index
	ev.pressed = true
	return ev

func make_joy_axis(axis: int, value: float) -> InputEventJoypadMotion:
	var ev := InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = value
	return ev

func make_key(scancode: int) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.scancode = scancode
	ev.pressed = true
	return ev

func assert_eq(actual, expected, msg: String) -> void:
	if actual == expected:
		pass_count += 1
		print("  PASS: " + msg)
	else:
		fail_count += 1
		print("  FAIL: " + msg + " (expected %s, got %s)" % [str(expected), str(actual)])

func assert_true(cond: bool, msg: String) -> void:
	assert_eq(cond, true, msg)

func action_event_count() -> int:
	return InputMap.get_action_list(test_action).size()

func action_has_joy_button(index: int) -> bool:
	for e in InputMap.get_action_list(test_action):
		if e is InputEventJoypadButton and e.button_index == index:
			return true
	return false

func action_has_joy_axis(axis: int) -> bool:
	for e in InputMap.get_action_list(test_action):
		if e is InputEventJoypadMotion and e.axis == axis:
			return true
	return false

func action_has_key(sc: int) -> bool:
	for e in InputMap.get_action_list(test_action):
		if e is InputEventKey and e.scancode == sc:
			return true
	return false

# --- Tests ---

func test_switch_events_with_old_event() -> void:
	print("test_switch_events_with_old_event:")
	reset_test_action()
	var old_ev := make_joy_button(0)
	InputMap.action_add_event(test_action, old_ev)
	assert_eq(action_event_count(), 1, "starts with 1 event")

	var new_ev := make_joy_button(3)
	switch_events(new_ev, test_action, old_ev)

	assert_eq(action_event_count(), 1, "still has 1 event after switch")
	assert_true(action_has_joy_button(3), "new event (btn 3) is present")
	assert_true(not action_has_joy_button(0), "old event (btn 0) is removed")

func test_switch_events_without_old_event_preserves_existing() -> void:
	print("test_switch_events_without_old_event_preserves_existing:")
	reset_test_action()
	var key_ev := make_key(KEY_Z)
	var joy_ev := make_joy_button(0)
	InputMap.action_add_event(test_action, key_ev)
	InputMap.action_add_event(test_action, joy_ev)
	assert_eq(action_event_count(), 2, "starts with 2 events")

	# FIXED: switch_events with null old_event should NOT erase all events
	var new_ev := make_joy_button(5)
	switch_events(new_ev, test_action, null)

	assert_true(action_event_count() >= 2, "existing events preserved (count >= 2, got " + str(action_event_count()) + ")")
	assert_true(action_has_key(KEY_Z), "keyboard event still present")
	assert_true(action_has_joy_button(5), "new event added")

	# Demonstrate the bug in the old code
	print("  (demonstrating old buggy behavior:)")
	reset_test_action()
	InputMap.action_add_event(test_action, key_ev)
	InputMap.action_add_event(test_action, joy_ev)
	switch_events_buggy(new_ev, test_action, null)
	assert_eq(action_event_count(), 1, "[OLD BUG] old code nuked all events to just 1")

func test_clear_action_event() -> void:
	print("test_clear_action_event:")
	reset_test_action()
	var ev := make_joy_button(4)
	InputMap.action_add_event(test_action, ev)
	assert_eq(action_event_count(), 1, "starts with 1 event")

	clear_action_event(test_action, ev)
	assert_eq(action_event_count(), 0, "event cleared")

func test_clear_action_event_null_is_safe() -> void:
	print("test_clear_action_event_null_is_safe:")
	reset_test_action()
	var ev := make_joy_button(2)
	InputMap.action_add_event(test_action, ev)

	clear_action_event(test_action, null)
	assert_eq(action_event_count(), 1, "no change when clearing null event")

func test_dual_joypad_bindings() -> void:
	print("test_dual_joypad_bindings:")
	reset_test_action()
	var joy1 := make_joy_button(3)
	var joy2 := make_joy_button(5)
	var key_ev := make_key(KEY_X)

	InputMap.action_add_event(test_action, key_ev)
	InputMap.action_add_event(test_action, joy1)
	InputMap.action_add_event(test_action, joy2)

	assert_eq(action_event_count(), 3, "has 3 events (1 key + 2 joypad)")
	assert_true(action_has_key(KEY_X), "keyboard event present")
	assert_true(action_has_joy_button(3), "joypad 1 (btn 3) present")
	assert_true(action_has_joy_button(5), "joypad 2 (btn 5) present")

func test_clear_one_joypad_keeps_other() -> void:
	print("test_clear_one_joypad_keeps_other:")
	reset_test_action()
	var joy1 := make_joy_button(3)
	var joy2 := make_joy_button(5)
	InputMap.action_add_event(test_action, joy1)
	InputMap.action_add_event(test_action, joy2)
	assert_eq(action_event_count(), 2, "starts with 2 joypad events")

	clear_action_event(test_action, joy2)
	assert_eq(action_event_count(), 1, "1 event remaining after clear")
	assert_true(action_has_joy_button(3), "first joypad (btn 3) still present")
	assert_true(not action_has_joy_button(5), "second joypad (btn 5) removed")

func test_switch_replaces_correct_event_in_multi_binding() -> void:
	print("test_switch_replaces_correct_event_in_multi_binding:")
	reset_test_action()
	var key_ev := make_key(KEY_Z)
	var joy1 := make_joy_button(3)
	var joy2 := make_joy_button(5)
	InputMap.action_add_event(test_action, key_ev)
	InputMap.action_add_event(test_action, joy1)
	InputMap.action_add_event(test_action, joy2)
	assert_eq(action_event_count(), 3, "starts with 3 events")

	var new_joy := make_joy_button(4)
	switch_events(new_joy, test_action, joy2)

	assert_eq(action_event_count(), 3, "still 3 events after replacing joy2")
	assert_true(action_has_key(KEY_Z), "keyboard unchanged")
	assert_true(action_has_joy_button(3), "joypad 1 (btn 3) unchanged")
	assert_true(action_has_joy_button(4), "joypad 2 now btn 4")
	assert_true(not action_has_joy_button(5), "old joypad 2 (btn 5) removed")

func test_joypad_axis_binding() -> void:
	print("test_joypad_axis_binding:")
	reset_test_action()
	var axis_ev := make_joy_axis(2, 1.0)
	InputMap.action_add_event(test_action, axis_ev)
	assert_eq(action_event_count(), 1, "axis event added")
	assert_true(action_has_joy_axis(2), "axis 2 present")

	var btn_ev := make_joy_button(5)
	InputMap.action_add_event(test_action, btn_ev)
	assert_eq(action_event_count(), 2, "axis + button = 2 events")

	clear_action_event(test_action, axis_ev)
	assert_eq(action_event_count(), 1, "1 event after clearing axis")
	assert_true(action_has_joy_button(5), "button still present")
	assert_true(not action_has_joy_axis(2), "axis removed")

func test_conflict_groups() -> void:
	print("test_conflict_groups:")
	# Same group should conflict
	assert_true(actions_can_conflict("fire", "jump"), "fire vs jump conflict (both gameplay)")
	assert_true(actions_can_conflict("move_left", "dash"), "move_left vs dash conflict (both gameplay)")
	assert_true(actions_can_conflict("pause", "ui_accept"), "pause vs ui_accept conflict (both menu)")
	assert_true(actions_can_conflict("analog_left", "analog_right"), "analog_left vs analog_right conflict (both weapon_wheel)")

	# Different groups should NOT conflict
	assert_true(not actions_can_conflict("fire", "pause"), "fire vs pause no conflict (gameplay vs menu)")
	assert_true(not actions_can_conflict("jump", "ui_accept"), "jump vs ui_accept no conflict (gameplay vs menu)")
	assert_true(not actions_can_conflict("fire", "analog_left"), "fire vs analog_left no conflict (gameplay vs wheel)")
	assert_true(not actions_can_conflict("pause", "analog_up"), "pause vs analog_up no conflict (menu vs wheel)")

	# Unknown actions should not conflict with anything
	assert_true(not actions_can_conflict("fire", "_unknown"), "fire vs unknown no conflict")
	assert_true(not actions_can_conflict("_unknown", "_unknown2"), "unknown vs unknown2 no conflict")

	# Same action should not conflict with itself
	assert_eq(get_conflict_group("fire"), "gameplay", "fire is in gameplay group")
	assert_eq(get_conflict_group("pause"), "menu", "pause is in menu group")
	assert_eq(get_conflict_group("analog_left"), "weapon_wheel", "analog_left is in weapon_wheel group")
	assert_eq(get_conflict_group("_unknown"), "", "unknown has no group")

func test_short_joy_names() -> void:
	print("test_short_joy_names:")
	# Test the short name lookup tables from ActionInput.gd
	# We replicate the logic here since we can't load the scene script
	var btn_short := {
		"Face Button Bottom": "A",
		"Face Button Right": "B",
		"Face Button Left": "X",
		"Face Button Top": "Y",
		"Left Shoulder": "LB",
		"Right Shoulder": "RB",
		"L": "LB",
		"R": "RB",
		"L2": "LT",
		"R2": "RT",
	}
	var axis_short := {
		"Left Stick X": "LX",
		"Left Stick Y": "LY",
		"Right Stick X": "RX",
		"Right Stick Y": "RY",
		"Left Trigger": "LT",
		"Right Trigger": "RT",
	}
	var axis_index_names := {
		0: "LX", 1: "LY", 2: "LT",
		3: "RX", 4: "RY", 5: "RT",
	}
	var axis_dirs := {
		"LX": ["L", "R"],
		"LY": ["U", "D"],
		"RX": ["L", "R"],
		"RY": ["U", "D"],
	}

	# Button abbreviations
	assert_eq(btn_short.get("Face Button Bottom", "Face Button Bottom"), "A", "Face Button Bottom -> A")
	assert_eq(btn_short.get("Face Button Top", "Face Button Top"), "Y", "Face Button Top -> Y")
	assert_eq(btn_short.get("Left Shoulder", "Left Shoulder"), "LB", "Left Shoulder -> LB")
	assert_eq(btn_short.get("L", "L"), "LB", "L -> LB")
	assert_eq(btn_short.get("R", "R"), "RB", "R -> RB")

	# Axis abbreviations
	assert_eq(axis_short.get("Left Stick X", "Left Stick X"), "LX", "Left Stick X -> LX")
	assert_eq(axis_short.get("Right Trigger", "Right Trigger"), "RT", "Right Trigger -> RT")

	# Unknown names pass through
	assert_eq(btn_short.get("Unknown Button", "Unknown Button"), "Unknown Button", "Unknown passes through")

func test_axis_index_fallback() -> void:
	print("test_axis_index_fallback:")
	# Replicate short_joy_axis logic with AXIS_INDEX_NAMES fallback
	var axis_short := {
		"Left Stick X": "LX", "Left Stick Y": "LY",
		"Right Stick X": "RX", "Right Stick Y": "RY",
		"Left Trigger": "LT", "Right Trigger": "RT",
	}
	var axis_index_names := {
		0: "LX", 1: "LY", 2: "LT",
		3: "RX", 4: "RY", 5: "RT",
	}
	var axis_dirs := {
		"LX": ["L", "R"], "LY": ["U", "D"],
		"RX": ["L", "R"], "RY": ["U", "D"],
	}

	# Simulate short_joy_axis for the exact bug case:
	# Input.get_joy_axis_string(4) returns "" on xpad
	var full_name := ""  # empty, as returned by Input.get_joy_axis_string(4)
	var axis := 4
	var base_name: String

	# OLD behavior (falls to Ax%d, no direction)
	if full_name in axis_short:
		base_name = axis_short[full_name]
	elif full_name != "":
		base_name = full_name
	elif axis >= 0:
		base_name = "Ax%d" % axis
	assert_eq(base_name, "Ax4", "[OLD] axis 4 with empty name -> Ax4")
	assert_true(not (base_name in axis_dirs), "[OLD] Ax4 not in axis_dirs, no direction")

	# NEW behavior (falls to AXIS_INDEX_NAMES, gets RY, then direction)
	base_name = ""
	if full_name in axis_short:
		base_name = axis_short[full_name]
	elif full_name != "":
		base_name = full_name
	elif axis in axis_index_names:
		base_name = axis_index_names[axis]
	elif axis >= 0:
		base_name = "Ax%d" % axis
	assert_eq(base_name, "RY", "[NEW] axis 4 with empty name -> RY via index lookup")
	assert_true(base_name in axis_dirs, "[NEW] RY is in axis_dirs")

	# Test direction suffix for RY
	var axis_value_up := -1.0
	var axis_value_down := 1.0
	if base_name in axis_dirs and axis_value_up != 0.0:
		var dir_up = axis_dirs[base_name][0] if axis_value_up < 0 else axis_dirs[base_name][1]
		assert_eq(base_name + " " + dir_up, "RY U", "axis 4 value=-1.0 -> RY U")
	if base_name in axis_dirs and axis_value_down != 0.0:
		var dir_down = axis_dirs[base_name][0] if axis_value_down < 0 else axis_dirs[base_name][1]
		assert_eq(base_name + " " + dir_down, "RY D", "axis 4 value=1.0 -> RY D")

	# All axis indices should resolve
	for idx in axis_index_names:
		assert_true(axis_index_names[idx] != "", "axis %d has a name" % idx)

	# Trigger axes should not have direction suffixes
	assert_true(not ("LT" in axis_dirs), "LT (axis 2) has no direction")
	assert_true(not ("RT" in axis_dirs), "RT (axis 5) has no direction")

func test_unmapped_controller_names() -> void:
	print("test_unmapped_controller_names:")
	# Replicate the exact short_joy_btn / short_joy_axis logic from ActionInput.gd
	# to verify both joy_known=true (SDL-mapped) and joy_known=false (raw xpad) paths.

	var JOY_BTN_SHORT := {
		"Face Button Bottom": "A", "Face Button Right": "B",
		"Face Button Left": "X", "Face Button Top": "Y",
		"Left Shoulder": "LB", "Right Shoulder": "RB",
		"Left Trigger": "LT", "Right Trigger": "RT",
		"Left Stick": "L3", "Right Stick": "R3",
		"DPAD Up": "D-Up", "DPAD Down": "D-Dn",
		"DPAD Left": "D-L", "DPAD Right": "D-R",
		"L": "LB", "L2": "LT", "L3": "L3",
		"R": "RB", "R2": "RT", "R3": "R3",
		"Select": "Back", "Start": "Start", "Guide": "Guide",
	}
	var JOY_AXIS_SHORT := {
		"Left Stick X": "LX", "Left Stick Y": "LY",
		"Right Stick X": "RX", "Right Stick Y": "RY",
		"Left Trigger": "LT", "Right Trigger": "RT",
	}
	var AXIS_INDEX_NAMES := {
		0: "LX", 1: "LY", 2: "LT",
		3: "RX", 4: "RY", 5: "RT",
	}
	var BTN_INDEX_NAMES := {
		0: "A", 1: "B", 2: "X", 3: "Y",
		4: "LB", 5: "RB", 6: "Back", 7: "Start",
		8: "Guide", 9: "L3", 10: "R3",
		12: "D-Up", 13: "D-Dn", 14: "D-L", 15: "D-R",
	}
	var AXIS_DIRS := {
		"LX": ["L", "R"], "LY": ["U", "D"],
		"RX": ["L", "R"], "RY": ["U", "D"],
	}

	# --- Helper lambdas (replicate exact ActionInput.gd logic) ---
	# We inline the logic since GDScript 3.x doesn't have lambdas

	# ============================================================
	# BUTTONS: joy_known=true (SDL-mapped controller)
	# Godot returns correct names, so we trust Input.get_joy_button_string()
	# ============================================================
	print("  -- Buttons: joy_known=true (SDL-mapped controller) --")

	# Godot standard: btn 0 = "Face Button Bottom" → A
	var result = _short_btn(JOY_BTN_SHORT, BTN_INDEX_NAMES, "Face Button Bottom", 0, true)
	assert_eq(result, "A", "[known] btn 0 'Face Button Bottom' -> A")

	# Godot standard: btn 6 = "L2" → LT (correct for SDL controller where btn 6 IS L2)
	result = _short_btn(JOY_BTN_SHORT, BTN_INDEX_NAMES, "L2", 6, true)
	assert_eq(result, "LT", "[known] btn 6 'L2' -> LT (correct for SDL)")

	# Godot standard: btn 7 = "R2" → RT
	result = _short_btn(JOY_BTN_SHORT, BTN_INDEX_NAMES, "R2", 7, true)
	assert_eq(result, "RT", "[known] btn 7 'R2' -> RT (correct for SDL)")

	# Godot standard: btn 8 = "L3"
	result = _short_btn(JOY_BTN_SHORT, BTN_INDEX_NAMES, "L3", 8, true)
	assert_eq(result, "L3", "[known] btn 8 'L3' -> L3 (correct for SDL)")

	# Godot standard: btn 9 = "R3"
	result = _short_btn(JOY_BTN_SHORT, BTN_INDEX_NAMES, "R3", 9, true)
	assert_eq(result, "R3", "[known] btn 9 'R3' -> R3 (correct for SDL)")

	# Godot standard: btn 10 = "Select" → Back
	result = _short_btn(JOY_BTN_SHORT, BTN_INDEX_NAMES, "Select", 10, true)
	assert_eq(result, "Back", "[known] btn 10 'Select' -> Back (correct for SDL)")

	# Godot standard: btn 11 = "Start"
	result = _short_btn(JOY_BTN_SHORT, BTN_INDEX_NAMES, "Start", 11, true)
	assert_eq(result, "Start", "[known] btn 11 'Start' -> Start (correct for SDL)")

	# ============================================================
	# BUTTONS: joy_known=false (unmapped xpad controller)
	# Godot returns WRONG names for indices 6-10, so use raw index table
	# ============================================================
	print("  -- Buttons: joy_known=false (unmapped xpad) --")

	# Buttons 0-5 match, but we still use raw table (which has same values)
	result = _short_btn(JOY_BTN_SHORT, BTN_INDEX_NAMES, "Face Button Bottom", 0, false)
	assert_eq(result, "A", "[unmapped] btn 0 -> A")

	result = _short_btn(JOY_BTN_SHORT, BTN_INDEX_NAMES, "Left Shoulder", 4, false)
	assert_eq(result, "LB", "[unmapped] btn 4 -> LB")

	# btn 6: Godot says "L2"→LT but xpad says Back
	result = _short_btn(JOY_BTN_SHORT, BTN_INDEX_NAMES, "L2", 6, false)
	assert_eq(result, "Back", "[unmapped] btn 6 -> Back (NOT LT)")

	# btn 7: Godot says "R2"→RT but xpad says Start
	result = _short_btn(JOY_BTN_SHORT, BTN_INDEX_NAMES, "R2", 7, false)
	assert_eq(result, "Start", "[unmapped] btn 7 -> Start (NOT RT)")

	# btn 8: Godot says "L3" but xpad says Guide
	result = _short_btn(JOY_BTN_SHORT, BTN_INDEX_NAMES, "L3", 8, false)
	assert_eq(result, "Guide", "[unmapped] btn 8 -> Guide (NOT L3)")

	# btn 9: Godot says "R3" but xpad says L3
	result = _short_btn(JOY_BTN_SHORT, BTN_INDEX_NAMES, "R3", 9, false)
	assert_eq(result, "L3", "[unmapped] btn 9 -> L3 (NOT R3)")

	# btn 10: Godot says "Select"→Back but xpad says R3
	result = _short_btn(JOY_BTN_SHORT, BTN_INDEX_NAMES, "Select", 10, false)
	assert_eq(result, "R3", "[unmapped] btn 10 -> R3 (NOT Back)")

	# DPAD buttons match (12-15)
	result = _short_btn(JOY_BTN_SHORT, BTN_INDEX_NAMES, "DPAD Up", 12, false)
	assert_eq(result, "D-Up", "[unmapped] btn 12 -> D-Up")

	# ============================================================
	# AXES: joy_known=true (SDL-mapped controller)
	# ============================================================
	print("  -- Axes: joy_known=true (SDL-mapped controller) --")

	# SDL axis 0 = "Left Stick X" → LX (matches for both)
	var axis_result = _short_axis(JOY_AXIS_SHORT, AXIS_INDEX_NAMES, AXIS_DIRS, "Left Stick X", 0, -1.0, true)
	assert_eq(axis_result, "LX L", "[known] axis 0 'Left Stick X' val=-1.0 -> LX L")

	axis_result = _short_axis(JOY_AXIS_SHORT, AXIS_INDEX_NAMES, AXIS_DIRS, "Left Stick Y", 1, 1.0, true)
	assert_eq(axis_result, "LY D", "[known] axis 1 'Left Stick Y' val=1.0 -> LY D")

	# SDL axis 2 = "Right Stick X" → RX (correct for SDL where axis 2 IS RX)
	axis_result = _short_axis(JOY_AXIS_SHORT, AXIS_INDEX_NAMES, AXIS_DIRS, "Right Stick X", 2, -1.0, true)
	assert_eq(axis_result, "RX L", "[known] axis 2 'Right Stick X' val=-1.0 -> RX L (correct for SDL)")

	# SDL axis 3 = "Right Stick Y" → RY (correct for SDL where axis 3 IS RY)
	axis_result = _short_axis(JOY_AXIS_SHORT, AXIS_INDEX_NAMES, AXIS_DIRS, "Right Stick Y", 3, -1.0, true)
	assert_eq(axis_result, "RY U", "[known] axis 3 'Right Stick Y' val=-1.0 -> RY U (correct for SDL)")

	# SDL axis 6 = "Left Trigger" → LT (no direction for triggers)
	axis_result = _short_axis(JOY_AXIS_SHORT, AXIS_INDEX_NAMES, AXIS_DIRS, "Left Trigger", 6, 1.0, true)
	assert_eq(axis_result, "LT", "[known] axis 6 'Left Trigger' -> LT (no direction)")

	# ============================================================
	# AXES: joy_known=false (unmapped xpad controller)
	# ============================================================
	print("  -- Axes: joy_known=false (unmapped xpad) --")

	# xpad axis 0 = LX (matches standard)
	axis_result = _short_axis(JOY_AXIS_SHORT, AXIS_INDEX_NAMES, AXIS_DIRS, "Left Stick X", 0, 1.0, false)
	assert_eq(axis_result, "LX R", "[unmapped] axis 0 val=1.0 -> LX R")

	# xpad axis 2: Godot says "Right Stick X"→RX, but xpad says LT
	axis_result = _short_axis(JOY_AXIS_SHORT, AXIS_INDEX_NAMES, AXIS_DIRS, "Right Stick X", 2, 1.0, false)
	assert_eq(axis_result, "LT", "[unmapped] axis 2 -> LT (NOT RX)")

	# xpad axis 3: Godot says "Right Stick Y"→RY, but xpad says RX
	axis_result = _short_axis(JOY_AXIS_SHORT, AXIS_INDEX_NAMES, AXIS_DIRS, "Right Stick Y", 3, -1.0, false)
	assert_eq(axis_result, "RX L", "[unmapped] axis 3 val=-1.0 -> RX L (NOT RY U)")

	axis_result = _short_axis(JOY_AXIS_SHORT, AXIS_INDEX_NAMES, AXIS_DIRS, "Right Stick Y", 3, 1.0, false)
	assert_eq(axis_result, "RX R", "[unmapped] axis 3 val=1.0 -> RX R")

	# xpad axis 4: Godot returns "" (undefined), xpad says RY
	axis_result = _short_axis(JOY_AXIS_SHORT, AXIS_INDEX_NAMES, AXIS_DIRS, "", 4, -1.0, false)
	assert_eq(axis_result, "RY U", "[unmapped] axis 4 val=-1.0 -> RY U")

	axis_result = _short_axis(JOY_AXIS_SHORT, AXIS_INDEX_NAMES, AXIS_DIRS, "", 4, 1.0, false)
	assert_eq(axis_result, "RY D", "[unmapped] axis 4 val=1.0 -> RY D")

	# xpad axis 5: Godot returns "" (undefined), xpad says RT
	axis_result = _short_axis(JOY_AXIS_SHORT, AXIS_INDEX_NAMES, AXIS_DIRS, "", 5, 1.0, false)
	assert_eq(axis_result, "RT", "[unmapped] axis 5 -> RT (no direction)")

# --- Helper functions replicating ActionInput.gd logic exactly ---

func _short_btn(btn_short: Dictionary, btn_index: Dictionary, full_name: String, button_index: int, joy_known: bool) -> String:
	if not joy_known and button_index in btn_index:
		return btn_index[button_index]
	if full_name in btn_short:
		return btn_short[full_name]
	if full_name != "":
		return full_name
	if button_index in btn_index:
		return btn_index[button_index]
	if button_index >= 0:
		return "Btn%d" % button_index
	return "???"

func _short_axis(axis_short: Dictionary, axis_index: Dictionary, axis_dirs: Dictionary, full_name: String, axis: int, axis_value: float, joy_known: bool) -> String:
	var base_name: String
	if not joy_known and axis in axis_index:
		base_name = axis_index[axis]
	elif full_name in axis_short:
		base_name = axis_short[full_name]
	elif full_name != "":
		base_name = full_name
	elif axis in axis_index:
		base_name = axis_index[axis]
	elif axis >= 0:
		base_name = "Ax%d" % axis
	else:
		return "???"
	if base_name in axis_dirs and axis_value != 0.0:
		var dir = axis_dirs[base_name][0] if axis_value < 0 else axis_dirs[base_name][1]
		return base_name + " " + dir
	return base_name
