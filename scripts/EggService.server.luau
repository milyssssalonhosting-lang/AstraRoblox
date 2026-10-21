-- ServerScriptService/EggService (Script)
-- Abrir huevos (gacha) con dinero del juego. El sorteo se hace SOLO aquí, con
-- las probabilidades de GameConfig.Eggs (las mismas que ve el jugador).
-- PolicyService: en países donde los objetos aleatorios pagados están restringidos,
-- los huevos se bloquean (el dinero del juego se podrá comprar con Robux).

local Players = game:GetService("Players")
local PolicyService = game:GetService("PolicyService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local PlayerStats = require(script.Parent.Modules.PlayerStats)
local eggRequest: RemoteFunction = ReplicatedStorage.Remotes.EggRequest

local REQUEST_COOLDOWN = 0.6 -- deja terminar la animación
local lastRequest: { [Player]: number } = {}
local rng = Random.new()

---------------------------------------------------------------- Política regional
local function checkPolicy(player: Player)
	local ok, info = pcall(function()
		return PolicyService:GetPolicyInfoForPlayerAsync(player)
	end)
	if ok and info then
		player:SetAttribute("RandomItemsRestricted", info.ArePaidRandomItemsRestricted == true)
	else
		-- Si no se puede saber, por seguridad se bloquea y se reintenta después
		player:SetAttribute("RandomItemsRestricted", true)
		warn("[EggService] No se pudo leer la política de " .. player.Name .. ": " .. tostring(info))
		task.delay(30, function()
			if player.Parent then
				checkPolicy(player)
			end
		end)
	end
end

Players.PlayerAdded:Connect(checkPolicy)
for _, player in Players:GetPlayers() do
	task.spawn(checkPolicy, player)
end

---------------------------------------------------------------- Sorteo
local function roll(egg): string
	local total = 0
	for _, entry in egg.Pets do
		total += entry.Weight
	end
	local pick = rng:NextNumber() * total
	for _, entry in egg.Pets do
		pick -= entry.Weight
		if pick <= 0 then
			return entry.Pet
		end
	end
	return egg.Pets[#egg.Pets].Pet
end

eggRequest.OnServerInvoke = function(player: Player, eggId: unknown, amount: unknown)
	local now = os.clock()
	if lastRequest[player] and now - lastRequest[player] < REQUEST_COOLDOWN then
		return false, "Espera un momento"
	end
	lastRequest[player] = now

	if not player:GetAttribute("StatsReady") then
		return false, "Cargando…"
	end
	if player:GetAttribute("RandomItemsRestricted") ~= false then
		return false, "Los huevos no están disponibles en tu región"
	end
	if typeof(eggId) ~= "string" or typeof(amount) ~= "number" then
		return false, "Huevo inválido"
	end
	local egg = GameConfig.GetEgg(eggId)
	if not egg or not table.find(GameConfig.EggOpenAmounts, amount) then
		return false, "Huevo inválido"
	end

	local cost = egg.Price * amount
	if not PlayerStats.TrySpend(player, cost) then
		return false, "Te faltan $" .. GameConfig.FormatNumber(cost - PlayerStats.GetMoney(player))
	end

	local seenBefore = PlayerStats.GetTable(player, "IndexSeen")
	local results = {}
	for _ = 1, amount do
		local petId = roll(egg)
		local isNew = not seenBefore[petId]
		seenBefore[petId] = true
		PlayerStats.GivePet(player, petId)
		table.insert(results, { Pet = petId, New = isNew })
	end
	PlayerStats.AddStat(player, "EggsOpened", amount)
	return true, results
end

Players.PlayerRemoving:Connect(function(player)
	lastRequest[player] = nil
end)
