-- ReplicatedStorage/Shared/GameConfig (ModuleScript)
-- Números del juego en un solo lugar. Lo leen el servidor y el cliente.
-- Cambiar aquí precios, velocidades, etc. sin tocar la lógica.

local GameConfig = {}

-- Modo prueba: en Studio cada jugador empieza con dinero casi ilimitado.
-- En el juego publicado esto NO aplica (el servidor revisa RunService:IsStudio()).
GameConfig.DevStartMoney = 1e15

-- Ganancia pasiva
GameConfig.PassiveTickSeconds = 1
GameConfig.BasePassiveMoney = 10 -- $ por segundo antes de multiplicadores
GameConfig.PassiveXP = 1 -- XP por segundo

-- Bono por amigos en el servidor
GameConfig.FriendBoostPerFriend = 0.10 -- +10% por amigo
GameConfig.FriendBoostMax = 0.50 -- tope +50%

-- Rebirth: reinicias dinero y mejoras a cambio de un bono de dinero permanente.
-- Conservas mascotas, nivel, pase y todo lo demás.
GameConfig.Rebirth = {
	BaseCost = 1000000, -- $1M para el primero
	CostGrowth = 4, -- cada rebirth cuesta 4 veces más
	MoneyBonusPerRebirth = 0.5, -- +50% de dinero por cada rebirth
}

function GameConfig.RebirthCost(rebirths: number): number
	return GameConfig.Rebirth.BaseCost * GameConfig.Rebirth.CostGrowth ^ rebirths
end

function GameConfig.RebirthMultiplier(rebirths: number): number
	return 1 + rebirths * GameConfig.Rebirth.MoneyBonusPerRebirth
end

-- Zona AFK del lobby: parado dentro del círculo ganas más
GameConfig.AFK = {
	Multiplier = 2, -- x2 dinero (con VIP será x4)
	Radius = 11, -- studs desde el centro del círculo
}

-- Otros mundos (lugares del mismo juego). PlaceId = 0 → todavía no existe.
-- Cuando se publique el juego y se creen los lugares, se pone aquí su PlaceId.
GameConfig.Worlds = {
	AFK = {
		Name = "Mundo AFK",
		Description = "Un mundo solo para estar AFK. ¡Déjalo ganando mientras comes o duermes!",
		PlaceId = 0,
	},
	Main = {
		Name = "Slime al Espacio",
		Description = "¡Lanza tu slime en cohete hasta la galaxia! Rondas automáticas: tú solo mejora y sube.",
		PlaceId = 0,
		LocalSpawn = "RocketSpawn", -- mientras no se publique: viaje dentro del mismo lugar
	},
	Lobby = {
		Name = "la Zona de Inicio",
		Description = "Volver al lobby: huevos, rebirth, zona AFK y más.",
		PlaceId = 0,
		LocalSpawn = "SpawnLocation",
	},
}

-- XP necesaria para pasar del nivel N al N+1
function GameConfig.XPForLevel(level: number): number
	return 100 * level
end

-- Mejoras (Upgrades). MaxLevel = cantidad de rayitas de la barra.
GameConfig.Upgrades = {
	{
		Id = "WalkSpeed",
		DisplayName = "Velocidad",
		Icon = "👟",
		MaxLevel = 8,
		BaseCost = 100,
		CostGrowth = 2.5,
		BaseValue = 16,
		PerLevel = 3,
		Format = "%d",
	},
	{
		Id = "MoneyMultiplier",
		DisplayName = "Multiplicador $",
		Icon = "💵",
		MaxLevel = 8,
		BaseCost = 250,
		CostGrowth = 3,
		BaseValue = 1,
		PerLevel = 0.25,
		Format = "x%.2f",
	},
	{
		Id = "PassiveIncome",
		DisplayName = "Ingreso pasivo",
		Icon = "⏱️",
		MaxLevel = 8,
		BaseCost = 500,
		CostGrowth = 3,
		BaseValue = 10,
		PerLevel = 15,
		Format = "$%d/s",
	},
	-- Mejoras del cohete (Slime al Espacio)
	{
		Id = "RocketEngine",
		DisplayName = "Motor",
		Icon = "🚀",
		MaxLevel = 8,
		BaseCost = 200,
		CostGrowth = 2.6,
		BaseValue = 15,
		PerLevel = 8,
		Format = "%d m/s",
	},
	{
		Id = "RocketFuel",
		DisplayName = "Combustible",
		Icon = "⛽",
		MaxLevel = 8,
		BaseCost = 300,
		CostGrowth = 2.8,
		BaseValue = 12,
		PerLevel = 4,
		Format = "%d s",
	},
}

