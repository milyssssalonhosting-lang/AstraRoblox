-- Herramienta (no va dentro del juego): construye el mapa con el paquete Low Poly
-- que está en ServerStorage.AssetLibrary. Se puede volver a correr: borra
-- Workspace.Map y lo arma de nuevo (con la misma semilla, queda igual).

local lib = game.ServerStorage.AssetLibrary
local lp = lib.LowPoly
local rng = Random.new(2026)

local function G(i)
	return lp["Group" .. i]
end

-- Qué es cada grupo del paquete (identificado por tamaño y foto)
local RAINBOW = 65
local MOUNTAINS = { 66, 67, 68, 71, 72, 74 }
local BIG_TREES = { 16, 17, 18, 19, 33, 34, 36 }
local SMALL_TREES = { 2, 12, 22 }
local HOUSES = { 69, 70, 13 }
local STALL = 30
local FOUNTAIN = 10
local PORTALS = { 28, 32 }
local CHESTS = { 73, 64, 14 }
local CANDY = 75
local ROCK_PILES = { 62, 63 }
local BRIDGE = 43
local FLOWERS = { 23, 24, 41, 42, 46, 47 }

local old = workspace:FindFirstChild("Map")
if old then
	old:Destroy()
end
local map = Instance.new("Folder")
map.Name = "Map"

local function folder(name)
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = map
	return f
end
local decor, nature, landmarks = folder("Decor"), folder("Nature"), folder("Landmarks")

-- Copia un grupo, lo escala, lo gira y lo apoya en el piso (y = 0)
local function place(index: number, parent: Instance, x: number, z: number, rotY: number?, scale: number?, name: string?)
	local source = G(index)
	local model = source:Clone()
	if model:IsA("BasePart") then
		local wrap = Instance.new("Model")
		model.Parent = wrap
		model = wrap
	end
	if scale and scale ~= 1 then
		model:ScaleTo(model:GetScale() * scale)
	end
	model.Name = name or ("Asset" .. index)
	local cf, size = model:GetBoundingBox()
	local pivotOffset = model:GetPivot().Position - cf.Position
	model:PivotTo(CFrame.new(x, size.Y / 2 + pivotOffset.Y, z) * CFrame.Angles(0, math.rad(rotY or 0), 0))
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
		end
	end
	model.Parent = parent
	return model
end

---------------------------------------------------------------- Piso
local ground = Instance.new("Part")
ground.Name = "Ground"
ground.Size = Vector3.new(560, 4, 560)
ground.Position = Vector3.new(0, -2, 0)
ground.Anchored = true
ground.Material = Enum.Material.SmoothPlastic
ground.Color = Color3.fromRGB(110, 200, 70)
ground.TopSurface = Enum.SurfaceType.Smooth
ground.Parent = map

-- Plaza grande: aquí están todas las estaciones de la zona de inicio
local plaza = Instance.new("Part")
plaza.Name = "Plaza"
plaza.Shape = Enum.PartType.Cylinder
plaza.Size = Vector3.new(0.4, 150, 150)
plaza.CFrame = CFrame.new(0, 0.2, 0) * CFrame.Angles(0, 0, math.rad(90))
plaza.Anchored = true
plaza.Material = Enum.Material.SmoothPlastic
plaza.Color = Color3.fromRGB(235, 215, 170)
plaza.Parent = map

---------------------------------------------------------------- Letreros flotantes
local CollectionService = game:GetService("CollectionService")
local GameConfig = require(game.ReplicatedStorage.Shared.GameConfig)
local FONT = Enum.Font.FredokaOne

