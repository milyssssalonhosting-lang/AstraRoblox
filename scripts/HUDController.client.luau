-- StarterGui/HUD/HUDController (LocalScript)
-- Parte principal del HUD: dinero animado, nivel, bonos, botones del menú y
-- panel de Mejoras. Los paneles Daily, Missions, Battle Pass y Settings tienen
-- su propio script en Controllers/. Las compras se PIDEN al servidor.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local purchaseUpgrade = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("PurchaseUpgrade")

local hud = script.Parent
local Modules = hud:WaitForChild("Modules")
local ClientSettings = require(Modules.ClientSettings)
local UIEffects = require(Modules.UIEffects)
local PanelManager = require(Modules.PanelManager)
local Sfx = require(Modules.Sfx)
local Toast = require(Modules.Toast)

local player = Players.LocalPlayer
local root = hud:WaitForChild("Root")
local panels = hud:WaitForChild("Panels")

local leftMenu = root:WaitForChild("LeftMenu")
local topTabs = root:WaitForChild("TopTabs")
local moneyFrame = root:WaitForChild("MoneyFrame")
local levelBar = root:WaitForChild("LevelBar")
local badges = root:WaitForChild("Badges")

local quick = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- Esperar a que el servidor prepare las estadísticas del jugador
while not player:GetAttribute("StatsReady") do
	player:GetAttributeChangedSignal("StatsReady"):Wait()
end

---------------------------------------------------------------- Tamaño y posición
local groups = { leftMenu, topTabs, moneyFrame, levelBar, badges }
local function applyLayout()
	local scale = ClientSettings.GetUIScale()
	for _, group in groups do
		group.UIScale.Scale = scale
	end
	for _, panel in panels:GetChildren() do
		if panel:FindFirstChild("UIScale") then
			panel.UIScale.Scale = ClientSettings.GetPanelScale(panel)
		end
	end

	-- En celular: abajo-izquierda es del joystick y abajo-derecha del botón de salto
	local touchOnly = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	if touchOnly then
		moneyFrame.AnchorPoint = Vector2.new(0, 0)
		moneyFrame.Position = UDim2.new(0, 14, 0, 4)
		badges.AnchorPoint = Vector2.new(1, 0.5)
		badges.Position = UDim2.new(1, -12, 0.45, 0)
	else
		moneyFrame.AnchorPoint = Vector2.new(0, 1)
		moneyFrame.Position = UDim2.new(0, 14, 1, -10)
		badges.AnchorPoint = Vector2.new(1, 1)
		badges.Position = UDim2.new(1, -12, 1, -10)
	end
end
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(applyLayout)
ClientSettings.Changed:Connect(function(key)
	if key == "HudScale" then
		applyLayout()
	end
end)
applyLayout()

---------------------------------------------------------------- Animaciones y sonido
UIEffects.AttachAll(hud)
UIEffects.AutoShine(leftMenu.DailyButton, 4)
UIEffects.AutoShine(leftMenu.PassButton, 5)
UIEffects.AutoShine(leftMenu.ShopButton, 6)
UIEffects.AutoShine(topTabs.UpgradesButton, 7)
Sfx.StartMusic()

---------------------------------------------------------------- Botones del menú
local function openPanel(name: string)
	return function()
		PanelManager.Toggle(panels[name])
	end
end
local comingSoon = panels:WaitForChild("ComingSoonPanel")
local function showComingSoon(title: string)
	return function()
		comingSoon.Title.Text = title
		PanelManager.Toggle(comingSoon)
	end
end

topTabs.UpgradesButton.Activated:Connect(openPanel("UpgradesPanel"))
topTabs.BaseButton.Activated:Connect(showComingSoon("My Base"))
leftMenu.SettingsButton.Activated:Connect(openPanel("SettingsPanel"))
leftMenu.DailyButton.Activated:Connect(openPanel("DailyPanel"))
leftMenu.MissionsButton.Activated:Connect(openPanel("MissionsPanel"))
leftMenu.PassButton.Activated:Connect(openPanel("BattlePassPanel"))
leftMenu.ShopButton.Activated:Connect(openPanel("ShopPanel"))
leftMenu.RebirthButton.Activated:Connect(openPanel("RebirthPanel"))
leftMenu.IndexButton.Activated:Connect(openPanel("IndexPanel"))
leftMenu.InventoryButton.Activated:Connect(openPanel("InventoryPanel"))
leftMenu.CodesButton.Activated:Connect(showComingSoon("Codes"))

