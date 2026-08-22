# Gym — example_dev

Sandbox pessoal, ignorado no build. Protótipo rápido de magia/ação/evento aqui sem seguir padrão.

## Fluxo
1. Crie pasta `gyms/example_dev/minha_magica/` com cena `.tscn` + script `.gd` bagunçado à vontade
2. Teste no editor (F6)
3. Quando aprovado, refatore para `data/abilities/minha_magica.tres` + `systems/ability/logics/minha_magica.gd` seguindo `TDD.md#schema-ia`
4. Adicione teste em `tests/unit/test_minha_magica.gd` + rode `gut -gexit`
5. CI garante que não quebrou nada

**Regra:** nada em `addons/`, `systems/`, `ui/` pode dar `preload("res://gyms/...")`. CI bloqueia.
