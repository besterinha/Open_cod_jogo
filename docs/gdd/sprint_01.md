# GDD — Sprint 01: Grid Isométrico + Herói + Câmera

## Visão Geral

Sprint 1 estabelece a fundação visual e interativa do motor de TRPG tático.
Entrega um grid isométrico 8×8 renderizado via `_draw()`, um herói (círculo azul)
posicionado na origem, câmera fixa com zoom por pinch (dois dedos), e
click-to-teleport: o jogador toca uma célula válida e o herói teletransporta-se
para ela. Sistemas conectados via sinal `screen_tapped` do `TouchController`.

## O que o jogador vê e faz

**Cena inicial (CombatScene):**
- Grid isométrico 8×8 (losangos cinza claro com borda escura) centralizado na tela.
- Herói (círculo azul com contorno) na célula (0,0) — canto superior esquerdo do grid.
- Nenhum tile destacado inicialmente.

**Ações do jogador:**
1. **Tocar uma célula válida** → a célula é destacada em amarelo translúcido e o herói se move instantaneamente para o centro dela.
2. **Tocar fora do grid** → nada acontece (sem crash, sem teleporte).
3. **Pinçar com dois dedos** → zoom da câmera entre 0.5× e 4×.

**Feedback visual:**
- Tile tocado fica amarelo translúcido (highlight).
- Herói reposiciona-se no centro do tile de destino.
- Zoom responde suavemente ao movimento dos dedos.

## Especificação Técnica

### Grid (GridSystem)

| Propriedade | Valor |
|------------|-------|
| Tamanho | 8×8 (`Vector2i(8, 8)`) |
| Tile size | 32×16 px (`TILE_SIZE`) |
| Renderização | `_draw()` com `draw_colored_polygon` + `draw_polyline` |
| Célula livre | Losango cinza claro (0.7, 0.7, 0.7) com borda escura |
| Célula bloqueada | Losango vermelho escuro (0.5, 0.2, 0.2) — nenhuma no Sprint 1 |
| Highlight | Losango amarelo translúcido (1.0, 1.0, 0.0, 0.5) com borda amarela |

**Conversão de coordenadas:**
- `world_to_grid(world_pos: Vector2) → Vector2i`: projeção isométrica reversa.
- `grid_to_world(grid_pos: Vector2i) → Vector2`: centro do tile em coordenadas world.

**Métodos públicos:**
- `setup(size: Vector2i)` — redefine o grid (data-driven).
- `is_within_bounds(pos: Vector2i) → bool` — valida se célula existe.
- `highlight_cell(pos: Vector2i)` — marca célula para redraw.
- `world_to_grid()` / `grid_to_world()` — conversão entre espaços.

### Herói (Hero)

| Propriedade | Valor |
|------------|-------|
| Tamanho | Raio 10 px |
| Cor | Azul (0.2, 0.4, 0.8) com contorno (0.3, 0.5, 0.9) |
| Posição inicial | Cell (0,0) → `grid_to_world(Vector2i(0, 0))` |
| Grid system | Injetado via `hero.grid_system = grid_system` no `_ready()` da cena |

**Métodos públicos:**
- `teleport_to(pos: Vector2i)` — atualiza `grid_position` e move o nó para o centro do tile.

### Câmera (Camera2D)

| Propriedade | Valor |
|------------|-------|
| Tipo | `Camera2D` como filho direto da raiz |
| Posição | `Vector2(0, 80)` — centralizada no grid |
| Zoom inicial | `Vector2(2, 2)` |
| Zoom mínimo | `Vector2(0.5, 0.5)` |
| Zoom máximo | `Vector2(4.0, 4.0)` |

**Comportamento:** Não há pan/drag. Apenas zoom por pinch (dois dedos).
O cálculo do zoom é feito diretamente no `TouchController` via
`get_viewport().get_camera_2d()`.

### Input (TouchController)

| Propriedade | Valor |
|------------|-------|
| Tipo | `Node` (autoload ou filho da cena) |
| Sinal | `screen_tapped(screen_pos: Vector2)` |
| Toque único | Emite `screen_tapped` no `pressed` |
| Pinç (2 toques) | Modifica `camera.zoom` diretamente durante `drag` |
| Mouse/Keyboard | Fora do escopo — mobile-only |

**Fluxo do toque em célula válida:**
1. `TouchController._on_touch()` emite `screen_tapped(pos_screen)`.
2. `CombatScene._on_screen_tapped()` recebe `screen_pos`.
3. Converte `screen_pos → world_pos` via `viewport.canvas_transform.affine_inverse()`.
4. Converte `world_pos → grid_pos` via `grid_system.world_to_grid()`.
5. Valida com `grid_system.is_within_bounds()`.
6. Se válido: `grid_system.highlight_cell(grid_pos)` + `hero.teleport_to(grid_pos)`.

### Árvore da Cena (CombatScene)

```
root (Node2D) → combat_scene.gd (CombatScene)
├── GridSystem (Node2D) → grid_system.gd (GridSystem)
├── Hero (Node2D) → hero.gd (Hero)
├── Camera (Camera2D)
│   ├── position = (0, 80)
│   └── zoom = (2, 2)
└── TouchController (Node) → touch_controller.gd (TouchController)
```

### Data Flow

```
Touch (input) → TouchController → signal screen_tapped(screen_pos)
                                      ↓
                              CombatScene._on_screen_tapped()
                                      ↓
                          viewport.canvas_transform.affine_inverse()
                                      ↓
                              world_pos (Vector2)
                                      ↓
                          GridSystem.world_to_grid(world_pos)
                                      ↓
                          grid_pos (Vector2i)
                                      ↓
                          is_within_bounds(grid_pos)?
                           ├── Não → retorna (no-op)
                           └── Sim → GridSystem.highlight_cell(grid_pos)
                                   → Hero.teleport_to(grid_pos)
```

## Critérios de Aceitação

1. **Grid renderizado** com 64 tiles visíveis (8×8), losangos cinza com borda.
2. **Herói aparece** na célula (0,0) ao iniciar a cena.
3. **Tocar célula válida** → herói teletransporta-se para aquela célula.
4. **Tocar fora do grid** → nenhum crash, nenhum teleporte.
5. **Pinça** (dois dedos) → zoom da câmera altera-se entre 0.5× e 4×.
6. **APK exportável** e funcional em dispositivo Android (toque e pinch).

## Fora do Escopo

- Pathfinding A* (Sprint 2)
- Obstáculos / tiles bloqueados (Sprint 2)
- Destaque de tiles adjacentes / alcance (Sprint 2)
- Sistema de turnos (Sprint 3)
- Inimigos / unidades múltiplas (Sprint 3)
- Atributos e habilidades (Sprint 3)
- Menus e HUD (Sprint 5+)
- Diálogos e narrativa (Sprint 7)
- Save/Load (Sprint 9)
- Mouse e teclado (mobile-only)
- Animações de movimento (teleporte instantâneo)
- Música e SFX
