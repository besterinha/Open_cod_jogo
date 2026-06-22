# Definition of Done por Sprint

## Sprint 1 — Grid + Click-to-Teleport + Herói + Câmera

**Técnico (Quality Gates):**
- Gate 0: Pattern docs refletem interface pública dos sistemas
- Gate 1: Testes gdUnit4 passando (unit + property + contract)
- Gate 2: Sintaxe GDScript válida
- Gate 3: Mutation testing zerado
- Gate 4: Smoke tests E2E passando
- Gate 5: APK exportável

**Funcional:**
- Grid 8×8 com 64 tiles visíveis (losangos)
- Herói (círculo azul) aparece na célula (0,0) ao iniciar
- Tap em célula válida teletransporta herói para essa célula
- Tap fora do grid não causa erro nem teleporte
- Célula tocada fica destacada em amarelo
- Zoom por pinch (dois dedos) funcional, range 0.5×–4×
- Câmera fixa centralizada no grid

**Fora do escopo:**
- Pathfinding A*
- Sistema de turnos
- Inimigos/combate
- Menu/splash
- Diálogos
- Save/Load

---

## Sprint 2 — Pathfinding A* + Obstáculos + Destaque de Tile

**Técnico (Quality Gates):**
- Gate 0: Pattern docs refletem interface pública dos sistemas
- Gate 1: Testes gdUnit4 passando (unit + property + contract)
- Gate 2: Sintaxe GDScript válida
- Gate 3: Mutation testing zerado
- Gate 4: Smoke tests E2E passando
- Gate 5: APK exportável

**Funcional:**
- Obstáculos visíveis: tiles bloqueados do JSON aparecem em vermelho escuro
- Path A* calculado: ao tocar célula vazia e desbloqueada, path é destacado em laranja
- Movimento animado: herói caminha tile a tile (0.15s por passo) até o destino
- Bloqueio de input: durante animação, toques são ignorados
- Alcance visível: ao tocar o herói, tiles alcançáveis dentro do range são destacados em verde
- Tile bloqueado impede path: A* desvia de bloqueios ou retorna vazio sem crash
- Célula inalcançável: sem path, sem animação, sem highlight
- Carga de cenário via JSON: grid_size, blocked_cells, hero_start, hero_move_range

**Fora do escopo:**
- Inimigos / unidades múltiplas (Sprint 3)
- Sistema de turnos (Sprint 3)
- HUD / barra de status (Sprint 5+)
- Custo de terreno variável (todos livres = custo 1)
- Pathfinding com 8-dir (apenas 4-dir manhattan)
- A* com weighted tiles / elevation
- Animações de sprite (usamos _draw() placeholders)
- Música e SFX

---

## Sprint 3 — Sistema de Turnos + Stats + Habilidades
*(a definir)*

## Sprint 4 — Combate Completo no Grid + Dano/Morte
*(a definir)*
