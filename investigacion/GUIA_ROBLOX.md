# Guía Maestra y Manual de Especificación Técnica para el Desarrollo de Videojuegos en Roblox (2025–2026)
## Documento de Contexto y Memoria para Inteligencia Artificial Copiloto
**Versión:** 2.0 (Master Production Blueprint)  
**Propósito del Documento:** Servir como referencia de arquitectura técnica, flujo de trabajo por fases y manual de contexto operativo para IAs de desarrollo y desarrolladores humanos en la creación, monetización, optimización cross-platform y publicación de un videojuego en la plataforma Roblox.

---

## 1. Misión del Proyecto y Estructura por Fases

El desarrollo se ejecutará mediante un enfoque modular por fases para garantizar que el producto cumpla con los estándares de rendimiento, retención y cumplimiento regulatorio de Roblox antes de su monetización y promoción masiva.

```
+-----------------------------------------------------------------------------------+
|                         ROADMAP ESTRATÉGICO POR FASES                             |
+-----------------------------------------------------------------------------------+
| FASE 1: Concepto, Identidad Visual y UI/HUD Mobile-First (ForgeGUI / Gemini)      |
| FASE 2: Arquitectura Luau Server-Side y Lógica Cross-Platform (PC/Mobile/Console) |
| FASE 3: Sistema de Persistencia y Guardado Seguro de Datos (DataStore Architecture)|
| FASE 4: Monetización Ética, Pases de Juego, Developer Products y Compliance       |
| FASE 5: Integración de Audio IA (ElevenLabs & Gemini) y Assets 3D Low-Poly         |
| FASE 6: Pruebas Multi-dispositivo, Optimización, Soft Launch y Live-Ops           |
+-----------------------------------------------------------------------------------+
```

---

## FASE 1: Concepto, Identidad Visual y UI/HUD Mobile-First

### 1.1 Definición del Core Loop e Idea del Juego
1. **Core Loop Básico:** Acción Principal (ej. Recolectar / Combatir) -> Recompensa Inmediata (Monedas / Experiencia) -> Progresión / Mejora (Comprar ventaja / Subir nivel) -> Re-loop social.
2. **Enganche Inmediato (Primeros 30 segundos):** Otorgar gratificación instantánea en los primeros segundos de juego para reducir la tasa de abandono (*bounce rate*).

### 1.2 Flujo de Trabajo con ForgeGUI e IA Generativa Visual
* **ForgeGUI (Creación de Interfaces y Sprites Gratuita):**
  * Generación de hojas de sprites para botones, marcos de inventario, barras de vida/energía y ventanas modales.
  * Creación de texturas de interfaz con coherencia cromática y estilo estilizado/cartoon.
* **Diseño de Icono del Juego y Miniatura (Thumbnail):**
  * **Icono (512x512 px):** Focalizado en un personaje central o ítem icónico, utilizando colores de alto contraste y poca saturación de texto. Meta de CTR: > 2.5%.
  * **Miniatura (1920x1080 px):** Transmitir la narrativa del juego o la mecánica principal sin incurrir en publicidad engañosa (*clickbait* prohibido por las normas de la comunidad).

### 1.3 Arquitectura del HUD/UI Responsivo (Mobile-First)
El más del 60% del tráfico de Roblox proviene de dispositivos móviles. El HUD debe cumplir con los siguientes estándares de UI/UX:

```
+-----------------------------------------------------------------------------------+
|                        DISTRIBUCIÓN DEL HUD EN PANTALLA TÁCTIL                    |
+-----------------------------------------------------------------------------------+
| [Icono Perfil / Nivel]                              [Monedas / Robux / Tienda]   |
| (Esquina Sup. Izquierda)                            (Esquina Sup. Derecha)       |
|                                                                                   |
|                                                                                   |
|            ZONA LIBRE DE INTERACCIÓN Y VISIÓN DEL MUNDO 3D                        |
|                                                                                   |
|                                                                                   |
| [Joystick Virtual]                                  [Botones de Acción / Jump]    |
| (ZONA INFERIOR IZQUIERDA)                           (ZONA INFERIOR DERECHA)       |
+-----------------------------------------------------------------------------------+
```

