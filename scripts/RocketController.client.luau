-- StarterGui/HUD/Controllers/RocketController (LocalScript)
-- Lo que VE el jugador en "Slime al Espacio":
--  * Dibuja el cohete de cada participante (con su slime de piloto) a la altura que
--    dice el servidor, con fuego, humo y luz mientras tiene combustible.
--  * Cámara que sigue a tu cohete; vibra al despegar.
--  * El cielo cambia con la altura: de día → atardecer → noche con estrellas.
--  * Líneas de velocidad, cuenta regresiva, banner al llegar a cada capa,
--    barra de progreso, ranking en vivo y tarjeta de resultados.
-- Todo es local y visual; el servidor decide las alturas y el dinero.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local Rocket = GameConfig.Rocket
local state = ReplicatedStorage:WaitForChild("RocketState")
-- Cohete caricatura (si existe); si no, el Basic de piezas
local rocketModels = ReplicatedStorage:WaitForChild("RocketModels")
local rocketTemplate = rocketModels:FindFirstChild("Cartoon") or rocketModels:WaitForChild("Basic")
local petModels = ReplicatedStorage:WaitForChild("PetModels")

local hud = script.Parent.Parent
local Modules = hud:WaitForChild("Modules")
local UIEffects = require(Modules.UIEffects)
local Sfx = require(Modules.Sfx)
local Toast = require(Modules.Toast)
local ClientSettings = require(Modules.ClientSettings)

local player = Players.LocalPlayer
local root = hud:WaitForChild("Root")
local bar = root:WaitForChild("RocketBar")
local leaders = root:WaitForChild("RocketLeaders")
local banner = root:WaitForChild("RocketBanner")
local countdown = root:WaitForChild("RocketCountdown")
local result = root:WaitForChild("RocketResult")
local toggleAuto = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RocketToggleAuto")
local FACE_CAMERA = CFrame.Angles(0, math.pi, 0) -- la ventana y el piloto miran a la cámara

local STUDS = Rocket.StudsPerMeter
local WORLD_MIN_Z = 2000

local folder = Instance.new("Folder")
folder.Name = "ClientRockets"
folder.Parent = workspace

---------------------------------------------------------------- Utilidades
local function myRoot(): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function inWorld(): boolean
	local r = myRoot()
	return r ~= nil and r.Position.Z > WORLD_MIN_Z
end

local function phase(): string
	return state:GetAttribute("Phase") or "Waiting"
end

local function timeLeft(): number
	return math.max(0, (state:GetAttribute("PhaseEndsAt") or 0) - workspace:GetServerTimeNow())
end

local function padByIndex(index: number): BasePart?
	for _, pad in CollectionService:GetTagged("LaunchPad") do
		if pad:GetAttribute("Index") == index then
			return pad
		end
	end
	return nil
end

local function formatMeters(m: number): string
	return GameConfig.FormatCommas(m) .. " m"
end

---------------------------------------------------------------- Cohetes de cada corredor
-- Un corredor es un Player o un bot (Configuration en RocketState.Bots); los dos
-- tienen los mismos atributos (RocketPad, Altitude, RocketFuel…).
type RocketEntry = { Model: Model, Pad: BasePart, Shown: number, Exhaust: Attachment, Pets: { Model }?, Roll: number }
local rockets: { [Instance]: RocketEntry } = {}
local botsFolder = state:WaitForChild("Bots")

local function racers(): { Instance }
	local list: { Instance } = {}
	for _, p in Players:GetPlayers() do
		table.insert(list, p)
	end
	for _, bot in botsFolder:GetChildren() do
		table.insert(list, bot)
	end
	return list
end

local function setCharacterHidden(p: Instance, hidden: boolean)
	if not p:IsA("Player") then
		return
	end
	local character = p.Character
	if not character then
		return
	end
	for _, d in character:GetDescendants() do
		if d:IsA("BasePart") or d:IsA("Decal") then
			d.LocalTransparencyModifier = if hidden then 1 else 0
		end
	end
end

local function pilotFor(p: Instance): string
	if p:GetAttribute("IsBot") then
		return p:GetAttribute("Pilot") or "Slime_Vanilla_1"
	end
	-- El piloto es tu primer slime equipado (o un slime de vainilla)
	local ok, equipped = pcall(HttpService.JSONDecode, HttpService, p:GetAttribute("Equipped") or "[]")
	if ok then
		for _, id in equipped do
			if string.sub(id, 1, 6) == "Slime_" then
				return id
			end
		end
	end
	return "Slime_Vanilla_1"
end

local function equippedOf(p: Player): { string }
	local ok, equipped = pcall(HttpService.JSONDecode, HttpService, p:GetAttribute("Equipped") or "[]")
	return if ok and type(equipped) == "table" then equipped else {}
end

