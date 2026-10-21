-- StarterGui/HUD/Controllers/InventoryController (LocalScript)
-- Inventario: pestaña de mascotas con tarjetas por rareza, detalle de la mascota
-- elegida y botones Equipar / Guardar / Equipar mejores. Ropa y Armas: próximamente.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local inventoryRequest = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("InventoryRequest")

local hud = script.Parent.Parent
local Modules = hud:WaitForChild("Modules")
local UIEffects = require(Modules.UIEffects)
local Sfx = require(Modules.Sfx)
local Toast = require(Modules.Toast)
local PetViewport = require(Modules.PetViewport)

local player = Players.LocalPlayer
local panel = hud:WaitForChild("Panels"):WaitForChild("InventoryPanel")
local content = panel.Content
local grid = content.Grid
local template = grid.PetCardTemplate
local details = content.Details
local fusePanel = panel:WaitForChild("FusePanel")
local fuseCard = fusePanel.Card

while not player:GetAttribute("StatsReady") do
	player:GetAttributeChangedSignal("StatsReady"):Wait()
end

local GREEN = ColorSequence.new(Color3.fromRGB(120, 255, 80), Color3.fromRGB(30, 190, 40))
local PURPLE = ColorSequence.new(Color3.fromRGB(200, 120, 255), Color3.fromRGB(120, 45, 210))
local GRAY = ColorSequence.new(Color3.fromRGB(170, 170, 185), Color3.fromRGB(105, 105, 125))
local RED = ColorSequence.new(Color3.fromRGB(255, 90, 100), Color3.fromRGB(200, 25, 45))

local function getTable(name: string)
	local ok, result = pcall(HttpService.JSONDecode, HttpService, player:GetAttribute(name) or "{}")
	return if ok and type(result) == "table" then result else {}
end

local function countIn(list, petId: string): number
	local n = 0
	for _, id in list do
		if id == petId then
			n += 1
		end
	end
	return n
end

local function rarityGradient(rarity: string): ColorSequence
	local r = GameConfig.Rarities[rarity]
	return ColorSequence.new(r.Top, r.Bottom)
end

local selected: string? = nil
local cards: { [string]: TextButton } = {}

local function request(action: string, petId: string?)
	local ok, success, message = pcall(inventoryRequest.InvokeServer, inventoryRequest, action, petId)
	if ok and success then
		Sfx.Play("Upgrade", 1.3)
		Toast.Show("🐾 " .. message, Toast.Good)
	else
		Toast.Show(if ok then message else "Error de conexión", Toast.Bad)
	end
end

---------------------------------------------------------------- Detalle
local function showDetails()
	local pets = getTable("Pets")
	local equipped = getTable("Equipped")
	local pet = selected and GameConfig.Pets[selected]
	if not pet or (pets[selected] or 0) == 0 then
		details.BigIcon.Text = "❔"
		details.BigIcon.TextTransparency = 0
		local view = details.BigIcon:FindFirstChild("PetView")
		if view then
			view.Visible = false
		end
		details.FuseButton.Visible = false
		details.NameText.Text = "Elige una mascota"
		details.RarityText.Text = ""
		details.BoostText.Text = ""
		details.OwnedText.Text = ""
		details.EquipButton.Visible = false
		details.UIGradient.Color = ColorSequence.new(Color3.fromRGB(170, 170, 185), Color3.fromRGB(105, 105, 125))
		return
	end
	local owned = pets[selected]
	local equippedCount = countIn(equipped, selected)
	details.BigIcon.Text = pet.Icon
	PetViewport.Show(details.BigIcon, selected)
	details.BigIcon.PetView.Visible = true
	details.NameText.Text = pet.Name
	details.RarityText.Text = pet.Rarity
	details.BoostText.Text = GameConfig.PetStatText(pet)
	details.OwnedText.Text = "Tienes " .. owned .. " · Equipadas " .. equippedCount
	details.UIGradient.Color = rarityGradient(pet.Rarity)
	details.EquipButton.Visible = true
	-- Fusionar (slimes y abejas que tienen siguiente nivel)
	details.FuseButton.Visible = pet.Next ~= nil
	if pet.Next then
		local canFuse = owned >= GameConfig.FuseAmount
		details.FuseButton.Label.Text = string.format("Fusionar %d → Nv.%d (%d/%d)", GameConfig.FuseAmount, pet.Level + 1, math.min(owned, GameConfig.FuseAmount), GameConfig.FuseAmount)
		details.FuseButton.UIGradient.Color = if canFuse then PURPLE else GRAY
	end
	-- Si ya tienes todas las de este tipo equipadas, el botón las guarda
	local canEquipMore = equippedCount < owned and #equipped < GameConfig.MaxEquippedPets
	if canEquipMore then
		details.EquipButton.Label.Text = "Equipar"
		details.EquipButton.UIGradient.Color = GREEN
	elseif equippedCount > 0 then
		details.EquipButton.Label.Text = "Guardar"
		details.EquipButton.UIGradient.Color = RED
	else
		details.EquipButton.Label.Text = "Espacios llenos"
		details.EquipButton.UIGradient.Color = RED
	end
