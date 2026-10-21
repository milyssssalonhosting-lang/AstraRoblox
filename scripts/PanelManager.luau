-- StarterGui/HUD/Modules/PanelManager (ModuleScript)
-- Abre y cierra los paneles del HUD (solo uno a la vez) con fondo oscuro y "pop".
-- Cualquier script puede usarlo: PanelManager.Open(panel), PanelManager.Close().

local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")

local ClientSettings = require(script.Parent.ClientSettings)
local Sfx = require(script.Parent.Sfx)

local PanelManager = {}

local hud = script.Parent.Parent
local dim: GuiButton = hud:WaitForChild("Root"):WaitForChild("Dim")
local pop = TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local current: GuiObject? = nil
local opened = Instance.new("BindableEvent")
PanelManager.Opened = opened.Event -- (panel)

function PanelManager.Close()
	if current then
		current.Visible = false
		current = nil
	end
	dim.Visible = false
	GuiService.SelectedObject = nil
end

function PanelManager.Open(panel: GuiObject)
	if current == panel then
		return
	end
	PanelManager.Close()
	current = panel
	dim.Visible = true
	panel.Visible = true
	Sfx.Play("Open", 1.1)

	local scale = panel:FindFirstChild("UIScale")
	if scale then
		local target = ClientSettings.GetPanelScale(panel)
		if GuiService.ReducedMotionEnabled then
			scale.Scale = target
		else
			scale.Scale = target * 0.85
			TweenService:Create(scale, pop, { Scale = target }):Play()
		end
	end
	opened:Fire(panel)
end

function PanelManager.Toggle(panel: GuiObject)
	if current == panel then
		PanelManager.Close()
	else
		PanelManager.Open(panel)
	end
end

function PanelManager.IsOpen(panel: GuiObject): boolean
	return current == panel
end

-- Clic en el fondo oscuro: cierra solo si fue FUERA del panel abierto
-- (si no, tocar el fondo del panel o una barra deslizable lo cerraría)
dim.Activated:Connect(function(input: InputObject)
	if current and input then
		local position = Vector2.new(input.Position.X, input.Position.Y)
		local topLeft = current.AbsolutePosition
		local bottomRight = topLeft + current.AbsoluteSize
		local inside = position.X >= topLeft.X
			and position.X <= bottomRight.X
			and position.Y >= topLeft.Y
			and position.Y <= bottomRight.Y
		if inside then
			return
		end
	end
	PanelManager.Close()
end)

-- Botón X de cada panel
for _, panel in hud:WaitForChild("Panels"):GetChildren() do
	local close = panel:FindFirstChild("CloseButton")
	if close then
		close.Activated:Connect(PanelManager.Close)
	end
end

return PanelManager
