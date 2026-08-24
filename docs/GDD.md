# GDD — Open_cod_jogo | TRPG Tático 2.5D + Caravana (One-Page + Detalhamento)

**Versão:** 0.1.0 | **Data:** 22/08/2026 | **Engine:** Godot 4.7.2-stable | **Plataforma:** Android (720p–2K, Offline)
**Inspiração:** The Banner Saga (referência, não contrato) | **Estado:** Pré-produção, modular plugável genérico

---

## 1. Elevator Pitch (1 frase)
Caravana em jornada 1D side-scrolling com gestão de recursos (Supplies/Morale/Renown) que alimenta combates táticos 2.5D por turnos — cada magia/evento é um dado plugável que IA pode gerar sem tocar no código.

## 2. Pillars (3)
1.  **Caravana = Coração** — Decisões difíceis na estrada têm custo real no combate (ex: moral baixa → penalidade plugável, ex: Banner Saga usa -willpower, mas fórmula é configurável).
2.  **Tático Legível** — Grid quadrado 2.5D isométrico, posicionamento > DPS. **Stats 100% genéricos data-driven** (`data/stats/*.tres`) — você define quais atributos existem (HP, Armor, Shield, Mana, etc.), motor não trava. Touch preciso.
3.  **Plugável = Longevidade** — Habilidades/eventos/stats são `.tres`/JSON, não código hardcoded. Resolver de combate plugável (`ICombatResolver`): Banner Saga `Armor vs Strength` é só 1 dos 3 exemplos em `systems/tactical/combat/resolvers/examples/`. Criar conteúdo não quebra Core.

## 3. Core Loop
```
[JORNADA] Viajar 1 dia -> Consome Supplies (-ceil(pop/100)/dia), Morale -10/dia, Renown fixo
   -> Evento Random (data/events/*.tres: 1-3 escolhas, cada com custo/recompensa)
   -> Chegada em Cidade/Acampamento
[ACAMPAMENTO] Descansar (+10 Morale/dia, consome Supplies, cura heróis) | Mercado (1 Renown : X Supplies, taxa variável) | Warfare (batalha auto de Fighters/Varl, opcional MVP)
[COMBATE TÁTICO] Grid 8x8 2.5D -> Turnos TeamRoundRobin (ou Initiative plugável) -> Mover (A* floodfill) + Ação (AbilityResource) -> Win/Lose -> volta para Jornada com Renown + loot
```

## 4. Caravana — Sistema (Genérico, exemplo Banner Saga)
- **População:** `Clansmen` (não lutam, geram supplies), `Fighters` (auto-batalhas), `Varl` (tank) — nomes exemplo, você pode renomear via `data/classes/*.tres`, `Heroes` (roster jogável).
- **Recursos (genéricos plugáveis):**
  - `Supplies` — comida/dias. `fórmula default simples: 1 Supplies = 1 dia` (plugável via `ICaravanResourceSystem`; exemplo Banner Saga `ceil(pop/100)/dia` é só 1 implementação). Falta = -Morale/dia.
  - `Morale` — 5 estados `Miserable..Great` **exemplo**. Você pode redefinir estados/efeitos via `data/stats/morale.tres`. Efeito no combate é plugável (ex: Banner Saga -willpower, mas pode ser -dano, -movimento, ou nada — configurável em `ICombatResolver`).
  - `Renown` — moeda + XP exemplo. Pode ser separado em `Gold + XP` ou outro recurso via `data/stats/caravan_resources.tres`.
- **Mapa:** 1D linear nodal (exemplo), caravana side-scrolling placeholder. 2D plugável futuro.

## 5. Combate Tático — Sistema (Genérico 100%)
- **Grid:** Quadrado 2.5D isométrico fixo (45°, câmera ortogonal `Node3D`), `Cell = Vector2i`, `cell_size = 1.0`. Hex plugável via `IGridSystem`.
- **Turnos:** `TeamRoundRobin` default (exemplo), plugável via `ITurnSystem` — você escolhe `Initiative`, `Speed-based`, etc. via `data/config/turn.tres`.
- **Stats Core — 100% data-driven (`data/stats/attributes.tres`):** Você define quais atributos existem. Exemplo default: `hp, armor, willpower, movement` (Banner Saga-like), mas pode ser `hp, shield, mana, stamina` ou `vida, defesa, foco` — **motor não trava**. Cada unidade tem `UnitStats: Dictionary[stat_id -> int]` validado contra a definição. Sem hardcode `Strength/Armor`.
- **Resolver Plugável (`ICombatResolver`):** Fórmula de dano é um `GDScript` Strategy. 3 exemplos em `systems/tactical/combat/resolvers/examples/` (movidos de gyms/ p/ testes dependerem do build):
  - `resolver_banner_saga.gd`: `dano = max(0, atk - armor)` (exemplo)
  - `resolver_hp_only.gd`: `dano = atk` puro (exemplo)
  - `resolver_shield.gd`: escudo absorve primeiro (exemplo)
  Você registra qual usar no `Registry` — trocar é 1 linha, sem tocar em `AbilityResource`.
- **Habilidades:** `AbilityResource`: `nome, custo {stat_id: valor}` (genérico, não só willpower), `alcance, area, efeitos [Resource genérico], vfx, logic_script`. Área via `floodfill`.
- **IA Inimiga:** `IAIBehavior` plugável genérica (`Agressive` exemplo foca `hp` baixo — stat id configurável).

## 6. Progressão & Conteúdo Plugável
- Herói sobe nível com Renown, desbloqueia `Tags` que liberam habilidades (`grant_tags_required`).
- Todo conteúdo é dado: `data/abilities/*.tres`, `data/events/*.tres`, `data/classes/*.tres`, `data/biomes/*.tres`. IA gera seguindo `docs/TDD.md#schema-ia`.
- Placeholders: `CapsuleMesh` unidade, `CubeMesh` tile, `Circle VFX`. Swap para `Sprite3D`/modelo GLB é trocar path no `.tres`.

## 7. Plataforma & Controles (Android)
- **Orientação:** Landscape (recomendado para tático), Portrait opcional via anchors.
- **Input:** Tap seleciona/move/ataca, long-press info, pinch zoom, drag pan. `VirtualJoystick` (Godot 4.7) se precisar.
- **Performance:** Renderer Mobile, ETC2 compressão, `max_sprites_per_batch 100` via MultiMesh, `Engine.max_fps = 60`, `Viewport UPDATE_WHEN_VISIBLE`.

## 8. Arte & Áudio (Placeholder First)
- Estilo alvo: pintado à mão crepuscular (Banner Saga), mas MVP = formas primitivas coloridas + `Label3D` HP.
- Áudio placeholder: `AudioStreamPlayer` beep. Real assets depois sem tocar código.

## 9. Scope MVP (Vertical Slice — Fase 0-3)
- **Corta v1:** Multiplayer, 2D world map navegável, photo mode, 20 classes, VFX complexo.
- **Entrega MVP (1-2 sprints):** Jornada 10 dias com 3 eventos + Acampamento (descansar/mercado) + Combate 6x6 com 2vs2 + 3 habilidades plugáveis (Strike/Heal/Fireball 3x3). Tudo rodável em APK debug.

## 10. Riscos & Mitigações
- **Risco:** Balanceamento supplies/morale quebrar fun → Mitigação: `ICaravanResourceSystem` plugável, tuning via `.tres` sem código.
- **Risco:** Grid 2.5D touch impreciso → Mitigação: `cell_size` grande, highlight floodfill, snap.

---
*GDD mantém experiência do jogador; detalhes de implementação em `TDD.md`.*