-- Tus mascotas equipadas vuelan alrededor de TU cohete (solo el tuyo, para no pesar)
local function addEscortPets(model: Model): { Model }
	local list = {}
	for _, petId in equippedOf(player) do
		local source = petModels:FindFirstChild(petId)
		if source then
			local pet = source:Clone()
			pet:ScaleTo(pet:GetScale() * 0.9)
			for _, d in pet:GetDescendants() do
				if d:IsA("BasePart") then
					d.Anchored = true
					d.CanCollide = false
					d.CanQuery = false
					d.CanTouch = false
				elseif d:IsA("BaseScript") then
					d:Destroy()
				end
			end
			pet.Parent = model
			table.insert(list, pet)
		end
	end
	return list
end

local function removeRocket(p: Instance)
	local entry = rockets[p]
	if entry then
		entry.Model:Destroy()
		rockets[p] = nil
	end
	setCharacterHidden(p, false)
end

local function ensureRocket(p: Instance)
	local padIndex = p:GetAttribute("RocketPad") or 0
	if padIndex == 0 then
		removeRocket(p)
		return
	end
	local pad = padByIndex(padIndex)
	if not pad then
		return
	end
	if rockets[p] and rockets[p].Pad == pad then
		return
	end
	removeRocket(p)
	local model = rocketTemplate:Clone()
	model.Name = "Rocket_" .. p.Name
	-- Color de cohete: cada jugador el suyo (según su UserId), los bots según su nombre
	local body = model:FindFirstChild("Body")
	local mesh = body and body:FindFirstChildOfClass("SpecialMesh")
	if mesh then
		local colors = Rocket.Colors
		local index = if p:IsA("Player") then p.UserId % #colors + 1 else #p.Name % #colors + 1
		local c = colors[index]
		mesh.VertexColor = Vector3.new(c.R, c.G, c.B)
	end
	local pilotSource = petModels:FindFirstChild(pilotFor(p))
	if pilotSource then
		local pilot = pilotSource:Clone()
		pilot:ScaleTo(pilot:GetScale() * 0.6)
		local attach = model.Root:FindFirstChild("Pilot")
		pilot:PivotTo(model.Root.CFrame * attach.CFrame)
		for _, d in pilot:GetDescendants() do
			if d:IsA("BasePart") then
				d.Anchored = false
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = model.Root
				weld.Part1 = d
				weld.Parent = d
			end
		end
		pilot.Parent = model
	end
	model:PivotTo(CFrame.new(pad.Position + Vector3.new(0, 0.3 + 5, 0)) * FACE_CAMERA)
	model.Parent = folder
	rockets[p] = { Model = model, Pad = pad, Shown = 0, Exhaust = model.Root.Exhaust, Pets = if p == player then addEscortPets(model) else nil, Roll = 0 }
	setCharacterHidden(p, true)
end

local function track(p: Instance)
	p:GetAttributeChangedSignal("RocketPad"):Connect(function()
		ensureRocket(p)
	end)
	ensureRocket(p)
end
for _, p in racers() do
	track(p)
end
Players.PlayerAdded:Connect(track)
Players.PlayerRemoving:Connect(removeRocket)
botsFolder.ChildAdded:Connect(track)
botsFolder.ChildRemoved:Connect(removeRocket)

-- Revisión de respaldo: si algún aviso se perdió, cada medio segundo se
-- confirma que cada quien tenga (o no) su cohete
task.spawn(function()
	while true do
		task.wait(0.5)
		for _, p in racers() do
			local hasPad = (p:GetAttribute("RocketPad") or 0) > 0
			if hasPad ~= (rockets[p] ~= nil) then
				ensureRocket(p)
			end
		end
	end
end)

---------------------------------------------------------------- Cielo según la altura
local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
local baseLighting = {
	ClockTime = Lighting.ClockTime,
	Density = atmosphere and atmosphere.Density or 0,
	Ambient = Lighting.Ambient,
	OutdoorAmbient = Lighting.OutdoorAmbient,
}
local SPACE_AMBIENT = Color3.fromRGB(170, 170, 200) -- en el espacio los cohetes siguen viéndose
-- Cielos por capa: el de siempre → Espacio (1500 m) → Galaxia (7000 m)
local skyBoxes = ReplicatedStorage:WaitForChild("SkyBoxes")
local defaultSky = Lighting:FindFirstChildOfClass("Sky")
local currentSkyName: string? = nil
local activeSky: Sky? = nil
local function setSkyBox(name: string?)
	if name == currentSkyName then
		return
	end
	currentSkyName = name
	if activeSky then
		activeSky:Destroy()
		activeSky = nil
	end
	if name then
		if defaultSky then
			defaultSky.Parent = nil
		end
		activeSky = skyBoxes[name]:Clone()
		activeSky.Parent = Lighting
	elseif defaultSky then
		defaultSky.Parent = Lighting
	end
end

-- Tinte de color de la pantalla según la capa (azulado en el espacio, morado en la galaxia)
local tint = Instance.new("ColorCorrectionEffect")
tint.Name = "RocketTint"
tint.Enabled = false
tint.Parent = Lighting

