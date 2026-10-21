# Notas del juego

## Estado
- 2026-10-19: Proyecto creado. Place guardado como `Place1.rbxl`. MCP de Roblox Studio conectado a Claude Code. Aún sin idea de juego.
- 2026-10-19: Conectado ForgeGUI (ForgeMCP) como conector. Prueba de Battle Pass:
  - Imagen `assets/battle-pass-gui-panel.png` (hecha en ForgeGUI) subida vía ForgeMCP a Roblox, sin gastar créditos → `rbxassetid://98166333569848`.
  - `StarterGui/BattlePassGui`: botón "BATTLE PASS" a la izquierda abre el panel; X o clic afuera lo cierra. "Claim All" y "Upgrade Pass" son zonas invisibles sobre la imagen que por ahora solo muestran un aviso de prueba.
  - Script: `scripts/BattlePassController.client.luau`.
  - Limitación: niveles, XP y recompensas están dibujados en la imagen (no cambian). Para un pase real hay que separar las piezas (marco, íconos) y llenar los datos desde el servidor.

- 2026-10-20: FASE 1 — HUD funcionando (todavía sin guardado; DataStore = Fase 3):
  - `ReplicatedStorage/Shared/GameConfig`: todos los números (precios, mejoras, bono de amigos, formato de dinero). Respaldo: `scripts/GameConfig.luau`.
  - `ServerScriptService/PlayerStatsService`: dinero, XP, nivel, ganancia pasiva cada segundo, bono de amigos (+10% c/u, máx. +50%), compras de mejoras validadas en el servidor. En Studio empiezas con $1Qd para pruebas. Respaldo: `scripts/PlayerStatsService.server.luau`.
  - `StarterGui/HUD` + `HUDController`: menú izquierdo (Settings, Daily, Shop, Pass, Rebirth, Index), pestañas (My Base, Upgrades), dinero animado con "+$" flotantes, barra de nivel, insignias x1. En celular el dinero sube arriba y las insignias se mueven para no tapar joystick/salto. Respaldo: `scripts/HUDController.client.luau`.
  - Panel Upgrades funcional: Velocidad, Multiplicador $, Ingreso pasivo (8 niveles c/u).
  - Pass abre el Battle Pass (BindableEvent `Toggle`). Shop/Daily/Rebirth/Index/Settings/My Base muestran "Próximamente".
  - Botones Robux (+, +5/+10/+25 niveles) muestran aviso; se conectan en Fase 4.
  - Íconos = emojis temporales; cambiar por íconos de ForgeGUI después.
  - Las piezas visuales del HUD viven en el place: guardar con Ctrl+S.
- 2026-10-20: FASE 1 (parte 2) — recompensas, efectos y ajustes:
  - Daily Rewards de 7 días (día 7 = Dragón Arcoíris). En Studio el día dura 15 s para probar; si pasan 2 días sin reclamar, la racha vuelve al día 1.
  - Misiones (10): nivel, dinero ganado, mejoras compradas, tiempo jugado, diarias. Dan dinero, XP, XP de pase y mascotas.
  - Battle Pass recreado (sin imagen): 30 niveles, pista gratis y premium, premios "al azar" con semilla fija en `GameConfig.BattlePass`, Claim All, cuenta regresiva de temporada. En Studio, "UPGRADE PASS" activa Premium gratis para probar.
  - Settings: música, efectos de sonido, tamaño del HUD (70–130%), efectos visuales Auto/Sí/No. Auto = se apagan con gráficos bajos (nivel 1–4).
  - Animaciones: destello al pasar el mouse, destellos automáticos en botones clave, brillo en premios listos, confeti, rebote al presionar, contador que rueda.
  - Sonidos gratis de la Creator Store (IDs en `GameConfig.Sounds`); música "Toy Puppies C" (APM).
  - Mascotas: se guardan en el atributo `Pets` (todavía no se ven ni se equipan → Inventario/Index).
  - Archivos: `scripts/` (módulos del HUD: ClientSettings, Sfx, UIEffects, PanelManager, Toast; controladores Daily/Missions/BattlePass/Settings; servidor PlayerStats + RewardsService). `scripts/BuildPanels.luau` reconstruye los paneles.
  - Pendiente: guardar progreso (Fase 3); los ajustes tampoco se guardan aún.
