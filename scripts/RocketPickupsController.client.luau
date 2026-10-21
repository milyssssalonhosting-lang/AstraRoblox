-- StarterGui/HUD/Controllers/RocketPickupsController (LocalScript)
-- Dibuja las monedas y gemas del aire en el carril de cada cohete y muestra los
-- efectos cuando alguien las recoge (lo decide el servidor). Solo dibuja las que
-- están cerca de la altura del cohete, para no cargar cientos de objetos.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local Rocket = GameConfig.Rocket
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local pickupsRemote = remotes:WaitForChild("RocketPickups")
local collectedRemote = remotes:WaitForChild("RocketCollected")
local models = ReplicatedStorage:WaitForChild("PickupModels")

local hud = script.Parent.Parent
local Modules = hud:WaitForChild("Modules")
local UIEffects = require(Modules.UIEffects)
local Sfx = require(Modules.Sfx)
local Toast = require(Modules.Toast)

local player = Players.LocalPlayer
local bar = hud:WaitForChild("Root"):WaitForChild("RocketBar")
local powerText = bar:WaitForChild("PowerText")

local STUDS = Rocket.StudsPerMeter
local SHOW_BELOW, SHOW_ABOVE = 40, 260 -- metros alrededor del cohete en los que se dibujan

local folder = Instance.new("Folder")
folder.Name = "ClientPickups"
folder.Parent = workspace

-- lanes[userId] = { Items = {...}, Models = { [id] = BasePart }, Collected = { [id] = true } }
local lanes: { [string]: any } = {}

local function padFor(userId: string): BasePart?
	local p = Players:GetPlayerByUserId(tonumber(userId))
	local index = p and p:GetAttribute("RocketPad") or 0
	for _, pad in CollectionService:GetTagged("LaunchPad") do
		if pad:GetAttribute("Index") == index then
			return pad
		end
	end
	return nil
end

local function clearAll()
	folder:ClearAllChildren()
	lanes = {}
end

local function modelName(kind: string): string
	if kind == "Coin" then
		return "Coin"
	end
	return Rocket.Pickups.Gems[kind].Model
end

pickupsRemote.OnClientEvent:Connect(function(all)
	clearAll()
	for userId, items in all do
		lanes[userId] = { Items = items, Models = {}, Collected = {} }
	end
end)

---------------------------------------------------------------- Efectos al recoger
local function burst(position: Vector3, color: Color3, amount: number)
	if not UIEffects.Fancy() then
		return
	end
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.Transparency = 1
	p.Size = Vector3.one
	p.Position = position
	p.Parent = folder
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(color)
	e.LightEmission = 1
	e.Size = NumberSequence.new(1, 0)
	e.Lifetime = NumberRange.new(0.4, 0.8)
	e.Speed = NumberRange.new(12, 22)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Rate = 0
	e.Parent = p
	e:Emit(amount)
	task.delay(1, function()
		p:Destroy()
	end)
end

local function floatingText(position: Vector3, text: string, color: Color3)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.Transparency = 1
	p.Size = Vector3.one
	p.Position = position
	p.Parent = folder
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(220, 50)
	bb.AlwaysOnTop = true
	bb.LightInfluence = 0
	bb.Parent = p
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.Text = text
	label.TextColor3 = color
	label.Parent = bb
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Color3.fromRGB(28, 22, 40)
	stroke.Parent = label
	TweenService:Create(bb, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { StudsOffsetWorldSpace = Vector3.new(0, 6, 0) }):Play()
	TweenService:Create(label, TweenInfo.new(0.9), { TextTransparency = 1 }):Play()
	TweenService:Create(stroke, TweenInfo.new(0.9), { Transparency = 1 }):Play()
	task.delay(1, function()
		p:Destroy()
	end)
end

local GEM_COLORS = {
	Turbo = Color3.fromRGB(60, 220, 255),
	Fuel = Color3.fromRGB(80, 255, 90),
	Double = Color3.fromRGB(255, 210, 60),
	Galaxy = Color3.fromRGB(190, 90, 255),
}

collectedRemote.OnClientEvent:Connect(function(userId: number, id: number, kind: string, value: number)
	local lane = lanes[tostring(userId)]
	if not lane then
		return
	end
	lane.Collected[id] = true
	local model = lane.Models[id]
	local position = if model then model.Position else nil
	if model then
		model:Destroy()
		lane.Models[id] = nil
	end
	local mine = userId == player.UserId
	if kind == "Coin" then
		if position then
			burst(position, Color3.fromRGB(255, 210, 60), 8)
		end
		if mine then
			Sfx.Play("Coin", 1 + math.random() * 0.3)
			if position then
				floatingText(position, "+$" .. GameConfig.FormatNumber(value), Color3.fromRGB(150, 255, 100))
			end
		end
	else
		local gem = Rocket.Pickups.Gems[kind]
		if position then
			burst(position, GEM_COLORS[kind] or Color3.new(1, 1, 1), 25)
		end
		if mine then
			Sfx.Play("Claim", 1.2)
			Toast.Show(gem.Icon .. " ¡" .. gem.Name .. "!", GEM_COLORS[kind])
			if position then
				floatingText(position, gem.Icon .. " " .. gem.Name, GEM_COLORS[kind] or Color3.new(1, 1, 1))
			end
		end
	end
end)

---------------------------------------------------------------- Dibujar y girar
RunService.RenderStepped:Connect(function()
	local phase = ReplicatedStorage.RocketState:GetAttribute("Phase")
	if phase == "Waiting" or phase == nil then
		if next(lanes) then
			clearAll()
		end
		return
	end
	local t = os.clock()
	for userId, lane in lanes do
		local p = Players:GetPlayerByUserId(tonumber(userId))
		local pad = padFor(userId)
		if not (p and pad) then
			continue
		end
		local altitude = p:GetAttribute("Altitude") or 0
		for _, item in lane.Items do
			local near = item.Altitude > altitude - SHOW_BELOW and item.Altitude < altitude + SHOW_ABOVE
			local model = lane.Models[item.Id]
			if near and not lane.Collected[item.Id] then
				if not model then
					model = models[modelName(item.Kind)]:Clone()
					model.Parent = folder
					lane.Models[item.Id] = model
				end
				-- A la altura de la ventana del cohete, girando
				local y = pad.Position.Y + 5.3 + item.Altitude * STUDS + 2
				model.CFrame = CFrame.new(pad.Position.X, y + math.sin(t * 2 + item.Id) * 0.4, pad.Position.Z + 3.5) -- un poco al frente
					* CFrame.Angles(0, t * 2 + item.Id, 0) -- la moneda gira como rueda: se ve su cara
			elseif model then
				model:Destroy()
				lane.Models[item.Id] = nil
			end
		end
	end

	-- Indicador de power-ups activos
	local parts = {}
	local boostLeft = (player:GetAttribute("RocketBoostUntil") or 0) - workspace:GetServerTimeNow()
	if boostLeft > 0 then
		table.insert(parts, "⚡ Turbo " .. math.ceil(boostLeft) .. "s")
	end
	if player:GetAttribute("RocketDouble") then
		table.insert(parts, "💰 Premio x2")
	end
	powerText.Text = table.concat(parts, "   ")
	powerText.Visible = #parts > 0
end)
