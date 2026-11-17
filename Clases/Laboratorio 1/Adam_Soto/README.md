# Laboratorio 01: Introducción a Godot Engine 4 y Prototipado 2D

**Curso:** Desarrollo de Videojuegos 2D con Godot  
**Estudiante:** Adam Soto  
**Proyecto:** `Lab01_Godot2D` / Prototipo conceptual Cahuide  

---

## 🎯 Objetivo de la Sesión
Familiarizarse con el entorno de desarrollo de **Godot Engine 4**, comprender la filosofía de diseño orientada a nodos y árboles de escenas (*SceneTree*), configurar los parámetros básicos de renderizado 2D y diseñar los primeros prototipos conceptuales y mecánicos del proyecto del curso.

---

## 🛠️ Implementaciones Realizadas

1. **Configuración del Proyecto:**
   - Creación del proyecto base con compatibilidad gráfica **GL Compatibility**.
   - Definición de resolución base de viewport (1280x720) y modo de escalado `canvas_items` con aspecto `expand`.
   - Mapeo inicial de acciones de entrada (`move_left`, `move_right`, `jump`).

2. **Estructura de Nodos 2D:**
   - Creación de la primera escena de prueba utilizando nodos raíz `Node2D`.
   - Integración de `Sprite2D` para renderizado de texturas y sprites de prueba.
   - Adición de `Camera2D` para seguimiento básico del área visible.

3. **Prototipado Conceptual:**
   - Elaboración y guardado de los bocetos de diseño (`Prototipo1.jpeg` a `Prototipo4.jpeg`) que definen el estilo visual, paleta de colores y silueta del guerrero inca **Cahuide**.
   - Estructuración inicial de carpetas del repositorio según buenas prácticas.

---

## 💡 Conceptos Clave Aprendidos
- **Nodos y Escenas:** En Godot todo es una escena compuesta por nodos especializados (`Sprite2D`, `Camera2D`, `Node2D`).
- **SceneTree:** El árbol de ejecución que coordina la actualización (`_process`), el renderizado y el ciclo de vida de los nodos.
- **Viewport y Escalado:** Cómo configurar la ventana para mantener la nitidez y relación de aspecto en diferentes monitores.
