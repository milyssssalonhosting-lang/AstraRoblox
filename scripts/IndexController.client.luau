-- StarterGui/HUD/Controllers/IndexController (LocalScript)
-- Index: todas las mascotas del juego. Las que ya descubriste se ven a color;
-- las que no, como "???" en gris, para dar ganas de conseguirlas.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))

local hud = script.Parent.Parent
local Modules = hud:WaitForChild("Modules")
local UIEffects = require(Modules.UIEffects)
local Sfx = require(Modules.Sfx)
local Toast = require(Modules.Toast)
local PetViewport = require(Modules.PetViewport)

local player = Players.LocalPlayer
local panel = hud:WaitForChild("Panels"):WaitForChild("IndexPanel")
local content = panel.Content
local grid = content.Grid
local template = grid.IndexCardTemplate

while not player:GetAttribute("StatsReady") do
	player:GetAttributeChangedSignal("StatsReady"):Wait()
end

local LOCKED = ColorSequence.new(Color3.fromRGB(80, 80, 95), Color3.fromRGB(45, 45, 60))

local function getSeen()
	local ok, result = pcall(HttpService.JSONDecode, HttpService, player:GetAttribute("IndexSeen") or "{}")
	return if ok and type(result) == "table" then result else {}
end

-- Orden: primero slimes, luego abejas; dentro, por rareza y nivel
local ids = GameConfig.PetIdsSorted()
local FAMILY_ORDER = { Slime = 1, Bee = 2 }
table.sort(ids, function(a, b)
	local pa, pb = GameConfig.Pets[a], GameConfig.Pets[b]
	local fa, fb = FAMILY_ORDER[pa.Family] or 9, FAMILY_ORDER[pb.Family] or 9
	if fa ~= fb then
		return fa < fb
	end
	local ra, rb = GameConfig.Rarities[pa.Rarity].Order, GameConfig.Rarities[pb.Rarity].Order
	if ra ~= rb then
		return ra < rb
	end
	if (pa.Level or 1) ~= (pb.Level or 1) then
		return (pa.Level or 1) < (pb.Level or 1)
	end
	return pa.Name < pb.Name
end)
local cards = {}
for order, petId in ids do
	local card = template:Clone()
	card.Name = petId
	card.LayoutOrder = order
	card.Visible = true
	card.Parent = grid
	card:SetAttribute("EffectsAttached", nil)
	UIEffects.AttachButton(card)
	card.Activated:Connect(function()
		local pet = GameConfig.Pets[petId]
		if getSeen()[petId] then
			Toast.Show(pet.Icon .. " " .. pet.Name .. " · " .. pet.Rarity .. " · " .. GameConfig.PetStatText(pet))
		else
			Toast.Show("❓ Mascota " .. pet.Rarity .. " sin descubrir")
		end
	end)
	cards[petId] = card
end

local lastSeenCount = nil
local function refresh()
	local seen = getSeen()
	local count = 0
	for _, petId in ids do
		local pet = GameConfig.Pets[petId]
		local card = cards[petId]
		local found = seen[petId] == true
		if found then
			count += 1
			local rarity = GameConfig.Rarities[pet.Rarity]
			card.UIGradient.Color = ColorSequence.new(rarity.Top, rarity.Bottom)
			card.Icon.Text = pet.Icon
			PetViewport.Show(card.Icon, petId)
			card.NameText.Text = pet.Name
			card.BoostText.Text = GameConfig.PetStatText(pet)
		else
			card.UIGradient.Color = LOCKED
			card.Icon.Text = "❓"
			PetViewport.Show(card.Icon, petId, { Silhouette = true }) -- silueta negra
			card.NameText.Text = "???"
			card.BoostText.Text = ""
		end
		-- La rareza siempre se ve: así sabes qué tan difícil es
		card.RarityText.Text = pet.Rarity
	end

	content.ProgressText.Text = "Descubiertas " .. count .. "/" .. #ids
	TweenService:Create(content.Bar.Fill, TweenInfo.new(0.3), { Size = UDim2.fromScale(count / #ids, 1) }):Play()

	if lastSeenCount and count > lastSeenCount then
		Sfx.Play("Claim", 1.15)
		Toast.Show("📖 ¡Nueva mascota en el Index!", Toast.Good)
	end
	lastSeenCount = count
end

player:GetAttributeChangedSignal("IndexSeen"):Connect(refresh)
refresh()
