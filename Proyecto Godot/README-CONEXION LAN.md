-------------------------------------------
Opción A — Directo desde el Editor de Godot (la más rápida)
Abre el proyecto en Godot 4.7.2.
En el menú superior ve a Debug → Customize Run Instances... (o Depurar → Personalizar instancias de ejecución...).
Activa Enable Multiple Instances y pon 2 instancias.
Pulsa F5 (Ejecutar proyecto): se abrirán dos ventanas del juego al mismo tiempo.
Ventana 1 (Host): entra a 🌐 Multijugador LAN → escribe un nombre → pulsa 👑 Crear Partida.
Ventana 2 (Cliente): entra a 🌐 Multijugador LAN → deja la IP en 127.0.0.1 y puerto 7777 → pulsa 🔗 Unirse a Partida.
En ambas ventanas elijan personaje, el Host selecciona Mapa y Dificultad, ambos pulsan ✔ ¡Estoy Listo!, y el Host pulsa ⚔️ Iniciar Partida LAN.


---------------------------------------------------
Opción B — En Dos PCs de la Misma Red Local (Wi-Fi / Ethernet)
En la PC 1 (Host) entra a Multijugador LAN → Crear Partida y anota la IP LAN mostrada en pantalla (ej. 192.168.1.15).
Si Windows Firewall solicita permiso al abrir el puerto UDP 7777, permite acceso en Redes privadas.
En la PC 2 (Cliente) entra a Multijugador LAN, escribe esa IP en IP Host con el mismo puerto (7777) y pulsa Unirse a Partida.