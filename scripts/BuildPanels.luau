-- Herramienta (no va dentro del juego): se ejecuta UNA vez en Studio (barra de comandos
-- o MCP) para construir los paneles Daily, Missions, BattlePass y Settings dentro de
-- StarterGui.HUD. Si se borran o se quieren rehacer, se vuelve a correr.

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
local function rainbow(p)
	return new("UIGradient", {
		Rotation = 35,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 90, 140)),
			ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 200, 60)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(110, 230, 110)),
			ColorSequenceKeypoint.new(0.75, Color3.fromRGB(80, 180, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(190, 100, 255)),
		}),
	}, p)
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
local GOLD = { Color3.fromRGB(255, 225, 80), Color3.fromRGB(245, 150, 20) }
local PURPLE = { Color3.fromRGB(170, 110, 255), Color3.fromRGB(105, 45, 200) }

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

---------------------------------------------------------------- Menú izquierdo: botón Missions
local left = hud.Root.LeftMenu
left.Size = UDim2.fromOffset(200, 356)
if not left:FindFirstChild("MissionsButton") then
	local b = button("MissionsButton", left, UDim2.fromOffset(0, 100), UDim2.fromOffset(200, 44), Color3.fromRGB(255, 180, 70), Color3.fromRGB(235, 100, 20), "📜 Missions")
	local dot = new("TextLabel", { Name = "Alert", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -2, 0, 2), Size = UDim2.fromOffset(24, 24), BackgroundColor3 = Color3.fromRGB(235, 50, 60), Font = FONT, Text = "!", TextScaled = true, TextColor3 = WHITE, ZIndex = 3, Visible = false }, b)
	corner(dot, 12)
	stroke(dot, 2, WHITE)
end
left.ShopButton.Position = UDim2.fromOffset(0, 152)
left.PassButton.Position = UDim2.fromOffset(104, 152)
left.RebirthButton.Position = UDim2.fromOffset(0, 256)
left.IndexButton.Position = UDim2.fromOffset(104, 256)
if not left.PassButton:FindFirstChild("Alert") then
	local dot = left.DailyButton.Alert:Clone()
	dot.Visible = false
	dot.Parent = left.PassButton
end

---------------------------------------------------------------- Daily Rewards
do
	local _, content = makePanel("DailyPanel", "Daily Rewards", Color3.fromRGB(120, 210, 255), Color3.fromRGB(40, 120, 230), 640, 440)
	local CARD_W, CARD_H, GAP = 138, 172, 12
	local colors = {
		{ Color3.fromRGB(140, 220, 255), Color3.fromRGB(60, 150, 240) },
		{ Color3.fromRGB(140, 220, 255), Color3.fromRGB(60, 150, 240) },
		{ Color3.fromRGB(140, 220, 255), Color3.fromRGB(60, 150, 240) },
		{ Color3.fromRGB(220, 140, 255), Color3.fromRGB(150, 60, 220) },
		{ Color3.fromRGB(220, 140, 255), Color3.fromRGB(150, 60, 220) },
		{ Color3.fromRGB(255, 210, 90), Color3.fromRGB(245, 140, 30) },
	}
	for day = 1, 7 do
		local pos, size
		if day <= 6 then
			local col, row = (day - 1) % 3, (day - 1) // 3
			pos = UDim2.fromOffset(col * (CARD_W + GAP), 14 + row * (CARD_H + GAP))
			size = UDim2.fromOffset(CARD_W, CARD_H)
		else
			pos = UDim2.fromOffset(3 * (CARD_W + GAP), 14)
			size = UDim2.fromOffset(CARD_W + 30, CARD_H * 2 + GAP)
		end
		local card = new("Frame", { Name = "Day" .. day, Position = pos, Size = size, BackgroundColor3 = WHITE }, content)
		corner(card, 12)
		stroke(card, 3)
		if day == 7 then
			rainbow(card)
		else
			gradient(card, colors[day][1], colors[day][2])
		end
		new("UIScale", {}, card)
		label({ Name = "DayText", Text = "DAY " .. day, Size = UDim2.new(1, -10, 0, if day == 7 then 40 else 28), Position = UDim2.fromOffset(5, 4) }, card)
		emoji({ Name = "Icon", Text = "🎁", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, if day == 7 then 0.42 else 0.44), Size = UDim2.fromScale(0.62, if day == 7 then 0.3 else 0.42) }, card)
		label({ Name = "RewardText", Text = "Premio", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -42), Size = UDim2.new(1, -10, 0, if day == 7 then 30 else 22) }, card)
		local claim = button("ClaimButton", card, UDim2.new(0, 8, 1, -38), UDim2.new(1, -16, 0, 32), RED[1], RED[2], "LOCKED")
		claim.Label.Size = UDim2.new(1, -8, 0.75, 0)
	end
