-- Herramienta (no va dentro del juego): construye en StarterGui.HUD
--  * RebirthPanel: info y botón de Rebirth.
--  * ConfirmDialog: ventana "¿Seguro?" reutilizable (viajar a otro mundo, rebirth…).
--  * AFKBadge: aviso arriba cuando estás en la zona AFK.

local hud = game.StarterGui.HUD
local panels = hud.Panels
local FONT = Enum.Font.FredokaOne
local INK = Color3.fromRGB(28, 22, 40)
local WHITE = Color3.new(1, 1, 1)

local function new(class, props, parent)
	local i = Instance.new(class)
	for k, v in props do
		i[k] = v
	end
	if parent then
		i.Parent = parent
	end
	return i
end
local function corner(p, r)
	return new("UICorner", { CornerRadius = UDim.new(0, r or 10) }, p)
end
local function stroke(p, t)
	return new("UIStroke", { Color = INK, Thickness = t or 3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, p)
end
local function gradient(p, top, bottom)
	return new("UIGradient", { Rotation = 90, Color = ColorSequence.new(top, bottom) }, p)
end
local function label(props, parent)
	local l = new("TextLabel", { BackgroundTransparency = 1, Font = FONT, TextColor3 = WHITE, TextScaled = true }, parent)
	for k, v in props do
		l[k] = v
	end
	new("UIStroke", { Color = INK, Thickness = 2.5 }, l)
	return l
end
local function button(name, parent, pos, size, top, bottom, text)
	local b = new("TextButton", { Name = name, Position = pos, Size = size, BackgroundColor3 = WHITE, AutoButtonColor = false, Text = "" }, parent)
	corner(b, 8)
	stroke(b, 3)
	gradient(b, top, bottom)
	new("UIScale", {}, b)
	label({ Name = "Label", Text = text, Size = UDim2.new(1, -12, 0.7, 0), Position = UDim2.new(0, 6, 0.15, 0) }, b)
	return b
end
local GREEN = { Color3.fromRGB(120, 255, 80), Color3.fromRGB(30, 190, 40) }
local RED = { Color3.fromRGB(255, 90, 100), Color3.fromRGB(200, 25, 45) }
local PURPLE = { Color3.fromRGB(230, 130, 255), Color3.fromRGB(140, 45, 210) }

local function makePanel(name, title, top, bottom, w, h, parent)
	local old = (parent or panels):FindFirstChild(name)
	if old then
		old:Destroy()
	end
	local p = new("Frame", { Name = name, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.53), Size = UDim2.fromOffset(w, h), BackgroundColor3 = WHITE, Visible = false, Active = true }, parent or panels)
	corner(p, 14)
	stroke(p, 4)
	gradient(p, top, bottom)
	new("UIScale", {}, p)
	label({ Name = "Title", Text = title, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.fromOffset(w * 0.75, 60), ZIndex = 3 }, p).UIStroke.Thickness = 4
	local content = new("Frame", { Name = "Content", Position = UDim2.fromOffset(18, 40), Size = UDim2.new(1, -36, 1, -56), BackgroundTransparency = 1 }, p)
	return p, content
end

---------------------------------------------------------------- Rebirth
do
	local p, c = makePanel("RebirthPanel", "Rebirth", Color3.fromRGB(200, 120, 255), Color3.fromRGB(110, 40, 190), 560, 430)
	button("CloseButton", p, UDim2.new(1, -30, 0, -22), UDim2.fromOffset(52, 52), RED[1], RED[2], "X").ZIndex = 3
	label({ Name = "CountText", Text = "🔄 Rebirths: 0", Size = UDim2.new(1, 0, 0, 34), Position = UDim2.fromOffset(0, 10) }, c)
	label({ Name = "BonusText", Text = "Ahora: x1  →  Siguiente: x1.5", Size = UDim2.new(1, 0, 0, 30), Position = UDim2.fromOffset(0, 50), TextColor3 = Color3.fromRGB(150, 255, 110) }, c)
	local bar = new("Frame", { Name = "Bar", Size = UDim2.new(1, -20, 0, 32), Position = UDim2.fromOffset(10, 96), BackgroundColor3 = Color3.fromRGB(40, 20, 70) }, c)
	corner(bar, 10)
	stroke(bar, 3)
	local fill = new("Frame", { Name = "Fill", Size = UDim2.fromScale(0.3, 1), BackgroundColor3 = WHITE }, bar)
	corner(fill, 10)
	gradient(fill, Color3.fromRGB(140, 255, 100), Color3.fromRGB(40, 190, 50))
	label({ Name = "MoneyText", Text = "$0 / $1M", Size = UDim2.new(1, -12, 0.8, 0), Position = UDim2.new(0, 6, 0.1, 0), ZIndex = 2 }, bar)
	label({ Name = "LoseText", Text = "❌ Pierdes: dinero y mejoras", TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -20, 0, 26), Position = UDim2.fromOffset(10, 146), TextColor3 = Color3.fromRGB(255, 160, 160) }, c)
	label({ Name = "KeepText", Text = "✅ Conservas: mascotas, nivel, pase y huevos", TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -20, 0, 26), Position = UDim2.fromOffset(10, 178), TextColor3 = Color3.fromRGB(170, 255, 170) }, c)
	button("RebirthButton", c, UDim2.new(0.5, -130, 1, -66), UDim2.fromOffset(260, 58), GREEN[1], GREEN[2], "REBIRTH")
end

---------------------------------------------------------------- Diálogo de confirmación (encima de todo)
do
	local old = hud:FindFirstChild("ConfirmLayer")
	if old then
		old:Destroy()
	end
	local layer = new("TextButton", { Name = "ConfirmLayer", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45, Text = "", AutoButtonColor = false, Visible = false, ZIndex = 6, Selectable = false }, hud)
	local p, c = makePanel("ConfirmDialog", "¿Viajar?", Color3.fromRGB(120, 210, 255), Color3.fromRGB(40, 110, 230), 480, 280, layer)
	p.Visible = true
	p.ZIndex = 7
	label({ Name = "Message", Text = "¿Quieres ir a otro mundo?", Size = UDim2.new(1, 0, 0, 110), Position = UDim2.fromOffset(0, 16) }, c)
	button("YesButton", c, UDim2.new(0, 10, 1, -64), UDim2.new(0.5, -20, 0, 54), GREEN[1], GREEN[2], "¡Sí, vamos!")
	button("NoButton", c, UDim2.new(0.5, 10, 1, -64), UDim2.new(0.5, -20, 0, 54), RED[1], RED[2], "Cancelar")
end

---------------------------------------------------------------- Aviso de zona AFK
do
	local old = hud.Root:FindFirstChild("AFKBadge")
	if old then
		old:Destroy()
	end
	local badge = new("Frame", { Name = "AFKBadge", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 112), Size = UDim2.fromOffset(300, 44), BackgroundColor3 = WHITE, Visible = false }, hud.Root)
	corner(badge, 22)
	stroke(badge, 3)
	gradient(badge, Color3.fromRGB(140, 220, 255), Color3.fromRGB(60, 130, 240))
	new("UIScale", {}, badge)
	label({ Name = "Label", Text = "💤 ZONA AFK  ·  x2 💰", Size = UDim2.new(1, -20, 0.75, 0), Position = UDim2.new(0, 10, 0.125, 0) }, badge)
end

-- El botón Rebirth del menú ahora abre su panel (lo conecta HUDController)
return "ok"
