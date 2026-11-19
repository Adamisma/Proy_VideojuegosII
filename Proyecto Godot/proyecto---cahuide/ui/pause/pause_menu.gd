class_name PauseMenu
extends Control

## ====================================================================
## Proyecto Cahuide - Menú de Pausa Seguro y Táctil
## ====================================================================
## Se muestra sobre la pantalla cuando el juego se pausa (Escape, P o botón táctil).
## Es totalmente independiente de los controles táctiles de la UI.

signal resumed
signal saved

@onready var resume_btn: Button = get_node_or_null("CenterContainer/PanelContainer/VBoxContainer/ResumeButton")
@onready var save_btn: Button = get_node_or_null("CenterContainer/PanelContainer/VBoxContainer/SaveButton")
@onready var restart_cp_btn: Button = get_node_or_null("CenterContainer/PanelContainer/VBoxContainer/RestartCheckpointButton")
@onready var main_menu_btn: Button = get_node_or_null("CenterContainer/PanelContainer/VBoxContainer/MainMenuButton")
@onready var quit_btn: Button = get_node_or_null("CenterContainer/PanelContainer/VBoxContainer/QuitButton")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	if resume_btn:
		resume_btn.pressed.connect(_on_resume_pressed)
	if save_btn:
		save_btn.pressed.connect(_on_save_pressed)
	if restart_cp_btn:
		restart_cp_btn.pressed.connect(_on_restart_checkpoint_pressed)
	if main_menu_btn:
		main_menu_btn.pressed.connect(_on_main_menu_pressed)
	if quit_btn:
		quit_btn.pressed.connect(_on_quit_pressed)

	_make_touch_friendly(resume_btn)
	_make_touch_friendly(save_btn)
	_make_touch_friendly(restart_cp_btn)
	_make_touch_friendly(main_menu_btn)
	_make_touch_friendly(quit_btn)


func open_menu() -> void:
	# En partida LAN no congelamos el árbol para mantener viva la red ENet
	if NetworkManager == null or not NetworkManager.is_multiplayer_active():
		get_tree().paused = true
	visible = true
	if resume_btn:
		resume_btn.grab_focus()
	if EventBus and EventBus.has_signal("game_paused"):
		EventBus.game_paused.emit(true)


func close_menu() -> void:
	visible = false
	get_tree().paused = false
	resumed.emit()
	if EventBus and EventBus.has_signal("game_paused"):
		EventBus.game_paused.emit(false)


func _on_resume_pressed() -> void:
	close_menu()


func _on_save_pressed() -> void:
	if SaveManager:
		SaveManager.save_game()
		saved.emit()
		var ui_ctrl := get_parent() as UIController
		if ui_ctrl:
			ui_ctrl.show_toast("¡Partida Guardada con Éxito!", Color(0.3, 1.0, 0.5))


func _on_restart_checkpoint_pressed() -> void:
	close_menu()
	var current_scene := get_tree().current_scene
	if current_scene and current_scene.has_method("respawn_player_at_checkpoint"):
		current_scene.respawn_player_at_checkpoint()


func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	if NetworkManager and NetworkManager.is_lan_session:
		NetworkManager.disconnect_session(false)
	if EventBus and EventBus.has_signal("game_paused"):
		EventBus.game_paused.emit(false)
	if SceneFlow:
		SceneFlow.change_to("res://scenes/ui/main_menu.tscn", 0.3)


func _on_quit_pressed() -> void:
	get_tree().paused = false
	get_tree().quit()

var _last_press_ticks: Dictionary = {}

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
