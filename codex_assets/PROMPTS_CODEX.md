# Prompts para ChatGPT Codex (Astra)

Cómo usar: pega primero el **Prompt 0 (contexto)** en una conversación nueva y luego el pedido
que quieras (1, 2, 3…). Si Codex trabaja con el repo/carpeta, dile que lea este archivo y mire
las imágenes de `codex_assets/referencias/`. Si no, adjunta esas imágenes a mano.
Todo lo que haga Codex va en `codex_assets/<fecha>_<pedido>/`.

---

## Sobre el juego: "Slime al Espacio" (Roblox)

**Qué es:** simulador para niños (8-14 años) de Roblox. Hay una isla lobby (zona de inicio, con
zona AFK, portal AFK Pro, huevos de mascotas y estaciones) y desde ahí se va al **Mundo Cohete**.
Un segundo juego (tablero caótico con dados) llegará después.

**Cómo se juega el Mundo Cohete:**
- Rondas automáticas: 10 s de cuenta regresiva → 45 s de vuelo → resultados.
- Cada jugador despega en su cohete con su **slime** (o abeja) de piloto, y sus mascotas
  equipadas vuelan en órbita alrededor del cohete.
- Para subir hay que **spamear clic / Espacio / botón TAP** (o activar el Auto-clic).
- El cielo cambia por capas: Cielo → Nubes (150 m) → Arcoíris (600 m) → Espacio (1,500 m)
  → Luna (3,500 m) → Marte (7,000 m) → Galaxia (15,000 m). Hay aurora boreal, planetas tipo
  Saturno, estrellas, nubes caricatura con borde negro.
- En el aire salen **monedas** y **gemas** (⚡ Turbo, ⛽ Combustible, 💰 Premio x2, 🌌 Galáctica).
- **Trolleos** contra rivales: ☄️ Meteorito, 🧲 Robar Turbo, ☢️ Bomba Nuclear.
- Más alto = más dinero. Ranking en vivo, récord personal, banners al pasar de capa.
- Algunas rondas empiezan más arriba (desde las nubes, el arcoíris, el espacio…).

**Progresión:** dinero, mejoras (motor, combustible…), Rebirth, nivel/XP, Pase de Batalla
(30 niveles), Recompensas diarias, Misiones, Index de mascotas, huevos (gacha con probabilidades
visibles). Mascotas: 17 slimes (sabores) y 17 abejas, 5 rarezas, 3 niveles cada una (se
fusionan 3 iguales → nivel siguiente). Cada mascota da bonos 💰 dinero, 🚀 velocidad del
cohete, ⭐ XP y 👟 caminar. **Próximo:** tienda de cohetes por rareza (con efectos distintos),
y luego compras con Robux (VIP, Auto-clic barato, huevo exclusivo).

### Cómo se ve (capturas reales del juego)

| | |
|---|---|
| ![Cohete actual en el arcoíris](referencias/01_cohete_actual_arcoiris.jpg) **Cohete actual** (malla caricatura blanco/azul) volando por el arcoíris, con su slime piloto y mascotas en órbita. | ![HUD durante el despegue](referencias/02_hud_despegue.jpg) **HUD**: menú izquierdo, barra de ronda arriba, ranking a la derecha, botones de trolleo. |
| ![Nubes, turbo y récord](referencias/03_nubes_turbo_record.jpg) Nubes, turbo con estrellas y banner "¡NUEVO RÉCORD!". | ![Aurora boreal](referencias/04_aurora_espacio.jpg) Aurora boreal entre el arcoíris y el espacio. |
| ![Galaxia](referencias/05_galaxia.jpg) Capa Galaxia (cielo morado con nebulosas). | ![Trolleos](referencias/06_trolleos.jpg) Trolleos y cohetes rivales (modelo viejo de piezas). |
| ![Mundo cohete, piso](referencias/07_mundo_cohete_piso_mascotas.jpg) Isla del Mundo Cohete: estilo low-poly con montañas nevadas y árboles otoñales. | ![Panel Rebirth](referencias/08_panel_rebirth.jpg) Estilo de paneles: degradado morado, borde oscuro grueso, botón verde. |
| ![Panel de fusión](referencias/09_panel_fusion.jpg) Mini-menú de fusión de mascotas. | ![Referencia cohete](referencias/ref_cohete_burbuja.webp) Referencia del cohete "Burbuja" (estilo a seguir). |

