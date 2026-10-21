# Línea de cohetes por rareza — Prompt 1

Arte conceptual para la tienda de **Slime al Espacio**. Fecha: 2026-10-21.
Se aplicó el contexto del Prompt 0 y se entregó solamente el Prompt 1.

## Archivos y uso

| Archivo | Contenido | Tamaño |
|---|---|---|
| `lineup_cohetes.png` | Los cinco cohetes en fila, cielo claro, nombres y rarezas en español. Comparación de familia y progresión visual. | 1774 × 887 px |
| `turnaround_comun.png` | Cohete Burbuja: frente, lado, atrás y 3/4. | 2048 × 2048 px |
| `turnaround_raro.png` | Cohete Turbo: frente, lado, atrás y 3/4. | 2048 × 2048 px |
| `turnaround_epico.png` | Cohete Relámpago: frente, lado, atrás y 3/4. | 2048 × 2048 px |
| `turnaround_legendario.png` | Cohete Fénix: frente, lado, atrás y 3/4. | 2048 × 2048 px |
| `turnaround_mitico.png` | Cohete Galáctico: frente, lado, atrás y 3/4. | 2048 × 2048 px |
| `vista_previa_cohetes.jpg` | Copia ligera de la línea completa para verla en el navegador. | 1200 × 600 px |
| `entrega_cohetes.zip` | Paquete con los seis PNG, la vista previa JPG y estas notas. | Aproximadamente 20 MB |

Todos son PNG con fondo opaco. Las hojas son referencias para modelado y selección de apariencia, con punta hacia arriba. Las vistas son ilustrativas, no proyecciones ortográficas calibradas: al modelar, mantener una sola geometría coherente entre ángulos. Las hojas se generaron a 1254 × 1254 y se reescalaron con Lanczos a la medida solicitada; el reescalado no añade detalle nativo.

## Familia visual

Cuerpo gordito tipo cápsula, ventana circular azul con aro plateado, aletas redondeadas, plástico brillante, contorno ciruela `#1C1628`. Mantener la misma altura de casco entre rarezas; la progresión se expresa mediante aletas, gráficos y efectos. Ventana solo al frente. Los rótulos del arte son rasterizados y de estilo redondo grueso; para texto editable en la interfaz, usar **Fredoka One**.

## Paletas HEX objetivo

Los códigos definen los colores base para reproducir el diseño; luces, reflejos y degradados del arte varían sus valores aparentes.

| Rareza / cohete | Cuerpo, nariz y aletas | Detalles |
|---|---|---|
| Común — Burbuja | Blanco `#F7FBFF`, azul rey `#1648F5` | Franjas celeste `#39C7FA` y amarillo `#FFD43B`; estrellas y luna amarillas. |
| Raro — Turbo | Blanco `#F7FBFF`, menta `#30DFAD`, verde petróleo `#078C79` | Franjas diagonales blancas y menta, cinturón verde petróleo, aletas barridas. |
| Épico — Relámpago | Morado `#833CE5`, amarillo `#FFE34D` | Rayos amarillos, estrellas moradas en aletas y doble tobera. |
| Legendario — Fénix | Dorado `#FFC83D`, naranja `#FF7A24` | Bordes oro claro `#FFE58A`, aletas con lóbulos de pluma y gráficos de alas alrededor de la ventana. |
| Mítico — Galáctico | Violeta `#5630B7`, rosa `#EF54D9`, azul `#43CAFF` | Nariz `#6931D8`, aletas lila `#B889FF` y celeste, estrellas blancas `#FFFFFF`, anillo celeste y rosa. |

Compartidos: aro y toberas plata `#B7C5D7`, cristal azul `#075AF5`, reflejos de cristal `#69E9FF`, tinta `#1C1628`, fondo de hojas azul muy claro `#F2F7FF`.

Colores de etiqueta de rareza: Común `#BEC8D2 → #788796`; Raro `#6EC8FF → #236EE6`; Épico `#D782FF → #822DD2`; Legendario `#FFE15A → #F08C14`; Mítico `#FF78BE → #7850FF`.

## Efectos propuestos para el juego

| Cohete | Fuego | Estela | Partículas y brillo |
|---|---|---|---|
| Burbuja | Una llama corta amarilla `#FFD951`, borde naranja `#FF963C`. | Blanca `#FFFFFF`, tenue y corta. | Pocas motas cálidas y humo blanco al despegar; reflejos de plástico, sin aura persistente. |
| Turbo | Una llama menta `#66FFE3` que pasa a cian `#25CFF4`, centro blanco. | Cian fina `#55ECFF`, más larga que Burbuja. | Pequeños puntos blancos y trazos de velocidad; resplandor menta discreto en el motor. |
| Relámpago | Dos llamas: núcleo amarillo eléctrico `#FFF477` y borde violeta `#B05CFF`. | Violeta `#9952FF` con pulsos amarillos. | Chispas y rayitos amarillos que se desvanecen; destellos intermitentes junto a las dos toberas. |
| Fénix | Azul intenso `#2D6BFF`, cian `#26CFFF` y núcleo azul muy claro `#C7FAFF`. | Azul celeste `#47CFFF`, limpia y luminosa. | Aura dorada suave `#FFD45A`, motas y rombos dorados. Mantener el fuego azul para contrastar con el casco cálido. |
| Galáctico | Arcoíris: rojo `#FF516B`, naranja `#FFAE43`, amarillo `#FFE45C`, verde `#69EF8B`, cian `#43D9FF`, azul `#4777FF`, violeta `#B16AFF`. | Cinta arcoíris con esa secuencia, más larga y luminosa que las demás. | Estrellas blancas, rosas y celestes; halo rosa-violeta y anillo flotante con brillo cian/rosa. |

Las imágenes muestran una muestra estática de los efectos. Estelas prolongadas, movimiento, destellos y partículas son indicaciones para la futura integración, no efectos ya implementados. Mantener libre la ventana y el espacio de la mascota piloto; colocar el anillo con separación real del casco y ajustar su altura si tapa al piloto.

## Referencias y alcance

Se leyó completo el documento `PROMPTS_CODEX.md` adjunto y se revisaron las 11 imágenes adjuntas: siete capturas del vuelo/mundo, panel Rebirth, panel Fusión y las dos referencias de cohete. En este checkout no existían `codex_assets/PROMPTS_CODEX.md` ni `codex_assets/referencias/`; se usaron los adjuntos proporcionados.

Referencia principal: juguete blanco/azul con estrellas, luna, franjas y ventana redonda. Las capturas guiaron la saturación, los bordes y los colores de rareza. Diseños creados sin logotipos ni marcas. No se modificaron scripts, el place ni archivos fuera de `codex_assets/` en el repositorio. Esta entrega no incluye modelos 3D, íconos transparentes, código ni panel de tienda: corresponden a otros prompts.
