# GDD — Open_cod_jogo | TRPG Tático 2.5D + Caravana (One-Page + Detalhamento)

**Versão:** 0.1.0 | **Data:** 22/08/2026 | **Engine:** Godot 4.7.2-stable | **Plataforma:** Android (720p–2K, Offline)
**Inspiração:** The Banner Saga | **Estado:** Pré-produção, modular plugável

---

## 1. Elevator Pitch (1 frase)
Caravana em jornada 1D side-scrolling com gestão de recursos (Supplies/Morale/Renown) que alimenta combates táticos 2.5D por turnos — cada magia/evento é um dado plugável que IA pode gerar sem tocar no código.

## 2. Pillars (3)
1.  **Caravana = Coração** — Decisões difíceis na estrada têm custo real no combate (moral baixa = willpower menor).
2.  **Tático Legível** — Grid quadrado 2.5D isométrico, Armor vs Strength, posicionamento > DPS. Touch preciso.
3.  **Plugável = Longevidade** — Habilidades/eventos são `.tres`/JSON, não código hardcoded. Criar conteúdo não quebra Core.

## 3. Core Loop
```
[JORNADA] Viajar 1 dia -> Consome Supplies (-ceil(pop/100)/dia), Morale -10/dia, Renown fixo
   -> Evento Random (data/events/*.tres: 1-3 escolhas, cada com custo/recompensa)
   -> Chegada em Cidade/Acampamento
[ACAMPAMENTO] Descansar (+10 Morale/dia, consome Supplies, cura heróis) | Mercado (1 Renown : X Supplies, taxa variável) | Warfare (batalha auto de Fighters/Varl, opcional MVP)
[COMBATE TÁTICO] Grid 8x8 2.5D -> Turnos TeamRoundRobin (ou Initiative plugável) -> Mover (A* floodfill) + Ação (AbilityResource) -> Win/Lose -> volta para Jornada com Renown + loot
```

## 4. Caravana — Sistema (Banner Saga-like)
- **População:** `Clansmen` (não lutam, geram supplies via forrageamento), `Fighters` (auto-batalhas), `Varl` (tank, forte), `Heroes` (roster jogável no tático).
- **Recursos:**
  - `Supplies` — comida/dias. `fórmula default simples: 1 Supplies = 1 dia` (plugável para `1/100 pessoas/dia` banner saga exata via `ICaravanResourceSystem`). Falta de supplies = -Morale/dia, perda de pop.
  - `Morale` — 5 estados: `Miserable / Low / Normal / Good / Great`. Afeta `Willpower` no combate (-2/+2). Viagem -10/dia, descanso +10/dia se bem provisionado, eventos +-5..25.
  - `Renown` — moeda + XP. Ganho em combate/eventos. Troca por Supplies no mercado (taxa `1:X`) ou upa heróis. Sem Renown = sem progressão.
- **Mapa:** 1D linear nodal (cidades conectadas) com caravana visual side-scrolling (sprites placeholder deslizando). Futuro: mapa 2D plugável.

## 5. Combate Tático — Sistema
- **Grid:** Quadrado 2.5D isométrico fixo (45°, câmera ortogonal `Node3D`), `Cell = Vector2i`, `cell_size = 1.0` mundo. Hex plugável via `IGridSystem`.
- **Turnos:** `TeamRoundRobin` default (time todo age), alternativa `Initiative (Agilidade)` plugável via `ITurnSystem`.
- **Stats Core (por unidade):** `Strength (HP + ATK)`, `Armor (buffer), Willpower (recurso para habilidades, afetado por Morale)`, `Movement`. Dano = `max(0, ATK - Armor_alvo)` simplificado, `Armor break` primeiro é ótimo.
- **Habilidades:** Toda ação é `AbilityResource` (Strategy): `nome, custo {willpower, renown}, alcance, area (Single/3x3/Cross/Line), efeitos [Damage, Heal, Status], vfx: PackedScene, logic_script: GDScript`. Área via `floodfill` no `GridSystem`.
- **IA Inimiga:** `IAIBehavior` plugável: `Agressive (foca Strength baixa), Defensive, Support`. Gera `Intent` não executa direto.

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