local function sign(adornee: BasePart, title: string, subtitle: string?, color: Color3, height: number)
	-- Ancla invisible SIN girar a la altura del letrero. (Si se usara la pieza
	-- directamente, en los cilindros acostados el letrero se iría de lado.)
	local anchor = Instance.new("Part")
	anchor.Name = "SignAnchor"
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.CFrame = CFrame.new(adornee.Position + Vector3.new(0, height, 0))
	anchor.Parent = adornee
	local bb = Instance.new("BillboardGui")
	bb.Name = "Sign"
	bb.Size = UDim2.fromScale(11, 3.5)
	bb.MaxDistance = 160
	bb.LightInfluence = 0
	bb.Adornee = anchor
	local t = Instance.new("TextLabel")
	t.Name = "Title"
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
		s2.Name = "Subtitle"
		s2.Text = subtitle
		s2.TextColor3 = Color3.new(1, 1, 1)
		s2.Position = UDim2.fromScale(0, 0.6)
		s2.Size = UDim2.fromScale(1, 0.4)
		s2.Parent = bb
	end
	bb.Parent = anchor
	return bb
end

-- Pieza invisible con un ProximityPrompt que abre un panel del HUD
local function station(name: string, position: Vector3, panel: string, actionText: string)
	local anchor = Instance.new("Part")
	anchor.Name = name
	anchor.Size = Vector3.new(4, 4, 4)
	anchor.Position = position
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.Transparency = 1
	anchor:SetAttribute("Panel", panel)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = actionText
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = anchor
	CollectionService:AddTag(anchor, "Station")
	return anchor
end

local function disk(name: string, position: Vector3, diameter: number, thickness: number, color: Color3, material: Enum.Material)
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = Enum.PartType.Cylinder
	p.Size = Vector3.new(thickness, diameter, diameter)
	p.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
	p.Anchored = true
	p.Material = material
	p.Color = color
	return p
end

local stations = folder("Stations")

---------------------------------------------------------------- Puntos de referencia
place(RAINBOW, landmarks, 0, -150, 0, 1.6, "Rainbow")
place(FOUNTAIN, landmarks, 0, -22, 0, 1, "Fountain")
place(CANDY, decor, 0, -95, 0, 1.2, "CandyRow")
place(BRIDGE, decor, 110, -60, 90, 1.4, "Bridge")

-- Tienda de huevos (oeste): puesto + un huevo gigante por cada huevo de la tienda
do
	place(STALL, stations, -60, 0, 90, 1.3, "EggStall")
	for i, egg in GameConfig.Eggs do
		local z = -14 + (i - 1) * 14
		local e = Instance.new("Part")
		e.Name = "EggDisplay_" .. egg.Id
		e.Shape = Enum.PartType.Ball
		e.Size = Vector3.new(5, 5, 5)
		e.Material = Enum.Material.SmoothPlastic
		e.Color = egg.Top
		e.Anchored = true
		e.CanCollide = false
		e.Position = Vector3.new(-44, 4.4, z)
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Scale = Vector3.new(1, 1.3, 1) -- forma de huevo
		mesh.Parent = e
		local base = disk("Pedestal", Vector3.new(-44, 0.6, z), 7, 1.2, egg.Bottom, Enum.Material.SmoothPlastic)
		base.Parent = e
		sign(e, egg.Icon .. " " .. egg.Name, "$" .. GameConfig.FormatNumber(egg.Price), egg.Top, 9)
		e.Parent = stations
	end
	local shop = station("EggShopStation", Vector3.new(-48, 2, 0), "ShopPanel", "Abrir huevos")
	shop.Parent = stations
end

-- Altar de Rebirth (noroeste)
do
	place(29, stations, -42, -44, 30, 2.2, "RebirthAltar")
	local anchor = station("RebirthStation", Vector3.new(-42, 3, -44), "RebirthPanel", "Rebirth")
	sign(anchor, "🔄 REBIRTH", "¡Gana más dinero para siempre!", Color3.fromRGB(230, 120, 255), 16)
	anchor.Parent = stations
end

