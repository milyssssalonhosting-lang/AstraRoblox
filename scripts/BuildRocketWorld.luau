-- Herramienta (no va dentro del juego): construye el Mundo Cohete ("Slime al Espacio")
-- lejos del lobby (z = 3000) y el modelo de cohete en ReplicatedStorage.RocketModels.
-- Se puede volver a correr: borra y rehace. Cuando el juego se publique, esta
-- carpeta se moverá a su propio lugar.

local CollectionService = game:GetService("CollectionService")
local GameConfig = require(game.ReplicatedStorage.Shared.GameConfig)
local lib = game.ServerStorage.AssetLibrary
local lp = lib.LowPoly
local rng = Random.new(77)

local ORIGIN = Vector3.new(0, 0, 3000)
local PADS = 12
local PAD_SPACING = 14
local STUDS_PER_METER = GameConfig.Rocket.StudsPerMeter
local FONT = Enum.Font.FredokaOne

local old = workspace:FindFirstChild("RocketWorld")
if old then
	old:Destroy()
end
local world = Instance.new("Folder")
world.Name = "RocketWorld"

local function part(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for k, v in props do
		p[k] = v
	end
	return p
end

local function folder(name, parent)
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent or world
	return f
end

local function place(index, parent, position, rotY, scale)
	local model = lp["Group" .. index]:Clone()
	if model:IsA("BasePart") then
		local wrap = Instance.new("Model")
		model.Parent = wrap
		model = wrap
	end
	if scale and scale ~= 1 then
		model:ScaleTo(model:GetScale() * scale)
	end
	local cf, size = model:GetBoundingBox()
	local pivotOffset = model:GetPivot().Position - cf.Position
	model:PivotTo(CFrame.new(position.X, position.Y + size.Y / 2 + pivotOffset.Y, position.Z) * CFrame.Angles(0, math.rad(rotY or 0), 0))
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
		end
	end
	model.Parent = parent
	return model
end

local function sign(position: Vector3, title: string, subtitle: string?, color: Color3, parent: Instance)
	local anchor = part({ Name = "SignAnchor", Size = Vector3.new(0.2, 0.2, 0.2), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, Position = position })
	local bb = Instance.new("BillboardGui")
	bb.Name = "Sign"
	bb.Size = UDim2.fromScale(11, 3.5)
	bb.MaxDistance = 200
	bb.LightInfluence = 0
	bb.Adornee = anchor
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 0.6)
	t.Font = FONT
	t.TextScaled = true
	t.Text = title
	t.TextColor3 = color
	t.Parent = bb
	local st = Instance.new("UIStroke")
	st.Thickness = 3
	st.Color = Color3.fromRGB(28, 22, 40)
	st.Parent = t
	if subtitle then
		local s2 = t:Clone()
		s2.Text = subtitle
		s2.TextColor3 = Color3.new(1, 1, 1)
		s2.Position = UDim2.fromScale(0, 0.6)
		s2.Size = UDim2.fromScale(1, 0.4)
		s2.Parent = bb
	end
	bb.Parent = anchor
	anchor.Parent = parent
end

---------------------------------------------------------------- Isla y plataforma
local ground = folder("Ground")
part({ Name = "Island", Size = Vector3.new(320, 4, 320), Position = ORIGIN + Vector3.new(0, -2, 0), Color = Color3.fromRGB(110, 200, 70) }).Parent = ground
part({
	Name = "LaunchDeck",
	Size = Vector3.new(PADS * PAD_SPACING + 16, 1, 30),
	Position = ORIGIN + Vector3.new(0, 0.5, 0),
	Color = Color3.fromRGB(235, 215, 170),
}).Parent = ground