Otra referencia: `referencias/ref_cohete_arcoiris_gemas.webp` (cohete plateado, arcoíris y gemas).

### Paleta y estilo de la interfaz

- Letra: **Fredoka One** (redonda y gruesa), texto blanco con contorno oscuro.
- Contorno/tinta: `#1C1628` (bordes gruesos de 3-4 px en todo).
- Botones (degradado de arriba a abajo): verde `#78FF50→#1EBE28`, rojo `#FF5A64→#C8192D`,
  dorado `#FFE150→#F59614`, azul `#6EC8FF→#1E6EE6`, morado `#C878FF→#6E28C8`.
- Paneles: morado `#9678FF→#4632B4`; barra de ronda `#6E50DC→#321E78`.
- Rarezas (tarjetas): Común `#BEC8D2→#788796` · Raro `#6EC8FF→#236EE6` · Épico `#D782FF→#822DD2`
  · Legendario `#FFE15A→#F08C14` · Mítico `#FF78BE→#7850FF`.
- Mundo: cielo celeste, nubes blancas esponjosas, arcoíris saturado, espacio azul/morado con
  estrellas, galaxia morada/rosa. Islas low-poly con pasto verde brillante.

---

## Prompt 0 — Contexto (pegar siempre primero)

```
Eres el artista y diseñador técnico de "Slime al Espacio", un juego de Roblox para niños
(8-14 años). Lee codex_assets/PROMPTS_CODEX.md (sección "Sobre el juego") y mira TODAS las
imágenes de codex_assets/referencias/ antes de diseñar: tus assets deben verse como parte de
ese juego (mismos colores, mismo estilo de interfaz, misma letra Fredoka One, bordes oscuros
gruesos #1C1628).

Resumen: los jugadores despegan en cohetes con su mascota slime/abeja de piloto, spamean clic
para subir por capas del cielo (nubes → arcoíris → espacio → luna → marte → galaxia), recogen
monedas y gemas, trollean a rivales y compiten en rondas automáticas. Mascotas con rarezas
Común, Raro, Épico, Legendario y Mítico.

ESTILO OBLIGATORIO: caricatura 3D tipo juguete, muy colorido ("dopamina"), formas redondeadas
y gorditas, colores saturados, brillo tipo plástico. Referencia principal del cohete:
referencias/ref_cohete_burbuja.webp (blanco con nariz y aletas azul rey, estrellitas y luna
amarillas, franjas celeste/amarillo, ventana redonda azul con borde metálico). Nada realista
ni oscuro, nada de sangre ni armas.

REGLAS:
- Todo es original: no copies Pet Simulator, Fortnite, Adopt Me ni marcas/logos (tampoco el de Roblox).
- Guarda tus entregas en codex_assets/<AAAA-MM-DD>_<nombre-del-pedido>/, con un NOTAS.md corto:
  qué es cada archivo, para qué parte del juego y tamaño sugerido.
- NO modifiques nada fuera de codex_assets/ (los scripts del juego los integra Claude).
- Modelos/código para Roblox: sin scripts escondidos, sin require() a IDs, sin HttpService.
- Escribe los textos del juego en español.
```

---

## Prompt 1 — Línea de cohetes por rareza (arte conceptual)

