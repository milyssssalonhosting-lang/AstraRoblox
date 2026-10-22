# Prompt 8 — Íconos del HUD

24 íconos originales para **Slime al Espacio**, siguiendo el contexto del Prompt 0. Cada `icon_*.png` es un PNG RGBA de **512 × 512**, con transparencia real, sin palabras ni números. El objeto ocupa aproximadamente el 85% de su dimensión mayor. No se cambiaron los scripts del juego ni el place.

## Archivos para integrar

| Archivo | Uso |
|---|---|
| `icon_settings.png` | Configuración: engrane plateado/celeste. |
| `icon_daily_rewards.png` | Diarias: calendario sin números con regalo. |
| `icon_missions.png` | Misiones: pergamino con palomita. |
| `icon_shop.png` | Tienda: carrito con huevo. |
| `icon_pass.png` | Pase: boleto dorado con estrella. |
| `icon_rebirth.png` | Rebirth: flechas circulares turquesa/azul. |
| `icon_index.png` | Índice: libro con huella. |
| `icon_inventory.png` | Inventario: mochila naranja/coral. |
| `icon_codes.png` | Códigos: cupón rosa con estrella. |
| `icon_money.png` | Dinero: moneda verde/dorada con slime. Sin símbolo $ para respetar la regla de piezas sin texto. |
| `icon_gem.png` | Gema cian. |
| `icon_xp.png` | XP: estrella dorada. |
| `icon_trophy.png` | Récord: trofeo dorado. |
| `icon_turbo.png` | Turbo: rayo celeste. |
| `icon_fuel.png` | Combustible: gota ámbar. |
| `icon_rocket.png` | Velocidad: Cohete Burbuja. |
| `icon_paw.png` | Mascotas: huella rosa/lila. |
| `icon_friends.png` | Amigos: dos slimes abrazados. |
| `icon_meteor.png` | Trolleo meteorito: roca caricatura en llamas. |
| `icon_magnet.png` | Trolleo robar turbo: imán y rayo. |
| `icon_nuclear.png` | Trolleo nuclear: bomba de juguete sonriente, con estrella y mecha. Sin símbolo de radiación. |
| `icon_auto.png` | Automático: robot slime. |
| `icon_tap.png` | TAP: dedo presionando un botón con pictograma de cohete. |
| `icon_close.png` | Cerrar: dos barras cruzadas. Es un pictograma geométrico, sin tipografía. |

Tamaños sugeridos en pantalla: menú 40–64 px; estadísticas 24–36 px; trolleos 44–60 px; Auto/TAP 28–48 px; cerrar 24–32 px. Mantener relación 1:1 con `ScaleType = Fit`, fondo del ImageLabel transparente y color de imagen blanco. El color del texto y la tipografía **Fredoka One** los pone el juego.

## Capas separadas para animación

Los íconos son bases estáticas. Los cuatro `fx_*.png` son overlays independientes, también **512 × 512 RGBA**, centrados en **(256, 256)**. Usar el mismo centro y tamaño de contenedor que el ícono; animar estas capas de forma independiente. Los reflejos pintados del plástico son parte de la ilustración estática, no una animación incorporada.

| Capa | Orden | Movimiento propuesto | Duración / repetición | Cuándo aparece |
|---|---|---|---|---|
| `fx_glow_cyan.png` | Detrás del ícono | Escala 0.95 → 1.08 → 0.95; transparencia 0.85 → 0.55 → 0.85. | Ciclo completo 1.6 s, continuo mientras esté activo. | Turbo o Auto activos. |
| `fx_glow_gold.png` | Detrás | Mismo pulso de escala y transparencia, suave. | Ciclo completo 1.8 s, continuo mientras haya premio listo. | Diaria o misión lista; detener tras reclamar. Para récord, mostrar 2 ciclos. |
| `fx_sparkle.png` | Delante | Escala 0.7 → 1.1 → 0.8; transparencia 1 → 0.3 → 1. | Destello completo 0.55 s, una vez. | Hover, recompensa lista o confirmación. |
| `fx_rays.png` | Detrás | Giro de 0° a 360°, lineal; transparencia sugerida 0.7. | Vuelta completa 12 s, continua mientras esté disponible. | Rebirth disponible o premio especial. |

Los tiempos indicados son ciclos completos, incluyendo ida y vuelta cuando corresponde. Al cerrar el panel o desactivarse el estado, ocultar la capa y detener su ciclo. `hud_assets.json` recoge archivos, usos, centros y estas indicaciones para Claude. No hay efectos programados ni scripts ocultos.

**9-slice / SliceCenter:** no aplica a estos pictogramas ni overlays. Este pedido no incluye marcos ni fondos de botones; los íconos Auto, TAP y Cerrar se colocan sobre los botones que ya tenga el juego. No estirar los íconos con `ScaleType.Slice`. Los marcos y botones de los pedidos posteriores sí deberán incluir sus márgenes 9-slice.

**Flipbooks:** no se incluyen en este set de íconos. Estas capas se animan por giro, escala y transparencia dentro del juego; las partículas y sus flipbooks corresponden al Prompt 11.

## Revisión y verificación

- `lamina_iconos.png`: lámina transparente de los 24 íconos, 1008 × 672, seis columnas por cuatro filas. Orden: el de la tabla de arriba, de izquierda a derecha y de arriba a abajo.
- `vista_previa_hud.jpg`: la misma lámina sobre fondo lila claro, solo para revisar en GitHub; no es una pieza de interfaz ni un fondo para importar.
- `VALIDACION.json`: dimensiones, canal alfa, transparencia y huellas SHA-256 de las piezas entregadas.
- `entrega_iconos_hud.zip`: solamente esta entrega; no incluye el juego ni los assets anteriores.

Se comprobaron los 24 íconos y los cuatro overlays: RGBA, 512 × 512, bordes transparentes y píxeles de alfa cero. La transparencia no se simula con cuadros pintados. Se revisó visualmente la lámina a tamaño reducido. No se probó su integración dentro de Roblox Studio.

## Mockup pendiente de captura

Falta **`mockup_hud_1920x1080.png` sobre una captura real del juego**. Las capturas del HUD adjuntas en la conversación anterior no existen como archivos accesibles en este checkout, y `codex_assets/referencias/` no está presente. Se pidió volver a adjuntar una captura; con ella se montará el mockup a 1920 × 1080. La lámina de revisión no se presenta como si fuera esa captura ni como si la interfaz ya estuviera integrada.
