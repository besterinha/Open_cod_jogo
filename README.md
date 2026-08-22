# Open_cod_jogo — TRPG Tático 2.5D + Caravana

TRPG tático 2.5D para Android, inspiração **Banner Saga**, Godot 4.7.2-stable, 100% gratuito, **plugável** para IA gerar magias/eventos sem tocar no Core.

## Quick Start

### Requisitos
- Godot 4.7.2-stable Standard (`godotengine.org/download/archive/4.7.2-stable`) + `export_templates.tpz` mesma versão
- OpenJDK 17 (Temurin), Android Studio SDK (Platform-Tools 35.0.0+, Build-Tools 35.0.1, Platform 35, NDK r28b, CMake 3.10.2)
- Node.js 18+ (para MCPs), Git

### Rodar
```bash
git clone https://github.com/besterinha/Open_cod_jogo
cd Open_cod_jogo
godot --headless --check-only
godot --headless --script addons/gut/gut_cmdln.gd -gexit # testes
godot # abre editor
```

### Export Android
1. `Project -> Install Android Build Template` (gera `android/build`, requer JDK/SDK configurado em `Editor -> Editor Settings -> Export -> Android`)
2. `Project -> Export -> Add Android -> Export` (APK debug) ou `GABE` (4.7 companion app)

## Estrutura (4 Pilares)
```
addons/ -> LIBRARIES (grid_toolkit, gut) — agnóstico
systems/ -> SYSTEMS (caravan, tactical, ability) — regras
ui/ -> UI isolada (só lê systems)
content/data/ -> CONTENT plugável onde IA atua (abilities/events)
gyms/ -> sandbox (ignorado no build)
placeholders/ -> capsule/cube/circle
tests/ -> GUT unit/smoke/regression
docs/ -> GDD/TDD/ADR
```

## Docs
- `AGENTS.md` — regras para agentes
- `docs/GDD.md` — design (one-page)
- `docs/TDD.md` — técnico + schema IA
- `docs/ADR/` — decisões arquiteturais

## Criar Nova Habilidade (exemplo plugável)
1. Protótipo em `gyms/seu_nome/meteor/`
2. Validar -> mover para `data/abilities/meteor.tres`:
```tres
[resource]
script = ExtResource("res://systems/ability/ability_resource.gd")
id = "meteor"
nome = "Meteoro"
custo = {"willpower": 3}
alcance = 5
area = "3x3"
vfx = ExtResource("res://placeholders/vfx_circle.tscn")
```
3. `DataValidator` + `gut -gexit` + `validation-flow` -> CI bloqueia se quebrar.

## Testes & CI
- `godot --headless --script addons/gut/gut_cmdln.gd -gexit` (local e GitHub Actions `barichello/godot-ci:4.7.2`)
- `godot-validation-flow` para deps quebradas

## Licença
MIT — veja `LICENSE` (a criar). Assets CC0/Blender GPL.

## MCPs
`opencode.json` configura `godot`, `godot-docs`, `context7` (todos MIT, gratuitos).

## Status
Fase 0 Bootstrap — esqueleto criado, pronto para implementar Caravana MVP.