```
Con las imágenes adjuntas como referencia de estilo, diseña una LÍNEA DE 5 COHETES para la
tienda del juego, uno por rareza. Todos deben verse de la misma familia (misma silueta base
gordita, ventana redonda, 3-4 aletas), pero cada rareza más espectacular que la anterior:

1. COMÚN – "Cohete Burbuja": blanco y azul (el de referencia). Simple y limpio.
2. RARO – "Cohete Turbo": verde menta y blanco, franjas de velocidad, aletas más afiladas.
3. ÉPICO – "Cohete Relámpago": morado y amarillo, rayos dibujados, doble propulsor, chispas.
4. LEGENDARIO – "Cohete Fénix": dorado y naranja, alas tipo plumas en las aletas,
   FUEGO AZUL en el propulsor, aura brillante.
5. MÍTICO – "Cohete Galáctico": cuerpo con textura de galaxia (morado/rosa/azul con estrellas),
   anillo flotante tipo Saturno alrededor, propulsor con fuego ARCOÍRIS y estela arcoíris.

Entrega:
- Una imagen "lineup" con los 5 en fila sobre fondo de cielo claro, cada uno con su nombre y
  rareza debajo (colores de rareza: Común gris, Raro azul, Épico morado, Legendario dorado,
  Mítico rosa-morado).
- Una hoja por cohete (turnaround): frente, lado, atrás y 3/4, fondo liso claro, cohete vertical
  con la punta hacia arriba. 2048x2048 PNG.
- En NOTAS.md: paleta de colores en HEX de cada cohete y descripción de sus efectos
  (color del fuego, estela, partículas, brillo).
```

---

## Prompt 2 — Íconos de tienda (PNG transparente)

```
Haz los ÍCONOS DE TIENDA de los 5 cohetes del pedido anterior (misma apariencia exacta).
- 512x512 PNG con FONDO TRANSPARENTE, cohete en vista 3/4, un poco inclinado como despegando,
  llamita pequeña abajo, contorno oscuro grueso (2-4 px) para que se lea en pantallas chicas.
- Versión extra de cada uno con marco de rareza (tarjeta redondeada con degradado del color de
  la rareza y brillo en la esquina) también 512x512.
- Nombres de archivo: icon_rocket_comun.png, icon_rocket_raro.png, icon_rocket_epico.png,
  icon_rocket_legendario.png, icon_rocket_mitico.png (y *_card.png los de marco).
```

---

## Prompt 3 — Cohetes 3D para Roblox (constructor Luau)

```
Escribe un script Luau "constructor" para Roblox Studio que cree los 5 cohetes del pedido 1
como modelos 3D hechos con piezas de Roblox (Part, WedgePart, CornerWedgePart, cilindros, esferas,
SpecialMesh de tipo Sphere/Cylinder), redondeados y caricaturescos. Archivo:
codex_assets/<fecha>_cohetes-3d/BuildRocketSkins.luau

CONTRATO OBLIGATORIO de cada modelo (el juego depende de esto):
- Model llamado "Rocket_Comun", "Rocket_Raro", "Rocket_Epico", "Rocket_Legendario", "Rocket_Mitico",
  guardado en ReplicatedStorage.RocketModels.
- PrimaryPart = "Root": Part 1x1x1, Transparency 1, CanCollide false, en el CENTRO del cohete.
- Alto total ≈ 10 studs (de y = -5 a y = +5 respecto a Root), ancho ≈ 4-5 studs con aletas.
- El FRENTE del cohete (ventana) mira hacia -Z de Root.
- Dentro de Root:
  * Attachment "Exhaust" en (0, -5, 0) con Orientation (0, 0, 180). Dentro: ParticleEmitter "Fire",
    ParticleEmitter "Smoke", PointLight "EngineLight" (todos Enabled = false; el juego los prende).
    Los colores del fuego/luz según la rareza (Legendario azul, Mítico arcoíris).
  * Attachments "TrailA" (-1.2, -4.5, 0) y "TrailB" (1.2, -4.5, 0) y un Trail "Trail" que los use
    (Enabled = false), color según rareza.
  * Attachment "Pilot" en (0, 0.6, -2.3) (donde se sienta el slime, frente a la ventana).
- Todas las piezas soldadas a Root con WeldConstraint, Anchored = false, CanCollide = false,
  Massless = true, CastShadow = false. Materiales SmoothPlastic/Neon/Glass (nada de texturas externas).
- Extras de rareza: Épico chispas (ParticleEmitter "Aura" Enabled=false), Legendario aura dorada,
  Mítico anillo neón flotante + estrellas.
- Menos de 60 piezas por cohete. Sin scripts dentro de los modelos.
- El constructor debe poder correrse varias veces (borra el modelo viejo antes de crearlo) y
  terminar con: return "ok: 5 cohetes".
Incluye en NOTAS.md una tabla con el conteo de piezas de cada uno.
```

