-- StarterGui/HUD/Modules/ClientSettings (ModuleScript)
-- Ajustes del jugador: volumen de música y efectos, tamaño del HUD y efectos visuales.
-- Por ahora viven solo en esta sesión; en la Fase 3 se guardan con DataStore.

local UserInputService = game:GetService("UserInputService")

local ClientSettings = {}

ClientSettings.Values = {
	MusicVolume = 0.4, -- 0 a 1
	SfxVolume = 0.7, -- 0 a 1
	HudScale = 1, -- 0.7 a 1.3
	EffectsMode = "Auto", -- "Auto" | "On" | "Off"
}

ClientSettings.Limits = {
	HudScale = { Min = 0.7, Max = 1.3 },
}

local changed = Instance.new("BindableEvent")
ClientSettings.Changed = changed.Event -- (key, value)

function ClientSettings.Set(key: string, value: any)
	if ClientSettings.Values[key] == value then
		return
	end
	ClientSettings.Values[key] = value
	changed:Fire(key, value)
end

function ClientSettings.Get(key: string): any
	return ClientSettings.Values[key]
end

-- Calidad de gráficos que eligió el jugador en el menú de Roblox
local gameSettings = UserSettings():GetService("UserGameSettings")

local function qualityIsHigh(): boolean
	local level = gameSettings.SavedQualityLevel
	if level == Enum.SavedQualitySetting.Automatic then
		-- En automático asumimos que el dispositivo aguanta, salvo celular chico
		local camera = workspace.CurrentCamera
		local smallTouch = UserInputService.TouchEnabled and camera and camera.ViewportSize.Y < 400
		return not smallTouch
	end
	return level.Value >= 5
end

-- ¿Mostrar brillos y animaciones extra?
function ClientSettings.EffectsEnabled(): boolean
	local mode = ClientSettings.Values.EffectsMode
	if mode == "On" then
		return true
	elseif mode == "Off" then
		return false
	end
	return qualityIsHigh()
end

gameSettings:GetPropertyChangedSignal("SavedQualityLevel"):Connect(function()
	changed:Fire("Quality", gameSettings.SavedQualityLevel)
end)

-- Escala final del HUD: tamaño de pantalla × preferencia del jugador
function ClientSettings.GetUIScale(): number
	local camera = workspace.CurrentCamera
	local screen = math.clamp(camera.ViewportSize.Y / 720, 0.55, 1.15)
	return screen * ClientSettings.Values.HudScale
end

-- Escala para un panel: igual que el HUD, pero nunca más grande que la pantalla
-- (deja margen para el título y la X que sobresalen)
function ClientSettings.GetPanelScale(panel: GuiObject): number
	local viewport = workspace.CurrentCamera.ViewportSize
	local width = panel.Size.X.Offset + 60
	local height = panel.Size.Y.Offset + 90
	return math.min(ClientSettings.GetUIScale(), viewport.X * 0.96 / width, viewport.Y * 0.92 / height)
end

return ClientSettings