* **Reglas de UI en Luau:**
  1. Usar escala relativa en `UDim2.new(ScaleX, OffsetX, ScaleY, OffsetY)` donde `Scale` varíe entre 0 y 1, evitando `Offset` absoluto para componentes principales.
  2. Implementar `UIAspectRatioConstraint` para mantener la relación de aspecto independiente de la resolución del dispositivo.
  3. Asegurar que las áreas táctiles de los botones tengan un tamaño mínimo de **44x44 px** para evitar toques erróneos.
  4. Mantener despejada la zona inferior izquierda reservada para el Joystick táctil predeterminado de Roblox.

---

## FASE 2: Arquitectura Luau Server-Authoritative y Lógica Cross-Platform

### 2.1 Modelo de Seguridad Server-Authoritative (Validación Absoluta)
Todas las acciones críticas (compra de ítems, daño, otorgamiento de ventajas, actualización de estadísticas) se procesan estrictamente en el Servidor (`Script`), usando `RemoteEvent` o `RemoteFunction` únicamente como canal de comunicación desde el Cliente (`LocalScript`).

```
[ LocalScript (Cliente) ] --( Dispara RemoteEvent )--> [ Script (Servidor) ]
                                                               |
                                                 1. Valida Cooldown / Coordenadas
                                                 2. Valida Inventario / Saldo
                                                 3. Ejecuta Lógica o Otorga Ítem
                                                               |
[ UI Cliente (Confirmación) ] <-- ( Responde Cliente ) ---------+
```

#### Código Luau de Referencia: Validación de Compra / Ventaja en Servidor
```lua
-- Guardar en ServerScriptService/GameManager.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local SolicitarVentajaEvent = Instance.new("RemoteEvent")
SolicitarVentajaEvent.Name = "SolicitarVentajaEvent"
SolicitarVentajaEvent.Parent = ReplicatedStorage

local COOLDOWN_TIEMPO = 2.0
local ultimasSolicitudes = {}

SolicitarVentajaEvent.OnServerEvent:Connect(function(player, tipoVentaja)
    local userId = player.UserId
    local now = os.clock()
    
    -- Validar Antihack / Rate Limiting
    if ultimasSolicitudes[userId] and (now - ultimasSolicitudes[userId]) < COOLDOWN_TIEMPO then
        warn("Solicitud rechazada por exceso de frecuencia (Spam): " .. player.Name)
        return
    end
    ultimasSolicitudes[userId] = now
    
    -- Validación de estado en el servidor
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then return end
    
    local oro = leaderstats:FindFirstChild("Oro")
    if oro and oro.Value >= 100 then
        oro.Value = oro.Value - 100
        -- Aplicar ventaja de forma segura en servidor
        local character = player.Character
        if character and character:FindFirstChild("Humanoid") then
            character.Humanoid.WalkSpeed = character.Humanoid.WalkSpeed + 4
        end
    end
end)
```

### 2.2 Validación y Adaptación Multi-Dispositivo (PC, Móvil, Consolas)
El sistema debe detectar dinámicamente el método de entrada activo mediante `UserInputService` y `ContextActionService`.

#### Código Luau: Mapeo Único Multi-Plataforma
```lua
-- Guardar en StarterPlayerScripts/InputManager.lua
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ACTION_USAR_VENTAJA = "UsarVentajaEspecial"

local function onUsarVentaja(actionName, inputState, inputObject)
    if inputState == Enum.UserInputState.Begin then
        local remote = ReplicatedStorage:WaitForChild("SolicitarVentajaEvent")
        remote:FireServer("Velocidad")
    end
    return Enum.ContextActionResult.Sink
end

-- Asignar botón de Teclado (PC), Botón de Mando (Xbox/PS) y Botón Pantalla (Móvil)
ContextActionService:BindAction(
    ACTION_USAR_VENTAJA,
    onUsarVentaja,
    true, -- Crear botón táctil automático para móviles
    Enum.KeyCode.E, -- Teclado PC
    Enum.KeyCode.ButtonX -- Mando Consola
)

-- Establecer posición y texto del botón en móvil
ContextActionService:SetTitle(ACTION_USAR_VENTAJA, "Habilidad")
ContextActionService:SetPosition(ACTION_USAR_VENTAJA, UDim2.new(0.75, -20, 0.5, -20))
```

