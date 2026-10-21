-- StarterGui/HUD/Modules/Confirm (ModuleScript)
-- Ventana "¿Seguro?" reutilizable. Espera la respuesta del jugador:
--   local yes = Confirm.Ask("¿Viajar?", "¿Quieres ir al Mundo AFK?", "¡Sí, vamos!")

local TweenService = game:GetService("TweenService")

local ClientSettings = require(script.Parent.ClientSettings)
local Sfx = require(script.Parent.Sfx)

local Confirm = {}

local hud = script.Parent.Parent
local layer = hud:WaitForChild("ConfirmLayer")
local dialog = layer:WaitForChild("ConfirmDialog")
local content = dialog:WaitForChild("Content")

local pending: BindableEvent? = nil

local function answer(value: boolean)
	if pending then
		local event = pending
		pending = nil
		layer.Visible = false
		event:Fire(value)
	end
end

content.YesButton.Activated:Connect(function()
	answer(true)
end)
content.NoButton.Activated:Connect(function()
	answer(false)
end)

function Confirm.IsOpen(): boolean
	return pending ~= nil
end

-- Devuelve true si el jugador dijo que sí
function Confirm.Ask(title: string, message: string, yesText: string?): boolean
	if pending then
		answer(false) -- cerrar la anterior
	end
	dialog.Title.Text = title
	content.Message.Text = message
	content.YesButton.Label.Text = yesText or "Sí"
	layer.Visible = true
	Sfx.Play("Open", 1.2)
	local scale = ClientSettings.GetPanelScale(dialog)
	dialog.UIScale.Scale = scale * 0.85
	TweenService:Create(dialog.UIScale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = scale }):Play()

	local event = Instance.new("BindableEvent")
	pending = event
	local result = event.Event:Wait()
	event:Destroy()
	return result
end

-- Cancelar desde fuera (por ejemplo, si el jugador se baja del portal)
function Confirm.Cancel()
	answer(false)
end

return Confirm
