# gyms/resolvers — 3 exemplos plugáveis de ICombatResolver

Cada arquivo implementa `CombatResolver.resolve(attacker: UnitStats, defender: UnitStats, ability: AbilityResource) -> Dictionary`
O motor não trava — você registra qual usar em `Registry.register("combat_resolver", seu_resolver)`.

- `resolver_banner_saga.gd` — Banner Saga-like: `dano = max(0, atk - armor)` onde `atk = ability.efeitos[0].delta` e `armor = defender.get_stat("armor")`. Exemplo, não contrato.
- `resolver_hp_only.gd` — HP puro: `hp -= dano` direto, ignora armor.
- `resolver_shield.gd` — Shield absorve primeiro: `shield -= dano; if shield <0: hp += shield`.

Copie o que quiser para `systems/stats/resolvers/` quando decidir a lógica final. Enquanto estiver em `gyms/`, CI ignora.
