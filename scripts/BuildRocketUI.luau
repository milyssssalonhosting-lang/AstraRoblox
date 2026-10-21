-- Herramienta (no va dentro del juego): construye la interfaz del Mundo Cohete en
-- StarterGui.HUD.Root: barra de ronda, ranking, banner de capa, cuenta regresiva y resultados.

local root = game.StarterGui.HUD.Root
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

for _, name in { "RocketBar", "RocketLeaders", "RocketBanner", "RocketCountdown", "RocketResult", "TrollBar", "NukeFlash", "TapPad" } do
	local old = root:FindFirstChild(name)
	if old then
		old:Destroy()
	end
end

---------------------------------------------------------------- Barra de ronda (arriba al centro)
local bar = new("Frame", { Name = "RocketBar", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 110), Size = UDim2.fromOffset(460, 100), BackgroundColor3 = WHITE, Visible = false }, root)
corner(bar, 16)
stroke(bar, 3)
gradient(bar, Color3.fromRGB(110, 80, 220), Color3.fromRGB(50, 30, 120))
new("UIScale", {}, bar)
label({ Name = "PhaseText", Text = "Esperando jugadores…", Size = UDim2.new(1, -20, 0, 24), Position = UDim2.fromOffset(10, 6), TextColor3 = Color3.fromRGB(255, 230, 120) }, bar)
label({ Name = "AltitudeText", Text = "0 m", Size = UDim2.new(1, -20, 0, 30), Position = UDim2.fromOffset(10, 30) }, bar)
local layer = new("Frame", { Name = "LayerBar", Size = UDim2.new(1, -110, 0, 22), Position = UDim2.fromOffset(55, 68), BackgroundColor3 = Color3.fromRGB(25, 15, 55) }, bar)
corner(layer, 11)
stroke(layer, 2.5)
local fill = new("Frame", { Name = "Fill", Size = UDim2.fromScale(0, 1), BackgroundColor3 = WHITE }, layer)
corner(fill, 11)
gradient(fill, Color3.fromRGB(120, 230, 255), Color3.fromRGB(60, 140, 255))
label({ Name = "LayerText", Text = "Cielo → Nubes", Size = UDim2.new(1, -10, 0.85, 0), Position = UDim2.new(0, 5, 0.075, 0), ZIndex = 2 }, layer)
new("TextLabel", { Name = "CurrentIcon", BackgroundTransparency = 1, Text = "☁️", TextScaled = true, Size = UDim2.fromOffset(36, 30), Position = UDim2.fromOffset(12, 64) }, bar)
-- Botón de modo automático (debajo de la barra)
do
	local b = new("TextButton", { Name = "AutoButton", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 1, 6), Size = UDim2.fromOffset(170, 36), BackgroundColor3 = WHITE, AutoButtonColor = false, Text = "" }, bar)
	corner(b, 10)
	stroke(b, 3)
	gradient(b, Color3.fromRGB(120, 255, 80), Color3.fromRGB(30, 190, 40))
	new("UIScale", {}, b)
	label({ Name = "Label", Text = "🤖 Auto: SÍ", Size = UDim2.new(1, -12, 0.75, 0), Position = UDim2.new(0, 6, 0.125, 0) }, b)
end
-- Velocímetro (izquierda del botón Auto): m/s durante el vuelo
label({ Name = "SpeedText", Text = "", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(0.5, -92, 1, 10), Size = UDim2.fromOffset(200, 28), TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = Color3.fromRGB(255, 200, 90) }, bar)
label({ Name = "PowerText", Text = "", Visible = false, AnchorPoint = Vector2.new(0, 0), Position = UDim2.new(0.5, 92, 1, 10), Size = UDim2.fromOffset(200, 28), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(120, 230, 255) }, bar)
new("TextLabel", { Name = "NextIcon", BackgroundTransparency = 1, Text = "🌥️", TextScaled = true, Size = UDim2.fromOffset(36, 30), Position = UDim2.new(1, -48, 0, 64) }, bar)