---------------------------------------------------------------- Slime al Espacio (cohete)
GameConfig.Rocket = {
	-- Rondas automáticas
	PrepareSeconds = 10, -- cuenta regresiva antes de despegar (corta: enganche rápido)
	FlightSeconds = 45, -- tiempo de vuelo
	ResultsSeconds = 8, -- ver resultados antes de la siguiente
	TickSeconds = 0.25, -- cada cuánto calcula el servidor la altura

	MoneyPerMeter = 5, -- dinero al final según la altura (× multiplicadores)
	LiveMoneyPerMeter = 1, -- dinero EN VIVO por cada metro que subes (× rebirth), se paga cada segundo
	LiveXPPerSecond = 2, -- XP cada segundo mientras subes
	XPPerRound = 25,
	BPXPPerRound = 20,
	StudsPerMeter = 0.4, -- altura visual: 1 metro = 0.4 studs

	-- Capas del cielo (metros). Al pasar cada una sale un aviso y cambia el cielo.
	Layers = {
		{ Id = "Sky", Name = "Cielo", Altitude = 0, Icon = "☁️", SkyTop = Color3.fromRGB(120, 200, 255) },
		{ Id = "Clouds", Name = "Nubes", Altitude = 150, Icon = "🌥️", SkyTop = Color3.fromRGB(150, 210, 255) },
		{ Id = "Rainbow", Name = "Arcoíris", Altitude = 600, Icon = "🌈", SkyTop = Color3.fromRGB(255, 170, 220) },
		{ Id = "Space", Name = "Espacio", Altitude = 1500, Icon = "🌌", SkyTop = Color3.fromRGB(40, 30, 90) },
		{ Id = "Moon", Name = "Luna", Altitude = 3500, Icon = "🌙", SkyTop = Color3.fromRGB(20, 15, 50) },
		{ Id = "Mars", Name = "Marte", Altitude = 7000, Icon = "🔴", SkyTop = Color3.fromRGB(60, 15, 20) },
		{ Id = "Galaxy", Name = "Galaxia", Altitude = 15000, Icon = "✨", SkyTop = Color3.fromRGB(70, 20, 110) },
	},
}

-- Objetos en el aire: aparecen en el carril de cada cohete y se recogen solos
-- al pasar (modo automático). El servidor decide dónde salen y aplica el efecto.
GameConfig.Rocket.Pickups = {
	CoinSpacing = { 35, 80 }, -- metros entre monedas (al azar entre estos dos)
	GemSpacing = { 300, 650 }, -- metros entre gemas
	CoinBase = 25, -- valor de una moneda = (CoinBase + altura × CoinPerMeter) × rebirth
	CoinPerMeter = 0.4,
	Gems = {
		Turbo = { Name = "Turbo", Icon = "⚡", Model = "GemTurbo", Weight = 40, SpeedMultiplier = 1.6, Seconds = 5 },
		Fuel = { Name = "Combustible", Icon = "⛽", Model = "GemFuel", Weight = 35, ExtraFuel = 4 },
		Double = { Name = "Premio x2", Icon = "💰", Model = "GemDouble", Weight = 20 },
		Galaxy = { Name = "Gema Galáctica", Icon = "🌌", Model = "GemGalaxy", Weight = 5, SpeedMultiplier = 2, Seconds = 4, CoinBurst = 10 },
	},
}

-- Trolleos: se compran durante el vuelo (por ahora con dinero del juego; en la
-- Fase 4 también con Robux). El servidor elige al objetivo y aplica el efecto.
GameConfig.Rocket.Trolls = {
	ProtectSeconds = 3, -- después de recibir un trolleo nadie te puede trollear por 3 s
	List = {
		{ Id = "Meteor", Name = "Meteorito", Icon = "☄️", Price = 2500, Cooldown = 5, AltitudeLoss = 0.25, StunSeconds = 2 },
		{ Id = "Steal", Name = "Robar Turbo", Icon = "🧲", Price = 5000, Cooldown = 8, BoostMultiplier = 1.6, BoostSeconds = 5, SlowMultiplier = 0.5, SlowSeconds = 4 },
		{ Id = "Nuke", Name = "Bomba Nuclear", Icon = "☢️", Price = 50000, Cooldown = 999, StunSeconds = 1.5, OncePerRound = true },
	},
}

function GameConfig.GetTroll(id: string)
	for _, troll in GameConfig.Rocket.Trolls.List do
		if troll.Id == id then
			return troll
		end
	end
	return nil
end

