# Pattern: Dialogue System

## Descrição
Motor de diálogo genérico que interpreta JSONs e gerencia ramificações narrativas.

## Regras de Implementação
- Lê JSONs da pasta `/src/data/dialogues/`
- IDs estruturados como `DIA_[TEMA]_[NNN]`
- Navega entre nós com base em `next` e condições de estado
- Consequências registradas via StateSystem
- Estrutura de JSON padronizada (version, id, text, choices)

## Interface Pública
- `get_next_node(current_id: String, state: Dictionary) -> String`
- `get_choices(node_id: String) -> Array`
- `apply_effects(effects: Dictionary) -> void`

## Estrutura do JSON
- version: int
- id: String (DIA_TEMA_NNN)
- text: String
- choices: Array de {text: String, next: String, effects: Dictionary}

## Placeholders
- Caixas de texto retangulares com fonte provisória
- Botões de escolha como retângulos clicáveis
- Nome do personagem em texto simples acima da caixa