---

## FASE 3: Sistema de Persistencia y Guardado Seguro de Datos (DataStore Architecture)

Para evitar la pérdida de datos o la corrupción por múltiples sesiones simultáneas (*race conditions*), se debe estructurar una persistencia basada en `DataStoreService` con manejo de errores (`pcall`), reintentos, autosave periódico y salvaguarda final con `BindToClose`.

### 3.1 Esquema Técnico de Persistencia de Datos
```lua
-- Guardar en ServerScriptService/DataStoreManager.lua
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local PlayerDataStore = DataStoreService:GetDataStore("PlayerData_v1.0")

local function getPlayerDataKey(userId)
    return "Player_" .. userId
end

local function CargarDatos(player)
    local key = getPlayerDataKey(player.UserId)
    local success, result = pcall(function()
        return PlayerDataStore:GetAsync(key)
    end)
    
    local datosDefecto = {
        Oro = 0,
        Nivel = 1,
        Inventario = {},
        GamePassesComprados = {}
    }
    
    if success and result then
        -- Fusionar datos guardados con estructura por defecto
        for k, v in pairs(result) do
            datosDefecto[k] = v
        end
    else
        warn("Error o datos inexistentes al cargar para " .. player.Name .. ". Usando datos por defecto.")
    end
    
    -- Crear Leaderstats
    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player
    
    local oro = Instance.new("IntValue")
    oro.Name = "Oro"
    oro.Value = datosDefecto.Oro
    oro.Parent = leaderstats
    
    local nivel = Instance.new("IntValue")
    nivel.Name = "Nivel"
    nivel.Value = datosDefecto.Nivel
    nivel.Parent = leaderstats
end

local function GuardarDatos(player)
    local key = getPlayerDataKey(player.UserId)
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then return end
    
    local datosGuardar = {
        Oro = leaderstats.Oro.Value,
        Nivel = leaderstats.Nivel.Value,
        Inventario = {}
    }
    
    local intentos = 0
    local exito = false
    while intentos < 3 and not exito do
        intentos = intentos + 1
        exito = pcall(function()
            PlayerDataStore:SetAsync(key, datosGuardar)
        end)
        if not exito then
            task.wait(2)
        end
    end
    if not exito then
        warn("CRÍTICO: No se pudieron guardar los datos de " .. player.Name)
    end
end

Players.PlayerAdded:Connect(CargarDatos)
Players.PlayerRemoving:Connect(GuardarDatos)

-- Salvaguarda en cierre de servidor (BindToClose)
game:BindToClose(function()
    if RunService:IsStudio() then task.wait(2) return end
    for _, player in ipairs(Players:GetPlayers()) do
        coroutine.wrap(GuardarDatos)(player)
    end
    task.wait(3)
end)
```

---

## FASE 4: Monetización Ética, Pases de Juego y Cumplimiento Normativo (2025–2026)

### 4.1 Categorización de Monetización
1. **Game Passes (Ventajas Permanentes):**
   * Multiplicadores de monedas (2x Gold), acceso a áreas exclusivas, mayor velocidad base.
   * Procesamiento en servidor mediante `MarketplaceService.PromptGamePassPurchaseFinished`.
2. **Developer Products (Consumibles / Ventajas Temporales):**
   * Moneda del juego instantánea, pociones de impulso temporal, resucitaciones inmediatas.
   * Deben procesarse de forma idempotente usando `MarketplaceService.ProcessReceipt`.
3. **Roblox Plus / Programas de Suscripción:**
   * Descuentos progresivos en ítems del juego cubiertos por la plataforma.
   * Bonos adicionales de Robux para el desarrollador por tiempo de juego de suscriptores.

### 4.2 Cumplimiento Obligatorio de Cumplimiento Normativo y PolicyService

#### PolicyService para Restricciones Regionales y Cajas de Botín
Cuando se ofrecen ítems aleatorios comprados con Robux o moneda virtual convertible, es legalmente obligatorio:
* Revelar los porcentajes exactos de probabilidad de cada recompensa antes de la compra.
* Desactivar mecánicas gacha o interacciones aleatorias pagadas para jugadores ubicados en jurisdicciones que lo prohíban según `PolicyService`.

