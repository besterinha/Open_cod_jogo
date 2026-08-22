# TDD — Open_cod_jogo | Technical Design Document

**Versão:** 0.1.0 | **Data:** 22/08/2026 | **Godot:** 4.7.2-stable Standard | **Linguagem:** GDScript | **Licença:** MIT (100% gratuito)

---

## 1. Overview
Construir TRPG tático 2.5D + Caravana modular plugável onde conteúdo (habilidades/eventos) é dado, não código. Dois layers: `Caravan` (gestão recursos + eventos) e `Tactical` (grid + turnos + combat). Crítico: `content -> systems -> addons` unidirecional, validável por IA.

## 2. Arquitetura — 4 Pilares (Epictellers/GDQuest)
Ver `AGENTS.md`. Diagrama de dependência:
```
addons (grid_toolkit, gut) <- systems (caravan, tactical, ability) <- content (data/*.tres, maps)
                                      ^                                |
                                      +----------- ui -------------------+
gyms (isolado, .gitignore no build)
```
CI bloqueia: `grep -r "gyms/" --include="*.gd" addons/ systems/ ui/` deve falhar.

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
├── data/                     # PLUGÁVEL — onde IA atua
│   ├── abilities/*.tres
│   ├── events/*.tres
│   └── classes/*.tres
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

### 4.3 AbilityResource (Data-Driven)
```gdscript
class_name AbilityResource extends Resource
@export var id: String
@export var nome: String
@export var custo: Dictionary = {"willpower": 1, "renown": 0}
@export var alcance: int = 1
@export var area: String = "single" # single, 3x3, cross, line
@export var efeitos: Array[Resource] # DamageEffect, HealEffect, StatusEffect
@export var tags_required: PackedStringArray
@export var vfx: PackedScene # placeholder: res://placeholders/vfx_circle.tscn
@export var logic_script: GDScript # implementa IAbilityLogic
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

### Habilidade JSON -> .tres
```json
{
  "id": "meteor",
  "nome": "Meteoro",
  "custo": {"willpower": 3},
  "alcance": 5,
  "area": "3x3",
  "efeitos": [{"type": "Damage", "value": 12, "element": "fire"}, {"type": "Burn", "turns": 2}],
  "vfx": "res://placeholders/vfx_circle.tscn",
  "logic_script": "res://systems/ability/logics/area_damage.gd"
}
```
Validator rejeita se: `alcance > 10`, `area` não em whitelist, `efeitos` tipo desconhecido.

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

## 8. Validação & Testes
Ver `AGENTS.md`. Pipeline:
1.  `godot-validation-flow` (broken deps) + `DataValidator` (contrato .tres)
2.  `GUT` unit (`tests/unit/*`), `SceneRunner` integration
3.  `Smoke` (`tests/smoke/test_all_scenes_load.gd`) carrega todas `*.tscn` headless
4.  `CI` GitHub Actions `barichello/godot-ci:4.7.2` -> `godot --headless --script addons/gut/gut_cmdln.gd -gexit` (bloqueia merge se falha)
5.  `Regression`: cada bug vira `test_regression_bug_<id>`

Comando local:
```
godot --headless --check-only
godot --headless --script addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit
```

## 9. Performance Android
- Compressão `ETC2`, `msaa 2x` max, `shadows off` no MVP, `MultiMesh` para tiles.
- `Engine.max_fps = 60`, `get_viewport().render_target_update_mode = WHEN_VISIBLE`.
- Profiling: `Performance` + `godot --headless --profile`.

## 10. Milestones Técnicos
- **Fase 0 (Bootstrap):** project.godot 4.7.2 + estrutura + grid 8x8 + capsule anda (A*) + export Android APK debug ok.
- **Fase 1 (Caravana MVP):** CaravanManager + Travel + Camp + Market + UI topbar, viajar 10 dias consome corretamente.
- **Fase 2 (Eventos plugáveis):** EventSystem data-driven + 3 eventos + schema documentado para IA.
- **Fase 3 (Tático):** TurnManager + CombatResolver BannerSaga + transição Caravana->Combate.
- **Fase 4 (Habilidades):** AbilitySystem + 3 magias + validator.
- **Fase 5 (Polimento):** Swap placeholders, otimização, fixtures save compat.

## 11. Decisões Registradas
Ver `docs/ADR/*.md`
