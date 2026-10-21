# Prompts para NotebookLM — Investigación "Cómo crear juegos exitosos en Roblox"

Uso en 2 partes:
1. **Parte A**: buscar fuentes. En NotebookLM → "Agregar fuentes" → "Descubrir / Deep Research". Pega UNA búsqueda a la vez y agrega las fuentes que encuentre. Repite con cada búsqueda (entre más fuentes, mejor; ideal 40-80).
2. **Parte B**: cuando ya tengas las fuentes, pega el prompt maestro en el chat (o en "Informe → Personalizar"). Copia la respuesta a un archivo `GUIA_ROBLOX.md` dentro de esta carpeta `investigacion/`.

---

## Parte A — Búsquedas (una por una)

1. Roblox game design best practices 2026: what makes a Roblox game go viral, retention, first 5 minutes, game loops
2. Most popular Roblox games 2025-2026 analysis: Grow a Garden, Steal a Brainrot, Dead Rails, 99 Nights in the Forest, Blox Fruits, Brookhaven, Adopt Me — why they succeeded
3. Roblox monetization guide: Game Passes, Developer Products, Premium Payouts, subscriptions, battle pass, limited-time offers, pricing in Robux
4. Roblox "troll" / social paid features: paid actions that affect other players (nukes, bombs, admin commands, trolling products), examples and design in obbies, races and tycoons
5. Roblox Developer Exchange (DevEx) and how much developers earn; Roblox Creator Hub monetization documentation
6. Roblox policies for monetization: paid random items rules, age guidelines / content maturity labels, rules about children and spending, advertising standards
7. What kids and teens like in Roblox games: psychology, rewards, progression, collecting, pets, social play, trends, memes (Brainrot)
8. Roblox game art style: low poly, cartoon, color palettes, UI design for kids, mobile-first UI, thumbnails and icons that get clicks
9. Roblox game discovery and algorithm: Home recommendations, sorts, thumbnails, playtime, retention, CCU, sponsored ads, updates and events
10. Using AI to make Roblox games: Claude, Roblox Studio MCP server, Roblox Assistant, prompting AI for Luau scripts, AI game development workflow
11. Roblox Studio for beginners: Luau scripting basics, ServerScriptService vs LocalScript, RemoteEvents, DataStores, common mistakes
12. Roblox game genres explained: simulator, tycoon, obby, tower defense, horror, roleplay, "Steal a" games, idle/incremental — difficulty to build and earning potential for a solo beginner developer

---

## Parte B — Prompt maestro (pegar en el chat cuando ya estén las fuentes)

```
Actúa como un diseñador de videojuegos experto en Roblox y consultor de monetización. Usa SOLO las fuentes de este cuaderno y cita las fuentes en cada sección. Si algo no aparece en las fuentes, dilo en lugar de inventarlo.

Contexto: soy un desarrollador principiante, trabajo solo junto con una IA (Claude, conectada a Roblox Studio por MCP). Quiero crear un juego de Roblox que atraiga a muchos jugadores (sobre todo niños y adolescentes), que los retenga y que genere Robux de forma legal y dentro de las reglas de Roblox.

Escribe una guía completa en formato Markdown (títulos con #, listas, tablas), en español, con estas secciones:

1. Resumen ejecutivo: las 10 reglas más importantes para hacer un juego exitoso en Roblox hoy.
2. Qué atrae a los jugadores: qué les gusta a niños y adolescentes en Roblox (recompensas, coleccionables, mascotas, juego social, tendencias y memes), y por qué.
3. Análisis de juegos exitosos: tabla con juego, género, mecánica principal, por qué funcionó, cómo monetiza.
4. Géneros recomendados para un principiante solo: tabla con dificultad, tiempo estimado, potencial de ganancias y riesgos.
5. Ciclo de juego y retención: core loop, progresión, los primeros 5 minutos, recompensas diarias, eventos y actualizaciones.
6. Monetización: Game Passes vs Developer Products vs Premium Payouts vs suscripciones; Battle Pass; ofertas por tiempo limitado; rangos de precio en Robux que funcionan; qué vende más.
7. Funciones sociales de pago ("trolleo" amistoso): compras que afectan a otros jugadores (ej. una bomba que regresa a todos al inicio en una carrera, comandos de admin, efectos sobre amigos). Ejemplos reales, cómo diseñarlas para que sean divertidas y no frustrantes, y cómo balancearlas.
8. Reglas y políticas de Roblox que debo cumplir: artículos aleatorios pagados, etiquetas de madurez/edad, publicidad, protección de menores, qué está prohibido. Lista de errores que pueden hacer que te baneen o te quiten el juego.
9. Estilo visual: estilos gráficos que funcionan (low poly, caricatura, etc.), paletas de colores recomendadas (con códigos HEX), diseño de UI para niños y celular, cómo hacer íconos y miniaturas que generen clics.
10. Descubrimiento y algoritmo: cómo Roblox recomienda juegos, métricas clave (retención D1/D7, tiempo de juego, CCU), anuncios patrocinados y estrategia de lanzamiento.
11. Desarrollar con IA (Claude + Roblox Studio MCP): flujo de trabajo recomendado, cómo pedirle cosas a la IA (ejemplos de buenos prompts para scripts, mapas, UI y sistemas), límites y errores comunes.
12. Bases técnicas mínimas: Luau, scripts de servidor vs cliente, RemoteEvents, DataStores (guardar progreso), seguridad contra exploits.
13. Plan por fases: un plan paso a paso desde la idea hasta publicar y actualizar (fase 1: prototipo, fase 2: monetización, fase 3: lanzamiento, fase 4: actualizaciones), con qué hacer en cada fase.
14. Checklist final: lista para revisar antes de publicar.
15. Glosario de términos de Roblox para principiantes.

Sé concreto y práctico: da ejemplos, números y precios cuando las fuentes los tengan.
```

---

## Cómo me lo pasas después
Guarda la respuesta como `investigacion/GUIA_ROBLOX.md`. En la conversación de Claude escribe: "Lee investigacion/GUIA_ROBLOX.md y propón 3 ideas de juego".