local function applySky(altitude: number)
	local skyName = if altitude >= 7000 then "Galaxy" elseif altitude >= 1500 then "Space" else nil
	setSkyBox(skyName)
	-- 600 m (arcoíris) → 1500 m (espacio): el cielo se oscurece. Ya con el cielo de
	-- espacio se regresa a "día" (sin sol) porque Roblox oscurece los cielos de noche.
	local t = math.clamp((altitude - 600) / 900, 0, 1)
	Lighting.ClockTime = if skyName then baseLighting.ClockTime else baseLighting.ClockTime + (24 - baseLighting.ClockTime) * t * 0.99
	tint.Enabled = skyName ~= nil
	if skyName == "Galaxy" then
		tint.TintColor = Color3.fromRGB(225, 185, 255) -- galaxia: bien morada
		tint.Saturation = 0.35
		tint.Contrast = 0.1
	else
		tint.TintColor = Color3.fromRGB(220, 230, 255)
		tint.Saturation = 0.15
		tint.Contrast = 0
	end
	if atmosphere then
		atmosphere.Density = baseLighting.Density * (1 - t)
	end
	Lighting.Ambient = baseLighting.Ambient:Lerp(SPACE_AMBIENT, t)
	Lighting.OutdoorAmbient = baseLighting.OutdoorAmbient:Lerp(SPACE_AMBIENT, t)
end
local function resetSky()
	setSkyBox(nil)
	tint.Enabled = false
	Lighting.ClockTime = baseLighting.ClockTime
	if atmosphere then
		atmosphere.Density = baseLighting.Density
	end
	Lighting.Ambient = baseLighting.Ambient
	Lighting.OutdoorAmbient = baseLighting.OutdoorAmbient
end

---------------------------------------------------------------- Líneas de velocidad
-- Partículas que "caen" junto al cohete para sentir que subes rápido
local speedPart = Instance.new("Part")
speedPart.Name = "SpeedLines"
speedPart.Size = Vector3.new(30, 1, 30)
speedPart.Transparency = 1
speedPart.Anchored = true
speedPart.CanCollide = false
speedPart.CanQuery = false
speedPart.CanTouch = false
speedPart.Parent = folder
local speedLines = Instance.new("ParticleEmitter")
speedLines.Texture = "rbxasset://textures/particles/sparkles_main.dds"
speedLines.Color = ColorSequence.new(Color3.new(1, 1, 1))
speedLines.LightEmission = 1
speedLines.Size = NumberSequence.new(0.3)
speedLines.Squash = NumberSequence.new(-2.5) -- estiradas: parecen rayas de velocidad
speedLines.Orientation = Enum.ParticleOrientation.VelocityParallel
speedLines.Transparency = NumberSequence.new(0.2, 1)
speedLines.Lifetime = NumberRange.new(0.5, 0.9)
speedLines.Speed = NumberRange.new(80, 120)
speedLines.EmissionDirection = Enum.NormalId.Bottom
speedLines.Rate = 0
speedLines.Parent = speedPart
-- Texturas tomadas de la Creator Store (solo el ID de la imagen; los modelos traían malware)
local TEX_SOFT_STAR = "rbxassetid://6822501679" -- estrella suave
local TEX_SPARKLE_STAR = "rbxassetid://1084970835" -- estrella de 4 puntas
local TEX_CARTOON_SMOKE = "rbxassetid://5253615811" -- nube de humo caricatura
local starDust = Instance.new("ParticleEmitter")
starDust.Texture = TEX_SOFT_STAR
starDust.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(150, 200, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 160, 230)),
})
starDust.LightEmission = 1
starDust.Size = NumberSequence.new(0.9, 0)
starDust.Lifetime = NumberRange.new(2.5, 4)
starDust.Speed = NumberRange.new(10, 25)
starDust.EmissionDirection = Enum.NormalId.Bottom
starDust.SpreadAngle = Vector2.new(30, 30)
starDust.Rate = 0
starDust.Parent = speedPart

