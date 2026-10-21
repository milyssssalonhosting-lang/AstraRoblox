-- ServerScriptService/RewardsService (Script)
-- Recompensas diarias, misiones y Battle Pass. El cliente solo PIDE reclamar;
-- aquí se revisa que de verdad le toque antes de entregar nada.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local PlayerStats = require(script.Parent.Modules.PlayerStats)
local rewardsRequest: RemoteFunction = ReplicatedStorage.Remotes.RewardsRequest

local REQUEST_COOLDOWN = 0.15
local lastRequest: { [Player]: number } = {}

local IS_STUDIO = RunService:IsStudio()
local DAILY_COOLDOWN = if IS_STUDIO then GameConfig.Daily.StudioCooldownSeconds else GameConfig.Daily.CooldownSeconds
local DAILY_RESET = if IS_STUDIO then GameConfig.Daily.StudioResetAfterSeconds else GameConfig.Daily.ResetAfterSeconds

---------------------------------------------------------------- Diarias
local function claimDaily(player: Player)
	local now = os.time()
	local last = player:GetAttribute("DailyLastClaim") or 0
	if last > 0 and now - last < DAILY_COOLDOWN then
		return false, "Aún no, vuelve más tarde"
	end

	local day = player:GetAttribute("DailyDay") or 0
	if last > 0 and now - last > DAILY_RESET then
		day = 0 -- se rompió la racha
	end

	local reward = GameConfig.Daily.Rewards[day + 1]
	PlayerStats.GrantReward(player, reward)
	player:SetAttribute("DailyDay", (day + 1) % #GameConfig.Daily.Rewards)
	player:SetAttribute("DailyLastClaim", now)
	PlayerStats.AddStat(player, "DailyClaims", 1)
	return true, "Día " .. (day + 1) .. ": " .. GameConfig.RewardText(reward)
end

---------------------------------------------------------------- Misiones
local function claimMission(player: Player, missionId: unknown)
	if typeof(missionId) ~= "string" then
		return false, "Misión inválida"
	end
	local mission = GameConfig.GetMission(missionId)
	if not mission then
		return false, "Misión inválida"
	end
	local claimed = PlayerStats.GetTable(player, "MissionsClaimed")
	if claimed[mission.Id] then
		return false, "Ya la reclamaste"
	end
	if PlayerStats.GetStat(player, mission.Stat) < mission.Target then
		return false, "Todavía no la completas"
	end

	claimed[mission.Id] = true
	PlayerStats.SetTable(player, "MissionsClaimed", claimed)
	for _, reward in mission.Rewards do
		PlayerStats.GrantReward(player, reward)
	end
	return true, "¡Misión completada!"
end

---------------------------------------------------------------- Battle Pass
local function claimPassReward(player: Player, level: number, track: string, claimed): boolean
	local rewards = GameConfig.BattlePass.Levels[level]
	if not rewards then
		return false
	end
	if level > PlayerStats.GetBattlePassLevel(player) then
		return false
	end
	if track == "Premium" and not player:GetAttribute("BPPremium") then
		return false
	end
	local key = tostring(level)
	if claimed[track][key] then
		return false
	end
	claimed[track][key] = true
	PlayerStats.GrantReward(player, rewards[track])
	return true
end

local function claimBattlePass(player: Player, level: unknown, track: unknown)
	if typeof(level) ~= "number" or level ~= math.floor(level) then
		return false, "Nivel inválido"
	end
	if track ~= "Free" and track ~= "Premium" then
		return false, "Pase inválido"
	end
	local claimed = PlayerStats.GetTable(player, "BPClaimed")
	claimed.Free = claimed.Free or {}
	claimed.Premium = claimed.Premium or {}
	if not claimPassReward(player, level, track, claimed) then
		return false, "No disponible"
	end
	PlayerStats.SetTable(player, "BPClaimed", claimed)
	return true, "¡Premio del nivel " .. level .. "!"
end

local function claimAllBattlePass(player: Player)
	local claimed = PlayerStats.GetTable(player, "BPClaimed")
	claimed.Free = claimed.Free or {}
	claimed.Premium = claimed.Premium or {}
	local count = 0
	for level = 1, PlayerStats.GetBattlePassLevel(player) do
		for _, track in { "Free", "Premium" } do
			if claimPassReward(player, level, track, claimed) then
				count += 1
			end
		end
	end
	if count == 0 then
		return false, "No hay premios por reclamar"
	end
	PlayerStats.SetTable(player, "BPClaimed", claimed)
	return true, "¡Reclamaste " .. count .. " premios!"
end

---------------------------------------------------------------- Entrada única
rewardsRequest.OnServerInvoke = function(player: Player, action: unknown, ...)
	local now = os.clock()
	if lastRequest[player] and now - lastRequest[player] < REQUEST_COOLDOWN then
		return false, "Muy rápido"
	end
	lastRequest[player] = now
	if not player:GetAttribute("StatsReady") then
		return false, "Cargando…"
	end

	if action == "ClaimDaily" then
		return claimDaily(player)
	elseif action == "ClaimMission" then
		return claimMission(player, ...)
	elseif action == "ClaimBattlePass" then
		return claimBattlePass(player, ...)
	elseif action == "ClaimAllBattlePass" then
		return claimAllBattlePass(player)
	elseif action == "DevTogglePremium" and IS_STUDIO then
		-- Solo en Studio: activar el pase premium gratis para probar.
		-- En el juego real se activará al comprarlo con Robux (Fase 4).
		player:SetAttribute("BPPremium", not player:GetAttribute("BPPremium"))
		return true, if player:GetAttribute("BPPremium") then "Premium activado (prueba)" else "Premium desactivado"
	end
	return false, "Acción inválida"
end

game:GetService("Players").PlayerRemoving:Connect(function(player)
	lastRequest[player] = nil
end)
