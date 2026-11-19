# Laboratorio 10: Efectos Visuales (VFX) y Shaders 2D

**Curso:** Desarrollo de Videojuegos 2D con Godot  
**Estudiante:** Adam Soto  
**Proyecto:** `Lab10_VFX`  

---

## 🎯 Objetivo de la Sesión
Enriquecer el aspecto visual y la retroalimentación sensorial (*Game Feel*) mediante sistemas de partículas en GPU/CPU, sombreadores personalizados escritos en **Godot Shading Language (GLSL)** y efectos de cámara dinámicos.

---

## 🛠️ Implementaciones Realizadas

1. **Sistemas de Partículas (`GPUParticles2D`):**
   - **`fx_land_dust`**: Emisión de partículas de polvo al aterrizar tras un salto o caída.
   - **`fx_hit_sparks`**: Chispas en el punto exacto de colisión de un ataque.
   - **`fx_death_burst`**: Explosión de fragmentos al derrotar a un enemigo.

2. **Shader de Daño / Destello Blanco (`damage_flash.gdshader`):**
   - Shader de tipo `canvas_item` que interpola el color del sprite hacia blanco puro usando un parámetro uniforme `flash_strength`:
     ```glsl
     shader_type canvas_item;
     uniform float flash_modifier : hint_range(0.0, 1.0) = 0.0;
     uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
     void fragment() {
         vec4 color = texture(TEXTURE, UV);
         COLOR = mix(color, flash_color, flash_modifier);
         COLOR.a = color.a;
     }
     ```

3. **Shader de Desvanecimiento / Disolución (`dissolve.gdshader`):**
   - Shader con textura de ruido fractal (*noise texture*) para desintegrar entidades al morir o al disiparse un poder.

4. **Sacudida de Cámara Paramétrica (`Camera Shake`):**
   - Script utilitario que aplica un desplazamiento oscilatorio decreciente basado en ruido Perlin o trigonométrico cuando el jugador recibe daño o activa un impacto fuerte.

---

## 💡 Conceptos Clave Aprendidos
- **Shaders en la GPU:** Operan en paralelo a nivel de fragmento/píxel, siendo inmensamente más rápidos que modificar texturas mediante código de CPU.
- **Micro-Retroalimentación Sensorial:** El destello blanco y las partículas de impacto comunican al instante si un golpe fue exitoso.
