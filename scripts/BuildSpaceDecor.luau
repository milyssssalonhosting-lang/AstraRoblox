-- Herramienta (no va dentro del juego): decora el cielo del Mundo Cohete con modelos
-- limpios de ServerStorage.AssetLibrary.Space. Correr DESPUÉS de BuildRocketWorld.
--  * Cambia cada nube de bolitas por una nube caricatura con borde negro (mismo lugar y tamaño).
--  * Agrega planetas tipo Saturno (anillos de colores) que pasan entre 2,000 y 14,000 m.

local ServerStorage = game:GetService("ServerStorage")

local space = ServerStorage.AssetLibrary.Space
local layers = workspace.RocketWorld.SkyLayers
local STUDS_PER_METER = 0.4
local rng = Random.new(7) -- semilla fija: siempre el mismo acomodo

local function prepare(model: Model)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.CastShadow = false
		end
	end
end

-- Nubes
local cloudCount = 0
for _, old in layers.Clouds:GetChildren() do
	if old:IsA("Model") and old.Name == "Cloud" then
		local size = old:GetExtentsSize()
		local cloud = space.CartoonCloud:Clone()
		cloud.Name = "Cloud"
		prepare(cloud)
		local cloudSize = cloud:GetExtentsSize()
		cloud:ScaleTo(cloud:GetScale() * (size.X / cloudSize.X))
		-- De frente a la cámara (que mira hacia -Z) con un poco de giro al azar
		cloud:PivotTo(CFrame.new(old:GetPivot().Position) * CFrame.Angles(0, math.rad(rng:NextNumber(-20, 20)), 0))
		cloud.Parent = layers.Clouds
		old:Destroy()
		cloudCount += 1
	end
end

-- Saturnos
local saturns = layers:FindFirstChild("Saturns")
if saturns then
	saturns:Destroy()
end
saturns = Instance.new("Folder")
saturns.Name = "Saturns"
saturns.Parent = layers
local ringColors = {
	{ Color3.fromRGB(255, 120, 200), Color3.fromRGB(255, 220, 90), Color3.fromRGB(120, 220, 255) },
	{ Color3.fromRGB(150, 255, 140), Color3.fromRGB(255, 160, 60), Color3.fromRGB(190, 120, 255) },
	{ Color3.fromRGB(255, 240, 120), Color3.fromRGB(255, 100, 120), Color3.fromRGB(100, 200, 255) },
}
local planetColors = { Color3.fromRGB(226, 155, 64), Color3.fromRGB(120, 110, 255), Color3.fromRGB(255, 120, 170), Color3.fromRGB(90, 220, 200) }
local altitude = 2000
local side = 1
local count = 0
while altitude < 14000 do
	local saturn = space.Saturn:Clone()
	prepare(saturn)
	local size = saturn:GetExtentsSize()
	saturn:ScaleTo(saturn:GetScale() * (rng:NextNumber(35, 70) / math.max(size.X, size.Z)))
	-- Colores alegres distintos en cada uno
	local rings = ringColors[rng:NextInteger(1, #ringColors)]
	local r = 0
	for _, p in saturn:GetChildren() do
		if p:IsA("UnionOperation") then
			r += 1
			p.UsePartColor = true
			p.Color = rings[(r - 1) % #rings + 1]
			p.Material = Enum.Material.Neon
		elseif p:IsA("Part") then
			p.Color = planetColors[rng:NextInteger(1, #planetColors)]
			p.Material = Enum.Material.SmoothPlastic
		end
	end
	local x = side * rng:NextNumber(70, 130)
	local position = Vector3.new(x, 1 + altitude * STUDS_PER_METER, 3000 - rng:NextNumber(60, 160))
	saturn:PivotTo(CFrame.new(position) * CFrame.Angles(math.rad(rng:NextNumber(15, 30)), 0, math.rad(rng:NextNumber(-25, 25))))
	saturn.Parent = saturns
	count += 1
	side = -side
	altitude += rng:NextNumber(1400, 2200)
end

return "ok: nubes=" .. cloudCount .. " saturnos=" .. count
