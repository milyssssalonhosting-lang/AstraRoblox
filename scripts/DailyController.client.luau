-- StarterGui/HUD/Controllers/DailyController (LocalScript)
-- Panel de recompensas diarias (7 días). Muestra cada día como RECLAMADO,
-- RECLAMAR, cuenta regresiva o BLOQUEADO. El servidor decide si se puede reclamar.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local rewardsRequest = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RewardsRequest")

local hud = script.Parent.Parent
local Modules = hud:WaitForChild("Modules")
local UIEffects = require(Modules.UIEffects)
local Sfx = require(Modules.Sfx)
local Toast = require(Modules.Toast)

local player = Players.LocalPlayer
local panel = hud:WaitForChild("Panels"):WaitForChild("DailyPanel")
local content = panel.Content
local alertDot = hud.Root.LeftMenu.DailyButton:WaitForChild("Alert")

while not player:GetAttribute("StatsReady") do
	player:GetAttributeChangedSignal("StatsReady"):Wait()
end

local IS_STUDIO = RunService:IsStudio()
local COOLDOWN = if IS_STUDIO then GameConfig.Daily.StudioCooldownSeconds else GameConfig.Daily.CooldownSeconds
local RESET = if IS_STUDIO then GameConfig.Daily.StudioResetAfterSeconds else GameConfig.Daily.ResetAfterSeconds

local GRAY = ColorSequence.new(Color3.fromRGB(170, 170, 180), Color3.fromRGB(110, 110, 125))
local GREEN = ColorSequence.new(Color3.fromRGB(120, 255, 80), Color3.fromRGB(30, 190, 40))
local RED = ColorSequence.new(Color3.fromRGB(255, 90, 100), Color3.fromRGB(200, 25, 45))

-- Llenar íconos y textos de los 7 premios
for day, reward in GameConfig.Daily.Rewards do
	local card = content["Day" .. day]
	card.Icon.Text = GameConfig.RewardIcon(reward)
	card.RewardText.Text = GameConfig.RewardText(reward)
end

local function formatTime(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	local h, m, s = seconds // 3600, (seconds % 3600) // 60, seconds % 60
	if h > 0 then
		return string.format("%d:%02d:%02d", h, m, s)
	end
	return string.format("%d:%02d", m, s)
end

-- Estado actual: qué día toca y cuánto falta
local function getState()
	local now = workspace:GetServerTimeNow()
	local last = player:GetAttribute("DailyLastClaim") or 0
	local day = player:GetAttribute("DailyDay") or 0
	if last > 0 and now - last > RESET then
		day = 0 -- racha perdida
	end
	local waitLeft = if last > 0 then COOLDOWN - (now - last) else 0
	return day, waitLeft
end

local stopGlow: (() -> ())? = nil
local glowingCard: Frame? = nil

local function refresh()
	local claimedCount, waitLeft = getState()
	local canClaim = waitLeft <= 0
	alertDot.Visible = canClaim

	for day = 1, 7 do
		local card = content["Day" .. day]
		local claimButton = card.ClaimButton
		if day <= claimedCount then
			claimButton.Label.Text = "CLAIMED"
			claimButton.UIGradient.Color = GRAY
		elseif day == claimedCount + 1 then
			claimButton.Label.Text = if canClaim then "CLAIM" else formatTime(waitLeft)
			claimButton.UIGradient.Color = if canClaim then GREEN else RED
		else
			claimButton.Label.Text = "LOCKED"
			claimButton.UIGradient.Color = RED
		end
	end

	-- La tarjeta que se puede reclamar brilla
	local target = if canClaim then content["Day" .. (claimedCount + 1)] else nil
	if target ~= glowingCard then
		if stopGlow then
			stopGlow()
			stopGlow = nil
		end
		glowingCard = target
		if target then
			stopGlow = UIEffects.Glow(target)
		end
	end
end

for day = 1, 7 do
	local card = content["Day" .. day]
	card.ClaimButton.Activated:Connect(function()
		local claimedCount, waitLeft = getState()
		if day ~= claimedCount + 1 or waitLeft > 0 then
			return
		end
		local ok, success, message = pcall(function()
			return rewardsRequest:InvokeServer("ClaimDaily")
		end)
		if ok and success then
			Sfx.Play("Claim")
			UIEffects.Confetti(panel, card, 30)
			UIEffects.Bump(card)
			Toast.Show("🎁 " .. message, Toast.Good)
		else
			Toast.Show(if ok then message else "Error de conexión", Toast.Bad)
		end
		refresh()
	end)
end

player:GetAttributeChangedSignal("DailyDay"):Connect(refresh)
player:GetAttributeChangedSignal("DailyLastClaim"):Connect(refresh)

-- Actualizar la cuenta regresiva cada segundo
while true do
	refresh()
	task.wait(1)
end