---------------------------------------------------------------- Despegue: nube de humo caricatura + llamarada
local launchPart = Instance.new("Part")
launchPart.Name = "LaunchFX"
launchPart.Size = Vector3.new(1, 1, 1)
launchPart.Transparency = 1
launchPart.Anchored = true
launchPart.CanCollide = false
launchPart.CanQuery = false
launchPart.CanTouch = false
launchPart.Parent = folder
local launchSmoke = Instance.new("ParticleEmitter")
launchSmoke.Texture = TEX_CARTOON_SMOKE
launchSmoke.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(220, 220, 235))
launchSmoke.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(0.3, 6), NumberSequenceKeypoint.new(1, 8) })
launchSmoke.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.7, 0.2), NumberSequenceKeypoint.new(1, 1) })
launchSmoke.Lifetime = NumberRange.new(1.5, 2.5)
launchSmoke.Speed = NumberRange.new(15, 30)
launchSmoke.Drag = 3
launchSmoke.SpreadAngle = Vector2.new(180, 15) -- sale hacia los lados, a ras del suelo
launchSmoke.EmissionDirection = Enum.NormalId.Right
launchSmoke.Rotation = NumberRange.new(0, 360)
launchSmoke.RotSpeed = NumberRange.new(-120, 120)
launchSmoke.Rate = 0
launchSmoke.Parent = launchPart
local launchFire = Instance.new("ParticleEmitter")
launchFire.Texture = "rbxasset://textures/particles/fire_main.dds"
launchFire.Color = ColorSequence.new(Color3.fromRGB(255, 230, 120), Color3.fromRGB(255, 80, 30))
launchFire.LightEmission = 1
launchFire.Size = NumberSequence.new(5, 0)
launchFire.Lifetime = NumberRange.new(0.4, 0.8)
launchFire.Speed = NumberRange.new(25, 40)
launchFire.Drag = 4
launchFire.SpreadAngle = Vector2.new(180, 10)
launchFire.EmissionDirection = Enum.NormalId.Right
launchFire.Rate = 0
launchFire.Parent = launchPart
local function launchBurst(pad: BasePart)
	if not UIEffects.Fancy() then
		return
	end
	launchPart.Position = pad.Position + Vector3.new(0, 1.5, 0)
	launchSmoke:Emit(45)
	launchFire:Emit(60)
end

-- Estrellas que salen del cohete con turbo
local turboStars = Instance.new("ParticleEmitter")
turboStars.Texture = TEX_SPARKLE_STAR
turboStars.Color = ColorSequence.new(Color3.fromRGB(255, 255, 140), Color3.fromRGB(140, 230, 255))
turboStars.LightEmission = 1
turboStars.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.3, 1.6), NumberSequenceKeypoint.new(1, 0) })
turboStars.Lifetime = NumberRange.new(0.6, 1.1)
turboStars.Speed = NumberRange.new(8, 16)
turboStars.SpreadAngle = Vector2.new(180, 180)
turboStars.RotSpeed = NumberRange.new(-180, 180)
turboStars.Rate = 0

---------------------------------------------------------------- Destello y anillo al cambiar de capa
local layerFlash = root:WaitForChild("NukeFlash")
local function layerBurst(color: Color3, rocketModel: Model?)
	if not UIEffects.Fancy() then
		return
	end
	layerFlash.Visible = true
	layerFlash.BackgroundColor3 = color
	layerFlash.BackgroundTransparency = 0.55
	TweenService:Create(layerFlash, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
	task.delay(0.5, function()
		layerFlash.BackgroundColor3 = Color3.new(1, 1, 1)
	end)
	if rocketModel then
		local ring = Instance.new("Part")
		ring.Shape = Enum.PartType.Cylinder
		ring.Anchored = true
		ring.CanCollide = false
		ring.CanQuery = false
		ring.Material = Enum.Material.Neon
		ring.Color = color
		ring.Size = Vector3.new(0.4, 6, 6)
		ring.CFrame = CFrame.new(rocketModel:GetPivot().Position) * CFrame.Angles(0, 0, math.rad(90))
		ring.Parent = folder
		TweenService:Create(ring, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(0.4, 60, 60), Transparency = 1 }):Play()
		task.delay(0.7, function()
			ring:Destroy()
		end)
	end
end

---------------------------------------------------------------- Línea de "Tu récord"
local recordTarget = 0 -- tu mejor altura ANTES de esta ronda
local recordBeaten = false
local recordLine = Instance.new("Part")
recordLine.Name = "RecordLine"
recordLine.Anchored = true
recordLine.CanCollide = false
recordLine.CanQuery = false
recordLine.CanTouch = false
recordLine.Material = Enum.Material.Neon
recordLine.Color = Color3.fromRGB(255, 210, 60)
recordLine.Size = Vector3.new(70, 0.4, 0.4)
recordLine.Transparency = 1
recordLine.Parent = folder
local recordSign = Instance.new("BillboardGui")
recordSign.Size = UDim2.fromOffset(260, 40)
recordSign.StudsOffset = Vector3.new(0, 2, 0)
recordSign.LightInfluence = 0
recordSign.Enabled = false
recordSign.Parent = recordLine
local recordText = Instance.new("TextLabel")
recordText.Size = UDim2.fromScale(1, 1)
recordText.BackgroundTransparency = 1
recordText.Font = Enum.Font.FredokaOne
recordText.TextScaled = true
recordText.TextColor3 = Color3.fromRGB(255, 220, 80)
recordText.Text = "🏆 Tu récord"
recordText.Parent = recordSign
local recordStroke = Instance.new("UIStroke")
recordStroke.Thickness = 3
recordStroke.Color = Color3.fromRGB(28, 22, 40)
recordStroke.Parent = recordText

