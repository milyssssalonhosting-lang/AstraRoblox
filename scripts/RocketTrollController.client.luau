-- StarterGui/HUD/Controllers/RocketTrollController (LocalScript)
-- Botones de trolleo durante el vuelo y sus efectos visuales:
--  ☄️ Meteorito: cae una roca en llamas sobre el cohete y explota.
--  🧲 Robar Turbo: rayo morado entre los dos cohetes.
--  ☢️ Nuclear: destello blanco, onda expansiva y temblor para todos.
-- El servidor decide si se puede, cobra, elige el objetivo y aplica el efecto.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local Rocket = GameConfig.Rocket
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local trollRequest = remotes:WaitForChild("RocketTroll")
local trollEvent = remotes:WaitForChild("RocketTrollEvent")
local state = ReplicatedStorage:WaitForChild("RocketState")

local hud = script.Parent.Parent
local Modules = hud:WaitForChild("Modules")
local UIEffects = require(Modules.UIEffects)
local Sfx = require(Modules.Sfx)
local Toast = require(Modules.Toast)
local ClientSettings = require(Modules.ClientSettings)

local player = Players.LocalPlayer
local root = hud:WaitForChild("Root")
local trollBar = root:WaitForChild("TrollBar")
local nukeFlash = root:WaitForChild("NukeFlash")

local effects = Instance.new("Folder")
effects.Name = "TrollEffects"
effects.Parent = workspace

local readyAt: { [string]: number } = {} -- cuándo se puede volver a usar cada trolleo (reloj local)

local function rocketOf(key: string): Model?
	local rockets = workspace:FindFirstChild("ClientRockets")
	return rockets and rockets:FindFirstChild("Rocket_" .. key) :: Model?
end

local function myKey(): string
	return player.Name
end

---------------------------------------------------------------- Temblor de cámara
local shakeUntil, shakePower = 0, 0
local function shake(power: number, seconds: number)
	shakePower = math.max(shakePower, power)
	shakeUntil = math.max(shakeUntil, os.clock() + seconds)
end
RunService:BindToRenderStep("TrollShake", Enum.RenderPriority.Camera.Value + 2, function()
	if os.clock() < shakeUntil then
		local camera = workspace.CurrentCamera
		local offset = Vector3.new(math.random() - 0.5, math.random() - 0.5, 0) * shakePower
		camera.CFrame = camera.CFrame * CFrame.new(offset)
	else
		shakePower = 0
	end
end)

---------------------------------------------------------------- Efectos
local function explosionAt(position: Vector3, color: Color3)
	if not UIEffects.Fancy() then
		return
	end
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Ball
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.Material = Enum.Material.Neon
	p.Color = color
	p.Size = Vector3.one * 2
	p.Position = position
	p.Parent = effects
	TweenService:Create(p, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.one * 14, Transparency = 1 }):Play()
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/fire_main.dds"
	e.Color = ColorSequence.new(Color3.fromRGB(255, 200, 80), Color3.fromRGB(255, 70, 30))
	e.LightEmission = 1
	e.Size = NumberSequence.new(3, 0)
	e.Lifetime = NumberRange.new(0.4, 0.8)
	e.Speed = NumberRange.new(20, 35)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Rate = 0
	e.Parent = p
	e:Emit(40)
	Debris:AddItem(p, 1.2)
end

local function meteor(targetKey: string)
	local target = rocketOf(targetKey)
	if not target then
		return
	end
	local rock = Instance.new("Part")
	rock.Shape = Enum.PartType.Ball
	rock.Size = Vector3.one * 5
	rock.Color = Color3.fromRGB(120, 70, 50)
	rock.Material = Enum.Material.Slate
	rock.Anchored = true
	rock.CanCollide = false
	rock.CanQuery = false
	rock.Parent = effects
	local fire = Instance.new("Fire")
	fire.Size = 8
	fire.Heat = 15
	fire.Parent = rock
	local start = os.clock()
	local connection
	connection = RunService.RenderStepped:Connect(function()
		local alpha = math.min(1, (os.clock() - start) / 0.6)
		local hit = target:GetPivot().Position + Vector3.new(0, 6, 0)
		rock.Position = hit + Vector3.new(-25, 70, 10) * (1 - alpha)
		if alpha >= 1 then
			connection:Disconnect()
			rock:Destroy()
			explosionAt(hit, Color3.fromRGB(255, 150, 60))
			Sfx.Play("Explosion", 1.1)
			if targetKey == myKey() then
				shake(1.5, 0.8)
			end
		end
	end)