---------------------------------------------------------------- Ranking en vivo (derecha)
local leaders = new("Frame", { Name = "RocketLeaders", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0.25, 0), Size = UDim2.fromOffset(230, 140), BackgroundColor3 = Color3.fromRGB(30, 20, 60), BackgroundTransparency = 0.25, Visible = false }, root)
corner(leaders, 12)
stroke(leaders, 2.5)
new("UIScale", {}, leaders)
label({ Name = "Title", Text = "🏆 Más alto", Size = UDim2.new(1, -16, 0, 24), Position = UDim2.fromOffset(8, 6), TextColor3 = Color3.fromRGB(255, 220, 80) }, leaders)
for i = 1, 3 do
	label({ Name = "Row" .. i, Text = "", TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -16, 0, 26), Position = UDim2.fromOffset(8, 6 + i * 32) }, leaders)
end

---------------------------------------------------------------- Banner de nueva capa (centro)
local banner = label({ Name = "RocketBanner", Text = "🌌 ¡ESPACIO!", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(620, 80), Visible = false, ZIndex = 5 }, root)
banner.UIStroke.Thickness = 5
new("UIScale", {}, banner)

---------------------------------------------------------------- Cuenta regresiva (centro)
local countdown = label({ Name = "RocketCountdown", Text = "3", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromOffset(300, 140), Visible = false, ZIndex = 5, TextColor3 = Color3.fromRGB(255, 220, 80) }, root)
countdown.UIStroke.Thickness = 6
new("UIScale", {}, countdown)

---------------------------------------------------------------- Resultado de la ronda (centro)
local result = new("Frame", { Name = "RocketResult", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromOffset(420, 170), BackgroundColor3 = WHITE, Visible = false, ZIndex = 5 }, root)
corner(result, 18)
stroke(result, 4)
gradient(result, Color3.fromRGB(255, 220, 90), Color3.fromRGB(245, 140, 30))
new("UIScale", {}, result)
label({ Name = "Title", Text = "¡Llegaste a 523 m!", Size = UDim2.new(1, -20, 0, 44), Position = UDim2.fromOffset(10, 14), ZIndex = 6 }, result)
label({ Name = "LayerText", Text = "🌈 Arcoíris", Size = UDim2.new(1, -20, 0, 30), Position = UDim2.fromOffset(10, 62), ZIndex = 6 }, result)
label({ Name = "RewardText", Text = "+$2,615", Size = UDim2.new(1, -20, 0, 50), Position = UDim2.fromOffset(10, 104), ZIndex = 6, TextColor3 = Color3.fromRGB(150, 255, 100) }, result)

---------------------------------------------------------------- Trolleos (derecha)
do
	local GameConfig = require(game.ReplicatedStorage.Shared.GameConfig)
	-- Columna a la derecha, centrada un poco abajo del medio: no tapa el ranking ni las insignias
	local trollBar = new("Frame", { Name = "TrollBar", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.66, 0), Size = UDim2.fromOffset(68, 3 * 74), BackgroundTransparency = 1, Visible = false }, root)
	new("UIScale", {}, trollBar)
	new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Right }, trollBar)
	local colors = {
		Meteor = { Color3.fromRGB(255, 160, 70), Color3.fromRGB(220, 70, 30) },
		Steal = { Color3.fromRGB(200, 120, 255), Color3.fromRGB(110, 40, 200) },
		Nuke = { Color3.fromRGB(190, 255, 80), Color3.fromRGB(60, 160, 30) },
	}
	for i, troll in GameConfig.Rocket.Trolls.List do
		local b = new("TextButton", { Name = troll.Id .. "Button", LayoutOrder = i, Size = UDim2.fromOffset(68, 68), BackgroundColor3 = WHITE, AutoButtonColor = false, Text = "" }, trollBar)
		new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, b) -- redondo
		stroke(b, 3)
		gradient(b, colors[troll.Id][1], colors[troll.Id][2])
		new("UIScale", {}, b)
		new("TextLabel", { Name = "Icon", BackgroundTransparency = 1, Text = troll.Icon, TextScaled = true, Size = UDim2.fromScale(0.5, 0.42), Position = UDim2.fromScale(0.25, 0.1) }, b)
		label({ Name = "NameText", Text = troll.Name, Size = UDim2.fromScale(0.86, 0.18), Position = UDim2.fromScale(0.07, 0.52) }, b)
		label({ Name = "PriceText", Text = "$" .. GameConfig.FormatNumber(troll.Price), Size = UDim2.fromScale(0.7, 0.2), Position = UDim2.fromScale(0.15, 0.7), TextColor3 = Color3.fromRGB(255, 240, 120) }, b)
		local cd = new("Frame", { Name = "Cooldown", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45, Visible = false, ZIndex = 3 }, b)
		new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, cd)
		label({ Name = "Text", Text = "5", Size = UDim2.fromScale(0.6, 0.4), Position = UDim2.fromScale(0.2, 0.3), ZIndex = 4 }, cd)
	end
