-- StarterGui/HUD/Controllers/SettingsController (LocalScript)
-- Panel de ajustes: volumen de música, volumen de efectos, tamaño del HUD y
-- efectos visuales (Auto = según la calidad de gráficos del jugador).

local UserInputService = game:GetService("UserInputService")

local hud = script.Parent.Parent
local Modules = hud:WaitForChild("Modules")
local ClientSettings = require(Modules.ClientSettings)
local Sfx = require(Modules.Sfx)
local Toast = require(Modules.Toast)

local panel = hud:WaitForChild("Panels"):WaitForChild("SettingsPanel")
local list = panel.Content.List

---------------------------------------------------------------- Ajustes guardados
-- Al entrar se aplican los ajustes que el servidor cargó; al cambiarlos se
-- mandan al servidor (que los valida y los guarda con el resto del progreso).
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local saveSettings = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("SaveSettings")
local player = Players.LocalPlayer

while not player:GetAttribute("StatsReady") do
	player:GetAttributeChangedSignal("StatsReady"):Wait()
end

local okDecode, saved = pcall(HttpService.JSONDecode, HttpService, player:GetAttribute("Settings") or "{}")
if okDecode and type(saved) == "table" then
	for key in ClientSettings.Values do
		if saved[key] ~= nil and type(saved[key]) == type(ClientSettings.Values[key]) then
			ClientSettings.Set(key, saved[key])
		end
	end
end

-- Enviar con una pausa: mientras arrastras la barra no se manda cada movimiento
local pendingSend = false
ClientSettings.Changed:Connect(function(key)
	if ClientSettings.Values[key] == nil or pendingSend then
		return
	end
	pendingSend = true
	task.delay(1.2, function()
		pendingSend = false
		saveSettings:FireServer(ClientSettings.Values)
	end)
end)

-- Conecta una barra deslizable a un ajuste. toValue/fromValue convierten 0..1 <-> valor real.
local function bindSlider(row: Frame, key: string, toValue, fromValue, format)
	local slider = row.Slider
	local knob = slider.Knob
	local fill = slider.Fill
	local valueText = row.ValueText
	local dragging = false

	local function show(alpha: number)
		fill.Size = UDim2.fromScale(alpha, 1)
		knob.Position = UDim2.fromScale(alpha, 0.5)
		valueText.Text = format(toValue(alpha))
	end

	local function setFromX(x: number)
		local alpha = math.clamp((x - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
		show(alpha)
		ClientSettings.Set(key, toValue(alpha))
	end

	local function begin(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			setFromX(input.Position.X)
		end
	end
	slider.InputBegan:Connect(begin)
	knob.InputBegan:Connect(begin)
	-- Un toque simple (sin arrastrar) también mueve la barra
	slider.Activated:Connect(function(input: InputObject)
		if input then
			setFromX(input.Position.X)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			setFromX(input.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			dragging = false
			if key == "SfxVolume" then
				Sfx.Play("Click") -- para escuchar cómo quedó
			end
		end
	end)

	show(fromValue(ClientSettings.Get(key)))
end

local function percent(v: number): string
	return math.floor(v * 100 + 0.5) .. "%"
end
local function identity(v: number): number
	return v
end

bindSlider(list.MusicRow, "MusicVolume", identity, identity, percent)
bindSlider(list.SfxRow, "SfxVolume", identity, identity, percent)

local hudLimits = ClientSettings.Limits.HudScale
bindSlider(list.HudScaleRow, "HudScale", function(alpha)
	-- pasos de 5% para que no tiemble
	local value = hudLimits.Min + alpha * (hudLimits.Max - hudLimits.Min)
	return math.floor(value * 20 + 0.5) / 20
end, function(value)
	return (value - hudLimits.Min) / (hudLimits.Max - hudLimits.Min)
end, percent)

-- Efectos visuales: Auto → On → Off
local modes = { "Auto", "On", "Off" }
local modeNames = { Auto = "Auto", On = "Sí", Off = "No" }
local modeButton = list.EffectsRow.ModeButton
local function showMode()
	local mode = ClientSettings.Get("EffectsMode")
	modeButton.Label.Text = modeNames[mode]
end
modeButton.Activated:Connect(function()
	local current = table.find(modes, ClientSettings.Get("EffectsMode")) or 1
	local nextMode = modes[current % #modes + 1]
	ClientSettings.Set("EffectsMode", nextMode)
	showMode()
	if nextMode == "Auto" then
		Toast.Show("Efectos: según tu calidad de gráficos")
	elseif nextMode == "On" then
		Toast.Show("Efectos: siempre encendidos ✨")
	else
		Toast.Show("Efectos: apagados (mejor rendimiento)")
	end
end)
showMode()
