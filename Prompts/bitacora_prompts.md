# BITÁCORA DE GENERACIÓN DE MODELOS CON IA (TRIPO / MESHY)

## 1. Identificación y Parámetros de Generación

- **Estudiante:** Daniela Campos Martínez / Francisco Javier García Rosados
- **Herramienta IA:** Tripo3D (v2.0) / Meshy.ai
- **Fecha de generación:** 29 de Septiembre de 2026
- **Procedencia:** Generado mediante IA generativa 3D a partir de prompt de texto, post-procesado para integración en Godot 4.x.
- **Licencia / Uso:** Formato educativo / Prototipado académico.

---

## 2. Prompt Exacto Utilizado

```text
Stylized low-poly adventurer explorer character, humanoid proportions, wearing an explorer jumpsuit with backpack and visor helmet, symmetrical T-pose, clean edge flow, game-ready asset, flat shading friendly, no internal floating geometry.
```

### Parámetros y Ajustes de Exportación:
- **Topología / Target Polygons:** ~2,500 - 4,000 triángulos (optimizado para tiempo real).
- **Postura:** T-Pose simétrica (orientada hacia el eje Z negativo en Godot).
- **Formato de exportación:** `.glb` / `.gltf` (glTF 2.0 con texturas embebidas).
- **Espacio de color / Texturas:** sRGB para Albedo/BaseColor, Linear para Roughness/Metallic/Normal.

---

## 3. Ficha Técnica del Modelo 3D

| Atributo | Especificación / Medición | Estado / Observación |
| :--- | :--- | :--- |
| **Triángulos** | 3,120 tris | Rango ideal para low-poly / prototipo móvil y PC |
| **Vértices** | 1,624 vértices | Sin vértices no soldados ni caras dobles |
| **Materiales** | 1 material PBR (`StandardMaterial3D`) | Reducción de draw calls |
| **Texturas** | 1024x1024 (Albedo, Roughness, Normal) | Formato PNG / WebP optimizado |
| **Escala** | Altura: 1.80 m (Y: 1.8, X: 0.8, Z: 0.5) | Escala humana estándar 1:1 en Godot |
| **Normales** | Normales exteriores calculadas correctamente | Sin caras invertidas ni sombreado roto |
| **Articulaciones** | T-pose estándar preparada para retargeting | Base lista para IK / animaciones en Tarea 2 |

---

## 4. Documentación de las 3 Verificaciones Técnicas Obligatorias

En lugar de simular fallas ficticias, se aplicó el protocolo de verificación en 3 etapas conforme a los lineamientos:

### Verificación 1: Orientación de Ejes y Escala Métrica
- **Prueba:** Se importó el modelo en una escena de prueba junto a una caja de referencia de $1 \times 2 \times 1\text{ m}$.
- **Resultado:** El modelo original generado por IA presentaba una rotación de $90^\circ$ en el eje X y una altura de $18\text{ m}$ (escala $10\times$).
- **Corrección aplicada:** En las opciones de importación de Godot (`Import Dock`), se configuró la escala de importación a $0.1$ y se corrigió la orientación hacia el frente de Godot (eje $-Z$), garantizando que al presionar la tecla **W** el personaje se desplace hacia adelante.

### Verificación 2: Integridad de la Malla y Normales
- **Prueba:** Inspección visual en modo *Wireframe* y *Display Normales* en Godot 3D.
- **Resultado:** No se encontraron polígonos degenerados ni normales invertidas en el torso ni extremidades. Se eliminaron polígonos internos no visibles que la IA generó en la base del casco.

### Verificación 3: Escena Envolvente y Desacoplamiento Arquitectónico
- **Prueba:** Conservar separado el modelo importado del controlador (`CharacterBody3D`).
- **Implementación:** Se construyó la escena envolvente `res://scenes/character_model.tscn`, la cual se instancia dentro del nodo `VisualWrapper` en `res://scenes/player.tscn`. De este modo:
  1. El controlador de físicas (`player.gd`) manipula únicamente la posición del cuerpo de colisión (`CollisionShape3D`).
  2. La actualización visual (`_process`) rota el `VisualWrapper` de manera independiente y suave.
  3. Reemplazar o actualizar el modelo generado por IA no afecta la jerarquía ni los scripts del jugador.
