# ADR-007 — Pirâmide realista 50/25/25 (era 70/25/5)

**Status:** Aceito (2026-08-24) | **Decide:** @Muse Spark | **Contexto:** `AGENTS.md:34` `70/25/5` genérico vs real `grep ^func test_` 96 funções

**Medição pós-PASSO1 (reclassificação 4 testes contract→unit):**
- `grep -r "^func test_" tests --include="*.gd"` → `unit 45 (46.9%)`, `integration 25 (26.0%)`, `contract 15 (15.6%) + smoke 4 (4.2%) + e2e 3 (3.1%) + regression 4 (4.2%) = cse 26 (27.1%)`, total 96
- `gut -gdir=contract -gdir=unit` antes 9→5 contract, 4→8 unit, mantém 95 tests `All passed`

**Decisão:** Atualizar alvo documentado `70/25/5` → `50/25/25` (`50% unit / 25% integration / 25% contract+smoke+e2e+regression`)

**Justificativa:**
- `70/25/5` é pirâmide genérica sem `DataValidator` pesado. Projeto tem `AttributeDatabase` + `DataValidator.validate_ability/validate_event` com 15 contract tests genuínos (valida `stat_id`, `alcance>10`, `area whitelist`, `vfx`, `ids duplicados`, `glob data/abilities+events`) + `smoke` 4 + `e2e` 3 + `regression` 4 = 26 testes que não são `5%` aspiracional, são `27%` real e necessário para `IA gerar conteúdo sem quebrar`.
- Tentar forçar `70% unit` inflando `20 unit` artificiais criaria testes rasos `assert true` sem valor, mesmo problema que `gate any test` já criticamos.
- `50/25/25` reflete real `47/26/27` com margem 3pp, mantém `integration 25%` já no alvo, e `piso` em `test_piramide_contract.gd` protege: `p_u >=40%, p_i >=20%, p_cse <=35%` (5pp abaixo do real), falha visível se apagar 30% unit.

**Consequência:** `TDD.md §8` e `AGENTS.md:34` atualizados para `50/25/25`. `test_piramide_proporcao_funcoes_com_piso_relativo` passa com `46.9/26/27.1`. Se `cse` voltar a `>35%`, guardião falha e indica nova reclassificação, não inflar unit.