---------------------------------------------------------------- Dopamina: números flotantes, hitos, turbo
-- Texto que sale del cohete, sube y se desvanece ("+$120", "⭐ +2 XP", "🎉 1,000 m!")
local function floatText(model: Model, text: string, color: Color3, big: boolean?)
	if not UIEffects.Fancy() then
		return
	end
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one * 0.2
	anchor.Position = model:GetPivot().Position + Vector3.new(math.random(-5, 5), math.random(0, 4), 3)
	anchor.Parent = folder
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(if big then 260 else 160, if big then 60 else 40)
	gui.LightInfluence = 0
	gui.AlwaysOnTop = true
	gui.Parent = anchor
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = color
	label.Text = text
	label.Parent = gui
	local textStroke = Instance.new("UIStroke")
	textStroke.Thickness = 3
	textStroke.Color = Color3.fromRGB(28, 22, 40)
	textStroke.Parent = label
	local scale = Instance.new("UIScale")
	scale.Scale = 0.3
	scale.Parent = label
	TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	TweenService:Create(anchor, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = anchor.Position + Vector3.new(0, 10, 0) }):Play()
	task.delay(0.7, function()
		TweenService:Create(label, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
		TweenService:Create(textStroke, TweenInfo.new(0.5), { Transparency = 1 }):Play()
	end)
	task.delay(1.3, function()
		anchor:Destroy()
	end)
end

-- Onda expansiva (turbo, hitos): anillo neón que crece bajo el cohete
local function shockRing(model: Model, color: Color3, size: number)
	if not UIEffects.Fancy() then
		return
	end
	local ring = Instance.new("Part")
	ring.Shape = Enum.PartType.Cylinder
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.Material = Enum.Material.Neon
	ring.Color = color
	ring.Transparency = 0.2
	ring.Size = Vector3.new(0.3, 4, 4)
	ring.CFrame = CFrame.new(model:GetPivot().Position + Vector3.new(0, -3, 0)) * CFrame.Angles(0, 0, math.rad(90))
	ring.Parent = folder
	TweenService:Create(ring, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(0.3, size, size), Transparency = 1 }):Play()
	task.delay(0.6, function()
		ring:Destroy()
	end)
end

-- Colores normales (del modelo) y de turbo
local BASE_FIRE = rocketTemplate.Root.Exhaust.Fire.Color
local baseTrail = rocketTemplate.Root:FindFirstChild("Trail")
local BASE_TRAIL = if baseTrail then baseTrail.Color else ColorSequence.new(Color3.new(1, 1, 1))
local RAINBOW = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)),
	ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 180, 60)),
	ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 250, 90)),
	ColorSequenceKeypoint.new(0.6, Color3.fromRGB(90, 255, 120)),
	ColorSequenceKeypoint.new(0.8, Color3.fromRGB(80, 170, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 90, 255)),
})
local TURBO_FIRE = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
	ColorSequenceKeypoint.new(0.4, Color3.fromRGB(120, 220, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 80, 255)),
})
local MILESTONE = 500 -- cada 500 m sale un "🎉 500 m!"
local lastMilestone = 0
local lastMoney = player:GetAttribute("Money") or 0
local lastXP = player:GetAttribute("XP") or 0
local lastBoostUntil = 0
local speedShown = 0 -- m/s suavizado para el velocímetro
local lastAltitude = 0
local baseFov = workspace.CurrentCamera.FieldOfView

---------------------------------------------------------------- Interfaz
local lastLayerIndex = 1
local function showBanner(text: string)
	banner.Text = text
	banner.Visible = true
	banner.UIScale.Scale = 0.3
	TweenService:Create(banner.UIScale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = ClientSettings.GetUIScale() }):Play()
	Sfx.Play("Claim", 1.2)
	UIEffects.Confetti(root, banner, 30)
	task.delay(2, function()
		if banner.Text == text then
			banner.Visible = false
		end
	end)
end

local lastCount = -1
local function updateCountdown()
	if phase() ~= "Prepare" then
		countdown.Visible = false
		lastCount = -1
		return
	end
	local n = math.ceil(timeLeft())
	if n <= 3 and n ~= lastCount then
		lastCount = n
		countdown.Visible = true
		countdown.Text = if n <= 0 then "¡DESPEGUE!" else tostring(n)
		countdown.UIScale.Scale = 1.6 * ClientSettings.GetUIScale()
		TweenService:Create(countdown.UIScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = ClientSettings.GetUIScale() }):Play()
		Sfx.Play("Beep", if n <= 0 then 1.5 else 1)
	end
end

local function updateLeaders()
	local ok, list = pcall(HttpService.JSONDecode, HttpService, state:GetAttribute("Leaderboard") or "[]")
	list = if ok and type(list) == "table" then list else {}
	local medals = { "🥇", "🥈", "🥉" }
	for i = 1, 3 do
		local entry = list[i]
		leaders["Row" .. i].Text = if entry then medals[i] .. " " .. entry.Name .. "  " .. formatMeters(entry.Altitude) else ""
	end
end
state:GetAttributeChangedSignal("Leaderboard"):Connect(updateLeaders)

