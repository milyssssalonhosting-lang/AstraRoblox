-- Herramienta (no va dentro del juego): crea los modelos de abejas Nv.2 y Nv.3 en
-- ReplicatedStorage.PetModels (copias más grandes de la abeja Nv.1) y pone brillos
-- dorados a TODAS las mascotas Nv.3 (slimes y abejas). Se puede correr otra vez.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local petModels = ReplicatedStorage.PetModels

local LEVEL_SCALE = { 1, 1.3, 1.6 } -- igual que los slimes (Nv.2 ≈ 1.3x)

local created = 0
for _, baseId in GameConfig.BeeIds do
	local base = petModels:FindFirstChild(baseId)
	if base then
		for level = 2, 3 do
			local id = baseId .. "_" .. level
			local old = petModels:FindFirstChild(id)
			if old then
				old:Destroy()
			end
			local model = base:Clone()
			model.Name = id
			model:ScaleTo(base:GetScale() * LEVEL_SCALE[level])
			model.Parent = petModels
			created += 1
		end
	end
end

-- Brillos dorados en las Nv.3
local sparkled = 0
for id, pet in GameConfig.Pets do
	local model = petModels:FindFirstChild(id)
	if model and pet.Level == 3 then
		local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
		if part and not part:FindFirstChild("LevelSparkles") then
			local e = Instance.new("ParticleEmitter")
			e.Name = "LevelSparkles"
			e.Texture = "rbxassetid://1084970835" -- estrella de 4 puntas
			e.Color = ColorSequence.new(Color3.fromRGB(255, 240, 120), Color3.fromRGB(255, 170, 60))
			e.LightEmission = 1
			e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.4, 0.5), NumberSequenceKeypoint.new(1, 0) })
			e.Lifetime = NumberRange.new(0.8, 1.4)
			e.Speed = NumberRange.new(1, 2.5)
			e.SpreadAngle = Vector2.new(180, 180)
			e.Rate = 6
			e.Parent = part
			sparkled += 1
		end
	end
end

return "ok: abejas nuevas=" .. created .. " brillos Nv.3=" .. sparkled
