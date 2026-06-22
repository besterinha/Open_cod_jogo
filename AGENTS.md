# AGENTS.md — Motor de TRPG Tático Genérico

## Sobre o Projeto
Motor de TRPG tático (estilo Banner Saga) genérico e orientado a dados,
construído em Godot 4.5 para Android mobile. Desenvolvimento inicial com
placeholders; conteúdo temático final (história, assets) será injetado na
Fase 4.

## Stack
- Engine: Godot 4.5 (Mobile/GL Compatibility)
- Linguagem: GDScript estritamente tipado
- Testes: gdUnit4 v6.1.3
- Modelo: Qwen3-Coder (1M contexto)

## Roadmap — 5 Fases, 10 Sprints

### Fase 1 — Fundação (Sprints 1-2)
| Sprint | Entrega |
|--------|---------|
| 1 | Grid isométrico + click-to-teleport + herói + câmera |
| 2 | Pathfinding A* + obstáculos + destaque de tile |

### Fase 2 — Combate (Sprints 3-4)
| Sprint | Entrega |
|--------|---------|
| 3 | Sistema de turnos + stats + habilidades |
| 4 | Combate completo no grid + dano/morte |

### Fase 3 — Gerência (Sprints 5-6)
| Sprint | Entrega |
|--------|---------|
| 5 | Sistema de recursos (suprimentos, moral) |
| 6 | Tela de party/formação + transições |

### Fase 4 — Narrativa (Sprints 7-8)
| Sprint | Entrega |
|--------|---------|
| 7 | Motor de diálogo + parser JSON narrativo |
| 8 | Integração diálogo → combate + consequências |

### Fase 5 — Progressão (Sprints 9-10)
| Sprint | Entrega |
|--------|---------|
| 9 | Save/Load + progressão entre mapas |
| 10 | Loop jogável completo + APK final |

---

## Regras de Ouro (Aplicam-se a Todos os Agentes)
- **Tipagem explícita**: `var vida: int = 10`
- **Sinais**: Conexão exclusiva via código (proibido editor visual)
- **Simplicidade**: Scripts máx. 300-400 linhas; se passar, dividir com
  responsabilidade única (SRP)
- **Legibilidade**: Máximo 100 caracteres por linha (ideal ≤80)
- **Modularidade**: Sistemas não acessam outros sistemas diretamente
- **Comunicação**: MessageBus para eventos; queries diretas para chamadas
  síncronas (ex: `grid_system.get_cell()`)
- **Mobile-first**: Touch input, safe areas, 48×48dp touch targets, GL
  Compatibility
- **Nomenclatura**: snake_case para arquivos e pastas
  (`grid_system.gd`, `combat_scene.tscn`). PascalCase apenas para
  `class_name` (`class_name GridSystem`). Sempre minúsculas para evitar
  problemas case-sensitive no export Linux.
- **Helpers de teste**: class_name padrao `*TestHelper`
  (`SmokeTestHelper`, `PropertyTestHelper`).
- **Nomenclatura de sinais**: sinais devem ser nomeados pelo dado que carregam,
  não pela intenção de uso.
  ✓ `signal screen_tapped(screen_pos: Vector2)`
  ✗ `signal world_tapped(world_pos: Vector2)` — nome mente se dado é screen
  A conversão entre espaços de coordenadas é responsabilidade do receptor
  ou de um intermediário explícito, nunca do emissor.
- **Builder ≠ Validator**: qa-tester nunca modifica código (apenas read/bash/glob/grep/skill)
- **Property-based tests primeiro**: Lógica complexa (grid, pathfinding) exige
  testes de invariante com 1000+ iterações antes de testes de exemplo
- **Mutation testing obrigatório**: Após testes passarem, executar
  `tests/mutation/mutation_test.sh` e zerar mutações sobreviventes

## Estrutura do Projeto

```
src/
  systems/       # Lógica de sistemas (GridSystem, CombatSystem, etc.)
  entities/      # Entidades do jogo (Hero, Enemy, Unit)
  ui/            # Interface do usuário (HUD, menus, botões)
  scenes/        # Cenas compostas (combat_scene.tscn)
  globals/       # Autoloads (MessageBus.gd, GameConfig.gd)
  input/         # Controles (touch_controller.gd)
data/
  combat/        # JSONs de classes, habilidades, personagens
  dialogue/      # JSONs de diálogos
  config/        # Resources de configuração (.tres)
assets/
  sprites/       # Sprites de personagens, tiles
  tilesets/      # Recursos TileSet (.tres)
  fonts/         # Fontes (.ttf/.otf)
  audio/         # SFX e música (sfx/, music/)
  shaders/       # Shaders customizados (.gdshader)
tests/
  unit/          # Testes unitários gdUnit4
  property/      # Testes de invariante (1000+ iterações)
  contract/      # Testes de contrato (MessageBus + queries)
  mutation/      # Mutation testing (mutation_test.sh)
  e2e/           # Smoke tests E2E
  performance/   # Testes de performance e baseline
```

### Regras de Dependência

```
data/          → independe
src/globals/   → data/
src/systems/   → src/globals/ + data/
src/entities/  → src/systems/
src/ui/        → src/systems/
src/scenes/    → tudo acima (composição final)
assets/        → independe (referenciado por path)
```

