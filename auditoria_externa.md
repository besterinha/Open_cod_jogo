# Auditoria Externa — Claude (Anthropic)

Este documento é o resultado de uma auditoria independente feita por Claude no
estado atual do workspace. A auditoria foi solicitada pelo desenvolvedor porque
modelos que geram o próprio plano têm ponto cego estrutural ao avaliá-lo — o
modelo lê o código pela intenção, não pelo que está escrito.

Todas as decisões arquiteturais já foram tomadas pelo desenvolvedor e estão
documentadas neste arquivo. Execute tudo na ordem indicada.

---

## PARTE 1 — Correções Estruturais no AGENTS.md

### 1. Definir REPLAN_STEP explicitamente

AGENTS.md menciona que o orchestrator executa REPLAN_STEP antes de cada
tarefa, mas esse procedimento não existe em lugar nenhum. Cada execução vai
interpretá-lo diferente.

**Ação:** Adicionar ao AGENTS.md a definição de REPLAN_STEP:

```
## REPLAN_STEP (executado pelo orchestrator antes de cada tarefa)
1. Atualizar state.json: status, última tarefa, próximo passo
2. Verificar se pattern docs refletem a interface pública atual (se divergirem,
   corrigir o doc antes de prosseguir)
3. Verificar se há decisões arquiteturais indefinidas bloqueando a próxima
   tarefa — se houver, pausar e solicitar decisão humana
4. Atualizar docs/project_map/index.md com status atual
5. Confirmar que todos os Quality Gates da tarefa anterior foram cumpridos
```

---

### 2. Adicionar regra de bloqueio para decisões arquiteturais indefinidas

Atualmente o orchestrator não tem regra que impeça delegar tarefas quando
decisões arquiteturais necessárias ainda não foram tomadas. Isso faz a IA
decidir silenciosamente.

**Ação:** Adicionar ao AGENTS.md na seção de regras do orchestrator:

```
- Antes de delegar qualquer tarefa de implementação, verificar se todas as
  decisões arquiteturais necessárias estão documentadas. Se não estiverem,
  NÃO delegar — pausar e listar as decisões pendentes para o desenvolvedor.
```

---

### 3. Definir responsável pelo wiring de sinais entre sistemas

AGENTS.md proíbe sistemas se acessarem diretamente, mas não define quem
escreve o código de conexão entre eles na cena.

**Ação:** Adicionar ao AGENTS.md na descrição do `scene-designer`:

```
Responsabilidades adicionais:
- Wiring de sinais entre sistemas: toda conexão entre nós via sinal deve ser
  feita no script do nó raiz da cena ou no _ready() do nó pai.
- Nunca deixar conexão de sinais para os próprios sistemas — eles não devem
  saber da existência uns dos outros.
```

---

### 4. Adicionar convenção de nomenclatura de sinais

`touch_controller.gd` emite `event.position` (coordenada de tela) num sinal
chamado `world_tapped`. O nome promete world space mas entrega screen space.
Com câmera deslocada isso produz bugs silenciosos que passam em testes
unitários.

**Ação:** Adicionar ao AGENTS.md na seção de Regras de Ouro:

```
- Nomenclatura de sinais: sinais devem ser nomeados pelo dado que carregam,
  não pela intenção de uso.
  ✓ signal screen_tapped(screen_pos: Vector2)
  ✗ signal world_tapped(world_pos: Vector2)  ← nome mente se dado é screen
  A conversão entre espaços de coordenadas é responsabilidade do receptor
  ou de um intermediário explícito, nunca do emissor.
```

Após adicionar a regra: renomear o sinal em `touch_controller.gd` para
`screen_tapped` e atualizar todas as referências.

---

### 5. Adicionar Documentation Sync como Quality Gate

Não existe nenhum gate que verifique se os pattern docs refletem a
implementação real. Isso já causou divergência: `docs/patterns/grid_system.md`
descreve uma interface (`get_cell`, `is_cell_free`, `find_path`, `move_unit`)
que não existe no `grid_system.gd` atual — a implementação tem
`is_within_bounds`, `world_to_grid`, `grid_to_world`.

**Ação 1:** Corrigir `docs/patterns/grid_system.md` para refletir a interface
atual implementada.

**Ação 2:** Adicionar ao AGENTS.md nos Quality Gates como Gate 0:

```
0. Documentation Sync: pattern docs em docs/patterns/ refletem a interface
   pública atual dos sistemas. Se divergirem, o doc está errado — corrigir
   antes de rodar qualquer teste.
```

---

### 6. Resolver docs/project_map/scenes.md e signals.md vazios

Esses arquivos existem na estrutura mas estão vazios. Agentes que os
consultarem receberão informação nula.

**Ação:** Ou popular com conteúdo real, ou remover e atualizar
`docs/project_map/index.md` para não os referenciar.

---

### 7. Consolidar scene_manifest em fonte única de verdade

Existem dois arquivos relacionados: `docs/scene_manifest.md` e
`docs/project_map/scene_manifest.md`. Agentes vão atualizar um e esquecer
o outro.

