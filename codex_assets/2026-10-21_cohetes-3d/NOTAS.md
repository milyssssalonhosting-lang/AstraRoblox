# Prompt 14 — Cinco cohetes 3D reales

Modelos originales basados en la línea y las cinco hojas de `2026-10-21_linea-cohetes`, con sus paletas HEX. Exportados a **FBX binario 7.4**, reabiertos con **Blender 4.3.2** y verificados. Cada cohete tiene un atlas de color con UVs, piezas separadas y una fuente `.blend` con textura empaquetada.

## Qué descargar e importar

Por cada rareza (`comun`, `raro`, `epico`, `legendario`, `mitico`):

- `rocket_<rareza>.fbx`: el modelo para el importador 3D de Roblox.
- `rocket_<rareza>_atlas.png`: su única textura de color, **1024 × 1024**. Mantenerla junto al FBX.
- `rocket_<rareza>.blend`: fuente editable con la textura empaquetada.
- `preview_<rareza>.png`: render 3/4, **1024 × 1024 RGBA**, realizado con el FBX reimportado, sin fuego ni partículas añadidos.

`build_rockets.py` reproduce geometría, atlas, exportación, verificación y renders. `VALIDACION.json` y `verification_<rareza>.json` contienen las mediciones y SHA-256 de los FBX y atlas. `INTEGRACION.json` recoge posiciones, pivotes, colores del fuego y movimientos para Claude. `vista_previa_cohetes_3d.jpg` reúne los cinco renders, de Común a Mítico. El ZIP contiene únicamente esta entrega.

## Medidas verificadas

Todos los valores son **metros** en el marco del cohete: **X horizontal, Y arriba, frente hacia -Z**. El pivote raíz está en **(0, 0, 0)**, centro de la caja envolvente del modelo completo. La punta alcanza Y = +1.4 y la salida de las toberas Y = -1.4. El total mide **2.8 m ≈ 10 studs**, usando 1 stud = 0.28 m.

| Cohete | Triángulos totales | Tamaño X × Y × Z (m) | Mallas separadas |
|---|---:|---|---|
| Común — Burbuja | 3.782 | 2.030 × 2.800 × 1.5631 | Body, Fins, Window, Nozzle |
| Raro — Turbo | 3.710 | 2.1395 × 2.800 × 1.5631 | Body, Fins, Window, Nozzle |
| Épico — Relámpago | 4.222 | 2.030 × 2.800 × 1.5631 | Body, Fins, Window, Nozzle |
| Legendario — Fénix | 4.398 | 2.300 × 2.800 × 1.5631 | Body, Fins, Window, Nozzle, WingLeft, WingRight |
| Mítico — Galáctico | 4.806 | 2.1830 × 2.800 × 2.260 | Body, Fins, Window, Nozzle, Ring |

`Body` incluye cuerpo, nariz y aro plateado con remaches. `Window` contiene solo el cristal azul. Las piezas estáticas comparten el origen raíz. Hay cuatro aletas: dos laterales y dos más cortas al frente y atrás; en el Fénix, las laterales se sustituyen por las dos alas independientes. El Épico tiene **dos componentes de tobera** dentro de `Nozzle`, comprobados tras importar el FBX.

## Posiciones de ventana, piloto, fuego y estela

Las posiciones se refieren al pivote raíz, no al centro de la pieza Nozzle.

| Cohete | Centro de cada salida de tobera (m) | Centro de ventana (m) |
|---|---|---|
| Burbuja | (0, -1.400, 0) | (0, +0.200, -0.617) |
| Turbo | (0, -1.400, 0) | (0, +0.200, -0.617) |
| Relámpago | (-0.205, -1.400, 0) y (+0.205, -1.400, 0) | (0, +0.200, -0.617) |
| Fénix | (0, -1.400, 0) | (0, +0.200, -0.617) |
| Galáctico | (0, -1.400, 0) | (0, +0.200, -0.617) |

- El frente exterior del cristal llega a **Z = -0.697 m**. Centro inicial recomendado para colocar el slime: **(0, +0.200, -0.870) m**; ajustar según el tamaño real de la mascota.
- Para cada fuego, colocar el Attachment 0.01 m más abajo de la salida: **Y = -1.410 m**, mismo X y Z de su tobera. Dirección de emisión: **(0, -1, 0)**.
- Estela única: extremos **(-0.240, -1.380, 0)** y **(+0.240, -1.380, 0)**. En el Épico, usar X = ±0.340 m para abarcar las dos toberas.
- No hay geometría ni adornos añadidos delante del cristal. El anillo del Galáctico está por debajo: separación vertical mínima de la ventana **0.1478 m** y distancia mínima al casco **0.4296 m** en la pose de reposo.

## Piezas y animación propuesta — sin keyframes

Todos los ejes indicados se refieren al **marco Y-up del cohete en Roblox**. Conservar la transformación de reposo importada de cada MeshPart al aplicar un offset animado.

