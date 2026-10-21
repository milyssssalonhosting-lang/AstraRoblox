-- Herramienta (no va dentro del juego): prepara los modelos de los objetos del aire
-- en ReplicatedStorage.PickupModels: una moneda dorada y 4 gemas del paquete Cartoon.

local gems = game.ServerStorage.AssetLibrary.Cartoon.Gems
local out = game.ReplicatedStorage:FindFirstChild("PickupModels")
if out then
	out:Destroy()
end
out = Instance.new("Folder")
out.Name = "PickupModels"

local function prepare(part: BasePart, name: string, size: number)
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	local biggest = math.max(part.Size.X, part.Size.Y, part.Size.Z)
	part.Size = part.Size * (size / biggest)
	part.CFrame = CFrame.new()
	part.Parent = out
	return part
end

-- Moneda: cilindro dorado con borde brillante
local coin = Instance.new("Part")
coin.Shape = Enum.PartType.Cylinder
coin.Size = Vector3.new(0.5, 3, 3)
coin.Color = Color3.fromRGB(255, 205, 50)
coin.Material = Enum.Material.SmoothPlastic
prepare(coin, "Coin", 3)
local glow = Instance.new("PointLight")
glow.Color = Color3.fromRGB(255, 210, 80)
glow.Range = 6
glow.Brightness = 1
glow.Parent = coin

-- Gemas (cada una con su luz del mismo color)
local MAP = {
	GemTurbo = { Source = "Gem3", Color = Color3.fromRGB(60, 220, 255) },
	GemFuel = { Source = "Gem7", Color = Color3.fromRGB(80, 255, 90) },
	GemDouble = { Source = "Gem4", Color = Color3.fromRGB(255, 210, 60) },
	GemGalaxy = { Source = "Gem8", Color = Color3.fromRGB(190, 90, 255) },
}
for name, info in MAP do
	local gem = prepare(gems[info.Source]:Clone(), name, 4.5)
	local light = Instance.new("PointLight")
	light.Color = info.Color
	light.Range = 10
	light.Brightness = 2
	light.Parent = gem
	local sparkle = Instance.new("ParticleEmitter")
	sparkle.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkle.Color = ColorSequence.new(info.Color)
	sparkle.LightEmission = 1
	sparkle.Size = NumberSequence.new(0.6, 0)
	sparkle.Rate = 8
	sparkle.Lifetime = NumberRange.new(0.6, 1)
	sparkle.Speed = NumberRange.new(1, 3)
	sparkle.SpreadAngle = Vector2.new(180, 180)
	sparkle.Parent = gem
end

out.Parent = game.ReplicatedStorage
return "ok: " .. #out:GetChildren() .. " modelos"
