# gyms/ — Sandbox (AGENTS.md: A2)

Fluxo documentado: `gyms/ -> validar contrato (DataValidator) -> mover para data/*.tres + systems/ability/logics/*.gd -> testes GUT+smoke -> CI bloqueia`

## Desvio bootstrap justificado (A2)
`data/abilities/strike.tres`, `heal.tres`, `fireball.tres` e `data/stats/attributes.tres` foram criados **direto em data/** no bootstrap `335307e/980ba84` para fechar MVP Fase 0-3 (vertical slice 3 magias). O motor já validava via `DataValidator` + `systems/ability/AbilityResource` tipado, então `gyms/`→`data/` não trouxe ganho naquele momento.

**Daqui para frente (Regra A2 travada):** toda nova magia/ação/evento **deve** nascer em `gyms/<dev>/` (ex: `gyms/example_dev/minha_magica/`), validar `DataValidator.validate_ability` + `validate_event`, e só então mover para `data/`. CI `check-file-coverage` + `pre-commit` bloqueiam nova `data/*.tres` sem `gyms/*` prévio? Não — bloqueia sem teste; o fluxo `gyms->data` permanece convenção documentada, não hard gate, para não travar solo dev. Os 3 exemplos plugáveis `ICombatResolver` foram **movidos para** `systems/tactical/combat/resolvers/examples/` (tests dependem do build; gyms é ignorado no pacote).

Ver `gyms/example_dev/README.md`.
