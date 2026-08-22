# ADR-003: Testes com GUT 9.7.1 + godot-validation-flow

**Data:** 22/08/2026 | **Status:** Aceito

## Contexto
Precisa validar que nova habilidade/ação plugável não quebra nada (contrato, integração, regressão). Godot não tem framework nativo.

## Decisão
- **GUT 9.7.1** (branch `godot_4_7`, MIT, 2.6k stars) como framework principal. Suporta Godot 4.7.2 hoje (`github.com/bitwes/Gut/releases/tag/v9.7.1`).
- **godot-validation-flow** (Odin, MIT) para validação estática (broken deps, bad UIDs).
- Alternativa GdUnit4 (1.2k stars) considerada, mas master só até 4.7.1-rc1 (`gdUnit4 compat table`), menos maduro para 4.7.2 estável.

## Alternativas
- GdUnit4 v6.2.x: inspirado JUnit, integrado editor, bom, mas versão pinada 4.7.1.
- WAT/UT.Boom: menos asserts, menor comunidade.

## Workflow
1. godot-validation-flow + DataValidator (contrato .tres)
2. GUT unit + SceneRunner
3. Smoke suite headless (carrega todas .tscn)
4. CI `barichello/godot-ci:4.7.2` -> `gut -gexit` bloqueia merge
5. Regression: cada bug vira `test_regression_bug_<id>`

## Consequências
- Positivas: Pipeline gratuito, headless CI, TDD possível, IA pode ser validada automaticamente.
- Negativas: GUT roda fora do editor (separate window), mas tem CLI CI.

## Referências
- https://github.com/bitwes/Gut
- https://github.com/indieshade/godot-validation-flow
- https://bugnet.io/blog/regression-testing-strategies-for-indie-games