end

local function stealBeam(fromKey: string, targetKey: string)
	local from, target = rocketOf(fromKey), rocketOf(targetKey)
	if not (from and target) then
		return
	end
	local a0 = Instance.new("Attachment")
	a0.Parent = target.PrimaryPart
	local a1 = Instance.new("Attachment")
	a1.Parent = from.PrimaryPart
	local beam = Instance.new("Beam")
	beam.Attachment0 = a0
	beam.Attachment1 = a1
	beam.Color = ColorSequence.new(Color3.fromRGB(220, 120, 255), Color3.fromRGB(120, 60, 255))
	beam.LightEmission = 1
	beam.Width0 = 1.5
	beam.Width1 = 1.5
	beam.FaceCamera = true
	beam.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	beam.TextureSpeed = 3
	beam.Parent = from.PrimaryPart
	Debris:AddItem(beam, 1.5)
	Debris:AddItem(a0, 1.5)
	Debris:AddItem(a1, 1.5)
	Sfx.Play("Claim", 0.8)
end

local function nuke(fromName: string)
	-- Destello blanco
	nukeFlash.Visible = true
	nukeFlash.BackgroundTransparency = 0
	TweenService:Create(nukeFlash, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { BackgroundTransparency = 1 }):Play()
	task.delay(1.2, function()
		nukeFlash.Visible = false
	end)
	shake(2.5, 1.5)
	Sfx.Play("Explosion", 0.7)
	-- Onda expansiva en cada cohete
	if UIEffects.Fancy() then
		for _, model in (workspace:FindFirstChild("ClientRockets") or effects):GetChildren() do
			if model:IsA("Model") then
				explosionAt(model:GetPivot().Position, Color3.fromRGB(190, 255, 80))
			end
		end
	end
end

trollEvent.OnClientEvent:Connect(function(info)
	local troll = GameConfig.GetTroll(info.Kind)
	if not troll then
		return
	end
	if info.Kind == "Meteor" then
		meteor(info.Targets[1])
	elseif info.Kind == "Steal" then
		stealBeam(info.From, info.Targets[1])
	elseif info.Kind == "Nuke" then
		nuke(info.FromName)
	end
	-- Avisos
	local hitMe = table.find(info.Targets, myKey()) ~= nil
	if hitMe then
		Toast.Show(troll.Icon .. " ¡" .. info.FromName .. " te lanzó " .. troll.Name .. "!", Toast.Bad)
	elseif info.From ~= myKey() and info.Kind == "Nuke" then
		Toast.Show("☢️ ¡" .. info.FromName .. " lanzó una BOMBA NUCLEAR!", Toast.Bad)
	end
end)

---------------------------------------------------------------- Botones
local busy = false
for _, troll in Rocket.Trolls.List do
	local button = trollBar:WaitForChild(troll.Id .. "Button")
	UIEffects.AttachButton(button)
	button.Activated:Connect(function()
		if busy or os.clock() < (readyAt[troll.Id] or 0) then
			return
		end
		busy = true
		local ok, success, message = pcall(trollRequest.InvokeServer, trollRequest, troll.Id)
		busy = false
		if ok and success then
			readyAt[troll.Id] = os.clock() + troll.Cooldown
			Toast.Show(message, Toast.Good)
			UIEffects.Bump(button)
		else
			Toast.Show(if ok then message else "Error de conexión", Toast.Bad)
		end
	end)
end

RunService.RenderStepped:Connect(function()
	-- Solo se ven durante el vuelo si estás en la carrera
	local flying = state:GetAttribute("Phase") == "Flight" and (player:GetAttribute("RocketPad") or 0) > 0
	trollBar.Visible = flying
	if not flying then
		readyAt = if state:GetAttribute("Phase") == "Prepare" then {} else readyAt
		return
	end
	trollBar.UIScale.Scale = ClientSettings.GetUIScale()
	local nukeUsed = state:GetAttribute("NukeUsed") == true
	for _, troll in Rocket.Trolls.List do
		local button = trollBar[troll.Id .. "Button"]
		local left = (readyAt[troll.Id] or 0) - os.clock()
		local blocked = troll.OncePerRound and nukeUsed
		button.Cooldown.Visible = left > 0 or blocked
		button.Cooldown.Text.Text = if blocked then "✖" else tostring(math.ceil(left))
	end
end)
