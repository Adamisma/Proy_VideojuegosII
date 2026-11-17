# 🏛️ Cahuide: Leyenda de la Fortaleza

**Proyecto Principal de Curso:** Desarrollo de Videojuegos 2D con Godot  
**Motor:** Godot Engine 4 (v4.4+ / v4.6+ con renderizador GL Compatibility)  
**Estudiante / Desarrollador:** Adam Soto, Leonardo Morales y Johann Napa
**Género:** Plataformas de Acción 2D / Aventura Histórica (*Action Platformer*)  

---

## 📜 1. Sinopsis y Contexto Histórico

**Cahuide: Leyenda de la Fortaleza** es un videojuego de plataformas y acción en dos dimensiones inspirado en la figura heroica del general inca **Cahuide** (*Titu Cusi Huallpa*), quien luchó con inquebrantable valor en la cima de la fortaleza de Sacsayhuamán durante el cerco del Cusco en 1536.

En el juego, el jugador toma el control de Cahuide para defender las terrazas sagradas, sortear trampas ancestrales, combatir tropas enemigas invasoras, invocar el **Poder del Sol (Inti)** y recuperar las reliquias sagradas para completar cada nivel y salvar su imperio.

---

## 🏗️ 2. Arquitectura de Software y Patrones de Diseño

El proyecto ha sido refactorizado y consolidado adoptando patrones arquitectónicos profesionales que garantizan escalabilidad, bajo acoplamiento y facilidad de mantenimiento:

### 🧩 A. Arquitectura Basada en Componentes (*Component-Based Architecture*)
Se aplica el principio de **Composición sobre Herencia**, permitiendo que tanto el jugador como los enemigos compartan módulos reutilizables sin jerarquías rígidas:
- **`HealthComponent`:** Gestión estricta de vida (`current_health`, `max_health`), métodos de daño/curación, frames de invulnerabilidad temporal (*i-frames*) y señales `health_changed`, `damaged` y `died`.
- **`MovementComponent`:** Física cinemática desacoplada con aceleración, desaceleración, fricción y velocidades máximas.
- **`HitboxComponent` (Área Ofensiva):** Emisor de colisión de daño con valores configurables de impacto y fuerza de retroceso (*knockback*).
- **`HurtboxComponent` (Área Receptora):** Receptor de daño vinculado al `HealthComponent` con filtrado seguro de colisiones y cálculo de dirección de retroceso.

### 🌐 B. Capa de Servicios Core y Autoloads Globales
- **`EventBus` (`core/events/event_bus.gd`):** Bus global de eventos (*Observer Pattern*) que desacopla la comunicación entre subsistemas. La UI, los checkpoints y el audio escuchan señales sin necesidad de referenciar directamente al jugador ni a los niveles.
- **`GameState` (`core/services/game_state.gd`):** Singleton gestor del estado del juego en tiempo real (puntuación acumulada, monedas, estado de pausa, arma seleccionada y flags de progreso).
- **`SaveManager` (`core/services/save_manager.gd`):** Administrador de persistencia en disco local (`user://save_game.json`) con serialización segura de salud, puntuación, checkpoint activo y fecha de guardado.
- **`SceneFlow` (`core/services/scene_flow.gd`):** Máquina de control de flujo de escenas que gestiona transiciones fluidas con fundido (*fade*) entre el menú principal, pantallas de carga y niveles.

### 🖥️ C. Controlador Centralizado de Interfaz (`UIController`)
- Administra en una capa `CanvasLayer` independiente el **HUD** en vivo, el **Menú de Pausa**, y la **Capa de Notificaciones Flotantes (Toasts)** sin saturar el campo de visión del jugador.

---

## ⚔️ 3. Mecánicas y Sistemas de Juego

### 🏃‍♂️ A. Movimiento Fluido y *Game Feel*
- **Salto Dinámico y Gravedad Asimétrica:** Gravedad reforzada en la caída (`fall_gravity_multiplier`) y corte temprano de salto para control milimétrico de altura.
- **Coyote Time:** Margen de gracia que permite saltar fracciones de segundo después de abandonar el borde de una plataforma.
- **Jump Buffering:** Registro previo del input de salto antes de tocar tierra para que el salto ocurra al instante del impacto.
- **Dash Táctico:** Desplazamiento rápido horizontal con tiempo de recarga (*cooldown*) para esquivar ataques o cruzar precipicios.

### 🏹 B. Sistema de Combate y Alternancia de Proyectiles
El jugador puede alternar instantáneamente sus armas a distancia presionando la tecla **E** (`switch_weapon`):
1. **Piedra (Huaraca):** Proyectil rápido de trayectoria balística parabólica con gravedad, ideal para alcanzar enemigos en terrazas inferiores o detrás de coberturas.
2. **Lanza (Chuki):** Proyectil perforante de alta velocidad en línea recta, con mayor poder de daño y fuerte impacto de retroceso.

### ☀️ C. Power-Up: Poder del Sol (Inti)
- Activación de invulnerabilidad temporal contra ataques enemigos.
- Emisión continua de partículas doradas radiantes y aumento temporal de velocidad de ataque y movimiento.
- Efecto de sacudida de pantalla épico al ser invocado.