**Ação:** Manter apenas `docs/scene_manifest.md` como autoritativo. Substituir
`docs/project_map/scene_manifest.md` por um redirecionamento ou removê-lo.
Atualizar `docs/project_map/index.md` para apontar para o caminho correto.

---

## PARTE 2 — Decisões Arquiteturais (já tomadas pelo desenvolvedor)

Estas decisões foram confirmadas e devem ser documentadas no AGENTS.md,
no state.json e no GDD do Sprint 1.

### D1 — Câmera
**Decisão:** Câmera fixa, centralizada no grid.
Zoom por pinch (dois dedos) habilitado no Sprint 1.
A câmera não segue o herói nem permite pan.

### D2 — Cena inicial
**Decisão:** `project.godot` aponta diretamente para `combat_scene.tscn`
como main_scene. `main_scene.tscn` é eliminada do projeto por enquanto.
Menu/splash fica para um sprint futuro.

### D3 — Wiring TouchController → Hero
**Decisão:** O nó raiz de `combat_scene.tscn` tem um script próprio que:
1. Recebe o sinal `screen_tapped(screen_pos: Vector2)` do TouchController
2. Converte para world space (aplicando transform da câmera)
3. Chama `grid_system.world_to_grid(world_pos)` para obter grid_pos
4. Chama `hero.teleport_to(grid_pos)`
Os sistemas (GridSystem, Hero, TouchController) não se conhecem diretamente.

### D4 — Tamanho do grid
**Decisão:** Grid data-driven. `GridSystem` passa a usar `var grid_size: Vector2i`
em vez de `const`, com valor padrão 8×8. Adicionar função `setup(size: Vector2i)`
chamada ao carregar a cena. Cada batalha futura define seu tamanho via JSON.
Justificativa: Banner Saga usa 8×8, adequado para mobile e profundidade tática.

### D5 — Input
**Decisão:** Android/touch apenas. Sem fallback para mouse ou teclado.
Usar exclusivamente `InputEventScreenTouch` e `InputEventScreenDrag`.
Não implementar nenhum código de input alternativo.

### D6 — Placeholders visuais Sprint 1
**Decisão:** Todos desenhados via `_draw()`:
- Tile walkable: losango cinza claro com borda cinza escura
- Tile bloqueado: losango vermelho escuro
- Highlight de seleção: losango amarelo semitransparente
- Herói: círculo azul

---

## PARTE 3 — O que Precisa Ser Criado

### 8. GDD do Sprint 1

O workflow define que toda tarefa começa com o game-designer criando o GDD.
Não existe nenhum GDD para o Sprint 1. Sem ele o orchestrator não tem spec
concreta e os agentes tomam decisões de design silenciosamente.

**Ação:** O agente `game-designer` deve criar `docs/gdd/sprint_01.md`
contendo:

- O que o jogador vê e consegue fazer ao final do Sprint 1:
  "Grid 8×8 renderizado na tela. Herói (círculo azul) aparece na célula (0,0)
  ao iniciar. Tap em qualquer célula dentro do grid teletransporta o herói
  imediatamente para aquela célula. Zoom por pinch funcional."
- Dimensões do grid: 8×8 (padrão), data-driven via setup()
- Comportamento da câmera: fixa, centralizada no grid, zoom por pinch
- Especificação de placeholders: conforme D6 acima
- Input: touch apenas (Android)
- Critérios de aceitação mensuráveis:
  - Grid renderizado com 64 tiles visíveis
  - Herói aparece em (0,0) ao iniciar a cena
  - Tap em célula válida move herói para essa célula
  - Tap fora do grid não causa erro
  - Zoom por pinch altera o zoom da câmera
  - APK exportável e funcional em Android
- Fora do escopo do Sprint 1: pathfinding, sistema de turnos, inimigos,
  menu, diálogos

---

### 9. Definition of Done por Sprint

Os Quality Gates cobrem validação técnica mas não critérios funcionais.

**Ação:** Criar `docs/sprint_definitions.md` com uma seção por sprint.
Para Sprint 1, usar os critérios de aceitação do GDD acima.
Formato:

```markdown
## Sprint 1 — Definition of Done
**Técnico:** todos os Quality Gates passando + APK exportável
**Funcional:** grid 8x8 visível, herói se teletransporta ao toque,
              zoom por pinch funcional
**Fora do escopo:** pathfinding, turnos, inimigos, menu
```

---

## Ordem de Execução

```
1. Aplicar correções estruturais no AGENTS.md (itens 1–7)
2. Documentar decisões D1–D6 no state.json e AGENTS.md
3. Eliminar main_scene.tscn e atualizar project.godot (D2)
4. game-designer cria docs/gdd/sprint_01.md (item 8)
5. Criar docs/sprint_definitions.md (item 9)
6. orchestrator executa REPLAN_STEP e valida que não há decisões
   arquiteturais indefinidas
7. Apenas então: iniciar implementação de código de jogo
```

---

## Contexto Final

A infraestrutura de validação (pirâmide de 8 camadas, CI/CD, 7 agentes,
4 skills, Quality Gates) está sólida. O workspace está preparado para
detectar erros. O que faltava era estar preparado para construir a coisa
certa — este documento resolve isso fornecendo GDD, decisões arquiteturais
e critérios de aceitação antes da implementação começar.