local pads = folder("LaunchPads")
for i = 1, PADS do
	local x = (i - (PADS + 1) / 2) * PAD_SPACING
	local pad = part({
		Name = "Pad" .. i,
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.6, 10, 10),
		CFrame = CFrame.new(ORIGIN + Vector3.new(x, 1.2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = if i % 2 == 0 then Color3.fromRGB(255, 150, 90) else Color3.fromRGB(120, 200, 255),
	})
	pad:SetAttribute("Index", i)
	CollectionService:AddTag(pad, "LaunchPad")
	pad.Parent = pads
end

-- Torre de lanzamiento (decoración) a cada lado
for _, side in { -1, 1 } do
	local x = side * (PADS * PAD_SPACING / 2 + 14)
	local tower = Instance.new("Model")
	tower.Name = "Tower"
	for level = 0, 5 do
		part({ Size = Vector3.new(6, 1, 6), Position = ORIGIN + Vector3.new(x, 4 + level * 6, 0), Color = Color3.fromRGB(255, 90, 100) }).Parent = tower
	end
	for _, c in { Vector3.new(-2.5, 0, -2.5), Vector3.new(2.5, 0, -2.5), Vector3.new(-2.5, 0, 2.5), Vector3.new(2.5, 0, 2.5) } do
		part({ Size = Vector3.new(0.8, 36, 0.8), Position = ORIGIN + Vector3.new(x, 18, 0) + c, Color = Color3.fromRGB(240, 240, 250) }).Parent = tower
	end
	part({ Name = "Beacon", Shape = Enum.PartType.Ball, Size = Vector3.new(3, 3, 3), Position = ORIGIN + Vector3.new(x, 38, 0), Color = Color3.fromRGB(255, 220, 80), Material = Enum.Material.Neon }).Parent = tower
	tower.Parent = ground
end

sign(ORIGIN + Vector3.new(0, 26, 0), "🚀 SLIME AL ESPACIO", "¡Despegue automático cada ronda!", Color3.fromRGB(255, 220, 80), ground)

-- Llegada y regreso
local spawnPoint = part({ Name = "RocketSpawn", Size = Vector3.new(10, 1, 10), Position = ORIGIN + Vector3.new(0, 0.6, 40), Transparency = 1, CanCollide = false })
spawnPoint.Parent = world

do
	local back = place(28, ground, ORIGIN + Vector3.new(0, 0, 90), 0, 1.6)
	back.Name = "LobbyPortal"
	local trigger = part({ Name = "LobbyPortalPad", Size = Vector3.new(14, 1, 10), Position = ORIGIN + Vector3.new(0, 0.5, 82), Transparency = 1, CanCollide = false })
	trigger:SetAttribute("World", "Lobby")
	CollectionService:AddTag(trigger, "WorldPortal")
	trigger.Parent = world
	sign(ORIGIN + Vector3.new(0, 22, 82), "🏠 LOBBY", "Volver a la zona de inicio", Color3.fromRGB(140, 220, 255), ground)
end

-- Decoración: árboles y montañas del paquete Low Poly
local nature = folder("Nature")
for i = 1, 30 do
	local angle = rng:NextNumber(0, math.pi * 2)
	local radius = rng:NextNumber(70, 140)
	local p = ORIGIN + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
	if math.abs(p.Z - ORIGIN.Z) > 25 or math.abs(p.X) > 110 then
		local trees = { 16, 17, 18, 19, 33, 34, 36 }
		place(trees[rng:NextInteger(1, #trees)], nature, p, rng:NextInteger(0, 359), rng:NextNumber(0.9, 1.3))
	end
end
for i = 1, 14 do
	local angle = (i / 14) * math.pi * 2
	local mountains = { 66, 67, 68, 71, 72, 74 }
	place(mountains[(i - 1) % #mountains + 1], nature, ORIGIN + Vector3.new(math.cos(angle) * 175, 0, math.sin(angle) * 175), rng:NextInteger(0, 359), 1.3)
end

---------------------------------------------------------------- Cielo por capas (a su altura real)
local sky = folder("SkyLayers")
local function heightOf(layerId: string): number
	for _, layer in GameConfig.Rocket.Layers do
		if layer.Id == layerId then
			return layer.Altitude * STUDS_PER_METER
		end
	end
	return 0
end

-- Nubes: bolitas blancas alrededor de la columna de vuelo
local clouds = folder("Clouds", sky)
for i = 1, 40 do
	local y = heightOf("Clouds") + rng:NextNumber(-15, 60)
	local x = rng:NextNumber(-140, 140)
	-- Atrás de los cohetes (z negativo) o muy a los lados: nunca entre la cámara y los cohetes
	local z = ORIGIN.Z + (if rng:NextNumber() < 0.75 then rng:NextNumber(-110, -25) else rng:NextNumber(60, 110))
	local puff = Instance.new("Model")
	puff.Name = "Cloud"
	for j = 1, 4 do
		local s = rng:NextNumber(10, 22)
		part({ Shape = Enum.PartType.Ball, Size = Vector3.new(s, s, s), Position = Vector3.new(x + j * 7, y + rng:NextNumber(-3, 3), z + rng:NextNumber(-4, 4)), Color = Color3.new(1, 1, 1), CanCollide = false, CastShadow = false }).Parent = puff
	end
	puff.Parent = clouds
end

-- Arcoíris gigante que los cohetes atraviesan
do
	local rainbow = place(65, sky, Vector3.new(0, heightOf("Rainbow") - 60, ORIGIN.Z - 60), 0, 2.2)
	rainbow.Name = "Rainbow"
	for _, d in rainbow:GetDescendants() do
		if d:IsA("BasePart") then
			d.CanCollide = false
			d.CastShadow = false
		end
	end
end

-- Luna, Marte y la galaxia
local function planet(name, layerId, size, color, offset)
	local p = part({
		Name = name,
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(size, size, size),
		Position = Vector3.new(offset.X, heightOf(layerId) + offset.Y, ORIGIN.Z + offset.Z),
		Color = color,
		CanCollide = false,
		CastShadow = false,
	})
	p.Parent = sky
	return p
end
planet("Moon", "Moon", 260, Color3.fromRGB(210, 210, 225), Vector3.new(-330, 80, -250))
planet("Mars", "Mars", 340, Color3.fromRGB(230, 90, 60), Vector3.new(380, 120, -300))
do
	local galaxy = folder("Galaxy", sky)
	local center = Vector3.new(0, heightOf("Galaxy") + 150, ORIGIN.Z - 400)
	for i = 1, 60 do
		local angle = i * 0.5
		local radius = 30 + i * 6
		local p = part({
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * rng:NextNumber(6, 16),
			Position = center + Vector3.new(math.cos(angle) * radius, math.sin(angle * 0.5) * 20, math.sin(angle) * radius * 0.4),
			Color = Color3.fromHSV(0.7 + rng:NextNumber(-0.1, 0.15), 0.6, 1),
			Material = Enum.Material.Neon,
			CanCollide = false,
			CastShadow = false,
		})
		p.Parent = galaxy
	end
end

-- Planetas y asteroides de colores que pasan a los lados durante el vuelo (sensación de velocidad)
do
	local passing = folder("PassingPlanets", sky)
	local colors = {
		Color3.fromRGB(255, 120, 190), Color3.fromRGB(120, 200, 255), Color3.fromRGB(255, 200, 80),
		Color3.fromRGB(140, 255, 160), Color3.fromRGB(190, 130, 255), Color3.fromRGB(255, 150, 90),
	}
	local altitude = 1600
	while altitude < 16000 do
		local side = if rng:NextNumber() < 0.5 then -1 else 1
		local y = altitude * STUDS_PER_METER
		local x = side * rng:NextNumber(70, 130)
		local z = ORIGIN.Z - rng:NextNumber(30, 120)
		local size = rng:NextNumber(14, 40)
		local color = colors[rng:NextInteger(1, #colors)]
		local planet = part({ Name = "Planet", Shape = Enum.PartType.Ball, Size = Vector3.one * size, Position = Vector3.new(x, y, z), Color = color, CanCollide = false, CastShadow = false })
		planet.Parent = passing
		if rng:NextNumber() < 0.45 then
			-- Anillo tipo Saturno
			part({ Name = "Ring", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, size * 1.9, size * 1.9), CFrame = CFrame.new(x, y, z) * CFrame.Angles(math.rad(rng:NextNumber(-25, 25)), 0, math.rad(90 + rng:NextNumber(-20, 20))), Color = color:Lerp(Color3.new(1, 1, 1), 0.4), Material = Enum.Material.Neon, Transparency = 0.35, CanCollide = false, CastShadow = false }).Parent = passing
		end
		-- Unos asteroides cerca
		for _ = 1, rng:NextInteger(2, 4) do
			local a = rng:NextNumber(2, 5)
			part({ Name = "Asteroid", Size = Vector3.new(a, a * 0.8, a * 1.1), Position = Vector3.new(x - side * rng:NextNumber(20, 45), y + rng:NextNumber(-20, 20), z + rng:NextNumber(10, 40)), Orientation = Vector3.new(rng:NextNumber(0, 360), rng:NextNumber(0, 360), 0), Color = Color3.fromRGB(130, 120, 140), Material = Enum.Material.Slate, CanCollide = false, CastShadow = false }).Parent = passing
		end
		altitude += rng:NextNumber(280, 520)
	end
end

world.Parent = workspace

---------------------------------------------------------------- Modelo del cohete
local modelsFolder = game.ReplicatedStorage:FindFirstChild("RocketModels") or Instance.new("Folder")
modelsFolder.Name = "RocketModels"
modelsFolder.Parent = game.ReplicatedStorage
local oldRocket = modelsFolder:FindFirstChild("Basic")
if oldRocket then
	oldRocket:Destroy()
end

local rocket = Instance.new("Model")
rocket.Name = "Basic"
local root = part({ Name = "Root", Size = Vector3.new(1, 1, 1), Transparency = 1, CanCollide = false, Position = Vector3.new(0, 5, 0) })
root.Parent = rocket
local function piece(props)
	local p = part(props)
	p.Anchored = false
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = p
	weld.Parent = p
	p.Parent = rocket
	return p
end
local WHITE, RED, BLUE = Color3.fromRGB(245, 245, 250), Color3.fromRGB(255, 80, 95), Color3.fromRGB(90, 190, 255)
piece({ Name = "Body", Shape = Enum.PartType.Cylinder, Size = Vector3.new(7, 4, 4), CFrame = CFrame.new(0, 4.5, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = WHITE })
local nose = piece({ Name = "Nose", Shape = Enum.PartType.Ball, Size = Vector3.new(4, 4, 4), Position = Vector3.new(0, 8.2, 0), Color = RED })
local noseMesh = Instance.new("SpecialMesh")
noseMesh.MeshType = Enum.MeshType.Sphere
noseMesh.Scale = Vector3.new(1, 1.4, 1)
noseMesh.Parent = nose
piece({ Name = "Stripe", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.8, 4.2, 4.2), CFrame = CFrame.new(0, 6.2, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = RED })
piece({ Name = "Window", Shape = Enum.PartType.Ball, Size = Vector3.new(2, 2, 2), Position = Vector3.new(0, 5.5, -1.6), Color = BLUE, Material = Enum.Material.Glass, Transparency = 0.2 })
piece({ Name = "Nozzle", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.2, 3, 3), CFrame = CFrame.new(0, 0.6, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(70, 70, 85) })
for i = 0, 3 do
	local angle = math.rad(i * 90)
	piece({
		Name = "Fin",
		Size = Vector3.new(0.4, 3, 2.4),
		CFrame = CFrame.new(0, 2, 0) * CFrame.Angles(0, angle, 0) * CFrame.new(0, 0, 2.6),
		Color = RED,
	})
end

-- Escape: fuego, humo y chispas (se encienden durante el vuelo)
local exhaust = Instance.new("Attachment")
exhaust.Name = "Exhaust"
exhaust.Position = Vector3.new(0, -5, 0) -- relativo a Root (y=5) → base del cohete
exhaust.Orientation = Vector3.new(0, 0, 180) -- apunta hacia abajo
exhaust.Parent = root
local fire = Instance.new("ParticleEmitter")
fire.Name = "Fire"
fire.Texture = "rbxasset://textures/particles/fire_main.dds"
fire.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 240, 150)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 140, 40)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 60, 30)) })
fire.LightEmission = 1
fire.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 3.5), NumberSequenceKeypoint.new(1, 0.5) })
fire.Lifetime = NumberRange.new(0.25, 0.45)
fire.Speed = NumberRange.new(18, 26)
fire.Rate = 140
fire.SpreadAngle = Vector2.new(8, 8)
fire.EmissionDirection = Enum.NormalId.Top
fire.Enabled = false
fire.Parent = exhaust
local smoke = Instance.new("ParticleEmitter")
smoke.Name = "Smoke"
smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
smoke.Color = ColorSequence.new(Color3.fromRGB(240, 240, 245))
smoke.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
smoke.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 7) })
smoke.Lifetime = NumberRange.new(1.2, 2)
smoke.Speed = NumberRange.new(8, 12)
smoke.Rate = 25
smoke.SpreadAngle = Vector2.new(20, 20)
smoke.EmissionDirection = Enum.NormalId.Top
smoke.Enabled = false
smoke.Parent = exhaust
local light = Instance.new("PointLight")
light.Name = "EngineLight"
light.Color = Color3.fromRGB(255, 160, 60)
light.Range = 14
light.Brightness = 2
light.Enabled = false
light.Parent = exhaust