### 🎨 D. Shaders y Efectos Visuales (VFX)
- **`damage_flash.gdshader`:** Sombreador de fragmentos que tiñe temporalmente el sprite de blanco brillante al recibir impactos.
- **`dissolve.gdshader`:** Sombreador procedural con mapa de ruido simplex para la desintegración visual de enemigos derrotados.
- **`CameraShake` (`scripts/utils/camera_shake.gd`):** Sacudida paramétrica no intrusiva configurada para activarse exclusivamente en momentos de impacto crítico (al recibir daño severo o invocar el poder del sol).
- **Sistemas de Partículas (`GPUParticles2D`):** Polvo al aterrizar (`fx_land_dust`), chispas de impacto (`fx_hit_sparks`) y estallido de derrota (`fx_death_burst`).

### 🚩 E. Checkpoints y Meta de Nivel
- **Puntos de Control (`checkpoint.tscn`):** Tótems colocados en puntos clave del nivel. Al pasar cerca, se activan emitiendo un toast no invasivo y registrando la posición de reaparición (*respawn*) si el héroe cae.
- **Reliquia Sagrada de Fin de Nivel (`level_goal.tscn`):** El nivel concluye al alcanzar y tomar el trofeo ceremonial sagrado ubicado al final del templo, dando paso al mensaje de victoria y la transición al siguiente nivel.

---

## 🎮 4. Guía de Controles

| Acción | Teclado Principal | Teclas Alternativas | Gamepad (Xbox / Genérico) |
| :--- | :--- | :--- | :--- |
| **Moverse a la Izquierda** | `A` | `Flecha Izquierda` | D-Pad Izquierda / Stick Izq. |
| **Moverse a la Derecha** | `D` | `Flecha Derecha` | D-Pad Derecha / Stick Izq. |
| **Agacharse / Abajo** | `S` | `Flecha Abajo` | D-Pad Abajo / Stick Izq. |
| **Saltar** | `Espacio` | `W` / `Flecha Arriba` | Botón `A` (Cruz) |
| **Dash (Impulso)** | `Shift Izquierdo` | `K` | Botón `B` / Gatillo `RT` |
| **Ataque Cuerpo a Cuerpo** | `J` | `Clic Izquierdo` | Botón `X` (Cuadrado) |
| **Cambiar Proyectil (Piedra / Lanza)** | `E` | `U` | Botón `Y` / `RB` |
| **Disparar Proyectil** | `J` (a distancia) | `Clic Derecho` | Gatillo `RT` |
| **Menú de Pausa** | `Escape` | `P` | Botón `Start` |

---

## 📁 5. Estructura del Proyecto

```text
proyecto---cahuide/
├── components/                  # Arquitectura de componentes desacoplados
│   ├── combat/                 # HitboxComponent y HurtboxComponent
│   ├── health/                 # HealthComponent (Vida, daño, i-frames)
│   └── movement/               # MovementComponent (Física cinemática)
├── core/                        # Servicios centrales y Autoloads
│   ├── events/                 # EventBus (Patrón Observer global)
│   └── services/               # GameState, SaveManager, SceneFlow
├── materials/                   # Materiales y shaders compilados
├── resources/                   # Recursos custom (.tres) para ítems y stats
├── scenes/                      # Escenas principales del juego
│   ├── environment/            # Checkpoints, trofeos de meta, trampas
│   ├── levels/                 # Nivel 01 (level_01.tscn) y niveles sucesivos
│   ├── player/                 # Escena del héroe Cahuide (player.tscn)
│   ├── projectiles/            # Proyectiles (piedra y lanza)
│   └── vfx/                    # Efectos de partículas (polvo, chispas, explosión)
├── scripts/                     # Lógica en GDScript
│   ├── enemies/                # IA y controladores de enemigos
│   ├── environment/            # Lógica de checkpoints y metas de nivel
│   ├── levels/                 # Scripts de control de nivel
│   ├── player/                 # Controlador maestro del personaje
│   ├── projectiles/            # Cinemática balística de proyectiles
│   └── utils/                  # Cámara con sacudida paramétrica (camera_shake.gd)
├── shaders/                     # Sombreadores GLSL (damage_flash, dissolve)
├── ui/                          # Sistema de Interfaz de Usuario
│   ├── notifications/          # Notificaciones flotantes no invasivas (Toasts)
│   ├── pause/                  # Menú de pausa interactivo con guardado
│   └── ui_controller.gd        # Controlador unificado de la interfaz
└── project.godot                # Configuración maestra del motor
```

---

## 🚀 6. Instrucciones de Ejecución

1. Abre **Godot Engine 4** (versión 4.4 o superior).
2. En la lista de proyectos, haz clic en **Importar** (*Import*) y selecciona la ruta:
   `Proyecto Godot/proyecto---cahuide/project.godot`.
3. Haz clic en **Importar y Editar**.
4. Presiona **F5** (o el botón *Play* en la esquina superior derecha) para iniciar el juego desde el **Menú Principal**.
5. Desde el menú principal puedes seleccionar **Nueva Partida** o **Continuar** si ya cuentas con un archivo de guardado previo.
