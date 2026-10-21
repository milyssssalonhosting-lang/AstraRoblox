-- StarterGui/HUD/Controllers/RebirthController (LocalScript)
-- Panel de Rebirth: cuántos llevas, bono actual y siguiente, barra de dinero
-- hacia el costo y botón con confirmación. El servidor valida todo.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local rebirthRequest = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RebirthRequest")

local hud = script.Parent.Parent
local Modules = hud:WaitForChild("Modules")
local Confirm = require(Modules.Confirm)
local Toast = require(Modules.Toast)
local Sfx = require(Modules.Sfx)
local UIEffects = require(Modules.UIEffects)

local player = Players.LocalPlayer
local panel = hud:WaitForChild("Panels"):WaitForChild("RebirthPanel")
local content = panel.Content

while not player:GetAttribute("StatsReady") do
	player:GetAttributeChangedSignal("StatsReady"):Wait()
end

local GREEN = ColorSequence.new(Color3.fromRGB(120, 255, 80), Color3.fromRGB(30, 190, 40))
local GRAY = ColorSequence.new(Color3.fromRGB(170, 170, 185), Color3.fromRGB(105, 105, 125))

local function formatMultiplier(n: number): string
	return (string.format("%.2f", n):gsub("%.?0+$", ""))
end

local function refresh()
	local rebirths = player:GetAttribute("Rebirths") or 0
	local money = player:GetAttribute("Money") or 0
	local cost = GameConfig.RebirthCost(rebirths)
	content.CountText.Text = "🔄 Rebirths: " .. rebirths
	content.BonusText.Text = "Dinero: x" .. formatMultiplier(GameConfig.RebirthMultiplier(rebirths))
		.. "  →  x" .. formatMultiplier(GameConfig.RebirthMultiplier(rebirths + 1))
	content.Bar.MoneyText.Text = "$" .. GameConfig.FormatNumber(math.min(money, cost)) .. " / $" .. GameConfig.FormatNumber(cost)
	TweenService:Create(content.Bar.Fill, TweenInfo.new(0.2), { Size = UDim2.fromScale(math.clamp(money / cost, 0, 1), 1) }):Play()
	local ready = money >= cost
	content.RebirthButton.UIGradient.Color = if ready then GREEN else GRAY
	content.RebirthButton.Label.Text = if ready then "REBIRTH" else "Te falta $" .. GameConfig.FormatNumber(cost - money)
end

content.RebirthButton.Activated:Connect(function()
	local rebirths = player:GetAttribute("Rebirths") or 0
	if (player:GetAttribute("Money") or 0) < GameConfig.RebirthCost(rebirths) then
		Toast.Show("Todavía no tienes suficiente dinero", Toast.Bad)
		return
	end
	local yes = Confirm.Ask(
		"¿Hacer Rebirth?",
		"Pierdes tu dinero y mejoras, pero ganarás x"
			.. formatMultiplier(GameConfig.RebirthMultiplier(rebirths + 1))
			.. " para siempre.",
		"¡Rebirth!"
	)
	if not yes then
		return
	end
	local ok, success, message = pcall(rebirthRequest.InvokeServer, rebirthRequest)
	if ok and success then
		Sfx.Play("Upgrade", 0.9)
		UIEffects.Confetti(panel, content.RebirthButton, 50)
		Toast.Show("🔄 " .. message, Toast.Good)
	else
		Toast.Show(if ok then message else "Error de conexión", Toast.Bad)
	end
end)

for _, attribute in { "Rebirths", "Money" } do
	player:GetAttributeChangedSignal(attribute):Connect(function()
		if panel.Visible then
			refresh()
		end
	end)
end
panel:GetPropertyChangedSignal("Visible"):Connect(refresh)
refresh()