-- Cohetes bot: llenan la carrera cuando hay pocos jugadores (siempre hay rivales)
GameConfig.Rocket.Bots = {
	MinRacers = 4,
	Names = { "Slimey", "Burbuja", "Gelatina", "Cohetín", "Estrellita", "Galaxio", "Pepino", "Nubecita" },
	SpeedRange = { 0.7, 1.25 }, -- relativo al promedio de los jugadores
}

-- Volar spameando: cada clic / Espacio / TAP cuenta. Potencia según clics por segundo:
-- sin clics sube al MinPower; a TargetCPS llega a MaxPower. Auto-clic = AutoPower.
GameConfig.Rocket.Click = {
	MinPower = 0.25,
	MaxPower = 1.3, -- spamear a mano rinde un poco más que el auto-clic
	TargetCPS = 7, -- clics por segundo para la potencia máxima
	MaxCPS = 20, -- más que esto se ignora (anti-trampa)
	AutoPower = 1,
	AutoClickFree = true, -- Fase 4: poner false y venderlo barato (pase o Robux)
}

-- Rondas variadas: no siempre se despega desde el piso (cambia el fondo y da emoción)
GameConfig.Rocket.StartVariants = {
	{ Id = "Ground", Name = "el piso", Icon = "🏝️", Altitude = 0, Weight = 55 },
	{ Id = "Clouds", Name = "las NUBES", Icon = "🌥️", Altitude = 300, Weight = 20 },
	{ Id = "Rainbow", Name = "el ARCOÍRIS", Icon = "🌈", Altitude = 800, Weight = 15 },
	{ Id = "Space", Name = "el ESPACIO", Icon = "🌌", Altitude = 2000, Weight = 8 },
	{ Id = "Moon", Name = "la LUNA", Icon = "🌙", Altitude = 4000, Weight = 2 },
}

-- Colores de cohete: cada jugador tiene el suyo (según su UserId); los bots al azar.
-- Se aplican como tinte sobre la malla del cohete.
GameConfig.Rocket.Colors = {
	Color3.fromRGB(255, 255, 255), -- blanco clásico
	Color3.fromRGB(255, 130, 130), -- rojo
	Color3.fromRGB(255, 190, 110), -- naranja
	Color3.fromRGB(255, 240, 120), -- amarillo
	Color3.fromRGB(140, 255, 150), -- verde
	Color3.fromRGB(130, 220, 255), -- celeste
	Color3.fromRGB(190, 150, 255), -- morado
	Color3.fromRGB(255, 150, 220), -- rosa
}

-- Capa en la que estás y la siguiente (para la barra de progreso)
function GameConfig.RocketLayerAt(altitude: number)
	local layers = GameConfig.Rocket.Layers
	local index = 1
	for i, layer in layers do
		if altitude >= layer.Altitude then
			index = i
		end
	end
	return layers[index], layers[index + 1], index
end

function GameConfig.GetUpgrade(id: string)
	for _, upgrade in GameConfig.Upgrades do
		if upgrade.Id == id then
			return upgrade
		end
	end
	return nil
end

function GameConfig.UpgradeCost(upgrade, currentLevel: number): number
	return math.floor(upgrade.BaseCost * upgrade.CostGrowth ^ currentLevel)
end

function GameConfig.UpgradeValue(upgrade, level: number): number
	return upgrade.BaseValue + upgrade.PerLevel * level
end

---------------------------------------------------------------- Recompensas
-- Una recompensa es una tabla: { Type = "Money" | "XP" | "BPXP" | "Pet", Amount = n, Pet = "Id" }

-- Mascotas. Cada una tiene sus propios bonos (cuando está equipada):
--   Boost  = 💰 +% dinero (pasiva, monedas, dinero en vivo y premio del cohete)
--   Rocket = 🚀 +% velocidad del cohete
--   XP     = ⭐ +% XP (y XP del pase) ganada en el cohete
--   Speed  = 👟 velocidad extra al caminar (solo abejas)
-- Name, Family ("Slime"/"Bee"), Rarity, Icon (emoji de respaldo). El modelo 3D está
-- en ReplicatedStorage.PetModels con el mismo Id.
-- Slimes y abejas: 3 niveles. Fusionar 3 iguales del nivel N da 1 del nivel N+1 (Next).
-- Ids: slimes "Slime_<Sabor>_<1-3>"; abejas "Bee_<Nombre>" (Nv.1, así quedan los datos
-- viejos), "Bee_<Nombre>_2" y "Bee_<Nombre>_3".
GameConfig.Pets = {}

