extends VBoxContainer

export (PackedScene) var input_holder
onready var main: CanvasLayer = $"../../.."

var configurable = {
	"move_left" : "LEFT_ACT",
	"move_right" : "RIGHT_ACT",
	"move_up" : "UP_ACT",
	"move_down" : "DOWN_ACT",
	"fire" : "SHOT_ACT",
	"alt_fire" : "SHOT2_ACT",
	"jump" : "JUMP_ACT",
	"dash" : "DASH_ACT",
	"select_special" : "ARMORABILITY_ACT",
	"weapon_select_left" : "PREV_ACT",
	"weapon_select_right" : "NEXT_ACT",
	"pause" : "PAUSE_ACT",
	#"select" : "Options Menu",
	"ui_accept" : "CONFIRM_ACT",
	"analog_left" : "WPNLEFT_ACT",
	"analog_right" : "WPNRIGHT_ACT",
	"analog_up" : "WPNUP_ACT",
	"analog_down" : "WPNDOWN_ACT",
	"reset_weapon" : "WPNRESET_ACT"
}

onready var exit: TextureButton = $"../../exit"
onready var profile_btn = $"../../ProfileRow/Button"

func _ready() -> void:
	Setup_actions()
	InputManager.connect("profile_applied", self, "refresh_all_actions")

func Setup_actions() -> void:
	var last_child
	for action in configurable.keys():
		last_child = instantiate(action)
	Set_neighbours(last_child)

func instantiate(action) -> Node:
	var instance = input_holder.instance()
	add_child(instance,true)
	instance.setup(action, configurable[action], main)
	return instance

func Set_neighbours(last_child) -> void:
	# Focus chain: exit ↔ profile selector ↔ first action ... last action ↔ exit
	exit.focus_neighbour_top = last_child.get_child(0).get_path()
	exit.focus_neighbour_bottom = profile_btn.get_path()
	profile_btn.focus_neighbour_top = exit.get_path()
	profile_btn.focus_neighbour_bottom = get_child(0).get_child(0).get_path()
	get_child(0).get_child(0).focus_neighbour_top = profile_btn.get_path()
	get_child(0).get_child(1).focus_neighbour_top = profile_btn.get_path()
	get_child(0).get_child(2).focus_neighbour_top = profile_btn.get_path()
	last_child.get_child(0).focus_neighbour_bottom = exit.get_path()
	last_child.get_child(1).focus_neighbour_bottom = exit.get_path()
	last_child.get_child(2).focus_neighbour_bottom = exit.get_path()

func refresh_all_actions() -> void:
	for child in get_children():
		if child.has_method("get_inputs_and_set_names"):
			child.get_inputs_and_set_names()
