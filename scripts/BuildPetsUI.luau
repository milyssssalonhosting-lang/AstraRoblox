-- Herramienta (no va dentro del juego): ajustes de UI para las mascotas 3D.
--  * Lista de probabilidades de cada huevo con scroll (ahora hay hasta 17 mascotas).
--  * Botón "Fusionar" en el detalle del inventario.

local hud = game.StarterGui.HUD
local INK = Color3.fromRGB(28, 22, 40)
local FONT = Enum.Font.FredokaOne

-- Odds: Frame → ScrollingFrame
local card = hud.Panels.ShopPanel.Content.Eggs.EggCardTemplate
local odds = card.Odds
if odds:IsA("Frame") then
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Odds"
	scroll.Position = odds.Position
	scroll.Size = odds.Size
	scroll.BackgroundColor3 = odds.BackgroundColor3
	scroll.BackgroundTransparency = odds.BackgroundTransparency
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 5
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.CanvasSize = UDim2.new()
	for _, child in odds:GetChildren() do
		child.Parent = scroll
	end
	scroll.Parent = card
	odds:Destroy()
	scroll.OddsRowTemplate.Size = UDim2.new(1, -6, 0, 26)
end

-- Detalle del inventario: íconos más chicos y botón Fusionar
local details = hud.Panels.InventoryPanel.Content.Details
details.BigIcon.Size = UDim2.fromOffset(100, 90)
details.NameText.Position = UDim2.fromOffset(10, 96)
details.RarityText.Position = UDim2.fromOffset(10, 124)
details.BoostText.Position = UDim2.fromOffset(10, 146)
details.OwnedText.Position = UDim2.fromOffset(10, 166)
details.EquipButton.Position = UDim2.new(0, 14, 1, -104)
details.EquipBestButton.Position = UDim2.new(0, 14, 1, -54)

local old = details:FindFirstChild("FuseButton")
if old then
	old:Destroy()
end
local fuse = details.EquipButton:Clone()
fuse.Name = "FuseButton"
fuse.Position = UDim2.new(0, 14, 1, -152)
fuse.Size = UDim2.new(1, -28, 0, 40)
fuse.UIGradient.Color = ColorSequence.new(Color3.fromRGB(200, 120, 255), Color3.fromRGB(120, 45, 210))
fuse.Label.Text = "Fusionar"
fuse.Visible = false
fuse:SetAttribute("EffectsAttached", nil)
fuse.Parent = details

return "ok"