GameConfig.PetPower = 2 -- multiplica TODOS los bonos de las tablas (subir = mascotas más fuertes)
GameConfig.SlimeLevelMultiplier = { 1, 2.5, 6 } -- bonos × según nivel (slimes y abejas)
GameConfig.WalkLevelMultiplier = { 1, 1.5, 2 } -- 👟 caminar × según nivel
GameConfig.FuseAmount = 3 -- cuántas iguales se necesitan para fusionar

local SLIMES = {
	-- Id del sabor, nombre, emoji, rareza, 💰 dinero, 🚀 cohete, ⭐ XP (en nivel 1)
	{ "Vanilla", "Vainilla", "🍦", "Común", 0.06, 0, 0 },
	{ "Lemon", "Limón", "🍋", "Común", 0, 0, 0.10 },
	{ "Lime", "Lima", "🍈", "Común", 0, 0.06, 0 },
	{ "Peach", "Durazno", "🍑", "Común", 0.03, 0.03, 0.03 },
	{ "Strawberry", "Fresa", "🍓", "Raro", 0.10, 0, 0.05 },
	{ "Blueberry", "Arándano", "🫐", "Raro", 0, 0.12, 0 },
	{ "Sky", "Cielo", "☁️", "Raro", 0, 0.08, 0.08 },
	{ "Lavender", "Lavanda", "💜", "Raro", 0, 0, 0.18 },
	{ "Grape", "Uva", "🍇", "Épico", 0.20, 0.05, 0 },
	{ "Cherry", "Cereza", "🍒", "Épico", 0.05, 0.20, 0 },
	{ "Rose", "Rosa", "🌹", "Épico", 0, 0.05, 0.30 },
	{ "Chocolate", "Chocolate", "🍫", "Épico", 0.25, 0, 0.05 },
	{ "Pearl", "Perla", "🤍", "Legendario", 0.35, 0, 0.12 },
	{ "Midnight", "Medianoche", "🌙", "Legendario", 0, 0.35, 0.10 },
	{ "Blossom", "Flor", "🌸", "Legendario", 0.15, 0.15, 0.15 },
	{ "Emerald", "Esmeralda", "💎", "Mítico", 0.60, 0.15, 0 },
	{ "Rainbow", "Arcoíris", "🌈", "Mítico", 0.30, 0.30, 0.30 },
}
GameConfig.SlimeFlavors = {}
for _, s in SLIMES do
	table.insert(GameConfig.SlimeFlavors, s[1])
	for level = 1, 3 do
		local m = GameConfig.SlimeLevelMultiplier[level]
		GameConfig.Pets["Slime_" .. s[1] .. "_" .. level] = {
			Name = "Slime " .. s[2] .. (if level > 1 then " Nv." .. level else ""),
			Family = "Slime",
			Icon = s[3],
			Rarity = s[4],
			Level = level,
			Boost = s[5] * m * GameConfig.PetPower,
			Rocket = s[6] * m * GameConfig.PetPower,
			XP = s[7] * m * GameConfig.PetPower,
			Next = if level < 3 then "Slime_" .. s[1] .. "_" .. (level + 1) else nil,
		}
	end
end

local BEES = {
	-- Id del modelo, nombre, rareza, 💰 dinero, 🚀 cohete, ⭐ XP, 👟 caminar
	{ "HoneyBee", "Abeja Miel", "Común", 0, 0.08, 0, 2 },
	{ "ThinBee", "Abeja Flaca", "Común", 0, 0, 0.08, 2 },
	{ "SadBee", "Abeja Triste", "Común", 0.05, 0, 0.04, 0 },
	{ "DumbBee", "Abeja Tontita", "Común", 0.05, 0.03, 0, 0 },
	{ "FatHoneyBee", "Abeja Gordita", "Raro", 0, 0.12, 0, 3 },
	{ "WhiteBee", "Abeja Blanca", "Raro", 0.10, 0, 0.06, 0 },
	{ "AppleBee", "Abeja Manzana", "Raro", 0.10, 0.05, 0, 0 },
	{ "FatGreenBee", "Abeja Verde", "Raro", 0.14, 0, 0, 0 },
	{ "FatBlueBee", "Abeja Azul", "Épico", 0.20, 0, 0.10, 0 },
	{ "AngryBee", "Abeja Enojada", "Épico", 0, 0.22, 0, 4 },
	{ "TigerBee", "Abeja Tigre", "Épico", 0.05, 0.22, 0, 5 },
	{ "SecterBee", "Abeja Secreta", "Épico", 0.22, 0, 0.12, 0 },
	{ "NinjaBee", "Abeja Ninja", "Legendario", 0, 0.35, 0.05, 7 },
	{ "FatAngryBee", "Abeja Furia", "Legendario", 0, 0.28, 0.12, 6 },
	{ "ButterFlyBee", "Abeja Mariposa", "Legendario", 0.35, 0, 0.18, 0 },
	{ "TornadoBee", "Abeja Tornado", "Mítico", 0, 0.60, 0, 10 },
	{ "KawaiBee", "Abeja Kawaii", "Mítico", 0.60, 0, 0.30, 0 },
}
GameConfig.BeeIds = {} -- solo Nv.1 (lo que sale de los huevos)
local function beeId(name: string, level: number): string
	return "Bee_" .. name .. (if level > 1 then "_" .. level else "")