end

---------------------------------------------------------------- Tarjetas
local function refresh()
	local pets = getTable("Pets")
	local equipped = getTable("Equipped")
	local any = false

	for petId, pet in GameConfig.Pets do
		local owned = pets[petId] or 0
		local card = cards[petId]
		if owned > 0 and not card then
			card = template:Clone()
			card.Name = petId
			card.Icon.Text = pet.Icon
			PetViewport.Show(card.Icon, petId)
			card.NameText.Text = pet.Name
			card.UIGradient.Color = rarityGradient(pet.Rarity)
			card:SetAttribute("EffectsAttached", nil)
			UIEffects.AttachButton(card)
			card.Activated:Connect(function()
				selected = petId
				showDetails()
			end)
			card.Parent = grid
			cards[petId] = card
		end
		if card then
			card.Visible = owned > 0
			card.CountText.Text = "x" .. owned
			card.EquippedMark.Visible = countIn(equipped, petId) > 0
			-- Equipadas primero, luego por rareza (de mayor a menor)
			-- Equipadas primero, luego por rareza y nivel (de mayor a menor)
			card.LayoutOrder = (if card.EquippedMark.Visible then 0 else 100) - GameConfig.Rarities[pet.Rarity].Order * 3 - (pet.Level or 1)
		end
		any = any or owned > 0
	end

	content.EmptyText.Visible = not any
	content.EquippedText.Text = "Equipadas " .. #equipped .. "/" .. GameConfig.MaxEquippedPets
	content.BoostText.Text = GameConfig.PetStatText({
		Boost = player:GetAttribute("PetBoost"),
		Rocket = player:GetAttribute("PetRocket"),
		XP = player:GetAttribute("PetXP"),
		Speed = player:GetAttribute("PetSpeed"),
	})
	showDetails()
end

details.EquipButton.Activated:Connect(function()
	if not selected then
		return
	end
	local label = details.EquipButton.Label.Text
	if label == "Equipar" then
		request("Equip", selected)
	elseif label == "Guardar" then
		request("Unequip", selected)
	else
		Toast.Show("Guarda otra mascota para liberar un espacio", Toast.Bad)
	end
end)
---------------------------------------------------------------- Mini-menú de fusión
-- 3 copias → la del siguiente nivel, con sus bonos. El servidor revisa y fusiona.
local fusing: string? = nil
local busyFusing = false
local slotHome: { [Instance]: UDim2 } = {}
for i = 1, 3 do
	local slot = fuseCard["Slot" .. i]
	slotHome[slot] = slot.Position
end