end

---------------------------------------------------------------- Missions
do
	local _, content = makePanel("MissionsPanel", "Missions", Color3.fromRGB(255, 200, 90), Color3.fromRGB(240, 120, 30), 620, 440)
	local list = new("ScrollingFrame", { Name = "List", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 6, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new() }, content)
	new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center }, list)
	new("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8) }, list)
	local row = new("Frame", { Name = "MissionRowTemplate", Size = UDim2.new(1, -16, 0, 92), BackgroundColor3 = WHITE, Visible = false }, list)
	corner(row, 12)
	stroke(row, 3)
	gradient(row, Color3.fromRGB(255, 245, 210), Color3.fromRGB(255, 215, 140))
	emoji({ Name = "Icon", Text = "📜", Size = UDim2.fromOffset(64, 64), Position = UDim2.fromOffset(10, 14) }, row)
	label({ Name = "MissionText", Text = "Misión", TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.fromOffset(300, 26), Position = UDim2.fromOffset(84, 8) }, row)
	local bar = new("Frame", { Name = "Bar", Size = UDim2.fromOffset(300, 22), Position = UDim2.fromOffset(84, 38), BackgroundColor3 = Color3.fromRGB(60, 50, 80) }, row)
	corner(bar, 6)
	stroke(bar, 2.5)
	local fill = new("Frame", { Name = "Fill", Size = UDim2.fromScale(0.3, 1), BackgroundColor3 = WHITE }, bar)
	corner(fill, 6)
	gradient(fill, Color3.fromRGB(140, 255, 90), Color3.fromRGB(40, 180, 40))
	label({ Name = "ProgressText", Text = "0/10", Size = UDim2.new(1, -8, 0.85, 0), Position = UDim2.new(0, 4, 0.075, 0), ZIndex = 2 }, bar)
	label({ Name = "RewardText", Text = "💵 $500  🎫 100", TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.fromOffset(300, 22), Position = UDim2.fromOffset(84, 64), TextColor3 = Color3.fromRGB(255, 240, 120) }, row)
	button("ClaimButton", row, UDim2.new(1, -140, 0.5, -22), UDim2.fromOffset(128, 44), GREEN[1], GREEN[2], "Reclamar")
end

---------------------------------------------------------------- Battle Pass
do
	local panel, content = makePanel("BattlePassPanel", "BATTLE PASS", Color3.fromRGB(110, 70, 180), Color3.fromRGB(55, 30, 110), 800, 480)
	panel.UIStroke.Color = Color3.fromRGB(255, 190, 40)
	panel.UIStroke.Thickness = 5

	-- Encabezado: nivel, temporada, barra de XP, tiempo restante, botón premium
	local header = new("Frame", { Name = "Header", Size = UDim2.new(1, 0, 0, 110), Position = UDim2.fromOffset(0, 8), BackgroundColor3 = Color3.fromRGB(45, 25, 90), BackgroundTransparency = 0.2 }, content)
	corner(header, 12)
	stroke(header, 2.5)
	local badge = new("Frame", { Name = "LevelBadge", Size = UDim2.fromOffset(88, 88), Position = UDim2.fromOffset(12, 11), BackgroundColor3 = WHITE, Rotation = 0 }, header)
	corner(badge, 18)
	stroke(badge, 3)
	gradient(badge, GOLD[1], GOLD[2])
	new("UIScale", {}, badge)
	emoji({ Name = "Crown", Text = "👑", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, 4), Size = UDim2.fromOffset(34, 28) }, badge)
	label({ Name = "LevelText", Text = "0", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.55), Size = UDim2.fromScale(0.8, 0.55) }, badge)
	label({ Name = "SeasonText", Text = "SEASON 1", TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.fromOffset(300, 32), Position = UDim2.fromOffset(116, 14) }, header)
	local xpBar = new("Frame", { Name = "XPBar", Size = UDim2.fromOffset(380, 28), Position = UDim2.fromOffset(116, 56), BackgroundColor3 = Color3.fromRGB(25, 15, 50) }, header)
	corner(xpBar, 8)
	stroke(xpBar, 2.5)
	local xpFill = new("Frame", { Name = "Fill", Size = UDim2.fromScale(0.45, 1), BackgroundColor3 = WHITE }, xpBar)
	corner(xpFill, 8)
	gradient(xpFill, GOLD[1], GOLD[2])
	label({ Name = "XPText", Text = "0 / 100 XP", Size = UDim2.new(1, -10, 0.85, 0), Position = UDim2.new(0, 5, 0.075, 0), ZIndex = 2 }, xpBar)
	label({ Name = "EndsText", Text = "⏱️ ENDS IN: 0d 0h", TextXAlignment = Enum.TextXAlignment.Right, Size = UDim2.fromOffset(220, 26), Position = UDim2.new(1, -232, 0, 12), TextColor3 = Color3.fromRGB(255, 210, 70) }, header)
	button("UpgradeButton", header, UDim2.new(1, -232, 0, 50), UDim2.fromOffset(220, 46), GOLD[1], GOLD[2], "UPGRADE PASS")

	-- Etiquetas PREMIUM / FREE a la izquierda
	local premiumTag = new("Frame", { Name = "PremiumTag", Size = UDim2.fromOffset(92, 112), Position = UDim2.fromOffset(0, 162), BackgroundColor3 = WHITE }, content)
	corner(premiumTag, 10)
	stroke(premiumTag, 3)
	gradient(premiumTag, GOLD[1], GOLD[2])
	emoji({ Text = "⭐", Size = UDim2.fromOffset(60, 50), Position = UDim2.fromOffset(16, 12) }, premiumTag)
	label({ Text = "PREMIUM", Size = UDim2.new(1, -8, 0, 22), Position = UDim2.new(0, 4, 1, -32) }, premiumTag)
	local freeTag = premiumTag:Clone()
	freeTag.Name = "FreeTag"
	freeTag.Position = UDim2.fromOffset(0, 282)
	freeTag.UIGradient.Color = ColorSequence.new(Color3.fromRGB(110, 190, 255), Color3.fromRGB(40, 100, 220))
	for _, child in freeTag:GetChildren() do
		if child:IsA("TextLabel") and child.Text == "PREMIUM" then
			child.Text = "FREE"
		elseif child:IsA("TextLabel") and child.Text == "⭐" then
			child.Text = "🔷"
		end
	end
	freeTag.Parent = content

	-- Pista horizontal con los 30 niveles
	local track = new("ScrollingFrame", { Name = "Track", Position = UDim2.fromOffset(102, 126), Size = UDim2.new(1, -102, 0, 274), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollingDirection = Enum.ScrollingDirection.X, ScrollBarThickness = 8, ScrollBarImageColor3 = Color3.fromRGB(255, 200, 60), AutomaticCanvasSize = Enum.AutomaticSize.X, CanvasSize = UDim2.new(), VerticalScrollBarInset = Enum.ScrollBarInset.None }, content)
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, track)
	new("UIPadding", { PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) }, track)

	local column = new("Frame", { Name = "LevelColumnTemplate", Size = UDim2.fromOffset(96, 262), BackgroundTransparency = 1, Visible = false }, track)
	local tag = new("Frame", { Name = "LevelTag", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, 18), Size = UDim2.fromOffset(30, 30), Rotation = 45, BackgroundColor3 = Color3.fromRGB(60, 35, 110) }, column)
	corner(tag, 6)
	stroke(tag, 2.5, Color3.fromRGB(255, 190, 40))
	label({ Name = "LevelNumber", Text = "1", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, 18), Size = UDim2.fromOffset(34, 22), ZIndex = 2 }, column)
	local function cell(name, y, top, bottom)
		local c = new("TextButton", { Name = name, Position = UDim2.fromOffset(4, y), Size = UDim2.fromOffset(88, 104), BackgroundColor3 = WHITE, AutoButtonColor = false, Text = "" }, column)
		corner(c, 12)
		stroke(c, 3)
		gradient(c, top, bottom)
		new("UIScale", {}, c)
		emoji({ Name = "Icon", Text = "🎁", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.4), Size = UDim2.fromScale(0.62, 0.52) }, c)
		label({ Name = "Amount", Text = "", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -4), Size = UDim2.new(1, -8, 0, 22) }, c)
		emoji({ Name = "Check", Text = "✅", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -2, 1, -22), Size = UDim2.fromOffset(28, 28), Visible = false, ZIndex = 3 }, c)
		local lock = new("Frame", { Name = "Lock", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45, Visible = false, ZIndex = 3 }, c)
		corner(lock, 12)
		emoji({ Text = "🔒", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromOffset(34, 34), ZIndex = 4 }, lock)
		return c
	end
	cell("PremiumCell", 40, Color3.fromRGB(255, 205, 90), Color3.fromRGB(200, 120, 20))
	cell("FreeCell", 152, Color3.fromRGB(90, 70, 150), Color3.fromRGB(50, 35, 100))

	local claimAll = button("ClaimAllButton", content, UDim2.new(0.5, -110, 1, -46), UDim2.fromOffset(220, 48), PURPLE[1], PURPLE[2], "CLAIM ALL")
	claimAll.UIStroke.Color = Color3.fromRGB(255, 190, 40)
