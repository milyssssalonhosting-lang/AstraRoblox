-- Herramienta (no va dentro del juego): se ejecuta UNA vez en Studio para construir
-- la tienda de huevos (ShopPanel) y la pantalla de abrir huevos (HatchOverlay).

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
local GREEN = { Color3.fromRGB(120, 255, 80), Color3.fromRGB(30, 190, 40) }
local RED = { Color3.fromRGB(255, 90, 100), Color3.fromRGB(200, 25, 45) }

---------------------------------------------------------------- Tienda (huevos)
do
	local old = panels:FindFirstChild("ShopPanel")
	if old then
		old:Destroy()
	end
	local w, h = 780, 500
	local p = new("Frame", { Name = "ShopPanel", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.53), Size = UDim2.fromOffset(w, h), BackgroundColor3 = WHITE, Visible = false, Active = true }, panels)
	corner(p, 14)
	stroke(p, 4)
	gradient(p, Color3.fromRGB(255, 120, 160), Color3.fromRGB(200, 40, 90))
	new("UIScale", {}, p)
	label({ Name = "Title", Text = "Shop", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.fromOffset(w * 0.5, 64), ZIndex = 3 }, p).UIStroke.Thickness = 4
	button("CloseButton", p, UDim2.new(1, -30, 0, -22), UDim2.fromOffset(52, 52), RED[1], RED[2], "X").ZIndex = 3
	local content = new("Frame", { Name = "Content", Position = UDim2.fromOffset(16, 40), Size = UDim2.new(1, -32, 1, -56), BackgroundTransparency = 1 }, p)

	label({ Name = "SectionText", Text = "🥚 Huevos de mascotas", TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.fromOffset(400, 30), Position = UDim2.fromOffset(4, 6) }, content)
	label({ Name = "OddsNote", Text = "Las probabilidades se muestran antes de abrir", TextXAlignment = Enum.TextXAlignment.Right, Size = UDim2.fromOffset(330, 18), Position = UDim2.new(1, -334, 0, 12), TextColor3 = Color3.fromRGB(255, 235, 150) }, content)

	local row = new("Frame", { Name = "Eggs", Position = UDim2.fromOffset(0, 46), Size = UDim2.new(1, 0, 1, -46), BackgroundTransparency = 1 }, content)
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }, row)

	local card = new("Frame", { Name = "EggCardTemplate", Size = UDim2.fromOffset(232, 390), BackgroundColor3 = WHITE, Visible = false }, row)
	corner(card, 14)
	stroke(card, 3)
	gradient(card, Color3.fromRGB(230, 230, 240), Color3.fromRGB(150, 160, 185))
	new("UIScale", {}, card)
	emoji({ Name = "Icon", Text = "🥚", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 8), Size = UDim2.fromOffset(80, 72) }, card)
	label({ Name = "NameText", Text = "Huevo", Position = UDim2.fromOffset(8, 82), Size = UDim2.new(1, -16, 0, 26) }, card)
	label({ Name = "PriceText", Text = "$500", Position = UDim2.fromOffset(8, 110), Size = UDim2.new(1, -16, 0, 24), TextColor3 = Color3.fromRGB(150, 255, 100) }, card)

	local odds = new("Frame", { Name = "Odds", Position = UDim2.fromOffset(10, 140), Size = UDim2.new(1, -20, 0, 150), BackgroundColor3 = Color3.fromRGB(25, 20, 45), BackgroundTransparency = 0.35 }, card)
	corner(odds, 10)
	new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, odds)
	new("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }, odds)
	local oddsRow = new("Frame", { Name = "OddsRowTemplate", Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, Visible = false }, odds)
	emoji({ Name = "Icon", Text = "🐶", Size = UDim2.fromOffset(28, 28) }, oddsRow)
	label({ Name = "NameText", Text = "Perro", TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(32, 4), Size = UDim2.new(1, -96, 0, 22) }, oddsRow)
	label({ Name = "ChanceText", Text = "45%", TextXAlignment = Enum.TextXAlignment.Right, Position = UDim2.new(1, -62, 0, 4), Size = UDim2.fromOffset(60, 22) }, oddsRow)

	button("Open1Button", card, UDim2.new(0, 10, 1, -92), UDim2.new(1, -20, 0, 40), GREEN[1], GREEN[2], "Abrir x1")
	button("Open3Button", card, UDim2.new(0, 10, 1, -46), UDim2.new(1, -20, 0, 38), Color3.fromRGB(110, 200, 255), Color3.fromRGB(30, 110, 230), "Abrir x3")
end

---------------------------------------------------------------- Pantalla de abrir huevos
do
	local old = hud:FindFirstChild("HatchOverlay")
	if old then
		old:Destroy()
	end
	local overlay = new("TextButton", { Name = "HatchOverlay", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(10, 5, 25), BackgroundTransparency = 0.25, Text = "", AutoButtonColor = false, Visible = false, ZIndex = 5, Selectable = false }, hud)
	local egg = emoji({ Name = "Egg", Text = "🥚", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.48), Size = UDim2.fromOffset(220, 220), ZIndex = 6 }, overlay)
	new("UIScale", {}, egg)
	local flash = new("Frame", { Name = "Flash", Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BackgroundTransparency = 1, ZIndex = 9 }, overlay)
	local results = new("Frame", { Name = "Results", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.48), Size = UDim2.fromOffset(600, 240), BackgroundTransparency = 1, Visible = false, ZIndex = 6 }, overlay)
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 16), SortOrder = Enum.SortOrder.LayoutOrder }, results)
	new("UIScale", {}, results)

	local card = new("Frame", { Name = "ResultCardTemplate", Size = UDim2.fromOffset(176, 220), BackgroundColor3 = WHITE, Visible = false, ZIndex = 6 }, results)
	corner(card, 16)
	stroke(card, 4)
	gradient(card, Color3.fromRGB(190, 200, 210), Color3.fromRGB(120, 135, 150))
	new("UIScale", {}, card)
	emoji({ Name = "Icon", Text = "🐶", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 14), Size = UDim2.fromOffset(110, 100), ZIndex = 7 }, card)
	label({ Name = "NameText", Text = "Perro", Position = UDim2.fromOffset(8, 122), Size = UDim2.new(1, -16, 0, 30), ZIndex = 7 }, card)
	label({ Name = "RarityText", Text = "Común", Position = UDim2.fromOffset(8, 154), Size = UDim2.new(1, -16, 0, 24), ZIndex = 7, TextColor3 = Color3.fromRGB(255, 235, 140) }, card)
	label({ Name = "BoostText", Text = "+5%", Position = UDim2.fromOffset(8, 182), Size = UDim2.new(1, -16, 0, 22), ZIndex = 7, TextColor3 = Color3.fromRGB(150, 255, 100) }, card)
	local newBadge = label({ Name = "NewBadge", Text = "¡NUEVO!", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.fromOffset(120, 30), Rotation = -8, ZIndex = 8, TextColor3 = Color3.fromRGB(255, 230, 60), Visible = false }, card)
	newBadge.UIStroke.Thickness = 3

	label({ Name = "ContinueText", Text = "Toca para continuar", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -40), Size = UDim2.fromOffset(320, 30), ZIndex = 6, Visible = false }, overlay)
end

return "ok"
