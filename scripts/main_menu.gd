extends Control

signal new_game_requested
signal continue_requested
signal load_game_requested(slot: int)

@export var ui: Control
@export var main_group: Control
@export var settings_group: Control
@export var load_group: Control
@export var confirm_group: Control

@export var title: Label
@export var subtitle: Label
@export var menu_buttons: VBoxContainer
@export var continue_button: Button
@export var new_game_button: Button
@export var load_game_button: Button
@export var settings_button: Button
@export var quit_button: Button
@export var master_volume: HSlider
@export var music_volume: HSlider
@export var sfx_volume: HSlider
@export var fullscreen_check: CheckButton
@export var save_list: VBoxContainer
@export var confirm_text: Label
@export var confirm_yes: Button
@export var confirm_no: Button
@export var settings_back: Button
@export var load_back: Button
@export var music_player: AudioStreamPlayer
@export var ambient_player: AudioStreamPlayer
@export var sfx_player: AudioStreamPlayer
@export var fade: ColorRect
@export var hover_sound : AudioStream
@export var select_sound : AudioStream
@export var back_sound : AudioStream

@export_group("Hover Arrows")
@export var arrow_texture: Texture2D
@export var arrow_size := Vector2(14, 14)
@export var arrow_gap := 4.0
@export var arrow_fade_time := 0.15

const SAVE_PATH := "user://settings.cfg"

const FADE_TIME := 0.45

enum MenuPage {
	MAIN,
	SETTINGS,
	LOAD,
	CONFIRM
}

var current_page: MenuPage = MenuPage.MAIN
var transition_locked := false
var confirmation_action: String = ""

var settings_data := {
	"master": 1.0,
	"music": 0.8,
	"sfx": 1.0,
	"fullscreen": true,
}

func _ready() -> void:
	randomize()

	_setup_buttons()
	_setup_groups()
	_setup_settings()
	_load_settings()
	_apply_settings()

	fade.color = Color.BLACK
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.show()
	var intro := create_tween()
	intro.tween_property(fade, "color:a", 0.0, 0.75
	).set_trans(Tween.TRANS_SINE)

	intro.tween_callback(func():
		fade.hide()
	)

	_play_music()
	_play_ambient()
	_start_title_animation()
	_show_group(main_group)
	current_page = MenuPage.MAIN
	continue_button.grab_focus()

func _play_sfx(sound_name: String) -> void:
	var stream: AudioStream

	match sound_name:
		"hover":
			stream = hover_sound

		"select":
			stream = select_sound

		"back":
			stream = back_sound

	if stream == null:
		return

	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = sfx_player.bus
	player.volume_db = sfx_player.volume_db
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

func _play_music() -> void:
	if music_player.stream:
		music_player.play()

func _play_ambient() -> void:
	if ambient_player.stream:
		ambient_player.play()

func _set_bus_volume(bus_name: String,value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)

	if bus_index < 0:
		return

	if value <= 0.001:
		AudioServer.set_bus_mute(bus_index, true)
	else:
		AudioServer.set_bus_mute(bus_index, false)

		AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))

func _save_settings() -> void:
	var config := ConfigFile.new()

	for key in settings_data:
		config.set_value(
			"settings",
			key,
			settings_data[key]
		)

	config.save(SAVE_PATH)

func _load_settings() -> void:
	var config := ConfigFile.new()

	if config.load(SAVE_PATH) != OK:
		return

	for key in settings_data:
		settings_data[key] = config.get_value(
			"settings",
			key,
			settings_data[key]
		)

func _apply_settings() -> void:
	master_volume.value = settings_data["master"]
	music_volume.value = settings_data["music"]
	sfx_volume.value = settings_data["sfx"]

	fullscreen_check.button_pressed = settings_data["fullscreen"]

	_set_bus_volume("Master", settings_data["master"])
	_set_bus_volume("Music", settings_data["music"])
	_set_bus_volume("SFX", settings_data["sfx"])

func _on_fullscreen_toggled(enabled: bool) -> void:
	settings_data["fullscreen"] = enabled

	if enabled:
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_FULLSCREEN
		)
	else:
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_WINDOWED
		)

	_save_settings()

