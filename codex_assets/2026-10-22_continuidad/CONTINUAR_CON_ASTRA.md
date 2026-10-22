# Continuidad para Astra — Slime al Espacio

**Actualizado: 22 de octubre de 2026.**

Este documento permite continuar el trabajo de este chat en otro chat de Astra / ChatGPT Codex, incluida la aplicación de PC. Es contexto de trabajo y registro de entregas. **Leerlo no significa ejecutar todos los pedidos pendientes: el usuario indicará la siguiente tarea.**

## 1. Quiénes somos y cómo trabajamos

- El usuario está creando un juego de Roblox y aprende Roblox Studio. Explicar en **español**, con pasos claros y sin asumir experiencia técnica avanzada.
- **Astra = ChatGPT Codex**: en esta conversación se ha encargado de arte, íconos, modelos 3D, texturas, renders, documentación y paquetes descargables.
- **Claude / Claude Code**: ha trabajado en el juego dentro de Roblox Studio y es quien normalmente integra los assets y programa los movimientos y efectos.
- El usuario decide qué prompt quiere ejecutar. Seguir su pedido más reciente; un catálogo de prompts no es una orden de producirlos todos.
- Avanzar con autonomía dentro de la tarea pedida, sin pedir confirmación para cada paso rutinario. Explicar de forma breve qué se está haciendo y qué falta.
- En los pedidos de arte de este chat, **las modificaciones del repositorio se limitan a `codex_assets/`**. No modificar scripts del juego, pruebas ni `Place1.rbxl` para integrar assets sin un nuevo encargo explícito.
- El usuario autorizó subir las entregas a su GitHub y dijo: «sí tú súbelo, no pasa nada, este GitHub es especial a ti». Las entregas se publicaron en ramas de trabajo. Conservar esta autorización para publicaciones normales de estas entregas, respetando cambios locales y el alcance pedido.
- El usuario quiere **descargar únicamente la entrega modificada**, no todo el repositorio cada vez. Preparar un ZIP independiente por entrega y dar el enlace directo en GitHub.

## 2. Repositorio y dónde está el trabajo

Repositorio: **https://github.com/milyssssalonhosting-lang/AstraRoblox**

| Rama | Contenido / último commit comprobado antes de crear este documento |
|---|---|
| `main` | Juego original y respaldos; `75ea7da2759764eb7041b66e600f240769490cc6`. |
| `codex/cohetes-2026-10-21` | Prompt 1: conceptos de cinco cohetes; `fd3df769b26cc70e9c70673f086ee958fb1be52e`. |
| `codex/hud-2026-10-21` | Añade el Prompt 8: íconos del HUD; `ff968fa8a52ba974a16eb3d4d3482b826084e85f`. |
| `codex/cohetes-3d-2026-10-21` | Añade el Prompt 14: FBX reales; `cba48561f7dc2fa9c55608617f95f15805017edc`. |
| `codex/continuidad-2026-10-22` | Este documento, creado sobre la rama de cohetes 3D; reúne también las entregas anteriores. |

Las ramas se crearon sucesivamente sobre la anterior. La rama de continuidad contiene los conceptos, el HUD y los modelos 3D. **No asumir que esos avances están en `main`: no se hizo merge en este chat.** Antes de trabajar en PC, comprobar la rama abierta y el estado de Git.

Para una copia nueva, si se usa Git por terminal:

```sh
git clone https://github.com/milyssssalonhosting-lang/AstraRoblox.git
cd AstraRoblox
git switch codex/continuidad-2026-10-22
git status --short
```

Si ya existe una copia local, abrirla e inspeccionarla primero. Preservar cambios del usuario antes de cambiar de rama. No hacer resets ni sobrescribir archivos para igualar este registro.

### Archivos que hay que leer al continuar

1. Este documento.
2. `codex_assets/PROMPTS_CODEX.md`: catálogo actualizado hasta el Prompt 14, incluido el contexto del Prompt 0.
3. `NOTAS.md` de la raíz: historia y decisiones del juego en Studio.
4. `CLAUDE.md` de la raíz y `codex_assets/README.md`: organización y convenciones.
5. El `NOTAS.md` de la entrega concreta que se vaya a modificar.
6. `investigacion/GUIA_ROBLOX.md` al tratar diseño, monetización o referencias.

