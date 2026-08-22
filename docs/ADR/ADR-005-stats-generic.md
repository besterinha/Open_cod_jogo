# ADR-005: Stats 100% Genéricos Data-Driven (Opção B)

**Data:** 22/08/2026 | **Status:** Aceito | **Escolha:** B (stats totalmente em dados)

## Contexto
Usuário não quer travar lógica de combate em Banner Saga (HP+Armor). Quer motor que aceite qualquer escolha criativa futura: HP puro, Shield, Mana, Stamina, etc.

## Decisão
- `AttributeDefinition` (`id, nome, default/min/max, is_resource`) em `data/stats/attributes.tres` — você define quais stats existem.
- `UnitStats` (`Dictionary[stat_id -> int]`) validado contra `AttributeDatabase`.
- `StatsRegistry` carrega `data/stats/` e valida custos/efeitos.
- `AbilityResource.custo: Dictionary` e `efeitos: Array[Dictionary]` referenciam `stat_id` genérico, não `willpower` hardcoded.
- `ICombatResolver` (Strategy) lê stats genéricos, 3 exemplos em `gyms/resolvers/` provam troca sem tocar Core.

## Alternativas
- A) Stats fixos hardcode `hp/armor/willpower` — simples mas trava design.
- B) **Escolhido** — genérico, custo 1 camada de indireção, mas permite IA/designer criar stats novos só editando `.tres`.

## Consequências
- Positivas: Trocar `Armor vs Strength` por `Shield` ou `HP only` é 1 linha (trocar resolver + editar `attributes.tres`), DataValidator bloqueia stat_id inexistente.
- Negativas: Leve overhead de validação, mas ganho de flexibilidade compensa para automação IA.
- Fallback: `StatsRegistry` cria defaults Banner Saga-like se `attributes.tres` faltar, para não quebrar editor.

## Validação
`tests/unit/test_stats_generic.gd` prova: mesmo dano, resolvers diferentes dão resultados diferentes; stat_id desconhecido rejeitado.

## Referências
- TDD.md#4.3b
- gyms/resolvers/