Nenhum sistema importa de uma camada acima. A direção é sempre
descendente: dados → infra → lógica → apresentação → composição.

## CI/CD
- **test.yml**: Rodado em todo push/PR (branch != main/master). Jobs: lint + unit-tests
  (sempre), mutation + smoke-e2e (apenas PR).
- **visual-qa.yml**: Rodado via `workflow_run` após test.yml completar em main/master.
  Exporta Web + Playwright para testes visuais.

## Skills (On-Demand)
As skills são carregadas sob demanda via `skill({name: "..."})`.
Disponíveis:
- **godot-gdscript** — sintaxe GDScript 2.0, padrões, anti-patterns
- **godot-isometric** — matemática de grid isométrico, _draw(), z-index
- **godot-mobile** — otimização Android, touch, safe areas
- **godot-testing** — gdUnit4, asserções, validação de cenas

**Regra**: Antes de iniciar qualquer implementação, carregue a skill
relevante. Ex: se for criar grid, faça
`skill({name: "godot-isometric"})`.

## Agentes Especialistas (Configurados no opencode.json)

| Agente | Domínio | Permissões |
|--------|---------|------------|
| `gdscript-dev` | Scripts GDScript, sistemas, lógica | edit + bash |
| `scene-designer` | Cenas .tscn, nós, propriedades | edit apenas |
| `data-architect` | JSONs, registros, integridade | edit + bash |
| `game-designer` | GDD, mecânicas, fluxo (não escreve código) | edit apenas |
| `art-director` | Estilo visual, UI/UX mobile (não escreve código) | edit apenas |
| `qa-tester` | Testes gdUnit4, validação, APK | bash + read (sem edit) |
| `orchestrator` | Planejamento, delegação, replanejamento | bash + task (sem edit) |

> **Responsabilidade do scene-designer:** Wiring de sinais entre sistemas.
> Toda conexão entre nós via sinal deve ser feita no script do nó raiz da cena
> ou no `_ready()` do nó pai. Sistemas nunca devem se conectar diretamente.

## REPLAN_STEP (executado pelo orchestrator antes de cada tarefa)
1. Atualizar state.json: status, última tarefa, próximo passo
2. Verificar se pattern docs refletem a interface pública atual (se divergirem,
   corrigir o doc antes de prosseguir)
3. Verificar se há decisões arquiteturais indefinidas bloqueando a próxima
   tarefa — se houver, pausar e solicitar decisão humana
4. Atualizar docs/project_map/index.md com status atual
5. Confirmar que todos os Quality Gates da tarefa anterior foram cumpridos

## Fluxo de Trabalho
1. Cada tarefa inicia com `game-designer` (se aplicável) para GDD
2. `orchestrator` quebra em sub-tarefas e delega para agentes
   especialistas
3. Cada implementação segue: skill → código → teste
4. `qa-tester` valida no final: testes gdUnit4 → sintaxe → mutation testing → smoke → APK
5. `orchestrator` executa REPLAN_STEP antes da próxima tarefa
6. Antes de delegar qualquer tarefa de implementação, verificar se todas as
   decisões arquiteturais necessárias estão documentadas. Se não estiverem,
   NÃO delegar — pausar e listar as decisões pendentes para o desenvolvedor.

## Pirâmide de Validação (Ordem)

| Camada | O que pega | Implementação |
|--------|-----------|---------------|
| 1. Feedforward | Erro antes de ser escrito | Skills on-demand, AGENTS.md |
| 2. Análise Estática | Segurança, estilo, tipos | `--check-only` (futuro: Semgrep/CodeQL) |
| 3. Testes Unitários | Regressão lógica básica | `tests/unit/` com gdUnit4 |
| 4. Property-based | Alucinações em edge cases | `tests/property/` com 1000+ iterações |
| 5. Mutation Testing | Testes que não testam nada | `tests/mutation/mutation_test.sh` |
| 6. Contract Testing | Interfaces divergentes | `tests/contract/` (MessageBus + queries) |
| 7. Smoke/E2E | Fluxo completo quebrado | Godot headless export |
| 8. Builder ≠ Validator | Viés do gerador | qa-tester com `read \| bash \| glob \| grep \| skill` (sem edit) |

## Error Recovery
- **Antes de cada tarefa**: `git add -A && git commit -m "snapshot: ..."`
  + `git checkout -b agent/<task-name>`
- **Limite**: 2 falhas por tarefa. Na 3ª, pausar para intervenção humana.

## Quality Gates (Ordem Obrigatória)
0. Documentation Sync: pattern docs em docs/patterns/ refletem a interface
   pública atual dos sistemas. Se divergirem, o doc está errado — corrigir
   antes de rodar qualquer teste.
1. Todos os testes gdUnit4 passando (unit + property + contract)
2. Sintaxe GDScript válida (`godot --headless --check-only --script res://<path>`,
   excluindo arquivos que dependem de addon — esses são validados pelo gdUnit4)
3. Mutation testing zerado (`bash tests/mutation/mutation_test.sh`)
4. Smoke tests E2E passando (`bash tests/e2e/smoke_test.sh`)
5. APK exportável (`godot --headless --export-debug "Android"`)
