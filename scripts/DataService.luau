-- ServerScriptService/Modules/DataService (ModuleScript)
-- Guarda y carga el progreso de cada jugador con DataStore, de forma segura:
--  * UpdateAsync (nunca SetAsync) para no pisar datos más nuevos.
--  * Bloqueo de sesión: si el jugador sigue "abierto" en otro servidor, esperamos.
--  * Si la carga FALLA, ese jugador NUNCA se guarda (así no se borra su progreso real).
--  * Autoguardado cada minuto, al salir y al cerrar el servidor (sin guardar dos veces).
--  * En Studio usa otro DataStore para no mezclar pruebas con jugadores reales. Si el
--    lugar no está publicado (o sin acceso a APIs), usa una memoria temporal de prueba.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local DataService = {}

local IS_STUDIO = RunService:IsStudio()
local STORE_NAME = if IS_STUDIO then "PlayerData_v1_Studio" else "PlayerData_v1"
local DATA_VERSION = 1
local LOCK_TIMEOUT = 90 -- segundos: un bloqueo más viejo se considera abandonado
local AUTOSAVE_INTERVAL = 60
local LOAD_ATTEMPTS = 6
local SAVE_ATTEMPTS = 3

---------------------------------------------------------------- Almacén
-- Memoria de prueba con la misma forma que un DataStore (solo dura esta sesión)
local function createMockStore()
	local memory = {}
	return {
		UpdateAsync = function(_, key, transform)
			local result = transform(memory[key])
			if result ~= nil then
				memory[key] = result
			end
			return memory[key]
		end,
	}
end

local store: any = nil
local usingMock = false

DataService.UsingMock = function()
	return usingMock
end

-- Errores que significan "Studio no tiene permiso", no "Roblox falló"
local function isStudioAccessError(message: string): boolean
	message = string.lower(message)
	return IS_STUDIO
		and (string.find(message, "publish") ~= nil or string.find(message, "api") ~= nil or string.find(message, "403") ~= nil)
end

local function switchToMock(reason: string)
	if not usingMock then
		usingMock = true
		store = createMockStore()
		warn("[DataService] Sin acceso a DataStore en Studio (" .. reason .. ").")
		warn("[DataService] Usando memoria temporal: el progreso NO se guardará entre pruebas.")
		warn("[DataService] Para guardar de verdad: publicar el lugar y activar 'Enable Studio Access to API Services'.")
	end
end

-- En un lugar sin publicar, GetDataStore falla de inmediato
local okStore, storeOrError = pcall(DataStoreService.GetDataStore, DataStoreService, STORE_NAME)
if okStore then
	store = storeOrError
elseif IS_STUDIO then
	switchToMock(tostring(storeOrError))
else
	error("[DataService] No se pudo abrir el DataStore: " .. tostring(storeOrError))
end

local function keyFor(player: Player): string
	return "Player_" .. player.UserId
end

---------------------------------------------------------------- Estado por jugador
-- loaded[player] = true solo si la carga salió bien → solo esos se guardan
local loaded: { [Player]: boolean } = {}
local released: { [Player]: boolean } = {}
local saving: { [Player]: boolean } = {}
local serializer: ((Player) -> { [string]: any })? = nil

---------------------------------------------------------------- Cargar
-- Devuelve (true, datos) o (false, mensaje). datos = nil si es jugador nuevo.
function DataService.Load(player: Player): (boolean, any)
	local key = keyFor(player)
	for attempt = 1, LOAD_ATTEMPTS do
		local lockedElsewhere = false
		local ok, result = pcall(function()
			return store:UpdateAsync(key, function(record)
				lockedElsewhere = false
				record = record or { Version = DATA_VERSION }
				local lock = record.Lock
				if lock and lock.JobId ~= game.JobId and os.time() - lock.Time < LOCK_TIMEOUT then
					lockedElsewhere = true
					return nil -- no escribir nada; otro servidor lo tiene
				end
				record.Lock = { JobId = game.JobId, Time = os.time() }
				return record
			end)
		end)

		if ok and not lockedElsewhere then
			loaded[player] = true
			released[player] = nil
			return true, if result then result.Data else nil
		elseif not ok and isStudioAccessError(tostring(result)) then
			switchToMock(tostring(result))
		elseif not ok then
			warn("[DataService] Error cargando " .. player.Name .. " (intento " .. attempt .. "): " .. tostring(result))
			task.wait(math.min(2 ^ attempt, 10))
		else
			-- Sigue abierto en otro servidor (por ejemplo, acaba de cambiarse de servidor)
			task.wait(5)
		end
		if not player.Parent then
			return false, "El jugador salió mientras cargaba"
		end
	end
	return false, "No se pudieron cargar tus datos. Vuelve a entrar en un minuto."
end

---------------------------------------------------------------- Guardar
local function save(player: Player, data: { [string]: any }, release: boolean): boolean
	local key = keyFor(player)
	for attempt = 1, SAVE_ATTEMPTS do
		local stolen = false
		local ok, err = pcall(function()
			store:UpdateAsync(key, function(record)
				stolen = false
				record = record or {}
				local lock = record.Lock
				if lock and lock.JobId ~= game.JobId then
					stolen = true -- otro servidor tomó los datos; no pisarlos
					return nil
				end
				return {
					Version = DATA_VERSION,
					Data = data,
					Lock = if release then nil else { JobId = game.JobId, Time = os.time() },
					SavedAt = os.time(),
				}
			end)
		end)
		if ok then
			if stolen then
				warn("[DataService] " .. player.Name .. " está abierto en otro servidor; no se guardó aquí.")
				return false
			end
			return true
		end
		warn("[DataService] Error guardando " .. player.Name .. " (intento " .. attempt .. "): " .. tostring(err))
		task.wait(attempt * 2)
	end
	warn("[DataService] CRÍTICO: no se pudo guardar a " .. player.Name)
	return false
end

-- Guarda ahora (sin soltar el bloqueo). Para autoguardado.
function DataService.Save(player: Player): boolean
	if not loaded[player] or released[player] or saving[player] or not serializer then
		return false
	end
	saving[player] = true
	local ok = save(player, serializer(player), false)
	saving[player] = nil
	return ok
end

-- Guarda por última vez y suelta el bloqueo (al salir o al cerrar). Solo una vez.
function DataService.Release(player: Player): boolean
	if not loaded[player] or released[player] or not serializer then
		loaded[player] = nil
		return false
	end
	released[player] = true
	local data = serializer(player)
	while saving[player] do
		task.wait()
	end
	local ok = save(player, data, true)
	loaded[player] = nil
	saving[player] = nil
	return ok
end

---------------------------------------------------------------- Arranque
-- serialize(player) debe devolver la tabla con todo lo que se guarda
function DataService.Start(serialize: (Player) -> { [string]: any })
	serializer = serialize

	Players.PlayerRemoving:Connect(function(player)
		DataService.Release(player)
		released[player] = nil
	end)

	-- Al cerrar el servidor: guardar a todos los que falten, en paralelo
	game:BindToClose(function()
		local pending = 0
		for player in loaded do
			pending += 1
			task.spawn(function()
				DataService.Release(player)
				pending -= 1
			end)
		end
		local started = os.clock()
		while pending > 0 and os.clock() - started < 25 do
			task.wait(0.1)
		end
	end)

	-- Autoguardado
	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_INTERVAL)
			for player in loaded do
				task.spawn(DataService.Save, player)
			end
		end
	end)
end

return DataService
