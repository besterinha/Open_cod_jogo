# CONSISTENCY_RULES.md

## Diálogo
- IDs únicos (sem duplicatas)
- Referências válidas (nenhum `next` aponta para ID inexistente)
- Sem diálogo sem saída (exceto finais explícitos)
- Sem diálogo inalcançável
- Todo `next` deve apontar para um ID existente no mesmo arquivo ou em arquivo referenciado

## Estado
- Toda flag deve existir no STATE_REGISTRY.md
- Tipos de flag não mudam após definidos
- Flags não usadas devem ser reportadas ao orquestrador

## Combate
- Referências de habilidades e stats devem ser válidas
- Toda habilidade referenciada deve existir nos JSONs de dados
- Stats de personagens e inimigos devem seguir a estrutura definida

## Geral
- Nenhum acesso direto entre sistemas
- Toda comunicação via StateSystem ou JSON
- PROJECT_MAP é a única verdade sobre a estrutura do projeto
- STATE_REGISTRY é a única verdade sobre variáveis globais
- SCENE_MANIFEST.md é a lista autoritativa de cenas