- 2026-10-20: FASE 3 — guardado de datos:
  - `ServerScriptService/Modules/DataService`: DataStore `PlayerData_v1` (en Studio `PlayerData_v1_Studio`, para no mezclar pruebas con jugadores reales). UpdateAsync + bloqueo de sesión (90 s). Si la carga falla, el jugador sale con un mensaje y NUNCA se guarda. Autoguardado cada 60 s, al salir y al cerrar el servidor, sin guardar dos veces.
  - Se guarda: dinero, XP, nivel, rebirths, mejoras, contadores de misiones, misiones reclamadas, mascotas, diarias (racha y última vez), Battle Pass (XP, premium, reclamados; se reinicia con temporada nueva) y ajustes (volumen, tamaño del HUD, efectos), validados en el servidor.
  - Datos viejos: los campos nuevos se completan solos con valores por defecto.
  - El lugar NO está publicado → en Studio se usa memoria temporal (aviso en Output). Para guardar de verdad: publicar (privado) + activar "Enable Studio Access to API Services".
  - Probado: ciclo cargar → autoguardar → salir → recargar, datos viejos, temporada nueva, ajustes al servidor.
- 2026-10-20: Inventario e Index:
  - Inventario (botón 🎒 del menú): pestaña Mascotas con tarjetas por rareza (x cantidad, ✅ equipada), detalle con bono, Equipar/Guardar y "Equipar mejores". Ropa y Armas: próximamente.
  - Máximo 3 mascotas equipadas (`GameConfig.MaxEquippedPets`). Su bono se suma al dinero: ingreso = base × multiplicador × (1 + amigos + mascotas).
  - Index (📖): las 7 mascotas por rareza; las no descubiertas se ven como "???" con su rareza; barra "Descubiertas X/7". Recuerda todo lo que alguna vez tuviste (`IndexSeen`).
  - Las mascotas equipadas siguen flotando a cada jugador (`StarterPlayerScripts/PetFollow`, solo visual en cada cliente).
  - Rarezas y colores: `GameConfig.Rarities`. Se guarda `Equipped` e `IndexSeen` con el resto del progreso.
  - Nuevo botón "Codes" en el menú (próximamente).
  - Archivos: `scripts/InventoryService.server.luau`, `InventoryController`, `IndexController`, `PetFollow`, `BuildInventory.luau`.
- 2026-10-20: Huevos (gacha) con dinero del juego:
  - Shop (🛒) ahora es la tienda de huevos: Básico $500, Dorado $25K, Arcoíris $1M. Abrir x1 o x3. Cada tarjeta muestra las probabilidades ANTES de abrir.
  - Probabilidades por pesos en `GameConfig.Eggs` (Básico: Perro 45, Gato 40, Conejo 12, Zorro 3…). El sorteo es solo en el servidor (`EggService`); con 20,000 tiradas simuladas coinciden con lo que se muestra.
  - PolicyService: si en el país del jugador están restringidos los objetos aleatorios pagados, los huevos se bloquean (si no se puede leer la política, se bloquea y se reintenta).
  - Animación: el huevo tiembla, destello blanco, cartas con rareza, "¡NUEVO!" si es la primera vez, brillo en Legendario/Mítico, confeti. Con efectos apagados se salta la animación.
  - Nuevas misiones: abrir 5 y 50 huevos (estadística `EggsOpened`, se guarda).
  - Pendiente: huevos con Robux (Fase 4), íconos de huevos de ForgeGUI en lugar de emojis, huevos físicos en el mapa.

