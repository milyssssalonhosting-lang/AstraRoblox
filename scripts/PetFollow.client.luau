-- StarterPlayer/StarterPlayerScripts/PetFollow (LocalScript)
-- Dibuja las mascotas equipadas de TODOS los jugadores siguiéndolos.
-- Solo visual y local (cada cliente las dibuja) → no carga al servidor; el
-- servidor solo dice qué tiene equipado cada quien (atributo Equipped).
-- Slimes saltan; abejas flotan. Las de jugadores lejanos no se dibujan.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local petModels = ReplicatedStorage:WaitForChild("PetModels")
local localPlayer = Players.LocalPlayer

local DRAW_DISTANCE = 140 -- más lejos que esto, las mascotas de otros se ocultan

local folder = Instance.new("Folder")
folder.Name = "ClientPets"
folder.Parent = workspace

-- Posiciones en semicírculo detrás del jugador (hasta 5)
local SLOTS = {
	Vector3.new(0, 0, 5),
	Vector3.new(-3.5, 0, 4),
	Vector3.new(3.5, 0, 4),
	Vector3.new(-6, 0, 2),
	Vector3.new(6, 0, 2),
}

type PetEntry = { Model: Model, Offset: Vector3, Family: string, Height: number, Phase: number }
local pets: { [Player]: { PetEntry } } = {}

local function makePet(petId: string): (Model?, number)
	local source = petModels:FindFirstChild(petId)
	if not source then
		return nil, 0
	end
	local model = source:Clone()
	local _, size = model:GetBoundingBox()
	model.Parent = folder
	return model, size.Y
end

local function clearPets(player: Player)
	for _, entry in pets[player] or {} do
		entry.Model:Destroy()
	end
	pets[player] = nil
end

local function rebuild(player: Player)
	clearPets(player)
	local ok, equipped = pcall(HttpService.JSONDecode, HttpService, player:GetAttribute("Equipped") or "[]")
	if not ok or type(equipped) ~= "table" then
		return
	end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local list = {}
	for i, petId in equipped do
		if i > #SLOTS then
			break
		end
		local model, height = makePet(petId)
		if model then
			if root then
				model:PivotTo(root.CFrame * CFrame.new(SLOTS[i])) -- aparece junto al jugador
			end
			local pet = GameConfig.Pets[petId]
			table.insert(list, {
				Model = model,
				Offset = SLOTS[i],
				Family = pet and pet.Family or "Bee",
				Height = height,
				Phase = i * 0.7,
			})
		end
	end
	pets[player] = list
end

local function track(player: Player)
	player:GetAttributeChangedSignal("Equipped"):Connect(function()
		rebuild(player)
	end)
	rebuild(player)
end

for _, player in Players:GetPlayers() do
	track(player)
end
Players.PlayerAdded:Connect(track)
Players.PlayerRemoving:Connect(clearPets)

---------------------------------------------------------------- Movimiento
local myRoot: BasePart? = nil

RunService.RenderStepped:Connect(function(dt)
	local t = os.clock()
	local myCharacter = localPlayer.Character
	myRoot = myCharacter and myCharacter:FindFirstChild("HumanoidRootPart") :: BasePart?

	for player, list in pets do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local visible = root ~= nil
			and (player == localPlayer or (myRoot ~= nil and (root.Position - myRoot.Position).Magnitude < DRAW_DISTANCE))
		for _, entry in list do
			if not visible then
				entry.Model.Parent = nil
				continue
			end
			entry.Model.Parent = folder
			-- Apoyar en el suelo: la cadera del personaje está ~3 studs arriba del piso
			local groundY = -3 + entry.Height / 2
			local y
			if entry.Family == "Slime" then
				y = groundY + math.abs(math.sin(t * 4 + entry.Phase)) * 1.2 -- saltitos
			else
				y = groundY + 2.5 + math.sin(t * 2.5 + entry.Phase) * 0.4 -- flota
			end
			local target = root.CFrame * CFrame.new(entry.Offset.X, y, entry.Offset.Z)
			local current = entry.Model:GetPivot()
			-- Se mueve suave hacia su lugar; mira hacia donde mira el jugador
			local position = current.Position:Lerp(target.Position, math.min(1, dt * 10))
			entry.Model:PivotTo(CFrame.new(position) * root.CFrame.Rotation)
		end
	end
end)