---

## Prompt 4 — (Opcional, más calidad) Cohetes como malla FBX

```
Además del constructor Luau, crea un script de Blender (Python, Blender 4.x) que modele el
"Cohete Burbuja" (común) en low-poly estilizado y lo exporte a FBX listo para el importador 3D
de Roblox: menos de 4,000 triángulos, escala en metros con alto total 2.8 m (≈10 studs),
pivote en el centro, punta hacia +Y, frente (ventana) hacia -Z, materiales simples con colores
planos (sin texturas externas) o UNA textura atlas 1024x1024 PNG. Separa en objetos: Body,
Nose, Fins, Window, Nozzle. Entrega: build_rocket.py, rocket_comun.fbx (si puedes generarlo) y
rocket_comun_atlas.png. Repite con las otras rarezas cambiando colores y detalles.
```

---

## Prompt 5 — Efectos por rareza (tabla de configuración)

```
Diseña los EFECTOS VISUALES de cada cohete de la tienda como una tabla Luau lista para pegar
(sin código de juego, solo datos). Archivo: codex_assets/<fecha>_efectos/RocketSkinEffects.luau

return {
  Comun = { Rarity = "Común", FireColors = {...}, TrailColors = {...}, LightColor = ..., Aura = nil,
            LaunchBurst = "humo blanco", Bonus = { Speed = 0, Fuel = 0 }, Price = 0 },
  ...
}

Usa Color3.fromRGB. Bonos sugeridos (el juego los puede ajustar):
Común +0%, Raro +15% velocidad, Épico +35% velocidad y +2 s combustible,
Legendario +70% velocidad, +4 s combustible y fuego azul,
Mítico +120% velocidad, +6 s combustible, fuego y estela arcoíris.
Precios en dinero del juego: Raro 25K, Épico 250K, Legendario 2.5M, Mítico 25M.
Describe en NOTAS.md cómo se ve cada efecto (para que se note la diferencia al instante).
```

---

## Prompt 6 — Panel "Tienda de Cohetes" (diseño de interfaz)

```
Diseña el PANEL DE TIENDA DE COHETES para la interfaz del juego (mockup PNG 1920x1080 y
recortes). Estilo de los simuladores de Roblox: bordes gruesos oscuros, degradados saturados,
letra redonda gruesa, botones verdes de "Comprar", tarjetas por rareza con el ícono del cohete,
nombre, bonos (🚀 +35% velocidad, ⛽ +2 s) y precio con ícono de moneda. Botón "Equipar" para los
que ya tienes. Pestañas: "Cohetes" y "Estelas" (próximamente).
Entrega: shop_mockup.png y piezas sueltas en PNG transparente (marco del panel 9-slice, tarjeta
de cada rareza, botón Comprar, botón Equipar, ícono de moneda) con sus medidas en NOTAS.md.
```

---

## Prompt 7 — Miniatura e ícono del juego

```
Usando la segunda imagen adjunta (cohete plateado con arcoíris y gemas) como idea, crea:
- Ícono del juego 1024x1024 PNG: un slime sonriente piloteando el "Cohete Burbuja", arcoíris
  y gemas alrededor, texto grande "SLIME AL ESPACIO" redondo y grueso.
- Miniatura 1920x1080: varios cohetes de colores compitiendo hacia arriba, uno siendo golpeado
  por un meteorito cómico, monedas y gemas volando, fondo que pasa de cielo a galaxia.
Sin logos de Roblox ni de otras marcas.
```