-- Estela blanca que queda atrás del cohete (se enciende con el motor)
local trailA = Instance.new("Attachment")
trailA.Name = "TrailA"
trailA.Position = Vector3.new(-1.2, -4.5, 0)
trailA.Parent = root
local trailB = Instance.new("Attachment")
trailB.Name = "TrailB"
trailB.Position = Vector3.new(1.2, -4.5, 0)
trailB.Parent = root
local trail = Instance.new("Trail")
trail.Name = "Trail"
trail.Attachment0 = trailA
trail.Attachment1 = trailB
trail.Lifetime = 0.9
trail.MinLength = 0.2
trail.LightEmission = 0.6
trail.FaceCamera = true
trail.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(150, 200, 255))
trail.Transparency = NumberSequence.new(0.2, 1)
trail.WidthScale = NumberSequence.new(1, 0.2)
trail.Enabled = false
trail.Parent = root

-- Donde se sienta el piloto (un slime)
local pilot = Instance.new("Attachment")
pilot.Name = "Pilot"
pilot.Position = Vector3.new(0, 0.6, -2.3) -- frente a la ventana, por fuera del cuerpo
pilot.Parent = root

rocket.PrimaryPart = root
rocket:PivotTo(CFrame.new())
rocket.Parent = modelsFolder