- 2026-10-20: Revisión de assets descargados (`C:\Users\Usuario\Downloads\assets gratis`, de builtbybit.com). Auditados en Studios aparte; NINGUNO trae backdoors.
  - Free Low Poly Assets: ⭐ base del mapa (arcoíris, montañas, casas de dulce, árboles, cofres, pilas de monedas/gemas, fuentes, portales de agua, letreros). Estilo perfecto con el HUD. 2 scripts inofensivos (flotar/girar).
  - Slime RPG: ⭐ mascotas. 16 sabores × 3 evoluciones (V1/V2/V3 con corona). 108–157 piezas c/u + script de salto → fusionar en una sola pieza y animar el salto completo para que no pese.
  - Bees (Loxxsy): ⭐ mascotas. 17 abejas de mallas (21–52 piezas), vienen gigantes (escala ×0.1). Script de alas limpio.
  - Customizable Cartoon: 10 gemas de colores (power-ups escondidos) + árboles/puente. Sin scripts.
  - Rocket: herramienta para volar, limpia; reescribir con física moderna y sin InvokeClient. Para pase "Volar" (Robux).
  - 200 Dance: 200 KeyframeSequences R15 sin subir. Muchas son bailes de Fortnite y cosas con derechos (Orange Justice, Floss, Thriller, Macarena…) → NO usar (riesgo DMCA). Usables: The Robot, Twist, Backflip, Worm, Sprinkler, Pogo, Wheel. Hay que publicarlas desde la cuenta del dueño del juego.
  - StudAssetPackEU: estilo bloque clásico, 3,152 piezas → no combina; no usar.
  - Creator Store: los "Pet Simulator X/99 packs" son copias de BIG Games → no usar.

- 2026-10-20: Mapa Low Poly + mascotas 3D (slimes y abejas):
  - Biblioteca: `ServerStorage/AssetLibrary` (LowPoly, Slimes, Bees, Cartoon, LowPolyLighting), traída de los archivos descargados SIN scripts.
  - Mapa (`Workspace/Map`, se rehace con `scripts/BuildMap.luau`): piso verde 560×560, plaza central con fuente, arcoíris al norte, fila de dulces, calle de 3 casas de dulce al oeste, puesto de mercado, 3 cofres, puente, 2 portales al este (reservados para AFK y AFK Pro), 24 montañas alrededor, 70 árboles, 90 flores, iluminación del paquete. Se quitaron el Baseplate y el árbol de bloques.
  - Mascotas: 68 modelos en `ReplicatedStorage/PetModels` (`scripts/PreparePets.luau`): 51 slimes (17 sabores × 3 niveles, fusionados en 1 pieza c/u) y 17 abejas (soldadas, sin Highlight). Las de emoji (perro, gato…) se eliminaron.
  - Slimes dan dinero (Común 5% … Mítico 60%; nivel 2 ×2.5, nivel 3 ×6). Fusionar 3 iguales → siguiente nivel (botón en Inventario). Abejas amarillas dan velocidad (+2…+10), las demás dinero. Máx. 5 equipadas, velocidad extra con tope de 40.
  - Huevos: Slime $500, Abeja $5K, Arcoíris $1M (solo Épico+ de ambas familias). Probabilidades por rareza, mostradas por mascota.
  - UI: tarjetas con modelo 3D (`HUD/Modules/PetViewport`, con precarga); Index de 68 con silueta negra para las no descubiertas. Las mascotas siguen al jugador (slimes saltan, abejas flotan; las de otros solo se dibujan a < 140 studs).
  - Premios de Diarias/Misiones/Pase cambiados a slimes y abejas. Nueva misión: fusionar un slime.
  - Pendiente: cohete para volar (Robux), gemas de power-up en el mapa, animaciones de baile (publicarlas), tercer animal, huevo exclusivo de Robux.

