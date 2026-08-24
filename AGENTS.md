# AGENTS.md — Open_cod_jogo (TRPG Tático 2.5D + Caravana)

Gerado via `/init` — Stack travada em Build Mode (22/08/2026)

## Projeto
TRPG tático 2.5D para Android, inspiração **Banner Saga** (caravana + combate tático). Plugável/data-driven para automação de IA criar magias/ações/eventos sem tocar no Core. Placeholders até assets reais.

## Stack
- **Engine:** Godot 4.7.2-stable Standard (GDScript, Renderer Mobile, ETC2) — `godotengine.org/download/archive/4.7.2-stable`
- **Build Android:** OpenJDK 17 (Temurin) + Android Studio SDK (Platform-Tools 35.0.0+, Build-Tools 35.0.1, Platform 35, NDK r28b, CMake 3.10.2) + GABE (Godot Android Build Environment, estável 4.7)
- **Linguagem:** GDScript (100% gratuito, MIT)
- **Testes:** GUT 9.7.1 (branch godot_4_7, MIT) + godot-validation-flow (Odin, MIT)
- **VCS:** Git + Git LFS (sob demanda)

## Arquitetura — 4 Pilares (Epictellers/GDQuest Modular)
```
addons/   -> LIBRARIES (toolkit agnóstico, nunca depende de systems/content) — ex: grid_toolkit
systems/  -> SYSTEMS (regras: systems/caravan, systems/tactical/combat, systems/ability) — usa addons
ui/       -> UI isolada — só LÊ de systems, nunca escreve lógica
content/  -> CONTENT específico do jogo — data/abilities/, data/events/, maps/ — USA systems. systems NUNCA depende de content.
gyms/     -> SANDBOX por dev, ignorado no build. Protótipo rápido -> refatora para padrão se aprova.
data/     -> Dados plugáveis (Resource .tres) onde IA atua
```
Fluxo de dependência: `content -> systems -> addons`, `ui -> systems`. CI bloqueia `gyms -> !gyms`.

## Convenções — Seguir `docs/STYLE.md` (fonte única)
- **Estilo:** GDScript tipado obrigatório (`var hp: int`, `func get_stat(id: String) -> int:`), `snake_case` vars/funcs, `PascalCase` classes, `SCREAMING_SNAKE` const. Ordem: `class_name → extends → signal → @export → var → @onready → func`. Ver `docs/STYLE.md` + `GDScript style guide 4.7`.
- **Arquitetura:** `addons → systems → content/data` + `ui → systems`, `gyms` isolado. CI bloqueia `gyms` fora de `gyms/`.
- Resources plugáveis: `class_name AbilityResource extends Resource` + `IAbilityLogic` (Strategy). Toda magia/evento é `.tres` referenciando `logic_script: GDScript` + `vfx: PackedScene` placeholder.
- Placeholders em `placeholders/` (capsule/cube/circle) — swap por `Sprite3D` textura é só trocar referência no `.tres`.
- 2.5D: cena `Node3D` + `Camera3D` ortogonal isométrica (45°), `Sprite3D` billboard para unidades.
- Android: `touch tap` mover, `pinch` zoom, `long-press` info. Anchors para 720p–2K.
- Validar antes de commit: `godot --headless --import` + `godot --headless --check-only` + `.editorconfig` (Tab/LF) + `godot-validation-flow` + `DataValidator` + `gut --headless -gexit` (CI falha se style/test != ok)
- Testes obrigatórios por feature (50/25/25, ADR-007; era 70/25/5 genérico): `unit` (isolado, lógica pura `RefCounted`) + `contract` (DataValidator) + `integration` (completo `HUD+Combat+Board`/`Input+Combat`/`Caravana->Tático` com `watch_signals`) + `smoke` (`await process_frame`) + `regression` (`test_regression_bug_<id>`) — piso `40/20/35` em `test_piramide_contract`
- Commits: `feat:`, `fix:`, `docs:`, `chore:`. Gratuito apenas (sem asset pago).

## Comandos úteis
```
# Rodar validação local
godot --headless --script addons/gut/gut_cmdln.gd -gexit
godot --headless --check-only  # syntax check
# Export Android (após Project -> Install Android Build Template)
godot --headless --export-release "Android" build.apk
```

## MCPs (opencode.json)
- `godot` (Coding-Solo/godot-mcp, MIT) — base leve
- `godot-docs` (@nuskey8/godot-docs-mcp, MIT)
- `context7` (MIT)
- `gopeak` (habilitar só Fase 3+ para screenshot/input)

## Regras de Agente
- Sempre gratuito/MIT. Nada pago.
- Toda nova habilidade/ação: criar em `gyms/` -> validar contrato -> mover para `data/` -> testes GUT + smoke -> CI bloqueia merge se falha.
- Para IA gerar conteúdo: usar schema JSON documentado em `docs/TDD.md#schema-ia`.
- Toda nova feature (habilidade, sistema, UI): testes `unit` (isolado, `new()` sem cena) + `integration` (completo `HUD+Combat+Board` com `watch_signals` e `await process_frame`) — CI bloqueia `contract/unit/integration/smoke` se falhar. Nunca só isolado.
- Toda nova feature que muda design/arquitetura/estilo: atualizar `docs/GDD.md` + `docs/TDD.md` + `docs/STYLE.md` no mesmo PR — CI bloqueia se `systems/*.gd` ou `ui/*.gd` mudou e `docs/*.md` não mudou.
- Finalização obrigatória: sempre fechar tarefa com `commit + resumo + TodoWrite completed` antes do `timeout` (<60s por `bash`), dividir `gut`/`export` em passos separados; nunca deixar `in_progress` exigindo `.` do usuário para terminar.
