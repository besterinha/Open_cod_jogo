# Pattern: Combat System

## Descrição
Sistema de combate tático por turnos orientado a dados.

## Regras de Implementação
- Loop: Iniciativa -> Ação -> Consequência
- Personagens definidos por JSON (stats, classe, habilidades)
- Habilidades definidas por JSON (nome, dano, alcance, efeitos)
- Sistema de recursos afetando stats (ex: moral, suprimentos)
- Comunicação apenas via StateSystem

## Interface Pública
- `execute_turn(state: Dictionary) -> Dictionary`
- `get_initiative_order(units: Array) -> Array`
- `apply_skill(caster_id: String, skill_id: String, target: Vector2) -> Dictionary`

## Placeholders
- Unidades em combate: círculos com borda colorida por time
- Área de ataque: highlight amarelo no grid
- Dano: número flutuante vermelho
