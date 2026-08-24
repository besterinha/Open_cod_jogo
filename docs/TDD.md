# TDD — Open_cod_jogo | Technical Design Document

**Versão:** 0.1.0 | **Data:** 22/08/2026 | **Godot:** 4.7.2-stable Standard | **Linguagem:** GDScript | **Licença:** MIT (100% gratuito)

---

## 1. Overview
Construir TRPG tático 2.5D + Caravana modular plugável **genérico** onde conteúdo (habilidades/eventos/**stats**) é dado, não código. Dois layers: `Caravan` e `Tactical`. Stats 100% data-driven (`data/stats/`), resolvers plugáveis. Banner Saga é **exemplo inspiração, não contrato**. Crítico: `content -> systems -> addons` unidirecional, validável por IA.

## 2. Arquitetura — 4 Pilares (Epictellers/GDQuest)
Ver `AGENTS.md`. Diagrama de dependência:
```
addons (grid_toolkit, gut) <- systems (caravan, tactical, ability) <- content (data/*.tres, maps)
                                      ^                                |
                                      +----------- ui -------------------+
gyms (isolado, .gitignore no build)
```
CI bloqueia: `grep -r "gyms/" --include="*.gd" addons/ systems/ ui/` deve falhar.

### Stats Genéricos (Opção B — 100% data-driven)
Você define atributos em `data/stats/attributes.tres` (`AttributeDefinition[]`). `UnitStats` guarda `Dictionary[stat_id -> value]` validado. `ICombatResolver` lê stats genéricos, sem hardcode `armor/strength`. Exemplos de resolvers em `systems/tactical/combat/resolvers/examples/` provam genericidade.

### Pastas
```
/
├── addons/grid_toolkit/      # Grid Utility + Pathfinding (MIT)
├── addons/gut/               # GUT 9.7.1 (MIT, branch godot_4_7)
├── systems/
│   ├── caravan/              # CaravanManager, TravelSystem, EventSystem, CampSystem, MarketSystem
│   ├── tactical/             # GridSystem, TurnManager, CombatResolver, Movement
│   ├── ability/              # AbilitySystem, AbilityResource, IAbilityLogic, effects/
│   └── common/               # EventBus (signals), Registry, SaveSystem, DataValidator, SaveCompat
├── ui/                       # caravan_bar, tactical_hud, event_popup (só LEEM de systems)
├── content/                  # vazio, usa systems (exemplo em data/)
├── data/                     # PLUGÁVEL — onde IA atua (100% genérico)
│   ├── stats/                # AttributeDefinition[] (você define hp/armor/shield/mana...)
│   ├── abilities/*.tres      # custo {stat_id: val} genérico
│   ├── events/*.tres
│   └── classes/*.tres        # classes referenciam stats via id
├── placeholders/             # capsule, cube, vfx_circle
├── tests/                    # GUT unit/smoke/regression
├── docs/
└── gyms/                     # sandbox dev, excluído do build
```

## 3. Stack Detalhado
- **Godot:** 4.7.2-stable Standard (sem .NET). Renderer: Mobile. Window: viewport 1280x720, stretch canvas_items, ETC2.
- **Android Build:** OpenJDK 17, SDK Platform-Tools 35.0.0+, Build-Tools 35.0.1, Platform 35, CMD-line Tools latest, NDK r28b, CMake 3.10.2.4988404, `android/build` via `Project -> Install Android Build Template` + GABE.
- **Testes:** GUT 9.7.1 godot_4_7 + godot-validation-flow (Odin) + DataValidator custom.
- **MCPs:** Coding-Solo/godot-mcp, godot-docs, context7 (opencode.json).

## 4. Sistemas Core & Interfaces Plugáveis

### 4.1 Caravan
```gdscript
class_name ICaravanResourceSystem
func consume_day(pop: int, supplies: int, morale: int) -> Dictionary # {supplies, morale, losses}
func rest_day(supplies: int, morale: int) -> Dictionary

class_name ITravelSystem
func travel(days: int) -> void # emite EventBus.day_passed

class_name IEventSystem
func roll_event(biome: String) -> EventResource # peso + trigger

class_name ICampSystem
func can_rest() -> bool

class_name IMarketSystem
func exchange_rate() -> int # X em 1:X
```

### 4.2 Tactical
```gdscript
class_name IGridSystem
func world_to_cell(world: Vector3) -> Vector2i
func cell_to_world(cell: Vector2i) -> Vector3
func get_reachable(origin: Vector2i, range: int, walkable: Callable) -> Array[Vector2i]

class_name ITurnSystem
func next_turn(units: Array) -> Unit
func order(units: Array) -> Array

class_name ICombatResolver
func resolve(attacker: Unit, defender: Unit, ability: AbilityResource) -> CombatResult

class_name IAbilityLogic extends Resource # Strategy
func can_activate(user: Unit, target_cell: Vector2i, ability: AbilityResource) -> bool
func activate(user: Unit, target_cells: Array[Vector2i], ability: AbilityResource) -> void

class_name IAIBehavior
func generate_intent(unit: Unit, board: Board) -> Intent
```

### 4.3 AbilityResource (Genérico — custo por stat_id)
```gdscript
class_name AbilityResource extends Resource
@export var id: String
@export var nome: String
@export var custo: Dictionary = {} # {stat_id: valor} ex: {"willpower":1} ou {"mana":3,"stamina":1} — validado contra data/stats/
@export var alcance: int = 1
@export var area: String = "single" # single, 3x3, cross, line
@export var efeitos: Array[Resource] # Array[StatEffect] genérico: {stat_id, delta, element}
@export var tags_required: PackedStringArray
@export var vfx: PackedScene
@export var logic_script: GDScript # Strategy plugável (ICombatResolver lê stats genéricos)
```

### 4.3b Stats Genéricos
```gdscript
class_name AttributeDefinition extends Resource
@export var id: String # "hp", "armor", "mana", "shield"...
@export var nome: String
@export var default_value: int = 10
@export var min_value: int = 0
@export var max_value: int = 999
@export var is_resource: bool = false # se true, é custo (willpower/mana) vs stat base

class_name UnitStats extends Resource
@export var values: Dictionary = {} # {stat_id: int} validado contra AttributeDefinition[]

class_name StatsRegistry # autoload ou singleton em systems/stats/
func get_definition(id: String) -> AttributeDefinition
func is_valid_stat(id: String) -> bool
func clamp_value(id: String, v: int) -> int
```

### 4.4 EventResource
```gdscript
class_name EventResource extends Resource
@export var id: String
@export var weight: int = 10
@export var trigger: String = "random" # random, city, camp
@export var titulo: String
@export var texto: String
@export var escolhas: Array[EventChoice] # {label, cost {supplies, morale}, reward {supplies, renown, fighters}}

class_name EventChoice extends Resource
@export var label: String
@export var cost: Dictionary
@export var reward: Dictionary
@export var requer_tag: String = ""
```

## 5. 2.5D Rendering
- Cena `Node3D` root + `Camera3D` isométrica `transform: rotation_degrees = Vector3(-45, 45, 0)`, `projection = ORTHOGONAL`, `size = 12`.
- Unidades: `Sprite3D` billboard `billboard = FIXED_Y` + `CapsuleMesh` placeholder (troca texture/mesh por referência).
- Tiles: `MeshInstance3D` com `BoxMesh` colorido, `GridMap` ou instâncias manuais.
- Input: `InputEventScreenTouch`, raycast `Camera3D.project_ray_origin/direction` -> `Plane` y=0 -> `IGridSystem.world_to_cell`.

## 6. Save & Persistência
- `SaveSystem` (autoload): `Dictionary` -> `JSON` -> `user://save.json` (plaintext para debug, futuramente binary). Guarda `pop, supplies, morale, renown, heroes, unlocked_tags, day`.
- Fixtures: `tests/fixtures/saves/v0.1.sav` para teste compatibilidade.

## 7. Schema IA — Como IA gera conteúdo sem quebrar

### Habilidade JSON -> .tres (genérico)
```json
{
  "id": "meteor",
  "nome": "Meteoro",
  "custo": {"mana": 3}, // stat_id genérico, validado contra data/stats/
  "alcance": 5,
  "area": "3x3",
  "efeitos": [{"stat_id": "hp", "delta": -12, "element": "fire"}, {"stat_id": "burn", "delta": 2}],
  "vfx": "res://placeholders/vfx_circle.tscn",
  "logic_script": "res://systems/ability/logics/area_damage.gd"
}
```
Validator rejeita se: `custo` contém `stat_id` não definido em `data/stats/`, `alcance > 10`, `area` não em whitelist.

### Evento JSON
```json
{
  "id": "supply_raid",
  "weight": 15,
  "trigger": "random",
  "titulo": "Saqueadores",
  "texto": "Bandidos pedem 2 carroças...",
  "escolhas": [
    {"label": "Lutar", "cost": {}, "reward": {"renown": 5}},
    {"label": "Entregar", "cost": {"supplies": 20}, "reward": {"morale": -10}}
  ]
}
```

Conversor: `systems/common/json_to_resource.gd` (JSON -> Resource). IA nunca edita `systems/`, só `data/`.

### Mapa/Terreno JSON -> BoardLayoutResource (T1)
```json
{
  "size": [8, 8],
  "damage_delta": -2,
  "rows": [
    "........",
    "..##....",
    "..##..3.",
    "........",
    "....^...",
    "...44...",
    "........",
    "........"
  ]
}
```
Tokens: `.` livre · `#` muro (movimento+visão) · `2`-`9` custo · `^` piso de dano. Validator: tokens na whitelist, linhas==size.y, colunas==size.x, custo>=1.

## 7b. Regra Input Real — Boundary Downstream (2026-08-23)
Input → handler → estado seleção → sistema turno lido. Teste que `assert` só no emissor é `unidade isolada`; `integração input real` deve `assert` no **consumidor downstream** que lê o efeito (Board, Combat, Turn, HUD, EventBus). Critério: se componente tem consumidores conhecidos, `watch_signals(consumidor)` não `emissor`. Ver `tests/integration/template_input_real.gd` + `tests/integration/test_movement_4dir_input_real.gd`.

## 4c. Terreno & LOS — camada plugável por dados (T1)
`BoardLayoutResource` (`data/maps/*.tres`): mapa por **tokens** (`.` livre · `#` muro bloqueia movimento+visão · `2`-`9` custo de movimento · `^` piso de dano com `damage_delta`). `TerrainLayer` opcional no board — sem layout, grid todo-livre (compat total).
- **Walkable:** `TacticalBoard.is_walkable` respeita `blocked` (consumidor TerrainLayer)
- **Movimento ponderado:** `MovementSystem.get_reachable` = Dijkstra-lite por ORÇAMENTO DE CUSTO (stat movement); `find_path` = A* ponderado pelo custo da célula; IA contorna automaticamente
- **Alcance de habilidade** continua floodfill uniforme (distância pura, não terreno)
- **Piso de dano:** aplicado uma vez ao entrar (`on_unit_entered` → `modify_stat`, sinal `damage_floor_triggered`)
- **LOS:** `GridSystem.has_line_of_sight(from, to, opaque)` Bresenham supercover; endpoints ignorados; pronta para `requires_los` no T4
- Visual placeholder: muro escuro, dano laranja (unshaded)
Schema IA em `#schema-ia`. Próximas fases: T3 status effects, T4 classes/targeting, T5 movimento especial.

## 4d. Áreas Strategy — formas plugáveis (T2)
`AreaShape` (Resource Strategy): `get_cells(origin, target, grid) -> Array[Vector2i]`. Built-ins registrados em `AreaShapeRegistry` (`systems/ability/areas/`): `single, 3x3, cross, line` (legado) + `cone (length)`, `ring (radius)`.
- **Plug:** `AbilityResource.area_shape: AreaShape` no `.tres` vence a string legada; sem shape, `resolve_area_cells` delega ao registry pelo id
- **Validator:** com `area_shape` setado pula whitelist de strings; valida interface `get_cells`
- **HUD plug = soltar `.tres` em `data/abilities/`** — glob substituiu lista fixa de 3
- Exemplos: `data/abilities/conejato.tres`, `anelado.tres` (origem gyms/example_dev/habilidades_area/)

## 4b. Movimento Tático — 4-dir + 0.70s per-cell
`MovementSystem.move_unit` usa `A* Manhattan 4-dir` `find_path` e anima waypoints sequenciais `0.70s per-cell` via `Tween` `SINE`, não linha reta. **Occupancy é imediata** ao iniciar o movimento (`update_occupancy` antes do tween) — previne 2 unidades na mesma célula durante a animação; posição visual chega depois (decisão ADR-007b). Bob do eixo y roda no mesmo tween via `tween_method`. **Lock anti-stack**: `is_moving(unit)` + `move_unit` rejeita enquanto anima (`_active: unit_id -> Tween`) — multi-tap não acelera nem corta caminho (regression move_stack). **1 movimento por turno** (GDD "Mover + Ação"): arena `moves_left=1` resetado em `_on_turn_started`; zerado limpa highlights verdes, mantém azul da habilidade. `TacticalArena._handle_tap` separa intenção `ataque (inimigo+can_use) vs move (walkable)` e ignora `próprio tile` para não gerar `VFX explosão` ao andar. `long-press 0.6s` mostra `Label3D` info. Vitória: `TeamRoundRobin._next_turn` chama `check_victory`; arena também conecta `unit_defeated -> check_victory` (guarda `_battle_over` anti-dupla emissão). Fundo branco: `default_env.tres background_mode=1 (BG_COLOR)` + `default_clear_color branco` (mode 0 ignora background_color — regression bg_white).

## 8. Validação & Testes — Pirâmide 50/25/25 (realista, ADR-007; era 70/25/5 genérico)
Ver `AGENTS.md` + `docs/STYLE.md`. Pirâmide real pós-PASSO1: `50% Unit / 25% Integração / 25% Contrato+Smoke+E2E+Regression` (`grep ^func test_` 45/25/26 de 96). Piso guardião `40/20/35` em `test_piramide_contract`. Ver `docs/ADR/ADR-007-piramide-realista.md`.

Pipeline (ordem bloqueia PR):
1.  **Import + Compile:** `godot --headless --import` + `godot --headless --check-only` + `.editorconfig` Tab/LF
2.  **Contrato (gate <1min):** `tests/contract/*` — `DataValidator` rejeita `stat_id` desconhecido, `alcance>10`, `area` inválida, `vfx` inexistente, `ids` duplicados, `AttributeDatabase`, `SaveCompat v0.1.sav`
3.  **Unit (gate <5min):** `tests/unit/*` — lógica pura `RefCounted` (`resolver`, `stats`, `floodfill`, `can_pay`) sem cena
4.  **Integração (gate PR <15min):** `tests/integration/*` — `HUD+Combat+Board` junto (pega `VFX sem dano` e `HUD 0 vs custo 3`), `Input+Combat` via `ScreenTouch` simulado, `Caravana->Tático` via `EventBus`
5.  **Smoke + E2E (gate <10min):** `tests/smoke/*` carrega todas `*.tscn` com `await process_frame` + `tiles 8x8` + `highlight`; `tests/e2e/*` vertical slice `10 dias jornada + 2v2 + 3 habilidades + Save`
6.  **Regressão:** cada bug vira `tests/regression/test_regression_bug_<id>.gd` permanente (ex: `VFX sem dano`)
7.  **CI** `.github/workflows/ci.yml` `barichello/godot-ci:4.7.2` falha se qualquer gate falhar; `gyms/`→`data/` só com `contract` verde

Comandos locais:
```bash
godot --headless --import
godot --headless --check-only
godot --headless --script addons/gut/gut_cmdln.gd -gdir=res://tests/contract -gexit
godot --headless --script addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit
godot --headless --script addons/gut/gut_cmdln.gd -gdir=res://tests/integration -gexit
godot --headless --script addons/gut/gut_cmdln.gd -gdir=res://tests/smoke -gdir=res://tests/e2e -gexit
godot --headless --script addons/gut/gut_cmdln.gd -gexit # tudo
```

## 9. Performance Android
- Compressão `ETC2`, `msaa 2x` max, `shadows off` no MVP, `MultiMesh` para tiles.
- `Engine.max_fps = 60`, `get_viewport().render_target_update_mode = WHEN_VISIBLE`.
- Profiling: `Performance` + `godot --headless --profile`.

## 10. Milestones Técnicos
- **Fase 0 (Bootstrap):** project.godot 4.7.2 + estrutura + grid 8x8 + capsule anda (A*) + export Android APK debug ok.
- **Fase 1 (Caravana MVP):** CaravanManager + Travel + Camp + Market + UI topbar, viajar 10 dias consome corretamente.
- **Fase 2 (Eventos plugáveis):** EventSystem data-driven + 3 eventos + schema documentado para IA.
- **Fase 3 (Tático Genérico):** TurnManager + ICombatResolver plugável (3 exemplos em systems/.../examples: banner_saga, hp_only, shield) + transição Caravana->Combate.
- **Fase 4 (Habilidades Genéricas):** AbilitySystem stat_id + validator contra data/stats/ + 3 magias exemplo.
- **Fase 5 (Polimento):** Swap placeholders, otimização, fixtures save compat.

## 11. Decisões Registradas
Ver `docs/ADR/*.md`
