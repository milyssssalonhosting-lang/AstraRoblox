-- ServerScriptService/RocketService (Script)
-- "Slime al Espacio": rondas automáticas en el Mundo Cohete.
--   Esperando → Preparación (cuenta regresiva) → Vuelo → Resultados → otra vez.
-- Todo el que esté en el Mundo Cohete juega solo (modo automático). El servidor
-- calcula la altura de cada cohete (Motor, Combustible, mascotas, gemas, trolleos);
-- el cliente solo la dibuja. Al final se paga según la altura.
--
-- "Corredores" = jugadores + cohetes bot (llenan la carrera si hay pocos jugadores).
--
-- Estado público (lo leen los clientes):
--   ReplicatedStorage.RocketState: atributos Phase, PhaseEndsAt, Round, Leaderboard (JSON), NukeUsed
--   ReplicatedStorage.RocketState.Bots: un Configuration por bot (DisplayName, Pilot, RocketPad, Altitude, RocketFuel…)
--   Player (y cada bot): RocketPad, Altitude (m), RocketFuel, RocketBoostUntil, RocketSlowUntil,
--                        RocketStunUntil, RocketDouble, LastRocketReward (solo jugadores)
--   Remotes: RocketPickups, RocketCollected, RocketTroll (pedir trolleo), RocketTrollEvent (efectos),
--            RocketClick (cada clic/TAP), RocketToggleAutoClick
--   Para subir hay que spamear clics: la potencia (RocketPower) depende de los clics por segundo.
--   Rondas variadas: RocketState.StartVariant / StartAltitude (a veces se despega desde las nubes, el espacio…)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local CollectionService = game:GetService("CollectionService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local PlayerStats = require(script.Parent.Modules.PlayerStats)
local Rocket = GameConfig.Rocket
local Pickups = Rocket.Pickups
local Trolls = Rocket.Trolls

local remotes = ReplicatedStorage.Remotes
local toggleAuto: RemoteEvent = remotes.RocketToggleAuto
local pickupsRemote: RemoteEvent = remotes.RocketPickups
local collectedRemote: RemoteEvent = remotes.RocketCollected
local trollRequest: RemoteFunction = remotes.RocketTroll
local trollEvent: RemoteEvent = remotes.RocketTrollEvent
local function getRemote(name: string): RemoteEvent
	local remote = remotes:FindFirstChild(name)
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = remotes
	end
	return remote
end
local clickRemote = getRemote("RocketClick")
local toggleAutoClick = getRemote("RocketToggleAutoClick")
local Click = Rocket.Click

local state = ReplicatedStorage:FindFirstChild("RocketState") or Instance.new("Folder")
state.Name = "RocketState"
state.Parent = ReplicatedStorage
local botsFolder = state:FindFirstChild("Bots") or Instance.new("Folder")
botsFolder.Name = "Bots"
botsFolder.Parent = state

local WORLD_MIN_Z = 2000 -- todo lo que está más allá de z=2000 es el Mundo Cohete
local rng = Random.new()

---------------------------------------------------------------- Utilidades
local function getRoot(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function inRocketWorld(player: Player): boolean
	local root = getRoot(player)
	return root ~= nil and root.Position.Z > WORLD_MIN_Z and player:GetAttribute("StatsReady") == true
end

local function setPhase(phase: string, seconds: number)
	state:SetAttribute("Phase", phase)
	state:SetAttribute("PhaseEndsAt", workspace:GetServerTimeNow() + seconds)
end

local function getPads(): { BasePart }
	local pads = CollectionService:GetTagged("LaunchPad")
	table.sort(pads, function(a, b)
		return (a:GetAttribute("Index") or 0) < (b:GetAttribute("Index") or 0)
	end)
	return pads
end

-- Fijar / soltar al personaje sobre su plataforma (dentro del cohete)
local function holdOnPad(player: Player, pad: BasePart?)
	local root = getRoot(player)
	if not root then
		return
	end
	root.Anchored = false
	if pad then
		root.CFrame = CFrame.new(pad.Position + Vector3.new(0, 4, 0))
		root.Anchored = true
	end
end

-- Convierte "segundos de vuelo" a hora del servidor (para que el cliente cuente)
local flightElapsed = 0
local function serverTimeAt(elapsed: number): number
	return workspace:GetServerTimeNow() + (elapsed - flightElapsed)
end

---------------------------------------------------------------- Modo automático
local lastToggle: { [Player]: number } = {}
toggleAuto.OnServerEvent:Connect(function(player: Player)
	local now = os.clock()
	if lastToggle[player] and now - lastToggle[player] < 0.5 then
		return
	end
	lastToggle[player] = now
	player:SetAttribute("RocketAuto", player:GetAttribute("RocketAuto") == false)
end)

-- Auto-clic: por ahora gratis (Click.AutoClickFree); en la Fase 4 se compra barato
toggleAutoClick.OnServerEvent:Connect(function(player: Player)
	local now = os.clock()
	if lastToggle[player] and now - lastToggle[player] < 0.5 then
		return
	end
	lastToggle[player] = now
	if not Click.AutoClickFree and not player:GetAttribute("OwnsAutoClick") then
		return
	end
	player:SetAttribute("RocketAutoClick", not player:GetAttribute("RocketAutoClick"))
end)

---------------------------------------------------------------- Corredores
type Racer = {
	Key: string, -- nombre del cohete en el cliente ("Rocket_" .. Key)
	Name: string,
	Player: Player?,
	Holder: Instance, -- donde viven sus atributos (el Player o el Configuration del bot)
	Altitude: number,
	Fuel: number,
	Engine: number,
	PetBonus: number,
	BoostUntil: number,
	BoostMultiplier: number,
	SlowUntil: number,
	SlowMultiplier: number,
	StunUntil: number,
	ProtectedUntil: number,
	Double: boolean,
	Pickups: { any }?,
	NextPickup: number,
	TrollReadyAt: { [string]: number },
	LiveMoney: number?,
	Climbed: boolean?,
	Clicks: { number }, -- momentos (os.clock) de los últimos clics
	BotPower: number?,
	Power: number,
}

local racers: { Racer } = {}
local racerOf: { [Player]: Racer } = {}

local function resetHolder(holder: Instance)
	holder:SetAttribute("RocketPad", 0)
	holder:SetAttribute("Altitude", 0)
	holder:SetAttribute("RocketFuel", 0)
	holder:SetAttribute("RocketBoostUntil", 0)
	holder:SetAttribute("RocketSlowUntil", 0)
	holder:SetAttribute("RocketStunUntil", 0)
	holder:SetAttribute("RocketDouble", false)
end

local function newRacer(key: string, name: string, holder: Instance, player: Player?, engine: number, petBonus: number, fuel: number): Racer
	return {
		Key = key,
		Name = name,
		Player = player,
		Holder = holder,
		Altitude = 0,
		Fuel = fuel,
		Engine = engine,
		PetBonus = petBonus,
		BoostUntil = 0,
		BoostMultiplier = 1,
		SlowUntil = 0,
		SlowMultiplier = 1,
		StunUntil = 0,
		ProtectedUntil = 0,
		Double = false,
		Pickups = nil,
		NextPickup = 1,
		TrollReadyAt = {},
		Clicks = {},
		Power = Click.MinPower,
	}
end

local function setBoost(racer: Racer, multiplier: number, seconds: number)
	racer.BoostMultiplier = math.max(if racer.BoostUntil > flightElapsed then racer.BoostMultiplier else 1, multiplier)
	racer.BoostUntil = math.max(racer.BoostUntil, flightElapsed) + seconds
	racer.Holder:SetAttribute("RocketBoostUntil", serverTimeAt(racer.BoostUntil))
end

local function setSlow(racer: Racer, multiplier: number, seconds: number)
	racer.SlowMultiplier = multiplier
	racer.SlowUntil = flightElapsed + seconds
	racer.Holder:SetAttribute("RocketSlowUntil", serverTimeAt(racer.SlowUntil))
end

local function setStun(racer: Racer, seconds: number)
	racer.StunUntil = math.max(racer.StunUntil, flightElapsed + seconds)
	racer.Holder:SetAttribute("RocketStunUntil", serverTimeAt(racer.StunUntil))
end

---------------------------------------------------------------- Objetos en el aire (solo jugadores)
local function rollGem(): string
	local total = 0
	for _, gem in Pickups.Gems do
		total += gem.Weight
	end
	local pick = rng:NextNumber() * total
	for kind, gem in Pickups.Gems do
		pick -= gem.Weight
		if pick <= 0 then
			return kind
		end
	end
	return "Turbo"
end

local function generatePickups(racer: Racer, start: number)
	local reach = start + racer.Engine * racer.PetBonus * Click.MaxPower * (racer.Fuel + 12) * 1.6
	local list = {}
	local id = 0
	local altitude = start + rng:NextNumber(Pickups.CoinSpacing[1], Pickups.CoinSpacing[2])
	while altitude < reach do
		id += 1
		table.insert(list, { Id = id, Altitude = math.floor(altitude), Kind = "Coin" })
		altitude += rng:NextNumber(Pickups.CoinSpacing[1], Pickups.CoinSpacing[2])
	end
	altitude = start + rng:NextNumber(Pickups.GemSpacing[1] * 0.5, Pickups.GemSpacing[2] * 0.5)
	while altitude < reach do
		id += 1
		table.insert(list, { Id = id, Altitude = math.floor(altitude), Kind = rollGem() })
		altitude += rng:NextNumber(Pickups.GemSpacing[1], Pickups.GemSpacing[2])
	end
	table.sort(list, function(a, b)
		return a.Altitude < b.Altitude
	end)
	racer.Pickups = list
	racer.NextPickup = 1
end

-- Multiplicador de dinero en el cohete: rebirth × (1 + amigos + mascotas 💰)
local function moneyMultiplier(player: Player): number
	local rebirth = GameConfig.RebirthMultiplier(player:GetAttribute("Rebirths") or 0)
	return rebirth * (1 + (player:GetAttribute("FriendBoost") or 0) + (player:GetAttribute("PetBoost") or 0))
end

-- XP con el bono ⭐ de las mascotas
local function petXP(player: Player, amount: number): number
	return math.floor(amount * (1 + (player:GetAttribute("PetXP") or 0)) + 0.5)
end

local function coinValue(player: Player, altitude: number): number
	return math.floor((Pickups.CoinBase + altitude * Pickups.CoinPerMeter) * moneyMultiplier(player))
end

local function applyPickup(racer: Racer, item)
	local player = racer.Player :: Player
	local value = 0
	if item.Kind == "Coin" then
		value = coinValue(player, item.Altitude)
		PlayerStats.AddMoney(player, value, true)
	else
		local gem = Pickups.Gems[item.Kind]
		if gem.SpeedMultiplier then
			setBoost(racer, gem.SpeedMultiplier, gem.Seconds)
		end
		if gem.ExtraFuel then
			racer.Fuel += gem.ExtraFuel
		end
		if item.Kind == "Double" then
			racer.Double = true
			racer.Holder:SetAttribute("RocketDouble", true)
		end
		if gem.CoinBurst then
			value = coinValue(player, item.Altitude) * gem.CoinBurst
			PlayerStats.AddMoney(player, value, true)
		end
		PlayerStats.AddStat(player, "RocketGems", 1)
	end
	collectedRemote:FireAllClients(player.UserId, item.Id, item.Kind, value)
end

local function collectPassed(racer: Racer)
	local list = racer.Pickups
	if not (list and racer.Player) then
		return
	end
	local index = racer.NextPickup
	while list[index] and list[index].Altitude <= racer.Altitude do
		applyPickup(racer, list[index])
		index += 1
	end
	racer.NextPickup = index
end

---------------------------------------------------------------- Clics (spamear para subir)
clickRemote.OnServerEvent:Connect(function(player: Player)
	local racer = racerOf[player]
	if not racer or state:GetAttribute("Phase") ~= "Flight" then
		return
	end
	local now = os.clock()
	local clicks = racer.Clicks
	-- quitar los de hace más de 1 s
	while clicks[1] and now - clicks[1] > 1 do
		table.remove(clicks, 1)
	end
	if #clicks < Click.MaxCPS then
		table.insert(clicks, now)
	end
end)

-- Potencia actual: bots fija; auto-clic fija; a mano según clics por segundo
local function powerOf(racer: Racer): number
	if racer.BotPower then
		return racer.BotPower
	end
	local player = racer.Player :: Player
	local now = os.clock()
	local cps = 0
	for _, t in racer.Clicks do
		if now - t <= 1 then
			cps += 1
		end
	end
	local manual = Click.MinPower + (Click.MaxPower - Click.MinPower) * math.min(1, cps / Click.TargetCPS)
	if player:GetAttribute("RocketAutoClick") then
		return math.max(manual, Click.AutoPower)
	end
	return manual
end

---------------------------------------------------------------- Trolleos
local function racerAbove(me: Racer): (Racer?, boolean)
	-- El más cercano que va arriba de mí; si está protegido, el siguiente
	local candidates = {}
	for _, other in racers do
		if other ~= me and other.Altitude > me.Altitude then
			table.insert(candidates, other)
		end
	end
	table.sort(candidates, function(a, b)
		return a.Altitude < b.Altitude
	end)
	for _, other in candidates do
		if other.ProtectedUntil <= flightElapsed then
			return other, true
		end
	end
	return nil, #candidates > 0
end

trollRequest.OnServerInvoke = function(player: Player, trollId: unknown)
	if typeof(trollId) ~= "string" then
		return false, "Trolleo inválido"
	end
	local troll = GameConfig.GetTroll(trollId)
	local me = racerOf[player]
	if not troll then
		return false, "Trolleo inválido"
	end
	if state:GetAttribute("Phase") ~= "Flight" or not me then
		return false, "Solo durante el vuelo"
	end
	if (me.TrollReadyAt[troll.Id] or 0) > flightElapsed then
		return false, "Espera " .. math.ceil(me.TrollReadyAt[troll.Id] - flightElapsed) .. "s"
	end
	if troll.OncePerRound and state:GetAttribute("NukeUsed") then
		return false, "Ya cayó una nuclear esta ronda"
	end

	-- Elegir objetivo(s) ANTES de cobrar
	local targets: { Racer } = {}
	if troll.Id == "Nuke" then
		for _, other in racers do
			if other ~= me then
				table.insert(targets, other)
			end
		end
	else
		local target, anyAbove = racerAbove(me)
		if not target then
			return false, if anyAbove then "Están protegidos, espera un momento" else "¡Vas en primer lugar!"
		end
		targets = { target }
	end
	if #targets == 0 then
		return false, "No hay a quién trollear"
	end
	if not PlayerStats.TrySpend(player, troll.Price) then
		return false, "Necesitas $" .. GameConfig.FormatNumber(troll.Price)
	end
	me.TrollReadyAt[troll.Id] = flightElapsed + troll.Cooldown

	-- Aplicar
	if troll.Id == "Meteor" then
		local t = targets[1]
		t.Altitude = math.floor(t.Altitude * (1 - troll.AltitudeLoss))
		setStun(t, troll.StunSeconds)
	elseif troll.Id == "Steal" then
		setBoost(me, troll.BoostMultiplier, troll.BoostSeconds)
		setSlow(targets[1], troll.SlowMultiplier, troll.SlowSeconds)
	elseif troll.Id == "Nuke" then
		state:SetAttribute("NukeUsed", true)
		for _, t in targets do
			t.Altitude = 0
			setStun(t, troll.StunSeconds)
		end
	end
	local keys, names = {}, {}
	for _, t in targets do
		t.ProtectedUntil = flightElapsed + Trolls.ProtectSeconds
		t.Holder:SetAttribute("Altitude", math.floor(t.Altitude))
		table.insert(keys, t.Key)
		table.insert(names, t.Name)
	end
	PlayerStats.AddStat(player, "RocketTrolls", 1)
	trollEvent:FireAllClients({ Kind = troll.Id, From = me.Key, FromName = me.Name, Targets = keys, TargetNames = names })
	return true, troll.Icon .. " " .. troll.Name .. (if #names == 1 then " a " .. names[1] else "") .. "!"
end

---------------------------------------------------------------- Fases
local function clearRound()
	for _, racer in racers do
		if racer.Player then
			if racer.Player.Parent then
				holdOnPad(racer.Player, nil)
				resetHolder(racer.Player)
			end
		end
	end
	botsFolder:ClearAllChildren()
	racers = {}
	racerOf = {}
end

local function prepare(): boolean
	clearRound()
	local pads = getPads()
	local players = {}
	for _, player in Players:GetPlayers() do
		if inRocketWorld(player) and player:GetAttribute("RocketAuto") ~= false and #players < #pads then
			table.insert(players, player)
		end
	end
	if #players == 0 then
		return false
	end
	state:SetAttribute("Round", (state:GetAttribute("Round") or 0) + 1)
	state:SetAttribute("Leaderboard", "[]")
	state:SetAttribute("NukeUsed", false)

	-- Ronda variada: ¿desde dónde despegan hoy?
	local totalWeight = 0
	for _, v in Rocket.StartVariants do
		totalWeight += v.Weight
	end
	local pick = rng:NextNumber() * totalWeight
	local variant = Rocket.StartVariants[1]
	for _, v in Rocket.StartVariants do
		pick -= v.Weight
		if pick <= 0 then
			variant = v
			break
		end
	end
	local start = variant.Altitude
	state:SetAttribute("StartVariant", variant.Id)
	state:SetAttribute("StartAltitude", start)

	local allPickups = {}
	local speedSum, fuelSum = 0, 0
	for i, player in players do
		local engine = PlayerStats.GetUpgradeValue(player, "RocketEngine")
		local petBonus = 1 + (player:GetAttribute("PetRocket") or 0) -- 🚀 de las mascotas
		local fuel = PlayerStats.GetUpgradeValue(player, "RocketFuel")
		local racer = newRacer(player.Name, player.DisplayName, player, player, engine, petBonus, fuel)
		resetHolder(player)
		player:SetAttribute("RocketPad", pads[i]:GetAttribute("Index"))
		player:SetAttribute("RocketFuel", fuel)
		holdOnPad(player, pads[i])
		racer.Altitude = start
		player:SetAttribute("Altitude", start)
		player:SetAttribute("RocketPower", Click.MinPower)
		generatePickups(racer, start)
		allPickups[tostring(player.UserId)] = racer.Pickups
		table.insert(racers, racer)
		racerOf[player] = racer
		speedSum += engine * petBonus
		fuelSum += fuel
	end

	-- Bots para que siempre haya rivales
	local botCount = math.min(Rocket.Bots.MinRacers - #players, #pads - #players)
	local names = table.clone(Rocket.Bots.Names)
	for b = 1, math.max(0, botCount) do
		local name = table.remove(names, rng:NextInteger(1, #names)) .. " 🤖"
		local bot = Instance.new("Configuration")
		bot.Name = "Bot" .. b
		bot:SetAttribute("IsBot", true)
		bot:SetAttribute("DisplayName", name)
		bot:SetAttribute("Pilot", "Slime_" .. GameConfig.SlimeFlavors[rng:NextInteger(1, #GameConfig.SlimeFlavors)] .. "_1")
		resetHolder(bot)
		local speed = speedSum / #players * rng:NextNumber(Rocket.Bots.SpeedRange[1], Rocket.Bots.SpeedRange[2])
		local fuel = fuelSum / #players * rng:NextNumber(0.8, 1.2)
		bot:SetAttribute("RocketPad", pads[#players + b]:GetAttribute("Index"))
		bot:SetAttribute("RocketFuel", fuel)
		bot.Parent = botsFolder
		local botRacer = newRacer(bot.Name, name, bot, nil, speed, 1, fuel)
		botRacer.Altitude = start
		botRacer.BotPower = rng:NextNumber(0.75, 1.1)
		bot:SetAttribute("Altitude", start)
		table.insert(racers, botRacer)
	end

	pickupsRemote:FireAllClients(allPickups)
	setPhase("Prepare", Rocket.PrepareSeconds)
	task.wait(Rocket.PrepareSeconds)
	return true
end

local function updateLeaderboard()
	local list = {}
	for _, racer in racers do
		if not racer.Player or racer.Player.Parent then
			table.insert(list, { Name = racer.Name, Key = racer.Key, Altitude = math.floor(racer.Altitude) })
		end
	end
	table.sort(list, function(a, b)
		return a.Altitude > b.Altitude
	end)
	local top = {}
	for i = 1, math.min(5, #list) do
		top[i] = list[i]
	end
	state:SetAttribute("Leaderboard", HttpService:JSONEncode(top))
end

local function flight()
	setPhase("Flight", Rocket.FlightSeconds)
	flightElapsed = 0
	while flightElapsed < Rocket.FlightSeconds do
		task.wait(Rocket.TickSeconds)
		flightElapsed += Rocket.TickSeconds
		for _, racer in racers do
			if racer.Player and not racer.Player.Parent then
				continue
			end
			if racer.Fuel > 0 and racer.StunUntil <= flightElapsed then
				-- Empieza lento y acelera en los primeros segundos (se siente el despegue)
				local ramp = math.min(1, 0.25 + flightElapsed / 4)
				local boost = if racer.BoostUntil > flightElapsed then racer.BoostMultiplier else 1
				local slow = if racer.SlowUntil > flightElapsed then racer.SlowMultiplier else 1
				local power = powerOf(racer)
				if math.abs(power - racer.Power) > 0.02 then
					racer.Power = power
					racer.Holder:SetAttribute("RocketPower", power)
				end
				local climb = racer.Engine * racer.PetBonus * power * ramp * boost * slow * Rocket.TickSeconds
				racer.Altitude += climb
				racer.Fuel = math.max(0, racer.Fuel - Rocket.TickSeconds)
				collectPassed(racer)
				-- Ganancia en vivo (se junta y se paga cada segundo)
				if racer.Player then
					racer.LiveMoney = (racer.LiveMoney or 0) + climb * Rocket.LiveMoneyPerMeter * moneyMultiplier(racer.Player)
					racer.Climbed = true
				end
			end
			racer.Holder:SetAttribute("Altitude", math.floor(racer.Altitude))
			racer.Holder:SetAttribute("RocketFuel", racer.Fuel)
		end
		-- Cada segundo: pagar lo juntado en vivo y dar XP a quien subió
		if math.floor(flightElapsed) ~= math.floor(flightElapsed - Rocket.TickSeconds) then
			for _, racer in racers do
				local player = racer.Player
				if player and player.Parent then
					local pay = math.floor(racer.LiveMoney or 0)
					if pay > 0 then
						racer.LiveMoney -= pay
						PlayerStats.AddMoney(player, pay, true)
					end
					if racer.Climbed then
						PlayerStats.AddXP(player, petXP(player, Rocket.LiveXPPerSecond))
						racer.Climbed = false
					end
				end
			end
		end
		updateLeaderboard()
	end
end

local function results()
	setPhase("Results", Rocket.ResultsSeconds)
	updateLeaderboard()
	for _, racer in racers do
		local player = racer.Player
		if player and player.Parent then
			local altitude = math.floor(racer.Altitude)
			-- Mismos bonos que el ingreso pasivo (rebirth, mascotas, amigos), sin AFK
			local reward = math.floor(altitude * Rocket.MoneyPerMeter * moneyMultiplier(player))
			if racer.Double then
				reward *= 2
			end
			-- Cuánto de eso fue gracias a las mascotas (💰 y 🚀), para mostrarlo en resultados
			local petBoost = player:GetAttribute("PetBoost") or 0
			local friend = player:GetAttribute("FriendBoost") or 0
			local withoutPetMoney = reward * (1 + friend) / (1 + friend + petBoost)
			local withoutPetRocket = withoutPetMoney / racer.PetBonus
			player:SetAttribute("LastRocketPetBonus", math.max(0, math.floor(reward - withoutPetRocket)))
			PlayerStats.AddMoney(player, reward, true)
			PlayerStats.AddXP(player, petXP(player, Rocket.XPPerRound))
			PlayerStats.AddBattlePassXP(player, petXP(player, Rocket.BPXPPerRound))
			PlayerStats.AddStat(player, "RocketRounds", 1)
			if altitude > (player:GetAttribute("Stat_RocketBest") or 0) then
				player:SetAttribute("Stat_RocketBest", altitude)
			end
			player:SetAttribute("LastRocketReward", reward)
		end
	end
	task.wait(Rocket.ResultsSeconds)
	clearRound()
end

---------------------------------------------------------------- Bucle principal
Players.PlayerAdded:Connect(resetHolder)
for _, player in Players:GetPlayers() do
	resetHolder(player)
end
Players.PlayerRemoving:Connect(function(player)
	lastToggle[player] = nil
	racerOf[player] = nil
end)

task.spawn(function()
	setPhase("Waiting", 0)
	while true do
		local ok, err = pcall(function()
			if prepare() then
				flight()
				results()
			else
				setPhase("Waiting", 0)
				task.wait(1)
			end
		end)
		if not ok then
			warn("[RocketService] Error en la ronda: " .. tostring(err))
			pcall(clearRound)
			task.wait(2)
		end
	end
end)