```lua
-- Guardar en ServerScriptService/PolicyChecker.lua
local PolicyService = game:GetService("PolicyService")
local Players = game:GetService("Players")

local function VerificarPoliticasJugador(player)
    local success, result = pcall(function()
        return PolicyService:GetPolicyInfoForPlayerAsync(player)
    end)
    
    if success and result then
        if result.ArePaidRandomItemsRestricted then
            -- Ocultar o desactivar interfaz de cajas de botín / ruletas aleatorias pagadas
            print("Jugador " .. player.Name .. " tiene restringidos los ítems aleatorios pagados.")
        end
        if not result.IsPaidItemTradingAllowed then
            -- Desactivar sistema de intercambio comercial
            print("Jugador " .. player.Name .. " tiene desactivado el comercio entre usuarios.")
        end
    else
        warn("Error obteniendo políticas para " .. player.Name)
    end
end

Players.PlayerAdded:Connect(VerificarPoliticasJugador)
```

### 4.3 Clasificación de Edad y Etiquetas de Madurez (Creator Hub)
Antes de publicar, se debe completar la encuesta de **Maturity & Compliance** en el Creator Hub para asignar la categoría correcta (*Minimal*, *Mild*, *Moderate*, *Restricted*) y evitar suspensiones por contenido no clasificado o violaciones a los Estándares de la Comunidad.

---

## FASE 5: Flujo de Trabajo con Herramientas de IA y Assets 3D

### 5.1 Integración de Audio con IA
* **ElevenLabs (Efectos de Sonido y Foley):**
  * Generación de efectos de sonido procedurales (pasos, explosiones, clics de interfaz, magia).
  * Exportación en formato MP3 o OGG a 44.1 kHz, importación directa al Roblox Asset Manager.
* **Gemini (Música de Fondo / BGM):**
  * Creación de composiciones musicales ambientales adaptativas en bucle sin interrupciones (`Sound.Looped = true`).

### 5.2 Estándares de Modelado 3D Low-Poly
* **Presupuesto de Polígonos:** Mantener los modelos principales de accesorios y mapa por debajo de 1,000–2,500 tri-polígonos.
* **Texturizado:** Utilizar una única paleta de colores de textura (*Texture Palette Atlas*) para reducir las llamadas de dibujo (*Draw Calls*) y el consumo de memoria en dispositivos móviles.

---

## FASE 6: Pruebas Cross-Platform, Soft Launch y Live-Ops

### 6.1 Matriz de Pruebas de Rendimiento
1. **Emulación en Studio:** Probar resoluciones e interfaces bajo perfiles de iPhone SE, iPad y Consolas.
2. **Presupuesto de Memoria:** Monitorear con el Developer Console (`F9`) para mantener el uso de memoria por debajo de 1,200 MB en clientes móviles.
3. **Streaming Enabled:** Activar `Workspace.StreamingEnabled` para cargar dinámicamente las partes del mapa cercanas al jugador y evitar caídas de FPS.

### 6.2 Indicadores Clave de Rendimiento (KPIs) de Retención
* **Retención Día 1 (D1):** Meta > 35%.
* **Retención Día 7 (D7):** Meta > 10%.
* **Tiempo Promedio de Sesión:** Meta > 12–15 minutos.

---

## 7. Instrucciones para la Inteligencia Artificial Copiloto

Cualquier IA que lea este documento debe operar bajo las siguientes directivas:
1. **Respetar el Enfoque por Fases:** No pasar a la programación de monetización sin antes haber validado la arquitectura del HUD y el Server-Authoritative Pattern.
2. **Código Seguro:** Todo código escrito en Luau debe incluir manejo de errores (`pcall`), comprobaciones en el servidor y tipado estricto cuando sea posible.
3. **Compatibilidad Móvil Obligatoria:** Toda solución de UI debe utilizar `UDim2` con escala relativa y soportar entradas mediante `ContextActionService`.
4. **Cumplimiento Normativo:** Garantizar siempre la integración de `PolicyService` al diseñar mecánicas de venta o recompensas.

---

## 8. Revisión de Claude (2026-10-20) — LEER ANTES DE USAR ESTA GUÍA

