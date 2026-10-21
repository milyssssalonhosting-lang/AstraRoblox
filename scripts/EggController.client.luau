-- StarterGui/HUD/Controllers/EggController (LocalScript)
-- Tienda de huevos: muestra precio y probabilidades de cada huevo, pide abrirlo
-- al servidor y enseña la animación: el huevo tiembla, destello y aparece la mascota.
-- Con efectos apagados (gráficos bajos) se salta la animación y muestra el resultado.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local eggRequest = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("EggRequest")

local hud = script.Parent.Parent
local Modules = hud:WaitForChild("Modules")
local UIEffects = require(Modules.UIEffects)
local PanelManager = require(Modules.PanelManager)
local ClientSettings = require(Modules.ClientSettings)
local Sfx = require(Modules.Sfx)
local Toast = require(Modules.Toast)
local PetViewport = require(Modules.PetViewport)

local player = Players.LocalPlayer
local panel = hud:WaitForChild("Panels"):WaitForChild("ShopPanel")
local eggsRow = panel.Content.Eggs
local cardTemplate = eggsRow.EggCardTemplate
local overlay = hud:WaitForChild("HatchOverlay")
local results = overlay.Results
local resultTemplate = results.ResultCardTemplate

while not player:GetAttribute("StatsReady") do
	player:GetAttributeChangedSignal("StatsReady"):Wait()
end

local busy = false
local canClose = false

---------------------------------------------------------------- Animación de abrir
local function clearResults()
	for _, child in results:GetChildren() do
		if child:IsA("Frame") and child ~= resultTemplate then
			child:Destroy()
		end
	end
end

local function showResults(list)
	clearResults()
	results.UIScale.Scale = ClientSettings.GetUIScale()
	for i, result in list do
		local pet = GameConfig.Pets[result.Pet]
		local rarity = GameConfig.Rarities[pet.Rarity]
		local card = resultTemplate:Clone()
		card.Name = "Result" .. i
		card.LayoutOrder = i
		card.Visible = true
		card.Icon.Text = pet.Icon
		card.NameText.Text = pet.Name
		card.RarityText.Text = pet.Rarity
		card.BoostText.Text = GameConfig.PetStatText(pet)
		card.UIGradient.Color = ColorSequence.new(rarity.Top, rarity.Bottom)
		card.NewBadge.Visible = result.New
		card.Parent = results
		PetViewport.Show(card.Icon, result.Pet)
		if UIEffects.Fancy() then
			card.UIScale.Scale = 0.2
			TweenService:Create(card.UIScale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
			if rarity.Order >= 4 then
				UIEffects.Glow(card) -- Legendario y Mítico brillan
			end
		end
	end
	results.Visible = true
end

local function playHatch(egg, list)
	overlay.Visible = true
	results.Visible = false
	overlay.ContinueText.Visible = false
	canClose = false
	local eggIcon = overlay.Egg
	eggIcon.Text = egg.Icon
	eggIcon.Visible = true
	eggIcon.Rotation = 0
	eggIcon.UIScale.Scale = ClientSettings.GetUIScale()

	if UIEffects.Fancy() then
		-- Tiembla cada vez más fuerte
		for i = 1, 6 do
			local angle = (if i % 2 == 0 then 1 else -1) * (6 + i * 3)
			TweenService:Create(eggIcon, TweenInfo.new(0.09), { Rotation = angle }):Play()
			Sfx.Play("Click", 0.8 + i * 0.08)
			task.wait(0.11)
		end
		eggIcon.Rotation = 0
		-- Destello blanco
		overlay.Flash.BackgroundTransparency = 0
		TweenService:Create(overlay.Flash, TweenInfo.new(0.45), { BackgroundTransparency = 1 }):Play()
	end

	eggIcon.Visible = false
	Sfx.Play("Claim")
	showResults(list)
	UIEffects.Confetti(overlay, results, 40)

	local anyNew = false
	for _, result in list do
		anyNew = anyNew or result.New
	end
	if anyNew then
		Toast.Show("📖 ¡Nueva mascota en el Index!", Toast.Good)
	end
	task.wait(0.4)
	overlay.ContinueText.Visible = true
	canClose = true
end

overlay.Activated:Connect(function()
	if canClose then
		overlay.Visible = false
		clearResults()
		busy = false
	end
end)

---------------------------------------------------------------- Abrir
local function open(egg, amount: number)
	if busy then
		return
	end
	if player:GetAttribute("RandomItemsRestricted") ~= false then
		Toast.Show("Los huevos no están disponibles en tu región", Toast.Bad)
		return
	end
	busy = true
	local ok, success, data = pcall(eggRequest.InvokeServer, eggRequest, egg.Id, amount)
	if ok and success then
		PanelManager.Close()
		playHatch(egg, data)
	else
		busy = false
		Toast.Show(if ok then data else "Error de conexión", Toast.Bad)
	end
end

---------------------------------------------------------------- Tarjetas de huevos
for index, egg in GameConfig.Eggs do
	local card = cardTemplate:Clone()
	card.Name = egg.Id
	card.LayoutOrder = index
	card.Visible = true
	card.Icon.Text = egg.Icon
	card.NameText.Text = egg.Name
	card.PriceText.Text = "$" .. GameConfig.FormatNumber(egg.Price)
	card.UIGradient.Color = ColorSequence.new(egg.Top, egg.Bottom)

	-- Probabilidades (ordenadas de más común a más rara)
	local chances = GameConfig.EggChances(egg)
	table.sort(chances, function(a, b)
		return a.Chance > b.Chance
	end)
	local oddsTemplate = card.Odds.OddsRowTemplate
	for order, entry in chances do
		local pet = GameConfig.Pets[entry.Pet]
		local row = oddsTemplate:Clone()
		row.Name = entry.Pet
		row.LayoutOrder = order
		row.Visible = true
		row.Icon.Text = pet.Icon
		row.NameText.Text = pet.Name
		row.ChanceText.Text = GameConfig.FormatChance(entry.Chance)
		row.ChanceText.TextColor3 = GameConfig.Rarities[pet.Rarity].Top
		row.Parent = card.Odds
	end

	card.Open1Button.Label.Text = "Abrir x1  ($" .. GameConfig.FormatNumber(egg.Price) .. ")"
	card.Open3Button.Label.Text = "Abrir x3  ($" .. GameConfig.FormatNumber(egg.Price * 3) .. ")"
	for _, button in { card.Open1Button, card.Open3Button } do
		button:SetAttribute("EffectsAttached", nil)
		UIEffects.AttachButton(button)
	end
	card.Open1Button.Activated:Connect(function()
		open(egg, 1)
	end)
	card.Open3Button.Activated:Connect(function()
		open(egg, 3)
	end)
	card.Parent = eggsRow
	if index == #GameConfig.Eggs then
		UIEffects.AutoShine(card.Open1Button, 4)
	end
end
