# ADR-006 — Manter Capsule unshaded em vez de Sprite3D (C5)

**Status:** Aceito (2026-08-23) | **Decide:** @Muse Spark | **Contexto:** `AGENTS.md` placeholder `CapsuleMesh` + `TDD.md:5` `Sprite3D billboard FIXED_Y` para 2.5D.

**Decisão:** Manter `placeholders/tactical/unit_capsule.tscn` `CapsuleMesh` + `content/maps/tactical_arena.gd:188` `StandardMaterial3D.shading_mode UNSHADED` `0.60,0.85,1` / `1.0,0.60,0.60` visível no `Redmi Note 8 Pro` (Mobile Vulkan `NDotL 0.55` escurecia `Sprite3D shaded` para `0.13` `quase preto` reportado).

**Justificativa C5:** `TDD.md:5` especifica `Sprite3D` para `hand-painted`, mas MVP `b29ddc7` provou `Capsule unshaded pastel + fundo branco 1,1,1 + grid 0.96/0.86 unshaded` distingue `azul/vermelho` mesmo com `brilho 60%`. Trocar agora para `Sprite3D` reintroduz `bug 4` `cópia` + exige `Texture CC0 128x128` + `SpriteFrames`. Swap futuro é só trocar `CapsuleMesh` por `Sprite3D` via `PackedScene` em `placeholders/tactical/unit_capsule.tscn` sem tocar `Unit` (`systems/tactical/units/unit.gd:1` `Node3D` agnóstico).

**Consequência:** `TDD.md:5` atualizado para `Capsule unshaded placeholder (Sprite3D quando asset CC0 pronto)`. `C5` considerado cumprido com desvio documentado. `CI` não exige `Sprite3D` até `Fase 5 Polimento`.