end
for _, b in BEES do
	table.insert(GameConfig.BeeIds, beeId(b[1], 1))
	for level = 1, 3 do
		local m = GameConfig.SlimeLevelMultiplier[level] * GameConfig.PetPower
		GameConfig.Pets[beeId(b[1], level)] = {
			Name = b[2] .. (if level > 1 then " Nv." .. level else ""),
			Family = "Bee",
			Icon = "🐝",
			Rarity = b[3],
			Level = level,
			Boost = b[4] * m,
			Rocket = b[5] * m,
			XP = b[6] * m,
			Speed = math.floor(b[7] * GameConfig.WalkLevelMultiplier[level]),
			Next = if level < 3 then beeId(b[1], level + 1) else nil,
		}
	end
end

GameConfig.MaxPetSpeed = 40 -- tope de velocidad al caminar sumando todas las mascotas
GameConfig.MaxPetRocket = 10 -- tope del bono de cohete (+1000%)

local function percent(value: number): string
	return math.floor(value * 100 + 0.5) .. "%"
end

-- Texto corto de los bonos: "💰+10% 🚀+5% ⭐+8% 👟+2"
function GameConfig.PetStatText(pet): string
	local parts = {}
	if (pet.Boost or 0) > 0 then
		table.insert(parts, "💰+" .. percent(pet.Boost))
	end
	if (pet.Rocket or 0) > 0 then
		table.insert(parts, "🚀+" .. percent(pet.Rocket))
	end
	if (pet.XP or 0) > 0 then
		table.insert(parts, "⭐+" .. percent(pet.XP))
	end
	if (pet.Speed or 0) > 0 then
		table.insert(parts, "👟+" .. pet.Speed)
	end
	return table.concat(parts, " ")
end

-- Puntaje para "Equipar mejores": todo cuenta, el dinero un poco más
function GameConfig.PetScore(pet): number
	return (pet.Boost or 0) * 1.2 + (pet.Rocket or 0) + (pet.XP or 0) * 0.8 + (pet.Speed or 0) * 0.02
end

-- Orden y colores de las rarezas (para tarjetas del inventario e index)
GameConfig.Rarities = {
	["Común"] = { Order = 1, Top = Color3.fromRGB(190, 200, 210), Bottom = Color3.fromRGB(120, 135, 150) },
	["Raro"] = { Order = 2, Top = Color3.fromRGB(110, 200, 255), Bottom = Color3.fromRGB(35, 110, 230) },
	["Épico"] = { Order = 3, Top = Color3.fromRGB(215, 130, 255), Bottom = Color3.fromRGB(130, 45, 210) },
	["Legendario"] = { Order = 4, Top = Color3.fromRGB(255, 225, 90), Bottom = Color3.fromRGB(240, 140, 20) },
	["Mítico"] = { Order = 5, Top = Color3.fromRGB(255, 120, 190), Bottom = Color3.fromRGB(120, 80, 255) },
}

---------------------------------------------------------------- Huevos (gacha)
-- Cada huevo da pesos POR RAREZA: todas las mascotas de una misma rareza tienen
-- el mismo peso. La probabilidad real de cada mascota es peso / suma de pesos,
-- y SIEMPRE se le muestra al jugador antes de abrir (regla de Roblox).
local function slimeIds()
	local ids = {}
	for _, flavor in GameConfig.SlimeFlavors do
		table.insert(ids, "Slime_" .. flavor .. "_1") -- los huevos dan nivel 1
	end
	return ids
end

local function buildPool(ids: { string }, weightByRarity: { [string]: number })
	local pool = {}
	for _, id in ids do
		local weight = weightByRarity[GameConfig.Pets[id].Rarity]
		if weight and weight > 0 then
			table.insert(pool, { Pet = id, Weight = weight })
		end
	end
	return pool
end