- 2026-10-20: La isla ahora es la ZONA DE INICIO (lobby). El juego principal será otro mundo (otro lugar del mismo juego) para no cargar todo aquí.
  - Plaza grande con estaciones: 🥚 tienda de huevos (oeste, puesto + 3 huevos gigantes, abre el Shop), 🔄 altar de Rebirth (noroeste), 💤 Zona AFK (este), 🌙 AFK Pro (sureste) y ⚔️ portal "Jugar" (sur). Casas, cofres y el otro portal quedaron guardados en `ServerStorage/StoredMapPieces`.
  - Zona AFK: círculo brillante; parado adentro ganas x2 (lo revisa el servidor), aviso "ZONA AFK x2" y el personaje baila con los bailes oficiales de Roblox.
  - AFK Pro y Jugar: al pararte encima pregunta "¿Ir a …?"; si dices que sí, pantalla de carga y viaje con TeleportService. Los mundos están en `GameConfig.Worlds` con PlaceId = 0 → por ahora responde "¡muy pronto!".
  - Rebirth: cuesta $1M (×4 cada vez), reinicia dinero y mejoras, da +50% de dinero por rebirth para siempre. Panel con barra de progreso y confirmación.
  - 2026-10-21: portal .glb importado por el usuario (Import 3D) → guardado en `ServerStorage/AssetLibrary/AFKProPortal` (con SurfaceAppearance PBR). En el lobby: `Map/Stations/AFKProPad/PortalMesh`, 18×1.8×18, apoyado en la plaza, con luz naranja y destellos. `AFKProPad` quedó como detector invisible (16 de diámetro). `BuildMap.luau` lo usa si existe.
  - Letreros flotantes: cada uno cuelga de un `SignAnchor` invisible sin girar (en los cilindros acostados el letrero se iba de lado). Alturas: huevos 9, AFK 15, AFK Pro 15, Rebirth 16, Jugar 24.
  - Archivos: `LobbyService.server.luau`, `LobbyController`, `RebirthController`, `Modules/Confirm`, `BuildLobbyUI.luau`, `BuildMap.luau`.
  - Pendiente para el Mundo AFK real: publicar el juego, crear el lugar, poner su PlaceId; ahí manejar la desconexión por inactividad de 20 min de Roblox.

- 2026-10-21: 🚀 Slime al Espacio — ETAPA 1 (núcleo) funcionando:
  - Mundo Cohete en `Workspace/RocketWorld` (z=3000; `scripts/BuildRocketWorld.luau`): isla, 12 plataformas de despegue, 2 torres, portal de regreso al lobby, cielo por capas a su altura real (40 nubes, arcoíris gigante, Luna, Marte, anillo de galaxia). Cohete de piezas en `ReplicatedStorage/RocketModels/Basic` con fuego, humo, luz y lugar para el slime piloto.
  - Portal "Jugar" del lobby → confirmación → pantalla de carga → Mundo Cohete (viaje local mientras no se publique; `GameConfig.Worlds.Main.LocalSpawn`).
  - Rondas automáticas (`RocketService`): Preparación 10 s → Vuelo 45 s → Resultados 8 s → otra vez. La altura la calcula el servidor: Motor (m/s) × (1 + 3% por punto de velocidad de mascotas), mientras dure el Combustible; arranque suave. Pago = altura × $5 × rebirth × (1 + amigos + mascotas). También XP, XP de pase y récord.
  - Capas (m): Cielo 0, Nubes 150, Arcoíris 600, Espacio 1500, Luna 3500, Marte 7000, Galaxia 15000 (`GameConfig.Rocket.Layers`).
  - Cliente (`RocketController`): cohetes de todos con su slime piloto, cámara que sigue y vibra al despegar, cielo de día → noche estrellada, iluminación en el espacio, líneas de velocidad, cuenta regresiva 3-2-1, banner al pasar de capa, barra de progreso hacia la siguiente capa, ranking en vivo, tarjeta de resultados.
  - Botón 🤖 Auto SÍ/NO: con NO terminas la ronda y quedas libre para caminar al portal 🏠.
  - Mejoras nuevas en Upgrades: Motor y Combustible (8 niveles). Misiones nuevas: llegar a Nubes, llegar al Espacio, 10 rondas.
  - Probado: ronda completa (4,412 m, Luna, +$35,296), modo Auto apagado, sin errores.
