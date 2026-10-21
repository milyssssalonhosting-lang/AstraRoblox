-- StarterGui/HUD/Controllers/BattlePassController (LocalScript)
-- Battle Pass de 30 niveles con pista gratis y premium. Se llena con los premios
-- de GameConfig.BattlePass. Cada premio se reclama tocándolo (o con CLAIM ALL);
-- el servidor revisa nivel, pase premium y que no se haya reclamado antes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local rewardsRequest = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RewardsRequest")

local hud = script.Parent.Parent
local Modules = hud:WaitForChild("Modules")
local UIEffects = require(Modules.UIEffects)
local PanelManager = require(Modules.PanelManager)
local Sfx = require(Modules.Sfx)
local Toast = require(Modules.Toast)

local player = Players.LocalPlayer
local panel = hud:WaitForChild("Panels"):WaitForChild("BattlePassPanel")
local content = panel.Content
local header = content.Header
local track = content.Track
local template = track.LevelColumnTemplate
local alertDot = hud.Root.LeftMenu.PassButton:WaitForChild("Alert")

while not player:GetAttribute("StatsReady") do
	player:GetAttributeChangedSignal("StatsReady"):Wait()
end

local Pass = GameConfig.BattlePass
local quick = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function getClaimed()
	local raw = player:GetAttribute("BPClaimed")
	local ok, result = pcall(HttpService.JSONDecode, HttpService, raw or "{}")
	local claimed = if ok and type(result) == "table" then result else {}
	claimed.Free = claimed.Free or {}
	claimed.Premium = claimed.Premium or {}
	return claimed
end

local function getLevel(): number
	return math.min((player:GetAttribute("BPXP") or 0) // Pass.XPPerLevel, Pass.MaxLevel)
end

local function request(...)
	local ok, success, message = pcall(rewardsRequest.InvokeServer, rewardsRequest, ...)
	if not ok then
		return false, "Error de conexión"
	end
	return success, message
end

---------------------------------------------------------------- Construir las 30 columnas
local columns = {}
for level = 1, Pass.MaxLevel do
	local column = template:Clone()
	column.Name = "Level" .. level
	column.LayoutOrder = level
	column.Visible = true
	column.LevelNumber.Text = tostring(level)
	for _, trackName in { "Free", "Premium" } do
		local cell = column[trackName .. "Cell"]
		local reward = Pass.Levels[level][trackName]
		cell.Icon.Text = GameConfig.RewardIcon(reward)
		cell.Amount.Text = GameConfig.RewardText(reward)
		cell:SetAttribute("EffectsAttached", nil)
		UIEffects.AttachButton(cell)
		cell.Activated:Connect(function()
			local success, message = request("ClaimBattlePass", level, trackName)
			if success then
				Sfx.Play("Claim")
				UIEffects.Confetti(panel, cell, 22)
				Toast.Show("🎉 " .. message, Toast.Good)
			elseif getLevel() < level then
				Toast.Show("Llega al nivel " .. level .. " del pase", Toast.Bad)
			elseif trackName == "Premium" and not player:GetAttribute("BPPremium") then
				Toast.Show("Necesitas el pase Premium ⭐", Toast.Bad)
			end
		end)
	end
	column.Parent = track
	columns[level] = column
end

---------------------------------------------------------------- Actualizar estado
local glows = {}

local function setGlow(cell: GuiObject, on: boolean)
	if on and not glows[cell] then
		glows[cell] = UIEffects.Glow(cell)
	elseif not on and glows[cell] then
		glows[cell]()
		glows[cell] = nil
	end
end

local lastLevel = getLevel()
local function refresh()
	local level = getLevel()
	local xp = player:GetAttribute("BPXP") or 0
	local premium = player:GetAttribute("BPPremium") == true
	local claimed = getClaimed()
	local anyReady = false

	header.LevelBadge.LevelText.Text = tostring(level)
	header.SeasonText.Text = "SEASON " .. Pass.Season .. (if premium then "  ⭐ PREMIUM" else "")
	if level >= Pass.MaxLevel then
		header.XPBar.XPText.Text = "¡NIVEL MÁXIMO!"
		header.XPBar.Fill.Size = UDim2.fromScale(1, 1)
	else
		local into = xp - level * Pass.XPPerLevel
		header.XPBar.XPText.Text = into .. " / " .. Pass.XPPerLevel .. " XP"
		TweenService:Create(header.XPBar.Fill, quick, { Size = UDim2.fromScale(into / Pass.XPPerLevel, 1) }):Play()
	end
	header.UpgradeButton.Label.Text = if premium then "PREMIUM ✓" else "UPGRADE PASS"

	for lvl, column in columns do
		local reached = lvl <= level
		column.LevelTag.BackgroundColor3 = if reached then Color3.fromRGB(255, 190, 40) else Color3.fromRGB(60, 35, 110)
		for _, trackName in { "Free", "Premium" } do
			local cell = column[trackName .. "Cell"]
			local isClaimed = claimed[trackName][tostring(lvl)] == true
			local locked = not reached or (trackName == "Premium" and not premium)
			cell.Check.Visible = isClaimed
			cell.Lock.Visible = locked and not isClaimed
			local ready = not locked and not isClaimed
			anyReady = anyReady or ready
			setGlow(cell, ready and PanelManager.IsOpen(panel))
		end
	end
	alertDot.Visible = anyReady

	if level > lastLevel then
		Toast.Show("🎫 ¡Pase nivel " .. level .. "!", Toast.Good)
		UIEffects.Bump(header.LevelBadge)
	end
	lastLevel = level
end

-- Tiempo restante de la temporada
local function refreshTimer()
	local left = math.max(0, Pass.SeasonEnds - workspace:GetServerTimeNow())
	local days = left // 86400
	local hours = (left % 86400) // 3600
	header.EndsText.Text = string.format("⏱️ ENDS IN: %dd %dh", days, hours)
end

---------------------------------------------------------------- Botones
content.ClaimAllButton.Activated:Connect(function()
	local success, message = request("ClaimAllBattlePass")
	if success then
		Sfx.Play("Claim")
		UIEffects.Confetti(panel, content.ClaimAllButton, 40)
		Toast.Show("🎉 " .. message, Toast.Good)
	else
		Toast.Show(message, Toast.Bad)
	end
end)

header.UpgradeButton.Activated:Connect(function()
	if RunService:IsStudio() then
		-- Prueba: en Studio el botón activa/desactiva Premium gratis
		local _, message = request("DevTogglePremium")
		Toast.Show(message)
	else
		Toast.Show("Compra del pase con Robux: próximamente 💎")
	end
end)

-- Al abrir el panel, mover la pista al nivel actual
PanelManager.Opened:Connect(function(opened)
	if opened == panel then
		refresh()
		local target = columns[math.max(1, getLevel())]
		task.defer(function()
			local x = target.AbsolutePosition.X - track.AbsolutePosition.X + track.CanvasPosition.X - 120
			track.CanvasPosition = Vector2.new(math.max(0, x), 0)
		end)
	end
end)

for _, attribute in { "BPXP", "BPPremium", "BPClaimed" } do
	player:GetAttributeChangedSignal(attribute):Connect(refresh)
end
refresh()

while true do
	refreshTimer()
	task.wait(30)
end