local allIds = slimeIds()
for _, id in GameConfig.BeeIds do
	table.insert(allIds, id)
end

GameConfig.Eggs = {
	{
		Id = "Slime",
		Name = "Huevo Slime",
		Icon = "🥚",
		Price = 500,
		Top = Color3.fromRGB(150, 240, 170),
		Bottom = Color3.fromRGB(40, 170, 110),
		Pets = buildPool(slimeIds(), { ["Común"] = 15, ["Raro"] = 6, ["Épico"] = 3, ["Legendario"] = 1, ["Mítico"] = 0.5 }),
	},
	{
		Id = "Bee",
		Name = "Huevo Abeja",
		Icon = "🍯",
		Price = 5000,
		Top = Color3.fromRGB(255, 225, 90),
		Bottom = Color3.fromRGB(240, 140, 20),
		Pets = buildPool(GameConfig.BeeIds, { ["Común"] = 14, ["Raro"] = 6, ["Épico"] = 4, ["Legendario"] = 1, ["Mítico"] = 0.5 }),
	},
	{
		Id = "Rainbow",
		Name = "Huevo Arcoíris",
		Icon = "🌈",
		Price = 1000000,
		Top = Color3.fromRGB(255, 120, 190),
		Bottom = Color3.fromRGB(120, 80, 255),
		-- Solo Épicos o mejores de ambas familias
		Pets = buildPool(allIds, { ["Épico"] = 10, ["Legendario"] = 3, ["Mítico"] = 0.5 }),
	},
}
GameConfig.EggOpenAmounts = { 1, 3 } -- abrir 1 o 3 a la vez

function GameConfig.GetEgg(id: string)
	for _, egg in GameConfig.Eggs do
		if egg.Id == id then
			return egg
		end
	end
	return nil
end

-- Probabilidad (0 a 1) de cada mascota del huevo
function GameConfig.EggChances(egg): { { Pet: string, Chance: number } }
	local total = 0
	for _, entry in egg.Pets do
		total += entry.Weight
	end
	local chances = {}
	for _, entry in egg.Pets do
		table.insert(chances, { Pet = entry.Pet, Chance = entry.Weight / total })
	end
	return chances
end

-- Texto de porcentaje: 0.45 -> "45%", 0.035 -> "3.5%"
function GameConfig.FormatChance(chance: number): string
	local percent = chance * 100
	if percent >= 10 or percent == math.floor(percent) then
		return string.format("%d%%", math.floor(percent + 0.5))
	end
	return (string.format("%.2f", percent):gsub("%.?0+$", "")) .. "%"
end

-- Cuántas mascotas se pueden equipar a la vez (después: más espacios con Robux/VIP)
GameConfig.MaxEquippedPets = 5

-- Lista de Ids de mascotas ordenada por rareza (para el Index)
function GameConfig.PetIdsSorted(): { string }
	local ids = {}
	for id in GameConfig.Pets do
		table.insert(ids, id)
	end
	table.sort(ids, function(a, b)
		local pa, pb = GameConfig.Pets[a], GameConfig.Pets[b]
		local ra, rb = GameConfig.Rarities[pa.Rarity].Order, GameConfig.Rarities[pb.Rarity].Order
		if ra ~= rb then
			return ra < rb
		end
		return pa.Name < pb.Name
	end)
	return ids
end

function GameConfig.RewardIcon(reward): string
	if reward.Type == "Money" then
		return "💵"
	elseif reward.Type == "XP" then
		return "⭐"
	elseif reward.Type == "BPXP" then
		return "🎫"
	elseif reward.Type == "Pet" then
		local pet = GameConfig.Pets[reward.Pet]
		return pet and pet.Icon or "🥚"
	end
	return "🎁"
end

function GameConfig.RewardText(reward): string
	if reward.Type == "Money" then
		return "$" .. GameConfig.FormatNumber(reward.Amount)
	elseif reward.Type == "XP" then
		return GameConfig.FormatNumber(reward.Amount) .. " XP"
	elseif reward.Type == "BPXP" then
		return GameConfig.FormatNumber(reward.Amount) .. " Pase"
	elseif reward.Type == "Pet" then
		local pet = GameConfig.Pets[reward.Pet]
		return pet and pet.Name or "Mascota"
	end
	return "?"
end

