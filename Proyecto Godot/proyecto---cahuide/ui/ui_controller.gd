class_name UIController
extends CanvasLayer

## ====================================================================
## Proyecto Cahuide - UIController Orquestador Maestro
## ====================================================================
## Centraliza HUD, Menú de Pausa y Notificaciones no invasivas sin colisión de inputs.

@onready var pause_menu: PauseMenu = get_node_or_null("PauseMenu")
@onready var notification_layer: NotificationLayer = get_node_or_null("NotificationLayer")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	if pause_menu:
		pause_menu.visible = false

	# Suscripción a eventos para toasts discretos
	if EventBus:
		EventBus.relic_collected.connect(func(_rem: int, _tot: int):
			show_toast("+50 Puntos (Reliquia)", Color(1.0, 0.85, 0.3))
		)
		EventBus.checkpoint_activated.connect(func(_id: StringName):
			show_toast("Punto de Control Guardado", Color(0.3, 1.0, 0.45))
		)
		EventBus.player_powerup_activated.connect(func(_dur: float):
			show_toast("¡Poder del Sol Activado!", Color(1.0, 0.9, 0.2))
		)
		EventBus.ranged_weapon_swapped.connect(func(w_name: String):
			show_toast("Arma: %s" % w_name, Color(0.4, 0.85, 1.0))
		)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE):
		_toggle_pause()
		get_viewport().set_input_as_handled()

func _toggle_pause() -> void:
	if pause_menu:
		if pause_menu.visible:
			pause_menu.close_menu()
		else:
			pause_menu.open_menu()

func show_toast(msg: String, color: Color = Color(1.0, 0.85, 0.2)) -> void:
	if notification_layer:
		notification_layer.show_toast(msg, color)
