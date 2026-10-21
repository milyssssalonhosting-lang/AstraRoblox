-- Herramienta (no va dentro del juego): prepara los modelos de mascotas a partir
-- de ServerStorage.AssetLibrary (Slimes y Bees) y los deja en
-- ReplicatedStorage.PetModels, livianos y del tamaño correcto:
--  * Slimes: sus ~100 piezas se fusionan en UNA (UnionOperation, conserva colores).
--  * Abejas: se sueldan a una pieza raíz y se les quita el Highlight (caro).
-- Nombres: Slime_<Sabor>_<Nivel> (nivel 1-3) y Bee_<Nombre>.

local GS = game:GetService("GeometryService")
local lib = game.ServerStorage.AssetLibrary

local out = game.ReplicatedStorage:FindFirstChild("PetModels")
if out then
	out:Destroy()
end
out = Instance.new("Folder")
out.Name = "PetModels"

local SLIME_SIZE = { 2.6, 3.4, 4.4 } -- tamaño máximo según nivel
local BEE_SIZE = 2.4

local function fitScale(model: Model, target: number)
	local _, size = model:GetBoundingBox()
	local biggest = math.max(size.X, size.Y, size.Z)
	model:ScaleTo(model:GetScale() * (target / biggest))
end

local function cleanPart(p: BasePart)
	p.Anchored = false
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CastShadow = false
end

local function finish(model: Model, root: BasePart, name: string)
	root.Name = "Root"
	root.Anchored = true
	model.PrimaryPart = root
	model.Name = name
	model:PivotTo(CFrame.new(0, 0, 0))
	model.Parent = out
end

---------------------------------------------------------------- Slimes
local slimeCount = 0
local function prepareSlime(source: Model, flavor: string, level: number)
	local copy = source:Clone()
	local parts = {}
	for _, d in copy:GetDescendants() do
		if d:IsA("BasePart") and d.Transparency < 1 then
			table.insert(parts, d)
		end
	end
	local main = table.remove(parts, 1)
	local ok, result = pcall(function()
		return GS:UnionAsync(main, parts, {
			CollisionFidelity = Enum.CollisionFidelity.Box,
			RenderFidelity = Enum.RenderFidelity.Automatic,
			SplitApart = false,
		})
	end)
	copy:Destroy()
	if not ok then
		warn("No se pudo fusionar " .. source.Name .. ": " .. tostring(result))
		return
	end
	local body = result[1]
	cleanPart(body)
	local model = Instance.new("Model")
	body.Parent = model
	model.PrimaryPart = body
	fitScale(model, SLIME_SIZE[level])
	finish(model, body, "Slime_" .. flavor .. "_" .. level)
	slimeCount += 1
end

for _, m in lib.Slimes.V1:GetChildren() do
	local flavor = m.Name:gsub("Slime$", "")
	prepareSlime(m, flavor, 1)
end
for _, m in lib.Slimes.Evolutions:GetChildren() do
	local flavor, level = m.Name:match("^(.-)SlimeV(%d)$")
	if flavor then
		prepareSlime(m, flavor, tonumber(level))
	end
end

---------------------------------------------------------------- Abejas
local beeCount = 0
for _, source in lib.Bees:GetChildren() do
	local model = source:Clone()
	for _, d in model:GetDescendants() do
		if d:IsA("Highlight") or d:IsA("LuaSourceContainer") then
			d:Destroy()
		end
	end
	fitScale(model, BEE_SIZE)
	-- Pieza raíz invisible en el centro; todas las demás soldadas a ella
	local cf, _ = model:GetBoundingBox()
	local root = Instance.new("Part")
	root.Size = Vector3.new(0.5, 0.5, 0.5)
	root.Transparency = 1
	root.CFrame = cf
	cleanPart(root)
	root.Parent = model
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d ~= root then
			cleanPart(d)
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = root
			weld.Part1 = d
			weld.Parent = d
		end
	end
	finish(model, root, "Bee_" .. source.Name)
	beeCount += 1
end

out.Parent = game.ReplicatedStorage
return string.format("ok: slimes=%d abejas=%d", slimeCount, beeCount)
