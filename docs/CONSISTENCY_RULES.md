# CONSISTENCY_RULES.md

## Diálogo
- IDs únicos (sem duplicatas)
- Referências válidas (nenhum `next` aponta para ID inexistente)
- Sem diálogo sem saída (exceto finais explícitos)
- Sem diálogo inalcançável
- Todo `next` deve apontar para um ID existente no mesmo arquivo ou em arquivo referenciado

## Estado
- Toda flag deve existir no state_registry.md
- Tipos de flag não mudam após definidos
- Flags não usadas devem ser reportadas ao orquestrador

## Combate
- Referências de habilidades e stats devem ser válidas
- Toda habilidade referenciada deve existir nos JSONs de dados
- Stats de personagens e inimigos devem seguir a estrutura definida

## Geral
- Nenhum acesso direto entre sistemas
- Toda comunicação via MessageBus ou queries diretas
- PROJECT_MAP é a única verdade sobre a estrutura do projeto
- state_registry é a única verdade sobre variáveis globais (quando implementado)
- scene_manifest.md é a lista autoritativa de cenas