func _on_master_volume_changed(value: float) -> void:
	settings_data["master"] = value
	_set_bus_volume("Master", value)
	_save_settings()


func _on_music_volume_changed(value: float) -> void:
	settings_data["music"] = value
	_set_bus_volume("Music", value)
	_save_settings()


func _on_sfx_volume_changed(value: float) -> void:
	settings_data["sfx"] = value
	_set_bus_volume("SFX", value)
	_save_settings()

func _setup_settings() -> void:
	master_volume.min_value = 0
	master_volume.max_value = 1
	master_volume.step = 0.05

	music_volume.min_value = 0
	music_volume.max_value = 1
	music_volume.step = 0.05

	sfx_volume.min_value = 0
	sfx_volume.max_value = 1
	sfx_volume.step = 0.05

	master_volume.value_changed.connect(_on_master_volume_changed)
	music_volume.value_changed.connect(_on_music_volume_changed)
	sfx_volume.value_changed.connect(_on_sfx_volume_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)

func _setup_groups() -> void:
	var groups: Array[Control] = [
		main_group,
		settings_group,
		load_group,
		confirm_group
	]

	for group in groups:
		if group == null:
			continue

		group.hide()
		group.modulate.a = 0.0
		group.mouse_filter = Control.MOUSE_FILTER_PASS

func _show_group(group: Control) -> void:
	if transition_locked:
		return

	transition_locked = true
	var groups: Array[Control] = [
		main_group,
		settings_group,
		load_group,
		confirm_group
	]

	for item in groups:
		if item == group or item == null:
			continue
		if item.visible:
			var old_tween := create_tween()
			old_tween.tween_property(item, "modulate:a", 0.0, 0.15)
			old_tween.tween_callback(func():
				item.hide()
			)

	group.show()
	group.modulate.a = 0.0
	group.position.y += 12

	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(group, "modulate:a", 1.0, FADE_TIME
	).set_trans(Tween.TRANS_SINE)

	tween.tween_property(group, "position:y", group.position.y - 12, FADE_TIME
	).set_trans(Tween.TRANS_CUBIC)

	tween.chain().tween_callback(func():
		transition_locked = false
	)

func _switch_page(group: Control, page: MenuPage) -> void:
	current_page = page
	_show_group(group)

func _return_to_main() -> void:
	_switch_page(main_group, MenuPage.MAIN)
	continue_button.grab_focus()
	_play_sfx("back")

func _on_continue() -> void:
	continue_requested.emit()

func _on_new_game() -> void:
	confirmation_action = "new_game"

	confirm_text.text = \
		"Begin a new journey?\nExisting progress may be overwritten."

	_switch_page(confirm_group, MenuPage.CONFIRM)
	confirm_no.grab_focus()

func _on_settings() -> void:
	_switch_page(settings_group, MenuPage.SETTINGS)
	settings_back.grab_focus()

func _on_quit() -> void:
	confirmation_action = "quit"

	confirm_text.text = \
		"Abandon this realm?\nAre you certain you wish to leave?"

	_switch_page(confirm_group, MenuPage.CONFIRM)
	confirm_no.grab_focus()

func _fade_and_emit_new_game() -> void:
	transition_locked = true
	fade.show()

	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, 0.8)
	tween.tween_callback(func():
		new_game_requested.emit()
	)

func _fade_and_quit() -> void:
	fade.show()

	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, 0.8)
	tween.tween_callback(func():
		get_tree().quit()
	)

func _confirm_yes() -> void:
	match confirmation_action:
		"new_game":
			_fade_and_emit_new_game()

		"quit":
			_fade_and_quit()

func _confirm_no() -> void:
	confirmation_action = ""
	_return_to_main()

# ---------------------------------------------------------------------------
# Button feedback (sound + hover arrows)
# Hover = focus: the mouse entering a button grabs focus, so mouse, keyboard
# and controller all drive the same single "active" button.
# ---------------------------------------------------------------------------

func _on_button_focus() -> void:
	_play_sfx("hover")

func _on_button_pressed(button: Button) -> void:
	if button not in [settings_back, load_back, confirm_no]:
		_play_sfx("select")

	var tween := create_tween()
	tween.tween_property(button, "scale", Vector2(0.97, 0.97), 0.05)
	tween.tween_property(button, "scale", Vector2.ONE, 0.12)

