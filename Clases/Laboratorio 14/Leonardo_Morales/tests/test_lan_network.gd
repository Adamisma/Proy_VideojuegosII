extends Node

## TestRunner para Laboratorio 14 (Matriz de pruebas N01 - N08)
## Ejecutable cargando res://tests/test_runner.tscn

func _ready() -> void:
	# Esperar un frame para que el SceneTree esté completamente listo
	await get_tree().process_frame

	print("==================================================")
	print(" INICIANDO TEST SUITE: LABORATORIO 14 (RED LAN)   ")
	print("==================================================")

	var all_passed := true

	# Test 1: Instancia y configuración de NetworkManager
	print("\n[TEST 1] Verificando NetworkManager Autoload...")
	if network_manager == null:
		push_error("FAIL: network_manager autoload no encontrado")
		all_passed = false
	else:
		print("PASS: network_manager autoload activo y accesible.")

	# Test 2: Iniciar Servidor (Host)
	print("\n[TEST 2] Creación de servidor LAN (Host)...")
	var host_err: Error = network_manager.host_game()
	if host_err != OK:
		push_error("FAIL: Error al crear servidor: %s" % str(host_err))
		all_passed = false
	else:
		var is_srv: bool = network_manager.is_host()
		var my_id: int = network_manager.get_local_peer_id()
		print("PASS: Servidor creado correctamente.")
		print("       - Es servidor: %s (esperado: true)" % str(is_srv))
		print("       - Peer ID local: %d (esperado: 1)" % my_id)
		if not is_srv or my_id != 1:
			push_error("FAIL: El Host debe ser servidor y tener Peer ID = 1")
			all_passed = false

	# Test 3: Carga de GameLAN y validación de Spawner/Synchronizer
	print("\n[TEST 3] Carga de GameLAN y validación de Spawner/Synchronizer...")
	var game_scene: PackedScene = load("res://multiplayer/game_lan.tscn")
	if game_scene == null:
		push_error("FAIL: No se pudo cargar res://multiplayer/game_lan.tscn")
		all_passed = false
	else:
		var game_instance = game_scene.instantiate()
		add_child(game_instance)
		await get_tree().process_frame

		# Comprobar que el Host spawneó su actor
		var players_node: Node2D = game_instance.get_node_or_null("Players")
		if players_node == null:
			push_error("FAIL: Nodo 'Players' no encontrado en GameLAN")
			all_passed = false
		else:
			var host_player = players_node.get_node_or_null("1")
			if host_player == null:
				push_error("FAIL: El jugador host (1) no se spawneó automáticamente")
				all_passed = false
			else:
				var auth: int = host_player.get_multiplayer_authority()
				var cam_enabled: bool = host_player.get_node("Camera2D").enabled
				print("PASS: Jugador Host (1) spawneado.")
				print("       - Multiplayer Authority: %d (esperado: 1)" % auth)
				print("       - Cámara habilitada: %s (esperado: true)" % str(cam_enabled))
				if auth != 1 or not cam_enabled:
					push_error("FAIL: La autoridad o cámara del Host no corresponden")
					all_passed = false

		# Test 4: Simulación de conexión y spawning de Peer Remoto (ID: 2)
		print("\n[TEST 4] Simulación de aparición de peer remoto (ID: 2)...")
		game_instance._spawn_player(2)
		var remote_player = players_node.get_node_or_null("2")
		if remote_player == null:
			push_error("FAIL: No se pudo instanciar jugador para peer remoto 2")
			all_passed = false
		else:
			var remote_auth: int = remote_player.get_multiplayer_authority()
			var remote_cam: bool = remote_player.get_node("Camera2D").enabled
			print("PASS: Jugador remoto (2) spawneado.")
			print("       - Multiplayer Authority: %d (esperado: 2)" % remote_auth)
			print("       - Cámara habilitada en host: %s (esperado: false)" % str(remote_cam))
			if remote_auth != 2 or remote_cam:
				push_error("FAIL: El peer remoto debe tener autoridad 2 y su cámara desactivada en esta máquina")
				all_passed = false

		# Test 5: Despawn de peer remoto al desconectarse
		print("\n[TEST 5] Simulación de desconexión y despawn de peer remoto (ID: 2)...")
		game_instance._despawn_player(2)
		var rem_after = players_node.get_node_or_null("2")
		if rem_after != null and not rem_after.is_queued_for_deletion():
			push_error("FAIL: Jugador remoto 2 no fue marcado para queue_free")
			all_passed = false
		else:
			print("PASS: Jugador remoto 2 despawneado correctamente.")

		game_instance.queue_free()

	# Test 6: Desconexión de red limpia
	print("\n[TEST 6] Desconexión de red y reset de MultiplayerPeer...")
	network_manager.disconnect_game()
	var srv_after: bool = network_manager.is_host()
	print("PASS: Desconexión ejecutada. is_host() = %s (esperado: false)" % str(srv_after))
	if srv_after:
		push_error("FAIL: Tras desconexión is_host() debe ser false")
		all_passed = false

	print("\n==================================================")
	if all_passed:
		print(" RESULTADO FINAL: TODOS LOS TESTS PASARON EXITOSAMENTE (100%) ")
	else:
		print(" RESULTADO FINAL: HUBO ERRORES EN LAS PRUEBAS ")
	print("==================================================")

	get_tree().quit(0 if all_passed else 1)