- 2026-10-21: 🚀 ETAPA 2 — monedas y gemas en el aire:
  - El servidor genera en cada ronda monedas (cada 35–80 m) y gemas (cada 300–650 m) en el carril de cada cohete, hasta un poco más de lo que puede alcanzar. Se recogen SOLAS al pasar (modo automático). Remotes: RocketPickups (lista) y RocketCollected (efecto).
  - Moneda: (25 + altura × 0.4) × rebirth, se paga al instante. Gemas (`GameConfig.Rocket.Pickups.Gems`): ⚡ Turbo (×1.6 por 5 s, 40%), ⛽ Combustible (+4 s, 35%), 💰 Premio x2 (20%), 🌌 Galáctica (×2 por 4 s + 10 monedas, 5%).
  - Modelos en `ReplicatedStorage/PickupModels` (moneda dorada + 4 gemas del paquete Cartoon con luz y destellos; `scripts/BuildPickups.luau`).
  - Cliente (`RocketPickupsController`): dibuja solo lo cercano (−40 a +260 m), objetos girando, destellos y "+$" flotante al recoger, aviso de gema, indicador "⚡ Turbo 3s / 💰 Premio x2" bajo la barra.
  - Cámara ajustada: el cohete va abajo para ver lo que viene arriba. Misión nueva: recoger 10 gemas.
- 2026-10-21: 🚀 ETAPA 3 — trolleos y cohetes bot:
  - Trolleos durante el vuelo (`GameConfig.Rocket.Trolls`), por ahora con dinero del juego (Robux en Fase 4): ☄️ Meteorito $2.5K (al de justo arriba: −25% altura y 2 s sin subir; espera 5 s), 🧲 Robar Turbo $5K (tú ×1.6 por 5 s, el de arriba ×0.5 por 4 s; espera 8 s), ☢️ Bomba Nuclear $50K (todos los demás a 0 m y 1.5 s sin subir; una por ronda). Quien recibe un trolleo queda protegido 3 s. El servidor elige objetivo y cobra solo si hay objetivo.
  - Cohetes bot 🤖 (Slimey, Burbuja, Gelatina…): llenan la carrera hasta 4 corredores, con velocidad parecida a la de los jugadores (×0.7–1.25) y slime piloto al azar. No trollean. Viven en `ReplicatedStorage/RocketState/Bots`.
  - `RocketService` reescrito con "corredores" (jugadores + bots). Remotes nuevos: RocketTroll (pedir), RocketTrollEvent (efectos).
  - Efectos (`RocketTrollController`): meteorito en llamas que cae y explota, rayo morado al robar turbo, destello blanco + explosiones + temblor con la nuclear; aviso "¡X te lanzó…!". Botones redondos a la derecha con precio y cuenta de espera.
  - Nubes fuera del pasillo de la cámara. Misión nueva: lanzar 5 trolleos.
  - Probado: meteorito, robar turbo y nuclear con bots, sin errores.
  - Siguiente: mejores modelos/efectos y sonidos de cohete, escudo (Robux), UGC, luego Fase 4 (Robux).