---

## Reglas para TODO lo de interfaz y efectos (Prompts 8-13) — agregadas 2026-10-21 tras revisar el Prompt 1

```
REGLAS DE ENTREGA PARA ROBLOX (aplican a todos los pedidos de interfaz y efectos):
- PNG con FONDO TRANSPARENTE real (canal alfa), nada de fondo blanco ni cuadritos dibujados.
- SIN TEXTO dibujado en las piezas: los textos los pone el juego con Fredoka One (así se pueden
  cambiar y traducir). Si quieres mostrar el texto, hazlo solo en el mockup.
- Máximo 1024x1024 por imagen (Roblox reduce lo más grande). Íconos 256x256 o 512x512.
- Marcos y botones en formato 9-slice: indica en NOTAS.md los márgenes (SliceCenter) en px.
- Lo que se anima va en CAPAS SEPARADAS (fondo, brillo, rayos, ícono, contorno), cada una su PNG,
  centradas en el mismo lienzo para que encajen al superponerlas.
- Efectos de partículas animados: hoja de cuadros (flipbook) 1024x1024 en cuadrícula 4x4 u 8x8,
  cuadros en orden de izquierda a derecha y de arriba a abajo, fondo transparente.
- Por cada pieza animada, describe en NOTAS.md la animación: qué gira/pulsa/brilla, duración en
  segundos, si se repite y en qué momento del juego aparece (Claude la programa con TweenService).
- Entrega un mockup 1920x1080 del conjunto sobre una captura del juego para ver cómo queda.
```

## Prompt 8 — Set de íconos del HUD (reemplazar emojis)

```
Haz el SET DE ÍCONOS del HUD de "Slime al Espacio" en el mismo estilo de los cohetes (juguete 3D,
contorno #1C1628, brillo de plástico). 512x512 PNG transparente cada uno, el objeto ocupa ~85%.
Menú izquierdo: Settings (engrane), Daily Rewards (calendario con regalo), Missions (pergamino con
palomita), Shop (carrito con huevo), Pass (boleto dorado con estrella), Rebirth (flechas circulares
con brillo), Index (libro con huella de slime), Inventory (mochila), Codes (boleto/cupón).
Monedas y stats: dinero (billete/moneda verde $), gema, estrella de XP, trofeo/récord, rayo de turbo,
gota de combustible, cohete pequeño (velocidad), huella (mascotas), amigos (2 slimes juntos).
Trolleos: meteorito en llamas, imán robando un rayo, bomba nuclear caricatura (sin símbolos reales
de radiación peligrosos: hazla tierna). Botones: Auto (robot slime), TAP (dedo/cohete), cerrar (X).
Archivos: icon_<nombre>.png en minúsculas. Agrega una lámina con todos juntos para revisar.
```

## Prompt 9 — Panel de Rebirth animado

```
Rediseña el PANEL DE REBIRTH (ver referencias/08_panel_rebirth.jpg: hoy es un cuadro morado plano).
Quiero que se sienta épico y "dopamínico". Entrega en capas separadas:
- Marco del panel 9-slice (morado #9678FF→#4632B4, borde #1C1628 grueso, brillo arriba).
- Rayos de luz detrás del título que GIRAN lento (capa aparte, 1024x1024).
- Emblema central de Rebirth: anillo de flechas circulares dorado/morado con slime adentro,
  separado en: anillo exterior (gira), núcleo brillante (pulsa), chispas (parpadean).
- Barra de progreso: fondo, relleno verde con brillo diagonal que se desliza (capa aparte), tapa.
- Botón REBIRTH grande verde con estado normal, presionado y bloqueado (gris).
- Tarjetas "Pierdes" (roja) y "Conservas" (verde) como marcos pequeños.
- Flipbook 8x8 de la EXPLOSIÓN de rebirth (anillo de luz + estrellas que salen) para cuando el
  jugador confirma.
Describe la animación completa en NOTAS.md: al abrir, mientras espera, al confirmar.
```

