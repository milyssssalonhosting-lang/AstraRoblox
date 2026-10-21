-- StarterGui/HUD/Controllers/LobbyController (LocalScript)
-- Zona de inicio:
--  * Estaciones (huevos, rebirth): su ProximityPrompt abre el panel del HUD.
--  * Plataformas-portal (AFK Pro, Jugar): al pararte encima te pregunta si quieres
--    viajar; si dices que sí, muestra pantalla de carga y se lo pide al servidor.
--  * Zona AFK: aviso "x2" y tu personaje baila mientras estás quieto adentro.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local worldRequest = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("WorldRequest")

local hud = script.Parent.Parent
local Modules = hud:WaitForChild("Modules")
local PanelManager = require(Modules.PanelManager)
local Confirm = require(Modules.Confirm)
local Toast = require(Modules.Toast)
local Sfx = require(Modules.Sfx)
local UIEffects = require(Modules.UIEffects)

local player = Players.LocalPlayer
local panels = hud:WaitForChild("Panels")
local afkBadge = hud:WaitForChild("Root"):WaitForChild("AFKBadge")

while not player:GetAttribute("StatsReady") do
	player:GetAttributeChangedSignal("StatsReady"):Wait()
end

---------------------------------------------------------------- Estaciones
local function hookStation(anchor: Instance)
	local prompt = anchor:FindFirstChildOfClass("ProximityPrompt")
	local panelName = anchor:GetAttribute("Panel")
	if not prompt or not panelName then
		return
	end
	prompt.Triggered:Connect(function()
		local panel = panels:FindFirstChild(panelName)
		if panel then
			PanelManager.Open(panel)
		end
	end)
end
for _, anchor in CollectionService:GetTagged("Station") do
	hookStation(anchor)
end
CollectionService:GetInstanceAddedSignal("Station"):Connect(hookStation)

---------------------------------------------------------------- Pantalla de carga
-- Se pasa a TeleportService para que siga visible durante el viaje
local function makeLoadingScreen(worldName: string): ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = "TravelLoading"
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 100
	gui.ResetOnSpawn = false
	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = Color3.new(1, 1, 1)
	bg.Parent = gui
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Color = ColorSequence.new(Color3.fromRGB(120, 90, 255), Color3.fromRGB(40, 20, 110))
	gradient.Parent = bg
	local text = Instance.new("TextLabel")
	text.AnchorPoint = Vector2.new(0.5, 0.5)
	text.Position = UDim2.fromScale(0.5, 0.45)
	text.Size = UDim2.fromScale(0.7, 0.1)
	text.BackgroundTransparency = 1
	text.Font = Enum.Font.FredokaOne
	text.TextScaled = true
	text.TextColor3 = Color3.new(1, 1, 1)
	text.Text = "Viajando a " .. worldName .. "…"
	text.Parent = bg
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 4
	stroke.Color = Color3.fromRGB(28, 22, 40)
	stroke.Parent = text
	local spinner = Instance.new("TextLabel")
	spinner.Name = "Spinner"
	spinner.AnchorPoint = Vector2.new(0.5, 0.5)
	spinner.Position = UDim2.fromScale(0.5, 0.6)
	spinner.Size = UDim2.fromOffset(80, 80)
	spinner.BackgroundTransparency = 1
	spinner.TextScaled = true
	spinner.Text = "🌙"
	spinner.Parent = bg
	TweenService:Create(spinner, TweenInfo.new(1.2, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), { Rotation = 360 }):Play()
	return gui
end

---------------------------------------------------------------- Plataformas-portal
local insidePortal: Instance? = nil
local busy = false

local function padRadius(part: BasePart): number
	if part.Shape == Enum.PartType.Cylinder then
		return part.Size.Y / 2 -- el cilindro está acostado: Y y Z son el diámetro
	end
	return math.max(part.Size.X, part.Size.Z) / 2
end