Esta guía sirve como referencia técnica general, pero **no copiar su código tal cual**. Correcciones:

1. **DataStore (Fase 3) borra progreso**: si `GetAsync` falla, carga datos por defecto y al salir los guarda encima de los reales. Regla: si la carga falla, NO guardar nunca para ese jugador. Usar `UpdateAsync`, bloqueo de sesión (o ProfileStore), y evitar doble guardado entre `PlayerRemoving` y `BindToClose`.
2. **Inventario**: el guardado escribe `Inventario = {}` siempre → lo borra. Guardar desde una tabla de datos en el servidor, no desde leaderstats.
3. **Game Passes**: no guardarlos en DataStore; comprobar con `MarketplaceService:UserOwnsGamePassAsync` al entrar + `PromptGamePassPurchaseFinished`. Developer Products: `ProcessReceipt` idempotente (guardar PurchaseId).
4. **Ventaja de velocidad**: se pierde al reaparecer; reaplicar en `CharacterAdded`.
5. **"Roblox Plus"** no está verificado; lo real son las suscripciones de experiencia y Premium Payouts.
6. Metas numéricas (KPIs, CTR, 1,200 MB de memoria, polígonos) no tienen fuente; tomarlas como orientativas.
7. **Creator Store (recursos gratis)**: preferir partículas, sonidos, imágenes y mallas. Los modelos con scripts pueden traer backdoors: revisar cada script antes de usarlo. Los audios de otros creadores a veces vienen bloqueados (cargan con duración 0); probar `IsLoaded`/`TimeLength` antes de usarlos. Elegir solo recursos que combinen con el estilo colorido del juego.
7b. **⚠️ Cielos (skybox) de la Creator Store**: los 2 que probamos traían malware (ventana falsa pidiendo pegar código en la barra de comandos de Studio, y `require(número)` escondido dentro de la Atmósfera). Regla: NUNCA insertar modelos de cielo; crear un `Sky` propio y solo copiar los IDs de las 6 imágenes. Y jamás pegar en la barra de comandos código que pida un modelo.
   - Lo mismo con efectos/partículas (2026-10-21): 4 de 6 "No scripts" traían ScreenGui + scripts ocultos (Runtime/ScreenBuilder/LightConfig). Proceso: insertar → mover a `ServerStorage.Quarantine` → listar TODO (scripts, Values, GUIs) → copiar solo IDs de textura/propiedades a objetos nuevos → borrar la cuarentena. Los "Fire" clásicos no sirven (son el efecto viejo de Roblox).
8. **Efectos según gráficos**: los efectos decorativos (destellos, confeti, brillos) se apagan si `UserGameSettings.SavedQualityLevel` es bajo, o si el jugador los apaga en Settings. Las animaciones de respuesta (presionar un botón) siempre quedan.
9. **Fase 3 ya implementada** en `scripts/DataService.luau` (sigue las reglas del punto 1). Usar un DataStore aparte en Studio. Si el lugar no está publicado, `GetDataStore` falla y se usa memoria temporal. Para agregar un dato nuevo que se guarde: añadirlo a `defaults()` (y a `SAVED_NUMBERS` o `SAVED_TABLES`) en `PlayerStats.luau`.
10. **Gacha ya implementado** (`scripts/EggService.server.luau`): probabilidades visibles antes de abrir, sorteo solo en el servidor y PolicyService (`ArePaidRandomItemsRestricted`) aplicado aunque hoy se pague con dinero del juego, porque ese dinero se podrá comprar con Robux. Si se agrega un huevo con Robux, usar `ProcessReceipt` idempotente y la misma revisión de política.
11. **Estructura de mundos**: la isla es el lobby (zona de inicio). El juego principal y el Mundo AFK serán lugares aparte del mismo juego (universe) y se viaja con `TeleportService:TeleportAsync`. Los datos se comparten porque es el mismo DataStore; el bloqueo de sesión de `DataService` espera a que el lugar anterior suelte los datos. Los PlaceId van en `GameConfig.Worlds`.
12. Faltó en la guía (cubrir cuando toque): análisis de juegos exitosos, psicología del jugador, funciones de "trolleo" de pago, Battle Pass, paletas de color, algoritmo de descubrimiento.
