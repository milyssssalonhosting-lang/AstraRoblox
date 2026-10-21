-- ServerScriptService/LobbyService (Script)
-- Cosas de la zona de inicio que decide el servidor:
--  * Zona AFK: si estás parado dentro del círculo, ganas x2 (lo revisa el servidor
--    con la posición real del personaje; el cliente no puede mentir).
--  * Rebirth (pedido por el cliente, validado aquí).
--  * Viajar a otros mundos (AFK, Principal) con TeleportService.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local CollectionService = game:GetService("CollectionService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local PlayerStats = require(script.Parent.Modules.PlayerStats)
local remotes = ReplicatedStorage.Remotes
local rebirthRequest: RemoteFunction = remotes.RebirthRequest
local worldRequest: RemoteFunction = remotes.WorldRequest

local lastRequest: { [Player]: number } = {}
local function tooFast(player: Player, seconds: number): boolean
	local now = os.clock()
	if lastRequest[player] and now - lastRequest[player] < seconds then
		return true
	end
	lastRequest[player] = now
	return false
end

local function getRoot(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

---------------------------------------------------------------- Zona AFK
local function findAFKZone(): BasePart?
	for _, part in CollectionService:GetTagged("AFKZone") do
		if part:IsA("BasePart") and part:IsDescendantOf(workspace) then
			return part
		end
	end
	return nil
end

task.spawn(function()
	while true do
		task.wait(0.5)
		local zone = findAFKZone()
		for _, player in Players:GetPlayers() do
			if player:GetAttribute("StatsReady") then
				local root = getRoot(player)
				local inside = false
				if zone and root then
					local offset = root.Position - zone.Position
					local flat = Vector3.new(offset.X, 0, offset.Z).Magnitude
					inside = flat <= GameConfig.AFK.Radius and math.abs(offset.Y) < 8
				end
				if (player:GetAttribute("InAFKZone") == true) ~= inside then
					player:SetAttribute("InAFKZone", inside)
					PlayerStats.RefreshDerived(player)
				end
			end
		end
	end
end)

---------------------------------------------------------------- Rebirth
rebirthRequest.OnServerInvoke = function(player: Player)
	if tooFast(player, 1) then
		return false, "Espera un momento"
	end
	if not player:GetAttribute("StatsReady") then
		return false, "Cargando…"
	end
	return PlayerStats.DoRebirth(player)
end

---------------------------------------------------------------- Viajar a otros mundos
worldRequest.OnServerInvoke = function(player: Player, worldId: unknown)
	if tooFast(player, 2) then
		return false, "Espera un momento"
	end
	if typeof(worldId) ~= "string" then
		return false, "Mundo inválido"
	end
	local world = GameConfig.Worlds[worldId]
	if not world then
		return false, "Mundo inválido"
	end

	-- Debe estar parado cerca del portal de ese mundo
	local root = getRoot(player)
	local near = false
	for _, portal in CollectionService:GetTagged("WorldPortal") do
		if portal:IsA("BasePart") and portal:GetAttribute("World") == worldId and root then
			if (portal.Position - root.Position).Magnitude < 25 then
				near = true
			end
		end
	end
	if not near then
		return false, "Acércate al portal"
	end

	-- Mientras el mundo no tenga su propio lugar (o estemos en Studio), se viaja
	-- dentro de este mismo lugar a su punto de llegada
	if world.PlaceId == 0 or RunService:IsStudio() then
		local target = world.LocalSpawn and workspace:FindFirstChild(world.LocalSpawn, true)
		if not (target and target:IsA("BasePart") and root) then
			return false, world.Name .. ": ¡muy pronto!"
		end
		local character = player.Character
		character:PivotTo(CFrame.new(target.Position + Vector3.new(0, 4, 0)))
		return true, "¡Bienvenido a " .. world.Name .. "!", "local"
	end

	local ok, err = pcall(function()
		TeleportService:TeleportAsync(world.PlaceId, { player })
	end)
	if not ok then
		warn("[LobbyService] Teleport falló para " .. player.Name .. ": " .. tostring(err))
		return false, "No se pudo viajar, intenta de nuevo"
	end
	return true, "Viajando a " .. world.Name .. "…"
end

Players.PlayerRemoving:Connect(function(player)
	lastRequest[player] = nil
end)
