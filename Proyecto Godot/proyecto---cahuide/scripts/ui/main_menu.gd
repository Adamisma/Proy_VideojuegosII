class_name MainMenu
extends Control

## ====================================================================
## Proyecto Cahuide - Menú Principal con Persistencia y SceneFlow
## ====================================================================

@export var level_01_scene: PackedScene = preload("res://scenes/levels/level_01.tscn")

@export_group("Audio")
@export var menu_music: AudioStream = preload("res://assets/sounds/ambiental/Menu.mp3")
@export var music_volume_db: float = -6.0

@onready var btn_play: Button = $MarginContainer/VBoxContainer/ButtonsContainer/BtnPlay
@onready var btn_continue: Button = get_node_or_null("MarginContainer/VBoxContainer/ButtonsContainer/BtnContinue")
@onready var btn_multiplayer: Button = get_node_or_null("MarginContainer/VBoxContainer/ButtonsContainer/BtnMultiplayer")
@onready var btn_controls: Button = $MarginContainer/VBoxContainer/ButtonsContainer/BtnControls
@onready var btn_quit: Button = $MarginContainer/VBoxContainer/ButtonsContainer/BtnQuit
@onready var controls_dialog: PanelContainer = $ControlsDialog
@onready var save_info_label: Label = get_node_or_null("MarginContainer/VBoxContainer/SaveInfoLabel")
@onready var ambient_music_player: AudioStreamPlayer = get_node_or_null("AmbientMusic")

var _last_press_ticks: Dictionary = {}

func _ready() -> void:
	if NetworkManager and NetworkManager.is_lan_session:
		NetworkManager.disconnect_session(false)
	_setup_menu_music()
	controls_dialog.visible = false
	btn_play.pressed.connect(_on_btn_play_pressed)
	btn_controls.pressed.connect(_on_btn_controls_pressed)
	btn_quit.pressed.connect(_on_btn_quit_pressed)
	if btn_multiplayer:
		btn_multiplayer.pressed.connect(_on_btn_multiplayer_pressed)

	var close_btn := get_node_or_null("ControlsDialog/VBoxContainer/BtnCloseControls") as Button
	if close_btn:
		close_btn.pressed.connect(_on_close_controls_pressed)

	if btn_continue:
		btn_continue.pressed.connect(_on_btn_continue_pressed)

	# Soporte táctil directo para móviles (garantiza respuesta incluso si la emulación de mouse falla en Android)
	_make_touch_friendly(btn_play)
	_make_touch_friendly(btn_continue)
	_make_touch_friendly(btn_multiplayer)
	_make_touch_friendly(btn_controls)
	_make_touch_friendly(btn_quit)
	_make_touch_friendly(close_btn)

	_update_save_state()

## Permite que cualquier botón responda directamente a toques de pantalla en dispositivos móviles
func _make_touch_friendly(btn: Button) -> void:
	if btn == null:
		return
	if not (OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios")):
		return
	btn.pressed.connect(func() -> void:
		_last_press_ticks[btn] = Time.get_ticks_msec()
	)
	btn.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventScreenTouch and not event.pressed:
			var now := Time.get_ticks_msec()
			var last: int = _last_press_ticks.get(btn, -99999)
			if now - last > 300:
				_last_press_ticks[btn] = now
				if not btn.disabled and Rect2(Vector2.ZERO, btn.size).has_point(event.position):
					btn.accept_event()
					btn.pressed.emit()
	)

func _update_save_state() -> void:
	var has_save: bool = SaveManager.has_save() if SaveManager else false

	if btn_continue:
		btn_continue.disabled = not has_save

	if save_info_label and SaveManager:
		if has_save:
			var info: Dictionary = SaveManager.get_save_info()
			var cp_str: String = (" (Checkpoint Activo)") if info.get("checkpoint_id", "") != "" else ""
			save_info_label.text = "Progreso Guardado: Puntos %d%s" % [info.get("score", 0), cp_str]
			save_info_label.modulate = Color(1.0, 0.88, 0.3)
			if btn_continue and not (OS.has_feature("mobile") or OS.has_feature("android")):
				btn_continue.grab_focus()
		else:
			save_info_label.text = "Comienza una nueva aventura."
			save_info_label.modulate = Color(0.7, 0.7, 0.7)
			if btn_play and not (OS.has_feature("mobile") or OS.has_feature("android")):
				btn_play.grab_focus()

func _on_btn_play_pressed() -> void:
	if GameState:
		GameState.start_new_game()
	if SaveManager:
		SaveManager.save_game()

	if SceneFlow:
		SceneFlow.go_to_level(&"level_01", 0.35)
	elif level_01_scene:
		get_tree().change_scene_to_packed(level_01_scene)
	else:
		get_tree().change_scene_to_file("res://scenes/levels/level_01.tscn")

func _on_btn_continue_pressed() -> void:
	if SaveManager and SaveManager.load_game():
		var target: StringName = GameState.current_level_id if GameState else &"level_01"
		if SceneFlow:
			SceneFlow.go_to_level(target, 0.35)
		else:
			get_tree().change_scene_to_file("res://scenes/levels/level_01.tscn")
	else:
		_on_btn_play_pressed()

func _on_btn_multiplayer_pressed() -> void:
	if SceneFlow:
		SceneFlow.change_to("res://scenes/ui/lan_lobby.tscn", 0.3)
	else:
		get_tree().change_scene_to_file("res://scenes/ui/lan_lobby.tscn")

func _on_btn_controls_pressed() -> void:
	controls_dialog.visible = true

func _on_close_controls_pressed() -> void:
	controls_dialog.visible = false

func _on_btn_quit_pressed() -> void:
	get_tree().quit()

func _setup_menu_music() -> void:
	if menu_music == null:
		return

	if menu_music is AudioStreamMP3:
		(menu_music as AudioStreamMP3).loop = true

	if ambient_music_player == null:
		ambient_music_player = AudioStreamPlayer.new()
		ambient_music_player.name = "AmbientMusic"
		ambient_music_player.bus = &"Master"
		ambient_music_player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(ambient_music_player)

	ambient_music_player.stream = menu_music
	ambient_music_player.volume_db = music_volume_db
	if not ambient_music_player.playing:
		ambient_music_player.play()
