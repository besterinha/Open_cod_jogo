# data/stats — Definição de atributos genéricos

**Você define aqui quais stats existem.** O motor não trava.

Edite `attributes.tres` para adicionar/remover atributos:
- `id` — usado em `AbilityResource.custo` e `efeitos` e `UnitStats.values`
- `nome` — exibição
- `default/min/max` — clamp automático
- `is_resource` — true se for custo (mana/willpower), false se for base (hp/armor)

Exemplos:
- Quer só `hp + mana`? Deixe só `hp` e `mana`.
- Quer `shield` que absorve antes de `hp`? Adicione `shield` aqui e implemente lógica em `gyms/resolvers/resolver_shield.gd`.

Toda habilidade/evento valida contra este arquivo via `DataValidator.validate_ability(ability, db)`.