end

-- Destello de la bomba nuclear (pantalla completa, encima de todo)
---------------------------------------------------------------- Botón de TAP (abajo a la derecha)
-- Para subir hay que spamear: clic / Espacio en PC o este botón en celular.
-- Encima: barra de potencia y el interruptor de Auto-clic.
do
	local pad = new("Frame", { Name = "TapPad", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -96, 1, -84), Size = UDim2.fromOffset(140, 210), BackgroundTransparency = 1, Visible = false }, root)
	new("UIScale", {}, pad)
	local auto = new("TextButton", { Name = "AutoClickButton", Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = WHITE, AutoButtonColor = false, Text = "" }, pad)
	corner(auto, 10)
	stroke(auto, 3)
	gradient(auto, Color3.fromRGB(170, 170, 185), Color3.fromRGB(105, 105, 125))
	new("UIScale", {}, auto)
	label({ Name = "Label", Text = "🤖 Auto-clic: NO", Size = UDim2.new(1, -10, 0.72, 0), Position = UDim2.new(0, 5, 0.14, 0) }, auto)
	local power = new("Frame", { Name = "PowerBar", Position = UDim2.fromOffset(0, 44), Size = UDim2.new(1, 0, 0, 20), BackgroundColor3 = Color3.fromRGB(25, 15, 55) }, pad)
	corner(power, 10)
	stroke(power, 2.5)
	local fill = new("Frame", { Name = "Fill", Size = UDim2.fromScale(0.25, 1), BackgroundColor3 = WHITE }, power)
	corner(fill, 10)
	gradient(fill, Color3.fromRGB(255, 220, 80), Color3.fromRGB(255, 110, 40))
	label({ Name = "PowerText", Text = "Potencia 25%", Size = UDim2.new(1, -8, 0.9, 0), Position = UDim2.new(0, 4, 0.05, 0), ZIndex = 2 }, power)
	local tap = new("TextButton", { Name = "TapButton", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 0), Size = UDim2.fromOffset(130, 130), BackgroundColor3 = WHITE, AutoButtonColor = false, Text = "" }, pad)
	corner(tap, 65)
	stroke(tap, 4)
	gradient(tap, Color3.fromRGB(255, 120, 80), Color3.fromRGB(220, 40, 90))
	new("UIScale", {}, tap)
	label({ Name = "Icon", Text = "🚀", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.4), Size = UDim2.fromScale(0.45, 0.4) }, tap)
	label({ Name = "Label", Text = "¡TAP!", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.74), Size = UDim2.fromScale(0.7, 0.24) }, tap)
	label({ Name = "Hint", Text = "¡Spamea clic o ESPACIO!", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 0, -6), Size = UDim2.fromOffset(240, 26), TextColor3 = Color3.fromRGB(255, 240, 120), Visible = false }, pad)
end

new("Frame", { Name = "NukeFlash", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, Visible = false, ZIndex = 20 }, root)

return "ok"
