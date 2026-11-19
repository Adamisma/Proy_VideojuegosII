class_name UIController
extends CanvasLayer

## ====================================================================
## Laboratorio 13 - Secciones 9, 12, 17, 34 & 46: UIController Maestro
## ====================================================================
## Orquesta y centraliza toda la capa de interfaz de usuario de la escena:
## - HUD (Vida, Score, Checkpoint, Arma, Autosave badge)
## - Hotbar (Acceso rápido con teclas 1 a 5)
## - InventoryPanel (Grid de 20 casilleros con detalles y consumo)
## - PauseMenu (Pausa atómica y reanudación segura)
## - NotificationLayer (Toasts no intrusivos)
## Garantiza que los paneles no se superpongan ni compitan por inputs.

@onready var hud: HUD = $HUD
@onready var hotbar: Hotbar = $Hotbar
@onready var inventory_panel: InventoryPanel = $InventoryPanel
@onready var pause_menu: PauseMenu = $PauseMenu
@onready var notification_layer: NotificationLayer = $NotificationLayer

var current_player: Node = null
var current_inventory: InventoryComponent = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	close_all_panels()

	# Conexión con ciclo de cierre de paneles
	if pause_menu:
		pause_menu.resumed.connect(_on_pause_menu_closed)
	if inventory_panel:
		inventory_panel.closed.connect(_on_inventory_closed)

	# Notificaciones reactivas globales
	if EventBus:
		EventBus.checkpoint_activated.connect(func(id: StringName):
			if notification_layer:
				notification_layer.show_toast("Punto de Control Guardado: %s" % String(id), Color(0.3, 1.0, 0.45))
		)

func _unhandled_input(event: InputEvent) -> void:
	# Atajo de Pausa [Escape]
	if event.is_action_pressed("pause") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE):
		_handle_pause_input()
		get_viewport().set_input_as_handled()

	# Atajo de Inventario [I]
	elif event.is_action_pressed("inventory") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_I):
		_handle_inventory_input()
		get_viewport().set_input_as_handled()

func _handle_pause_input() -> void:
	if inventory_panel and inventory_panel.visible:
		inventory_panel.close_inventory()
		return

	if pause_menu:
		if pause_menu.visible:
			pause_menu.close_menu()
		else:
			close_all_panels()
			pause_menu.open_menu()

func _handle_inventory_input() -> void:
	if pause_menu and pause_menu.visible:
		return

	if inventory_panel:
		if inventory_panel.visible:
			inventory_panel.close_inventory()
		else:
			close_all_panels()
			inventory_panel.open_inventory()

## Inyección de dependencias desde LevelController hacia todos los subsistemas de UI
func bind_player(player: Node) -> void:
	current_player = player
	if hud and player:
		hud.bind_player(player)

	# Buscar componente de inventario en el jugador
	var inv := player.get_node_or_null("InventoryComponent") as InventoryComponent
	if inv == null:
		# Instanciar dinámicamente si el actor aún no lo tiene
		inv = InventoryComponent.new()
		inv.name = "InventoryComponent"
		player.add_child(inv)

	current_inventory = inv

	if inventory_panel:
		inventory_panel.bind_inventory(inv, player)
	if hotbar:
		hotbar.bind_inventory(inv, player)

	# Escuchar eventos de recogida para mostrar toasts
	if not inv.item_added.is_connected(_on_item_added):
		inv.item_added.connect(_on_item_added)

func _on_item_added(item_id: StringName, quantity: int) -> void:
	if notification_layer:
		var item_db: ItemDatabase = inventory_panel.item_database if inventory_panel else null
		var item: ItemData = item_db.get_item(item_id) if item_db else null
		var name_str: String = item.display_name if item != null else String(item_id)
		notification_layer.show_toast("+%d %s" % [quantity, name_str], Color(0.4, 0.9, 1.0))

func close_all_panels() -> void:
	if pause_menu:
		pause_menu.visible = false
	if inventory_panel:
		inventory_panel.visible = false

func _on_pause_menu_closed() -> void:
	pass

func _on_inventory_closed() -> void:
	pass