| Pieza | Pivote en metros | Movimiento | Ritmo y uso |
|---|---|---|---|
| Raíz completa de cada cohete | (0, 0, 0) | Balanceo visual ±2° sobre Z y flotación ±0.025 m en Y. | Seno, ciclo completo 2.6 s, mientras está en reposo. No sustituye a la trayectoria del juego. |
| WingLeft del Fénix | (-0.460, -0.540, 0) | Giro sobre Y: -15° × sin(2πt / 0.6). | Aleteo continuo durante vuelo. |
| WingRight del Fénix | (+0.460, -0.540, 0) | Giro sobre Y: +15° × sin(2πt / 0.6). | Mismo reloj que la izquierda, signo opuesto; ciclo completo 0.6 s. |
| Ring del Galáctico | (0, 0, 0) | Giro lineal sobre Y, 360°. | Una vuelta cada 3 s, mientras el cohete sea visible. |

`Body`, `Fins`, `Window` y `Nozzle` permanecen fijos respecto a la raíz. La geometría del anillo está inclinada 15° y centrada a Y = -0.540 m, pero **su origen es el centro del cohete**. La rotación propuesta mantiene su distancia radial y su intervalo de alturas, dejando libre la ventana. Las alas tienen los orígenes en sus uniones con el casco, no en sus centros.

No se hornearon movimientos, esqueletos ni efectos. Claude implementa el aleteo, giro, idle, ParticleEmitter, Trail y las activaciones de vuelo.

## Colores y acabado

| Cohete | HEX base / dibujos pintados | Fuego y estela propuestos |
|---|---|---|
| Burbuja | Blanco #F7FBFF, azul #1648F5, franjas #39C7FA y #FFD43B; estrellas y luna amarillas. | Fuego #FFD951 → #FF963C; estela blanca. |
| Turbo | Blanco #F7FBFF, menta #30DFAD, nariz y franja #078C79; franjas diagonales. | #66FFE3 → #25CFF4; estela cian. |
| Relámpago | Morado #833CE5 y amarillo #FFE34D; rayos y estrellas en aletas. | Dos llamas amarillas/violetas #FFF477 y #B05CFF; estela violeta. |
| Fénix | Dorado #FFC83D, naranja #FF7A24 y borde #FFE58A; gráficos de alas y trazos de pluma. | Azul #2D6BFF, cian #26CFFF y núcleo #C7FAFF; aura dorada a programar. |
| Galáctico | Violeta #5630B7, rosa #EF54D9 y cian #43CAFF, nariz #6931D8, aletas #B889FF; nebulosa y estrellas pintadas. | Arcoíris #FF516B, #FFAE43, #FFE45C, #69EF8B, #43D9FF, #4777FF, #B16AFF. |

Los dibujos se encuentran en el atlas, no en objetos flotantes ni imágenes de fondo. El único atlas de cada modelo es opaco: es un mapa de color para mallas, no una pieza de interfaz. Los PNG de vista previa sí tienen fondo transparente. Los reflejos del render dependen de la iluminación; los colores base del atlas conservan los HEX indicados.

## Importación e integración en Roblox

1. Extraer el ZIP. Importar el FBX deseado con su PNG de atlas al lado, conservando las piezas separadas.
2. Revisar el tamaño final: **10 studs de alto**. Si se importara como 2.8 studs, aplicar una escala uniforme de **3.5714286**. No escalar cada eje por separado.
3. Comprobar el atlas en cada MeshPart. Si el importador no lo vincula, subir el PNG correspondiente y asignar el mismo mapa de color a las piezas del cohete. No es necesario descargar ninguna textura externa.
4. Conservar los pivotes de WingLeft, WingRight y Ring. Si Studio los recentra, restaurarlos con las coordenadas documentadas —convertidas a studs— antes de animar.
5. El juego actual usa `Root`, `PrimaryPart`, `Exhaust`, `Pilot` y la estela. El Empty raíz del FBX **no es un Part de Roblox**. Claude debe añadir el Root invisible y los Attachments al integrar las mallas. Los dos fuegos del Épico requieren dos Attachments.

**Verificado aquí:** FBX reimportados en Blender, límites de triángulos, altura/pivote, piezas, componentes de las toberas, UVs, atlas de 1024, ejes/unidades FBX y separaciones del anillo. Los renders provienen de esos mismos FBX reimportados.

**No ejecutado aquí:** importación y funcionamiento dentro de Roblox Studio. No se modificaron scripts del juego ni `Place1.rbxl`. Los modelos y las fuentes `.blend` no contienen scripts ocultos, textos ejecutables ni animaciones.

## Reproducir la entrega

Requiere Blender 4.3.2, sin paquetes externos ni acceso a internet. Ejecutar en una terminal:

```sh
blender -b -t 2 --python-exit-code 1 --python build_rockets.py -- --output-dir ./salida
```

Solo un cohete, por ejemplo el Mítico:

```sh
blender -b -t 2 --python-exit-code 1 --python build_rockets.py -- --output-dir ./salida --only mitico
```

Reabrir y validar los cinco FBX existentes sin reconstruirlos ni renderizar:

```sh
blender -b -t 2 --python-exit-code 1 --python build_rockets.py -- --output-dir ./salida --verify-only --skip-render
```

Los archivos `.blend` usan el espacio nativo Z-up de Blender; el exportador los convierte al FBX Y-up indicado. La salida se reemplaza al reconstruir. Los renders usan Cycles en CPU y no requieren OpenImageDenoise.
