# STYLE.md — Norma de Código | Open_cod_jogo

**Fonte:** `GDScript style guide — Godot 4.7` (`docs.godotengine.org/en/4.7/tutorials/scripting/gdscript/gdscript_styleguide.html`), inspirado em `PEP 8`. Este doc é a **fonte única** para IA e humanos — `AGENTS.md` aponta para cá.

---

## 1. Princípio
Código deve ser **consistente, legível e mantível**. Preferir clareza a “esperteza”. O editor do Godot já usa essas convenções por padrão — deixe-o ajudar. Em caso de dúvida, siga este guia ou pergunte.

## 2. Convenções de Nomenclatura (obrigatório)

| Tipo | Convenção | Exemplo |
|------|-----------|---------|
| Arquivos | `snake_case` | `grid_system.gd`, `caravan_manager.gd` |
| Classes (`class_name`) | `PascalCase` | `class_name GridSystem`, `class_name CaravanManager` |
| Nodes | `PascalCase` | `Camera3D`, `TurnManager` |
| Funções | `snake_case` | `func get_reachable():`, `func can_pay():` |
| Variáveis | `snake_case` | `var supplies: int = 30`, `var is_traveling: bool` |
| Sinais | `snake_case` | `signal turn_started(unit: Unit)` |
| Constantes | `SCREAMING_SNAKE_CASE` | `const MAX_SUPPLIES: int = 99` |
| Enums | `PascalCase` (valores `SCREAMING_SNAKE`) | `enum State { IDLE, MOVING }` |

**Regras extras:**
*   Autoloads e `class_name` sempre `PascalCase`.
*   Nunca `Var Hp` ou `function GetStat()` — sempre `var hp: int`, `func get_stat()`.

## 3. Tipagem (obrigatório para IA)

*   Sempre tipado: `var supplies: int = 30`, `func get_stat(id: String) -> int:`, `func can_pay(cost: Dictionary) -> bool:`
*   Usar inferência `:=` quando tipo é óbvio e função tem `-> Retorno`: `var dir := get_direction()`
*   `void` explícito quando não retorna: `func rest_day() -> void:`

## 4. Ordem em Arquivos `.gd` (obrigatório)

```gdscript
class_name StateMachine
extends Node
## Docstring da classe.

signal state_changed(previous, new)

@export var initial_state: Node
var is_active: bool = true

@onready var _state: Node = initial_state

func _init() -> void:
    pass

func _ready() -> void:
    pass

func _process(delta: float) -> void:
    pass

# Funções públicas depois de callbacks
func get_state() -> Node:
    return _state

# Funções privadas último
func _private_helper() -> void:
    pass
```

Ordem: `class_name` → `extends` → `## docstring` → `signal` → `enum` → `const` → `@export` → `var` → `@onready` → `func _init/_ready/_process` → `func públicas` → `func _privadas`.

## 5. Formatação

*   **Indentação:** `Tab` (editor padrão), 1 tab por nível.
*   **Linhas:** Máx ~100 colunas; quebrar com `(` preferível a `\`.
*   **Espaços:** `dict["key"] = 5`, `my_array = [4, 5, 6]`, `print("foo")` — nunca `dict ["key"]` ou `print ("foo")`.
*   **Nunca alinhar colunas:** `x = 100` (não `x        = 100`).
*   **Números:** `1_234_567`, `0xfb8c0b` (minúsculo), `0b1101_0010` — só para > 1_000_000.
*   **If/ternário:** Sempre em linhas separadas, exceto `next_state = "idle" if is_on_floor() else "fall"`:
    ```gdscript
    if position.x > width:
        position.x = 0
    # NÃO: if position.x > width: position.x = 0
    ```
*   **Blank lines:** 1 linha entre funções, 2 entre classes (se houver `inner class`).

## 6. Comentários e Documentação

*   Comentários concisos, não “chain-of-thought” longo.
*   Use `##` para docstring de classe/função que aparece no `Help`.
*   Comente *porquê*, não *o quê* (código já diz o quê).

## 7. Arquitetura (reforço `AGENTS.md`)

*   `addons/` nunca depende de `systems/content`.
*   `systems/` usa `addons`, nunca depende de `content`.
*   `ui/` só lê `systems`.
*   `gyms/` isolado — CI bloqueia `grep -r "gyms/" systems/ ui/ addons/`.

## 8. Validação Automática

*   **Editor:** Godot formata com `Tab` automaticamente.
*   **Local:** `gdlint` (BLOQUEANTE) + `gdformat --check` (BLOQUEANTE ETAPA 2, `gdformatrc` `line_length 100, Tab`) + `godot --headless --check-only` + `DataValidator` + `gut --headless -gexit`
*   **CI:** `barichello/godot-ci:4.7.2` `Gate 0 gdlint + gdformat + check-only` falha se `style != ok`
*   **Gate 0 ETAPA 2:** `gdformat` alinhado `Tab` (`gdformatrc`), base zerada `61 files left unchanged`, promovido `AVISO → BLOQUEANTE` `pre-commit` e `ci.yml`

## 9. Para IA — Prompt Padrão

> Gere GDScript seguindo `docs/STYLE.md` + `AGENTS.md`. Use `snake_case` funcs/vars, `PascalCase` classes, tipo `var hp: int`, ordem `class_name→extends→signal→@export→var→@onready→func`. Assuma linter vai rodar — produza código já próximo de passar.

## 10. Referências

*   GDScript style guide 4.7: `docs.godotengine.org/en/4.7/tutorials/scripting/gdscript/gdscript_styleguide.html`
*   GDQuest GDScript guidelines: `gdquest.gitbook.io/gdquests-guidelines/godot-gdscript-guidelines`
*   Qodo 2025: inconsistência de estilo quebra confiança — 1.5x mais frustração quando IA não segue padrão.
