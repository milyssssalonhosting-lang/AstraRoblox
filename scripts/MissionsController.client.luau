-- StarterGui/HUD/Controllers/MissionsController (LocalScript)
-- Lista de misiones con barra de progreso y botón Reclamar. Las completas sin
-- reclamar van arriba y brillan; las reclamadas se van al fondo.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local rewardsRequest = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RewardsRequest")

local hud = script.Parent.Parent
local Modules = hud:WaitForChild("Modules")
local UIEffects = require(Modules.UIEffects)
local Sfx = require(Modules.Sfx)
local Toast = require(Modules.Toast)

local player = Players.LocalPlayer
local panel = hud:WaitForChild("Panels"):WaitForChild("MissionsPanel")
local list = panel.Content.List
local template = list.MissionRowTemplate
local alertDot = hud.Root.LeftMenu.MissionsButton:WaitForChild("Alert")

while not player:GetAttribute("StatsReady") do
	player:GetAttributeChangedSignal("StatsReady"):Wait()
end

local GREEN = ColorSequence.new(Color3.fromRGB(120, 255, 80), Color3.fromRGB(30, 190, 40))
local GRAY = ColorSequence.new(Color3.fromRGB(170, 170, 180), Color3.fromRGB(110, 110, 125))
local quick = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function getClaimed(): { [string]: boolean }
	local raw = player:GetAttribute("MissionsClaimed")
	local ok, result = pcall(HttpService.JSONDecode, HttpService, raw or "{}")
	return if ok and type(result) == "table" then result else {}
end

local function getStat(stat: string): number
	if stat == "Level" then
		return player:GetAttribute("Level") or 1
	end
	return player:GetAttribute("Stat_" .. stat) or 0
end

local function formatProgress(mission, value: number): string
	value = math.min(value, mission.Target)
	if mission.Stat == "PlaySeconds" then
		return string.format("%d/%d min", value // 60, mission.Target // 60)
	elseif mission.Stat == "MoneyEarned" then
		return "$" .. GameConfig.FormatNumber(value) .. "/$" .. GameConfig.FormatNumber(mission.Target)
	end
	return value .. "/" .. mission.Target
end

local rows = {}
local glows = {}

for index, mission in GameConfig.Missions do
	local row = template:Clone()
	row.Name = mission.Id
	row.Visible = true
	row.MissionText.Text = mission.Text
	row.Icon.Text = GameConfig.RewardIcon(mission.Rewards[1])
	local parts = {}
	for _, reward in mission.Rewards do
		table.insert(parts, GameConfig.RewardIcon(reward) .. " " .. GameConfig.RewardText(reward))
	end
	row.RewardText.Text = table.concat(parts, "   ")
	row.Parent = list
	row.ClaimButton:SetAttribute("EffectsAttached", nil)
	UIEffects.AttachButton(row.ClaimButton)
	rows[mission.Id] = { Row = row, Mission = mission, Index = index }

	row.ClaimButton.Activated:Connect(function()
		local ok, success, message = pcall(function()
			return rewardsRequest:InvokeServer("ClaimMission", mission.Id)
		end)
		if ok and success then
			Sfx.Play("Claim")
			UIEffects.Confetti(panel, row.ClaimButton, 26)
			Toast.Show("📜 " .. message, Toast.Good)
		elseif ok then
			Toast.Show(message, Toast.Bad)
		else
			Toast.Show("Error de conexión", Toast.Bad)
		end
	end)
end

local function refresh()
	local claimed = getClaimed()
	local anyReady = false
	for id, entry in rows do
		local row, mission = entry.Row, entry.Mission
		local value = getStat(mission.Stat)
		local done = value >= mission.Target
		local isClaimed = claimed[id] == true
		local ready = done and not isClaimed
		anyReady = anyReady or ready

		row.Bar.ProgressText.Text = if isClaimed then "¡Completada!" else formatProgress(mission, value)
		TweenService:Create(row.Bar.Fill, quick, { Size = UDim2.fromScale(math.clamp(value / mission.Target, 0, 1), 1) }):Play()
		row.ClaimButton.Visible = not isClaimed
		row.ClaimButton.Label.Text = if ready then "Reclamar" else "En curso"
		row.ClaimButton.UIGradient.Color = if ready then GREEN else GRAY
		row.ClaimButton.Active = ready
		-- Orden: listas para reclamar → en curso → reclamadas
		row.LayoutOrder = (if ready then 0 elseif isClaimed then 2000 else 1000) + entry.Index

		if ready and not glows[id] then
			glows[id] = UIEffects.Glow(row)
		elseif not ready and glows[id] then
			glows[id]()
			glows[id] = nil
		end
	end
	alertDot.Visible = anyReady
end

for _, attribute in { "Level", "MissionsClaimed", "Stat_MoneyEarned", "Stat_UpgradesBought", "Stat_PlaySeconds", "Stat_DailyClaims", "Stat_EggsOpened", "Stat_PetsFused", "Stat_RocketBest", "Stat_RocketRounds", "Stat_RocketGems", "Stat_RocketTrolls" } do
	player:GetAttributeChangedSignal(attribute):Connect(refresh)
end
refresh()
