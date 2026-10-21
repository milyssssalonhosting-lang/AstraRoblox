-- ServerScriptService/PlayerStatsService (Script)
-- Prepara a cada jugador, da la ganancia pasiva cada segundo, calcula el bono
-- de amigos y valida la compra de mejoras. Carga y guarda con Modules/DataService. Las funciones de estadísticas están
-- en Modules/PlayerStats para que otros scripts (recompensas) las compartan.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local PlayerStats = require(script.Parent.Modules.PlayerStats)
local DataService = require(script.Parent.Modules.DataService)
local purchaseUpgrade: RemoteFunction = ReplicatedStorage.Remotes.PurchaseUpgrade
local saveSettings: RemoteEvent = ReplicatedStorage.Remotes.SaveSettings

DataService.Start(PlayerStats.Serialize)

local PURCHASE_COOLDOWN = 0.2
local lastPurchase: { [Player]: number } = {}
local lastSettingsSave: { [Player]: number } = {}
local friendCache: { [string]: boolean } = {}

-- ¿Son amigos? Guardamos el resultado para no preguntarle a Roblox cada vez.
local function areFriends(a: Player, b: Player): boolean
	local low, high = math.min(a.UserId, b.UserId), math.max(a.UserId, b.UserId)
	local key = low .. ":" .. high
	if friendCache[key] == nil then
		local ok, result = pcall(function()
			return a:IsFriendsWith(b.UserId)
		end)
		friendCache[key] = ok and result or false
	end
	return friendCache[key]
end

local function refreshFriendBoosts()
	local all = Players:GetPlayers()
	for _, player in all do
		local friends = 0
		for _, other in all do
			if other ~= player and other.Parent and areFriends(player, other) then
				friends += 1
			end
		end
		local boost = math.min(friends * GameConfig.FriendBoostPerFriend, GameConfig.FriendBoostMax)
		player:SetAttribute("FriendBoost", boost)
		PlayerStats.RefreshDerived(player)
	end
end

local function onPlayerAdded(player: Player)
	local ok, savedOrError = DataService.Load(player)
	if not player.Parent then
		DataService.Release(player) -- salió mientras cargaba: soltar el bloqueo
		return
	end
	if not ok then
		-- Regla de la guía: si la carga falla, no jugar ni guardar (protege su progreso real)
		player:Kick(savedOrError)
		return
	end
	PlayerStats.Init(player, savedOrError)
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("Humanoid")
		PlayerStats.ApplyWalkSpeed(player)
	end)
	if player.Character then
		PlayerStats.ApplyWalkSpeed(player)
	end
	task.spawn(refreshFriendBoosts)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerRemoving:Connect(function(player)
	lastPurchase[player] = nil
	lastSettingsSave[player] = nil
	task.defer(refreshFriendBoosts)
end)

-- Ajustes del jugador (volumen, tamaño del HUD, efectos). Se validan antes de guardar.
local SETTINGS_RULES = {
	MusicVolume = { Min = 0, Max = 1 },
	SfxVolume = { Min = 0, Max = 1 },
	HudScale = { Min = 0.7, Max = 1.3 },
}
local EFFECT_MODES = { Auto = true, On = true, Off = true }

saveSettings.OnServerEvent:Connect(function(player: Player, settings: unknown)
	local now = os.clock()
	if lastSettingsSave[player] and now - lastSettingsSave[player] < 1 then
		return
	end
	lastSettingsSave[player] = now
	if type(settings) ~= "table" or not player:GetAttribute("StatsReady") then
		return
	end
	local clean = {}
	for key, rule in SETTINGS_RULES do
		local value = settings[key]
		if type(value) == "number" and value == value then -- value == value descarta NaN
			clean[key] = math.clamp(value, rule.Min, rule.Max)
		end
	end
	if type(settings.EffectsMode) == "string" and EFFECT_MODES[settings.EffectsMode] then
		clean.EffectsMode = settings.EffectsMode
	end
	PlayerStats.SetTable(player, "Settings", clean)
end)

-- Compra de mejoras: todo se valida aquí
purchaseUpgrade.OnServerInvoke = function(player: Player, upgradeId: unknown)
	local now = os.clock()
	if lastPurchase[player] and now - lastPurchase[player] < PURCHASE_COOLDOWN then
		return false, "Muy rápido"
	end
	lastPurchase[player] = now

	if typeof(upgradeId) ~= "string" then
		return false, "Mejora inválida"
	end
	local upgrade = GameConfig.GetUpgrade(upgradeId)
	if not upgrade then
		return false, "Mejora inválida"
	end

	local level = PlayerStats.GetUpgradeLevel(player, upgrade.Id)
	if level >= upgrade.MaxLevel then
		return false, "¡Nivel máximo!"
	end

	local cost = GameConfig.UpgradeCost(upgrade, level)
	if not PlayerStats.TrySpend(player, cost) then
		return false, "No tienes suficiente dinero"
	end

	player:SetAttribute("Upgrade_" .. upgrade.Id, level + 1)
	PlayerStats.AddStat(player, "UpgradesBought", 1)
	PlayerStats.RefreshDerived(player)
	if upgrade.Id == "WalkSpeed" then
		PlayerStats.ApplyWalkSpeed(player)
	end
	return true, upgrade.DisplayName .. " nivel " .. (level + 1)
end

-- Ganancia pasiva: cada segundo, a todos
while true do
	task.wait(GameConfig.PassiveTickSeconds)
	for _, player in Players:GetPlayers() do
		if player:GetAttribute("StatsReady") then
			PlayerStats.AddMoney(player, PlayerStats.ComputeMoneyPerSecond(player), true)
			PlayerStats.AddXP(player, GameConfig.PassiveXP)
			PlayerStats.AddStat(player, "PlaySeconds", GameConfig.PassiveTickSeconds)
			PlayerStats.AddBattlePassXP(player, GameConfig.BattlePass.PassiveXPPerSecond * GameConfig.PassiveTickSeconds)
		end
	end
end
