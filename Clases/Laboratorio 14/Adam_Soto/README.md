# Laboratorio 14: Introducción a Redes y Multijugador LAN

**Curso:** Desarrollo de Videojuegos 2D con Godot  
**Estudiante:** Adam Soto  
**Proyecto:** `Lab14_LAN_Multiplayer`  

---

## 🎯 Objetivo de la Sesión
Comprender los fundamentos de la arquitectura de redes multijugador cliente-servidor en **Godot 4 High-Level Multiplayer API**, configurando conexiones locales sobre UDP con `ENetMultiplayerPeer`, instanciando jugadores de forma autoritativa con `MultiplayerSpawner` y sincronizando posiciones y animaciones continuas con `MultiplayerSynchronizer`.

---

## 🛠️ Implementaciones Realizadas

1. **Gestor de Red (`network_manager.gd`):**
   - Autoload que encapsula la API `multiplayer`.
   - Modos: **Host** (Crea servidor UDP en el puerto 7000 para hasta 8 clientes) y **Join** (Conexión a localhost `127.0.0.1` o IP privada LAN).
   - Manejo de señales de alto nivel: `peer_connected`, `peer_disconnected`, `connected_to_server`, `connection_failed`, `server_disconnected`.
   - Limpieza y desconexión segura con `OfflineMultiplayerPeer`.

2. **Menú de Conexión LAN (`network/network_menu.tscn`):**
   - Interfaz con campos para apodo de jugador, dirección IP del servidor, botones **Crear Partida**, **Unirse a Partida**, **Desconectar** e indicadores de estado de red y Peer ID asignado.

3. **Arena Multijugador (`multiplayer/game_lan.tscn`):**
   - **MultiplayerSpawner**: Ubicado sobre el contenedor `Players`. El servidor es la única autoridad autorizada para instanciar (`_spawn_player`) o destruir (`_despawn_player`) nodos replicados.
   - **4 Puntos de Spawn no Superpuestos**: Marcadores distribuidos en los cuatro cuadrantes de la arena calculados por el índice del Peer ID para evitar colisiones físicas iniciales.
   - **HUD de Red en Vivo**: Muestra rol actual (`[HOST]` / `[CLIENT]`), Peer ID local, número de jugadores conectados, lista de IDs en sala y botón para desconectarse y volver al menú principal.

4. **Actor de Red Sincronizado (`multiplayer/player_net.tscn`):**
   - **Autoridad Determinista**: `set_multiplayer_authority(name.to_int())` asignada según el nombre del nodo (`str(peer_id)`).
   - **Control de Input Local Estricto**: `if not is_multiplayer_authority(): return` para garantizar que cada cliente mueva únicamente a su personaje.
   - **Cámara Local Exclusiva**: `camera.enabled = is_multiplayer_authority()`.
   - **MultiplayerSynchronizer**: Replica de forma continua posición (`.:position`), animación (`.:current_anim`), orientación horizontal (`Visuals:scale`) y apodo.
   - **Tonalidad Distintiva por Peer**: Asignación automática de un color HSV único a cada jugador derivado matemáticamente de su Peer ID.

5. **Suite de Pruebas Automatizada (`tests/test_runner.tscn`):**
   - Validación completa de las matrices de prueba N01-N08 con resultado **100% PASS**.

---

## 💡 Conceptos Clave Aprendidos
- **Servidor Autoritativo vs Autoridad de Nodo:** El servidor controla la creación/destrucción de nodos en el SceneTree; la autoridad local del nodo procesa el input del teclado físico de esa máquina.
- **Diferencia entre Memoria Compartida y Sincronización:** Cada computadora tiene su propio proceso y SceneTree independiente; la red transmite paquetes mínimos de datos para actualizar nodos equivalentes.
