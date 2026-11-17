# Laboratorio 04: Construcción de Escenarios con TileMaps y TileSets

**Curso:** Desarrollo de Videojuegos 2D con Godot  
**Estudiante:** Adam Soto  
**Proyecto:** `Lab04_TileMap`  

---

## 🎯 Objetivo de la Sesión
Dominar el flujo de trabajo con la herramienta de cuadrícula 2D en Godot 4 mediante el uso de recursos `TileSet` y nodos `TileMap`, estructurando capas de renderizado independientes y asignando propiedades físicas de colisión y navegación a los tiles.

---

## 🛠️ Implementaciones Realizadas

1. **Configuración del Recurso `TileSet`:**
   - División precisa de texturas en atlas de tiles con tamaño de celda estándar (16x16 / 32x32 píxeles).
   - Definición de formas de colisión estáticas por celda en la capa física (*Physics Layer*).

2. **Capas de Renderizado en `TileMap`:**
   - Capa de **Fondo (Background)**: Elementos visuales decorativos sin colisión y con modulación oscura.
   - Capa de **Terreno/Suelo (Ground)**: Bloques sólidos principales donde el jugador y enemigos interactúan y colisionan.
   - Capa de **Detalles/Decoración (Foreground)**: Vegetación, antorchas y elementos superpuestos con orden Z apropiado.

3. **Herramientas de Autotiling y Terrenos:**
   - Configuración de conjuntos de terrenos (*Terrain Sets*) para pintar de forma orgánica esquinas, bordes y bloques centrales sin seleccionar manualmente cada variante de tile.

4. **Optimización de Escenario:**
   - Agrupación de polígonos de colisión para evitar fisuras o enganches microscópicos en bordes de baldosas.

---

## 💡 Conceptos Clave Aprendidos
- **Godot 4 TileMap Architecture:** El rediseño de TileMaps en Godot 4 permite capas múltiples dentro de un solo nodo, reduciendo la complejidad del árbol de escenas.
- **Layers vs Physics Layers:** Separar la representación visual de la lógica de colisiones garantiza niveles más eficientes y fáciles de expandir.