-- Aurora boreal entre el arcoíris y el espacio (~1,100 m), detrás de los cohetes.
-- Copia limpia de "Northern Lights" (TheRisingTides, Creator Store): solo Beams, sin scripts.
do
	local auroraRoot = Instance.new("Part")
	auroraRoot.Name = "AuroraRoot"
	auroraRoot.Anchored = true
	auroraRoot.CanCollide = false
	auroraRoot.CanQuery = false
	auroraRoot.CanTouch = false
	auroraRoot.Transparency = 1
	auroraRoot.Size = Vector3.new(2, 250, 500)
	auroraRoot.CFrame = CFrame.new(0, 1 + 1100 * 0.4, 3000 - 350) * CFrame.Angles(0, math.rad(90), 0)
	local one = Instance.new("Attachment")
	one.Name = "One"
	one.Position = Vector3.new(0, 4.5, 500)
	one.Parent = auroraRoot
	local two = Instance.new("Attachment")
	two.Name = "Two"
	two.Position = Vector3.new(0, 4.5, -500)
	two.Parent = auroraRoot
	local function key(t, c) return ColorSequenceKeypoint.new(t, Color3.fromHex(c)) end
	local function nkey(t, v) return NumberSequenceKeypoint.new(t, v) end
	local beams = {
		{ "4553095322", { key(0, "00ffe2"), key(0.13, "78b2f0"), key(0.33, "ff5cff"), key(0.68, "4ecdeb"), key(1, "00ffe2") }, { nkey(0, 1), nkey(0.3, 0.51), nkey(0.5, 0.74), nkey(0.7, 0.52), nkey(1, 1) }, 500, 650, 0.01 },
		{ "4553095322", { key(0, "c042ff"), key(0.69, "2ff5ff"), key(1, "c042ff") }, { nkey(0, 1), nkey(0.31, 0.48), nkey(0.5, 0.76), nkey(0.7, 0.52), nkey(1, 1) }, 700, 800, -0.01 },
		{ "4537255327", { key(0, "ff5cf7"), key(1, "ff5cf7") }, { nkey(0, 1), nkey(0.28, 0.69), nkey(0.8, 0.91), nkey(1, 1) }, 800, 1500, 0.03 },
		{ "4537255327", { key(0, "c131ff"), key(1, "c131ff") }, { nkey(0, 1), nkey(0.51, 0.88), nkey(1, 1) }, 260, 1000, -0.06 },
		{ "4537255327", { key(0, "4ac6ff"), key(1, "4ac6ff") }, { nkey(0, 1), nkey(0.23, 0.82), nkey(0.81, 0.89), nkey(1, 1) }, 400, 2000, -0.03 },
	}
	for _, b in beams do
		local beam = Instance.new("Beam")
		beam.Texture = "rbxassetid://" .. b[1]
		beam.Color = ColorSequence.new(b[2])
		beam.Transparency = NumberSequence.new(b[3])
		beam.Width0 = b[4]
		beam.Width1 = b[4]
		beam.TextureLength = b[5]
		beam.TextureSpeed = b[6]
		beam.TextureMode = Enum.TextureMode.Static
		beam.Segments = 250
		beam.CurveSize0 = 500
		beam.CurveSize1 = 260
		beam.Attachment0 = one
		beam.Attachment1 = two
		beam.Parent = auroraRoot
	end
	local aurora = Instance.new("Model")
	aurora.Name = "Aurora"
	auroraRoot.Parent = aurora
	aurora.Parent = world
end

local padCount = #CollectionService:GetTagged("LaunchPad")
return "ok: plataformas=" .. padCount .. " nubes=" .. #clouds:GetChildren()