**Advertencia de contexto antiguo:** `CLAUDE.md` aún dice que no hay idea de juego definida. Eso quedó desactualizado: el juego ya es **Slime al Espacio**. `NOTAS.md` también es cronológico: frases antiguas como «no hay guardado», «3 mascotas equipadas» o «7 mascotas» fueron superadas por entradas posteriores. Leer el estado más reciente y comprobar el código/Studio actual.

## 3. Qué es el juego

**Slime al Espacio** es un simulador de Roblox orientado a niños de aproximadamente **8–14 años**. Debe sentirse alegre, colorido, fácil de entender y con mejoras visualmente gratificantes.

Hay una **isla lobby** con estaciones y un **Mundo Cohete**. Está planeado un segundo mundo de tablero caótico con dados, pero el foco actual es el juego de cohetes.

### Mundo Cohete

- Rondas automáticas: **10 s de preparación → 45 s de vuelo → 8 s de resultados**.
- Cada jugador tiene un cohete con un slime o abeja como piloto.
- Las mascotas equipadas vuelan en órbita alrededor del cohete y dan bonos.
- Se sube pulsando clic, Espacio o un botón grande TAP en móvil; también existe Auto-clic.
- Según `GameConfig` actual: sin clics, potencia 0.25; a 7 clics/s llega a 1.30; Auto-clic da 1.00. Hay un límite de 20 clics/s considerados por el servidor. Auto-clic es gratis en pruebas; su venta se dejó para la fase de Robux.
- El servidor calcula altura, pagos, recogidas y trolleos. El cliente dibuja cohetes, cámara, interfaz y efectos.
- Más altura da más dinero, XP, XP de pase y récord. Hay dinero y XP en vivo durante el ascenso, además del premio final.
- Ranking en vivo, cuenta regresiva, barra hacia la siguiente capa, banner de capa alcanzada, récord personal y resultados.
- Los bots completan una carrera de al menos cuatro corredores cuando faltan jugadores; no trollean.

| Capa | Altitud de juego |
|---|---:|
| Cielo | 0 m |
| Nubes | 150 m |
| Arcoíris | 600 m |
| Espacio | 1.500 m |
| Luna | 3.500 m |
| Marte | 7.000 m |
| Galaxia | 15.000 m |

Algunas rondas pueden empezar a mayor altura: piso, nubes, arcoíris, espacio o luna. **El código de estas variantes existe, pero la última nota de Studio dice que faltó observar una ronda que no empezara desde el piso.**

**Dos escalas distintas:** la conversión física de los modelos 3D es 2.8 m ≈ 10 studs. En cambio, `GameConfig.Rocket.StudsPerMeter = 0.4` es una escala visual de la altitud del minijuego. No usar ese 0.4 para importar los FBX ni cambiarlo solo para ajustar una malla.

### Objetos recogibles y trolleos

- Monedas en el carril del cohete; las recogidas se deciden en el servidor.
- Gemas: Turbo, Combustible, Premio x2 y Galáctica.
- Turbo: aumento temporal de velocidad; Combustible: tiempo de vuelo extra; Galáctica: velocidad y ráfaga de monedas.
- Trolleos actuales con dinero del juego: Meteorito, Robar Turbo y Bomba Nuclear.
- Meteorito: precio 2.5K, pérdida de altura y pausa breve del rival.
- Robar Turbo: precio 5K, acelera al atacante y ralentiza al objetivo.
- Nuclear: precio 50K, reinicia la altura de los demás; una por ronda.
- El servidor elige objetivos y valida cobros. No confiar en datos enviados por clientes.

### Progresión y lobby

- Dinero, nivel/XP, mejoras de caminar, multiplicador, ingreso pasivo, motor y combustible.
- Rebirth: primer coste 1M, crecimiento ×4; reinicia dinero y mejoras, conserva mascotas y otros progresos, y añade +50% de dinero por rebirth.
- Recompensas diarias, misiones, pase de batalla de 30 niveles, ajustes, inventario, índice de mascotas y huevos.
- Mascotas: 17 sabores de slime y 17 tipos de abeja; se añadieron evoluciones de nivel 2/3 para ambas familias. Fusión de tres iguales hacia el siguiente nivel.
- Máximo actual de mascotas equipadas: **5**. `GameConfig.PetPower = 2`; tope `MaxPetRocket = 10`. Los recuentos antiguos del índice no describen necesariamente el catálogo final de evoluciones.
- Bonos de mascotas: dinero, velocidad del cohete, XP y caminar. «Equipar mejores» considera sus bonos.
- Lobby con tienda de huevos, Rebirth, zona AFK ×2, portal AFK Pro y portal Jugar.
- Los mundos separados y sus PlaceId seguían pendientes según el último estado del repositorio. El Mundo Cohete se usa localmente lejos del lobby, alrededor de z = 3000.
- La fase de Robux, VIP comercial, escudo, huevo exclusivo y UGC es posterior al pulido del juego y sus assets.
- El tablero con dados y UGC por mundo son planes futuros, no entregas terminadas.

