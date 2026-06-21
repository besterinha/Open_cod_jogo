---
name: godot-gdscript
description: GDScript 2.0 strictly typed syntax, patterns, conventions, and anti-patterns for Godot 4.5
---

# Skill: GDScript (godot-gdscript)

## When to Use
Use when writing or modifying `.gd` script files in Godot 4.5. Provides
strictly typed syntax rules, signal patterns, and file organization
conventions.

## Typing Rules
- All variables MUST have explicit types: `var health: int = 10`
- Function returns MUST be typed: `func heal(amount: int) -> void:`
- Use `Variant` only when type is genuinely dynamic
- Prefer built-in types over `Variant` where possible

## Signals
- Connect ONLY via code: `signal_name.connect(_on_signal)`
- NEVER use editor visual connections
- Declare signals with typed parameters:
  `signal unit_moved(unit: Node2D, from: Vector2i, to: Vector2i)`

## Node References
- Use `@onready` for node references:
  `@onready var sprite: Sprite2D = %Sprite2D`
- Use `%` unique name references in scenes
- Initialize in `_ready()`, avoid `_init()` for scene-dependent logic

## Performance
- Avoid `_process()` overhead — use `_physics_process()` or timers
- Cache frequent lookups: `var grid: GridSystem = %GridSystem`
- Pool and reuse objects instead of instantiating repeatedly

## File Organization
- Max 400 lines per script. Split at responsibility boundaries.
- Max 100 chars per line. Break long lines with parentheses or `\`.
- `class_name` for reusable components, not for singletons.
- One class per file, file named after class (PascalCase).
