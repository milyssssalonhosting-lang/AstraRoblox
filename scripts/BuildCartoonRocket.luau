-- Herramienta (no va dentro del juego): crea ReplicatedStorage.RocketModels.Cartoon
-- a partir del cohete "Basic" (mismos Attachments: Exhaust, Trail, Pilot) pero con la
-- malla del cohete azul caricatura (descarga "Rocket For High Quality Developer",
-- ya limpia en ServerStorage.AssetLibrary.Space) y llamas con textura animada.
-- Se ejecuta en la barra de comandos / MCP en modo Edición.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local models = ReplicatedStorage.RocketModels
local space = ServerStorage.AssetLibrary.Space

local BODY_SCALE = 0.22 -- escala de la malla (0.1 = tamaño original); 0.22 ≈ 10 studs de alto como Basic
local BODY_OFFSET = Vector3.new(0, 0, 0) -- ajuste fino de la malla respecto a Root
local BODY_YAW = 0 -- la malla no tiene ventana; el slime piloto va montado al frente

local old = models:FindFirstChild("Cartoon")
if old then
	old:Destroy()
end

local rocket = models.Basic:Clone()
rocket.Name = "Cartoon"
local root = rocket.Root

-- Quitar el cuerpo de piezas del cohete Basic (se queda Root con sus Attachments)
for _, d in rocket:GetDescendants() do
	if d:IsA("BasePart") and d ~= root then
		d:Destroy()
	end
end

-- Cuerpo nuevo: la malla caricatura (vertical tal cual: su punta es +Y)
local body = space.CartoonRocketBody:Clone()
body.Name = "Body"
body.Anchored = false
body.CanCollide = false
body.CanQuery = false
body.CanTouch = false
body.Massless = true
body.Transparency = 0
body.Size = Vector3.new(4, 10, 4) -- solo la caja (la malla FileMesh se ve según Mesh.Scale)
body.Mesh.Scale = Vector3.one * BODY_SCALE
body.CFrame = root.CFrame * CFrame.new(BODY_OFFSET) * CFrame.Angles(0, BODY_YAW, 0)
body.Parent = rocket
local weld = Instance.new("WeldConstraint")
weld.Part0 = root
weld.Part1 = body
weld.Parent = body

-- Llama animada (flipbook) además del fuego normal
local exhaust = root.Exhaust
for _, source in space.RocketFlames:GetChildren() do
	if source.FlipbookLayout ~= Enum.ParticleFlipbookLayout.None then
		local flame = source:Clone()
		flame.Name = "FlameFX"
		flame.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2.5), NumberSequenceKeypoint.new(1, 0.6) })
		flame.Lifetime = NumberRange.new(0.25, 0.4)
		flame.Speed = NumberRange.new(14, 20)
		flame.Rate = 35
		flame.Color = ColorSequence.new(Color3.fromRGB(255, 240, 140), Color3.fromRGB(255, 120, 40)) -- naranja (la original era verdosa)
		flame.LightEmission = 0.6
		flame.EmissionDirection = Enum.NormalId.Top -- Exhaust apunta hacia abajo
		flame.SpreadAngle = Vector2.new(6, 6)
		flame.Enabled = false
		flame.Parent = exhaust
		break
	end
end

-- El slime piloto va montado al frente del cuerpo (más delgado que el Basic)
root.Pilot.Position = Vector3.new(0, 0.4, -2)

rocket.PrimaryPart = root
rocket:PivotTo(CFrame.new())
rocket.Parent = models
return "ok: Cartoon creado"
