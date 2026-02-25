extends Node

var observed_inputs = ["move_right","move_left", "move_up", "move_down"]
var last_inputs = []
var last_timings = []
var current_associated_key := ""
var timing_leeway := 0.25
var timer := 0.0

var modified_keys = {}

var combos : Dictionary

var _joy_log_file : File
var _joy_log_path := "user://joy_log.txt"

# Conflict groups: actions in the same group warn when sharing a button
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

func _input(_event: InputEvent) -> void:
	# TEMP: Log all joypad events to file
	if _event is InputEventJoypadButton:
		_log_joy("BTN %d pressed=%s" % [_event.button_index, str(_event.pressed)])
	elif _event is InputEventJoypadMotion:
		if abs(_event.axis_value) > 0.15:
			_log_joy("AXIS %d value=%.3f" % [_event.axis, _event.axis_value])

func _log_joy(msg: String) -> void:
	if not _joy_log_file:
		_joy_log_file = File.new()
		_joy_log_file.open(_joy_log_path, File.WRITE)
	_joy_log_file.store_line(str(OS.get_ticks_msec()) + " " + msg)
	_joy_log_file.flush()

func _ready() -> void:
	var _s = Configurations.connect("value_changed",self,"activate_dash")

func activate_dash(key) -> void:
	if key == "DashCommand":
		if Configurations.get(key):
			var double_front = InputPressCombo.new(["move_right","move_right"], 0.25)
			combos["dash"] = double_front
		else:
			var _v = combos.erase("dash")


func _physics_process(delta: float) -> void:
	timer += delta
	add_inputs_to_list()
	check_for_combos()
	release_input_when_key_is_released()

func check_for_combos() -> void:
	for combo in get_combos_that_matches_last_input():
		if matches_all_inputs(combo):
			activate_combo(combo)

func get_combos_that_matches_last_input() -> Array:
	var matching_combos = []
	for key in combos.keys():
		var inputs = combos[key].inputs
		var combo_last_input = inputs[inputs.size()-1]
		if get_last_input() == combo_last_input:
			matching_combos.append(key)
		elif is_facing_back():
			if get_last_input() == Tools.flip_input(combo_last_input):
				matching_combos.append(key)

	return matching_combos

func is_facing_back() -> bool:
	if GameManager.is_player_in_scene():
		return GameManager.player.get_facing_direction() == -1
	return false

func matches_all_inputs(key : String) -> bool:
	return combos[key].matches(last_inputs,last_timings,timing_leeway)

func add_inputs_to_list() -> void:
	for key in observed_inputs:
		if Input.is_action_just_pressed(key):
			last_inputs.append(key)
			last_timings.append(timer)

func activate_combo(key) -> void:
	var event = InputEventAction.new()
	event.action = key
	event.pressed = true
	Input.parse_input_event(event)
	#Input.action_press(key)
	current_associated_key = get_last_input()
	last_inputs.clear()
	last_timings.clear()

func release_input_when_key_is_released() -> void:
	if current_associated_key != "":
		if Input.is_action_just_released(current_associated_key):
			var event = InputEventAction.new()
			event.action = "dash"
			event.pressed = false
			Input.parse_input_event(event)
			current_associated_key = ""

func get_last_input() -> String:
	if size()>= 0:
		return last_inputs[size()]

	return ""

func size() -> int:
	return last_inputs.size() - 1

func add_to_file(action,event,old_event):
	if not action in modified_keys.keys():
		modified_keys[action] = [event, old_event]
	else:
		var new_action = "00_" + action
		modified_keys[new_action] = [event, old_event]

func load_modified_keys(new_keys) -> void:
	# TEMP: Force-reset all keybinds to defaults (remove after confirming controller works)
	print("InputManager: Resetting all keybinds to defaults")
	modified_keys.clear()
	InputMap.load_from_globals()
	# Force English locale
	TranslationServer.set_locale("en")
	return

func get_default_key(action, old_event) -> InputEvent:
	var InputType = define_event_type(old_event)
	var input_list = InputMap.get_action_list(action)
	for event in input_list:
		if event is InputType:
			return event
	return old_event

func define_event_type(event):
	if event is InputEventJoypadButton:
		return InputEventJoypadButton
	elif event is InputEventJoypadMotion:
		return InputEventJoypadMotion
	elif event is InputEventKey:
		return InputEventKey
	elif event is InputEventMouseButton:
		return InputEventMouseButton
	push_error("Unable to find type for event " + str(event))

signal double_check(event_text, action_display, action_key)
signal double_detected(event_text, action_display, action_key)

func set_new_action_event(action,event,old_event) -> void:
	ui_case_handler(event, action)
	switch_events(event, action, old_event)
	add_to_file(action,var2str(event),var2str(old_event))

func ui_case_handler(event, action) -> void: #TODO: resolver bug de seta não funcionando no menu
	if "move" in action:
		var extra_action = "ui" + action.trim_prefix("move")
		InputMap.action_erase_events(extra_action)
		InputMap.action_add_event(extra_action, event)
		InputMap.action_set_deadzone(extra_action,.85)

func switch_events(event, action, old_event) -> void:
	if old_event:
		InputMap.action_erase_event(action, old_event)
	InputMap.action_add_event(action, event)
	InputMap.action_set_deadzone(action,.85)

func clear_action_event(action, old_event) -> void:
	if old_event:
		InputMap.action_erase_event(action, old_event)
