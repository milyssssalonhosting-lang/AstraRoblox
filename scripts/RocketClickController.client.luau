-- StarterGui/HUD/Controllers/RocketClickController (LocalScript)
-- Para que el cohete suba hay que SPAMEAR: clic del mouse o Espacio en PC, y el
-- botón grande "🚀 ¡TAP!" en celular (también sirve en PC). Cada toque se manda al
-- servidor, que calcula la potencia según los clics por segundo.
-- El "🤖 Auto-clic" hace los clics por ti (en la Fase 4 tendrá un costo barato).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local Click = GameConfig.Rocket.Click
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local clickRemote = remotes:WaitForChild("RocketClick")
local toggleAutoClick = remotes:WaitForChild("RocketToggleAutoClick")
local state = ReplicatedStorage:WaitForChild("RocketState")

local hud = script.Parent.Parent
local Modules = hud:WaitForChild("Modules")
local UIEffects = require(Modules.UIEffects)
local Sfx = require(Modules.Sfx)
local ClientSettings = require(Modules.ClientSettings)

local player = Players.LocalPlayer
local root = hud:WaitForChild("Root")
local pad = root:WaitForChild("TapPad")
local tapButton = pad:WaitForChild("TapButton")
local autoButton = pad:WaitForChild("AutoClickButton")
local powerBar = pad:WaitForChild("PowerBar")
local hint = pad:WaitForChild("Hint")

local SEND_INTERVAL = 1 / Click.MaxCPS -- no mandar más rápido de lo que el servidor cuenta
local lastSent = 0
local lastTap = 0

local function flying(): boolean
	return state:GetAttribute("Phase") == "Flight" and (player:GetAttribute("RocketPad") or 0) > 0
end

local function myRocket(): Model?
	local rockets = workspace:FindFirstChild("ClientRockets")
	return rockets and rockets:FindFirstChild("Rocket_" .. player.Name) :: Model?
end

-- Efecto de cada toque: botón rebota y el cohete escupe una llamarada
local function tapFeedback()
	tapButton.UIScale.Scale = 0.88
	local rocket = myRocket()
	local exhaust = rocket and rocket:FindFirstChild("Root") and rocket.Root:FindFirstChild("Exhaust")
	if exhaust and UIEffects.Fancy() then
		local flame = exhaust:FindFirstChild("FlameFX") or exhaust:FindFirstChild("Fire")
		if flame then
			flame:Emit(4)
		end
	end
end

local function tap()
	if not flying() then
		return
	end
	lastTap = os.clock()
	tapFeedback()
	if os.clock() - lastSent >= SEND_INTERVAL then
		lastSent = os.clock()
		clickRemote:FireServer()
		Sfx.Play("Click", 0.9 + math.random() * 0.4)
	end
end

-- Botón (celular y PC)
tapButton.Activated:Connect(tap)

-- PC: clic en cualquier parte del mundo (no sobre botones) y Espacio
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		tap()
	end
end)
ContextActionService:BindAction("RocketTapSpace", function(_, inputState)
	if inputState == Enum.UserInputState.Begin and flying() then
		tap()
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Pass -- fuera del vuelo, Espacio sigue siendo saltar
end, false, Enum.KeyCode.Space, Enum.KeyCode.ButtonA)

-- Auto-clic
local function refreshAuto()
	local on = player:GetAttribute("RocketAutoClick") == true
	autoButton.Label.Text = if on then "🤖 Auto-clic: SÍ" else "🤖 Auto-clic: NO"
	autoButton.UIGradient.Color = if on
		then ColorSequence.new(Color3.fromRGB(120, 255, 80), Color3.fromRGB(30, 190, 40))
		else ColorSequence.new(Color3.fromRGB(170, 170, 185), Color3.fromRGB(105, 105, 125))
end
autoButton.Activated:Connect(function()
	toggleAutoClick:FireServer()
end)
player:GetAttributeChangedSignal("RocketAutoClick"):Connect(refreshAuto)
refreshAuto()
UIEffects.AttachButton(autoButton)

-- Cada cuadro: mostrar/ocultar, barra de potencia, auto-clic visual
local autoPulse = 0
RunService.RenderStepped:Connect(function(dt)
	local fly = flying()
	local preparing = state:GetAttribute("Phase") == "Prepare" and (player:GetAttribute("RocketPad") or 0) > 0
	pad.Visible = fly or preparing
	if not pad.Visible then
		return
	end
	pad.UIScale.Scale = ClientSettings.GetUIScale()
	tapButton.UIScale.Scale += (1 - tapButton.UIScale.Scale) * math.min(1, dt * 12)

	local auto = player:GetAttribute("RocketAutoClick") == true
	local power = player:GetAttribute("RocketPower") or Click.MinPower
	local fill = math.clamp(power / Click.MaxPower, 0, 1)
	powerBar.Fill.Size = powerBar.Fill.Size:Lerp(UDim2.fromScale(fill, 1), math.min(1, dt * 8))
	powerBar.PowerText.Text = "Potencia " .. math.floor(power * 100 + 0.5) .. "%"
	tapButton.Label.Text = if auto then "AUTO" else "¡TAP!"

	-- Si no estás spameando (y no hay auto-clic), parpadea el aviso
	local idle = fly and not auto and os.clock() - lastTap > 1
	hint.Visible = idle or preparing
	hint.Text = if preparing then "¡Prepárate para spamear clic / ESPACIO!" else "¡Spamea clic o ESPACIO para subir!"
	if idle then
		hint.TextTransparency = 0.3 + 0.3 * math.sin(os.clock() * 8)
		tapButton.Rotation = math.sin(os.clock() * 14) * 6 -- se mueve para llamar la atención
	else
		hint.TextTransparency = 0
		tapButton.Rotation = 0
	end

	-- Auto-clic: el botón "late" solo y salen llamaradas (lo cuenta el servidor)
	if fly and auto then
		autoPulse += dt
		if autoPulse >= 0.15 then
			autoPulse = 0
			tapFeedback()
		end
	end
end)
