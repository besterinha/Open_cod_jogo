# CHANGELOG

## 2026-06-21 — Infraestrutura de validação + Correções F4
- Reset completo do histórico do git (orphan commit 2000055)
- Infraestrutura de validação de 8 camadas (unit, property, contract, mutation, smoke, etc.)
- CI/CD: test.yml (lint + gdUnit4 + mutation + smoke) + visual-qa.yml (Playwright)
- 7 agentes no opencode.json com permissões e habilidades
- MessageBus como autoload
- Export Android (arm64, minSdk 24) + Web configurados
- 12 correções F4: timeout do contract helper, performance helper, smoke helper, gitignore, etc.
- Arquivos docs/ renomeados para snake_case (GridSystem → grid_system, etc.)
- CHANGELOG limpo: reflete apenas o estado real do projeto
- Esqueleto do Sprint 1: grid_system.gd, hero.gd, touch_controller.gd, combat_scene.tscn
- main_scene.tscn criada e registrada no project.godot
- Smoke test destravado (test_combat_scene.gd agora passa com a cena placeholder)

## 2026-06-20 — (histórico anterior resetado)
- Projeto reiniciado do zero para motor TRPG tático genérico Godot 4.5