## 4. Estado del juego y límites de lo que comprobó Astra

El desarrollo anterior en Studio está descrito en `NOTAS.md`: HUD, economía, recompensas, DataStore, inventario, fusión, huevos, lobby, vuelo, bots, trolleos, cámara, efectos y cohete Cartoon. Esas entradas incluyen pruebas realizadas en sesiones anteriores de Claude/Studio. **Astra no repitió esas pruebas dentro de Studio durante este chat.**

Detalles importantes del último estado documentado:

- `DataService` implementa guardado, autoguardado y bloqueo de sesión. Según las notas, el lugar aún usaba memoria temporal en Studio al no estar publicado/configurado para acceso a API. Confirmar su estado actual antes de diagnosticar persistencia.
- La última sesión de Studio perdió la conexión MCP y pudo quedar sin guardar. Revisar qué contiene el place antes de restaurar respaldos.
- Respaldos relevantes si faltan esos últimos cambios: GameConfig, PlayerStats, RocketService, InventoryController, RocketController y RocketClickController; remotes RocketClick/RocketToggleAutoClick; constructores BuildRocketUI, BuildFuseUI y BuildPetLevels.
- BuildSpaceDecor se ejecuta después de BuildRocketWorld si se necesita reconstruir ese escenario.
- El saldo enorme de las capturas proviene del modo de prueba: `DevStartMoney = 1e15`. No es evidencia de que la economía publicada funcione así.
- La desconexión y las capturas negras de Studio no prueban un fallo del juego; validar el estado real y Output.

### Estructura del proyecto

| Ruta | Qué contiene |
|---|---|
| `Place1.rbxl` | Place de Roblox. Se gestiona desde Studio; Astra no lo editó durante las entregas. |
| `scripts/` | Respaldos Luau, con su ruta de Studio normalmente anotada al principio. No hay sincronización Rojo configurada. |
| `scripts/GameConfig.luau` | Números del juego, mascotas, rarezas, mejoras y configuración. |
| `scripts/RocketService.server.luau` | Lógica del servidor del minijuego. |
| `scripts/RocketController.client.luau` y otros controladores | Visuales, cámara, clics, recogidas y trolleos. |
| `scripts/Build*.luau` | Constructores de UI, mapa, modelos y decoraciones para Studio. |
| `scripts/tools/transfer_server.py` | Servidor auxiliar local para transferir scripts/modelos entre ventanas de Studio. |
| `codex_assets/` | Trabajo entregado por Astra. |
| `investigacion/` | Guía y material de diseño/monetización. |

### Organización de Roblox

- Servidor: `ServerScriptService`; cliente: `StarterPlayerScripts` / `StarterGui`; compartido: `ReplicatedStorage`.
- Módulos comunes en `ReplicatedStorage/Shared`; HUD en `StarterGui/HUD`.
- `ReplicatedStorage/RocketModels` contiene las plantillas de cohetes.
- `ReplicatedStorage/PetModels`, `PickupModels`, `RocketState` y `Remotes` son relevantes para el vuelo.
- Nombres de instancias/variables en inglés; explicaciones y comentarios en español.
- Mantener validaciones de servidor para economía y RemoteEvents.

## 5. Dirección artística

Caricatura 3D tipo juguete: formas gorditas, redondeadas, colores saturados, plástico brillante y siluetas fáciles de reconocer. Mundo low-poly alegre con pasto vivo, nubes esponjosas, arcoíris, auroras, planetas y galaxias moradas/rosas. Evitar realismo oscuro, sangre y armas realistas.