local function showResult()
	local altitude = player:GetAttribute("Altitude") or 0
	local layer = GameConfig.RocketLayerAt(altitude)
	result.Title.Text = "¡Llegaste a " .. formatMeters(altitude) .. "!"
	result.LayerText.Text = layer.Icon .. " " .. layer.Name
	result.RewardText.Text = "+$" .. GameConfig.FormatCommas(player:GetAttribute("LastRocketReward") or 0)
	-- Lo que pusieron tus mascotas (para que se note tenerlas)
	local petPart = player:GetAttribute("LastRocketPetBonus") or 0
	if petPart > 0 then
		task.delay(0.6, function()
			Toast.Show("🐾 ¡Tus mascotas te dieron +$" .. GameConfig.FormatCommas(petPart) .. "!", Toast.Good)
		end)
	end
	result.Visible = true
	result.UIScale.Scale = 0.3
	TweenService:Create(result.UIScale, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = ClientSettings.GetUIScale() }):Play()
	Sfx.Play("Coin")
	UIEffects.Confetti(root, result, 50)
end
state:GetAttributeChangedSignal("Phase"):Connect(function()
	local p = phase()
	local playing = (player:GetAttribute("RocketPad") or 0) > 0
	if p == "Prepare" then
		result.Visible = false
		-- Ronda variada: si despegan desde arriba, no repetir los avisos de capas de abajo
		local start = state:GetAttribute("StartAltitude") or 0
		local _, _, startIndex = GameConfig.RocketLayerAt(start)
		lastLayerIndex = startIndex
		if playing then
			for _, v in Rocket.StartVariants do
				if v.Id == state:GetAttribute("StartVariant") and v.Altitude > 0 then
					showBanner(v.Icon .. " ¡Ronda desde " .. v.Name .. "!")
				end
			end
			-- Recordatorio de lo que dan tus mascotas
			local petText = GameConfig.PetStatText({ Rocket = player:GetAttribute("PetRocket"), Boost = player:GetAttribute("PetBoost"), XP = player:GetAttribute("PetXP") })
			Toast.Show(if petText ~= "" then "🐾 Tus mascotas: " .. petText else "🐾 ¡Equipa mascotas para volar más rápido y ganar más!", if petText ~= "" then Toast.Good else nil)
		end
		lastMilestone = 0
		lastAltitude = 0
		recordTarget = player:GetAttribute("Stat_RocketBest") or 0
		recordBeaten = false
	elseif p == "Flight" and playing then
		Sfx.Play("RocketLaunch", 1)
		local mine = rockets[player]
		if mine then
			launchBurst(mine.Pad)
		end
	elseif p == "Results" and playing then
		task.wait(0.4) -- deja que llegue el premio del servidor
		showResult()
	elseif p == "Waiting" then
		result.Visible = false
	end
end)

---------------------------------------------------------------- Bucle de cada cuadro
local camera = workspace.CurrentCamera
local controllingCamera = false
local flightStart = 0

