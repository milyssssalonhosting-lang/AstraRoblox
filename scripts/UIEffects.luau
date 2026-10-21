-- StarterGui/HUD/Modules/UIEffects (ModuleScript)
-- Animaciones de la interfaz: botones que crecen y se aplastan, destello que
-- cruza el botón al pasar el mouse, brillo de "¡reclámame!", confeti.
-- Los efectos "extra" (destellos, pulsos, confeti) se apagan solos si el jugador
-- tiene gráficos bajos o los desactiva en Settings. El crecer/aplastar siempre
-- está, porque es barato y ayuda a saber que el botón respondió.

local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")

local ClientSettings = require(script.Parent.ClientSettings)
local Sfx = require(script.Parent.Sfx)

local UIEffects = {}

local quick = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local bounce = TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local sweep = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function fancy(): boolean
	return ClientSettings.EffectsEnabled() and not GuiService.ReducedMotionEnabled
end
UIEffects.Fancy = fancy

---------------------------------------------------------------- Destello
-- Una franja blanca diagonal que cruza el botón de izquierda a derecha.
local function getShine(button: GuiObject): UIGradient
	local shine = button:FindFirstChild("Shine")
	if not shine then
		shine = Instance.new("Frame")
		shine.Name = "Shine"
		shine.Size = UDim2.fromScale(1, 1)
		shine.BackgroundColor3 = Color3.new(1, 1, 1)
		shine.BackgroundTransparency = 0.25
		shine.ZIndex = button.ZIndex + 1
		shine.Active = false
		shine.Interactable = false
		local corner = button:FindFirstChildOfClass("UICorner")
		if corner then
			corner:Clone().Parent = shine
		end
		local gradient = Instance.new("UIGradient")
		gradient.Rotation = 20
		gradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.42, 1),
			NumberSequenceKeypoint.new(0.5, 0.2),
			NumberSequenceKeypoint.new(0.58, 1),
			NumberSequenceKeypoint.new(1, 1),
		})
		gradient.Offset = Vector2.new(-1, 0)
		gradient.Parent = shine
		shine.Parent = button
	end
	return shine.UIGradient
end

function UIEffects.Shine(button: GuiObject)
	if not fancy() then
		return
	end
	local gradient = getShine(button)
	gradient.Offset = Vector2.new(-1, 0)
	TweenService:Create(gradient, sweep, { Offset = Vector2.new(1, 0) }):Play()
end

-- Destello automático cada cierto tiempo (para botones importantes)
function UIEffects.AutoShine(button: GuiObject, interval: number)
	task.spawn(function()
		task.wait(math.random() * interval)
		while button.Parent do
			if button.Visible then
				UIEffects.Shine(button)
			end
			task.wait(interval)
		end
	end)
end

---------------------------------------------------------------- Botones
-- Crece al pasar el mouse, se aplasta al presionar, rebota al soltar, suena al clic.
function UIEffects.AttachButton(button: GuiButton, clickSound: string?)
	if button:GetAttribute("EffectsAttached") then
		return
	end
	button:SetAttribute("EffectsAttached", true)
	local scale = button:FindFirstChildOfClass("UIScale")
	if not scale then
		scale = Instance.new("UIScale")
		scale.Parent = button
	end
	button.MouseEnter:Connect(function()
		TweenService:Create(scale, quick, { Scale = 1.07 }):Play()
		UIEffects.Shine(button)
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(scale, quick, { Scale = 1 }):Play()
	end)
	button.MouseButton1Down:Connect(function()
		TweenService:Create(scale, quick, { Scale = 0.9 }):Play()
	end)
	button.MouseButton1Up:Connect(function()
		TweenService:Create(scale, bounce, { Scale = 1 }):Play()
	end)
	button.Activated:Connect(function()
		Sfx.Play(clickSound or "Click", 0.95 + math.random() * 0.1)
	end)
end

function UIEffects.AttachAll(root: Instance)
	for _, descendant in root:GetDescendants() do
		if descendant:IsA("GuiButton") and descendant.Name ~= "Dim" and descendant:FindFirstChildOfClass("UIScale") then
			UIEffects.AttachButton(descendant)
		end
	end
end

---------------------------------------------------------------- Brillo de "¡reclámame!"
-- El borde del objeto late entre dorado y blanco. Devuelve una función para apagarlo.
function UIEffects.Glow(guiObject: GuiObject): () -> ()
	local stroke = guiObject:FindFirstChildOfClass("UIStroke")
	if not stroke or not fancy() then
		return function() end
	end
	local original = { Color = stroke.Color, Thickness = stroke.Thickness }
	stroke.Color = Color3.fromRGB(255, 220, 60)
	local tween = TweenService:Create(
		stroke,
		TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Color = Color3.new(1, 1, 1), Thickness = original.Thickness + 2 }
	)
	tween:Play()
	return function()
		tween:Cancel()
		stroke.Color = original.Color
		stroke.Thickness = original.Thickness
	end
end

---------------------------------------------------------------- Confeti
local CONFETTI_COLORS = {
	Color3.fromRGB(255, 80, 120),
	Color3.fromRGB(255, 210, 50),
	Color3.fromRGB(90, 220, 90),
	Color3.fromRGB(80, 180, 255),
	Color3.fromRGB(200, 100, 255),
}

-- Lluvia de papelitos desde el centro de "origin" (un GuiObject) dentro de "layer"
function UIEffects.Confetti(layer: GuiObject, origin: GuiObject, count: number?)
	if not fancy() then
		return
	end
	local center = origin.AbsolutePosition + origin.AbsoluteSize / 2 - layer.AbsolutePosition
	for _ = 1, count or 24 do
		local piece = Instance.new("Frame")
		piece.Size = UDim2.fromOffset(math.random(6, 12), math.random(10, 16))
		piece.AnchorPoint = Vector2.new(0.5, 0.5)
		piece.Position = UDim2.fromOffset(center.X, center.Y)
		piece.BackgroundColor3 = CONFETTI_COLORS[math.random(#CONFETTI_COLORS)]
		piece.BorderSizePixel = 0
		piece.Rotation = math.random(0, 360)
		piece.ZIndex = 50
		piece.Parent = layer
		local angle = math.random() * math.pi * 2
		local distance = math.random(80, 220)
		local target = center + Vector2.new(math.cos(angle), math.sin(angle)) * distance + Vector2.new(0, 60)
		local tween = TweenService:Create(piece, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.fromOffset(target.X, target.Y),
			Rotation = piece.Rotation + math.random(-360, 360),
			BackgroundTransparency = 1,
		})
		tween.Completed:Connect(function()
			piece:Destroy()
		end)
		tween:Play()
	end
end

-- Pequeño salto de un objeto (por ejemplo, el contador al recibir premio)
function UIEffects.Bump(guiObject: GuiObject)
	local scale = guiObject:FindFirstChildOfClass("UIScale")
	if not scale then
		return
	end
	local base = scale.Scale
	scale.Scale = base * 1.15
	TweenService:Create(scale, bounce, { Scale = base }):Play()
end

return UIEffects