- Tipografía de interfaz: **Fredoka One**, redonda/gruesa; texto blanco con contorno oscuro.
- Tinta/contorno: **#1C1628**.
- Botón verde: **#78FF50 → #1EBE28**.
- Rojo: **#FF5A64 → #C8192D**.
- Dorado: **#FFE150 → #F59614**.
- Azul: **#6EC8FF → #1E6EE6**.
- Morado: **#C878FF → #6E28C8**.
- Panel: **#9678FF → #4632B4**.
- Barra de ronda: **#6E50DC → #321E78**.

| Rareza | Gradiente de tarjeta |
|---|---|
| Común | #BEC8D2 → #788796 |
| Raro | #6EC8FF → #236EE6 |
| Épico | #D782FF → #822DD2 |
| Legendario | #FFE15A → #F08C14 |
| Mítico | #FF78BE → #7850FF |

Referencia principal del cohete: cápsula blanca, nariz y aletas azul rey, estrellas y luna amarillas, franjas celeste/amarilla y ventana redonda azul con aro plateado.

### Originalidad y assets externos

Todo el trabajo nuevo debe ser original, sin copiar juegos, logotipos o marcas. En sesiones anteriores se encontraron scripts maliciosos en modelos de Creator Store, incluidos falsos avisos para pegar código y cargas con `require(número)`. Eso motivó querer más assets propios. No ejecutar código de modelos descargados sin revisar ni introducir scripts ocultos en entregas.

## 6. Reglas de entrega acordadas

Estas reglas son especialmente importantes para **interfaz y efectos**:

1. PNG con **transparencia real, canal alfa**. No fondo blanco ni cuadritos pintados para simular transparencia.
2. **Sin texto dibujado en las piezas**. El juego coloca textos editables/localizables con Fredoka One. Los mockups sí pueden llevar texto.
3. Máximo **1024 × 1024 por pieza**; íconos normalmente 256 × 256 o 512 × 512.
4. Marcos y fondos de botones en **9-slice**, con márgenes y `SliceCenter` en píxeles documentados.
5. Lo que se anima debe venir en **capas PNG separadas**, centradas en el mismo lienzo: base, brillo, rayos, emblema, etc.
6. Describir qué gira/pulsa/brilla, duración, repetición y momento de activación. Claude lo programa dentro del juego.
7. Partículas animadas: flipbooks **1024 × 1024**, cuadrícula 4×4 u 8×8, orden izquierda a derecha y arriba abajo, fondo transparente.
8. Mockup del conjunto a **1920 × 1080 sobre una captura real del juego**. Esta imagen de revisión tiene una medida distinta a las piezas importables.
9. Guardar cada entrega en `codex_assets/<AAAA-MM-DD>_<pedido>/`, con `NOTAS.md` y un ZIP que solo contenga esa entrega.
10. Verificar archivos reales, dimensiones y alfa. Para 3D, exportar mallas reales y reabrirlas: no entregar solo imágenes o solo un generador sin ejecutar.

Los atlas opacos de color de una malla 3D son distintos de una pieza de interfaz transparente. Los renders y láminas de revisión tampoco deben confundirse con assets ya integrados en el juego.

## 7. Lo que Astra entregó en este chat

### A. Prompt 0 + Prompt 1 — Conceptos de los cinco cohetes

Carpeta: **`codex_assets/2026-10-21_linea-cohetes/`**.

| Rareza | Nombre y diseño |
|---|---|
| Común | **Cohete Burbuja**: blanco/azul, estrellas y luna amarillas, franjas celeste/amarilla. |
| Raro | **Cohete Turbo**: blanco/menta, franjas de velocidad y aletas más barridas. |
| Épico | **Cohete Relámpago**: morado/amarillo, rayos y doble propulsor. |
| Legendario | **Cohete Fénix**: dorado/naranja, aletas de plumas y fuego azul propuesto. |
| Mítico | **Cohete Galáctico**: galaxia violeta/rosa/cian, anillo flotante y fuego/estela arcoíris propuestos. |

Archivos: `lineup_cohetes.png`, cinco `turnaround_<rareza>.png`, `NOTAS.md`, `vista_previa_cohetes.jpg` y `entrega_cohetes.zip`.

- Lineup: 1774 × 887.
- Hojas: frente, lado, atrás y 3/4; exportadas a 2048 × 2048 mediante reescalado desde 1254 × 1254. No afirmar que son detalle nativo 2048.
- Son **arte conceptual** y vistas orientativas, no planos ortográficos calibrados.
- Llevan nombres y fondo porque el Prompt 1 era una lámina de concepto, anterior a las reglas posteriores para piezas de UI.
- Paletas y efectos están en su `NOTAS.md`.