- 2026-10-21: 🚀 Pulido del vuelo:
  - Ganancia EN VIVO: $1 por metro subido (× rebirth), pagado cada segundo, y +2 XP por segundo subiendo (`LiveMoneyPerMeter`, `LiveXPPerSecond`). Además del premio final.
  - Cielos por capa (`ReplicatedStorage/SkyBoxes`): Espacio desde 1,500 m (Vía Láctea) y Galaxia desde 7,000 m, con tinte azul/morado. Al estar en esos cielos la hora vuelve a "día" (Roblox oscurece los cielos de noche).
  - ⚠️ Los dos modelos de cielo de la Creator Store traían scripts maliciosos (ventana falsa de "copia este código en la barra de comandos" y un `require(número)` escondido en la Atmósfera). Se borraron; solo se copiaron las imágenes a Sky limpios.
  - Efectos: estela blanca del cohete, líneas de velocidad estiradas, polvo de estrellas en el espacio, destello del color de la capa + anillo al subir de capa, 162 planetas/anillos/asteroides de colores que pasan a los lados (1,600–16,000 m).
  - Línea dorada "🏆 Tu récord" en el cielo; al superarla: banner ¡NUEVO RÉCORD!.
  - Sonidos: pitido de cuenta regresiva, despegue, motor en loop (más agudo con turbo), explosión en meteorito y nuclear.
  - Botones de trolleo más chicos (68 px) y más abajo: ya no tapan el ranking ni las insignias.
  - Probado hasta Marte (7,346 m), sin errores.
- 2026-10-21 🐾 Mascotas útiles en el cohete + vuelo más dopamínico (HECHO, probado en Play sin errores):
  - Cada mascota tiene bonos PROPIOS (tabla en `GameConfig.luau`, SLIMES/BEES): 💰 +% dinero (pasiva, monedas, dinero en vivo y premio final), 🚀 +% velocidad del cohete, ⭐ +% XP (XP en vivo, XP de ronda y XP del pase en el cohete), 👟 caminar (solo abejas rápidas). Slimes Nv.2 ×2.5 y Nv.3 ×6.
    - Ej.: Limón = XP; Lima = cohete; Durazno = un poco de todo; Arcoíris (mítico) = 30% de todo; Abeja Tornado = +60% cohete; Abeja Kawaii = +60% dinero +30% XP.
  - Atributos en el Player: PetBoost, PetRocket (tope +500%, `MaxPetRocket`), PetXP, PetSpeed. "Equipar mejores" usa `GameConfig.PetScore`.
  - Texto de bonos en tarjetas/Index/huevos: "💰+10% 🚀+5% ⭐+8% 👟+2" (`GameConfig.PetStatText`). Inventario muestra el total.
  - Dinero en el cohete ahora = rebirth × (1 + amigos + mascotas 💰) también para monedas y dinero en vivo.
  - Animaciones nuevas (RocketController): tus mascotas equipadas vuelan en órbita alrededor de tu cohete; velocímetro "🚀 75 m/s" (izq. del botón Auto); la cámara se abre (FOV) con la velocidad y más con turbo; "+$" y "⭐ +XP" flotantes saliendo del cohete; "🎉 500 m!" cada 500 m con onda dorada y sonido que sube de tono; turbo = giro del cohete, onda azul, "⚡ ¡TURBO!", fuego azul-morado, estela arcoíris, estrellas y más rayas de velocidad; cohete trolleado tambalea; al despegar sale nube de humo caricatura + llamarada en la plataforma.
  - Creator Store (pedido del usuario): se probaron 6 efectos. ⚠️ 4 traían malware escondido aunque decían "No scripts" (Star Effect, Star Particles, Ring of Fire: ventana falsa "WindowDriver/ScreenBuilder"; Cartoony Smoke: scripts disfrazados de librerías de Quenty). Se BORRARON; solo se copiaron IDs de texturas: estrella suave 6822501679, estrella 4 puntas 1084970835, humo caricatura 5253615811.
  - Aurora boreal limpia (Northern Lights de TheRisingTides, solo Beams) en `Workspace.RocketWorld.Aurora`, a ~1,100 m detrás de los cohetes; también está en `BuildRocketWorld.luau`.
  - Pendiente para después: ícono de mascotas en la tarjeta de resultados, Fase 4 (Robux).