## Prompt 10 — Insignias de pasivas (abajo a la derecha)

```
Diseña las INSIGNIAS DE BONOS PASIVOS que van abajo a la derecha del HUD (hoy son íconos sueltos
con "x1", "x1", "N/A"). Cada insignia: medallón redondo 256x256 transparente con ícono adentro y
espacio abajo para el número (lo pone el juego).
Tipos: Multiplicador de dinero, Rebirths, VIP (corona), Amigos, Mascotas, Zona AFK, Turbo activo,
Evento (estrella), Premio x2.
Cada tipo en 3 niveles de intensidad: normal (x1), activo (borde dorado y brillo) y máximo (aura
arcoíris). Capa extra de brillo/aura por separado para que el juego la haga pulsar.
Incluye mockup de la fila de insignias sobre referencias/02_hud_despegue.jpg.
```

## Prompt 11 — Partículas y efectos del vuelo (texturas)

```
Haz las TEXTURAS DE EFECTOS para ParticleEmitter y Beam de Roblox, PNG transparente, estilo
caricatura con contorno suave (no realista):
- Fuego del propulsor por rareza (amarillo, menta, amarillo/violeta, azul Fénix, arcoíris) como
  flipbook 4x4 1024x1024 cada uno (usa los HEX de 2026-10-21_linea-cohetes/NOTAS.md).
- Humo caricatura de despegue (bolitas blancas con contorno) flipbook 4x4.
- Explosión caricatura (meteorito y nuclear) flipbook 8x8.
- Sueltas 256x256: estrella 4 puntas, chispa, rayito amarillo, pluma dorada (Fénix), rombo dorado,
  anillo de onda expansiva, destello de moneda, estrella de rareza.
- Estelas (Beam/Trail) 512x128 que se puedan repetir horizontalmente: blanca, cian, violeta con
  pulsos, celeste, arcoíris.
En NOTAS.md: para qué cohete/efecto es cada una y colores sugeridos.
```

## Prompt 12 — Banners y avisos del vuelo

```
Diseña los BANNERS que aparecen durante el vuelo (piezas sin texto, en capas, transparentes):
- Banner de capa alcanzada, una variante por capa con su ícono: Nubes, Arcoíris, Espacio, Luna,
  Marte, Galaxia (cinta horizontal 1024x256 + ícono 256x256 aparte).
- "¡NUEVO RÉCORD!" (cinta dorada con trofeo y rayos detrás que giran).
- "¡TURBO!" (rayo azul con líneas de velocidad), "¡Ronda desde…!" y cuenta regresiva 3-2-1-¡YA!
  (círculos de número con contorno grueso, 512x512 cada uno).
- Tarjeta de RESULTADOS de la ronda: marco con podio 1-2-3, espacio para altura, dinero, XP y
  bono de mascotas.
- Panel de RANKING "Más alto" (derecha): marco 9-slice y medallas oro/plata/bronce 128x128.
- Barra de ronda (arriba) y barra de potencia del TAP: fondo, relleno y brillo deslizante.
Incluye en NOTAS.md la animación de entrada/salida de cada banner (rebote, escala, brillo).
```

## Prompt 13 — Cielos caricatura (skybox)

```
Crea SKYBOXES caricatura para cada capa del cielo, 6 caras 1024x1024 cada una (Bk, Dn, Ft, Lf, Rt, Up)
que empaten sin costuras: Cielo de día, Arcoíris, Espacio (azul con estrellas), Luna (gris-azul con
cráteres a lo lejos), Marte (rojo-naranja con polvo), Galaxia (morado/rosa con nebulosas). Estilo
pintado y saturado como las referencias 04 y 05, sin planetas reales con marcas. Nombra
sky_<capa>_<cara>.png y agrega una vista previa de cada cielo.
```
