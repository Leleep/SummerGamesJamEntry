extends Node

@export var camera: Camera2D
@export var player: Player

# ==============================================================================
# CENTRALIZED CONFIGURATION
# ==============================================================================
@export_group("Modifier Settings")
@export var camera_zoom_increment: Vector2 = Vector2(0.5, 0.5) 
@export var gravity_multiplier: float = 2.5                    
@export var ice_friction: float = 0.05                         
@export var ice_bounce: float = 0.0                            

# Control mappings for mirroring
@export var reverse_controls: Dictionary = {
	"up": "slide",
	"slide": "up",
	"left": "right",
	"right": "left",
	"left_click": "right_click",
	"right_click": "left_click"
}

# State tracking for clearing previous debuffs
var current_active_effect: String = ""
var original_controls: Dictionary = {}
var original_double_press: bool = false
var original_zoom: Vector2 = Vector2.ZERO
var original_gravity_scale: float = 1.0
var original_physics_material: PhysicsMaterial = null

func _ready() -> void:
	randomize()
	# Save initial baseline states if nodes are assigned
	if camera:
		original_zoom = camera.zoom
	if player:
		if "gravity_scale" in player:
			original_gravity_scale = player.gravity_scale
		if "physics_material_override" in player:
			original_physics_material = player.physics_material_override
		if "controls" in player:
			original_controls = player.controls.duplicate()
		if "requires_double_press" in player:
			original_double_press = player.requires_double_press

func _process(delta: float) -> void:
	pass

# Rolls and applies a new debuff, automatically clearing any old one first
func _roll_dice() -> void:
	# 1. Clear the previous debuff before applying a new one
	_clear_current_effect()
	
	# 2. Pick a new effect
	var effects: Array[String] = [
		"_mirror_controls",
		"_jam_controls",
		"_reduce_vision",
		"_add_gravity",
		"_slippery_surface"
	]
	var chosen_effect = effects[randi() % effects.size()]
	
	# 3. Track and apply the new effect
	current_active_effect = chosen_effect
	call(chosen_effect)
	print("New debuff applied: ", chosen_effect)

# Reverts whatever effect was active back to its pre-debuff state
func _clear_current_effect() -> void:
	if current_active_effect == "":
		return
		
	match current_active_effect:
		"_mirror_controls":
			if player and "controls" in player:
				player.controls = original_controls.duplicate()
		"_jam_controls":
			if player and "requires_double_press" in player:
				player.requires_double_press = original_double_press
		"_reduce_vision":
			if camera:
				camera.zoom = original_zoom
		"_add_gravity":
			if player and "gravity_scale" in player:
				player.gravity_scale = original_gravity_scale
		"_slippery_surface":
			if player and "physics_material_override" in player:
				player.physics_material_override = original_physics_material
				
	print("Cleared previous debuff: ", current_active_effect)
	current_active_effect = ""

# --- INDIVIDUAL DEBUFF FUNCTIONS ---

func _mirror_controls() -> void:
	if not player or not "controls" in player: return
	original_controls = player.controls.duplicate()
	
	for key in reverse_controls.keys():
		if player.controls.has(key):
			player.controls[key] = reverse_controls[key]

func _jam_controls() -> void:
	if not player or not "requires_double_press" in player: return
	original_double_press = player.requires_double_press
	player.requires_double_press = true

func _reduce_vision() -> void:
	if not camera: return
	original_zoom = camera.zoom
	camera.zoom += camera_zoom_increment

func _add_gravity() -> void:
	if not player or not "gravity_scale" in player: return
	original_gravity_scale = player.gravity_scale
	player.gravity_scale *= gravity_multiplier

func _slippery_surface() -> void:
	if not player or not "physics_material_override" in player: return
	original_physics_material = player.physics_material_override
	
	var slippery_material := PhysicsMaterial.new()
	slippery_material.friction = ice_friction
	slippery_material.bounce = ice_bounce
	player.physics_material_override = slippery_material
