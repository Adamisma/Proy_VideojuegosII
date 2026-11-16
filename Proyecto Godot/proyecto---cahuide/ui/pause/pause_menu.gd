class_name PauseMenu
extends Control

## ====================================================================
## Proyecto Cahuide - Menú de Pausa Seguro
## ====================================================================

signal resumed

@onready var resume_btn: Button = $CenterContainer/PanelContainer/VBoxContainer/ResumeButton
@onready var restart_cp_btn: Button = $CenterContainer/PanelContainer/VBoxContainer/RestartCheckpointButton
@onready var main_menu_btn: Button = $CenterContainer/PanelContainer/VBoxContainer/MainMenuButton
@onready var quit_btn: Button = $CenterContainer/PanelContainer/VBoxContainer/QuitButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false

	resume_btn.pressed.connect(_on_resume_pressed)
	restart_cp_btn.pressed.connect(_on_restart_checkpoint_pressed)
	main_menu_btn.pressed.connect(_on_main_menu_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)

func open_menu() -> void:
	get_tree().paused = true
	visible = true
	resume_btn.grab_focus()

func close_menu() -> void:
	visible = false
	get_tree().paused = false
	resumed.emit()

func _on_resume_pressed() -> void:
	close_menu()

func _on_restart_checkpoint_pressed() -> void:
	close_menu()
	var current_scene := get_tree().current_scene
	if current_scene and current_scene.has_method("respawn_player_at_checkpoint"):
		current_scene.respawn_player_at_checkpoint()

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	if SceneFlow:
		SceneFlow.change_to("res://scenes/ui/main_menu.tscn", 0.3)

func _on_quit_pressed() -> void:
	get_tree().quit()
