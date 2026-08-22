# Regression
Cada bug corrigido vira um teste permanente `test_regression_bug_<id>.gd` que reproduz a falha.

Exemplo: `VFX sem dano` virou `tests/integration/test_hud_combat_board.gd::test_vfx_and_damage_atomicos` + `test_vfx_sem_dano_deve_falhar`.

Ao corrigir bug, crie arquivo aqui e referencie issue.