end

---------------------------------------------------------------- Settings
do
	local _, content = makePanel("SettingsPanel", "Settings", Color3.fromRGB(150, 165, 200), Color3.fromRGB(80, 95, 135), 520, 400)
	local list = new("Frame", { Name = "List", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, content)
	new("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center }, list)
	new("UIPadding", { PaddingTop = UDim.new(0, 14) }, list)
	local function row(name, order, text)
		local r = new("Frame", { Name = name, LayoutOrder = order, Size = UDim2.new(1, -10, 0, 66), BackgroundColor3 = WHITE }, list)
		corner(r, 12)
		stroke(r, 3)
		gradient(r, Color3.fromRGB(110, 125, 165), Color3.fromRGB(65, 75, 115))
		label({ Name = "NameText", Text = text, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.fromOffset(190, 30), Position = UDim2.new(0, 14, 0.5, -15) }, r)
		return r
	end
	local function slider(r)
		local s = new("TextButton", { Name = "Slider", Position = UDim2.new(0, 210, 0.5, -9), Size = UDim2.new(1, -300, 0, 18), BackgroundColor3 = Color3.fromRGB(35, 30, 55), AutoButtonColor = false, Text = "" }, r)
		corner(s, 9)
		stroke(s, 2.5)
		local fill = new("Frame", { Name = "Fill", Size = UDim2.fromScale(0.5, 1), BackgroundColor3 = WHITE }, s)
		corner(fill, 9)
		gradient(fill, GREEN[1], GREEN[2])
		local knob = new("TextButton", { Name = "Knob", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(32, 32), BackgroundColor3 = WHITE, AutoButtonColor = false, Text = "", ZIndex = 2 }, s)
		corner(knob, 16)
		stroke(knob, 3)
		label({ Name = "ValueText", Text = "50%", Size = UDim2.fromOffset(72, 28), Position = UDim2.new(1, -82, 0.5, -14) }, r)
		return s
	end
	slider(row("MusicRow", 1, "🎵 Música"))
	slider(row("SfxRow", 2, "🔊 Efectos de sonido"))
	slider(row("HudScaleRow", 3, "📐 Tamaño del HUD"))
	local fx = row("EffectsRow", 4, "✨ Efectos visuales")
	button("ModeButton", fx, UDim2.new(1, -164, 0.5, -21), UDim2.fromOffset(150, 42), GREEN[1], GREEN[2], "Auto")
end

-- El Battle Pass viejo (imagen fija) ya no se usa
local oldPass = game.StarterGui:FindFirstChild("BattlePassGui")
if oldPass then
	oldPass:Destroy()
end

return "ok"
