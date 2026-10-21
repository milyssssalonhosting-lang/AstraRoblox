-- StarterGui/HUD/Modules/Sfx (ModuleScript)
-- Sonidos de la interfaz y música de fondo. Usa dos SoundGroups (Música y Efectos)
-- para que el volumen de cada uno se controle desde Settings.

local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local ClientSettings = require(script.Parent.ClientSettings)

local Sfx = {}

local function getGroup(name: string): SoundGroup
	local group = SoundService:FindFirstChild(name)
	if not group then
		group = Instance.new("SoundGroup")
		group.Name = name
		group.Parent = SoundService
	end
	return group
end

local musicGroup = getGroup("MusicGroup")
local sfxGroup = getGroup("SfxGroup")

local sounds: { [string]: Sound } = {}
for name, id in GameConfig.Sounds do
	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = id
	if name == "Music" then
		sound.Looped = true
		sound.SoundGroup = musicGroup
	else
		sound.SoundGroup = sfxGroup
	end
	if name == "RocketEngine" then
		sound.Looped = true
		sound.Volume = 0.35
	end
	sound.Parent = sound.SoundGroup
	sounds[name] = sound
end

local function applyVolumes()
	musicGroup.Volume = ClientSettings.Get("MusicVolume")
	sfxGroup.Volume = ClientSettings.Get("SfxVolume")
end
applyVolumes()
ClientSettings.Changed:Connect(function(key)
	if key == "MusicVolume" or key == "SfxVolume" then
		applyVolumes()
	end
end)

-- Reproduce un efecto (pitch opcional para variar un poco el tono)
function Sfx.Play(name: string, pitch: number?)
	local sound = sounds[name]
	if sound then
		sound.PlaybackSpeed = pitch or 1
		sound.TimePosition = 0
		sound:Play()
	end
end

-- Para sonidos en loop (motor del cohete): encender/apagar y cambiar el tono
function Sfx.SetLoop(name: string, on: boolean, pitch: number?)
	local sound = sounds[name]
	if not sound then
		return
	end
	if pitch then
		sound.PlaybackSpeed = pitch
	end
	if on and not sound.IsPlaying then
		sound:Play()
	elseif not on and sound.IsPlaying then
		sound:Stop()
	end
end

function Sfx.StartMusic()
	local music = sounds.Music
	if music and not music.IsPlaying then
		music:Play()
	end
end

return Sfx
