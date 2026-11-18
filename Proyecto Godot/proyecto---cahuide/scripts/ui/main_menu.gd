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
@onready var btn_controls: Button = $MarginContainer/VBoxContainer/ButtonsContainer/BtnControls
@onready var btn_quit: Button = $MarginContainer/VBoxContainer/ButtonsContainer/BtnQuit
@onready var controls_dialog: PanelContainer = $ControlsDialog
@onready var save_info_label: Label = get_node_or_null("MarginContainer/VBoxContainer/SaveInfoLabel")
@onready var ambient_music_player: AudioStreamPlayer = get_node_or_null("AmbientMusic")

func _ready() -> void:
	_setup_menu_music()
	controls_dialog.visible = false
	btn_play.pressed.connect(_on_btn_play_pressed)
	btn_controls.pressed.connect(_on_btn_controls_pressed)
	btn_quit.pressed.connect(_on_btn_quit_pressed)

	var close_btn := get_node_or_null("ControlsDialog/VBoxContainer/BtnCloseControls") as Button
	if close_btn:
		close_btn.pressed.connect(_on_close_controls_pressed)

	if btn_continue:
		btn_continue.pressed.connect(_on_btn_continue_pressed)

	_update_save_state()

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
			if btn_continue:
				btn_continue.grab_focus()
		else:
			save_info_label.text = "Comienza una nueva aventura."
			save_info_label.modulate = Color(0.7, 0.7, 0.7)
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