-- Zona AFK (este): círculo brillante; adentro ganas x2
do
	local zone = disk("AFKZone", Vector3.new(46, 0.45, -6), 22, 0.5, Color3.fromRGB(120, 210, 255), Enum.Material.Neon)
	zone.CanCollide = false
	zone.Transparency = 0.35
	CollectionService:AddTag(zone, "AFKZone")
	local ring = disk("Ring", Vector3.new(46, 0.35, -6), 24, 0.4, Color3.new(1, 1, 1), Enum.Material.SmoothPlastic)
	ring.CanCollide = false
	ring.Parent = zone
	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Name = "Sparkles"
	sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkles.Rate = 6
	sparkles.Lifetime = NumberRange.new(1.5, 2.5)
	sparkles.Speed = NumberRange.new(2, 4)
	sparkles.Size = NumberSequence.new(0.4)
	sparkles.EmissionDirection = Enum.NormalId.Right -- hacia arriba (el cilindro está girado)
	sparkles.Parent = zone
	sign(zone, "💤 ZONA AFK", "Párate aquí: ¡ganas x2!", Color3.fromRGB(140, 220, 255), 15)
	zone.Parent = stations
end

-- AFK Pro (sureste): plataforma que te manda al Mundo AFK.
-- "pad" es un detector invisible; lo que se ve es el portal importado (.glb de
-- Tripo3D, guardado en AssetLibrary.AFKProPortal). Si no está, se ve un disco simple.
do
	local pad = disk("AFKProPad", Vector3.new(50, 0.5, 30), 16, 0.6, Color3.fromRGB(250, 230, 210), Enum.Material.SmoothPlastic)
	pad:SetAttribute("World", "AFK")
	CollectionService:AddTag(pad, "WorldPortal")
	local source = lib:FindFirstChild("AFKProPortal")
	if source then
		pad.Transparency = 1
		pad.CanCollide = false
		local portal = source:Clone()
		portal.Name = "PortalMesh"
		portal.Size = Vector3.new(18, 1.8, 18) -- aplanado para poder subir caminando
		portal.Anchored = true
		portal.CanCollide = true
		portal.CFrame = CFrame.new(50, 0.45 + portal.Size.Y / 2, 30) -- apoyado sobre la plaza
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 160, 90)
		light.Range = 18
		light.Brightness = 1.5
		light.Parent = portal
		local attach = Instance.new("Attachment")
		attach.Position = Vector3.new(0, portal.Size.Y / 2, 0)
		attach.Parent = portal
		local sparkles = Instance.new("ParticleEmitter")
		sparkles.Name = "Sparkles"
		sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		sparkles.Color = ColorSequence.new(Color3.fromRGB(255, 190, 120), Color3.fromRGB(255, 120, 70))
		sparkles.Rate = 10
		sparkles.Lifetime = NumberRange.new(1.5, 2.5)
		sparkles.Speed = NumberRange.new(3, 6)
		sparkles.SpreadAngle = Vector2.new(25, 25)
		sparkles.Size = NumberSequence.new(0.5, 0)
		sparkles.Shape = Enum.ParticleEmitterShape.Disc
		sparkles.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
		sparkles.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
		sparkles.Parent = attach
		portal.Parent = pad
	else
		local ring = disk("Ring", Vector3.new(50, 0.4, 30), 16, 0.5, Color3.fromRGB(250, 120, 70), Enum.Material.SmoothPlastic)
		ring.Parent = pad
	end
	sign(pad, "🌙 AFK PRO", "Mundo solo para AFK", Color3.fromRGB(255, 170, 90), 15)
	pad.Parent = stations
end

-- Portal al juego principal (sur)
do
	place(PORTALS[1], stations, 0, 64, 180, 1.8, "MainPortal")
	local trigger = Instance.new("Part")
	trigger.Name = "MainPortalPad"
	trigger.Size = Vector3.new(14, 1, 10)
	trigger.Position = Vector3.new(0, 0.5, 56)
	trigger.Anchored = true
	trigger.CanCollide = false
	trigger.Transparency = 1
	trigger:SetAttribute("World", "Main")
	CollectionService:AddTag(trigger, "WorldPortal")
	sign(trigger, "⚔️ JUGAR", "Mundo Principal (pronto)", Color3.fromRGB(255, 220, 80), 24)
	trigger.Parent = stations
