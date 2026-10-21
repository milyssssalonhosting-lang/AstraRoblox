-- StarterGui/HUD/Modules/PetViewport (ModuleScript)
-- Dibuja el modelo 3D de una mascota dentro de una tarjeta de la interfaz
-- (ViewportFrame). Si el modelo no existe, deja visible el emoji de respaldo.
--   PetViewport.Show(container, petId, { Silhouette = true })

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local petModels = ReplicatedStorage:WaitForChild("PetModels")

local PetViewport = {}

-- Precargar las mallas de todas las mascotas al entrar, para que las tarjetas
-- (y el resultado de los huevos) no aparezcan vacías la primera vez
task.spawn(function()
	pcall(function()
		game:GetService("ContentProvider"):PreloadAsync({ petModels })
	end)
end)

local function getViewport(container: GuiObject): ViewportFrame
	local viewport = container:FindFirstChild("PetView")
	if not viewport then
		viewport = Instance.new("ViewportFrame")
		viewport.Name = "PetView"
		viewport.BackgroundTransparency = 1
		viewport.Size = UDim2.fromScale(1, 1)
		viewport.Ambient = Color3.fromRGB(200, 200, 200)
		viewport.LightColor = Color3.new(1, 1, 1)
		viewport.LightDirection = Vector3.new(-1, -1, -1)
		viewport.ZIndex = container.ZIndex
		local camera = Instance.new("Camera")
		camera.FieldOfView = 30
		camera.Parent = viewport
		viewport.CurrentCamera = camera
		viewport.Parent = container
	end
	return viewport
end

-- container: el área donde se dibuja (normalmente el Icon de la tarjeta)
function PetViewport.Show(container: GuiObject, petId: string, options: { Silhouette: boolean? }?)
	local source = petModels:FindFirstChild(petId)
	local viewport = getViewport(container)
	if container:IsA("TextLabel") then
		-- el emoji queda solo si no hay modelo
		container.TextTransparency = if source then 1 else 0
	end
	if viewport:GetAttribute("PetId") == petId then
		viewport.ImageColor3 = if options and options.Silhouette then Color3.new(0, 0, 0) else Color3.new(1, 1, 1)
		return
	end
	viewport:SetAttribute("PetId", petId)
	for _, child in viewport:GetChildren() do
		if child:IsA("Model") then
			child:Destroy()
		end
	end
	if not source then
		return
	end

	local model = source:Clone()
	model:PivotTo(CFrame.new())
	model.Parent = viewport
	-- Encuadre: cámara de frente (el frente del modelo es -Z), un poco arriba y
	-- a un lado, a la distancia justa para que llene la tarjeta
	local cf, size = model:GetBoundingBox()
	local biggest = math.max(size.X, size.Y, size.Z)
	local distance = (biggest / 2) / math.tan(math.rad(viewport.CurrentCamera.FieldOfView / 2)) * 1.35
	local fromFront = Vector3.new(0.35, 0.3, -1).Unit
	viewport.CurrentCamera.CFrame = CFrame.lookAt(cf.Position + fromFront * distance, cf.Position)
	viewport.ImageColor3 = if options and options.Silhouette then Color3.new(0, 0, 0) else Color3.new(1, 1, 1)
end

return PetViewport
