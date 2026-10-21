-- ServerScriptService/Modules/PlayerStats (ModuleScript)
-- Funciones del servidor para leer y cambiar las estadísticas de un jugador.
-- Los valores viven como atributos del Player (el cliente los ve, pero solo
-- el servidor los puede cambiar). Las listas (mascotas, misiones reclamadas…)
-- se guardan como texto JSON en un atributo.
-- FASE 1: no se guarda nada al salir; en la Fase 3 esto se conecta a DataStore.

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local PlayerStats = {}

---------------------------------------------------------------- JSON en atributos
function PlayerStats.GetTable(player: Player, name: string): { [any]: any }
	local raw = player:GetAttribute(name)
	if type(raw) ~= "string" or raw == "" then
		return {}
	end
	local ok, result = pcall(HttpService.JSONDecode, HttpService, raw)
	return if ok and type(result) == "table" then result else {}
end

function PlayerStats.SetTable(player: Player, name: string, value: { [any]: any })
	player:SetAttribute(name, HttpService:JSONEncode(value))
end

---------------------------------------------------------------- Contadores para misiones
function PlayerStats.AddStat(player: Player, stat: string, amount: number)
	local key = "Stat_" .. stat
	player:SetAttribute(key, (player:GetAttribute(key) or 0) + amount)
end

function PlayerStats.GetStat(player: Player, stat: string): number
	if stat == "Level" then
		return player:GetAttribute("Level") or 1
	end
	return player:GetAttribute("Stat_" .. stat) or 0
end

---------------------------------------------------------------- Mejoras y bonos
function PlayerStats.GetUpgradeLevel(player: Player, id: string): number
	return player:GetAttribute("Upgrade_" .. id) or 0
end

function PlayerStats.GetUpgradeValue(player: Player, id: string): number
	local upgrade = GameConfig.GetUpgrade(id)
	return GameConfig.UpgradeValue(upgrade, PlayerStats.GetUpgradeLevel(player, id))
end

function PlayerStats.ComputeMoneyPerSecond(player: Player): number
	local base = PlayerStats.GetUpgradeValue(player, "PassiveIncome")
	local multiplier = PlayerStats.GetUpgradeValue(player, "MoneyMultiplier")
	local friendBoost = player:GetAttribute("FriendBoost") or 0
	local petBoost = player:GetAttribute("PetBoost") or 0
	local rebirth = GameConfig.RebirthMultiplier(player:GetAttribute("Rebirths") or 0)
	local afk = if player:GetAttribute("InAFKZone") then GameConfig.AFK.Multiplier else 1
	return base * multiplier * (1 + friendBoost + petBoost) * rebirth * afk
end

-- Suma de los bonos de las mascotas equipadas (dinero, cohete, XP, caminar)
local function computePetBonuses(player: Player): (number, number, number, number)
	local boost, rocket, xp, speed = 0, 0, 0, 0
	for _, petId in PlayerStats.GetTable(player, "Equipped") do
		local pet = GameConfig.Pets[petId]
		if pet then
			boost += pet.Boost or 0
			rocket += pet.Rocket or 0
			xp += pet.XP or 0
			speed += pet.Speed or 0
		end
	end
	return boost, math.min(rocket, GameConfig.MaxPetRocket), xp, math.min(speed, GameConfig.MaxPetSpeed)
end

function PlayerStats.RefreshDerived(player: Player)
	local boost, rocket, xp, speed = computePetBonuses(player)
	player:SetAttribute("PetBoost", boost)
	player:SetAttribute("PetRocket", rocket)
	player:SetAttribute("PetXP", xp)
	if player:GetAttribute("PetSpeed") ~= speed then
		player:SetAttribute("PetSpeed", speed)
		PlayerStats.ApplyWalkSpeed(player)
	end
	player:SetAttribute("MoneyPerSecond", PlayerStats.ComputeMoneyPerSecond(player))
	player:SetAttribute("MoneyMultiplierTotal", PlayerStats.GetUpgradeValue(player, "MoneyMultiplier"))
end