---------------------------------------------------------------- Recompensas diarias
GameConfig.Daily = {
	CooldownSeconds = 24 * 3600, -- 1 día entre reclamos
	ResetAfterSeconds = 48 * 3600, -- si pasan 2 días sin reclamar, vuelves al día 1
	-- En Studio el tiempo va rápido para poder probar
	StudioCooldownSeconds = 15,
	StudioResetAfterSeconds = 120,
	Rewards = {
		{ Type = "Money", Amount = 1000 },
		{ Type = "Pet", Pet = "Slime_Lemon_1" },
		{ Type = "XP", Amount = 250 },
		{ Type = "Money", Amount = 25000 },
		{ Type = "Pet", Pet = "Bee_FatHoneyBee" },
		{ Type = "BPXP", Amount = 500 },
		{ Type = "Pet", Pet = "Slime_Rainbow_1" }, -- día 7: el premio grande
	},
}

---------------------------------------------------------------- Misiones
-- Stat = qué se mide. "Level" usa el nivel; los demás son contadores del jugador.
GameConfig.MissionStats = {
	Level = "Nivel",
	MoneyEarned = "Dinero ganado",
	UpgradesBought = "Mejoras compradas",
	PlaySeconds = "Tiempo jugado",
	DailyClaims = "Recompensas diarias",
	EggsOpened = "Huevos abiertos",
	PetsFused = "Mascotas fusionadas",
	RocketRounds = "Rondas de cohete",
	RocketBest = "Mejor altura",
	RocketGems = "Gemas del cohete",
	RocketTrolls = "Trolleos lanzados",
}

GameConfig.Missions = {
	{ Id = "Level2", Text = "Llega al nivel 2", Stat = "Level", Target = 2, Rewards = { { Type = "Money", Amount = 500 }, { Type = "BPXP", Amount = 100 } } },
	{ Id = "Level5", Text = "Llega al nivel 5", Stat = "Level", Target = 5, Rewards = { { Type = "Money", Amount = 5000 }, { Type = "BPXP", Amount = 250 } } },
	{ Id = "Level10", Text = "Llega al nivel 10", Stat = "Level", Target = 10, Rewards = { { Type = "Pet", Pet = "Bee_ButterFlyBee" }, { Type = "BPXP", Amount = 500 } } },
	{ Id = "Earn1K", Text = "Gana $1,000", Stat = "MoneyEarned", Target = 1000, Rewards = { { Type = "XP", Amount = 100 }, { Type = "BPXP", Amount = 100 } } },
	{ Id = "Earn100K", Text = "Gana $100,000", Stat = "MoneyEarned", Target = 100000, Rewards = { { Type = "Pet", Pet = "Slime_Grape_1" }, { Type = "BPXP", Amount = 300 } } },
	{ Id = "Upgrade1", Text = "Compra 1 mejora", Stat = "UpgradesBought", Target = 1, Rewards = { { Type = "Money", Amount = 1000 }, { Type = "BPXP", Amount = 100 } } },
	{ Id = "Upgrade10", Text = "Compra 10 mejoras", Stat = "UpgradesBought", Target = 10, Rewards = { { Type = "Pet", Pet = "Bee_WhiteBee" }, { Type = "BPXP", Amount = 300 } } },
	{ Id = "Play5", Text = "Juega 5 minutos", Stat = "PlaySeconds", Target = 300, Rewards = { { Type = "Money", Amount = 2000 }, { Type = "BPXP", Amount = 150 } } },
	{ Id = "Play30", Text = "Juega 30 minutos", Stat = "PlaySeconds", Target = 1800, Rewards = { { Type = "Pet", Pet = "Slime_Strawberry_1" }, { Type = "BPXP", Amount = 400 } } },
	{ Id = "Eggs5", Text = "Abre 5 huevos", Stat = "EggsOpened", Target = 5, Rewards = { { Type = "Money", Amount = 3000 }, { Type = "BPXP", Amount = 200 } } },
	{ Id = "Eggs50", Text = "Abre 50 huevos", Stat = "EggsOpened", Target = 50, Rewards = { { Type = "Pet", Pet = "Slime_Pearl_1" }, { Type = "BPXP", Amount = 500 } } },
	{ Id = "RocketClouds", Text = "Llega a las Nubes con tu cohete", Stat = "RocketBest", Target = 150, Rewards = { { Type = "Money", Amount = 2000 }, { Type = "BPXP", Amount = 150 } } },
	{ Id = "RocketSpace", Text = "Llega al Espacio", Stat = "RocketBest", Target = 1500, Rewards = { { Type = "Pet", Pet = "Slime_Sky_1" }, { Type = "BPXP", Amount = 400 } } },
	{ Id = "RocketGems10", Text = "Recoge 10 gemas en el aire", Stat = "RocketGems", Target = 10, Rewards = { { Type = "Money", Amount = 15000 }, { Type = "BPXP", Amount = 300 } } },
	{ Id = "Troll5", Text = "Lanza 5 trolleos", Stat = "RocketTrolls", Target = 5, Rewards = { { Type = "Money", Amount = 10000 }, { Type = "BPXP", Amount = 250 } } },
	{ Id = "Rocket10", Text = "Juega 10 rondas de cohete", Stat = "RocketRounds", Target = 10, Rewards = { { Type = "Money", Amount = 20000 }, { Type = "BPXP", Amount = 300 } } },
	{ Id = "Fuse1", Text = "Fusiona un slime", Stat = "PetsFused", Target = 1, Rewards = { { Type = "Money", Amount = 10000 }, { Type = "BPXP", Amount = 250 } } },
	{ Id = "Daily3", Text = "Reclama 3 recompensas diarias", Stat = "DailyClaims", Target = 3, Rewards = { { Type = "Money", Amount = 50000 }, { Type = "BPXP", Amount = 500 } } },
}