# Wires up sounds and arrows for one button.
# Used for the fixed menu buttons and for save slots created at runtime.
func _setup_button(button: Button) -> void:
	if button == null:
		return

	button.focus_entered.connect(_on_button_focus)
	button.pressed.connect(_on_button_pressed.bind(button))
	_add_arrows(button)

func _add_arrows(btn: Button) -> void:
	var left := _make_arrow(false)
	var right := _make_arrow(true)
	btn.add_child(left)
	btn.add_child(right)
	left.modulate.a = 0.0
	right.modulate.a = 0.0

	btn.mouse_entered.connect(btn.grab_focus)
	btn.focus_entered.connect(_fade_arrows.bind(btn, left, right, 1.0))
	btn.focus_exited.connect(_fade_arrows.bind(btn, left, right, 0.0))
	btn.resized.connect(_layout_arrows.bind(btn, left, right))
	_layout_arrows(btn, left, right)

func _make_arrow(flip: bool) -> TextureRect:
	var t := TextureRect.new()
	t.texture = arrow_texture
	t.flip_h = flip
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = arrow_size
	t.size = arrow_size
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t

func _layout_arrows(btn: Button, left: TextureRect, right: TextureRect) -> void:
	var font := btn.get_theme_font("font")
	var font_size := btn.get_theme_font_size("font_size")
	var text_w := font.get_string_size(btn.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var cx := btn.size.x / 2.0
	var cy := btn.size.y / 2.0
	left.position = Vector2(cx - text_w / 2.0 - arrow_gap - arrow_size.x, cy - arrow_size.y / 2.0)
	right.position = Vector2(cx + text_w / 2.0 + arrow_gap, cy - arrow_size.y / 2.0)

func _fade_arrows(btn: Button, left: TextureRect, right: TextureRect, to: float) -> void:
	if btn.has_meta("arrow_tween"):
		var old: Tween = btn.get_meta("arrow_tween")
		if old and old.is_valid():
			old.kill()
	var tw := btn.create_tween().set_parallel(true)
	tw.tween_property(left, "modulate:a", to, arrow_fade_time)
	tw.tween_property(right, "modulate:a", to, arrow_fade_time)
	btn.set_meta("arrow_tween", tw)

func _populate_save_list() -> void:
	if save_list == null:
		return

	for child in save_list.get_children():
		child.queue_free()

	for i in range(3):
		var button := Button.new()
		button.text = "Save Slot %d" % (i + 1)

		button.pressed.connect(func():
			load_game_requested.emit(i + 1)
		)

		save_list.add_child(button)
		_setup_button(button)

func _on_load_game() -> void:
	_populate_save_list()
	_switch_page(load_group, MenuPage.LOAD)
	load_back.grab_focus()

func _setup_buttons() -> void:
	var buttons: Array[Button] = [
		continue_button,
		new_game_button,
		load_game_button,
		settings_button,
		quit_button,
		settings_back,
		load_back,
		confirm_yes,
		confirm_no
	]

	for button in buttons:
		_setup_button(button)

	continue_button.pressed.connect(_on_continue)
	new_game_button.pressed.connect(_on_new_game)
	load_game_button.pressed.connect(_on_load_game)
	settings_button.pressed.connect(_on_settings)
	quit_button.pressed.connect(_on_quit)
	settings_back.pressed.connect(_return_to_main)
	load_back.pressed.connect(_return_to_main)
	confirm_yes.pressed.connect(_confirm_yes)
	confirm_no.pressed.connect(_confirm_no)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if current_page == MenuPage.MAIN:
			_on_quit()
		else:
			_return_to_main()

		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		get_tree().quit()

func _start_title_animation() -> void:
	title.pivot_offset = title.size / 2.0
	title.modulate.a = 0.0

	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(title, "modulate:a", 1.0, 1.5)
	tween.tween_property(title, "position:y", title.position.y, 0.75
	).from(title.position.y + 10)

	var breathe := create_tween()
	breathe.set_loops()

	breathe.tween_property(
		title,
		"modulate",
		Color(0.993, 0.418, 0.418, 1.0),
		1
	)

	breathe.tween_property(
		title,
		"modulate",
		Color.WHITE,
		1
	)
