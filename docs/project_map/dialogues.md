# Dialogues

## IDs de Diálogos do Projeto

### IDs Existentes
- DIA_EXAMPLE_001: Diálogo inicial (2 choices: partir / treinar)
- DIA_EXAMPLE_002: Estrada (2 choices: distribuir suprimentos / ignorar)
- DIA_EXAMPLE_003: Jornada continua (1 choice: recomeçar)

### Estrutura do JSON
```json
{
  "version": 1,
  "id": "DIA_EXAMPLE_001",
  "text": "Texto do diálogo.",
  "choices": [
    {
      "text": "Opção visível",
      "next": "DIA_PROXIMO_ID",
      "effects": {"flag": valor},
      "conditions": {"flag": valor}
    }
  ]
}
```

### Regras
- Esta é a lista autoritativa de IDs de diálogos
- IDs seguem o padrão `DIA_[TEMA]_[NNN]`
- `effects` altera flags no StateSystem quando a choice é selecionada
- `conditions` filtra choices com base no estado atual (não mostra se condição falhar)
- Qualquer ID não listado aqui é considerado fora do escopo
