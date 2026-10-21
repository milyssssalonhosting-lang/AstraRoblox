-- ServerScriptService/InventoryService (Script)
-- Equipar y guardar mascotas. El cliente pide; aquí se valida que la mascota
-- exista, que la tengas y que haya espacio.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local PlayerStats = require(script.Parent.Modules.PlayerStats)
local inventoryRequest: RemoteFunction = ReplicatedStorage.Remotes.InventoryRequest

local REQUEST_COOLDOWN = 0.15
local lastRequest: { [Player]: number } = {}

inventoryRequest.OnServerInvoke = function(player: Player, action: unknown, petId: unknown)
	local now = os.clock()
	if lastRequest[player] and now - lastRequest[player] < REQUEST_COOLDOWN then
		return false, "Muy rápido"
	end
	lastRequest[player] = now
	if not player:GetAttribute("StatsReady") then
		return false, "Cargando…"
	end

	if action == "EquipBest" then
		return PlayerStats.EquipBest(player)
	end
	if typeof(petId) ~= "string" then
		return false, "Mascota inválida"
	end
	if action == "Equip" then
		return PlayerStats.EquipPet(player, petId)
	elseif action == "Unequip" then
		return PlayerStats.UnequipPet(player, petId)
	elseif action == "Fuse" then
		return PlayerStats.FusePet(player, petId)
	end
	return false, "Acción inválida"
end

Players.PlayerRemoving:Connect(function(player)
	lastRequest[player] = nil
end)