end

for i, pile in ROCK_PILES do
	place(pile, decor, -110 + (i - 1) * 220, 120, rng:NextInteger(0, 359), 1.3, "RockPile" .. i)
end

-- Las casas y cofres se guardan aparte (no se usan en el lobby por ahora)
local stored = game.ServerStorage:FindFirstChild("StoredMapPieces") or Instance.new("Folder")
stored.Name = "StoredMapPieces"
stored.Parent = game.ServerStorage
for _, index in { HOUSES[1], HOUSES[2], HOUSES[3], CHESTS[1], CHESTS[2], CHESTS[3], PORTALS[2] } do
	if not stored:FindFirstChild("Group" .. index) then
		G(index):Clone().Parent = stored
	end
end

---------------------------------------------------------------- Montañas alrededor
local ring = 24
for i = 1, ring do
	local angle = (i / ring) * math.pi * 2
	local radius = 245 + rng:NextNumber(-10, 10)
	local m = MOUNTAINS[(i - 1) % #MOUNTAINS + 1]
	place(m, nature, math.cos(angle) * radius, math.sin(angle) * radius, rng:NextInteger(0, 359), rng:NextNumber(1.1, 1.6), "Mountain")
end

---------------------------------------------------------------- Árboles y flores
-- Zonas libres (no poner árboles encima): plaza, dulces, puente
local blocked = {
	{ Vector3.new(0, 0, 0), 82 }, -- plaza con estaciones
	{ Vector3.new(0, 0, -120), 60 }, -- dulces y arcoíris
	{ Vector3.new(110, 0, -60), 25 }, -- puente
}
local function isFree(x, z, margin)
	for _, zone in blocked do
		if (Vector3.new(x, 0, z) - zone[1]).Magnitude < zone[2] + margin then
			return false
		end
	end
	return math.sqrt(x * x + z * z) < 215
end

local placedTrees = 0
local attempts = 0
while placedTrees < 70 and attempts < 2000 do
	attempts += 1
	local x, z = rng:NextNumber(-210, 210), rng:NextNumber(-210, 210)
	if isFree(x, z, 6) then
		local big = rng:NextNumber() < 0.7
		local list = if big then BIG_TREES else SMALL_TREES
		place(list[rng:NextInteger(1, #list)], nature, x, z, rng:NextInteger(0, 359), rng:NextNumber(0.9, 1.4), "Tree")
		placedTrees += 1
	end
end

local placedFlowers = 0
attempts = 0
while placedFlowers < 90 and attempts < 3000 do
	attempts += 1
	local x, z = rng:NextNumber(-200, 200), rng:NextNumber(-200, 200)
	if isFree(x, z, 1) then
		place(FLOWERS[rng:NextInteger(1, #FLOWERS)], nature, x, z, rng:NextInteger(0, 359), rng:NextNumber(0.9, 1.3), "Flower")
		placedFlowers += 1
	end
end

map.Parent = workspace

---------------------------------------------------------------- Limpieza e iluminación
for _, name in { "Baseplate", "PixelTree" } do
	local o = workspace:FindFirstChild(name)
	if o then
		o:Destroy()
	end
end
local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
if spawn then
	spawn.Position = Vector3.new(0, 0.6, 12)
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.Transparency = 1
	spawn.CanCollide = false
	local decal = spawn:FindFirstChildOfClass("Decal")
	if decal then
		decal:Destroy()
	end
end

local Lighting = game.Lighting
for _, child in Lighting:GetChildren() do
	if child:IsA("Sky") or child:IsA("Atmosphere") or child:IsA("PostEffect") then
		child:Destroy()
	end
end
for _, child in lib.LowPolyLighting:GetChildren() do
	child:Clone().Parent = Lighting
end

return string.format("ok: árboles=%d flores=%d montañas=%d", placedTrees, placedFlowers, ring)
