# ADR-002: Arquitetura Modular 4 Pilares (Epictellers/GDQuest)

**Data:** 22/08/2026 | **Status:** Aceito

## Contexto
Projeto precisa suportar criação contínua de magias/eventos por IA sem tocar Core, e permitir swap placeholders -> assets reais. Monolito quebraria.

## Decisão
Adotar **4 Pilares Epictellers (GDQuest Modular Game Architecture, 2026/06/15)**:
- `addons/` Libraries (toolkit agnóstico)
- `systems/` Systems (regras, usam addons)
- `ui/` UI (só lê systems)
- `content/` + `data/` Content (usa systems, systems nunca depende de content)
- `gyms/` Sandbox (ignorado no build)

Fluxo: `content -> systems -> addons`.

## Alternativas
- ECS puro (flecs): overkill para turno, tradeoff complexidade.
- MVC tradicional: UI acoplada a systems, difícil para IA gerar conteúdo isolado.
- Monolito src/: rápido inicio mas dívida técnica escala mal.

## Consequências
- Positivas: IA gera só `data/*.tres`, content swap sem quebrar, CI bloqueia `gyms -> !gyms`, sequel pronto.
- Negativas: Overhead inicial de pastas, curva para solo dev (mitigado permitindo UI levemente acoplada no MVP).
- Escalabilidade: Suporta 1–30 devs.

## Referências
- https://www.gdquest.com/library/modular_game_architecture/
- https://github.com/garyritchie/pt_godot_modular