local function openFuse(petId: string)
	local pet = GameConfig.Pets[petId]
	local nextPet = pet and pet.Next and GameConfig.Pets[pet.Next]
	if not nextPet then
		return
	end
	fusing = petId
	for i = 1, 3 do
		local slot = fuseCard["Slot" .. i]
		slot.Position = slotHome[slot]
		slot.Visible = true
		slot.UIGradient.Color = rarityGradient(pet.Rarity)
		slot.Icon.Text = pet.Icon
		PetViewport.Show(slot.Icon, petId)
	end
	local result = fuseCard.Result
	result.UIGradient.Color = rarityGradient(nextPet.Rarity)
	result.Icon.Text = nextPet.Icon
	PetViewport.Show(result.Icon, pet.Next)
	result.LevelBadge.Text = "Nv." .. (nextPet.Level or 2)
	fuseCard.FromText.Text = GameConfig.FuseAmount .. "x " .. pet.Name
	fuseCard.FromStats.Text = "Cada una: " .. GameConfig.PetStatText(pet)
	fuseCard.ResultName.Text = nextPet.Name
	fuseCard.ResultStats.Text = GameConfig.PetStatText(nextPet)
	fusePanel.Visible = true
	fuseCard.UIScale.Scale = 0.4
	TweenService:Create(fuseCard.UIScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	Sfx.Play("Open", 1.2)
end

local function closeFuse()
	fusePanel.Visible = false
	fusing = nil
end

details.FuseButton.Activated:Connect(function()
	if not selected then
		return
	end
	local owned = getTable("Pets")[selected] or 0
	if owned < GameConfig.FuseAmount then
		Toast.Show("Necesitas " .. GameConfig.FuseAmount .. " iguales para fusionar (tienes " .. owned .. ")", Toast.Bad)
		return
	end
	openFuse(selected)
end)

fuseCard.CancelButton.Activated:Connect(closeFuse)
fuseCard.ConfirmButton.Activated:Connect(function()
	if not fusing or busyFusing then
		return
	end
	busyFusing = true
	local petId = fusing
	local ok, success, message = pcall(inventoryRequest.InvokeServer, inventoryRequest, "Fuse", petId)
	if ok and success then
		-- Animación: las 3 copias vuelan al resultado, destello y rebote
		local result = fuseCard.Result
		for i = 1, 3 do
			local slot = fuseCard["Slot" .. i]
			TweenService:Create(slot, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Position = UDim2.fromOffset(result.Position.X.Offset + 33, result.Position.Y.Offset + 33) }):Play()
		end
		task.wait(0.35)
		for i = 1, 3 do
			fuseCard["Slot" .. i].Visible = false
		end
		result.UIScale.Scale = 1.4
		TweenService:Create(result.UIScale, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		Sfx.Play("Claim", 1.1)
		UIEffects.Confetti(panel, result, 50)
		Toast.Show("✨ Fusión: " .. message, Toast.Good)
		local fused = GameConfig.Pets[petId]
		selected = fused.Next -- mostrar la nueva mascota
		refresh()
		task.wait(1.2)
		closeFuse()
	else
		Toast.Show(if ok then message else "Error de conexión", Toast.Bad)
	end
	busyFusing = false
end)
panel:GetPropertyChangedSignal("Visible"):Connect(function()
	if not panel.Visible then
		closeFuse()
	end
end)
details.EquipBestButton.Activated:Connect(function()
	request("EquipBest")
end)

-- Ropa y Armas llegan después
content.Tabs.ClothesTab.Activated:Connect(function()
	Toast.Show("👕 Ropa: próximamente")
end)
content.Tabs.WeaponsTab.Activated:Connect(function()
	Toast.Show("⚔️ Armas: próximamente")
end)

for _, attribute in { "Pets", "Equipped", "PetBoost", "PetRocket", "PetXP", "PetSpeed" } do
	player:GetAttributeChangedSignal(attribute):Connect(refresh)
end
refresh()
