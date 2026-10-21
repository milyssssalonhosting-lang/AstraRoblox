# MiPrimerJuego — Roblox

## Contexto
- Proyecto de juego en Roblox Studio. El usuario está aprendiendo Roblox Studio (nivel principiante); trabajamos juntos: yo creo scripts, funciones, animaciones y construyo en Studio, y explico lo que hago en español, paso a paso y sin asumir conocimiento previo.
- Todavía no hay idea de juego definida. Antes de construir algo grande, proponer opciones y preguntar.

## Conexión con Roblox Studio (MCP)
- Servidor MCP `Roblox_Studio` registrado a nivel usuario en Claude Code (`cmd.exe /c cd /d %LOCALAPPDATA%\Roblox && .\mcp.bat`).
- Requiere Roblox Studio abierto con "Habilitar Studio como servidor MCP" encendido (Asistente → Configuración → Servidores).
- Si las herramientas MCP no aparecen o fallan: pedir al usuario que revise que Studio esté abierto con el lugar cargado y el interruptor activo; luego abrir sesión nueva.

## Archivos
- `Place1.rbxl`: el lugar (place) del juego. Se abre en Studio; los cambios se hacen dentro de Studio vía MCP, no editando este archivo.
- Recordar al usuario guardar en Studio (Control+S) después de cambios importantes.
- `scripts/`: copias de respaldo de scripts importantes (Luau, `.luau`), con la ruta en Studio anotada al inicio de cada archivo (ej. `-- ServerScriptService/GameManager`).
- `investigacion/`: prompt para NotebookLM y la guía resultante `GUIA_ROBLOX.md` (diseño, monetización, estilo visual, reglas de Roblox). Consultarla al proponer ideas o sistemas de monetización.
- `codex_assets/`: entregas de ChatGPT Codex (assets, diseños). Revisarlas/auditarlas antes de integrarlas.
- Repo GitHub: https://github.com/milyssssalonhosting-lang/AstraRoblox (rama `main`).
- `NOTAS.md`: decisiones del juego, ideas y progreso. Actualizarlo al terminar algo importante.

## Convenciones Roblox
- Lenguaje: Luau. Lógica del servidor en `ServerScriptService`, del cliente en `StarterPlayerScripts`/`StarterGui`, módulos compartidos en `ReplicatedStorage`.
- Nunca confiar en el cliente: validar en el servidor todo lo que venga por RemoteEvents.
- Nombres claros en inglés para instancias y variables; comentarios y explicaciones en español.
- Futuro opcional: Rojo para sincronizar scripts con esta carpeta y usar git.