- 2026-10-21 🚀 Cohete caricatura + nubes y Saturnos (HECHO, probado en Play hasta 9,782 m):
  - Cohete nuevo `ReplicatedStorage.RocketModels.Cartoon` (blanco con aletas azules): malla del modelo que descargó el usuario ("Rocket For High Quality Developer.rbxm"), sin sus scripts. Lo arma `scripts/BuildCartoonRocket.luau` sobre el Basic (mismos Exhaust/Trail/Pilot). La malla no tiene ventana: el slime piloto va montado al frente. Llama animada (flipbook) "FlameFX" teñida naranja. El cliente usa Cartoon si existe, si no Basic.
  - Nubes: las 40 nubes de bolitas → nubes caricatura con borde negro. Saturnos: 7 planetas con anillos neón de colores entre 2,000 y 14,000 m (`SkyLayers.Saturns`). Los pone `scripts/BuildSpaceDecor.luau` (correr DESPUÉS de BuildRocketWorld).
  - Recursos limpios guardados en `ServerStorage.AssetLibrary.Space`: CartoonRocketBody, RocketFlames, CartoonCloud, Saturn.
  - ⚠️ Creator Store otra vez (ver abajo): Tierra, Saturno, cohete rojo y nubes traían scripts falsos ("LightConfig" de Quenty, "LightAndPartHandler", ventana falsa "Runtime/ScreenBuilder"). Solo se guardó la geometría. La Tierra cartoon se ve blanca (textura no carga): descartada.

- 2026-10-21 🎯 Pedido del usuario antes de Robux (CASI TODO HECHO — ver estado abajo):
  1. Que se NOTE la diferencia de mascotas en el cohete: bonos más fuertes (GameConfig.PetPower), aviso "🐾 Tus mascotas: 🚀+X% 💰+Y% ⭐+Z%" al preparar y línea en resultados.
  2. Fusión: si tienes 3 iguales (slime O abeja) → botón Fusionar abre mini-menú en el Inventario (3 copias → resultado con sus bonos → Confirmar). Abejas ahora también tienen Nv.2/Nv.3 (Ids Bee_X_2, Bee_X_3; Bee_X sigue siendo Nv.1 para no romper datos guardados).
  3. Color de cohete por jugador (tinte de la malla con SpecialMesh.VertexColor; bots al azar). Después: skins desbloqueables.
  4. Rondas variadas: unas empiezan desde el piso, otras desde las nubes/arcoíris/espacio (atributo StartAltitude en RocketState, banner "¡Ronda desde …!").
  5. Volar = spamear Espacio / clic (PC) o botón grande "🚀 TAP" (celular). Sin clics el cohete sube lento. "Auto-clic" hace los clics por ti (en la Fase 4 tendrá costo barato; por ahora gratis para probar).
  6. Efectos extra donde falten. Robux (Fase 4) DESPUÉS de esto.
  - ESTADO (fin de sesión 2026-10-21):
    - ✅ 1 Mascotas más fuertes: GameConfig.PetPower = 2 (todos los bonos ×2), MaxPetRocket 10. Al preparar sale Toast "🐾 Tus mascotas: …"; en resultados Toast "🐾 ¡Tus mascotas te dieron +$X!" (atributo LastRocketPetBonus). Probado: de $3,625 → $2,416 fueron por mascotas.
    - ✅ 2 Fusión: abejas con Nv.2/Nv.3 (modelos 1.3x/1.6x, Nv.3 con brillos dorados; `BuildPetLevels.luau`). Mini-menú `InventoryPanel.FusePanel` (`BuildFuseUI.luau`): 3 copias → resultado con bonos, "✨ ¡Fusionar!" con animación y confeti. Si las fusionadas estaban equipadas, la nueva se equipa sola. Probado en Play.
    - ✅ 3 Color de cohete por jugador: tinte SpecialMesh.VertexColor según UserId (GameConfig.Rocket.Colors). Falta: elegir/desbloquear skins.
    - ⚠️ 4 Rondas variadas: código hecho (GameConfig.Rocket.StartVariants, RocketState.StartVariant/StartAltitude, banner "¡Ronda desde …!") pero NO se alcanzó a ver una ronda no-piso en Play (Studio se desconectó). Probar.
    - ✅ 5 Volar con clics: `RocketClickController` (LocalScript nuevo) + `TapPad` (botón "🚀 ¡TAP!", barra de potencia, "🤖 Auto-clic"). Servidor: remotes RocketClick / RocketToggleAutoClick, potencia = 25% sin clics → 130% a 7 clics/s; auto-clic = 100%. Probado: sin clics 0.25, 10 clics 0.40, auto 1.00.
    - ⏳ 6 Efectos extra: pendiente revisar con calma.
  - ⚠️ Studio se desconectó del MCP al final. Si al abrir faltan cambios (no se guardó), reinstalar desde `scripts/`: GameConfig, PlayerStats, RocketService, InventoryController, RocketController, RocketClickController (crear LocalScript en HUD.Controllers), remotes RocketClick/RocketToggleAutoClick (en ReplicatedStorage.Remotes), y correr BuildRocketUI, BuildFuseUI, BuildPetLevels (+ BuildCartoonRocket/BuildSpaceDecor si falta el cohete/nubes).
  - Las capturas de pantalla salían con el mundo 3D negro (fallo de captura de Studio, no del juego): revisar a ojo las miniaturas 3D del menú de fusión.