function PlayerStats.ApplyWalkSpeed(player: Player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = PlayerStats.GetUpgradeValue(player, "WalkSpeed") + (player:GetAttribute("PetSpeed") or 0)
	end
end

---------------------------------------------------------------- Dinero, XP y pase
function PlayerStats.GetMoney(player: Player): number
	return player:GetAttribute("Money") or 0
end

local function setMoney(player: Player, value: number)
	player:SetAttribute("Money", value)
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		stats.Money.Value = value
	end
end

-- countAsEarned = true cuenta para misiones de "gana $X" (no cuenta el dinero de prueba)
function PlayerStats.AddMoney(player: Player, amount: number, countAsEarned: boolean?)
	setMoney(player, PlayerStats.GetMoney(player) + amount)
	if countAsEarned then
		PlayerStats.AddStat(player, "MoneyEarned", amount)
	end
end

function PlayerStats.TrySpend(player: Player, cost: number): boolean
	local money = PlayerStats.GetMoney(player)
	if money < cost then
		return false
	end
	setMoney(player, money - cost)
	return true
end

function PlayerStats.AddXP(player: Player, amount: number)
	local xp = (player:GetAttribute("XP") or 0) + amount
	local level = player:GetAttribute("Level") or 1
	while xp >= GameConfig.XPForLevel(level) do
		xp -= GameConfig.XPForLevel(level)
		level += 1
	end
	player:SetAttribute("XP", xp)
	player:SetAttribute("Level", level)
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		stats.Level.Value = level
	end
end

function PlayerStats.AddBattlePassXP(player: Player, amount: number)
	local maxXP = GameConfig.BattlePass.MaxLevel * GameConfig.BattlePass.XPPerLevel
	local xp = math.min((player:GetAttribute("BPXP") or 0) + amount, maxXP)
	player:SetAttribute("BPXP", xp)
end

function PlayerStats.GetBattlePassLevel(player: Player): number
	local xp = player:GetAttribute("BPXP") or 0
	return math.min(xp // GameConfig.BattlePass.XPPerLevel, GameConfig.BattlePass.MaxLevel)
end

function PlayerStats.GivePet(player: Player, petId: string)
	if not GameConfig.Pets[petId] then
		warn("Mascota desconocida: " .. tostring(petId))
		return
	end
	local pets = PlayerStats.GetTable(player, "Pets")
	pets[petId] = (pets[petId] or 0) + 1
	PlayerStats.SetTable(player, "Pets", pets)

	-- El Index recuerda cada mascota que alguna vez tuviste
	local seen = PlayerStats.GetTable(player, "IndexSeen")
	if not seen[petId] then
		seen[petId] = true
		PlayerStats.SetTable(player, "IndexSeen", seen)
	end
end

---------------------------------------------------------------- Equipar mascotas
local function countIn(list: { string }, petId: string): number
	local count = 0
	for _, id in list do
		if id == petId then
			count += 1
		end
	end
	return count
end

function PlayerStats.EquipPet(player: Player, petId: string): (boolean, string)
	if not GameConfig.Pets[petId] then
		return false, "Mascota inválida"
	end
	local owned = PlayerStats.GetTable(player, "Pets")[petId] or 0
	local equipped = PlayerStats.GetTable(player, "Equipped")
	if #equipped >= GameConfig.MaxEquippedPets then
		return false, "Máximo " .. GameConfig.MaxEquippedPets .. " mascotas equipadas"
	end
	if countIn(equipped, petId) >= owned then
		return false, "No tienes más de esa mascota"
	end
	table.insert(equipped, petId)
	PlayerStats.SetTable(player, "Equipped", equipped)
	PlayerStats.RefreshDerived(player)
	return true, GameConfig.Pets[petId].Name .. " equipado"
end

function PlayerStats.UnequipPet(player: Player, petId: string): (boolean, string)
	local equipped = PlayerStats.GetTable(player, "Equipped")
	local index = table.find(equipped, petId)
	if not index then
		return false, "No está equipada"
	end
	table.remove(equipped, index)
	PlayerStats.SetTable(player, "Equipped", equipped)
	PlayerStats.RefreshDerived(player)
	return true, GameConfig.Pets[petId].Name .. " guardado"
end

-- Equipa las que dan más bono
function PlayerStats.EquipBest(player: Player): (boolean, string)
	local candidates = {}
	for petId, count in PlayerStats.GetTable(player, "Pets") do
		if GameConfig.Pets[petId] then
			for _ = 1, math.min(count, GameConfig.MaxEquippedPets) do
				table.insert(candidates, petId)
			end
		end
	end
	if #candidates == 0 then
		return false, "Todavía no tienes mascotas"
	end
	local function score(petId: string): number
		return GameConfig.PetScore(GameConfig.Pets[petId])
	end
	table.sort(candidates, function(a, b)
		return score(a) > score(b)
	end)
	local best = {}
	for i = 1, math.min(#candidates, GameConfig.MaxEquippedPets) do
		best[i] = candidates[i]
	end
	PlayerStats.SetTable(player, "Equipped", best)
	PlayerStats.RefreshDerived(player)
	return true, "¡Mejores mascotas equipadas!"
end

-- Rebirth: cuesta dinero; reinicia dinero y mejoras; da bono de dinero permanente
function PlayerStats.DoRebirth(player: Player): (boolean, string)
	local rebirths = player:GetAttribute("Rebirths") or 0
	local cost = GameConfig.RebirthCost(rebirths)
	if PlayerStats.GetMoney(player) < cost then
		return false, "Necesitas $" .. GameConfig.FormatNumber(cost)
	end
	setMoney(player, 0)
	for _, upgrade in GameConfig.Upgrades do
		player:SetAttribute("Upgrade_" .. upgrade.Id, 0)
	end
	player:SetAttribute("Rebirths", rebirths + 1)
	PlayerStats.RefreshDerived(player)
	PlayerStats.ApplyWalkSpeed(player)
	return true, "¡Rebirth " .. (rebirths + 1) .. "! Ahora ganas x" .. GameConfig.RebirthMultiplier(rebirths + 1)
end

-- Fusionar: 3 iguales del nivel N → 1 del nivel N+1 (slimes y abejas)
function PlayerStats.FusePet(player: Player, petId: string): (boolean, string)
	local pet = GameConfig.Pets[petId]
	if not pet or not pet.Next then
		return false, "Esta mascota no se puede fusionar"
	end
	local pets = PlayerStats.GetTable(player, "Pets")
	local owned = pets[petId] or 0
	if owned < GameConfig.FuseAmount then
		return false, "Necesitas " .. GameConfig.FuseAmount .. " iguales (tienes " .. owned .. ")"
	end
	pets[petId] = owned - GameConfig.FuseAmount
	if pets[petId] == 0 then
		pets[petId] = nil
	end
	PlayerStats.SetTable(player, "Pets", pets)

	-- Si se fusionaron mascotas equipadas, quitarlas de las equipadas
	local equipped = PlayerStats.GetTable(player, "Equipped")
	local remaining = pets[petId] or 0
	local kept = {}
	local hadEquipped = false
	for _, id in equipped do
		if id == petId then
			if remaining > 0 then
				remaining -= 1
				table.insert(kept, id)
			else
				hadEquipped = true
			end
		else
			table.insert(kept, id)
		end
	end
	PlayerStats.GivePet(player, pet.Next)
	-- Si usabas las que se fusionaron, la nueva toma su lugar
	if hadEquipped and #kept < GameConfig.MaxEquippedPets then
		table.insert(kept, pet.Next)
	end
	PlayerStats.SetTable(player, "Equipped", kept)

	PlayerStats.AddStat(player, "PetsFused", 1)
	PlayerStats.RefreshDerived(player)
	return true, "¡" .. GameConfig.Pets[pet.Next].Name .. "!"
end

-- Entrega cualquier recompensa de GameConfig (dinero, XP, pase o mascota)
function PlayerStats.GrantReward(player: Player, reward)
	if reward.Type == "Money" then
		PlayerStats.AddMoney(player, reward.Amount, false)
	elseif reward.Type == "XP" then
		PlayerStats.AddXP(player, reward.Amount)
	elseif reward.Type == "BPXP" then
		PlayerStats.AddBattlePassXP(player, reward.Amount)
	elseif reward.Type == "Pet" then
		PlayerStats.GivePet(player, reward.Pet)
	end
end

---------------------------------------------------------------- Guardar y cargar
-- Qué se guarda: números sueltos, mejoras, contadores y tablas (como texto JSON
-- en atributos, pero en el DataStore se guardan como tablas normales).
local SAVED_NUMBERS = { "Money", "XP", "Level", "Rebirths", "BPXP", "DailyDay", "DailyLastClaim" }
local SAVED_TABLES = { "BPClaimed", "MissionsClaimed", "Pets", "Equipped", "IndexSeen", "Settings" }

local function defaults(): { [string]: any }
	local data = {
		Money = 0,
		XP = 0,
		Level = 1,
		Rebirths = 0,
		BPXP = 0,
		BPPremium = false,
		BPSeason = GameConfig.BattlePass.Season,
		DailyDay = 0, -- días reclamados en la racha actual (0-6)
		DailyLastClaim = 0,
		Upgrades = {},
		Stats = {},
		BPClaimed = { Free = {}, Premium = {} },
		MissionsClaimed = {},
		Pets = {},
		Equipped = {}, -- lista de Ids de mascotas equipadas
		IndexSeen = {}, -- mascotas descubiertas alguna vez
		Settings = {},
	}
	for _, upgrade in GameConfig.Upgrades do
		data.Upgrades[upgrade.Id] = 0
	end
	for stat in GameConfig.MissionStats do
		if stat ~= "Level" then
			data.Stats[stat] = 0
		end
	end
	return data
end

-- Empaca los atributos del jugador en una tabla para el DataStore
function PlayerStats.Serialize(player: Player): { [string]: any }
	local data = defaults()
	for _, name in SAVED_NUMBERS do
		data[name] = player:GetAttribute(name) or data[name]
	end
	data.BPPremium = player:GetAttribute("BPPremium") == true
	data.BPSeason = GameConfig.BattlePass.Season
	for id in data.Upgrades do
		data.Upgrades[id] = PlayerStats.GetUpgradeLevel(player, id)
	end
	for stat in data.Stats do
		data.Stats[stat] = player:GetAttribute("Stat_" .. stat) or 0
	end
	for _, name in SAVED_TABLES do
		data[name] = PlayerStats.GetTable(player, name)
	end
	return data
end

---------------------------------------------------------------- Al entrar
-- saved = lo que vino del DataStore (nil si es jugador nuevo)
function PlayerStats.Init(player: Player, saved: { [string]: any }?)
	local data = defaults()
	local isNew = saved == nil
	if saved then
		-- Encima de los valores por defecto: así los campos nuevos del juego
		-- aparecen solos en jugadores viejos
		for key, value in saved do
			if type(value) == "table" and type(data[key]) == "table" then
				for k, v in value do
					data[key][k] = v
				end
			elseif data[key] ~= nil and type(value) == type(data[key]) then
				data[key] = value
			end
		end
	end

	-- Temporada nueva del Battle Pass: se reinicia el progreso del pase
	if data.BPSeason ~= GameConfig.BattlePass.Season then
		data.BPXP = 0
		data.BPPremium = false
		data.BPClaimed = { Free = {}, Premium = {} }
	end

	-- Limpiar mascotas: el Index incluye todo lo que tienes, y solo se equipa lo que existe y tienes
	local stillOwned = {}
	for petId, count in data.Pets do
		if GameConfig.Pets[petId] then
			data.IndexSeen[petId] = true
			stillOwned[petId] = count
		end
	end
	local cleanEquipped = {}
	for _, petId in data.Equipped do
		if (stillOwned[petId] or 0) > 0 and #cleanEquipped < GameConfig.MaxEquippedPets then
			stillOwned[petId] -= 1
			table.insert(cleanEquipped, petId)
		end
	end
	data.Equipped = cleanEquipped

	-- Modo prueba: en Studio, un jugador nuevo empieza con dinero casi ilimitado
	if isNew and RunService:IsStudio() then
		data.Money = GameConfig.DevStartMoney
	end

	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local money = Instance.new("NumberValue")
	money.Name = "Money"
	money.Parent = stats
	local level = Instance.new("IntValue")
	level.Name = "Level"
	level.Value = data.Level
	level.Parent = stats
	stats.Parent = player

	for _, name in SAVED_NUMBERS do
		player:SetAttribute(name, data[name])
	end
	player:SetAttribute("BPPremium", data.BPPremium)
	player:SetAttribute("FriendBoost", 0)
	for id, value in data.Upgrades do
		player:SetAttribute("Upgrade_" .. id, value)
	end
	for stat, value in data.Stats do
		player:SetAttribute("Stat_" .. stat, value)
	end
	for _, name in SAVED_TABLES do
		PlayerStats.SetTable(player, name, data[name])
	end

	setMoney(player, data.Money)
	PlayerStats.RefreshDerived(player)
	player:SetAttribute("StatsReady", true)
end

return PlayerStats