RunService.RenderStepped:Connect(function(dt)
	local here = inWorld()
	bar.Visible = here
	leaders.Visible = here and phase() ~= "Waiting"
	if not here then
		if controllingCamera then
			controllingCamera = false
			camera.CameraType = Enum.CameraType.Custom
			resetSky()
		end
		speedLines.Rate = 0
		return
	end

	local currentPhase = phase()
	if currentPhase == "Flight" and flightStart == 0 then
		flightStart = os.clock()
	elseif currentPhase ~= "Flight" then
		flightStart = 0
	end

	-- Mover todos los cohetes (suave hacia la altura del servidor)
	for p, entry in rockets do
		local target = p:GetAttribute("Altitude") or 0
		entry.Shown += (target - entry.Shown) * math.min(1, dt * 4)
		local wobble = if currentPhase == "Flight" then math.sin(os.clock() * 9) * 0.05 else 0
		entry.Roll = math.max(0, entry.Roll - dt * 2) -- giro de turbo: una vuelta en 0.5 s
		local spin = if entry.Roll > 0 then (1 - entry.Roll) * math.pi * 2 else 0
		local stunned = (p:GetAttribute("RocketStunUntil") or 0) > workspace:GetServerTimeNow()
		local boosted = (p:GetAttribute("RocketBoostUntil") or 0) > workspace:GetServerTimeNow()
		local burning = currentPhase == "Flight" and (p:GetAttribute("RocketFuel") or 0) > 0 and not stunned
		local stunTilt = if stunned then math.sin(os.clock() * 20) * 0.25 else 0 -- tambalea si lo trollearon
		local rocketCFrame = CFrame.new(entry.Pad.Position + Vector3.new(0, 5.3 + entry.Shown * STUDS, 0)) * FACE_CAMERA * CFrame.Angles(0, spin, wobble + stunTilt)
		entry.Model:PivotTo(rocketCFrame)
		-- Mascotas en órbita alrededor de tu cohete (más rápido con turbo)
		if entry.Pets then
			local count = #entry.Pets
			local orbit = os.clock() * (if burning then (if boosted then 3.5 else 2) else 0.8)
			for i, pet in entry.Pets do
				local angle = orbit + (i / count) * math.pi * 2
				local offset = Vector3.new(math.cos(angle) * 8, math.sin(os.clock() * 3 + i) * 1.2 - 1, math.sin(angle) * 5)
				pet:PivotTo(CFrame.new(rocketCFrame.Position + offset) * CFrame.Angles(0, -angle, 0))
			end
		end
		-- Turbo: fuego azul-morado y estela arcoíris
		entry.Exhaust.Fire.Color = if boosted then TURBO_FIRE else BASE_FIRE
		entry.Exhaust.Fire.Enabled = burning
		local flameFX = entry.Exhaust:FindFirstChild("FlameFX")
		if flameFX then
			flameFX.Enabled = burning
		end
		entry.Exhaust.Smoke.Enabled = burning
		entry.Exhaust.EngineLight.Enabled = burning
		local trail = entry.Model.Root:FindFirstChild("Trail")
		if trail then
			trail.Enabled = burning
			trail.Color = if boosted then RAINBOW else BASE_TRAIL
		end
	end

	-- Mi cohete: cámara, cielo, líneas de velocidad, barra
	local mine = rockets[player]
	local altitude = if mine then mine.Shown else 0
	if mine then
		controllingCamera = true
		camera.CameraType = Enum.CameraType.Scriptable
		local rocketPos = mine.Model:GetPivot().Position
		local shake = Vector3.zero
		if flightStart > 0 and os.clock() - flightStart < 2.5 then
			shake = Vector3.new(math.random() - 0.5, math.random() - 0.5, 0) * 0.6
		end
		-- Cohete en la parte de abajo de la pantalla: así se ve lo que viene arriba
		local desired = CFrame.lookAt(rocketPos + Vector3.new(0, 2, 40) + shake, rocketPos + Vector3.new(0, 12, 0))
		camera.CFrame = camera.CFrame:Lerp(desired, math.min(1, dt * 6))
		-- Velocidad (m/s) para el velocímetro y para abrir la cámara (se siente más rápido)
		if dt > 0 then
			local instant = math.max(0, (mine.Shown - lastAltitude) / dt)
			speedShown += (instant - speedShown) * math.min(1, dt * 3)
		end
		lastAltitude = mine.Shown
		local boostedMe = (player:GetAttribute("RocketBoostUntil") or 0) > workspace:GetServerTimeNow()
		local fovTarget = if currentPhase == "Flight" then baseFov + math.min(18, speedShown / 8) + (if boostedMe then 10 else 0) else baseFov
		camera.FieldOfView += (fovTarget - camera.FieldOfView) * math.min(1, dt * 4)
		if currentPhase == "Flight" then
			-- Turbo recién activado: giro, onda y "¡TURBO!"
			local boostUntil = player:GetAttribute("RocketBoostUntil") or 0
			if boostUntil > lastBoostUntil + 0.5 and boostedMe then
				mine.Roll = 1
				shockRing(mine.Model, Color3.fromRGB(120, 220, 255), 40)
				floatText(mine.Model, "⚡ ¡TURBO!", Color3.fromRGB(120, 230, 255), true)
			end
			lastBoostUntil = boostUntil
			if turboStars.Parent ~= mine.Model.Root then
				turboStars.Parent = mine.Model.Root
			end
			turboStars.Rate = if boostedMe and UIEffects.Fancy() then 40 else 0
			-- Hitos cada 500 m
			local milestone = math.floor(mine.Shown / MILESTONE) * MILESTONE
			if milestone > lastMilestone and milestone > 0 then
				lastMilestone = milestone
				floatText(mine.Model, "🎉 " .. GameConfig.FormatCommas(milestone) .. " m!", Color3.fromRGB(255, 240, 120), true)
				shockRing(mine.Model, Color3.fromRGB(255, 220, 80), 30)
				Sfx.Play("Coin", 1 + math.min(1, milestone / 15000))
				UIEffects.Bump(bar.AltitudeText)
			end
		end
		-- "+$" y "+XP" flotantes cada vez que ganas en vuelo
		local money = player:GetAttribute("Money") or 0
		if currentPhase == "Flight" and money > lastMoney then
			floatText(mine.Model, "+$" .. GameConfig.FormatNumber(money - lastMoney), Color3.fromRGB(120, 255, 110))
		end
		lastMoney = money
		local xp = player:GetAttribute("XP") or 0
		if currentPhase == "Flight" and xp > lastXP then
			floatText(mine.Model, "⭐ +" .. (xp - lastXP) .. " XP", Color3.fromRGB(150, 210, 255))
		end
		lastXP = xp
		bar.SpeedText.Text = if currentPhase == "Flight" then "🚀 " .. math.floor(speedShown) .. " m/s" else ""
		applySky(altitude)
		local burning = currentPhase == "Flight" and (player:GetAttribute("RocketFuel") or 0) > 0
		speedPart.Position = rocketPos + Vector3.new(0, 45, 0)
		local fancy = UIEffects.Fancy()
		speedLines.Rate = if burning and fancy then (if boosted then 260 else 120) else 0
		starDust.Rate = if fancy and altitude >= 1500 then 35 else 0
		-- Motor: suena mientras hay combustible; más agudo con turbo
		local boosted = (player:GetAttribute("RocketBoostUntil") or 0) > workspace:GetServerTimeNow()
		Sfx.SetLoop("RocketEngine", burning, if boosted then 1.25 else 0.9)
		-- Línea de tu récord (solo si ya tienes uno)
		if recordTarget > 0 and not recordBeaten then
			recordLine.Transparency = 0.2
			recordSign.Enabled = true
			recordText.Text = "🏆 Tu récord: " .. formatMeters(recordTarget)
			recordLine.Position = Vector3.new(mine.Pad.Position.X, mine.Pad.Position.Y + 5.3 + recordTarget * STUDS, mine.Pad.Position.Z + 3)
			if altitude > recordTarget then
				recordBeaten = true
				recordLine.Transparency = 1
				recordSign.Enabled = false
				showBanner("🏆 ¡NUEVO RÉCORD!")
				layerBurst(Color3.fromRGB(255, 210, 60), mine.Model)
			end
		else
			recordLine.Transparency = 1
			recordSign.Enabled = false
		end
	elseif controllingCamera then
		controllingCamera = false
		camera.CameraType = Enum.CameraType.Custom
		resetSky()
		camera.FieldOfView = baseFov
		bar.SpeedText.Text = ""
		speedLines.Rate = 0
		starDust.Rate = 0
		Sfx.SetLoop("RocketEngine", false)
		recordLine.Transparency = 1
		recordSign.Enabled = false
	end

	-- Barra de ronda
	local left = math.ceil(timeLeft())
	if not mine and player:GetAttribute("RocketAuto") == false then
		bar.PhaseText.Text = "⏸ Auto apagado · camina al portal 🏠 o actívalo"
	elseif currentPhase == "Waiting" then
		bar.PhaseText.Text = "Esperando la siguiente ronda…"
	elseif currentPhase == "Prepare" then
		bar.PhaseText.Text = if mine then "🚀 ¡Despegue en " .. left .. "!" else "⏳ Próxima ronda en " .. left .. "s"
	elseif currentPhase == "Flight" then
		local fuel = player:GetAttribute("RocketFuel") or 0
		bar.PhaseText.Text = if not mine then "👀 Mirando · entras la próxima ronda"
			elseif fuel > 0 then "⛽ Combustible " .. math.ceil(fuel) .. "s · ronda " .. left .. "s"
			else "🪂 Sin combustible · ronda " .. left .. "s"
	elseif currentPhase == "Results" then
		bar.PhaseText.Text = "🏁 ¡Resultados!"
	end
	bar.AltitudeText.Text = formatMeters(math.floor(altitude))

	local layer, nextLayer, index = GameConfig.RocketLayerAt(altitude)
	bar.CurrentIcon.Text = layer.Icon
	if nextLayer then
		bar.NextIcon.Text = nextLayer.Icon
		bar.LayerBar.LayerText.Text = layer.Name .. " → " .. nextLayer.Name
		local progress = (altitude - layer.Altitude) / (nextLayer.Altitude - layer.Altitude)
		bar.LayerBar.Fill.Size = UDim2.fromScale(math.clamp(progress, 0, 1), 1)
	else
		bar.NextIcon.Text = "🏆"
		bar.LayerBar.LayerText.Text = layer.Name .. " · ¡MÁXIMO!"
		bar.LayerBar.Fill.Size = UDim2.fromScale(1, 1)
	end
	if mine and index > lastLayerIndex then
		lastLayerIndex = index
		showBanner(layer.Icon .. " ¡" .. string.upper(layer.Name) .. "!")
		layerBurst(layer.SkyTop, mine.Model)
	end

	updateCountdown()
end)

-- Botón de modo automático
local autoButton = bar:WaitForChild("AutoButton")
local function refreshAuto()
	local on = player:GetAttribute("RocketAuto") ~= false
	autoButton.Label.Text = if on then "🤖 Auto: SÍ" else "🤖 Auto: NO"
	autoButton.UIGradient.Color = if on
		then ColorSequence.new(Color3.fromRGB(120, 255, 80), Color3.fromRGB(30, 190, 40))
		else ColorSequence.new(Color3.fromRGB(255, 90, 100), Color3.fromRGB(200, 25, 45))
end
autoButton.Activated:Connect(function()
	toggleAuto:FireServer()
end)
player:GetAttributeChangedSignal("RocketAuto"):Connect(refreshAuto)
refreshAuto()
UIEffects.AttachButton(autoButton)

-- Escala de la UI del cohete según pantalla y ajustes
local function applyScale()
	local s = ClientSettings.GetUIScale()
	bar.UIScale.Scale = s
	leaders.UIScale.Scale = s
end
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(applyScale)
ClientSettings.Changed:Connect(applyScale)
applyScale()
updateLeaders()
