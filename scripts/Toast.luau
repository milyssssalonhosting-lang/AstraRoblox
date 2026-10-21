-- StarterGui/HUD/Modules/Toast (ModuleScript)
-- Mensajito arriba de la pantalla ("¡Misión completada!", "No tienes dinero"...).

local TweenService = game:GetService("TweenService")

local Toast = {}

local toast: TextLabel = script.Parent.Parent:WaitForChild("Root"):WaitForChild("Toast")
local token = 0

function Toast.Show(text: string, color: Color3?)
	token += 1
	local my = token
	toast.Text = text
	toast.TextColor3 = color or Color3.fromRGB(255, 240, 120)
	toast.Visible = true
	toast.TextTransparency = 0
	toast.UIStroke.Transparency = 0
	task.delay(2, function()
		if token ~= my then
			return
		end
		local fade = TweenInfo.new(0.3)
		TweenService:Create(toast, fade, { TextTransparency = 1 }):Play()
		TweenService:Create(toast.UIStroke, fade, { Transparency = 1 }):Play()
		task.wait(0.3)
		if token == my then
			toast.Visible = false
		end
	end)
end

Toast.Good = Color3.fromRGB(140, 255, 100)
Toast.Bad = Color3.fromRGB(255, 120, 120)

return Toast