function GameConfig.GetMission(id: string)
	for _, mission in GameConfig.Missions do
		if mission.Id == id then
			return mission
		end
	end
	return nil
end

---------------------------------------------------------------- Battle Pass
GameConfig.BattlePass = {
	Season = 1,
	MaxLevel = 30,
	XPPerLevel = 100,
	PassiveXPPerSecond = 1, -- XP de pase por estar jugando (afinar después)
	SeasonEnds = DateTime.fromUniversalTime(2026, 12, 1).UnixTimestamp,
	Levels = {},
}

-- Premios "al azar" pero siempre los mismos para todos (semilla fija).
-- Después se pueden escribir a mano nivel por nivel.
do
	local rng = Random.new(2026)
	local freePets = { "Slime_Vanilla_1", "Bee_HoneyBee", "Slime_Blueberry_1" }
	local premiumPets = { "Bee_AngryBee", "Slime_Cherry_1", "Bee_NinjaBee" }
	for level = 1, GameConfig.BattlePass.MaxLevel do
		local free, premium
		if level % 10 == 0 then
			free = { Type = "Pet", Pet = freePets[level // 10] }
			premium = { Type = "Pet", Pet = if level == 30 then "Bee_TornadoBee" else premiumPets[level // 10] }
		elseif level % 5 == 0 then
			free = { Type = "Pet", Pet = freePets[rng:NextInteger(1, #freePets)] }
			premium = { Type = "Pet", Pet = premiumPets[rng:NextInteger(1, #premiumPets)] }
		else
			free = if rng:NextNumber() < 0.6
				then { Type = "Money", Amount = 500 * level }
				else { Type = "XP", Amount = 50 * level }
			premium = if rng:NextNumber() < 0.6
				then { Type = "Money", Amount = 2500 * level }
				else { Type = "XP", Amount = 200 * level }
		end
		GameConfig.BattlePass.Levels[level] = { Free = free, Premium = premium }
	end
end

---------------------------------------------------------------- Sonidos (Creator Store, gratis)
GameConfig.Sounds = {
	Click = "rbxassetid://102702078778790",
	Coin = "rbxassetid://93529351909119",
	Claim = "rbxassetid://71491555548135",
	Upgrade = "rbxassetid://135996502799215",
	Open = "rbxassetid://9120733724",
	Music = "rbxassetid://1847246688",
	-- Cohete
	RocketLaunch = "rbxassetid://2706228430",
	RocketEngine = "rbxassetid://12222065", -- en loop durante el vuelo
	Explosion = "rbxassetid://78012301000651",
	Beep = "rbxassetid://117751546358455",
}

-- Formato corto de números: 1234 -> 1.23K, 5e15 -> 5Qd
local SUFFIXES = { "", "K", "M", "B", "T", "Qd", "Qn", "Sx", "Sp", "Oc", "No", "Dc" }
function GameConfig.FormatNumber(n: number): string
	if n < 1000 then
		return tostring(math.floor(n))
	end
	local index = 1
	while n >= 1000 and index < #SUFFIXES do
		n /= 1000
		index += 1
	end
	local text = if n >= 100 then string.format("%d", n) else string.format("%.2f", n):gsub("%.?0+$", "")
	return text .. SUFFIXES[index]
end

-- Dinero con comas: 572831 -> 572,831 (para el contador grande)
function GameConfig.FormatCommas(n: number): string
	if n >= 1e12 then
		return GameConfig.FormatNumber(n)
	end
	local s = tostring(math.floor(n))
	local formatted = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (formatted:gsub("^,", ""))
end

return GameConfig
