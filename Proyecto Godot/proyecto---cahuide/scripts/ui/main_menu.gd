class_name MainMenu
extends Control

## Menú de inicio básico para el proyecto Cahuide

@export var level_01_scene: PackedScene = preload("res://scenes/levels/level_01.tscn")

@onready var btn_play: Button = $MarginContainer/VBoxContainer/ButtonsContainer/BtnPlay
@onready var btn_controls: Button = $MarginContainer/VBoxContainer/ButtonsContainer/BtnControls
@onready var btn_quit: Button = $MarginContainer/VBoxContainer/ButtonsContainer/BtnQuit
@onready var controls_dialog: PanelContainer = $ControlsDialog

func _ready() -> void:
	controls_dialog.visible = false
	btn_play.pressed.connect(_on_btn_play_pressed)
	btn_controls.pressed.connect(_on_btn_controls_pressed)
	btn_quit.pressed.connect(_on_btn_quit_pressed)
	$ControlsDialog/VBoxContainer/BtnCloseControls.pressed.connect(_on_close_controls_pressed)

func _on_btn_play_pressed() -> void:
	if level_01_scene:
		get_tree().change_scene_to_packed(level_01_scene)
	else:
		get_tree().change_scene_to_file("res://scenes/levels/level_01.tscn")

func _on_btn_controls_pressed() -> void:
	controls_dialog.visible = true

func _on_close_controls_pressed() -> void:
	controls_dialog.visible = false

func _on_btn_quit_pressed() -> void:
	get_tree().quit()
