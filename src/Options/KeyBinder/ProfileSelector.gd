extends X8OptionButton

const Profiles = preload("res://src/Options/KeyBinder/ControllerProfiles.gd")

var profile_names := Profiles.get_profile_names()
var current_index := 0

func _ready() -> void:
	# Set up menu (from X8TextureButton) for lock/unlock signals
	if menu_path:
		menu = get_node(menu_path)
		connect_lock_signals(menu)
	# Connect save/load signals (from X8OptionButton), guarded against re-entry
	if not Savefile.is_connected("loaded", self, "setup"):
		var _s = Savefile.connect("loaded", self, "setup")
		Event.listen("update_options", self, "setup")
	if not InputManager.is_connected("manual_rebind", self, "_on_manual_rebind"):
		InputManager.connect("manual_rebind", self, "_on_manual_rebind")

func setup() -> void:
	var saved = Configurations.get("ControllerProfile")
	if saved and saved in profile_names:
		current_index = profile_names.find(saved)
	else:
		current_index = 0  # Default
	display_value(tr(profile_names[current_index]))

func increase_value() -> void:
	current_index = (current_index + 1) % profile_names.size()
	_apply_current()

func decrease_value() -> void:
	current_index = (current_index - 1 + profile_names.size()) % profile_names.size()
	_apply_current()

func _apply_current() -> void:
	var profile_name = profile_names[current_index]
	Configurations.set("ControllerProfile", profile_name)
	display_value(tr(profile_name))
	if profile_name == Profiles.PROFILE_CUSTOM:
		return
	var data = Profiles.get_profile_data(profile_name)
	InputManager.apply_joypad_profile(data)

func _on_manual_rebind() -> void:
	current_index = profile_names.find(Profiles.PROFILE_CUSTOM)
	Configurations.set("ControllerProfile", Profiles.PROFILE_CUSTOM)
	display_value(tr(Profiles.PROFILE_CUSTOM))
