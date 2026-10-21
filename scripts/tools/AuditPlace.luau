-- Herramienta de auditoría (solo lectura). Se corre en un Studio APARTE con el
-- archivo descargado abierto. Lista qué trae el archivo y marca patrones
-- peligrosos en los scripts (posibles backdoors). No modifica nada.

local ROOTS = {
	game.Workspace, game.ReplicatedStorage, game.ReplicatedFirst, game.ServerScriptService,
	game.ServerStorage, game.StarterGui, game.StarterPack, game.Lighting, game.SoundService,
	game.StarterPlayer, game.Teams, game:GetService("Chat"),
}

local SUSPICIOUS = {
	{ "require%s*%(%s*%d+", "require(número): carga código externo" },
	{ "loadstring", "loadstring: ejecuta texto como código" },
	{ "getfenv", "getfenv: truco común de backdoors" },
	{ "setfenv", "setfenv: truco común de backdoors" },
	{ "HttpService", "HttpService: se comunica con internet" },
	{ "PostAsync", "PostAsync: envía datos a internet" },
	{ "InsertService", "InsertService: inserta modelos externos" },
	{ "TeleportService", "TeleportService: manda jugadores a otro lugar" },
	{ "MarketplaceService", "MarketplaceService: compras con Robux" },
	{ "string%.char", "string.char: puede ocultar texto" },
	{ "\\%d%d%d", "texto escapado: posible ofuscación" },
	{ "_G%.", "_G: variables globales compartidas" },
	{ ":Kick%(", "Kick: expulsa jugadores" },
	{ "BanAsync", "BanAsync: banea jugadores" },
	{ "SetCore", "SetCore" },
	{ "webhook", "webhook (Discord u otro)" },
}

local report = {}
local function add(line)
	table.insert(report, line)
end

-- Resumen por raíz
for _, root in ROOTS do
	local children = root:GetChildren()
	local names = {}
	for _, child in children do
		if not (root == game.Workspace and (child:IsA("Camera") or child:IsA("Terrain"))) then
			table.insert(names, child.Name .. "<" .. child.ClassName .. ">")
		end
	end
	if #names > 0 then
		local shown = {}
		for i = 1, math.min(#names, 25) do
			shown[i] = names[i]
		end
		add(root.Name .. " (" .. #names .. "): " .. table.concat(shown, ", ") .. (if #names > 25 then ", …" else ""))
	end
end

-- Conteo por clase
local counts = {}
for _, root in ROOTS do
	for _, d in root:GetDescendants() do
		counts[d.ClassName] = (counts[d.ClassName] or 0) + 1
	end
end
local interesting = { "Model", "MeshPart", "Part", "Animation", "KeyframeSequence", "Sound", "Tool", "ParticleEmitter", "Decal", "Texture", "Script", "LocalScript", "ModuleScript" }
local countLine = {}
for _, class in interesting do
	if counts[class] then
		table.insert(countLine, class .. "=" .. counts[class])
	end
end
add("CLASES: " .. table.concat(countLine, " "))

-- Scripts
add("SCRIPTS:")
for _, root in ROOTS do
	for _, s in root:GetDescendants() do
		if s:IsA("LuaSourceContainer") then
			local ok, src = pcall(function()
				return s.Source
			end)
			src = ok and src or ""
			local lines = select(2, src:gsub("\n", "\n")) + 1
			local longest = 0
			for line in src:gmatch("[^\n]+") do
				longest = math.max(longest, #line)
			end
			local flags = {}
			for _, rule in SUSPICIOUS do
				if src:find(rule[1]) then
					table.insert(flags, rule[2])
				end
			end
			if longest > 600 then
				table.insert(flags, "línea de " .. longest .. " caracteres: posible ofuscación")
			end
			local disabled = s:IsA("BaseScript") and s.Disabled
			add(string.format("  %s [%s%s] %d líneas%s", s:GetFullName(), s.ClassName, if disabled then ", desactivado" else "", lines, if #flags > 0 then "  ⚠ " .. table.concat(flags, "; ") else ""))
		end
	end
end

return table.concat(report, "\n")