-- Compras con Robux: llegan en la Fase 4 (monetización)
local function robuxLater()
	Toast.Show("Compras con Robux: próximamente 💎")
end
moneyFrame.AddMoneyButton.Activated:Connect(robuxLater)
for _, n in { 5, 10, 25 } do
	levelBar.BuyLevels["Plus" .. n .. "Button"].Activated:Connect(robuxLater)
end

---------------------------------------------------------------- Dinero animado
local moneyLabel = moneyFrame.MoneyLabel
local popups = moneyFrame.Popups
local displayedMoney = player:GetAttribute("Money") or 0
local lastMoney = displayedMoney

local function spawnPopup(amount: number, big: boolean)
	local label = moneyLabel:Clone()
	label.Name = "Popup"
	label.Text = "+$" .. GameConfig.FormatNumber(amount)
	label.Size = if big then UDim2.fromOffset(220, 42) else UDim2.fromOffset(160, 30)
	label.Position = UDim2.fromOffset(math.random(0, 80), 30)
	label.TextTransparency = 0
	label.Parent = popups
	local info = TweenInfo.new(if big then 1.3 else 0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(label, info, {
		Position = label.Position - UDim2.fromOffset(0, if big then 80 else 50),
		TextTransparency = 1,
	})
	TweenService:Create(label.UIStroke, info, { Transparency = 1 }):Play()
	tween.Completed:Connect(function()
		label:Destroy()
	end)
	tween:Play()
end

player:GetAttributeChangedSignal("Money"):Connect(function()
	local money = player:GetAttribute("Money") or 0
	local delta = money - lastMoney
	lastMoney = money
	if delta > 0 then
		-- Un premio grande (más de 10 segundos de ingreso) se celebra más
		local big = delta > (player:GetAttribute("MoneyPerSecond") or 0) * 10
		spawnPopup(delta, big)
		if big then
			Sfx.Play("Coin")
			UIEffects.Bump(moneyFrame)
		end
	end
end)

-- El botón "+" sigue al final del número, sin importar qué tan largo sea
local addMoneyButton = moneyFrame.AddMoneyButton
moneyLabel:GetPropertyChangedSignal("TextBounds"):Connect(function()
	addMoneyButton.Position = UDim2.fromOffset(moneyLabel.TextBounds.X + 10, 31)
end)

-- El número "rueda" hacia el valor real en lugar de saltar
RunService.RenderStepped:Connect(function(dt)
	local target = player:GetAttribute("Money") or 0
	displayedMoney += (target - displayedMoney) * math.min(1, dt * 8)
	if math.abs(target - displayedMoney) < 1 then
		displayedMoney = target
	end
	moneyLabel.Text = "$" .. GameConfig.FormatCommas(displayedMoney)
end)

---------------------------------------------------------------- Stats, nivel y bonos
-- 1 -> "1", 1.25 -> "1.25", 1.5 -> "1.5"
local function formatMultiplier(n: number): string
	return (string.format("%.2f", n):gsub("%.?0+$", ""))
end

local lastLevel = player:GetAttribute("Level") or 1
local function refreshStats()
	local friendBoost = player:GetAttribute("FriendBoost") or 0
	local perSecond = player:GetAttribute("MoneyPerSecond") or 0
	local multiplier = player:GetAttribute("MoneyMultiplierTotal") or 1
	local level = player:GetAttribute("Level") or 1
	local xp = player:GetAttribute("XP") or 0
	local needed = GameConfig.XPForLevel(level)

	moneyFrame.FriendBoostLabel.Text = string.format("Friend Boost: +%d%%", math.floor(friendBoost * 100 + 0.5))
	moneyFrame.PerSecondLabel.Text = "+$" .. GameConfig.FormatNumber(perSecond) .. "/s"
	moneyFrame.RebirthLabel.Text = "🔄 " .. (player:GetAttribute("Rebirths") or 0)

	levelBar.Bar.LevelText.Text = "Level " .. level
	levelBar.Bar.XPText.Text = xp .. "/" .. needed .. " XP"
	TweenService:Create(levelBar.Bar.Fill, quick, { Size = UDim2.fromScale(math.clamp(xp / needed, 0, 1), 1) }):Play()

	if level > lastLevel then
		Sfx.Play("Upgrade", 1.2)
		UIEffects.Bump(levelBar)
		UIEffects.Confetti(root, levelBar.Bar, 18)
		Toast.Show("⭐ ¡Nivel " .. level .. "!", Toast.Good)
	end
	lastLevel = level

	local petBoost = player:GetAttribute("PetBoost") or 0
	local rebirthMultiplier = GameConfig.RebirthMultiplier(player:GetAttribute("Rebirths") or 0)
	local afkMultiplier = if player:GetAttribute("InAFKZone") then GameConfig.AFK.Multiplier else 1
	local totalMultiplier = multiplier * (1 + friendBoost + petBoost) * rebirthMultiplier * afkMultiplier
	levelBar.MultiplierLabel.Text = "x" .. formatMultiplier(totalMultiplier) .. " Multiplier"
	badges.MoneyBadge.Value.Text = "x" .. formatMultiplier(multiplier)
	badges.RebirthBadge.Value.Text = "x" .. formatMultiplier(rebirthMultiplier)
	badges.VipBadge.Value.Text = "N/A"
end

for _, attribute in { "FriendBoost", "PetBoost", "MoneyPerSecond", "MoneyMultiplierTotal", "Level", "XP", "Rebirths", "InAFKZone" } do
	player:GetAttributeChangedSignal(attribute):Connect(refreshStats)
end
refreshStats()

---------------------------------------------------------------- Panel de Mejoras
local upgradesPanel = panels:WaitForChild("UpgradesPanel")
local list = upgradesPanel.Content.List
local template = list.UpgradeRowTemplate
local FILLED = Color3.fromRGB(255, 210, 50)
local EMPTY = Color3.fromRGB(255, 255, 255)

local function refreshRow(row: Frame, upgrade)
	local level = player:GetAttribute("Upgrade_" .. upgrade.Id) or 0
	local value = GameConfig.UpgradeValue(upgrade, level)
	row.NameText.Text = upgrade.DisplayName .. ": " .. string.format(upgrade.Format, value)
	for i = 1, 8 do
		local segment = row.Segments:FindFirstChild("S" .. i)
		segment.Visible = i <= upgrade.MaxLevel
		segment.BackgroundColor3 = if i <= level then FILLED else EMPTY
	end
	if level >= upgrade.MaxLevel then
		row.CostText.Text = "MAX"
		row.BuyButton.Label.Text = "Máximo"
	else
		row.CostText.Text = "$" .. GameConfig.FormatNumber(GameConfig.UpgradeCost(upgrade, level))
		row.BuyButton.Label.Text = "Comprar"
	end
end

for index, upgrade in GameConfig.Upgrades do
	local row = template:Clone()
	row.Name = upgrade.Id
	row.LayoutOrder = index
	row.Icon.Text = upgrade.Icon
	row.Visible = true
	row.Parent = list
	row.BuyButton:SetAttribute("EffectsAttached", nil)
	UIEffects.AttachButton(row.BuyButton)

	local busy = false
	row.BuyButton.Activated:Connect(function()
		if busy then
			return
		end
		busy = true
		local ok, success, message = pcall(function()
			return purchaseUpgrade:InvokeServer(upgrade.Id)
		end)
		busy = false
		if not ok then
			Toast.Show("Error de conexión, intenta de nuevo", Toast.Bad)
		elseif success then
			Sfx.Play("Upgrade")
			UIEffects.Bump(row.BuyButton)
			Toast.Show("⬆️ " .. message, Toast.Good)
		else
			Toast.Show(message, Toast.Bad)
		end
	end)

	player:GetAttributeChangedSignal("Upgrade_" .. upgrade.Id):Connect(function()
		refreshRow(row, upgrade)
	end)
	refreshRow(row, upgrade)
end