local function travel(portal: BasePart)
	local worldId = portal:GetAttribute("World")
	local world = GameConfig.Worlds[worldId]
	if not world or busy then
		return
	end
	busy = true
	local yes = Confirm.Ask("¿Ir a " .. world.Name .. "?", world.Description, "¡Sí, vamos!")
	if yes and insidePortal == portal then
		local loading = makeLoadingScreen(world.Name)
		loading.Parent = player.PlayerGui
		TeleportService:SetTeleportGui(loading)
		local ok, success, message, mode = pcall(worldRequest.InvokeServer, worldRequest, worldId)
		if not (ok and success) then
			loading:Destroy()
			Toast.Show(if ok then message else "Error de conexión", Toast.Bad)
		elseif mode == "local" then
			-- Viaje dentro del mismo lugar: la pantalla de carga se desvanece sola
			task.wait(1.2)
			for _, d in loading:GetDescendants() do
				if d:IsA("Frame") then
					TweenService:Create(d, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
				elseif d:IsA("TextLabel") then
					TweenService:Create(d, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
				elseif d:IsA("UIStroke") then
					TweenService:Create(d, TweenInfo.new(0.5), { Transparency = 1 }):Play()
				end
			end
			task.delay(0.6, function()
				loading:Destroy()
			end)
			Toast.Show(message, Toast.Good)
		end
	end
	busy = false
end

task.spawn(function()
	while true do
		task.wait(0.2)
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local found: BasePart? = nil
		if root then
			for _, portal in CollectionService:GetTagged("WorldPortal") do
				if portal:IsA("BasePart") then
					local offset = root.Position - portal.Position
					if Vector3.new(offset.X, 0, offset.Z).Magnitude <= padRadius(portal) and math.abs(offset.Y) < 8 then
						found = portal
						break
					end
				end
			end
		end
		if found ~= insidePortal then
			insidePortal = found
			if found then
				task.spawn(travel, found)
			elseif Confirm.IsOpen() then
				Confirm.Cancel() -- se bajó del portal: cerrar la pregunta
			end
		end
	end
end)

---------------------------------------------------------------- Zona AFK
-- Bailes oficiales de Roblox (gratis para cualquier juego, personajes R15)
local DANCES = { "rbxassetid://507771019", "rbxassetid://507776043", "rbxassetid://507777268" }
local danceTrack: AnimationTrack? = nil

local function stopDance()
	if danceTrack then
		danceTrack:Stop(0.3)
		danceTrack = nil
	end
end

local function startDance()
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if not animator or danceTrack or humanoid.RigType ~= Enum.HumanoidRigType.R15 then
		return
	end
	local animation = Instance.new("Animation")
	animation.AnimationId = DANCES[math.random(#DANCES)]
	local ok, track = pcall(animator.LoadAnimation, animator, animation)
	if ok and track then
		track.Looped = true
		track.Priority = Enum.AnimationPriority.Action
		track:Play(0.3)
		danceTrack = track
	end
end

local function refreshAFK()
	local inside = player:GetAttribute("InAFKZone") == true
	afkBadge.Visible = inside
	if inside then
		Sfx.Play("Coin", 1.3)
		Toast.Show("💤 Zona AFK: ¡ganas x" .. GameConfig.AFK.Multiplier .. "!", Toast.Good)
		UIEffects.Bump(afkBadge)
	else
		stopDance()
	end
end
player:GetAttributeChangedSignal("InAFKZone"):Connect(refreshAFK)
refreshAFK()

-- Baila solo si está quieto dentro de la zona; si camina, deja de bailar
task.spawn(function()
	local stillTime = 0
	while true do
		task.wait(0.25)
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if player:GetAttribute("InAFKZone") and humanoid then
			if humanoid.MoveDirection.Magnitude < 0.1 then
				stillTime += 0.25
				if stillTime >= 1 then
					startDance()
				end
			else
				stillTime = 0
				stopDance()
			end
		else
			stillTime = 0
		end
	end
end)

player.CharacterAdded:Connect(function()
	danceTrack = nil
end)
