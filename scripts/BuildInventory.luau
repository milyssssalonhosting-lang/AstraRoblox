-- Herramienta (no va dentro del juego): se ejecuta UNA vez en Studio para construir
-- los paneles Inventario e Index dentro de StarterGui.HUD y sus botones del menú.

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
local function stroke(p, t, color)
	return new("UIStroke", { Color = color or INK, Thickness = t or 3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, p)
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
local function emoji(props, parent)
	local l = new("TextLabel", { BackgroundTransparency = 1, Font = FONT, TextColor3 = WHITE, TextScaled = true }, parent)
	for k, v in props do
		l[k] = v
	end
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
local function tile(name, parent, pos, top, bottom, icon, text)
	local b = new("TextButton", { Name = name, Position = pos, Size = UDim2.fromOffset(96, 96), BackgroundColor3 = WHITE, AutoButtonColor = false, Text = "" }, parent)
	corner(b, 10)
	stroke(b, 3)
	gradient(b, top, bottom)
	new("UIScale", {}, b)
	emoji({ Name = "Icon", Text = icon, Size = UDim2.fromScale(0.7, 0.58), Position = UDim2.fromScale(0.15, 0.06) }, b)
	label({ Name = "Label", Text = text, Size = UDim2.fromScale(0.92, 0.26), Position = UDim2.fromScale(0.04, 0.68) }, b)
	return b
end
local GREEN = { Color3.fromRGB(120, 255, 80), Color3.fromRGB(30, 190, 40) }
local RED = { Color3.fromRGB(255, 90, 100), Color3.fromRGB(200, 25, 45) }
local GOLD = { Color3.fromRGB(255, 225, 80), Color3.fromRGB(245, 150, 20) }
local BLUE = { Color3.fromRGB(110, 200, 255), Color3.fromRGB(30, 110, 230) }
local GRAY = { Color3.fromRGB(170, 170, 185), Color3.fromRGB(105, 105, 125) }

local function makePanel(name, title, top, bottom, w, h)
	local old = panels:FindFirstChild(name)
	if old then
		old:Destroy()
	end
	local p = new("Frame", { Name = name, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.53), Size = UDim2.fromOffset(w, h), BackgroundColor3 = WHITE, Visible = false, Active = true }, panels)
	corner(p, 14)
	stroke(p, 4)
	gradient(p, top, bottom)
	new("UIScale", {}, p)
	local t = label({ Name = "Title", Text = title, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.fromOffset(w * 0.7, 64), ZIndex = 3 }, p)
	t.UIStroke.Thickness = 4
	local x = button("CloseButton", p, UDim2.new(1, -30, 0, -22), UDim2.fromOffset(52, 52), RED[1], RED[2], "X")
	x.ZIndex = 3
	local content = new("Frame", { Name = "Content", Position = UDim2.fromOffset(16, 40), Size = UDim2.new(1, -32, 1, -56), BackgroundTransparency = 1 }, p)
	return p, content
end

local function grid(parent, name, pos, size, cell)
	local g = new("ScrollingFrame", { Name = name, Position = pos, Size = size, BackgroundColor3 = Color3.fromRGB(30, 20, 60), BackgroundTransparency = 0.6, BorderSizePixel = 0, ScrollBarThickness = 6, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new() }, parent)
	corner(g, 12)
	new("UIGridLayout", { CellSize = cell, CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center }, g)
	new("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }, g)
	return g
end

-- Tarjeta de mascota (sirve para Inventario e Index)
local function petCard(parent, name)
	local c = new("TextButton", { Name = name, Size = UDim2.fromOffset(100, 120), BackgroundColor3 = WHITE, AutoButtonColor = false, Text = "", Visible = false }, parent)
	corner(c, 12)
	stroke(c, 3)
	gradient(c, GRAY[1], GRAY[2])
	new("UIScale", {}, c)
	emoji({ Name = "Icon", Text = "🐶", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.4), Size = UDim2.fromScale(0.62, 0.48) }, c)
	label({ Name = "NameText", Text = "Mascota", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -6), Size = UDim2.new(1, -8, 0, 20) }, c)
	return c
end

---------------------------------------------------------------- Menú izquierdo
local left = hud.Root.LeftMenu
left.Size = UDim2.fromOffset(200, 460)
for _, name in { "InventoryButton", "CodesButton" } do
	local old = left:FindFirstChild(name)
	if old then
		old:Destroy()
	end
end
tile("InventoryButton", left, UDim2.fromOffset(0, 360), Color3.fromRGB(255, 170, 90), Color3.fromRGB(225, 90, 30), "🎒", "Inventory")
tile("CodesButton", left, UDim2.fromOffset(104, 360), Color3.fromRGB(120, 230, 210), Color3.fromRGB(30, 160, 150), "🎟️", "Codes")

