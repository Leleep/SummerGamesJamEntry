extends Node

var profiles: Dictionary = {
	"0": {
		"remap": {},
		"disabled": [],
		"forced": {},
		"jammed": [],
		"axis_multiplier": 1.0
	},
	"1": {
		"remap": {&"left": &"right", &"right": &"left"},
		"disabled": [],
		"forced": {},
		"jammed": [],
		"axis_multiplier": -1.0
	},
	"2": {
		"remap": {&"jump": &"left_click", &"left_click": &"jump"},
		"disabled": [],
		"forced": {},
		"jammed": [],
		"axis_multiplier": 1.0
	},
	"3": {
		"remap": {},
		"disabled": [],
		"forced": {},
		"jammed": [&"down"],
		"axis_multiplier": 1.0
	},
	"4": {
		"remap": {},
		"disabled": [],
		"forced": {},
		"jammed": [],
		"axis_multiplier": 0.5
	},
	"5": {
		"remap": {},
		"disabled": [],
		"forced": {},
		"jammed": [&"jump"],
		"axis_multiplier": 1.0
	},
	"6": {
		"remap": {},
		"disabled": [],
		"forced": {},
		"jammed": [&"left_click"],
		"axis_multiplier": 1.0
	},
	"7": {
		"remap": {&"jump": &"down", &"down": &"jump"},
		"disabled": [],
		"forced": {},
		"jammed": [],
		"axis_multiplier": 1.0
	},
	"8": {
		"remap": {},
		"disabled": [],
		"forced": {},
		"jammed": [&"left"],
		"axis_multiplier": 1.2
	},
	"9": {
		"remap": {&"left_click": &"down", &"down": &"left_click"},
		"disabled": [],
		"forced": {},
		"jammed": [],
		"axis_multiplier": 1.0
	},
	"10": {
		"remap": {},
		"disabled": [],
		"forced": {},
		"jammed": [&"right"],
		"axis_multiplier": 1.0
	}
}

var current_profile: Dictionary = profiles["0"]

var jammed_last_press_time: Dictionary = {}
var jammed_is_active: Dictionary = {}
const JAMMED_WINDOW: float = 0.2 

func randomize():
	var list = profiles.keys()
	current_profile = profiles[list[randi_range(0,len(list)-1)]]
	print(current_profile)

func set_profile(profile_name: String) -> void:
	if profiles.has(profile_name):
		current_profile = profiles[profile_name]
		jammed_last_press_time.clear()
		jammed_is_active.clear()
	else:
		push_warning("InputManager: Profile '" + profile_name + "' does not exist!")

func _is_disabled(action: StringName) -> bool:
	var disabled_list = current_profile.get("disabled", [])
	return action in disabled_list

func _get_forced_state(action: StringName) -> Variant:
	var forced_dict = current_profile.get("forced", {})
	if forced_dict.has(action):
		return forced_dict[action]
	return null

func _get_mapped_action(action: StringName) -> StringName:
	var remap_dict = current_profile.get("remap", {})
	return remap_dict.get(action, action)

func _get_action_strength_modified(action: StringName) -> float:
	if _is_disabled(action):
		return 0.0
		
	var forced = _get_forced_state(action)
	if forced != null:
		return 1.0 if bool(forced) else 0.0
		
	var target_action = _get_mapped_action(action)
	var raw_pressed = Input.is_action_pressed(target_action)
	var jammed_list = current_profile.get("jammed", [])
	
	if action in jammed_list:
		if not raw_pressed:
			jammed_is_active[action] = false
			return 0.0
		return Input.get_action_strength(target_action) if jammed_is_active.get(action, false) else 0.0
		
	return Input.get_action_strength(target_action)

func is_action_pressed(action: StringName) -> bool:
	return _get_action_strength_modified(action) > 0.0

func is_action_just_pressed(action: StringName) -> bool:
	if _is_disabled(action):
		return false
		
	var forced = _get_forced_state(action)
	if forced != null:
		return bool(forced)
		
	var target_action = _get_mapped_action(action)
	var raw_just_pressed = Input.is_action_just_pressed(target_action)
	var jammed_list = current_profile.get("jammed", [])
	
	if action in jammed_list:
		var current_time = Time.get_ticks_msec() * 0.001
		
		if raw_just_pressed:
			var last_time = jammed_last_press_time.get(action, -1.0)
			jammed_last_press_time[action] = current_time
			
			if last_time != -1.0 and (current_time - last_time) <= JAMMED_WINDOW:
				jammed_is_active[action] = true
				return true
			else:
				jammed_is_active[action] = false
				return false
				
		return false
		
	return raw_just_pressed

func get_axis(negative_action: StringName, positive_action: StringName) -> float:
	var mult = current_profile.get("axis_multiplier", 1.0)
	if mult == 0.0:
		return 0.0
		
	var neg_val = _get_action_strength_modified(negative_action)
	var pos_val = _get_action_strength_modified(positive_action)
	
	var axis_value = pos_val - neg_val
	return axis_value * mult
