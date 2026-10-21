-- Herramienta (no va dentro del juego): agrega el mini-menú de FUSIÓN dentro del
-- panel de Inventario (StarterGui.HUD.Panels.InventoryPanel.FusePanel).
-- Muestra las 3 copias → la mascota del siguiente nivel con sus bonos, y los botones
-- "¡Fusionar!" y "Cancelar". Lo controla InventoryController. Se puede correr otra vez.

local panel = game.StarterGui.HUD.Panels.InventoryPanel
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
local function slot(name, parent, pos, size)
	local f = new("Frame", { Name = name, Position = pos, Size = size, BackgroundColor3 = WHITE }, parent)
	corner(f, 12)
	stroke(f, 3)
	gradient(f, Color3.fromRGB(190, 200, 210), Color3.fromRGB(120, 135, 150))
	-- "Icon" es donde PetViewport pone el modelo 3D
	new("TextLabel", { Name = "Icon", BackgroundTransparency = 1, Font = FONT, TextScaled = true, Text = "❔", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.85, 0.85) }, f)
	return f
end
local function button(name, parent, pos, size, top, bottom, text)
	local b = new("TextButton", { Name = name, Position = pos, Size = size, BackgroundColor3 = WHITE, AutoButtonColor = false, Text = "" }, parent)
	corner(b, 10)
	stroke(b, 3)
	gradient(b, top, bottom)
	new("UIScale", {}, b)
	label({ Name = "Label", Text = text, Size = UDim2.new(1, -12, 0.7, 0), Position = UDim2.new(0, 6, 0.15, 0) }, b)
	return b
end

local old = panel:FindFirstChild("FusePanel")
if old then
	old:Destroy()
end

-- Fondo oscuro que tapa el inventario mientras eliges
local fuse = new("Frame", { Name = "FusePanel", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(15, 10, 30), BackgroundTransparency = 0.35, Visible = false, Active = true, ZIndex = 20 }, panel)
corner(fuse, 14)

local card = new("Frame", { Name = "Card", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.52), Size = UDim2.fromOffset(560, 330), BackgroundColor3 = WHITE }, fuse)
corner(card, 16)
stroke(card, 4)
gradient(card, Color3.fromRGB(200, 120, 255), Color3.fromRGB(110, 40, 200))
new("UIScale", {}, card)
label({ Name = "Title", Text = "✨ Fusión ✨", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 10), Size = UDim2.fromOffset(300, 40) }, card)

-- 3 copias  →  resultado
for i = 1, 3 do
	slot("Slot" .. i, card, UDim2.fromOffset(24 + (i - 1) * 92, 80), UDim2.fromOffset(84, 84))
end
label({ Name = "Plus", Text = "→", Position = UDim2.fromOffset(300, 98), Size = UDim2.fromOffset(50, 50), TextColor3 = Color3.fromRGB(255, 240, 120) }, card)
local result = slot("Result", card, UDim2.fromOffset(360, 60), UDim2.fromOffset(150, 150))
new("UIScale", {}, result)
label({ Name = "LevelBadge", Text = "Nv.2", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -6, 0, 4), Size = UDim2.fromOffset(52, 24), TextColor3 = Color3.fromRGB(255, 240, 120), ZIndex = 3 }, result)

label({ Name = "FromText", Text = "3x Slime", Position = UDim2.fromOffset(20, 172), Size = UDim2.fromOffset(280, 24) }, card)
label({ Name = "FromStats", Text = "", Position = UDim2.fromOffset(20, 198), Size = UDim2.fromOffset(280, 22), TextColor3 = Color3.fromRGB(220, 220, 230) }, card)
label({ Name = "ResultName", Text = "Slime Nv.2", Position = UDim2.fromOffset(320, 214), Size = UDim2.fromOffset(230, 26), TextColor3 = Color3.fromRGB(255, 240, 120) }, card)
label({ Name = "ResultStats", Text = "", Position = UDim2.fromOffset(320, 242), Size = UDim2.fromOffset(230, 22), TextColor3 = Color3.fromRGB(150, 255, 100) }, card)

button("ConfirmButton", card, UDim2.fromOffset(24, 262), UDim2.fromOffset(200, 50), Color3.fromRGB(120, 255, 80), Color3.fromRGB(30, 190, 40), "✨ ¡Fusionar!")
button("CancelButton", card, UDim2.fromOffset(236, 270), UDim2.fromOffset(70, 36), Color3.fromRGB(255, 90, 100), Color3.fromRGB(200, 25, 45), "✖")

return "ok: FusePanel"