## Ideas
Funciones que el juego DEBE tener (2026-10-20), sin importar el tema:
- Multijugador con bono por amigos en el servidor (+% XP y dinero).
- Zona AFK: ganas x2 sin hacer nada (para que la gente se quede en el servidor).
- Ganancia pasiva cada segundo, visible en pantalla (números que suben, popups).
- Inventario: equipar mascotas / ropa / armas que dan bonos (más dinero, más velocidad).
- Gacha: cajas con dinero del juego o Robux (mostrar probabilidades + PolicyService).
- VIP (Robux): x2 dinero para siempre (AFK = x4), cajas más baratas, etc.
- Battle Pass barato, máximo nivel 30.
- Poderes de "trolleo" pagados contra otros jugadores (bomba al rival de enfrente, perder turno, cambiar posición, bomba nuclear cara).
- Competencia tipo carrera automática.
- Botón Auto-jugar (tu personaje sigue jugando mientras estás en menús). Distinto del AFK.
- Construir por fases según la guía, empezando por el HUD.
- También: Rebirth, Recompensas diarias (7 días), Settings, Index, Códigos, Invitar, Trade, botones "+5/+10/+25 niveles".
- Estilo visual: muy colorido ("dopamina"), degradados saturados, bordes gruesos oscuros, letra redonda gruesa, paneles con cuadros/arcoíris. Referencias: capturas de simuladores enviadas el 2026-10-20.
- HUD y sistemas reutilizables: la acción principal del juego se podrá cambiar después.
- Ropa UGC limitada gratis (1000–2000 copias) como premio de misión, para atraer jugadores. Fase posterior; revisar reglas y costos de Roblox.

## Decisiones
- 2026-10-21: Habrá DOS juegos (mundos) saliendo del lobby, con 2 UGC gratis en cada uno:
  1. 🚀 "Slime al Espacio" (primero, el más sencillo): rondas automáticas; tu slime despega en cohete, sube por capas (nubes → arcoíris → espacio → luna → planetas → galaxia); más alto = más dinero; barra de progreso por capa; trolleos que reinician/tumban al rival; todo en automático.
  2. 🎲 Tablero caótico (después): cada jugador tira dados solo, sin turnos compartidos.
  - Mientras no se publique, el Mundo Cohete vive lejos del lobby en el mismo archivo (z≈3000, carpeta Workspace.RocketWorld + RocketService), hecho como módulo para moverlo a su propio lugar después.
  - Orden: juego y modelado primero; detalles visuales (After Effects / HyperFrames para tráiler, ForgeGUI íconos, efectos) al final.
