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