[Descargar conceptos ZIP](https://github.com/milyssssalonhosting-lang/AstraRoblox/blob/codex/cohetes-2026-10-21/codex_assets/2026-10-21_linea-cohetes/entrega_cohetes.zip?raw=true)

[Ver lámina de conceptos](https://github.com/milyssssalonhosting-lang/AstraRoblox/blob/codex/cohetes-2026-10-21/codex_assets/2026-10-21_linea-cohetes/vista_previa_cohetes.jpg)

### B. Prompt 8 — 24 íconos del HUD

Carpeta: **`codex_assets/2026-10-21_iconos-hud/`**.

**24 PNG RGBA de 512 × 512**, sin palabras ni números, normalizados a aproximadamente el 85% del lienzo y con bordes transparentes comprobados.

- Menú: `settings`, `daily_rewards`, `missions`, `shop`, `pass`, `rebirth`, `index`, `inventory`, `codes`.
- Estadísticas: `money`, `gem`, `xp`, `trophy`, `turbo`, `fuel`, `rocket`, `paw`, `friends`.
- Trolleos: `meteor`, `magnet`, `nuclear`.
- Controles: `auto`, `tap`, `close`.
- Todos se nombran `icon_<nombre>.png`.
- Dinero usa una moneda verde con slime, sin letra ni símbolo $ pintado.
- Nuclear es una bomba de juguete simpática, sin símbolo de radiación real.
- Cerrar es un pictograma de dos barras cruzadas, no texto de interfaz horneado.

Capas extra independientes, también 512 × 512 y centradas:

| Archivo | Animación propuesta |
|---|---|
| `fx_glow_cyan.png` | Pulso de escala/transparencia, ciclo 1.6 s; Turbo/Auto activos. |
| `fx_glow_gold.png` | Pulso de 1.8 s; premio o misión listos. |
| `fx_sparkle.png` | Destello de 0.55 s, una vez al hover/recompensa/confirmación. |
| `fx_rays.png` | Giro de 360° en 12 s, para Rebirth disponible/premio. |

Incluye `hud_assets.json`, `VALIDACION.json`, `NOTAS.md`, `lamina_iconos.png`, `vista_previa_hud.jpg` y `entrega_iconos_hud.zip`. Los íconos usan `ScaleType.Fit`; 9-slice no aplica a estos pictogramas porque no se crearon marcos/fondos de botones en ese pedido.

**Pendiente concreto:** `mockup_hud_1920x1080.png` sobre una captura real. Se solicitó volver a adjuntar una captura porque las anteriores no estaban disponibles como archivos. La lámina de íconos no sustituye ese mockup. **No se confirmó importación ni sustitución de emojis dentro de Studio.**

[Descargar solo HUD ZIP — aproximadamente 8.5 MB](https://github.com/milyssssalonhosting-lang/AstraRoblox/blob/codex/hud-2026-10-21/codex_assets/2026-10-21_iconos-hud/entrega_iconos_hud.zip?raw=true)

[Ver los 24 íconos juntos](https://github.com/milyssssalonhosting-lang/AstraRoblox/blob/codex/hud-2026-10-21/codex_assets/2026-10-21_iconos-hud/vista_previa_hud.jpg)

### C. Prompt 14 — Cinco cohetes 3D reales

**Último pedido de producción completado antes de este documento.**

Carpeta: **`codex_assets/2026-10-21_cohetes-3d/`**.

Por rareza: `rocket_<rareza>.fbx`, `rocket_<rareza>.blend`, `rocket_<rareza>_atlas.png` y `preview_<rareza>.png`.

Además: `build_rockets.py`, `NOTAS.md`, `INTEGRACION.json`, `VALIDACION.json`, cinco `verification_<rareza>.json`, `vista_previa_cohetes_3d.jpg` y `entrega_cohetes_3d.zip`.

**Son mallas de verdad.** Se construyeron en Blender, se exportaron a FBX binario 7.4 y se reabrieron para validar. Los renders 3/4 proceden de los FBX reimportados. Las fuentes `.blend` incluyen el atlas empaquetado.

| Cohete | Triángulos verificados | Tamaño X × Y × Z en metros | Piezas |
|---|---:|---|---|
| Burbuja / común | 3.782 | 2.030 × 2.800 × 1.5631 | Body, Fins, Window, Nozzle |
| Turbo / raro | 3.710 | 2.1395 × 2.800 × 1.5631 | Body, Fins, Window, Nozzle |
| Relámpago / épico | 4.222 | 2.030 × 2.800 × 1.5631 | Body, Fins, Window, Nozzle, con dos toberas |
| Fénix / legendario | 4.398 | 2.300 × 2.800 × 1.5631 | Las cuatro anteriores + WingLeft y WingRight |
| Galáctico / mítico | 4.806 | 2.1830 × 2.800 × 2.260 | Las cuatro básicas + Ring |

Contrato de geometría:

- Menos de 6.000 triángulos por cohete.
- Alto 2.8 m; punta +Y; ventana/frente -Z; raíz en (0,0,0), centro de la caja envolvente.
- Un atlas PNG 1024 × 1024 por cohete, con UVs. Dibujos de estrellas, luna, rayos, alas y galaxia pintados en el atlas.
- `Body`: cápsula + nariz + aro/remaches plateados. `Window`: cristal azul independiente.
- Cuatro aletas; en Fénix las laterales son las alas separadas.
- Pivote de `WingLeft`: **(-0.460, -0.540, 0) m**; `WingRight`: **(+0.460, -0.540, 0) m**.
- `Ring`: origen **(0,0,0)**. Geometría inclinada 15° y centrada a Y = -0.540 m; deja libre la ventana.
- Separación comprobada del anillo: mínimo 0.4296 m al casco y 0.1478 m por debajo de la ventana, en reposo.
- Sin keyframes, esqueletos, scripts ocultos ni efectos de fuego añadidos a los modelos.

Posiciones para integrar, en metros respecto a la raíz:

- Centro de ventana: **(0, +0.200, -0.617)**; superficie frontal llega a Z = -0.697.
- Posición inicial recomendada del piloto: **(0, +0.200, -0.870)**, a ajustar a su tamaño.
- Salida de una tobera: **(0, -1.400, 0)**.
- Épico: salidas **(-0.205, -1.400, 0)** y **(+0.205, -1.400, 0)**.
- Attachment de cada fuego: 0.01 m por debajo de su salida; dirección **(0,-1,0)**.
- Extremos de estela normal: **(-0.240,-1.380,0)** y **(+0.240,-1.380,0)**. En Épico, X = ±0.340.

Movimientos propuestos para programar, con ejes en el marco Y-up del cohete:

- Idle general: ±2° sobre Z y ±0.025 m sobre Y, seno con periodo 2.6 s, solo offset visual.
- Alas del Fénix: giro sobre Y, signos opuestos, ±15°, ciclo completo 0.6 s durante vuelo.
- Anillo del Galáctico: giro sobre Y, una vuelta cada 3 s mientras sea visible.
- Fuego Fénix azul/cian; fuego Mítico arcoíris. Los HEX y demás colores están en `NOTAS.md` e `INTEGRACION.json`.

**Pendiente de integración:** no se importaron ni probaron en Roblox Studio. El juego actual espera un Part `Root`, `PrimaryPart`, `Exhaust`, `Pilot` y estela. El Empty raíz del FBX no crea ese Part automáticamente: Claude debe añadirlo y configurar Attachments/soldaduras/animación. Restaurar pivotes documentados si el importador los recentra. El Épico necesita dos emisores/Attachments de fuego.

Conversión de medidas del modelo a studs: dividir metros entre **0.28**. No confundirla con la escala de altitud visual del minijuego.

[Descargar solo cohetes 3D ZIP — aproximadamente 7.4 MB](https://github.com/milyssssalonhosting-lang/AstraRoblox/blob/codex/cohetes-3d-2026-10-21/codex_assets/2026-10-21_cohetes-3d/entrega_cohetes_3d.zip?raw=true)

[Ver renders de las cinco mallas](https://github.com/milyssssalonhosting-lang/AstraRoblox/blob/codex/cohetes-3d-2026-10-21/codex_assets/2026-10-21_cohetes-3d/vista_previa_cohetes_3d.jpg)

[Leer notas completas de los modelos 3D](https://github.com/milyssssalonhosting-lang/AstraRoblox/blob/codex/cohetes-3d-2026-10-21/codex_assets/2026-10-21_cohetes-3d/NOTAS.md)

## 8. Catálogo de prompts y qué está pendiente

Consultar siempre el texto completo del prompt elegido en `codex_assets/PROMPTS_CODEX.md`. Este resumen no sustituye sus medidas y contratos.

| Prompt | Tema | Estado en este chat |
|---:|---|---|
| 0 | Contexto del juego y estilo | Aplicado en las entregas. |
| 1 | Línea conceptual de cinco cohetes | Entregado. |
| 2 | Cinco íconos de tienda de cohetes + cinco tarjetas de rareza | **Pendiente.** El ícono Burbuja del HUD no equivale a este set. |
| 3 | Constructor Luau de cinco cohetes con piezas | No ejecutado. No confundir con el constructor Python del Prompt 14. |
| 4 | Modelos de Blender/FBX | No se ejecutó literalmente el pedido antiguo; el Prompt 14 produjo las cinco mallas FBX con su contrato actualizado. |
| 5 | Tabla Luau de efectos/bonos/precios de skins | Pendiente. Los datos de fuego del Prompt 14 no equivalen a esta tabla completa. |
| 6 | Panel de tienda de cohetes | Pendiente. |
| 7 | Miniatura e ícono del juego | Pendiente; el usuario quería dejarlo para el final. |
| 8 | Íconos del HUD | Assets entregados; falta mockup con captura e integración en Studio. |
| 9 | Rebirth animado por capas, botón/estados y explosión | Pendiente. |
| 10 | Insignias pasivas, tres intensidades y aura separada | Pendiente. |
| 11 | Texturas de vuelo, fuego por rareza, humo, explosiones, partículas y estelas | Pendiente. |
| 12 | Banners de vuelo, récord, turbo, cuenta regresiva, resultados, ranking y barras | Pendiente. |
| 13 | Skyboxes caricatura de seis caras por cielo | Pendiente. |
| 14 | Cohetes FBX reales + piezas y pivotes de animación | Entregado y validado en Blender; importación en Studio pendiente. |

Orden general que había propuesto el usuario: 2 → 8 → 9 → 10 → 11 → 12 → 13 → cohetes 3D → 7. Después pidió específicamente primero el 8 y luego el 14; se respetaron esos pedidos. **No decir que el 2 u otros pendientes ya se hicieron ni retomar un pedido automáticamente por leer este historial.**

## 9. Referencias visuales y problemas de descarga

El usuario adjuntó originalmente once imágenes: nueve capturas del juego —vuelo/arcoíris, despegue, récord, aurora, galaxia, trolleos, isla, Rebirth y fusión— y dos referencias de cohetes.

En el checkout de este chat **no existía `codex_assets/referencias/`** ni copias en disco de esas capturas. No están incluidas en los ZIP de entregas. Las hojas conceptuales que generó Astra sí están guardadas en `2026-10-21_linea-cohetes/` y sirven de referencia para los nuevos modelos.

Si se necesita el mockup sobre una captura real, buscar primero si el usuario ya la añadió al proyecto local. Si no existe, pedir esa captura. No inventar que un escenario generado es una captura del juego.

El visor del chat mostró galerías negras y «Sin imagen». Los enlaces a `/workspace/...` también fallaron con «No se pudo descargar el artefacto». Se comprobó que los PNG y ZIP existían y eran válidos; el fallo era de visualización/exportación del visor. **No volver a ofrecer esos enlaces internos como si resolvieran la descarga.**

La solución adoptada fue publicar en GitHub y dar:

- Un enlace a la vista previa JPG en GitHub.
- Un enlace directo al ZIP de esa entrega con `?raw=true`.
- Si hace falta, la carpeta de esa entrega en GitHub.

El botón de GitHub **Code → Download ZIP** descarga la rama completa, por lo que no es lo que el usuario prefiere para cada actualización. Mantener los ZIP por entrega actualizados con los archivos finales.

## 10. Herramientas y entorno: qué se puede reutilizar y qué hay que comprobar

En el chat anterior se trabajó en un entorno Linux en la nube, con el repositorio en `/workspace/AstraRoblox`. Esa ruta y sus procesos **no son una carpeta del PC del usuario** ni se trasladan solos al nuevo chat.

Herramientas que estuvieron disponibles allí:

- Blender **4.3.2**, con NumPy **2.2.4** incluido.
- Python 3, ImageMagick y Git.
- Generación de imágenes para el arte 2D.
- Luau **0.701** preparado en una carpeta de herramientas fuera del repositorio; se compilaron los 46 respaldos `.luau` sin errores de sintaxis/compilación.
- El servidor `scripts/tools/transfer_server.py` se inició y se comprobaron descarga de scripts, transferencia de prueba y respuesta 404. Solo escucha en `127.0.0.1:34999`; un servidor en la nube no conecta por sí solo con Studio en otro PC.

Esto **no acredita pruebas de gameplay** y no significa que esas herramientas, autenticación o servidores ya estén instalados/activos en el PC nuevo. El setup inicial del entorno dejó de ser el objetivo cuando el usuario aclaró que quería contexto y trabajo de assets. No reiniciar el onboarding como tarea pendiente.

### Conexión con Studio en el PC

`CLAUDE.md` describe un MCP `Roblox_Studio` que se usaba desde Claude Code en Windows, con Studio abierto y «Habilitar Studio como servidor MCP» activado. El arranque que documenta es `cmd.exe /c cd /d %LOCALAPPDATA%\Roblox && .\mcp.bat`.

Ese registro histórico **no confirma que Codex para PC tenga el mismo MCP configurado o conectado**. En el nuevo chat, descubrir las herramientas disponibles y comprobar una operación de lectura antes de afirmar que se puede editar Studio. No pedir tokens ni copiar credenciales dentro de este archivo.

### Reproducir los modelos 3D

Desde la carpeta de la entrega, con Blender disponible en PATH:

```sh
blender -b -t 2 --python-exit-code 1 --python build_rockets.py -- --output-dir ./salida
```

Solo una rareza:

```sh
blender -b -t 2 --python-exit-code 1 --python build_rockets.py -- --output-dir ./salida --only mitico
```

Verificar archivos existentes sin reconstruir ni renderizar:

```sh
blender -b -t 2 --python-exit-code 1 --python build_rockets.py -- --output-dir ./salida --verify-only --skip-render
```

En Windows puede ser necesario usar la ruta del ejecutable Blender. El script no necesita paquetes externos ni red. Los `.blend` usan Z-up nativo; la conversión al FBX Y-up está resuelta en el constructor. Cycles funciona en CPU; se desactivó el denoiser porque ese Blender no incluía OpenImageDenoise.

## 11. Cómo retomar sin perder el trabajo

1. Leer este documento y los archivos de contexto.
2. Localizar el proyecto, comprobar la rama y conservar cualquier cambio local del usuario.
3. Revisar las entregas y sus `NOTAS.md` antes de regenerar nada.
4. Identificar qué herramientas están realmente disponibles en el nuevo equipo; el archivo de contexto no transfiere conexiones ni sesiones.
5. Pedir al usuario la siguiente tarea concreta si solo entregó este contexto. No rehacer conceptos, HUD o FBX ya terminados.
6. Si pide integrar los nuevos cohetes, empezar por importar **un Burbuja**, revisar UV/atlas, orientación, 10 studs de alto, Root/Attachments y piloto; después seguir con las otras rarezas y sus piezas animables.
7. Si pide terminar el HUD, conseguir la captura para el mockup y luego coordinar la sustitución de emojis en Studio. No marcarlo integrado sin comprobarlo.
8. Si pide otro prompt, leer su texto actualizado y aplicar las reglas de alfa, capas, medidas y documentación.
9. Al terminar un cambio, verificar la entrega, actualizar sus notas/ZIP y subir la rama para dar enlaces descargables de GitHub.

## 12. Mensaje listo para pegar en el nuevo chat

> Astra, continúa mi proyecto de Roblox «Slime al Espacio». Lee completo el archivo `CONTINUAR_CON_ASTRA.md` que adjunto. Si tienes acceso al repositorio, revisa también `codex_assets/PROMPTS_CODEX.md`, `NOTAS.md` y los `NOTAS.md` de las entregas. La rama `codex/continuidad-2026-10-22` reúne el trabajo anterior. Conserva el estilo y las reglas de entrega. No rehagas los prompts 1, 8 y 14 ni asumas que ya se integraron en Studio. Primero confirma brevemente que comprendiste el estado y espera mi siguiente pedido.

---

Este archivo no contiene secretos ni configura por sí mismo el nuevo equipo. Es una memoria de continuidad basada en la conversación, el repositorio y las verificaciones efectuadas hasta esta entrega. Las decisiones nuevas del usuario y el estado real más reciente del proyecto tienen prioridad sobre este registro histórico.