---------------------------------------------------------------- Inventario
do
	local _, content = makePanel("InventoryPanel", "Inventory", Color3.fromRGB(150, 120, 255), Color3.fromRGB(70, 50, 180), 740, 470)

	-- Pestañas
	local tabs = new("Frame", { Name = "Tabs", Size = UDim2.fromOffset(450, 40), Position = UDim2.fromOffset(0, 8), BackgroundTransparency = 1 }, content)
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, tabs)
	for i, t in { { "PetsTab", "🐾 Mascotas", GOLD }, { "ClothesTab", "👕 Ropa", GRAY }, { "WeaponsTab", "⚔️ Armas", GRAY } } do
		local b = button(t[1], tabs, UDim2.new(), UDim2.fromOffset(144, 40), t[3][1], t[3][2], t[2])
		b.LayoutOrder = i
	end

	label({ Name = "EquippedText", Text = "Equipadas 0/3", TextXAlignment = Enum.TextXAlignment.Right, Size = UDim2.fromOffset(240, 24), Position = UDim2.new(1, -240, 0, 6) }, content)
	label({ Name = "BoostText", Text = "Bono de mascotas: +0%", TextXAlignment = Enum.TextXAlignment.Right, Size = UDim2.fromOffset(240, 20), Position = UDim2.new(1, -240, 0, 30), TextColor3 = Color3.fromRGB(150, 255, 100) }, content)

	local g = grid(content, "Grid", UDim2.fromOffset(0, 56), UDim2.fromOffset(460, 350), UDim2.fromOffset(100, 120))
	local card = petCard(g, "PetCardTemplate")
	label({ Name = "CountText", Text = "x1", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -4, 0, 4), Size = UDim2.fromOffset(40, 20), TextXAlignment = Enum.TextXAlignment.Right }, card)
	emoji({ Name = "EquippedMark", Text = "✅", Position = UDim2.fromOffset(4, 4), Size = UDim2.fromOffset(24, 24), Visible = false, ZIndex = 3 }, card)
	label({ Name = "EmptyText", Text = "Aún no tienes mascotas.\n¡Gánalas en Diarias, Misiones y el Pase!", Size = UDim2.new(1, -40, 0, 70), Position = UDim2.new(0, 20, 0.5, -35), Visible = false }, content)

	-- Detalle de la mascota elegida
	local details = new("Frame", { Name = "Details", Position = UDim2.fromOffset(472, 56), Size = UDim2.new(1, -472, 0, 350), BackgroundColor3 = WHITE }, content)
	corner(details, 12)
	stroke(details, 3)
	gradient(details, GRAY[1], GRAY[2])
	emoji({ Name = "BigIcon", Text = "❔", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 10), Size = UDim2.fromOffset(110, 100) }, details)
	label({ Name = "NameText", Text = "Elige una mascota", Position = UDim2.fromOffset(10, 114), Size = UDim2.new(1, -20, 0, 30) }, details)
	label({ Name = "RarityText", Text = "", Position = UDim2.fromOffset(10, 146), Size = UDim2.new(1, -20, 0, 22), TextColor3 = Color3.fromRGB(255, 230, 120) }, details)
	label({ Name = "BoostText", Text = "", Position = UDim2.fromOffset(10, 172), Size = UDim2.new(1, -20, 0, 22), TextColor3 = Color3.fromRGB(150, 255, 100) }, details)
	label({ Name = "OwnedText", Text = "", Position = UDim2.fromOffset(10, 198), Size = UDim2.new(1, -20, 0, 20) }, details)
	button("EquipButton", details, UDim2.new(0, 14, 1, -110), UDim2.new(1, -28, 0, 44), GREEN[1], GREEN[2], "Equipar")
	button("EquipBestButton", details, UDim2.new(0, 14, 1, -56), UDim2.new(1, -28, 0, 44), BLUE[1], BLUE[2], "⭐ Equipar mejores")
end

---------------------------------------------------------------- Index
do
	local _, content = makePanel("IndexPanel", "Index", Color3.fromRGB(110, 200, 255), Color3.fromRGB(30, 100, 220), 640, 470)
	label({ Name = "ProgressText", Text = "Descubiertas 0/0", TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.fromOffset(260, 28), Position = UDim2.fromOffset(4, 10) }, content)
	local bar = new("Frame", { Name = "Bar", Position = UDim2.fromOffset(270, 14), Size = UDim2.new(1, -274, 0, 22), BackgroundColor3 = Color3.fromRGB(25, 30, 70) }, content)
	corner(bar, 8)
	stroke(bar, 2.5)
	local fill = new("Frame", { Name = "Fill", Size = UDim2.fromScale(0, 1), BackgroundColor3 = WHITE }, bar)
	corner(fill, 8)
	gradient(fill, GOLD[1], GOLD[2])
	local g = grid(content, "Grid", UDim2.fromOffset(0, 50), UDim2.new(1, 0, 1, -50), UDim2.fromOffset(110, 140))
	local card = petCard(g, "IndexCardTemplate")
	card.Size = UDim2.fromOffset(110, 140)
	card.Icon.Position = UDim2.fromScale(0.5, 0.33)
	card.Icon.Size = UDim2.fromScale(0.6, 0.4)
	card.NameText.Position = UDim2.new(0.5, 0, 1, -40)
	label({ Name = "RarityText", Text = "", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -22), Size = UDim2.new(1, -8, 0, 16), TextColor3 = Color3.fromRGB(255, 235, 140) }, card)
	label({ Name = "BoostText", Text = "", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -4), Size = UDim2.new(1, -8, 0, 16), TextColor3 = Color3.fromRGB(150, 255, 100) }, card)
end

return "ok"
