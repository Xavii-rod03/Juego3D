# PROMPT Y BITÁCORA DE MODELADO 3D CON INTELIGENCIA ARTIFICIAL

**Proyecto:** Laberinto 3D  
**Entrega:** Tarea 1 - Modelado y Animación con IA    
**Fecha:** Octubre 2026  
 

---

## 1. Prompt Exacto Utilizado

### Pront:
> *"Personaje explorador aventurero estilizado en bajo poligonaje (low-poly), proporciones humanoides, vistiendo un traje de explorador con mochila propulsora y casco con visor, pose en T simétrica, flujo de aristas limpio, recurso listo para videojuego, apto para sombreado plano, sin geometría flotante interna y topología optimizada."*

---

## 2. Parámetros y Ajustes de Generación

| Parámetro | Configuración | Razón Técnica |
| :--- | :--- | :--- |
| **Plataforma / Motor** | Tripo3D / Meshy.ai | Generación de malla 3D y texturas PBR a partir de texto |
| **Postura (Pose)** | T-Pose Simétrica | Estándar para retargeting, rigging y animación en la Tarea 2 |
| **Límite Poligonal** | $\approx 3,000$ a $4,000$ triángulos | Optimizado para tiempo real |
| **Espacio de Color** | sRGB (Albedo), Linear (Roughness, Metallic) | Cumplimiento del estándar PBR en Godot 4.x |
| **Texturizado** | Textura difusa / PBR $1024 \times 1024$ | Balance ideal entre nitidez visual y consumo de VRAM |

---

## 3. Ficha Técnica del Modelo 3D Final

- **Triángulos:** 3,120 tris (topología controlada y limpia).
- **Vértices:** 1,624 vértices.
- **Materiales:** 1 material PBR (`StandardMaterial3D`).
- **Texturas:** 1 mapa de textura unificado de $1024 \times 1024\text{ px}$.
- **Escala:** Altura proporcional de $1.80\text{ m}$ (coincide con la cápsula de colisión humana de Godot).
- **Normales:** Normales exteriores unificadas (sin polígonos invertidos ni sombreado roto).
- **Articulaciones:** Geometría separada en torso, hombros, extremidades y visor, lista para cinemática inversa y animación.

---

## 4. Protocolo de las Tres Verificaciones Técnicas (Cumplimiento de Rúbrica)

Para cumplir con la directiva de *"documentar tres verificaciones en lugar de inventar defectos"*, se ejecutaron las siguientes pruebas técnicas:

### Verificación 1: Escala Métrica y Orientación de Ejes
- **Prueba realizada:** Se importó el modelo junto a un cubo de referencia de $1 \times 1 \times 1\text{ m}$ en la escena 3D de Godot.
- **Observación inicial:** Los generadores de IA frecuentemente exportan mallas orientadas al eje $Y$ hacia arriba pero con el frente hacia $+Z$ o rotadas $90^\circ$ en $X$, y a una escala basada en centímetros ($180\text{ cm} = 18\text{ m}$ en Godot).
- **Ajuste aplicado:** En las propiedades de importación de Godot (`Import Dock`), se escaló a $0.1$ y se confirmó la orientación frontal hacia el eje $-Z$ de Godot, garantizando que el personaje avance hacia adelante al presionar la tecla **W**.

### Verificación 2: Inspección de Malla, Normales y Topología
- **Prueba realizada:** Se activaron los modos *Debug Draw: Wireframe* y *Overdraw* en el viewport 3D.
- **Resultado:** Se comprobó que no existían caras invertidas (*backface culling* accidental) ni geometría invisible que aumentara el costo de renderizado.

### Verificación 3: Escena Envolvente y Desacoplamiento Arquitectónico
- **Prueba realizada:** Comprobar la separación del modelo importado respecto al controlador cinemático.
- **Implementación:** El modelo se encapsuló en la escena `res://scenes/character_model.tscn`, la cual se instancia dentro del nodo `VisualWrapper` en `res://scenes/player.tscn`.
- **Beneficio técnico:** 
  1. El cuerpo físico (`CharacterBody3D`) y la cápsula de colisión (`CollisionShape3D`) mantienen su tamaño fijo de $1.8\text{ m} \times 0.4\text{ m}$.
  2. La interpolación visual suave (`lerp_angle` en `_process`) opera exclusivamente sobre el contenedor `VisualWrapper`.
  3. Sustituir o re-importar el modelo 3D o sus animaciones no requiere alterar ninguna línea del código de movimiento ni de las colisiones del jugador.
